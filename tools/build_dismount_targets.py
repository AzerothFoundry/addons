"""Generate local target metadata from the user's own 1.12 DBCs; never publish output."""
import argparse
import json
from pathlib import Path
import struct


def dbc(path, fields=None):
    raw=Path(path).read_bytes()
    if raw[:4]!=b'WDBC':raise ValueError('not a WDBC file')
    n,f,size,length=struct.unpack_from('<4I',raw,4)
    if (fields is not None and f!=fields) or size!=f*4 or len(raw)!=20+n*size+length:
        raise ValueError('unexpected DBC layout/length')
    return [struct.unpack_from('<'+'I'*f,raw,20+i*size) for i in range(n)],raw[20+n*size:]


def text(strings,offset):
    return strings[offset:strings.index(b'\0',offset)].decode('utf-8')


def build(rows,strings,creatures,cstrings):
    candidates={}
    for row in rows:
        # Trainer teaching records share player-facing names/ranks but are not spellbook casts.
        if row[6] & 0x40 or 36 in row[61:64]:continue
        targets=[(row[82+i],row[85+i]) for i in range(3) if row[61+i]]
        kind=None
        if targets and row[17]==0:
            if all(a==6 and b==0 for a,b in targets):kind='enemy'
            if all(a==21 and b==0 for a,b in targets):kind='friend-other' if row[7] & 0x80000 else 'friend'
            if all(a==1 and b==0 for a,b in targets) and not row[7] & 0x80000:kind='self'
        profile=(kind,row[14]) if kind else None
        for locale in range(8):
            name=text(strings,row[120+locale])
            if not name:continue
            key=name+'\001'+text(strings,row[129+locale])
            candidates.setdefault(key,set()).add(profile)
    spells={k:next(iter(v)) for k,v in candidates.items() if len(v)==1 and None not in v}
    types={}
    for row in creatures:
        if not 1<=row[0]<=32:continue
        for offset in row[1:9]:
            name=text(cstrings,offset)
            if name:types[name]=2**(row[0]-1)
    return spells,types


def quote(value):return json.dumps(value,ensure_ascii=False).replace('\\u0001','\\001')


def write(path,spells,types):
    lines=['-- Generated locally from original 1.12 DBCs; do not commit or redistribute.','AzerothDismountData={spells={']
    for key,(kind,mask) in sorted(spells.items()):lines.append('['+quote(key)+']={kind='+quote(kind)+',creatures='+str(mask)+'},')
    lines+=['},creatures={']
    for key,bit in sorted(types.items()):lines.append('['+quote(key)+']='+str(bit)+',')
    lines+=['}}']
    Path(path).write_text('\n'.join(lines)+'\n')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('spell_dbc',type=Path);p.add_argument('creature_type_dbc',type=Path);p.add_argument('output',type=Path)
    a=p.parse_args();rows,strings=dbc(a.spell_dbc,173);creatures,cstrings=dbc(a.creature_type_dbc)
    spells,types=build(rows,strings,creatures,cstrings);write(a.output,spells,types)
    print('Generated',len(spells),'unambiguous direct-target spell profiles;',len(types),'localized creature types; local use only.')
