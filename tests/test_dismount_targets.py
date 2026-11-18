import importlib.util
from pathlib import Path
import struct
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('targets',ROOT/'tools/build_dismount_targets.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)

class TargetProfilesTest(unittest.TestCase):
    def setUp(self):self.strings=bytearray(b'\0')
    def string(self,value):
        offset=len(self.strings);self.strings.extend(value.encode()+b'\0');return offset
    def row(self,kind=6,name='Fire',rank='Rank 1',effect=2):
        r=[0]*173;r[61]=effect;r[82]=kind;r[124]=self.string(name);r[133]=self.string(rank);return r
    def build(self,rows):return m.build(rows,bytes(self.strings),[],b'\0')[0]
    def test_direct_enemy_and_friend_separate(self):
        profiles=self.build([self.row(),self.row(21,'Heal')])
        self.assertEqual(profiles['Fire\001Rank 1'],('enemy',0))
        self.assertEqual(profiles['Heal\001Rank 1'],('friend',0))
    def test_conflicting_castable_profiles_rejected(self):
        self.assertNotIn('Fire\001Rank 1',self.build([self.row(),self.row(21)]))
    def test_training_records_do_not_shadow_actual_spellbook_cast(self):
        self.assertEqual(self.build([self.row(),self.row(1,effect=36)])['Fire\001Rank 1'],('enemy',0))
    def test_unknown_and_target_aura_requirements_fail_closed(self):
        aura=self.row(name='Execute');aura[17]=2
        self.assertEqual(self.build([self.row(1),aura]),{})
    def test_creature_restriction_preserved(self):
        row=self.row();row[14]=193
        self.assertEqual(self.build([row])['Fire\001Rank 1'],('enemy',193))
    def test_wrong_dbc_layout_rejected(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/'Spell.dbc';p.write_bytes(b'WDBC'+struct.pack('<4I',1,172,688,1)+b'\0'*689)
            with self.assertRaisesRegex(ValueError,'layout'):m.dbc(p,173)

if __name__=='__main__':unittest.main()
