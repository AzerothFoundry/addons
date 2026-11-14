use benilla_ui::script::{UiScript,ItemTemplateView,ContainerSlot,ContainerState};
use std::collections::HashMap;
fn session()->UiScript{
 let mut s=UiScript::new().unwrap();s.keep_calls();
 s.run("SlashCmdList={}; UIParent=CreateFrame('Frame','UIParent'); DEFAULT_CHAT_FRAME={AddMessage=function() end}").unwrap();
 for (id,name,stack) in [(6948,"Hearthstone",1),(2589,"Linen Cloth",20)] {
  s.set_item_template(id,ItemTemplateView{name:name.into(),quality:1,stackable:stack,..Default::default()});
 }
 let mut slots=HashMap::new();
 for (slot,id,name,count) in [(1,6948,"Hearthstone",1),(5,2589,"Linen Cloth",12)] {
  slots.insert(slot,ContainerSlot{item_id:id,guid:id as u64,count,quality:Some(1),link:Some(format!("|cffffffff|Hitem:{id}:0:0:0|h[{name}]|h|r")),..Default::default()});
 }
 s.set_container(0,Some(ContainerState{name:None,num_slots:16,slots}));
 s.run(include_str!(env!("CONVENIENCE_MAIN"))).unwrap();
 s.run(include_str!(env!("CONVENIENCE_SORT"))).unwrap();
 s
}
fn main(){
 let mut s=session();
 s.run("local link=GetContainerItemLink(0,1); assert(GetItemInfo(6948)=='Hearthstone'); assert(GetItemInfo(link)==nil); assert(AzerothConvenience.ItemInfo(link)=='Hearthstone'); local slots=AzerothConvenience.SortSnapshot(); assert(slots and table.getn(slots)==16); AzerothConvenience.StartSort(); AzerothConvenience.SortStep(.2); assert(AzerothConvenience.sort.moves==1 and not CursorHasItem())").unwrap();
 let moves=s.take_container_moves();assert_eq!(moves.len(),1);assert_eq!((moves[0].src_bag,moves[0].src_slot,moves[0].dst_bag,moves[0].dst_slot),(0,5,0,2));
 let mut fixed=session();fixed.lock_item(6948);
 fixed.run("AzerothConvenience.StartSort();AzerothConvenience.SortStep(.2);assert(AzerothConvenience.sort.moves==1 and not CursorHasItem());assert(AzerothConvenience.ItemInfo(GetContainerItemLink(0,1))=='Hearthstone')").unwrap();
 let fixed_moves=fixed.take_container_moves();assert_eq!(fixed_moves.len(),1);assert_eq!((fixed_moves[0].src_bag,fixed_moves[0].src_slot,fixed_moves[0].dst_bag,fixed_moves[0].dst_slot),(0,5,0,2));assert!(fixed.item_locked(6948));
 println!("PASS native lock: locked slot remains untouched and locked while a different native move is queued");
 println!("PASS native API: cached ID resolves, full hyperlink fails, normalized link resolves, full snapshot builds, native move 0:5 -> 0:2 queued");
}
