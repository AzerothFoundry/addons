"""Run the module fixture with the client's Lua 5.0 semantics, without starting a client."""
from pathlib import Path
import argparse
import json
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--source', type=Path, default=ROOT / 'AddOns/AzerothTalentPreview/AzerothTalentPreview.lua')
args = parser.parse_args()
workspace = next((p for p in ROOT.parents if (p / 'benilla/crates/benilla-lua/Cargo.toml').exists()), None)
if workspace is None:
    raise SystemExit('Provide the benilla sibling checkout to verify Lua 5.0 loop-capture semantics.')
# A disposable harness depends on the existing interpreter; no client source is modified.
with tempfile.TemporaryDirectory(prefix='talent-native-vm-') as temp:
    project = Path(temp)
    (project / 'src').mkdir()
    dependency = str(workspace / 'benilla/crates/benilla-lua')
    (project / 'Cargo.toml').write_text('[package]\nname="talent-native-vm-test"\nversion="0.1.0"\nedition="2021"\n[dependencies]\nbenilla-lua={path=' + json.dumps(dependency) + '}\n')
    (project / 'src/main.rs').write_text(r'''
fn main() {
 let mut args=std::env::args().skip(1);
 let harness=std::fs::read_to_string(args.next().expect("harness")).unwrap();
 let addon=std::fs::read_to_string(args.next().expect("addon")).unwrap();
 // Host shims use modern Lua syntax; the actual addon runs unchanged in the client VM.
 let harness=harness.lines().filter(|l| !l.starts_with("table.getn =") && !l.starts_with("local source =") && !l.starts_with("print(")).collect::<Vec<_>>().join("\n");
 let script=format!("_G=getfenv(0)\n{}\nreturn 'PASS: client Lua VM talent callbacks'",harness.replace("dofile(source)",&addon));
 let mut vm=benilla_lua::new_state();
 match vm.exec(script.as_bytes(),b"=talent-regression") {
  Ok(v)=>for x in v {println!("{}",vm.display(x));},
  Err(e)=>{eprintln!("{}",vm.display(e));std::process::exit(1);}
 }
}
''')
    subprocess.run(['cargo', 'run', '--offline', '--quiet', '--manifest-path', str(project / 'Cargo.toml'), '--target-dir', str(Path(tempfile.gettempdir()) / 'talent-native-vm-target'), '--', str(ROOT / 'tests/verify_talent_preview.lua'), str(args.source.resolve())], check=True)
