import Base
import ./main.bend as Application
import ./world.bend as W
import ./monster_damage.bend as MD
import ./live_tick.bend as Tick
import ./compat.bend as C
import ./support.bend as Support
import ./data.bend as Data
import ./terrain.bend as Terrain
import ./simulation.bend as S
import ./players.bend as P
import ./monsters.bend as M
import ./roster.bend as R
import ./locomotion.bend as L
import ./planning.bend as Plan
import ./ai_refs.bend as AIRefs
import ./landscape.bend as Landscape
import ./population.bend as Pop
import ./players_check.bend as Test
import ./rebuild_check.bend as Old
import ./ai_refs_check.bend as F
import ./simulation_check.bend as ST

# Preserved pre-change attack and full tick pipeline as the independent oracle.
law Previous.catalog:
  (@+k_0: U32 -> U32)

@unsafe
def Previous.catalog():
  (k_0 => (+apply_494 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_495 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_496 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_497 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_498 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_499 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_500 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_501 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_502 = {(word => C.Bq.word_case(U32, word, 0, (unit => 42), (_67_0 => 30), 0)) : (@+___0: U32 -> U32)}; apply_502(C.Bq.bit(U32.is_eq(k_0, 8))))), (_69_1 => 22), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_501(k_0, C.Bq.bit(U32.is_eq(k_0, 7))))), (_71_1 => 14), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_500(k_0, C.Bq.bit(U32.is_eq(k_0, 6))))), (_73_1 => 22), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_499(k_0, C.Bq.bit(U32.is_eq(k_0, 5))))), (_75_1 => 18), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_498(k_0, C.Bq.bit(U32.is_eq(k_0, 4))))), (_77_1 => 14), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_497(k_0, C.Bq.bit(U32.is_eq(k_0, 3))))), (_79_1 => 10), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_496(k_0, C.Bq.bit(U32.is_eq(k_0, 2))))), (_81_1 => 6), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_495(k_0, C.Bq.bit(U32.is_eq(k_0, 1))))), (_83_1 => 4), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_494(k_0, C.Bq.bit(U32.is_eq(k_0, 0)))))

law Previous.current:
  (@+kind_0: U32 -> (@+hp_1: U32 -> (@+mhp_2: U32 -> U32)))

@unsafe
def Previous.current():
  (kind_0 => (hp_1 => (mhp_2 => (+a_3 = Previous.catalog(kind_0); (+apply_503 = {(a_0 => (word => C.Bq.word_case(U32, word, 0, (unit => a_0), (_1427_1 => (a_0 * 2 : U32)), 0))) : (@+a_0: U32 -> (@+___1: U32 -> U32))}; apply_503(a_3, C.Bq.word_and(C.Bq.bit(U32.is_eq(kind_0, 9)), C.Bq.bit(U32.is_lt((hp_1 * 10 : U32), (mhp_2 * 3 : U32))))))))))

@unsafe
def Previous.amount(monster: M.Monsters.State) -> U32:
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}: U32.mul(Previous.current(kind,hp,maximum),U32.add(1,rare))

@unsafe
def Previous.damages(monsters: List<&2,M.Monsters.State>) -> List<&2,U32>:
  match monsters:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{Previous.amount(M.Monsters.tick_state(M.Monsters.tick(head))),Previous.damages(rest)}

@unsafe
def Previous.result(result: S.Simulation.Result, +maps: List<&2,List<&2,U32>>, tick: U32) -> C.Bq.Pair.Pair(W.Bq.World, (world => List<&1, W.Bq.OutL>)):
  match result:
    case S.Simulation.Result{state, events}:
      match state:
        case S.Simulation.State{meta, players, monsters}:
          +shared_meta = meta
          +shared_players = players
          +shared_monsters = monsters
          Tuple{Terrain.Terrain.world(maps,S.Simulation.State{shared_meta,shared_players,shared_monsters}), Support.Bq.List.concat(W.Bq.OutL, W.Bq.player_events(events, maps), W.Bq.snap_outs(shared_players, shared_monsters, tick, W.Bq.wm_sigils(shared_meta), S.Simulation.phase(shared_meta)))}

@unsafe
def Previous.finish(+prepared: S.Simulation.Prepared,+maps: List<&2,List<&2,U32>>,rules: S.Simulation.Rules) -> C.Bq.Pair.Pair(W.Bq.World,(world => List<&1,W.Bq.OutL>)):
  match prepared:
    case S.Simulation.Prepared{meta,monsters,upkeep,running}:
      match running:
        case False{}:
          Previous.result(AIRefs.AIRefs.finish(S.Simulation.Prepared{meta,monsters,upkeep,False{}},maps,Nil{},Nil{},Nil{},Nil{},rules),maps,S.Simulation.clock(meta))
        case True{}:
          d0 d1 d2 d3 = Previous.damages(R.Roster.zone(monsters,0)) Previous.damages(R.Roster.zone(monsters,1)) Previous.damages(R.Roster.zone(monsters,2)) Previous.damages(R.Roster.zone(monsters,3))
          Previous.result(AIRefs.AIRefs.finish(S.Simulation.Prepared{meta,monsters,upkeep,True{}},maps,d0,d1,d2,d3,rules),maps,S.Simulation.clock(meta))

law Previous.tick:
  (@+w_0: W.Bq.World -> C.Bq.Pair.Pair(W.Bq.World, (__1 => List<&1, W.Bq.OutL>)))

@unsafe
def Previous.tick(world):
  match world:
    case Terrain.Terrain.World{meta, players, monsters, maps}:
      Previous.finish(L.Locomotion.begin(S.Simulation.State{meta, players, monsters}, maps, W.Bq.simulation_rules), maps, W.Bq.simulation_rules)


def same_line(a: List<&1,Char>,b: List<&1,Char>) -> Bool: Test.same_name(P.Players.share_name(a),P.Players.share_name(b))

def same_out(a: W.Bq.OutL,b: W.Bq.OutL) -> Bool:
  match a:
    case W.Bq.OutL.All{line}:
      match b:
        case W.Bq.OutL.All{other_line}: same_line(line,other_line)
        case W.Bq.OutL.To{other_cid,other_line}: False{}
        case W.Bq.OutL.ZoneL{other_zone,other_line}: False{}
        case W.Bq.OutL.Log{other_line}: False{}
    case W.Bq.OutL.To{cid,line}:
      match b:
        case W.Bq.OutL.All{other_line}: False{}
        case W.Bq.OutL.To{other_cid,other_line}: Bool.and(U32.is_eq(cid,other_cid),same_line(line,other_line))
        case W.Bq.OutL.ZoneL{other_zone,other_line}: False{}
        case W.Bq.OutL.Log{other_line}: False{}
    case W.Bq.OutL.ZoneL{zone,line}:
      match b:
        case W.Bq.OutL.All{other_line}: False{}
        case W.Bq.OutL.To{other_cid,other_line}: False{}
        case W.Bq.OutL.ZoneL{other_zone,other_line}: Bool.and(U32.is_eq(zone,other_zone),same_line(line,other_line))
        case W.Bq.OutL.Log{other_line}: False{}
    case W.Bq.OutL.Log{line}:
      match b:
        case W.Bq.OutL.All{other_line}: False{}
        case W.Bq.OutL.To{other_cid,other_line}: False{}
        case W.Bq.OutL.ZoneL{other_zone,other_line}: False{}
        case W.Bq.OutL.Log{other_line}: same_line(line,other_line)

def same_outs(a: List<&1,W.Bq.OutL>,b: List<&1,W.Bq.OutL>) -> Bool:
  match a:
    case Nil{}:
      match b:
        case Nil{}: True{}
        case Con{head,rest}: False{}
    case Con{head,rest}:
      match b:
        case Nil{}: False{}
        case Con{other,later}: Bool.and(same_out(head,other),same_outs(rest,later))

def same_result(a: Terrain.Terrain.World & List<&1,W.Bq.OutL>,b: Terrain.Terrain.World & List<&1,W.Bq.OutL>) -> Bool:
  match a:
    case Tuple{world,outs}:
      match b:
        case Tuple{other,lines}: Bool.and(Old.same(world,other),same_outs(outs,lines))

def mob(kind: U32,rare: U32,hp: U32,maximum: U32,dead: U32,timer: U32) -> M.Monsters.State:
  M.Monsters.State{42,kind,rare,0,14,8,hp,maximum,1,0,dead,timer}

def world(state: S.Simulation.State) -> Terrain.Terrain.World: Terrain.Terrain.world(Landscape.Landscape.maps(0),state)

@unsafe
def catalog(label: String,+kind: U32) -> IO(Unit): Test.verdict(label,Bool.and(U32.is_eq(MD.MonsterDamage.catalog(kind),Previous.catalog(kind)),U32.is_eq(Data.Bq.mob_atk(kind),Previous.catalog(kind))))

@unsafe
def current(label: String,+kind: U32,+hp: U32,+maximum: U32) -> IO(Unit): Test.verdict(label,Bool.and(U32.is_eq(MD.MonsterDamage.current(kind,hp,maximum),Previous.current(kind,hp,maximum)),U32.is_eq(W.Bq.mob_atk_now(kind,hp,maximum),Previous.current(kind,hp,maximum))))

@unsafe
def amount(label: String,+monster: M.Monsters.State) -> IO(Unit): Test.verdict(label,Bool.and(U32.is_eq(MD.MonsterDamage.amount(monster),Previous.amount(monster)),U32.is_eq(W.Bq.ai_damage(monster),Previous.amount(monster))))

@unsafe
def damages(label: String,+monsters: List<&2,M.Monsters.State>) -> IO(Unit): Test.verdict(label,Bool.and(F.same_words(MD.MonsterDamage.list(monsters),Previous.damages(monsters)),F.same_words(W.Bq.ai_damages(monsters),Previous.damages(monsters))))

@unsafe
def checked(label: String,+before: Terrain.Terrain.World) -> IO(Unit): Test.verdict(label,same_result(W.Bq.tick_world(before),Previous.tick(before)))

@unsafe
def after(result: Terrain.Terrain.World & List<&1,W.Bq.OutL>) -> Terrain.Terrain.World:
  match result:
    case Tuple{world,outs}: world

@unsafe
def repeated(label: String,+before: Terrain.Terrain.World) -> IO(Unit): Test.verdict(label,same_result(W.Bq.tick_world(after(W.Bq.tick_world(before))),Previous.tick(after(Previous.tick(before)))))

@unsafe
def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- catalog("live tick catalogue 0",0)
    Unit <- catalog("live tick catalogue 1",1)
    Unit <- catalog("live tick catalogue 2",2)
    Unit <- catalog("live tick catalogue 3",3)
    Unit <- catalog("live tick catalogue 4",4)
    Unit <- catalog("live tick catalogue 5",5)
    Unit <- catalog("live tick catalogue 6",6)
    Unit <- catalog("live tick catalogue 7",7)
    Unit <- catalog("live tick catalogue 8",8)
    Unit <- catalog("live tick catalogue 9",9)
    Unit <- catalog("live tick catalogue 10",10)
    Unit <- catalog("live tick catalogue 4294967295",4294967295)
    Unit <- current("live tick below rage threshold",9,29,100)
    Unit <- current("live tick exact rage threshold",9,30,100)
    Unit <- current("live tick above rage threshold",9,31,100)
    Unit <- current("live tick nonboss low health",8,0,100)
    Unit <- current("live tick zero maximum",9,0,0)
    Unit <- current("live tick wrapped health product",9,4294967295,100)
    Unit <- current("live tick wrapped maximum product",9,1,4294967295)
    Unit <- current("live tick MAX kind fallback",4294967295,0,100)
    Unit <- amount("live tick normal damage",mob(0,0,18,18,0,0))
    Unit <- amount("live tick rare damage",mob(0,1,18,18,0,0))
    Unit <- amount("live tick enraged rare boss",mob(9,1,29,100,0,0))
    Unit <- amount("live tick MAX rarity wraps",mob(9,4294967295,29,100,0,0))
    Unit <- amount("live tick corpse damage data",mob(0,0,0,18,1,1))
    Unit <- amount("live tick MAX damage metadata",mob(4294967295,4294967294,4294967295,4294967295,0,0))
    Unit <- damages("live tick empty damage list",Nil{})
    Unit <- damages("live tick post tick regeneration",[mob(9,1,29,100,0,0)])
    Unit <- damages("live tick post tick respawn",[mob(0,0,0,18,1,1)])
    Unit <- damages("live tick mixed damage list order",[mob(9,1,29,100,0,0),mob(0,0,0,18,1,1),mob(8,0,100,100,0,0)])
    Unit <- checked("live tick output fresh seed zero",Pop.Population.fresh(1,0,0))
    Unit <- checked("live tick output fresh seed MAX",Pop.Population.fresh(1,4294967295,0))
    Unit <- checked("live tick output empty rosters",world(F.state(1,0,Nil{},Nil{})))
    Unit <- checked("live tick output waiting phase",world(F.state(0,0,[F.player(1,0,14,8,0,30,0,0)],[F.monster(7,0,1,0)])))
    Unit <- checked("live tick output ended phase",world(F.state(2,0,[F.player(1,0,14,8,0,30,0,0)],[F.monster(7,0,1,0)])))
    Unit <- checked("live tick output single attack",world(F.state(1,0,[F.player(1,0,14,8,0,30,0,0)],[F.monster(7,0,1,0)])))
    Unit <- checked("live tick output ordered lethal attacks",world(F.state(1,0,[F.player(1,0,14,8,0,1,0,0)],[F.monster(7,0,0,0),F.monster(8,0,0,0)])))
    Unit <- checked("live tick output movement before targeting",world(F.state(1,0,[F.player(1,0,13,8,1,30,0,0)],[F.monster(7,0,1,0)])))
    Unit <- checked("live tick output player respawn",world(F.state(1,0,[F.player(1,0,14,8,0,0,1,1)],[F.monster(7,0,1,0)])))
    Unit <- checked("live tick output monster cooldown",world(F.state(1,0,[F.player(1,0,14,8,0,30,0,0)],[F.monster(7,0,1,3)])))
    Unit <- checked("live tick output monster respawn",world(F.state(1,0,[F.player(1,0,14,8,0,30,0,0)],[F.corpse(7,0,1,1)])))
    Unit <- checked("live tick output permanent corpse",world(F.state(1,0,[F.player(1,0,14,8,0,30,0,0)],[F.corpse(7,0,1,4294967295)])))
    Unit <- checked("live tick output boss regeneration threshold",world(F.state(1,0,[F.player(1,0,14,8,0,30,0,0)],[mob(9,1,29,100,0,0)])))
    Unit <- checked("live tick output four zones",world(F.state(1,0,[F.player(1,0,14,8,0,30,0,0),F.player(2,1,14,8,0,30,0,0),F.player(3,2,14,8,0,30,0,0),F.player(4,3,14,8,0,30,0,0)],[F.monster(10,3,4,0),F.monster(11,1,2,0),F.monster(12,0,1,0),F.monster(13,2,3,0)])))
    Unit <- checked("live tick output tick wrap",world(F.state(1,4294967295,[F.player(1,0,14,8,0,30,0,0)],[F.monster(7,0,1,0)])))
    Unit <- checked("live tick output arbitrary inactive phase",world(F.state(4294967295,0,[F.player(1,0,14,8,0,30,0,0)],[F.monster(7,0,1,0)])))
    Unit <- checked("live tick output Unicode styled roster",world(F.state(1,0,[Old.styled(7,1,"Étoile猫"),Old.styled(8,2,"Bob")],Nil{})))
    Unit <- checked("live tick output actual arbitrary maps",Terrain.Terrain.world([[0,1,2],Nil{},[4294967295]],F.state(0,99,Nil{},Nil{})))
    Unit <- checked("live tick output missing old target",world(F.state(1,0,[F.player(1,0,14,8,0,30,0,0)],[F.monster(7,0,999,0)])))
    repeated("live tick successive full outputs",world(F.state(1,0,[F.player(1,0,14,8,0,30,0,0)],[F.monster(7,0,1,0)])))

#| PASS live tick catalogue 0
#| PASS live tick catalogue 1
#| PASS live tick catalogue 2
#| PASS live tick catalogue 3
#| PASS live tick catalogue 4
#| PASS live tick catalogue 5
#| PASS live tick catalogue 6
#| PASS live tick catalogue 7
#| PASS live tick catalogue 8
#| PASS live tick catalogue 9
#| PASS live tick catalogue 10
#| PASS live tick catalogue 4294967295
#| PASS live tick below rage threshold
#| PASS live tick exact rage threshold
#| PASS live tick above rage threshold
#| PASS live tick nonboss low health
#| PASS live tick zero maximum
#| PASS live tick wrapped health product
#| PASS live tick wrapped maximum product
#| PASS live tick MAX kind fallback
#| PASS live tick normal damage
#| PASS live tick rare damage
#| PASS live tick enraged rare boss
#| PASS live tick MAX rarity wraps
#| PASS live tick corpse damage data
#| PASS live tick MAX damage metadata
#| PASS live tick empty damage list
#| PASS live tick post tick regeneration
#| PASS live tick post tick respawn
#| PASS live tick mixed damage list order
#| PASS live tick output fresh seed zero
#| PASS live tick output fresh seed MAX
#| PASS live tick output empty rosters
#| PASS live tick output waiting phase
#| PASS live tick output ended phase
#| PASS live tick output single attack
#| PASS live tick output ordered lethal attacks
#| PASS live tick output movement before targeting
#| PASS live tick output player respawn
#| PASS live tick output monster cooldown
#| PASS live tick output monster respawn
#| PASS live tick output permanent corpse
#| PASS live tick output boss regeneration threshold
#| PASS live tick output four zones
#| PASS live tick output tick wrap
#| PASS live tick output arbitrary inactive phase
#| PASS live tick output Unicode styled roster
#| PASS live tick output actual arbitrary maps
#| PASS live tick output missing old target
#| PASS live tick successive full outputs
