"""Checks the battery menu's profile selection and restores the previous profile."""
import subprocess
import time

def call(*args):
    return subprocess.check_output(args, text=True).strip()

def menu(action, *args):
    return call('qs', 'ipc', '-c', 'inir', 'call', 'notch-battery-menu', action, *args)

previous = call('powerprofilesctl', 'get')
call('qs', 'ipc', '-c', 'inir', 'call', 'notch-eDP-1', 'menu', 'battery')
time.sleep(0.3)
try:
    assert menu('choose', 'power-saver') == 'true'
    assert call('powerprofilesctl', 'get') == 'power-saver'
    assert menu('choose', 'invalid') == 'false'
finally:
    menu('choose', previous)
    menu('close')
assert call('powerprofilesctl', 'get') == previous
print('OK: ahorro, rechazo de perfil inválido y restauración.')
