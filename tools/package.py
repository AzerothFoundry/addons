"""Package only owned source with empty local-data placeholders; never fetch third parties."""
from pathlib import Path
import hashlib, zipfile
root = Path(__file__).resolve().parents[1]
for relative, variable in [('AzerothSpellID/SpellNames.lua', 'AzerothSpellIDNames'), ('AzerothTalentPreview/TalentData.lua', 'AzerothTalentData')]:
    expected = '-- Empty source placeholder. Generate locally from your own game data; never commit generated content.\n' + variable + ' = {}\n'
    if (root/'AddOns'/relative).read_text() != expected:
        raise SystemExit('Refusing public source package with generated game data: ' + relative)
out = root/'dist'; out.mkdir(exist_ok=True)
archive = out/'addons-source-preview.zip'
with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as z:
    for f in sorted((root/'AddOns').rglob('*')):
        if f.is_file(): z.write(f, f.relative_to(root))
    z.write(root/'README.md', 'README.md')
(out/'SHA256SUMS').write_text(hashlib.sha256(archive.read_bytes()).hexdigest() + '  ' + archive.name + '\n')
print('Built source preview only; third-party plugins and local game lookup data are excluded.')
