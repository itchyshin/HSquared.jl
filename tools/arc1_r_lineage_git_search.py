"""Search an hsquared R git checkout for the commit that best matches the
Arc 1 v8/v10/v11 R source maps recorded in
docs/dev-log/after-task/2026-10-24-arc1-r-lineage-comparison.json.

Usage: python3 -I tools/arc1_r_lineage_git_search.py <HSquared.jl root> <hsquared R repo> <out.json>
Read-only on both repos (git log / ls-tree / cat-file only).
"""
import json,subprocess,hashlib,sys,collections
J,R,OUT=sys.argv[1],sys.argv[2],sys.argv[3]
d=json.load(open(J+'/docs/dev-log/after-task/2026-10-24-arc1-r-lineage-comparison.json'))
maps={}
for m in d['source_maps']:
    e=m['comparisons'][0]['entries']; maps[m['candidate']]={x['path']:x['expected_sha256'] for x in e}
paths=sorted(set(p for m in maps.values() for p in m))
g=lambda *a: subprocess.run(['git','-C',R]+list(a),capture_output=True,text=True,check=True).stdout
# every blob that ever lived at a mapped path, across all refs
raw=g('log','--all','--format=','--raw','--no-abbrev','--no-renames','--',*paths)
blobs=collections.defaultdict(set)
for line in raw.splitlines():
    f=line.split('\t'); 
    if len(f)<2: continue
    meta=f[0].split(); blobs[f[1]].add(meta[3])
allb=sorted({b for s in blobs.values() for b in s if set(b)!={'0'}})
p=subprocess.Popen(['git','-C',R,'cat-file','--batch'],stdin=subprocess.PIPE,stdout=subprocess.PIPE)
sha={}
for b in allb:
    p.stdin.write((b+'\n').encode()); p.stdin.flush()
    hdr=p.stdout.readline().split(); n=int(hdr[2]); data=p.stdout.read(n); p.stdout.read(1)
    sha[b]=hashlib.sha256(data).hexdigest()
rev={}
for path,bs in blobs.items():
    for b in bs:
        if b in sha: rev[(path,sha[b])]=b
res={'schema':'r-lineage-git-blob-search/v1','r_repo_head':g('rev-parse','HEAD').strip(),'refs_searched':'--all (local + all origin branches fetched 2026-11-04)','maps':{}}
commits=g('rev-list','--all').split()
for name,m in maps.items():
    found={p:rev.get((p,h)) for p,h in m.items()}
    never=[p for p,b in found.items() if b is None]
    # score commits: count mapped paths whose blob at that commit equals expected
    best=[]
    want={p:b for p,b in found.items() if b}
    for c in commits:
        ls=g('ls-tree','-r',c,'--',*want.keys())
        have={l.split('\t')[1]:l.split()[2] for l in ls.splitlines()}
        sc=sum(1 for p,b in want.items() if have.get(p)==b)
        best.append((sc,c))
    best.sort(reverse=True); top=best[:5]
    tc=top[0][1]; ls=g('ls-tree','-r',tc,'--',*m.keys()); have={l.split('\t')[1]:l.split()[2] for l in ls.splitlines()}
    diff=[p for p in m if have.get(p)!=found.get(p) or found.get(p) is None]
    res['maps'][name]={'paths':len(m),'paths_with_blob_anywhere_in_history':len(want),'paths_never_in_history':never,
      'top_commits':[{'commit':c,'matches':s,'subject':g('log','-1','--format=%ad %s','--date=short',c).strip(),'on_refs':g('branch','-a','--contains',c).split()[:6]} for s,c in top],
      'best_commit_mismatched_paths':diff}
json.dump(res,open(OUT,'w'),indent=1)
for n,v in res['maps'].items():
    print(n,v['paths'],'in-history',v['paths_with_blob_anywhere_in_history'],'never',len(v['paths_never_in_history']),v['paths_never_in_history'][:12])
    for t in v['top_commits'][:3]: print('  ',t['matches'],t['commit'][:10],t['subject'][:70],t['on_refs'][:3])
    print('   mismatched at best:',len(v['best_commit_mismatched_paths']))
