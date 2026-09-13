import Base
import ./terrain.bend as Terrain
import ./combat.bend as K
import ./players.bend as P
import ./vitals.bend as V
import ./monsters.bend as M
import ./game.bend as G
import ./world.bend as W
import ./compat.bend as C
import ./simulation.bend as S
import ./players_check.bend as T
import ./simulation_check.bend as ST
import ./ai_check.bend as MT
import ./interactions_check.bend as IT

# Deliberately non-default fields expose accidental profile resets.
def fixture_player(+pid: U32,dead: U32,attack: U32,spin: U32) -> P.Players.State:
  P.Players.State{pid,U32.add(pid,10),G.Bq.fresh_hero,P.Players.Pos{0,6,4,3,1},V.Vitals.State{35,42,dead,7,attack,spin},P.Players.Style{1,2,3,4,5,6},P.Players.Quest{1,7,2,3,4,5},P.Players.Meta{40,8,9,T.name}}

def fixture_meta(phase: U32) -> S.Simulation.Meta: S.Simulation.Meta{phase,7,41,17,100,200,0,19,51,450}
def fixture_monster(mid: U32,zone: U32,x: U32,y: U32,hp: U32,dead: U32) -> M.Monsters.State:
  M.Monsters.State{mid,0,0,zone,x,y,hp,10000,0,0,dead,10}

def fixture_mobs() -> List<&2,M.Monsters.State>: [fixture_monster(7,0,6,5,10000,0),fixture_monster(8,0,7,4,10000,0)]
def fixture_world(players: List<&2,P.Players.State>,monsters: List<&2,M.Monsters.State>,phase: U32) -> W.Bq.World:
  Terrain.Terrain.World{fixture_meta(phase),players,monsters,[[101],[102],[103],[104]]}

def check_step(label: String,actual: K.Combat.Step,expected: P.Players.State,accepted: Bool) -> IO(Unit):
  match actual:
    case K.Combat.Step{player,decision}: T.verdict(label,Bool.and(T.same_player(player,expected),Bool.not(Bool.xor(decision,accepted))))

def check_roster(label: String,actual: K.Combat.Result,expected: List<&2,P.Players.State>,actor: Maybe<&2,P.Players.State>) -> IO(Unit):
  match actual:
    case K.Combat.Result{players,attacker}: T.verdict(label,Bool.and(T.same_players(players,expected),T.same_found(attacker,actor)))

@unsafe
def world_result(label: String,actual: C.Bq.Pair.Pair(W.Bq.World,(w => List<&1,W.Bq.OutL>)),expected: List<&2,P.Players.State>,monsters: List<&2,M.Monsters.State>,phase: U32,outputs: U32) -> IO(Unit):
  match actual:
    case Tuple{world,outs}:
      match world:
        case Terrain.Terrain.World{wm,players,mobs,maps}:
          +shared = {outs : List<&1,W.Bq.OutL>}
          T.verdict(label,Bool.and(ST.same_meta(wm,fixture_meta(phase)),Bool.and(T.same_players(players,expected),Bool.and(MT.same_list(mobs,monsters),Bool.and(IT.same_maps(maps,[[101],[102],[103],[104]]),U32.is_eq(T.out_count(shared),outputs))))))

@unsafe
def again(kind: K.Combat.Kind,pid: U32,result: C.Bq.Pair.Pair(W.Bq.World,(w => List<&1,W.Bq.OutL>))) -> C.Bq.Pair.Pair(W.Bq.World,(w => List<&1,W.Bq.OutL>)):
  match kind:
    case K.Combat.Attack{}:
      match result:
        case Tuple{world,outs}: W.Bq.cmd_atk(world,pid)
    case K.Combat.Spin{}:
      match result:
        case Tuple{world,outs}: W.Bq.cmd_spin(world,pid)

# The first accepted attack is compared against literal fixtures, including damage.
def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- check_step("attack sets four tick cooldown only",K.Combat.prepare(K.Combat.Attack{},1,fixture_player(2,0,0,9)),fixture_player(2,0,4,9),True{})
    Unit <- check_step("spin sets twenty five tick cooldown only",K.Combat.prepare(K.Combat.Spin{},1,fixture_player(2,0,3,0)),fixture_player(2,0,3,25),True{})
    Unit <- check_step("dead attack exact no-op",K.Combat.prepare(K.Combat.Attack{},1,fixture_player(2,1,0,0)),fixture_player(2,1,0,0),False{})
    Unit <- check_step("dead spin exact no-op",K.Combat.prepare(K.Combat.Spin{},1,fixture_player(2,1,0,0)),fixture_player(2,1,0,0),False{})
    Unit <- check_step("cooling attack exact no-op",K.Combat.prepare(K.Combat.Attack{},1,fixture_player(2,0,1,0)),fixture_player(2,0,1,0),False{})
    Unit <- check_step("cooling spin exact no-op",K.Combat.prepare(K.Combat.Spin{},1,fixture_player(2,0,0,1)),fixture_player(2,0,0,1),False{})
    Unit <- check_step("maximum attack cooldown stays blocked",K.Combat.prepare(K.Combat.Attack{},1,fixture_player(2,0,4294967295,0)),fixture_player(2,0,4294967295,0),False{})
    Unit <- check_step("maximum spin cooldown stays blocked",K.Combat.prepare(K.Combat.Spin{},1,fixture_player(2,0,0,4294967295)),fixture_player(2,0,0,4294967295),False{})
    Unit <- check_step("inactive attack exact no-op",K.Combat.prepare(K.Combat.Attack{},0,fixture_player(2,0,0,0)),fixture_player(2,0,0,0),False{})
    Unit <- check_step("ended spin exact no-op",K.Combat.prepare(K.Combat.Spin{},2,fixture_player(2,0,0,0)),fixture_player(2,0,0,0),False{})
    Unit <- check_step("unknown phase exact no-op",K.Combat.prepare(K.Combat.Attack{},4294967295,fixture_player(2,0,0,0)),fixture_player(2,0,0,0),False{})
    Unit <- check_step("attack spam does not restart cooldown",K.Combat.prepare(K.Combat.Attack{},1,K.Combat.player(K.Combat.prepare(K.Combat.Attack{},1,fixture_player(2,0,0,9)))),fixture_player(2,0,4,9),False{})
    Unit <- check_step("spin spam does not restart cooldown",K.Combat.prepare(K.Combat.Spin{},1,K.Combat.player(K.Combat.prepare(K.Combat.Spin{},1,fixture_player(2,0,3,0)))),fixture_player(2,0,3,25),False{})
    Unit <- check_step("attack and spin retain independent cooldowns",K.Combat.prepare(K.Combat.Spin{},1,K.Combat.player(K.Combat.prepare(K.Combat.Attack{},1,fixture_player(2,0,0,0)))),fixture_player(2,0,4,25),True{})
    Unit <- check_roster("missing attacker preserves full roster",K.Combat.run([fixture_player(1,0,0,0)],2,K.Combat.Attack{},1),[fixture_player(1,0,0,0)],None{})
    Unit <- check_roster("empty roster cannot admit an attacker",K.Combat.run([],2,K.Combat.Spin{},1),[],None{})
    Unit <- check_roster("lookup commits exact admitted player",K.Combat.run([fixture_player(1,0,0,0),fixture_player(2,0,0,0)],2,K.Combat.Attack{},1),[fixture_player(2,0,4,0),fixture_player(1,0,0,0)],Some{fixture_player(2,0,4,0)})
    Unit <- check_roster("rejected lookup keeps other complete records",K.Combat.run([fixture_player(1,0,0,0),fixture_player(2,1,0,0)],2,K.Combat.Spin{},1),[fixture_player(2,1,0,0),fixture_player(1,0,0,0)],None{})
    Unit <- check_roster("duplicate ID still selects first occurrence",K.Combat.run([fixture_player(2,0,0,0),fixture_player(2,0,7,9)],2,K.Combat.Spin{},1),[fixture_player(2,0,0,25),fixture_player(2,0,7,9)],Some{fixture_player(2,0,0,25)})
    Unit <- world_result("server dead attack has no damage or output",W.Bq.cmd_atk(fixture_world([fixture_player(2,1,0,0)],fixture_mobs,1),2),[fixture_player(2,1,0,0)],fixture_mobs,1,0)
    Unit <- world_result("server dead spin has no damage or output",W.Bq.cmd_spin(fixture_world([fixture_player(2,1,0,0)],fixture_mobs,1),2),[fixture_player(2,1,0,0)],fixture_mobs,1,0)
    Unit <- world_result("server inactive attack has no damage or output",W.Bq.cmd_atk(fixture_world([fixture_player(2,0,0,0)],fixture_mobs,0),2),[fixture_player(2,0,0,0)],fixture_mobs,0,0)
    Unit <- world_result("server missing attacker leaves world unchanged",W.Bq.cmd_atk(fixture_world([fixture_player(2,0,0,0)],fixture_mobs,1),99),[fixture_player(2,0,0,0)],fixture_mobs,1,0)
    Unit <- world_result("server empty attack still consumes cooldown",W.Bq.cmd_atk(fixture_world([fixture_player(2,0,0,0)],[],1),2),[fixture_player(2,0,4,0)],[],1,0)
    Unit <- world_result("server empty spin still emits animation",W.Bq.cmd_spin(fixture_world([fixture_player(2,0,0,0)],[],1),2),[fixture_player(2,0,0,25)],[],1,1)
    Unit <- world_result("server attack damages one target and resets cooldown",W.Bq.cmd_atk(fixture_world([fixture_player(2,0,0,0)],fixture_mobs,1),2),[fixture_player(2,0,4,0)],[fixture_monster(7,0,6,5,9986,0),fixture_monster(8,0,7,4,10000,0)],1,1)
    Unit <- world_result("server spin damages both targets in order",W.Bq.cmd_spin(fixture_world([fixture_player(2,0,0,0)],fixture_mobs,1),2),[fixture_player(2,0,0,25)],[fixture_monster(8,0,7,4,9996,0),fixture_monster(7,0,6,5,9996,0)],1,1)
    Unit <- world_result("server repeated attack deals no additional damage",again(K.Combat.Attack{},2,W.Bq.cmd_atk(fixture_world([fixture_player(2,0,0,0)],fixture_mobs,1),2)),[fixture_player(2,0,4,0)],[fixture_monster(7,0,6,5,9986,0),fixture_monster(8,0,7,4,10000,0)],1,0)
    Unit <- world_result("server repeated spin deals no additional damage",again(K.Combat.Spin{},2,W.Bq.cmd_spin(fixture_world([fixture_player(2,0,0,0)],fixture_mobs,1),2)),[fixture_player(2,0,0,25)],[fixture_monster(8,0,7,4,9996,0),fixture_monster(7,0,6,5,9996,0)],1,0)
    Unit <- world_result("server attack then spin retains both cooldowns",again(K.Combat.Spin{},2,W.Bq.cmd_atk(fixture_world([fixture_player(2,0,0,0)],fixture_mobs,1),2)),[fixture_player(2,0,4,25)],[fixture_monster(8,0,7,4,9996,0),fixture_monster(7,0,6,5,9982,0)],1,1)
    Unit <- world_result("server cooling attack cannot emit effects",W.Bq.cmd_atk(fixture_world([fixture_player(2,0,1,0)],fixture_mobs,1),2),[fixture_player(2,0,1,0)],fixture_mobs,1,0)
    Unit <- world_result("server cooling spin cannot emit effects",W.Bq.cmd_spin(fixture_world([fixture_player(2,0,0,1)],fixture_mobs,1),2),[fixture_player(2,0,0,1)],fixture_mobs,1,0)
    Unit <- world_result("server unknown phase cannot spin",W.Bq.cmd_spin(fixture_world([fixture_player(2,0,0,0)],fixture_mobs,4294967295),2),[fixture_player(2,0,0,0)],fixture_mobs,4294967295,0)
    Unit <- world_result("server attack leaves other players unchanged",W.Bq.cmd_atk(fixture_world([fixture_player(1,0,7,9),fixture_player(2,0,0,0)],fixture_mobs,1),2),[fixture_player(2,0,4,0),fixture_player(1,0,7,9)],[fixture_monster(7,0,6,5,9986,0),fixture_monster(8,0,7,4,10000,0)],1,1)
    return Unit{}

#| PASS attack sets four tick cooldown only
#| PASS spin sets twenty five tick cooldown only
#| PASS dead attack exact no-op
#| PASS dead spin exact no-op
#| PASS cooling attack exact no-op
#| PASS cooling spin exact no-op
#| PASS maximum attack cooldown stays blocked
#| PASS maximum spin cooldown stays blocked
#| PASS inactive attack exact no-op
#| PASS ended spin exact no-op
#| PASS unknown phase exact no-op
#| PASS attack spam does not restart cooldown
#| PASS spin spam does not restart cooldown
#| PASS attack and spin retain independent cooldowns
#| PASS missing attacker preserves full roster
#| PASS empty roster cannot admit an attacker
#| PASS lookup commits exact admitted player
#| PASS rejected lookup keeps other complete records
#| PASS duplicate ID still selects first occurrence
#| PASS server dead attack has no damage or output
#| PASS server dead spin has no damage or output
#| PASS server inactive attack has no damage or output
#| PASS server missing attacker leaves world unchanged
#| PASS server empty attack still consumes cooldown
#| PASS server empty spin still emits animation
#| PASS server attack damages one target and resets cooldown
#| PASS server spin damages both targets in order
#| PASS server repeated attack deals no additional damage
#| PASS server repeated spin deals no additional damage
#| PASS server attack then spin retains both cooldowns
#| PASS server cooling attack cannot emit effects
#| PASS server cooling spin cannot emit effects
#| PASS server unknown phase cannot spin
#| PASS server attack leaves other players unchanged
