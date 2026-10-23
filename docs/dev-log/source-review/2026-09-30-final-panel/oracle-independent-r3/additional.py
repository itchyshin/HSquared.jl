import probes as t
import copy,json
# Keep valid project and change only command, independently of the project refusal.
t.reset();r=json.loads((t.ev/'live-bridge-result.json').read_text());r['command']=['/synthetic/bin/Rscript','-e','unrelated()'];t.put(t.ev/'live-bridge-result.json',r);t.pin_current('live-bridge-result.json');t.run('wrong bridge command only rejected','R',False)
t.reset();r=json.loads((t.ev/'live-bridge-result.json').read_text());r['julia_threads']=2;t.put(t.ev/'live-bridge-result.json',r);t.pin_current('live-bridge-result.json');t.run('wrong bridge threads rejected','R',False)
t.reset();t.put(t.root/'docs/src/new.md','new docs');t.run('added documentation rejected','docs',False)
t.reset();t.run('complete Julia under optimization','julia',True,True)
(t.p/'results-additional.json').write_text(json.dumps(t.rows,indent=2)+'\n');print('TOTAL_ADDITIONAL',len(t.rows))
