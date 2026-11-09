from pathlib import Path
import json,struct,sys

def dbc(path):
 b=Path(path).read_bytes();assert b[:4]==b'WDBC';n,f,r,s=struct.unpack_from('<4I',b,4)
 return [struct.unpack_from('<'+str(f)+'I',b,20+i*r) for i in range(n)],b[20+n*r:]
rows,_=dbc(sys.argv[1]);tabs,strings=dbc(sys.argv[2]);spells={r['id']:r for r in json.loads(Path(sys.argv[3]).read_text())}
out=Path(sys.argv[4])
def lua(value):
 if isinstance(value,str):return json.dumps(value,ensure_ascii=False)
 if isinstance(value,(int,float)):return str(value)
 if isinstance(value,list):return '{'+','.join(lua(v) for v in value)+'}'
 if isinstance(value,dict):return '{'+','.join('['+lua(k)+']='+lua(v) for k,v in value.items())+'}'
 raise TypeError(type(value))
result={}
for tab in tabs:
 if not tab[12]:continue
 bg=strings[tab[14]:].split(b'\0')[0].decode();mine=[r for r in rows if r[1]==tab[0]];indices={r[0]:i+1 for i,r in enumerate(mine)}
 nodes=[]
 for row in mine:
  ranks=[n for n in row[4:9] if n];req=[]
  for i in range(3):
   if row[13+i]:req.append([indices[row[13+i]],row[16+i]+1])
  nodes.append({'row':row[2]+1,'col':row[3]+1,'max':len(ranks),'req':req,'desc':[spells.get(n,{}).get('effect','') for n in ranks]})
 result[bg]=nodes
out.write_text('-- Generated from the installed original 1.12 talent data; do not commit game data.\nAzerothTalentData='+lua(result)+'\n')
print('Generated',len(result),'original talent trees')
