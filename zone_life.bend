# Lifetime certificates follow actual zone filtering, plans and merged outputs.
import Base
import ./monster_life.bend as Life
import ./monsters.bend as M
import ./vitals.bend as V
import ./ai.bend as A
import ./zones.bend as Z
import ./roster.bend as R
import ./combat_targets.bend as Targets
import ./numeric.bend as N
import ./identity.bend as I
import ./planning.bend as Plan
import ./terrain.bend as T
import ./simulation.bend as S
import ./players.bend as P

law ZoneLife.keep_member:
  for +flag: Bool
  for +head: M.Monsters.State
  for +tail: List<&2,M.Monsters.State>
  for +monster: M.Monsters.State
  for +inside: Targets.Targets.In<monster,tail>
  Targets.Targets.In<monster,R.Roster.keep(flag,head,tail)>

def ZoneLife.keep_member(flag,head,tail,monster,inside):
  match flag:
    case True{}: Targets.Targets.There{head,tail,{==},inside}
    case False{}: inside

law ZoneLife.zone_member:
  for +monster: M.Monsters.State
  for -monsters: List<&2,M.Monsters.State>
  for +inside: Targets.Targets.In<monster,monsters>
  Targets.Targets.In<monster,R.Roster.zone(monsters,R.Roster.zone_of(monster))>

def ZoneLife.zone_member(monster,monsters,inside):
  match inside:
    case Targets.Targets.Here{rest,shape}:
      %Equal.sym(List<&2,M.Monsters.State>,monsters,Con{monster,rest},shape) : Targets.Targets.In<monster,R.Roster.zone(_,R.Roster.zone_of(monster))>
      %Equal.sym(Bool,U32.is_eq(R.Roster.zone_of(monster),R.Roster.zone_of(monster)),True{},N.Numeric.u32_eq_refl(R.Roster.zone_of(monster))) : Targets.Targets.In<monster,R.Roster.keep(_,monster,R.Roster.zone(rest,R.Roster.zone_of(monster)))>
      Targets.Targets.Here{R.Roster.zone(rest,R.Roster.zone_of(monster)),{==}}
    case Targets.Targets.There{head,rest,shape,earlier}:
      %Equal.sym(List<&2,M.Monsters.State>,monsters,Con{head,rest},shape) : Targets.Targets.In<monster,R.Roster.zone(_,R.Roster.zone_of(monster))>
      ZoneLife.keep_member(U32.is_eq(R.Roster.zone_of(head),R.Roster.zone_of(monster)),head,R.Roster.zone(rest,R.Roster.zone_of(monster)),monster,ZoneLife.zone_member(monster,rest,earlier))

law ZoneLife.concat_left:
  for +monster: M.Monsters.State
  for -left: List<&2,M.Monsters.State>
  for +right: List<&2,M.Monsters.State>
  for +inside: Targets.Targets.In<monster,left>
  Targets.Targets.In<monster,R.Roster.concat(left,right)>

def ZoneLife.concat_left(monster,left,right,inside):
  match inside:
    case Targets.Targets.Here{rest,shape}:
      %Equal.sym(List<&2,M.Monsters.State>,left,Con{monster,rest},shape) : Targets.Targets.In<monster,R.Roster.concat(_,right)>
      Targets.Targets.Here{R.Roster.concat(rest,right),{==}}
    case Targets.Targets.There{head,rest,shape,earlier}:
      %Equal.sym(List<&2,M.Monsters.State>,left,Con{head,rest},shape) : Targets.Targets.In<monster,R.Roster.concat(_,right)>
      Targets.Targets.There{head,R.Roster.concat(rest,right),{==},ZoneLife.concat_left(monster,rest,right,earlier)}

law ZoneLife.concat_right:
  for +monster: M.Monsters.State
  for +left: List<&2,M.Monsters.State>
  for +right: List<&2,M.Monsters.State>
  for +inside: Targets.Targets.In<monster,right>
  Targets.Targets.In<monster,R.Roster.concat(left,right)>

def ZoneLife.concat_right(monster,left,right,inside):
  match left:
    case Nil{}: inside
    case Con{head,rest}: Targets.Targets.There{head,R.Roster.concat(rest,right),{==},ZoneLife.concat_right(monster,rest,right,inside)}

law ZoneLife.merge_left:
  for +monster: M.Monsters.State
  for +left: A.AI.Result
  for +right: A.AI.Result
  for +inside: Targets.Targets.In<monster,A.AI.monsters(left)>
  Targets.Targets.In<monster,A.AI.monsters(A.AI.merge(left,right))>

def ZoneLife.merge_left(monster,left,right,inside):
  match left:
    case A.AI.Result{lm,lh}:
      match right:
        case A.AI.Result{rm,rh}: ZoneLife.concat_left(monster,lm,rm,inside)

law ZoneLife.merge_right:
  for +monster: M.Monsters.State
  for +left: A.AI.Result
  for +right: A.AI.Result
  for +inside: Targets.Targets.In<monster,A.AI.monsters(right)>
  Targets.Targets.In<monster,A.AI.monsters(A.AI.merge(left,right))>

def ZoneLife.merge_right(monster,left,right,inside):
  match left:
    case A.AI.Result{lm,lh}:
      match right:
        case A.AI.Result{rm,rh}: ZoneLife.concat_right(monster,lm,rm,inside)

def ZoneLife.plans(-zone: U32,valid: Z.Zones.Valid<zone>,p0: List<&2,A.AI.Plan>,p1: List<&2,A.AI.Plan>,p2: List<&2,A.AI.Plan>,p3: List<&2,A.AI.Plan>) -> List<&2,A.AI.Plan>:
  match valid:
    case Z.Zones.Hollow{equal}: p0
    case Z.Zones.Cavern{equal}: p1
    case Z.Zones.Frost{equal}: p2
    case Z.Zones.Rift{equal}: p3

law ZoneLife.embed:
  for +monster: M.Monsters.State
  for +monsters: List<&2,M.Monsters.State>
  for +zone: U32
  for +p0: List<&2,A.AI.Plan>
  for +p1: List<&2,A.AI.Plan>
  for +p2: List<&2,A.AI.Plan>
  for +p3: List<&2,A.AI.Plan>
  for +valid: Z.Zones.Valid<zone>
  for +inside: Targets.Targets.In<monster,A.AI.monsters(A.AI.run(R.Roster.zone(monsters,zone),ZoneLife.plans(zone,valid,p0,p1,p2,p3)))>
  Targets.Targets.In<monster,A.AI.monsters(A.AI.run_zones(monsters,p0,p1,p2,p3))>

def ZoneLife.embed(monster,monsters,zone,p0,p1,p2,p3,valid,inside):
  match valid:
    case Z.Zones.Hollow{equal}: ZoneLife.merge_left(monster,A.AI.run(R.Roster.zone(monsters,0),p0),A.AI.merge(A.AI.run(R.Roster.zone(monsters,1),p1),A.AI.merge(A.AI.run(R.Roster.zone(monsters,2),p2),A.AI.run(R.Roster.zone(monsters,3),p3))),(%equal : Targets.Targets.In<monster,A.AI.monsters(A.AI.run(R.Roster.zone(monsters,_),p0))>; inside))
    case Z.Zones.Cavern{equal}: ZoneLife.merge_right(monster,A.AI.run(R.Roster.zone(monsters,0),p0),A.AI.merge(A.AI.run(R.Roster.zone(monsters,1),p1),A.AI.merge(A.AI.run(R.Roster.zone(monsters,2),p2),A.AI.run(R.Roster.zone(monsters,3),p3))),ZoneLife.merge_left(monster,A.AI.run(R.Roster.zone(monsters,1),p1),A.AI.merge(A.AI.run(R.Roster.zone(monsters,2),p2),A.AI.run(R.Roster.zone(monsters,3),p3)),(%equal : Targets.Targets.In<monster,A.AI.monsters(A.AI.run(R.Roster.zone(monsters,_),p1))>; inside)))
    case Z.Zones.Frost{equal}: ZoneLife.merge_right(monster,A.AI.run(R.Roster.zone(monsters,0),p0),A.AI.merge(A.AI.run(R.Roster.zone(monsters,1),p1),A.AI.merge(A.AI.run(R.Roster.zone(monsters,2),p2),A.AI.run(R.Roster.zone(monsters,3),p3))),ZoneLife.merge_right(monster,A.AI.run(R.Roster.zone(monsters,1),p1),A.AI.merge(A.AI.run(R.Roster.zone(monsters,2),p2),A.AI.run(R.Roster.zone(monsters,3),p3)),ZoneLife.merge_left(monster,A.AI.run(R.Roster.zone(monsters,2),p2),A.AI.run(R.Roster.zone(monsters,3),p3),(%equal : Targets.Targets.In<monster,A.AI.monsters(A.AI.run(R.Roster.zone(monsters,_),p2))>; inside))))
    case Z.Zones.Rift{equal}: ZoneLife.merge_right(monster,A.AI.run(R.Roster.zone(monsters,0),p0),A.AI.merge(A.AI.run(R.Roster.zone(monsters,1),p1),A.AI.merge(A.AI.run(R.Roster.zone(monsters,2),p2),A.AI.run(R.Roster.zone(monsters,3),p3))),ZoneLife.merge_right(monster,A.AI.run(R.Roster.zone(monsters,1),p1),A.AI.merge(A.AI.run(R.Roster.zone(monsters,2),p2),A.AI.run(R.Roster.zone(monsters,3),p3)),ZoneLife.merge_right(monster,A.AI.run(R.Roster.zone(monsters,2),p2),A.AI.run(R.Roster.zone(monsters,3),p3),(%equal : Targets.Targets.In<monster,A.AI.monsters(A.AI.run(R.Roster.zone(monsters,_),p3))>; inside))))

# The exact plan at the monster's position after filtering its own zone.
def ZoneLife.plan(+monster: M.Monsters.State,+monsters: List<&2,M.Monsters.State>,p0: List<&2,A.AI.Plan>,p1: List<&2,A.AI.Plan>,p2: List<&2,A.AI.Plan>,p3: List<&2,A.AI.Plan>,valid: Z.Zones.Valid<R.Roster.zone_of(monster)>,+inside: Targets.Targets.In<monster,monsters>) -> A.AI.Plan:
  Life.Life.plan_for(monster,R.Roster.zone(monsters,R.Roster.zone_of(monster)),ZoneLife.plans(R.Roster.zone_of(monster),valid,p0,p1,p2,p3),ZoneLife.zone_member(monster,monsters,inside))

law ZoneLife.run_member:
  for +monster: M.Monsters.State
  for +monsters: List<&2,M.Monsters.State>
  for +p0: List<&2,A.AI.Plan>
  for +p1: List<&2,A.AI.Plan>
  for +p2: List<&2,A.AI.Plan>
  for +p3: List<&2,A.AI.Plan>
  for +valid: Z.Zones.Valid<R.Roster.zone_of(monster)>
  for +inside: Targets.Targets.In<monster,monsters>
  Targets.Targets.In<A.AI.monster(A.AI.step(monster,ZoneLife.plan(monster,monsters,p0,p1,p2,p3,valid,inside))),A.AI.monsters(A.AI.run_zones(monsters,p0,p1,p2,p3))>

def ZoneLife.run_member(monster,monsters,p0,p1,p2,p3,valid,inside):
  ZoneLife.embed(A.AI.monster(A.AI.step(monster,ZoneLife.plan(monster,monsters,p0,p1,p2,p3,valid,inside))),monsters,R.Roster.zone_of(monster),p0,p1,p2,p3,valid,Life.Life.run_member(monster,R.Roster.zone(monsters,R.Roster.zone_of(monster)),ZoneLife.plans(R.Roster.zone_of(monster),valid,p0,p1,p2,p3),ZoneLife.zone_member(monster,monsters,inside)))

type ZoneLife.Follow<-monster: M.Monsters.State,-plan: A.AI.Plan,-monsters: List<&2,M.Monsters.State>> is Data:
  ZoneLife.Follow{certificate: Life.Life.Certificate<monster,plan>,member: Targets.Targets.In<A.AI.monster(A.AI.step(monster,plan)),monsters>}

law ZoneLife.follow:
  for +monster: M.Monsters.State
  for +monsters: List<&2,M.Monsters.State>
  for +p0: List<&2,A.AI.Plan>
  for +p1: List<&2,A.AI.Plan>
  for +p2: List<&2,A.AI.Plan>
  for +p3: List<&2,A.AI.Plan>
  for +valid: Z.Zones.Valid<R.Roster.zone_of(monster)>
  for +inside: Targets.Targets.In<monster,monsters>
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  ZoneLife.Follow<monster,ZoneLife.plan(monster,monsters,p0,p1,p2,p3,valid,inside),A.AI.monsters(A.AI.run_zones(monsters,p0,p1,p2,p3))>

def ZoneLife.follow(monster,monsters,p0,p1,p2,p3,valid,inside,dead): ZoneLife.Follow{Life.Life.classify(monster,ZoneLife.plan(monster,monsters,p0,p1,p2,p3,valid,inside),dead),ZoneLife.run_member(monster,monsters,p0,p1,p2,p3,valid,inside)}

law ZoneLife.final_lookup:
  for +monster: M.Monsters.State
  for +monsters: List<&2,M.Monsters.State>
  for +p0: List<&2,A.AI.Plan>
  for +p1: List<&2,A.AI.Plan>
  for +p2: List<&2,A.AI.Plan>
  for +p3: List<&2,A.AI.Plan>
  for +valid: Z.Zones.Valid<R.Roster.zone_of(monster)>
  for +inside: Targets.Targets.In<monster,monsters>
  for +zones: Z.Zones.All(monsters)
  for +unique: I.Identity.Monsters(monsters)
  {R.Roster.found(R.Roster.take(A.AI.monsters(A.AI.run_zones(monsters,p0,p1,p2,p3)),R.Roster.id(monster))) == Some{A.AI.monster(A.AI.step(monster,ZoneLife.plan(monster,monsters,p0,p1,p2,p3,valid,inside)))} : Maybe<&2,M.Monsters.State>}

def ZoneLife.final_lookup(monster,monsters,p0,p1,p2,p3,valid,inside,zones,unique):
  %Life.Life.step_id(monster,ZoneLife.plan(monster,monsters,p0,p1,p2,p3,valid,inside)) : {R.Roster.found(R.Roster.take(A.AI.monsters(A.AI.run_zones(monsters,p0,p1,p2,p3)),_)) == Some{A.AI.monster(A.AI.step(monster,ZoneLife.plan(monster,monsters,p0,p1,p2,p3,valid,inside)))} : Maybe<&2,M.Monsters.State>}
  Targets.Targets.lookup_member(A.AI.monster(A.AI.step(monster,ZoneLife.plan(monster,monsters,p0,p1,p2,p3,valid,inside))),A.AI.monsters(A.AI.run_zones(monsters,p0,p1,p2,p3)),ZoneLife.run_member(monster,monsters,p0,p1,p2,p3,valid,inside),I.Identity.run_zones_unique(monsters,p0,p1,p2,p3,zones,unique))

# These plans are exactly Planning.actions' four actual context-based lists.
def ZoneLife.run_planned(+monsters: List<&2,M.Monsters.State>,c0: List<&2,Plan.Planning.Context>,c1: List<&2,Plan.Planning.Context>,c2: List<&2,Plan.Planning.Context>,c3: List<&2,Plan.Planning.Context>,+maps: T.Terrain.Maps,+tick: U32) -> A.AI.Result:
  A.AI.run_zones(monsters,Plan.Planning.plans(R.Roster.zone(monsters,0),c0,maps,tick),Plan.Planning.plans(R.Roster.zone(monsters,1),c1,maps,tick),Plan.Planning.plans(R.Roster.zone(monsters,2),c2,maps,tick),Plan.Planning.plans(R.Roster.zone(monsters,3),c3,maps,tick))

def ZoneLife.planned_plan(+monster: M.Monsters.State,+monsters: List<&2,M.Monsters.State>,c0: List<&2,Plan.Planning.Context>,c1: List<&2,Plan.Planning.Context>,c2: List<&2,Plan.Planning.Context>,c3: List<&2,Plan.Planning.Context>,+maps: T.Terrain.Maps,+tick: U32,valid: Z.Zones.Valid<R.Roster.zone_of(monster)>,+inside: Targets.Targets.In<monster,monsters>) -> A.AI.Plan:
  ZoneLife.plan(monster,monsters,Plan.Planning.plans(R.Roster.zone(monsters,0),c0,maps,tick),Plan.Planning.plans(R.Roster.zone(monsters,1),c1,maps,tick),Plan.Planning.plans(R.Roster.zone(monsters,2),c2,maps,tick),Plan.Planning.plans(R.Roster.zone(monsters,3),c3,maps,tick),valid,inside)

law ZoneLife.planned:
  for +monster: M.Monsters.State
  for +monsters: List<&2,M.Monsters.State>
  for +c0: List<&2,Plan.Planning.Context>
  for +c1: List<&2,Plan.Planning.Context>
  for +c2: List<&2,Plan.Planning.Context>
  for +c3: List<&2,Plan.Planning.Context>
  for +maps: T.Terrain.Maps
  for +tick: U32
  for +valid: Z.Zones.Valid<R.Roster.zone_of(monster)>
  for +inside: Targets.Targets.In<monster,monsters>
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  ZoneLife.Follow<monster,ZoneLife.planned_plan(monster,monsters,c0,c1,c2,c3,maps,tick,valid,inside),A.AI.monsters(ZoneLife.run_planned(monsters,c0,c1,c2,c3,maps,tick))>

def ZoneLife.planned(monster,monsters,c0,c1,c2,c3,maps,tick,valid,inside,dead): ZoneLife.follow(monster,monsters,Plan.Planning.plans(R.Roster.zone(monsters,0),c0,maps,tick),Plan.Planning.plans(R.Roster.zone(monsters,1),c1,maps,tick),Plan.Planning.plans(R.Roster.zone(monsters,2),c2,maps,tick),Plan.Planning.plans(R.Roster.zone(monsters,3),c3,maps,tick),valid,inside,dead)

# The active actual Planning.finish retains the very same updated AI roster,
# while applying attacks to players and advancing world metadata.
law ZoneLife.finish:
  for +meta: S.Simulation.Meta
  for +monsters: List<&2,M.Monsters.State>
  for +upkeep: P.Players.Result
  for +maps: T.Terrain.Maps
  for +c0: List<&2,Plan.Planning.Context>
  for +c1: List<&2,Plan.Planning.Context>
  for +c2: List<&2,Plan.Planning.Context>
  for +c3: List<&2,Plan.Planning.Context>
  for +rules: S.Simulation.Rules
  for +monster: M.Monsters.State
  for +valid: Z.Zones.Valid<R.Roster.zone_of(monster)>
  for +inside: Targets.Targets.In<monster,monsters>
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  ZoneLife.Follow<monster,ZoneLife.planned_plan(monster,monsters,c0,c1,c2,c3,maps,S.Simulation.clock(meta),valid,inside),S.Simulation.monsters(S.Simulation.state(Plan.Planning.finish(S.Simulation.Prepared{meta,monsters,upkeep,True{}},maps,c0,c1,c2,c3,rules)))>

def ZoneLife.finish(meta,monsters,upkeep,maps,c0,c1,c2,c3,rules,monster,valid,inside,dead):
  match rules:
    case S.Simulation.Rules{spawn_x,spawn_y,timer}: ZoneLife.planned(monster,monsters,c0,c1,c2,c3,maps,S.Simulation.clock(meta),valid,inside,dead)
