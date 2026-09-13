from pathlib import Path
import subprocess,json,runpy
s=Path(__file__).resolve().parent
runpy.run_path(str(s/'prepare_negative.py'))
results={}
for name,location in json.loads((s/'negative_cases.json').read_text()).items():
 run=subprocess.run(['bun','/Users/macolas/Software/bend2-core/bend2/main.ts',str(s/('negative_'+name+'.bend'))],cwd=s,text=True,capture_output=True)
 out=run.stdout+run.stderr
 (s/('negative_'+name+'.txt')).write_text(out)
 assert run.returncode!=0 and 'All terms check.' not in out and 'Error:' in out and '- expected :' in out and '- observed :' in out,(name,out)
 assert 'Location: '+location in out,(name,out)
 results[name]={'exit':run.returncode,'rejected':True}
(s/'negative_results.json').write_text(json.dumps(results,indent=2)+'\n')
print('PASS seven intended negative checks: stale birth world, stale birth record, stale wait record, skipped command world, false birth marker, stale lookup record, assumed boundary validity.')

