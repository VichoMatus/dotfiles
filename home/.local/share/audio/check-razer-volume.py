"""Verify software volume and keyboard path while muted, then restore previous state."""
import json
import subprocess
import time

def call(*args):
    return subprocess.check_output(args, text=True, stderr=subprocess.DEVNULL).strip()

def device():
    name = call('pactl', 'get-default-sink')
    assert name.startswith('alsa_output.usb-1532_Razer_BlackShark_V2_Pro_2.4_'), 'Select the Razer output first'
    return next(s for s in json.loads(call('pactl', '--format=json', 'list', 'sinks')) if s['name'] == name)

before = device()
name = before['name']
original = before['volume']['front-left']['value']
try:
    call('pactl', 'set-sink-mute', name, '1')
    assert 'HW_VOLUME_CTRL' not in device()['flags']
    for percent in [15, 20, 25, 30]:
        call('pactl', 'set-sink-volume', name, str(percent) + '%')
        time.sleep(0.15)
        actual = device()['volume']['front-left']['value'] / 65536
        assert abs(actual - percent / 100) < 0.015
    call('pactl', 'set-sink-volume', name, '20%')
    time.sleep(0.2)
    call('qs', 'ipc', '-c', 'inir', 'call', 'audio', 'volumeUp')
    time.sleep(0.3)
    actual = device()['volume']['front-left']['value'] / 65536
    assert actual > 0.205, actual
finally:
    call('pactl', 'set-sink-volume', name, str(original))
    call('pactl', 'set-sink-mute', name, '1' if before['mute'] else '0')
print('OK: mezcla por software, niveles 15–30 % y tecla de subir por encima del 20 %; estado restaurado.')
