# Monster target references, reconciled against the authoritative player roster.
import Base
import ./players.bend as P
import ./monsters.bend as M
import ./roster.bend as R
import ./zones.bend as Z
import ./identity.bend as I
import ./terrain.bend as T
import ./habitat.bend as H
import ./simulation.bend as S
import ./locomotion.bend as Walk
import ./planning.bend as Plan
import ./landscape.bend as L
import ./population.bend as Pop
import ./placement.bend as Place

def References.target(monster: M.Monsters.State) -> U32:
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}: target

def References.exists(players: List<&2,P.Players.State>,+target: U32) -> Bool:
  Bool.or(U32.is_eq(target,0),P.Players.has_id(players,target))

def References.Valid(+players: List<&2,P.Players.State>,monster: M.Monsters.State) -> Data:
  {References.exists(players,References.target(monster)) == True{} : Bool}

def References.All(+players: List<&2,P.Players.State>,monsters: List<&2,M.Monsters.State>) -> Data:
  match monsters:
    case Nil{}: Unit
    case Con{head,rest}: Sigma<&2,&2,References.Valid(players,head),(valid => References.All(players,rest))>

def References.clear(monster: M.Monsters.State) -> M.Monsters.State:
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}: M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,0,attack,dead,respawn}

def References.gate(valid: Bool,monster: M.Monsters.State) -> M.Monsters.State:
  match valid:
    case True{}: monster
    case False{}: References.clear(monster)

def References.repair(+players: List<&2,P.Players.State>,+monster: M.Monsters.State) -> M.Monsters.State:
  References.gate(References.exists(players,References.target(monster)),monster)

def References.reconcile(+players: List<&2,P.Players.State>,monsters: List<&2,M.Monsters.State>) -> List<&2,M.Monsters.State>:
  match monsters:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{References.repair(players,head),References.reconcile(players,rest)}

# Every field except target is retained exactly.
type References.Frame is Data:
  References.Frame{mid: U32,kind: U32,rare: U32,zone: U32,x: U32,y: U32,hp: U32,maximum: U32,attack: U32,dead: U32,respawn: U32}

def References.frame(monster: M.Monsters.State) -> References.Frame:
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}: References.Frame{mid,kind,rare,zone,x,y,hp,maximum,attack,dead,respawn}

law References.clear_target:
  for +monster: M.Monsters.State
  {References.target(References.clear(monster)) == 0 : U32}

def References.clear_target(monster):
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}: {==}

law References.clear_valid:
  for +players: List<&2,P.Players.State>
  for +monster: M.Monsters.State
  References.Valid(players,References.clear(monster))

def References.clear_valid(players,monster):
  %Equal.sym(U32,References.target(References.clear(monster)),0,References.clear_target(monster)) : {References.exists(players,_) == True{} : Bool}
  {==}

law References.gate_valid:
  for +valid: Bool
  for +players: List<&2,P.Players.State>
  for +monster: M.Monsters.State
  for +decision: {References.exists(players,References.target(monster)) == valid : Bool}
  References.Valid(players,References.gate(valid,monster))

def References.gate_valid(valid,players,monster,decision):
  match valid:
    case True{}: decision
    case False{}: References.clear_valid(players,monster)

law References.repair_valid:
  for +players: List<&2,P.Players.State>
  for +monster: M.Monsters.State
  References.Valid(players,References.repair(players,monster))

def References.repair_valid(players,monster): References.gate_valid(References.exists(players,References.target(monster)),players,monster,{==})

law References.reconcile_valid:
  for +monsters: List<&2,M.Monsters.State>
  for +players: List<&2,P.Players.State>
  References.All(players,References.reconcile(players,monsters))

def References.reconcile_valid(monsters,players):
  match monsters:
    case Nil{}: Unit{}
    case Con{head,rest}: Tuple{References.repair_valid(players,head),References.reconcile_valid(rest,players)}

law References.repair_unchanged:
  for +players: List<&2,P.Players.State>
  for +monster: M.Monsters.State
  for +valid: References.Valid(players,monster)
  {References.repair(players,monster) == monster : M.Monsters.State}

def References.repair_unchanged(players,monster,valid):
  %Equal.sym(Bool,References.exists(players,References.target(monster)),True{},valid) : {References.gate(_,monster) == monster : M.Monsters.State}
  {==}

law References.repair_missing:
  for +players: List<&2,P.Players.State>
  for +monster: M.Monsters.State
  for +missing: {References.exists(players,References.target(monster)) == False{} : Bool}
  {References.repair(players,monster) == References.clear(monster) : M.Monsters.State}

def References.repair_missing(players,monster,missing):
  %Equal.sym(Bool,References.exists(players,References.target(monster)),False{},missing) : {References.gate(_,monster) == References.clear(monster) : M.Monsters.State}
  {==}

law References.reconcile_unchanged:
  for +monsters: List<&2,M.Monsters.State>
  for +players: List<&2,P.Players.State>
  for +valid: References.All(players,monsters)
  {References.reconcile(players,monsters) == monsters : List<&2,M.Monsters.State>}

def References.reconcile_unchanged(monsters,players,valid):
  match monsters:
    case Nil{}: {==}
    case Con{head,rest}:
      match valid:
        case Tuple{head_ok,rest_ok}:
          %References.repair_unchanged(players,head,head_ok) : {Con{References.repair(players,head),References.reconcile(players,rest)} == Con{_,rest} : List<&2,M.Monsters.State>}
          %References.reconcile_unchanged(rest,players,rest_ok) : {Con{References.repair(players,head),References.reconcile(players,rest)} == Con{References.repair(players,head),_} : List<&2,M.Monsters.State>}
          {==}

law References.reconcile_idempotent:
  for +players: List<&2,P.Players.State>
  for +monsters: List<&2,M.Monsters.State>
  {References.reconcile(players,References.reconcile(players,monsters)) == References.reconcile(players,monsters) : List<&2,M.Monsters.State>}

def References.reconcile_idempotent(players,monsters): References.reconcile_unchanged(References.reconcile(players,monsters),players,References.reconcile_valid(monsters,players))

law References.clear_frame:
  for +monster: M.Monsters.State
  {References.frame(References.clear(monster)) == References.frame(monster) : References.Frame}

def References.clear_frame(monster):
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}: {==}

law References.gate_frame:
  for +valid: Bool
  for +monster: M.Monsters.State
  {References.frame(References.gate(valid,monster)) == References.frame(monster) : References.Frame}

def References.gate_frame(valid,monster):
  match valid:
    case True{}: {==}
    case False{}: References.clear_frame(monster)

law References.repair_frame:
  for +players: List<&2,P.Players.State>
  for +monster: M.Monsters.State
  {References.frame(References.repair(players,monster)) == References.frame(monster) : References.Frame}

def References.repair_frame(players,monster): References.gate_frame(References.exists(players,References.target(monster)),monster)

law References.clear_ok:
  for +monster: M.Monsters.State
  for +valid: M.Monsters.OK(monster)
  M.Monsters.OK(References.clear(monster))

def References.clear_ok(monster,valid):
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}: valid

law References.gate_ok:
  for +ready: Bool
  for +monster: M.Monsters.State
  for +valid: M.Monsters.OK(monster)
  M.Monsters.OK(References.gate(ready,monster))

def References.gate_ok(ready,monster,valid):
  match ready:
    case True{}: valid
    case False{}: References.clear_ok(monster,valid)

law References.reconcile_ok:
  for +monsters: List<&2,M.Monsters.State>
  for +players: List<&2,P.Players.State>
  for +valid: R.Roster.OK(monsters)
  R.Roster.OK(References.reconcile(players,monsters))

def References.reconcile_ok(monsters,players,valid):
  match monsters:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match valid:
        case Tuple{head_ok,rest_ok}: Tuple{References.gate_ok(References.exists(players,References.target(head)),head,head_ok),References.reconcile_ok(rest,players,rest_ok)}


law References.clear_key:
  for +monster: M.Monsters.State
  {Z.Zones.key(References.clear(monster)) == Z.Zones.key(monster) : Z.Zones.Key}

def References.clear_key(monster):
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}: {==}

law References.gate_key:
  for +valid: Bool
  for +monster: M.Monsters.State
  {Z.Zones.key(References.gate(valid,monster)) == Z.Zones.key(monster) : Z.Zones.Key}

def References.gate_key(valid,monster):
  match valid:
    case True{}: {==}
    case False{}: References.clear_key(monster)

law References.repair_key:
  for +players: List<&2,P.Players.State>
  for +monster: M.Monsters.State
  {Z.Zones.key(References.repair(players,monster)) == Z.Zones.key(monster) : Z.Zones.Key}

def References.repair_key(players,monster): References.gate_key(References.exists(players,References.target(monster)),monster)


law References.clear_position:
  for +monster: M.Monsters.State
  {H.Habitat.pos(References.clear(monster)) == H.Habitat.pos(monster) : P.Players.Pos}

def References.clear_position(monster):
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}: {==}

law References.gate_position:
  for +valid: Bool
  for +monster: M.Monsters.State
  {H.Habitat.pos(References.gate(valid,monster)) == H.Habitat.pos(monster) : P.Players.Pos}

def References.gate_position(valid,monster):
  match valid:
    case True{}: {==}
    case False{}: References.clear_position(monster)

law References.repair_position:
  for +players: List<&2,P.Players.State>
  for +monster: M.Monsters.State
  {H.Habitat.pos(References.repair(players,monster)) == H.Habitat.pos(monster) : P.Players.Pos}

def References.repair_position(players,monster): References.gate_position(References.exists(players,References.target(monster)),monster)


law References.reconcile_keys:
  for +monsters: List<&2,M.Monsters.State>
  for +players: List<&2,P.Players.State>
  {Z.Zones.keys(References.reconcile(players,monsters)) == Z.Zones.keys(monsters) : List<&2,Z.Zones.Key>}

def References.reconcile_keys(monsters,players):
  match monsters:
    case Nil{}: {==}
    case Con{head,rest}:
      %References.repair_key(players,head) : {Con{Z.Zones.key(References.repair(players,head)),Z.Zones.keys(References.reconcile(players,rest))} == Con{_,Z.Zones.keys(rest)} : List<&2,Z.Zones.Key>}
      %References.reconcile_keys(rest,players) : {Con{Z.Zones.key(References.repair(players,head)),Z.Zones.keys(References.reconcile(players,rest))} == Con{Z.Zones.key(References.repair(players,head)),_} : List<&2,Z.Zones.Key>}
      {==}

law References.reconcile_conserves:
  for +monsters: List<&2,M.Monsters.State>
  for +players: List<&2,P.Players.State>
  Z.Zones.Conserved<monsters,References.reconcile(players,monsters)>

def References.reconcile_conserves(monsters,players): Z.Zones.Conserved{monsters,R.Roster.Same{{==}},References.reconcile_keys(monsters,players)}

law References.reconcile_on:
  for +monsters: List<&2,M.Monsters.State>
  for +players: List<&2,P.Players.State>
  for +maps: T.Terrain.Maps
  for +valid: H.Habitat.All(maps,monsters)
  H.Habitat.All(maps,References.reconcile(players,monsters))

def References.reconcile_on(monsters,players,maps,valid):
  match monsters:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match valid:
        case Tuple{head_ok,rest_ok}:
          Tuple{(%Equal.sym(P.Players.Pos,H.Habitat.pos(References.repair(players,head)),H.Habitat.pos(head),References.repair_position(players,head)) : T.Terrain.On<maps,_>; head_ok),References.reconcile_on(rest,players,maps,rest_ok)}

law References.reconcile_count:
  for +monsters: List<&2,M.Monsters.State>
  for +players: List<&2,P.Players.State>
  {R.Roster.length(References.reconcile(players,monsters)) == R.Roster.length(monsters) : Nat}

def References.reconcile_count(monsters,players):
  match monsters:
    case Nil{}: {==}
    case Con{head,rest}:
      %References.reconcile_count(rest,players) : {Succ{R.Roster.length(References.reconcile(players,rest))} == Succ{_} : Nat}
      {==}

# Deletion preserves the existing first-match player lookup behavior.
def References.finish_remove(meta: S.Simulation.Meta,taken: P.Players.Take,monsters: List<&2,M.Monsters.State>) -> S.Simulation.State:
  +remaining = P.Players.others(taken)
  S.Simulation.State{meta,remaining,References.reconcile(remaining,monsters)}

def References.remove_state(state: S.Simulation.State,pid: U32) -> S.Simulation.State:
  match state:
    case S.Simulation.State{meta,players,monsters}: References.finish_remove(meta,P.Players.take(players,pid),monsters)

def References.remove(world: T.Terrain.World,pid: U32) -> T.Terrain.World:
  match world:
    case T.Terrain.World{meta,players,monsters,maps}: T.Terrain.world(maps,References.remove_state(S.Simulation.State{meta,players,monsters},pid))

law References.remove_valid:
  for +state: S.Simulation.State
  for +pid: U32
  References.All(S.Simulation.players(References.remove_state(state,pid)),S.Simulation.monsters(References.remove_state(state,pid)))

def References.remove_valid(state,pid):
  match state:
    case S.Simulation.State{meta,players,monsters}: References.reconcile_valid(monsters,P.Players.others(P.Players.take(players,pid)))

law References.remove_players:
  for +state: S.Simulation.State
  for +pid: U32
  {S.Simulation.players(References.remove_state(state,pid)) == P.Players.others(P.Players.take(S.Simulation.players(state),pid)) : List<&2,P.Players.State>}

def References.remove_players(state,pid):
  match state:
    case S.Simulation.State{meta,players,monsters}: {==}

law References.remove_meta:
  for +state: S.Simulation.State
  for +pid: U32
  {S.Simulation.meta(References.remove_state(state,pid)) == S.Simulation.meta(state) : S.Simulation.Meta}

def References.remove_meta(state,pid):
  match state:
    case S.Simulation.State{meta,players,monsters}: {==}

law References.remove_maps:
  for +world: T.Terrain.World
  for +pid: U32
  {T.Terrain.maps(References.remove(world,pid)) == T.Terrain.maps(world) : T.Terrain.Maps}

def References.remove_maps(world,pid):
  match world:
    case T.Terrain.World{meta,players,monsters,maps}: {==}

law References.remove_monster_count:
  for +state: S.Simulation.State
  for +pid: U32
  {R.Roster.length(S.Simulation.monsters(References.remove_state(state,pid))) == R.Roster.length(S.Simulation.monsters(state)) : Nat}

def References.remove_monster_count(state,pid):
  match state:
    case S.Simulation.State{meta,players,monsters}: References.reconcile_count(monsters,P.Players.others(P.Players.take(players,pid)))


law References.remove_monster_ids:
  for +state: S.Simulation.State
  for +pid: U32
  for +valid: I.Identity.Monsters(S.Simulation.monsters(state))
  I.Identity.Monsters(S.Simulation.monsters(References.remove_state(state,pid)))

def References.remove_monster_ids(state,pid,valid):
  match state:
    case S.Simulation.State{meta,players,monsters}:
      +remaining = P.Players.others(P.Players.take(players,pid))
      I.Identity.conserved_unique(monsters,References.reconcile(remaining,monsters),References.reconcile_conserves(monsters,remaining),valid)

def References.others_ok(taken: P.Players.Take,valid: P.Players.TakeOK<taken>) -> P.Players.All(P.Players.others(taken)):
  match valid:
    case P.Players.ValidTake{others,found}: others

law References.remove_ok:
  for +state: S.Simulation.State
  for +pid: U32
  for +valid: S.Simulation.OK<state>
  S.Simulation.OK<References.remove_state(state,pid)>

def References.remove_ok(state,pid,valid):
  match state:
    case S.Simulation.State{meta,players,monsters}:
      match valid:
        case S.Simulation.OK{ps,ms,zs}:
          +remaining = P.Players.others(P.Players.take(players,pid))
          S.Simulation.OK{References.others_ok(P.Players.take(players,pid),P.Players.take_ok(players,pid,ps)),References.reconcile_ok(monsters,remaining,ms),Z.Zones.conserved_all(monsters,References.reconcile(remaining,monsters),References.reconcile_conserves(monsters,remaining),zs)}

law References.others_on:
  for +maps: T.Terrain.Maps
  for +taken: P.Players.Take
  for +valid: Walk.Locomotion.All(maps,P.Players.restore(taken))
  Walk.Locomotion.All(maps,P.Players.others(taken))

def References.others_on(maps,taken,valid):
  match taken:
    case P.Players.Take{others,found}:
      match found:
        case None{}: valid
        case Some{player}: Walk.Locomotion.tail_on(maps,player,others,valid)

law References.remove_positions:
  for +seed: U32
  for +state: S.Simulation.State
  for +pid: U32
  for +valid: Plan.Planning.Positions<seed,state>
  Plan.Planning.Positions<seed,References.remove_state(state,pid)>

def References.remove_positions(seed,state,pid,valid):
  match state:
    case S.Simulation.State{meta,players,monsters}:
      match valid:
        case Plan.Planning.Positions{ps,ms}:
          +maps = L.Landscape.maps(seed)
          Plan.Planning.Positions{References.others_on(maps,P.Players.take(players,pid),Walk.Locomotion.take_on(maps,players,pid,ps)),References.reconcile_on(monsters,P.Players.others(P.Players.take(players,pid)),maps,ms)}

law References.remove_missing:
  for +state: S.Simulation.State
  for +pid: U32
  for +missing: {P.Players.has_id(S.Simulation.players(state),pid) == False{} : Bool}
  for +valid: References.All(S.Simulation.players(state),S.Simulation.monsters(state))
  {References.remove_state(state,pid) == state : S.Simulation.State}

def References.remove_missing(state,pid,missing,valid):
  match state:
    case S.Simulation.State{meta,players,monsters}:
      %Equal.sym(P.Players.Take,P.Players.take(players,pid),P.Players.Take{players,None{}},P.Players.take_missing(players,pid,missing)) : {References.finish_remove(meta,_,monsters) == S.Simulation.State{meta,players,monsters} : S.Simulation.State}
      %References.reconcile_unchanged(monsters,players,valid) : {S.Simulation.State{meta,players,References.reconcile(players,monsters)} == S.Simulation.State{meta,players,_} : S.Simulation.State}
      {==}


def References.frames(monsters: List<&2,M.Monsters.State>) -> List<&2,References.Frame>:
  match monsters:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{References.frame(head),References.frames(rest)}

law References.reconcile_frames:
  for +monsters: List<&2,M.Monsters.State>
  for +players: List<&2,P.Players.State>
  {References.frames(References.reconcile(players,monsters)) == References.frames(monsters) : List<&2,References.Frame>}

def References.reconcile_frames(monsters,players):
  match monsters:
    case Nil{}: {==}
    case Con{head,rest}:
      %References.repair_frame(players,head) : {Con{References.frame(References.repair(players,head)),References.frames(References.reconcile(players,rest))} == Con{_,References.frames(rest)} : List<&2,References.Frame>}
      %References.reconcile_frames(rest,players) : {Con{References.frame(References.repair(players,head)),References.frames(References.reconcile(players,rest))} == Con{References.frame(References.repair(players,head)),_} : List<&2,References.Frame>}
      {==}

law References.remove_frames:
  for +state: S.Simulation.State
  for +pid: U32
  {References.frames(S.Simulation.monsters(References.remove_state(state,pid))) == References.frames(S.Simulation.monsters(state)) : List<&2,References.Frame>}

def References.remove_frames(state,pid):
  match state:
    case S.Simulation.State{meta,players,monsters}: References.reconcile_frames(monsters,P.Players.others(P.Players.take(players,pid)))

law References.world_valid:
  for +world: T.Terrain.World
  for +pid: U32
  References.All(S.Simulation.players(T.Terrain.simulation(References.remove(world,pid))),S.Simulation.monsters(T.Terrain.simulation(References.remove(world,pid))))

def References.world_valid(world,pid):
  match world:
    case T.Terrain.World{meta,players,monsters,maps}: References.remove_valid(S.Simulation.State{meta,players,monsters},pid)

def References.trace(targets: List<&2,U32>,state: S.Simulation.State) -> S.Simulation.State:
  match targets:
    case Nil{}: state
    case Con{head,rest}: References.trace(rest,References.remove_state(state,head))

law References.trace_valid:
  for +targets: List<&2,U32>
  for +state: S.Simulation.State
  for +valid: References.All(S.Simulation.players(state),S.Simulation.monsters(state))
  References.All(S.Simulation.players(References.trace(targets,state)),S.Simulation.monsters(References.trace(targets,state)))

def References.trace_valid(targets,state,valid):
  match targets:
    case Nil{}: valid
    case Con{head,rest}: References.trace_valid(rest,References.remove_state(state,head),References.remove_valid(state,head))

law References.trace_ok:
  for +targets: List<&2,U32>
  for +state: S.Simulation.State
  for +valid: S.Simulation.OK<state>
  S.Simulation.OK<References.trace(targets,state)>

def References.trace_ok(targets,state,valid):
  match targets:
    case Nil{}: valid
    case Con{head,rest}: References.trace_ok(rest,References.remove_state(state,head),References.remove_ok(state,head,valid))

law References.trace_positions:
  for +targets: List<&2,U32>
  for +seed: U32
  for +state: S.Simulation.State
  for +valid: Plan.Planning.Positions<seed,state>
  Plan.Planning.Positions<seed,References.trace(targets,state)>

def References.trace_positions(targets,seed,state,valid):
  match targets:
    case Nil{}: valid
    case Con{head,rest}: References.trace_positions(rest,seed,References.remove_state(state,head),References.remove_positions(seed,state,head,valid))

law References.spawn_positive_target:
  for +value: Nat
  for +mid: U32
  for +kind: U32
  for +rare: U32
  for +zone: U32
  for +x: U32
  for +y: U32
  for +maximum: U32
  {References.target(M.Monsters.spawn_positive(value,mid,kind,rare,zone,x,y,maximum)) == 0 : U32}

def References.spawn_positive_target(value,mid,kind,rare,zone,x,y,maximum):
  match value:
    case Zero{}: {==}
    case Succ{rest}: {==}

law References.spawn_valid:
  for +players: List<&2,P.Players.State>
  for +mid: U32
  for +kind: U32
  for +rare: U32
  for +zone: U32
  for +x: U32
  for +y: U32
  for +maximum: U32
  References.Valid(players,M.Monsters.spawn(mid,kind,rare,zone,x,y,maximum))

def References.spawn_valid(players,mid,kind,rare,zone,x,y,maximum):
  %Equal.sym(U32,References.target(M.Monsters.spawn(mid,kind,rare,zone,x,y,maximum)),0,References.spawn_positive_target(U32.to_nat(maximum),mid,kind,rare,zone,x,y,maximum)) : {References.exists(players,_) == True{} : Bool}
  {==}

law References.at_valid:
  for +players: List<&2,P.Players.State>
  for +mid: U32
  for +kind: U32
  for +rare: U32
  for +pos: P.Players.Pos
  for +maximum: U32
  References.Valid(players,Pop.Population.at(mid,kind,rare,pos,maximum))

def References.at_valid(players,mid,kind,rare,pos,maximum):
  match pos:
    case P.Players.Pos{zone,x,y,dir,moving}: References.spawn_valid(players,mid,kind,rare,zone,x,y,maximum)

law References.monster_valid:
  for +players: List<&2,P.Players.State>
  for +maps: T.Terrain.Maps
  for +mid: U32
  for +zone: U32
  for +salt: U32
  for +rare: U32
  References.Valid(players,Pop.Population.monster(maps,mid,zone,salt,rare))

def References.monster_valid(players,maps,mid,zone,salt,rare):
  +kind = Pop.Population.kind(zone,salt)
  References.at_valid(players,mid,kind,rare,Place.Placement.spot(maps,zone,U32.add(U32.mul(salt,977),mid)),U32.mul(Pop.Population.maximum(kind),U32.add(1,U32.mul(7,rare))))

law References.boss_valid:
  for +players: List<&2,P.Players.State>
  for +mid: U32
  for +zone: U32
  References.Valid(players,Pop.Population.boss(mid,zone))

def References.boss_valid(players,mid,zone): References.at_valid(players,mid,U32.add(6,zone),0,Pop.Population.boss_pos(zone),Pop.Population.maximum(U32.add(6,zone)))

law References.populate_value_valid:
  for +count: Nat
  for +players: List<&2,P.Players.State>
  for +maps: T.Terrain.Maps
  for +zone: U32
  for +base: U32
  References.All(players,Pop.Population.populate_value(count,maps,zone,base))

def References.populate_value_valid(count,players,maps,zone,base):
  match count:
    case Zero{}: Unit{}
    case Succ{rest}:
      +n = U32.from_nat(rest)
      +mid = U32.add(U32.add(base,1),n)
      +rare = L.Landscape.pick(U32.is_lt(U32.mod(L.Landscape.hash(mid,U32.add(zone,31)),100),Pop.Population.rare_pct),1,0)
      Tuple{References.monster_valid(players,maps,mid,zone,L.Landscape.hash(U32.add(U32.add(U32.mul(zone,100),1),n),555),rare),References.populate_value_valid(rest,players,maps,zone,base)}

law References.populate_valid:
  for +count: Nat
  for +players: List<&2,P.Players.State>
  for +maps: T.Terrain.Maps
  for +zone: U32
  for +base: U32
  References.All(players,Pop.Population.populate(count,maps,zone,base))

def References.populate_valid(count,players,maps,zone,base):
  %Equal.sym(List<&2,M.Monsters.State>,Pop.Population.populate(count,maps,zone,base),Pop.Population.populate_value(count,maps,zone,base),Pop.Population.populate_refines(count,maps,zone,base)) : References.All(players,_)
  References.populate_value_valid(count,players,maps,zone,base)

law References.concat_valid:
  for +left: List<&2,M.Monsters.State>
  for +right: List<&2,M.Monsters.State>
  for +players: List<&2,P.Players.State>
  for +left_ok: References.All(players,left)
  for +right_ok: References.All(players,right)
  References.All(players,R.Roster.concat(left,right))

def References.concat_valid(left,right,players,left_ok,right_ok):
  match left:
    case Nil{}: right_ok
    case Con{head,rest}:
      match left_ok:
        case Tuple{head_ok,rest_ok}: Tuple{head_ok,References.concat_valid(rest,right,players,rest_ok,right_ok)}

law References.bosses_valid:
  for +players: List<&2,P.Players.State>
  References.All(players,Pop.Population.bosses)

def References.bosses_valid(players): Tuple{References.boss_valid(players,1,0),Tuple{References.boss_valid(players,2,1),Tuple{References.boss_valid(players,3,2),Tuple{References.boss_valid(players,4,3),Unit{}}}}}

law References.initial_valid:
  for +players: List<&2,P.Players.State>
  for +maps: T.Terrain.Maps
  References.All(players,Pop.Population.initial(maps))

def References.initial_valid(players,maps):
  +a = Pop.Population.populate(U32.to_nat(Pop.Population.cap),maps,0,100)
  +b = Pop.Population.populate(U32.to_nat(Pop.Population.cap),maps,1,200)
  +c = Pop.Population.populate(U32.to_nat(Pop.Population.cap),maps,2,300)
  References.concat_valid(Pop.Population.bosses,R.Roster.concat(a,R.Roster.concat(b,c)),players,References.bosses_valid(players),References.concat_valid(a,R.Roster.concat(b,c),players,References.populate_valid(U32.to_nat(Pop.Population.cap),players,maps,0,100),References.concat_valid(b,c,players,References.populate_valid(U32.to_nat(Pop.Population.cap),players,maps,1,200),References.populate_valid(U32.to_nat(Pop.Population.cap),players,maps,2,300))))

law References.fresh_valid:
  for +world: U32
  for +seed: U32
  for +now: U32
  References.All(S.Simulation.players(T.Terrain.simulation(Pop.Population.fresh(world,seed,now))),S.Simulation.monsters(T.Terrain.simulation(Pop.Population.fresh(world,seed,now))))

def References.fresh_valid(world,seed,now): References.initial_valid(Nil{},L.Landscape.maps(seed))
