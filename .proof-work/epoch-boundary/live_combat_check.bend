import Base
import ./main.bend as Application
import ./world.bend as W
import ./live_combat.bend as Fight
import ./combat.bend as Combat
import ./battle.bend as Battle
import ./terrain.bend as Terrain
import ./simulation.bend as S
import ./players.bend as P
import ./monsters.bend as M
import ./payouts.bend as Pay
import ./data.bend as Data
import ./compat.bend as C
import ./support.bend as Support
import ./players_check.bend as Test
import ./combat_check.bend as CT
import ./rebuild_check.bend as Old

law Previous.cmd_spin:
  (@+w_0: W.Bq.World -> (@+pid_1: U32 -> C.Bq.Pair.Pair(W.Bq.World, (__2 => List<&1, W.Bq.OutL>))))

law Previous.cmd_atk:
  (@+w_0: W.Bq.World -> (@+pid_1: U32 -> C.Bq.Pair.Pair(W.Bq.World, (__2 => List<&1, W.Bq.OutL>))))

@unsafe
def Previous.battle_world(maps: List<&2,List<&2,U32>>,result: Battle.Battle.Result) -> C.Bq.Pair.Pair(W.Bq.World,(world => List<&1,W.Bq.OutL>)):
  match result:
    case Battle.Battle.Result{state,notices}:
      match state:
        case S.Simulation.State{meta,players,monsters}: Tuple{Terrain.Terrain.World{meta,players,monsters,maps},W.Bq.battle_notices(notices)}

@unsafe
def Previous.spin_finished(zone: U32,x: U32,y: U32,result: Sigma<&1,&1,W.Bq.World,(world => List<&1,W.Bq.OutL>)>) -> Sigma<&1,&1,W.Bq.World,(world => List<&1,W.Bq.OutL>)>:
  match result:
    case Tuple{updated,outs}: Tuple{updated,Con{W.Bq.fx(zone,1,x,y),outs}}

@unsafe
def Previous.spin_admitted(+wm: W.Bq.WMeta,+mobs: List<&2,W.Bq.Mob>,maps: List<&2,List<&2,U32>>,+pid: U32,+result: Combat.Combat.Result) -> Sigma<&1,&1,W.Bq.World,(world => List<&1,W.Bq.OutL>)>:
  match result:
    case Combat.Combat.Result{players,attacker}:
      match attacker:
        case None{}:
          Previous.battle_world(maps,Battle.Battle.execute(wm,mobs,Combat.Combat.Result{players,None{}},Nil{},pid,Data.Bq.MQ_SCORE_SIGIL))
        case Some{player}:
          match player:
            case P.Players.State{actor_id,cid,hero,pos,vitals,style,quest,meta}:
              match pos:
                case P.Players.Pos{zone,x,y,dir,moving}:
                  +plans = W.Bq.battle_spin_inputs(W.Bq.mids_in_reach(mobs,zone,x,y),mobs,hero,wm)
                  +actor = {P.Players.State{actor_id,cid,hero,P.Players.Pos{zone,x,y,dir,moving},vitals,style,quest,meta} : P.Players.State}
                  Previous.spin_finished(zone,x,y,Previous.battle_world(maps,Battle.Battle.execute(wm,mobs,Combat.Combat.Result{players,Some{actor}},plans,pid,Data.Bq.MQ_SCORE_SIGIL)))

@unsafe
def Previous.cmd_spin(world,pid):
  match world:
    case Terrain.Terrain.World{wm,players,mobs,maps}:
      Previous.spin_admitted(wm,mobs,maps,pid,Combat.Combat.run(players,pid,Combat.Combat.Spin{},W.Bq.wm_phase(wm)))

@unsafe
def Previous.attack_finished(zone: U32,x: U32,y: U32,dir: U32,mid: U32,crit: U32,result: Sigma<&1,&1,W.Bq.World,(world => List<&1,W.Bq.OutL>)>) -> Sigma<&1,&1,W.Bq.World,(world => List<&1,W.Bq.OutL>)>:
  match result:
    case Tuple{final,outs}: Tuple{final,Support.Bq.List.concat(W.Bq.OutL,W.Bq.atk_fx(zone,x,y,dir,mid,crit),outs)}

@unsafe
def Previous.attack_admitted(+wm: W.Bq.WMeta,+mobs: List<&2,W.Bq.Mob>,maps: List<&2,List<&2,U32>>,+pid: U32,+result: Combat.Combat.Result) -> Sigma<&1,&1,W.Bq.World,(world => List<&1,W.Bq.OutL>)>:
  match result:
    case Combat.Combat.Result{players,attacker}:
      match attacker:
        case None{}:
          Previous.battle_world(maps,Battle.Battle.execute(wm,mobs,Combat.Combat.Result{players,None{}},Nil{},pid,Data.Bq.MQ_SCORE_SIGIL))
        case Some{player}:
          match player:
            case P.Players.State{actor_id,cid,hero,pos,vitals,style,quest,meta}:
              match pos:
                case P.Players.Pos{zone,x,y,dir,moving}:
                  +mid = W.Bq.mob_in_reach(mobs,zone,x,y)
                  +crit = C.Bq.bit(U32.is_lt(U32.mod(W.Bq.hash2(W.Bq.wm_tick(wm),U32.add(U32.mul(pid,7),3)),100),W.Bq.hero_crit(hero)))
                  +damage = W.Bq.plr_hit(hero,W.Bq.mob_df_at(mobs,mid),crit)
                  +actor = {P.Players.State{actor_id,cid,hero,P.Players.Pos{zone,x,y,dir,moving},vitals,style,quest,meta} : P.Players.State}
                  Previous.attack_finished(zone,x,y,dir,mid,crit,Previous.battle_world(maps,Battle.Battle.execute(wm,mobs,Combat.Combat.Result{players,Some{actor}},[W.Bq.battle_input(mobs,mid,damage,wm)],pid,Data.Bq.MQ_SCORE_SIGIL)))

@unsafe
def Previous.cmd_atk(world,pid):
  match world:
    case Terrain.Terrain.World{wm,players,mobs,maps}:
      Previous.attack_admitted(wm,mobs,maps,pid,Combat.Combat.run(players,pid,Combat.Combat.Attack{},W.Bq.wm_phase(wm)))

def Output.same_line(a: List<&1,Char>,b: List<&1,Char>) -> Bool: Test.same_name(P.Players.share_name(a),P.Players.share_name(b))

def Output.same_out(a: W.Bq.OutL,b: W.Bq.OutL) -> Bool:
  match a:
    case W.Bq.OutL.All{line}:
      match b:
        case W.Bq.OutL.All{other_line}: Output.same_line(line,other_line)
        case W.Bq.OutL.To{other_cid,other_line}: False{}
        case W.Bq.OutL.ZoneL{other_zone,other_line}: False{}
        case W.Bq.OutL.Log{other_line}: False{}
    case W.Bq.OutL.To{cid,line}:
      match b:
        case W.Bq.OutL.All{other_line}: False{}
        case W.Bq.OutL.To{other_cid,other_line}: Bool.and(U32.is_eq(cid,other_cid),Output.same_line(line,other_line))
        case W.Bq.OutL.ZoneL{other_zone,other_line}: False{}
        case W.Bq.OutL.Log{other_line}: False{}
    case W.Bq.OutL.ZoneL{zone,line}:
      match b:
        case W.Bq.OutL.All{other_line}: False{}
        case W.Bq.OutL.To{other_cid,other_line}: False{}
        case W.Bq.OutL.ZoneL{other_zone,other_line}: Bool.and(U32.is_eq(zone,other_zone),Output.same_line(line,other_line))
        case W.Bq.OutL.Log{other_line}: False{}
    case W.Bq.OutL.Log{line}:
      match b:
        case W.Bq.OutL.All{other_line}: False{}
        case W.Bq.OutL.To{other_cid,other_line}: False{}
        case W.Bq.OutL.ZoneL{other_zone,other_line}: False{}
        case W.Bq.OutL.Log{other_line}: Output.same_line(line,other_line)

def Output.same_outs(a: List<&1,W.Bq.OutL>,b: List<&1,W.Bq.OutL>) -> Bool:
  match a:
    case Nil{}:
      match b:
        case Nil{}: True{}
        case Con{head,rest}: False{}
    case Con{head,rest}:
      match b:
        case Nil{}: False{}
        case Con{other,later}: Bool.and(Output.same_out(head,other),Output.same_outs(rest,later))

def Output.same_result(a: Terrain.Terrain.World & List<&1,W.Bq.OutL>,b: Terrain.Terrain.World & List<&1,W.Bq.OutL>) -> Bool:
  match a:
    case Tuple{world,outs}:
      match b:
        case Tuple{other,lines}: Bool.and(Old.same(world,other),Output.same_outs(outs,lines))

def Output.after(result: Terrain.Terrain.World & List<&1,W.Bq.OutL>) -> Terrain.Terrain.World:
  match result:
    case Tuple{world,outs}: world


@unsafe
def current(kind: Combat.Combat.Kind,world: Terrain.Terrain.World,pid: U32) -> Terrain.Terrain.World & List<&1,W.Bq.OutL>:
  match kind:
    case Combat.Combat.Attack{}: W.Bq.cmd_atk(world,pid)
    case Combat.Combat.Spin{}: W.Bq.cmd_spin(world,pid)

@unsafe
def previous(kind: Combat.Combat.Kind,world: Terrain.Terrain.World,pid: U32) -> Terrain.Terrain.World & List<&1,W.Bq.OutL>:
  match kind:
    case Combat.Combat.Attack{}: Previous.cmd_atk(world,pid)
    case Combat.Combat.Spin{}: Previous.cmd_spin(world,pid)

@unsafe
def checked(label: String,+kind: Combat.Combat.Kind,+world: Terrain.Terrain.World,+pid: U32) -> IO(Unit):
  Test.verdict(label,Output.same_result(current(kind,world,pid),previous(kind,world,pid)))

@unsafe
def twice(label: String,+first: Combat.Combat.Kind,+last: Combat.Combat.Kind,+world: Terrain.Terrain.World,+pid: U32,+next: U32) -> IO(Unit):
  Test.verdict(label,Bool.and(Output.same_result(current(first,world,pid),previous(first,world,pid)),Output.same_result(current(last,Output.after(current(first,world,pid)),next),previous(last,Output.after(previous(first,world,pid)),next))))

def creature(mid: U32,kind: U32,rare: U32,zone: U32,x: U32,y: U32,hp: U32,dead: U32) -> M.Monsters.State:
  M.Monsters.State{mid,kind,rare,zone,x,y,hp,10000,0,0,dead,10}

def malicious(ready: Fight.LiveCombat.Ready) -> Fight.LiveCombat.Plan:
  Fight.LiveCombat.Plan{[Battle.Battle.Input{7,4294967295,Pay.Payout.Plan{9,0,999,999,0,0,0,0,0,0,0}}],Fight.LiveCombat.Spin{3,99,99}}

@unsafe
def rejected(label: String,+kind: Combat.Combat.Kind,+world: Terrain.Terrain.World,+pid: U32) -> IO(Unit):
  Test.verdict(label,Output.same_result(Fight.LiveCombat.emit(W.Bq.OutL,Fight.LiveCombat.run(world,kind,pid,Data.Bq.MQ_SCORE_SIGIL,malicious),W.Bq.render_combat),previous(kind,world,pid)))

@unsafe
def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- checked("live combat attack ready",Combat.Combat.Attack{},CT.fixture_world([CT.fixture_player(2,0,0,0)],CT.fixture_mobs,1),2)
    Unit <- checked("live combat attack dead",Combat.Combat.Attack{},CT.fixture_world([CT.fixture_player(2,1,0,0)],CT.fixture_mobs,1),2)
    Unit <- checked("live combat attack cooling",Combat.Combat.Attack{},CT.fixture_world([CT.fixture_player(2,0,1,1)],CT.fixture_mobs,1),2)
    Unit <- checked("live combat attack MAX cooldown",Combat.Combat.Attack{},CT.fixture_world([CT.fixture_player(2,0,4294967295,4294967295)],CT.fixture_mobs,1),2)
    Unit <- checked("live combat attack inactive",Combat.Combat.Attack{},CT.fixture_world([CT.fixture_player(2,0,0,0)],CT.fixture_mobs,0),2)
    Unit <- checked("live combat attack ended",Combat.Combat.Attack{},CT.fixture_world([CT.fixture_player(2,0,0,0)],CT.fixture_mobs,2),2)
    Unit <- checked("live combat attack unknown phase",Combat.Combat.Attack{},CT.fixture_world([CT.fixture_player(2,0,0,0)],CT.fixture_mobs,4294967295),2)
    Unit <- checked("live combat attack missing",Combat.Combat.Attack{},CT.fixture_world([CT.fixture_player(2,0,0,0)],CT.fixture_mobs,1),99)
    Unit <- checked("live combat attack empty roster",Combat.Combat.Attack{},CT.fixture_world([],CT.fixture_mobs,1),2)
    Unit <- checked("live combat attack empty monsters",Combat.Combat.Attack{},CT.fixture_world([CT.fixture_player(2,0,0,0)],[],1),2)
    Unit <- checked("live combat attack multiplayer",Combat.Combat.Attack{},CT.fixture_world([CT.fixture_player(1,0,7,9),CT.fixture_player(2,0,0,0)],CT.fixture_mobs,1),2)
    Unit <- checked("live combat attack duplicate player lookup",Combat.Combat.Attack{},CT.fixture_world([CT.fixture_player(2,0,0,0),CT.fixture_player(2,0,7,9)],CT.fixture_mobs,1),2)
    Unit <- checked("live combat attack wrong zone",Combat.Combat.Attack{},CT.fixture_world([CT.fixture_player(2,0,0,0)],[creature(7,0,0,1,6,4,10000,0)],1),2)
    Unit <- checked("live combat attack out of range",Combat.Combat.Attack{},CT.fixture_world([CT.fixture_player(2,0,0,0)],[creature(7,0,0,0,8,4,10000,0)],1),2)
    Unit <- checked("live combat attack dead target",Combat.Combat.Attack{},CT.fixture_world([CT.fixture_player(2,0,0,0)],[creature(7,0,0,0,6,4,0,1)],1),2)
    Unit <- checked("live combat attack MAX coordinate",Combat.Combat.Attack{},CT.fixture_world([CT.fixture_player(2,0,0,0)],[creature(7,0,0,0,4294967295,4,10000,0)],1),2)
    Unit <- checked("live combat attack diagonal",Combat.Combat.Attack{},CT.fixture_world([CT.fixture_player(2,0,0,0)],[creature(7,0,0,0,7,5,10000,0)],1),2)
    Unit <- checked("live combat attack lethal ordinary",Combat.Combat.Attack{},CT.fixture_world([CT.fixture_player(2,0,0,0)],[creature(7,0,0,0,6,4,1,0)],1),2)
    Unit <- checked("live combat attack lethal rare",Combat.Combat.Attack{},CT.fixture_world([CT.fixture_player(2,0,0,0)],[creature(7,2,1,0,6,4,1,0)],1),2)
    Unit <- checked("live combat attack first warden",Combat.Combat.Attack{},CT.fixture_world([CT.fixture_player(2,0,0,0)],[creature(7,6,0,0,6,4,1,0)],1),2)
    Unit <- checked("live combat attack final boss",Combat.Combat.Attack{},CT.fixture_world([CT.fixture_player(2,0,0,0)],[creature(7,9,0,0,6,4,1,0)],1),2)
    Unit <- checked("live combat attack two kills",Combat.Combat.Attack{},CT.fixture_world([CT.fixture_player(2,0,0,0)],[creature(7,0,0,0,6,4,1,0),creature(8,1,0,0,7,4,1,0)],1),2)
    Unit <- checked("live combat attack boss then warden",Combat.Combat.Attack{},CT.fixture_world([CT.fixture_player(2,0,0,0)],[creature(7,9,0,0,6,4,1,0),creature(8,6,0,0,7,4,1,0)],1),2)
    Unit <- checked("live combat attack dead before live",Combat.Combat.Attack{},CT.fixture_world([CT.fixture_player(2,0,0,0)],[creature(7,0,0,0,6,4,0,1),creature(8,0,0,0,7,4,10000,0)],1),2)
    Unit <- checked("live combat attack reversed targets",Combat.Combat.Attack{},CT.fixture_world([CT.fixture_player(2,0,0,0)],[creature(8,0,0,0,7,4,10000,0),creature(7,0,0,0,6,4,10000,0)],1),2)
    Unit <- checked("live combat spin ready",Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,0)],CT.fixture_mobs,1),2)
    Unit <- checked("live combat spin dead",Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,1,0,0)],CT.fixture_mobs,1),2)
    Unit <- checked("live combat spin cooling",Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,1,1)],CT.fixture_mobs,1),2)
    Unit <- checked("live combat spin MAX cooldown",Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,4294967295,4294967295)],CT.fixture_mobs,1),2)
    Unit <- checked("live combat spin inactive",Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,0)],CT.fixture_mobs,0),2)
    Unit <- checked("live combat spin ended",Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,0)],CT.fixture_mobs,2),2)
    Unit <- checked("live combat spin unknown phase",Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,0)],CT.fixture_mobs,4294967295),2)
    Unit <- checked("live combat spin missing",Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,0)],CT.fixture_mobs,1),99)
    Unit <- checked("live combat spin empty roster",Combat.Combat.Spin{},CT.fixture_world([],CT.fixture_mobs,1),2)
    Unit <- checked("live combat spin empty monsters",Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,0)],[],1),2)
    Unit <- checked("live combat spin multiplayer",Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(1,0,7,9),CT.fixture_player(2,0,0,0)],CT.fixture_mobs,1),2)
    Unit <- checked("live combat spin duplicate player lookup",Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,0),CT.fixture_player(2,0,7,9)],CT.fixture_mobs,1),2)
    Unit <- checked("live combat spin wrong zone",Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,0)],[creature(7,0,0,1,6,4,10000,0)],1),2)
    Unit <- checked("live combat spin out of range",Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,0)],[creature(7,0,0,0,8,4,10000,0)],1),2)
    Unit <- checked("live combat spin dead target",Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,0)],[creature(7,0,0,0,6,4,0,1)],1),2)
    Unit <- checked("live combat spin MAX coordinate",Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,0)],[creature(7,0,0,0,4294967295,4,10000,0)],1),2)
    Unit <- checked("live combat spin diagonal",Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,0)],[creature(7,0,0,0,7,5,10000,0)],1),2)
    Unit <- checked("live combat spin lethal ordinary",Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,0)],[creature(7,0,0,0,6,4,1,0)],1),2)
    Unit <- checked("live combat spin lethal rare",Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,0)],[creature(7,2,1,0,6,4,1,0)],1),2)
    Unit <- checked("live combat spin first warden",Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,0)],[creature(7,6,0,0,6,4,1,0)],1),2)
    Unit <- checked("live combat spin final boss",Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,0)],[creature(7,9,0,0,6,4,1,0)],1),2)
    Unit <- checked("live combat spin two kills",Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,0)],[creature(7,0,0,0,6,4,1,0),creature(8,1,0,0,7,4,1,0)],1),2)
    Unit <- checked("live combat spin boss then warden",Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,0)],[creature(7,9,0,0,6,4,1,0),creature(8,6,0,0,7,4,1,0)],1),2)
    Unit <- checked("live combat spin dead before live",Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,0)],[creature(7,0,0,0,6,4,0,1),creature(8,0,0,0,7,4,10000,0)],1),2)
    Unit <- checked("live combat spin reversed targets",Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,0)],[creature(8,0,0,0,7,4,10000,0),creature(7,0,0,0,6,4,10000,0)],1),2)
    Unit <- twice("live combat sequence attack then attack",Combat.Combat.Attack{},Combat.Combat.Attack{},CT.fixture_world([CT.fixture_player(2,0,0,0)],CT.fixture_mobs,1),2,2)
    Unit <- twice("live combat sequence spin then spin",Combat.Combat.Spin{},Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,0)],CT.fixture_mobs,1),2,2)
    Unit <- twice("live combat sequence attack then spin",Combat.Combat.Attack{},Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,0)],CT.fixture_mobs,1),2,2)
    Unit <- twice("live combat sequence spin then attack",Combat.Combat.Spin{},Combat.Combat.Attack{},CT.fixture_world([CT.fixture_player(2,0,0,0)],CT.fixture_mobs,1),2,2)
    Unit <- twice("live combat multiplayer competing attack",Combat.Combat.Attack{},Combat.Combat.Attack{},CT.fixture_world([CT.fixture_player(2,0,0,0),CT.fixture_player(3,0,0,0)],[creature(7,9,0,0,6,4,1,0)],1),2,3)
    Unit <- twice("live combat multiplayer competing spin",Combat.Combat.Spin{},Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,0),CT.fixture_player(3,0,0,0)],[creature(7,9,0,0,6,4,1,0)],1),2,3)
    Unit <- rejected("live combat rejects hostile plan dead",Combat.Combat.Attack{},CT.fixture_world([CT.fixture_player(2,1,0,0)],CT.fixture_mobs,1),2)
    Unit <- rejected("live combat rejects hostile plan cooling",Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,1)],CT.fixture_mobs,1),2)
    Unit <- rejected("live combat rejects hostile plan missing",Combat.Combat.Attack{},CT.fixture_world([CT.fixture_player(2,0,0,0)],CT.fixture_mobs,1),99)
    Unit <- rejected("live combat rejects hostile plan ended",Combat.Combat.Spin{},CT.fixture_world([CT.fixture_player(2,0,0,0)],CT.fixture_mobs,2),2)
    return Unit{}

#| PASS live combat attack ready
#| PASS live combat attack dead
#| PASS live combat attack cooling
#| PASS live combat attack MAX cooldown
#| PASS live combat attack inactive
#| PASS live combat attack ended
#| PASS live combat attack unknown phase
#| PASS live combat attack missing
#| PASS live combat attack empty roster
#| PASS live combat attack empty monsters
#| PASS live combat attack multiplayer
#| PASS live combat attack duplicate player lookup
#| PASS live combat attack wrong zone
#| PASS live combat attack out of range
#| PASS live combat attack dead target
#| PASS live combat attack MAX coordinate
#| PASS live combat attack diagonal
#| PASS live combat attack lethal ordinary
#| PASS live combat attack lethal rare
#| PASS live combat attack first warden
#| PASS live combat attack final boss
#| PASS live combat attack two kills
#| PASS live combat attack boss then warden
#| PASS live combat attack dead before live
#| PASS live combat attack reversed targets
#| PASS live combat spin ready
#| PASS live combat spin dead
#| PASS live combat spin cooling
#| PASS live combat spin MAX cooldown
#| PASS live combat spin inactive
#| PASS live combat spin ended
#| PASS live combat spin unknown phase
#| PASS live combat spin missing
#| PASS live combat spin empty roster
#| PASS live combat spin empty monsters
#| PASS live combat spin multiplayer
#| PASS live combat spin duplicate player lookup
#| PASS live combat spin wrong zone
#| PASS live combat spin out of range
#| PASS live combat spin dead target
#| PASS live combat spin MAX coordinate
#| PASS live combat spin diagonal
#| PASS live combat spin lethal ordinary
#| PASS live combat spin lethal rare
#| PASS live combat spin first warden
#| PASS live combat spin final boss
#| PASS live combat spin two kills
#| PASS live combat spin boss then warden
#| PASS live combat spin dead before live
#| PASS live combat spin reversed targets
#| PASS live combat sequence attack then attack
#| PASS live combat sequence spin then spin
#| PASS live combat sequence attack then spin
#| PASS live combat sequence spin then attack
#| PASS live combat multiplayer competing attack
#| PASS live combat multiplayer competing spin
#| PASS live combat rejects hostile plan dead
#| PASS live combat rejects hostile plan cooling
#| PASS live combat rejects hostile plan missing
#| PASS live combat rejects hostile plan ended
