"""Check pointer retention and a short playback interruption; requires one playing MPRIS player."""
import json
import subprocess
import time

def call(*args):
    return subprocess.check_output(args, text=True).strip()

def status():
    return json.loads(call('qs', 'ipc', '-c', 'inir', 'call', 'notch-eDP-1', 'status'))

def toggle():
    call('qs', 'ipc', '-c', 'inir', 'call', 'notch-eDP-1', 'toggle')

players = call('playerctl', '-l').splitlines()
assert len(players) == 1 and call('playerctl', '-p', players[0], 'status') == 'Playing'
assert status()['visible'] and status()['playing']
paused = False
try:
    if not status()['expanded']:
        toggle()
    # Current internal display: logical center x=768; ydotool y=15 targets its top edge.
    call('ydotool', 'mousemove', '--absolute', '-x', '768', '-y', '15')
    time.sleep(0.2)
    assert status()['hovered']
    call('playerctl', '-p', players[0], 'pause')
    paused = True
    time.sleep(0.3)
    assert status()['expanded'], 'Playback interruption must not collapse the panel'
    call('playerctl', '-p', players[0], 'play')
    paused = False
    time.sleep(4.4)
    assert status()['expanded'], 'Pointer over the notch must keep it open'
    call('ydotool', 'mousemove', '--absolute', '-x', '768', '-y', '300')
    time.sleep(4.4)
    assert not status()['expanded'], 'Leaving the notch must restore auto-close'
finally:
    if paused:
        call('playerctl', '-p', players[0], 'play')
    if status()['expanded']:
        toggle()
print('OK: interrupción de reproducción, permanencia con puntero y cierre al salir.')
