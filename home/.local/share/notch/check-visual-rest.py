"""Check the bar's visual break with a short two-second test."""
import json
import subprocess
import time

def call(target, action, *args):
    return subprocess.check_output(['qs', 'ipc', '-c', 'inir', 'call', target, action, *args], text=True).strip()

def state():
    return json.loads(call('notch-eDP-1', 'status'))

assert state()['visible'], 'Run with the bar visible and outside fullscreen'
assert call('notch-rest', 'start', '0') == 'false'
assert call('notch-rest', 'start', '2') == 'true'
assert call('notch-rest', 'start', '2') == 'false', 'Must not overlap breaks'
assert not state()['visible']
assert not state()['monitoring']
time.sleep(2.3)
assert state()['visible']
assert state()['monitoring']
assert not json.loads(call('notch-rest', 'status'))['active']
print('OK: descanso visual, protección contra solapamiento y restauración.')
