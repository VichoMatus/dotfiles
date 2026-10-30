"""Run in the graphical session; checks feedback without changing audio or brightness."""
import json
import subprocess
import time

def ipc(target, action):
    return subprocess.check_output(['qs', 'ipc', '-c', 'inir', 'call', target, action], text=True)

def status():
    return json.loads(ipc('notch-eDP-1', 'status'))

assert status()['visible'], 'Notch must be visible for this check'
for kind in ['volume', 'brightness']:
    ipc('osd', kind)
    time.sleep(0.15)
    assert status()['level'] == kind
    # Repeated requests must extend the feedback, even without a value change.
    time.sleep(0.9)
    ipc('osd', kind)
    time.sleep(1.1)
    assert status()['level'] == kind
    time.sleep(0.9)
    assert status()['level'] == ''
if status()['expanded']:
    ipc('notch-eDP-1', 'toggle')
ipc('notch-eDP-1', 'toggle')
if status()['playing']:
    assert status()['expanded']
    time.sleep(4.3)
assert not status()['expanded']
print('OK: volumen, brillo, solicitudes repetidas y panel musical según reproducción.')
