"""Run with: python ~/.local/share/modo-tele/test_modo_tele.py"""
import json
from pathlib import Path
import runpy
import tempfile
from types import SimpleNamespace
from unittest.mock import patch

home = Path.home()
ns = runpy.run_path(str(home / '.local/bin/modo-tele'))
scope = ns['activate'].__globals__
original = json.loads((home / '.config/inir/config.json').read_text())
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    config = root / 'config.json'
    animations = root / 'animations.kdl'
    snapshot = root / 'restore.json'
    config.write_text(json.dumps(original))
    animations.write_text('animations {\n slowdown 1.2\n}\n')
    scope.update(STATE=root, CONFIG=config, ANIMATIONS=animations, SNAPSHOT=snapshot)
    scope['run'] = lambda *args, **kw: SimpleNamespace(returncode=int('is-active' in args))
    ns['activate']()
    assert snapshot.exists()
    assert json.loads(config.read_text())['idle']['onBattery']['suspendTimeout'] == 0
    assert 'off // Modo Tele' in animations.read_text()
    ns['activate']()
    changed = json.loads(config.read_text())
    changed['resources']['autoStopDelay'] = 12345
    config.write_text(json.dumps(changed))
    ns['deactivate']()
    restored = json.loads(config.read_text())
    assert restored['resources'].pop('autoStopDelay') == 12345
    assert restored == original
    assert not snapshot.exists()
    assert animations.read_text() == 'animations {\n slowdown 1.2\n}\n'
    ns['deactivate']()

profile = runpy.run_path(str(home / '.local/bin/power-profile-auto'))['desired_profile']
with patch.object(Path, 'exists', return_value=True):
    assert profile(True) == profile(False) == 'power-saver'
with patch.object(Path, 'exists', return_value=False):
    assert profile(True) == 'balanced'
    assert profile(False) == 'performance'
print('OK: Tele, restauración, repetición y prioridad de perfiles.')
