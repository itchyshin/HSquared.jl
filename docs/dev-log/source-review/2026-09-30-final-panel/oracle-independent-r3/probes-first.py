from pathlib import Path
import hashlib,json,subprocess,sys,copy
p=Path(__file__).resolve().parent;root=p/'root';ev=p/'evidence';rr=p/'R'
def put(path,value):
 path.parent.mkdir(parents=True,exist_ok=True);path.write_text(json.dumps(value) if isinstance(value,dict) else value)
def h(path):return hashlib.sha256(path.read_bytes()).hexdigest()
for n in ['src/a.jl','test/runtests.jl','test/fixtures/a.jl','Project.toml','Manifest.toml','docs/src/a.md','docs/src/b.md','docs/make.jl','docs/Project.toml','docs/Manifest.toml']:put(root/n,'original '+n)
for n in ['R/a.R','tests/testthat/a.R','man/a.Rd','vignettes/a.Rmd','DESCRIPTION','NAMESPACE']:put(rr/n,'original '+n)
result={'exit_status':0,'over_estimate':False,'elapsed_seconds':1,'estimate_seconds':120,'start_utc':'2026-09-30T01:00:00+00:00','julia_threads':1,'blas_threads':1,'require_bridge':True,'project':str(root),'command':['/synthetic/bin/julia','--startup-file=no','--project=.','-e','using Pkg; Pkg.test(;julia_args=["--threads=1"])']}
for n in ['julia-package-final-result.json','docs-result.json','R-result.json','live-bridge-result.json','R-site-result.json']:
 r=copy.deepcopy(result)
 if n=='live-bridge-result.json':r['command']=['/synthetic/bin/Rscript','-e','devtools::test(filter = "fa-optin|gllvm-optin", stop_on_failure=TRUE)']
 put(ev/n,r)
for n in ['julia-package-final.log','docs.log','R.log','R-00check.log','live-bridge.log','R-site.log','docs-Project.toml','docs-Manifest.toml','hsquared_0.9.0.tar.gz']:put(ev/n,{'julia-package-final.log':'Testing HSquared tests passed','R-00check.log':'Status: OK','live-bridge.log':'[ FAIL 0 | WARN 0 | SKIP 0 | PASS 213 ]'}.get(n,'evidence '+n))
put(ev/'source-test-freeze-final.json',{'utc':'2026-09-30T00:00:00+00:00','files':{n:h(root/n) for n in ['src/a.jl','test/runtests.jl','test/fixtures/a.jl','Project.toml','Manifest.toml']}})
pages=[]
for lang,names in [('julia',['validation-status','multivariate-models']),('R',['current-limits','multivariate','genetic-gllvm'])]:
 for n in names:
  art=lang+'-'+n+'.html';put(ev/art,'<p>experimental</p>');pages.append({'language':lang,'name':n,'artifact':art,'required_terms':['experimental']})
manifest={'artifacts':{f.name:h(f) for f in ev.iterdir() if f.is_file()},'julia_documentation_files':{'docs/src/a.md':h(root/'docs/src/a.md'),'docs/src/b.md':h(root/'docs/src/b.md'),'docs/make.jl':h(root/'docs/make.jl')},'julia_documentation_environment_files':{n:h(root/n) for n in ['docs/Project.toml','docs/Manifest.toml']},'r_files':{str(f.relative_to(rr)):h(f) for f in rr.rglob('*') if f.is_file()},'rendered_pages':pages}
original={str(f):f.read_bytes() for q in (root,ev,rr) for f in q.rglob('*') if f.is_file()}
rows=[]
def reset():
 for q in (root,ev,rr):
  for f in q.rglob('*'):
   if f.is_file() and str(f) not in original:f.unlink()
 for name,contents in original.items():Path(name).write_bytes(contents)
 put(ev/'final-acceptance-manifest.json',manifest)
def mutate_manifest(fn):
 m=copy.deepcopy(manifest);fn(m);put(ev/'final-acceptance-manifest.json',m)
def pin_current(name):
 m=json.loads((ev/'final-acceptance-manifest.json').read_text());m['artifacts'][name]=h(ev/name);put(ev/'final-acceptance-manifest.json',m)
def run(name,scope,expected,optimized=False):
 cmd=[sys.executable]+(['-O'] if optimized else [])+[str(p/'oracle.py'),scope,'--root',str(root),'--evidence',str(ev),'--r-root',str(rr)]
 c=subprocess.run(cmd,capture_output=True,text=True);success=c.returncode==0 and c.stdout.strip()=='HSQ_FINAL_'+{'julia':'JULIA','docs':'DOCS','R':'R_BRIDGE_DOCS'}[scope]+'_PASS'
 assert success==expected,(name,c.returncode,c.stdout,c.stderr)
 if not expected:assert c.returncode!=0 and c.stdout=='',name
 rows.append({'name':name,'accepted':success,'exit_status':c.returncode,'stdout':c.stdout.strip(),'stderr_last':c.stderr.splitlines()[-1] if c.stderr else ''})
for scope in ['julia','docs','R']:
 reset();run('valid complete '+scope,scope,True)
for n,scope in [('src/a.jl','julia'),('test/fixtures/a.jl','julia'),('docs/src/a.md','docs')]:
 reset();put(root/n,'changed');run('changed '+n,scope,False)
for n,scope in [('julia-package-final-result.json','julia'),('julia-package-final.log','julia'),('julia-validation-status.html','docs'),('R-genetic-gllvm.html','R')]:
 reset();put(ev/n,'changed');run('changed '+n,scope,False)
reset();put(root/'src/new.jl','added');run('added source','julia',False)
reset();put(root/'test/new.jl','added');run('added test','julia',False)
reset();put(ev/'source-test-freeze-final.json',{'utc':'2026-09-30T00:00:00+00:00','files':{'Project.toml':h(root/'Project.toml')}});pin_current('source-test-freeze-final.json');run('zero source/test freeze','julia',False)
for n,scope in [('julia-package-final-result.json','julia'),('julia-package-final.log','julia'),('source-test-freeze-final.json','julia'),('julia-validation-status.html','docs'),('R-genetic-gllvm.html','R'),('docs-Manifest.toml','docs')]:
 reset();mutate_manifest(lambda m:m['artifacts'].pop(n));run('omitted pin '+n,scope,False)
for changes,name in [({'exit_status':False},'Boolean exit'),({'over_estimate':None},'missing estimate'),({'elapsed_seconds':float('inf')},'infinite elapsed'),({'start_utc':'bad'},'malformed timestamp'),({'start_utc':'2026-09-29T00:00:00+00:00'},'predates freeze')]:
 reset();r=copy.deepcopy(result);r.update(changes);put(ev/'julia-package-final-result.json',r);pin_current('julia-package-final-result.json');run(name,'julia',False)
reset();mutate_manifest(lambda m:m['rendered_pages'][0].update(required_terms=[]));run('empty terms','docs',False)
reset();mutate_manifest(lambda m:m['rendered_pages'].pop());run('missing required R page','R',False)
reset();put(root/'src/a.jl','changed');run('optimized mode source rejection','julia',False,True)
# Residual semantic controls: fresh hashes cannot bind an insufficient declared contract.
reset();mutate_manifest(lambda m:m['julia_documentation_files'].pop('docs/src/b.md'));put(root/'docs/src/b.md','changed unlisted documentation');run('omitted changed docs rejected','docs',False)
reset();put(root/'docs/Manifest.toml','changed environment');run('changed current docs environment rejected','docs',False)
reset();r=copy.deepcopy(result);r['project']='/different/project';r['command']=['different-command'];put(ev/'live-bridge-result.json',r);pin_current('live-bridge-result.json');run('wrong bridge project/command rejected','R',False)
reset();r=copy.deepcopy(result);r['command']=['unrelated-command'];put(ev/'julia-package-final-result.json',r);pin_current('julia-package-final-result.json');run('wrong package command rejected','julia',False)
(p/'results.json').write_text(json.dumps(rows,indent=2)+'\n');print(json.dumps(rows,indent=2));print('TOTAL',len(rows))
