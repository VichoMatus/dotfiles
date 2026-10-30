"""Check that left-side statistics follow bar visibility; restores initial visibility."""
import json
import subprocess

def call(target, action):
    return subprocess.check_output(['qs', 'ipc', '-c', 'inir', 'call', target, action], text=True)

def status():
    return json.loads(call('notch-eDP-1', 'status'))

previous = status()['visible']
try:
    call('bar', 'open')
    assert status()['visible'], 'Run outside fullscreen and with the session unlocked'
    assert status()['monitoring']
    assert status()['appCount'] >= 0
    call('bar', 'close')
    assert not status()['monitoring']
    call('bar', 'open')
    assert status()['monitoring']
finally:
    call('bar', 'open' if previous else 'close')
print('OK: monitoreo activo solo con la barra visible.')
