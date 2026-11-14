"""Exercise actual coordinate hit testing with the operator's installed Bagnon."""
from pathlib import Path
import os, re, shutil, subprocess, tempfile

root = Path(__file__).resolve().parents[1]
installed = Path(os.environ['BAGNON_ADDONS'])
harness = os.environ['ADDON_HARNESS']
setup = '''Bagnon:Show();AzerothConvenience.AttachSortButton();
SortClicks=0;local start=AzerothConvenience.StartSort
AzerothConvenience.StartSort=function() SortClicks=SortClicks+1;start() end
return "hit fixture ready"'''

def run(folder, steps):
    result = subprocess.run([harness, str(folder), '--probe', 'AzerothConvenience', *steps],
                            env=os.environ.copy(), capture_output=True, text=True, timeout=60)
    text = result.stdout + result.stderr
    assert result.returncode == 0 and 'load errors: 0' in text and 'session errors: 0' in text and 'ERROR:' not in text, text
    return text

with tempfile.TemporaryDirectory(prefix='bag-sort-hit-') as scratch:
    folder = Path(scratch) / 'AddOns'
    folder.mkdir()
    for addon in installed.iterdir():
        if addon.is_dir() and addon.name != 'AzerothConvenience':
            (folder / addon.name).symlink_to(addon, target_is_directory=True)
    shutil.copytree(root / 'AddOns/AzerothConvenience', folder / 'AzerothConvenience')
    toc = folder / 'AzerothConvenience/AzerothConvenience.toc'
    toc.write_text('## Dependencies: Bagnon\n' + toc.read_text())
    geometry = run(folder, ['--eval', setup, '--tick', '.3', '--eval', '''local b=AzerothConvenience.sortButton
return string.format("SORT_RECT %.5f %.5f %.5f %.5f",b:GetLeft(),b:GetBottom(),b:GetWidth(),b:GetHeight())'''])
    match = re.search(r'SORT_RECT ([\d.]+) ([\d.]+) ([\d.]+) ([\d.]+)', geometry)
    assert match, geometry
    left, bottom, width, height = map(float, match.groups())
    points = [(left+width/2, bottom+height/2), (left+3,bottom+3),
              (left+width-3,bottom+3), (left+3,bottom+height-3),
              (left+width-3,bottom+height-3)]
    steps = ['--eval', setup, '--tick', '.3']
    clicks = 0
    for x, y in points:
        clicks += 1
        point = f'{x:.3f},{y:.3f}'
        steps += ['--mouse', point, '--eval', 'assert(GetMouseFocus()==AzerothConvenience.sortButton);return "sort receives pointer"',
                  '--click', point, '--eval', f'assert(SortClicks=={clicks});return "sort receives click {clicks}"']
    center = f'{points[0][0]:.3f},{points[0][1]:.3f}'
    for strata in ['LOW', 'MEDIUM', 'HIGH']:
        clicks += 1
        steps += ['--eval', f'Bagnon:SetFrameStrata("{strata}");BagnonTitle:SetFrameLevel(20);AzerothConvenience.AttachSortButton();return "layer changed"',
                  '--mouse', center, '--eval', 'assert(GetMouseFocus()==AzerothConvenience.sortButton);return "sort remains above title"',
                  '--click', center, '--eval', f'assert(SortClicks=={clicks});return "sort receives click {clicks}"']
    steps += ['--mouse', f'{left-10:.3f},{bottom+height/2:.3f}',
              '--eval', 'assert(GetMouseFocus()==BagnonTitle);return "adjacent title remains interactive"']
    print(run(folder, steps))
    print(f'PASS: {clicks} coordinate clicks, five button points, three strata, raised title, adjacent title preserved')
