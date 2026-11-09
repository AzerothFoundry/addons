"""Build local tooltip lookup from user-supplied 1.12 Spell.dbc files.

Generated game-data names stay out of Git. All same-name/rank IDs are retained;
the addon labels ambiguity rather than choosing an unrelated NPC spell.
"""
import argparse
import json
import struct
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("output", type=Path)
parser.add_argument("dbc", type=Path, nargs="+")
args = parser.parse_args()
names = {}
for path in args.dbc:
    data = path.read_bytes()
    assert data[:4] == b"WDBC", path
    count, fields, size, strings_size = struct.unpack_from("<4I", data, 4)
    assert fields == 173 and size == fields * 4, "Expected original 1.12 Spell.dbc"
    start = 20 + count * size
    assert start + strings_size == len(data), "Truncated DBC"
    strings = data[start:]

    def string(offset):
        assert offset < strings_size
        return strings[offset:strings.index(b"\0", offset)].decode("utf-8")

    for i in range(count):
        row = struct.unpack_from("<173I", data, 20 + i * size)
        for locale in range(8):
            name = string(row[120 + locale])
            if not name:
                continue
            rank = string(row[129 + locale])
            names.setdefault(name + "\x01" + rank, set()).add(row[0])

args.output.parent.mkdir(parents=True, exist_ok=True)
with args.output.open("w") as out:
    out.write("-- Generated from the installed 1.12 client. Do not commit game data.\nAzerothSpellIDNames = {\n")
    for key, ids in sorted(names.items()):
        literal = json.dumps(key, ensure_ascii=False).replace("\\u0001", "\\001")
        out.write("[" + literal + "]={" + ",".join(map(str, sorted(ids))) + "},\n")
    out.write("}\n")
print(f"Generated {len(names)} localized name/rank keys")
