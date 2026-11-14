"""Run the addon against cached native benilla-ui APIs, without mocking item getters/moves."""
from pathlib import Path
import os, subprocess, tempfile
root = Path(__file__).resolve().parents[1]
deps = Path(os.environ['BENILLA_UI_DEPS'])
lib = max(deps.glob('libbenilla_ui-*.rlib'), key=lambda p: p.stat().st_mtime)
env = dict(os.environ, CONVENIENCE_MAIN=str(root/'AddOns/AzerothConvenience/AzerothConvenience.lua'),
           CONVENIENCE_SORT=str(root/'AddOns/AzerothConvenience/BagSort.lua'))
with tempfile.TemporaryDirectory(prefix='bag-sort-native-') as scratch:
    binary = str(Path(scratch)/'check')
    subprocess.run([os.environ.get('RUSTC','rustc'),'--edition','2021',str(root/'tests/native_convenience_links.rs'),
                    '--extern','benilla_ui='+str(lib),'-L','dependency='+str(deps),'-o',binary], env=env, check=True)
    subprocess.run([binary], check=True)
