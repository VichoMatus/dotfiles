import json,os,subprocess,time
from pathlib import Path

def ipc(target,action):
 return subprocess.check_output(['qs','ipc','-c','inir','call',target,action],text=True).strip()
def processes():
 result={}
 for name in ['qs','niri']:
  ids=subprocess.check_output(['pgrep','-x',name],text=True).split()
  for pid in ids:
   raw=Path('/proc',pid,'stat').read_text().rsplit(')',1)[1].split()
   result[pid]=(name,int(raw[11])+int(raw[12]),int(raw[21])*os.sysconf('SC_PAGE_SIZE')/1048576)
 return result
initial=json.loads(ipc('notch-eDP-1','status'))
if initial['expanded']: ipc('notch-eDP-1','toggle')
rows=[]
try:
 for mode in ['visible','hidden','visible','hidden']:
  ipc('bar','open' if mode=='visible' else 'close')
  time.sleep(3)
  before=processes(); start=time.monotonic(); watts=[]
  for _ in range(8):
   try: watts.append(int(Path('/sys/class/power_supply/BAT0/power_now').read_text())/1e6)
   except OSError: pass
   time.sleep(1)
  after=processes(); elapsed=time.monotonic()-start
  row={'mode':mode,'elapsed':round(elapsed,2),'cpu_percent':{},'rss_mib':{},'battery_watts':round(sum(watts)/len(watts),3) if watts else None}
  for pid,(name,ticks,rss) in after.items():
   if pid not in before: raise RuntimeError('Proceso reiniciado durante muestra; repetir medición')
   row['cpu_percent'][name]=round(row['cpu_percent'].get(name,0)+(ticks-before[pid][1])/os.sysconf('SC_CLK_TCK')/elapsed*100,2)
   row['rss_mib'][name]=round(row['rss_mib'].get(name,0)+rss,2)
  rows.append(row); print(json.dumps(row),flush=True)
finally:
 ipc('bar','open' if initial['visible'] else 'close')
 if initial['expanded'] and initial['visible']: ipc('notch-eDP-1','toggle')
Path('/tmp/vicho-notch-measurements.json').write_text(json.dumps({'initial':initial,'samples':rows},indent=2))
