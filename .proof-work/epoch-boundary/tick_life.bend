# Dead-monster lifetime certificates for the actual complete live world tick.
import Base
import ./monster_life.bend as Life
import ./zone_life.bend as ZL
import ./monsters.bend as M
import ./vitals.bend as V
import ./ai.bend as A
import ./zones.bend as Z
import ./roster.bend as R
import ./combat_targets.bend as Targets
import ./identity.bend as I
import ./planning.bend as Plan
import ./terrain.bend as T
import ./simulation.bend as S
import ./players.bend as P
import ./ai_refs.bend as Refs
import ./locomotion.bend as Walk
import ./live_tick.bend as Tick
import ./live_dead.bend as LD
import ./dead_rewards.bend as Dead

# None means the actual inactive tick did not execute AI upkeep.
def TickLife.after(+monster: M.Monsters.State,mode: Maybe<&2,A.AI.Plan>) -> M.Monsters.State:
  match mode:
    case None{}: monster
    case Some{plan}: A.AI.monster(A.AI.step(monster,plan))

def TickLife.event(+monster: M.Monsters.State,mode: Maybe<&2,A.AI.Plan>) -> Bool:
  match mode:
    case None{}: False{}
    case Some{plan}: Life.Life.reborn(monster,plan)

def TickLife.Quiet(+monster: M.Monsters.State,mode: Maybe<&2,A.AI.Plan>) -> Data:
  match mode:
    case None{}: Unit
    case Some{plan}: {A.AI.hit(A.AI.step(monster,plan)) == None{} : Maybe<&2,A.AI.Hit>}

type TickLife.Tracked<-monster: M.Monsters.State,-mode: Maybe<&2,A.AI.Plan>,-monsters: List<&2,M.Monsters.State>> is Data:
  TickLife.Tracked{inside: Targets.Targets.In<TickLife.after(monster,mode),monsters>,key: {Z.Zones.key(TickLife.after(monster,mode)) == Z.Zones.key(monster) : Z.Zones.Key},dead: {V.Vitals.dead(M.Monsters.vitals(TickLife.after(monster,mode))) == Targets.Targets.pick(TickLife.event(monster,mode),0,1) : U32},quiet: TickLife.Quiet(monster,mode),unique: I.Identity.Monsters(monsters)}

law TickLife.paused:
  for +monster: M.Monsters.State
  for +monsters: List<&2,M.Monsters.State>
  for +inside: Targets.Targets.In<monster,monsters>
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  for +unique: I.Identity.Monsters(monsters)
  TickLife.Tracked<monster,None{},monsters>

def TickLife.paused(monster,monsters,inside,dead,unique): TickLife.Tracked{inside,{==},dead,Unit{},unique}

law TickLife.from_follow:
  for +monster: M.Monsters.State
  for +plan: A.AI.Plan
  for +monsters: List<&2,M.Monsters.State>
  for +follow: ZL.ZoneLife.Follow<monster,plan,monsters>
  for +unique: I.Identity.Monsters(monsters)
  TickLife.Tracked<monster,Some{plan},monsters>

def TickLife.from_follow(monster,plan,monsters,follow,unique):
  match follow:
    case ZL.ZoneLife.Follow{certificate,member}:
      match certificate:
        case Life.Life.Certificate{actual,same,key,quiet,dead}:
          TickLife.Tracked{member,(%same : {Z.Zones.key(A.AI.monster(_)) == Z.Zones.key(monster) : Z.Zones.Key}; key),(%same : {V.Vitals.dead(M.Monsters.vitals(A.AI.monster(_))) == Targets.Targets.pick(Life.Life.reborn(monster,plan),0,1) : U32}; dead),(%same : {A.AI.hit(_) == None{} : Maybe<&2,A.AI.Hit>}; quiet),unique}

# Select against actual post-upkeep players and actual per-zone damage lists.
def TickLife.mode(+prepared: S.Simulation.Prepared,+maps: T.Terrain.Maps,d0: List<&2,U32>,d1: List<&2,U32>,d2: List<&2,U32>,d3: List<&2,U32>,+monster: M.Monsters.State,valid: Z.Zones.Valid<R.Roster.zone_of(monster)>,+inside: Targets.Targets.In<monster,S.Simulation.prepared_monsters(prepared)>) -> Maybe<&2,A.AI.Plan>:
  match prepared:
    case S.Simulation.Prepared{meta,monsters,upkeep,running}:
      match running:
        case False{}: None{}
        case True{}:
          +players = P.Players.roster(upkeep)
          Some{ZL.ZoneLife.planned_plan(monster,monsters,Refs.AIRefs.contexts(monsters,players,0,d0),Refs.AIRefs.contexts(monsters,players,1,d1),Refs.AIRefs.contexts(monsters,players,2,d2),Refs.AIRefs.contexts(monsters,players,3,d3),maps,S.Simulation.clock(meta),valid,inside)}

law TickLife.finish:
  for +prepared: S.Simulation.Prepared
  for +maps: T.Terrain.Maps
  for +d0: List<&2,U32>
  for +d1: List<&2,U32>
  for +d2: List<&2,U32>
  for +d3: List<&2,U32>
  for +rules: S.Simulation.Rules
  for +monster: M.Monsters.State
  for +valid: Z.Zones.Valid<R.Roster.zone_of(monster)>
  for +inside: Targets.Targets.In<monster,S.Simulation.prepared_monsters(prepared)>
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  for +zones: Z.Zones.All(S.Simulation.prepared_monsters(prepared))
  for +unique: I.Identity.Monsters(S.Simulation.prepared_monsters(prepared))
  TickLife.Tracked<monster,TickLife.mode(prepared,maps,d0,d1,d2,d3,monster,valid,inside),S.Simulation.monsters(S.Simulation.state(Refs.AIRefs.finish(prepared,maps,d0,d1,d2,d3,rules)))>

def TickLife.finish(prepared,maps,d0,d1,d2,d3,rules,monster,valid,inside,dead,zones,unique):
  match prepared:
    case S.Simulation.Prepared{meta,monsters,upkeep,running}:
      match running:
        case False{}: TickLife.paused(monster,monsters,inside,dead,unique)
        case True{}:
          +players = P.Players.roster(upkeep)
          +c0 = Refs.AIRefs.contexts(monsters,players,0,d0)
          +c1 = Refs.AIRefs.contexts(monsters,players,1,d1)
          +c2 = Refs.AIRefs.contexts(monsters,players,2,d2)
          +c3 = Refs.AIRefs.contexts(monsters,players,3,d3)
          TickLife.from_follow(monster,ZL.ZoneLife.planned_plan(monster,monsters,c0,c1,c2,c3,maps,S.Simulation.clock(meta),valid,inside),S.Simulation.monsters(S.Simulation.state(Plan.Planning.finish(S.Simulation.Prepared{meta,monsters,upkeep,True{}},maps,c0,c1,c2,c3,rules))),ZL.ZoneLife.finish(meta,monsters,upkeep,maps,c0,c1,c2,c3,rules,monster,valid,inside,dead),I.Identity.planning_finish_unique(S.Simulation.Prepared{meta,monsters,upkeep,True{}},maps,c0,c1,c2,c3,rules,zones,unique))

def TickLife.chosen(damages: Refs.AIRefs.Damages,+prepared: S.Simulation.Prepared,maps: T.Terrain.Maps,+monster: M.Monsters.State,valid: Z.Zones.Valid<R.Roster.zone_of(monster)>,inside: Targets.Targets.In<monster,S.Simulation.prepared_monsters(prepared)>) -> Maybe<&2,A.AI.Plan>:
  match damages:
    case Refs.AIRefs.Damages{d0,d1,d2,d3}: TickLife.mode(prepared,maps,d0,d1,d2,d3,monster,valid,inside)

law TickLife.simulate:
  for +damages: Refs.AIRefs.Damages
  for +prepared: S.Simulation.Prepared
  for +maps: T.Terrain.Maps
  for +rules: S.Simulation.Rules
  for +monster: M.Monsters.State
  for +valid: Z.Zones.Valid<R.Roster.zone_of(monster)>
  for +inside: Targets.Targets.In<monster,S.Simulation.prepared_monsters(prepared)>
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  for +zones: Z.Zones.All(S.Simulation.prepared_monsters(prepared))
  for +unique: I.Identity.Monsters(S.Simulation.prepared_monsters(prepared))
  TickLife.Tracked<monster,TickLife.chosen(damages,prepared,maps,monster,valid,inside),S.Simulation.monsters(S.Simulation.state(Tick.LiveTick.simulate(damages,prepared,maps,rules)))>

def TickLife.simulate(damages,prepared,maps,rules,monster,valid,inside,dead,zones,unique):
  match damages:
    case Refs.AIRefs.Damages{d0,d1,d2,d3}: TickLife.finish(prepared,maps,d0,d1,d2,d3,rules,monster,valid,inside,dead,zones,unique)

law TickLife.finish_tick:
  for +prepared: S.Simulation.Prepared
  for +maps: T.Terrain.Maps
  for +rules: S.Simulation.Rules
  for +monster: M.Monsters.State
  for +valid: Z.Zones.Valid<R.Roster.zone_of(monster)>
  for +inside: Targets.Targets.In<monster,S.Simulation.prepared_monsters(prepared)>
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  for +zones: Z.Zones.All(S.Simulation.prepared_monsters(prepared))
  for +unique: I.Identity.Monsters(S.Simulation.prepared_monsters(prepared))
  TickLife.Tracked<monster,TickLife.chosen(Tick.LiveTick.damages(prepared),prepared,maps,monster,valid,inside),S.Simulation.monsters(T.Terrain.simulation(Tick.LiveTick.world(Tick.LiveTick.finish(prepared,maps,rules))))>

def TickLife.finish_tick(prepared,maps,rules,monster,valid,inside,dead,zones,unique):
  %Equal.sym(S.Simulation.State,T.Terrain.simulation(Tick.LiveTick.world(Tick.LiveTick.pack(Tick.LiveTick.simulate(Tick.LiveTick.damages(prepared),prepared,maps,rules),maps,S.Simulation.clock(S.Simulation.prepared_meta(prepared))))),S.Simulation.state(Tick.LiveTick.simulate(Tick.LiveTick.damages(prepared),prepared,maps,rules)),Tick.LiveTick.pack_simulation(Tick.LiveTick.simulate(Tick.LiveTick.damages(prepared),prepared,maps,rules),maps,S.Simulation.clock(S.Simulation.prepared_meta(prepared)))) : TickLife.Tracked<monster,TickLife.chosen(Tick.LiveTick.damages(prepared),prepared,maps,monster,valid,inside),S.Simulation.monsters(_)>
  TickLife.simulate(Tick.LiveTick.damages(prepared),prepared,maps,rules,monster,valid,inside,dead,zones,unique)

law TickLife.prepare_member:
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +rules: S.Simulation.Rules
  for +monster: M.Monsters.State
  for +inside: Targets.Targets.In<monster,S.Simulation.monsters(state)>
  Targets.Targets.In<monster,S.Simulation.prepared_monsters(Walk.Locomotion.begin(state,maps,rules))>

def TickLife.prepare_member(state,maps,rules,monster,inside):
  %Equal.sym(List<&2,M.Monsters.State>,S.Simulation.prepared_monsters(Walk.Locomotion.begin(state,maps,rules)),S.Simulation.monsters(state),Plan.Planning.begin_monsters(state,maps,rules)) : Targets.Targets.In<monster,_>
  inside

def TickLife.decision(+world: T.Terrain.World,+timer: U32,+monster: M.Monsters.State,+valid: Z.Zones.Valid<R.Roster.zone_of(monster)>,+inside: Targets.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(world))>) -> Maybe<&2,A.AI.Plan>:
  +state = T.Terrain.simulation(world)
  +maps = T.Terrain.maps(world)
  +rules = Plan.Planning.rules(timer)
  +prepared = Walk.Locomotion.begin(state,maps,rules)
  TickLife.chosen(Tick.LiveTick.damages(prepared),prepared,maps,monster,valid,TickLife.prepare_member(state,maps,rules,monster,inside))

law TickLife.run:
  for +world: T.Terrain.World
  for +timer: U32
  for +monster: M.Monsters.State
  for +valid: Z.Zones.Valid<R.Roster.zone_of(monster)>
  for +inside: Targets.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(world))>
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  for +zones: Z.Zones.All(S.Simulation.monsters(T.Terrain.simulation(world)))
  for +unique: I.Identity.Monsters(S.Simulation.monsters(T.Terrain.simulation(world)))
  TickLife.Tracked<monster,TickLife.decision(world,timer,monster,valid,inside),S.Simulation.monsters(T.Terrain.simulation(Tick.LiveTick.world(Tick.LiveTick.run(world,timer))))>

def TickLife.run(world,timer,monster,valid,inside,dead,zones,unique):
  +state = T.Terrain.simulation(world)
  +maps = T.Terrain.maps(world)
  +rules = Plan.Planning.rules(timer)
  +prepared = Walk.Locomotion.begin(state,maps,rules)
  +same = Equal.sym(List<&2,M.Monsters.State>,S.Simulation.prepared_monsters(prepared),S.Simulation.monsters(state),Plan.Planning.begin_monsters(state,maps,rules))
  TickLife.finish_tick(prepared,maps,rules,monster,valid,TickLife.prepare_member(state,maps,rules,monster,inside),dead,(%same : Z.Zones.All(_); zones),(%same : I.Identity.Monsters(_); unique))

law TickLife.after_id:
  for +monster: M.Monsters.State
  for +mode: Maybe<&2,A.AI.Plan>
  {R.Roster.id(TickLife.after(monster,mode)) == R.Roster.id(monster) : U32}

def TickLife.after_id(monster,mode):
  match mode:
    case None{}: {==}
    case Some{plan}: Life.Life.step_id(monster,plan)

law TickLife.lookup:
  for +monster: M.Monsters.State
  for +mode: Maybe<&2,A.AI.Plan>
  for +monsters: List<&2,M.Monsters.State>
  for +tracked: TickLife.Tracked<monster,mode,monsters>
  {R.Roster.found(R.Roster.take(monsters,R.Roster.id(monster))) == Some{TickLife.after(monster,mode)} : Maybe<&2,M.Monsters.State>}

def TickLife.lookup(monster,mode,monsters,tracked):
  match tracked:
    case TickLife.Tracked{inside,key,dead,quiet,unique}:
      %TickLife.after_id(monster,mode) : {R.Roster.found(R.Roster.take(monsters,_)) == Some{TickLife.after(monster,mode)} : Maybe<&2,M.Monsters.State>}
      Targets.Targets.lookup_member(TickLife.after(monster,mode),monsters,inside,unique)

law TickLife.no_event_dead:
  for +monster: M.Monsters.State
  for +mode: Maybe<&2,A.AI.Plan>
  for -monsters: List<&2,M.Monsters.State>
  for +tracked: TickLife.Tracked<monster,mode,monsters>
  for +none: {TickLife.event(monster,mode) == False{} : Bool}
  {V.Vitals.dead(M.Monsters.vitals(TickLife.after(monster,mode))) == 1 : U32}

def TickLife.no_event_dead(monster,mode,monsters,tracked,none):
  match tracked:
    case TickLife.Tracked{inside,key,dead,quiet,unique}:
      %none : {V.Vitals.dead(M.Monsters.vitals(TickLife.after(monster,mode))) == Targets.Targets.pick(_,0,1) : U32}
      dead

# Continue from the actual changed corpse and actual complete post-tick world.
law TickLife.continue:
  for requests: List<&1,LD.LiveDead.Request>
  for +world: T.Terrain.World
  for +monster: M.Monsters.State
  for +mode: Maybe<&2,A.AI.Plan>
  for +tracked: TickLife.Tracked<monster,mode,S.Simulation.monsters(T.Terrain.simulation(world))>
  for +none: {TickLife.event(monster,mode) == False{} : Bool}
  LD.LiveDead.TraceSafe<TickLife.after(monster,mode),LD.LiveDead.trace(requests,world)>

def TickLife.continue(requests,world,monster,mode,tracked,none):
  match tracked:
    case TickLife.Tracked{inside,key,dead,quiet,unique}:
      LD.LiveDead.safe(requests,world,TickLife.after(monster,mode),inside,unique,(%none : {V.Vitals.dead(M.Monsters.vitals(TickLife.after(monster,mode))) == Targets.Targets.pick(_,0,1) : U32}; dead))

law TickLife.after_commands:
  for requests: List<&1,LD.LiveDead.Request>
  for +world: T.Terrain.World
  for +timer: U32
  for +monster: M.Monsters.State
  for +valid: Z.Zones.Valid<R.Roster.zone_of(monster)>
  for +inside: Targets.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(world))>
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  for +zones: Z.Zones.All(S.Simulation.monsters(T.Terrain.simulation(world)))
  for +unique: I.Identity.Monsters(S.Simulation.monsters(T.Terrain.simulation(world)))
  for +none: {TickLife.event(monster,TickLife.decision(world,timer,monster,valid,inside)) == False{} : Bool}
  LD.LiveDead.TraceSafe<TickLife.after(monster,TickLife.decision(world,timer,monster,valid,inside)),LD.LiveDead.trace(requests,Tick.LiveTick.world(Tick.LiveTick.run(world,timer)))>

def TickLife.after_commands(requests,world,timer,monster,valid,inside,dead,zones,unique,none):
  TickLife.continue(requests,Tick.LiveTick.world(Tick.LiveTick.run(world,timer)),monster,TickLife.decision(world,timer,monster,valid,inside),TickLife.run(world,timer,monster,valid,inside,dead,zones,unique),none)

law TickLife.after_commands_zero:
  for requests: List<&1,LD.LiveDead.Request>
  for +world: T.Terrain.World
  for +timer: U32
  for +monster: M.Monsters.State
  for +valid: Z.Zones.Valid<R.Roster.zone_of(monster)>
  for +inside: Targets.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(world))>
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  for +zones: Z.Zones.All(S.Simulation.monsters(T.Terrain.simulation(world)))
  for +unique: I.Identity.Monsters(S.Simulation.monsters(T.Terrain.simulation(world)))
  for +none: {TickLife.event(monster,TickLife.decision(world,timer,monster,valid,inside)) == False{} : Bool}
  {Dead.Dead.count(R.Roster.id(monster),LD.LiveDead.notices(LD.LiveDead.trace(requests,Tick.LiveTick.world(Tick.LiveTick.run(world,timer))))) == 0n : Nat}

def TickLife.after_commands_zero(requests,world,timer,monster,valid,inside,dead,zones,unique,none):
  %TickLife.after_id(monster,TickLife.decision(world,timer,monster,valid,inside)) : {Dead.Dead.count(_,LD.LiveDead.notices(LD.LiveDead.trace(requests,Tick.LiveTick.world(Tick.LiveTick.run(world,timer))))) == 0n : Nat}
  LD.LiveDead.zero(TickLife.after(monster,TickLife.decision(world,timer,monster,valid,inside)),LD.LiveDead.trace(requests,Tick.LiveTick.world(Tick.LiveTick.run(world,timer))),TickLife.after_commands(requests,world,timer,monster,valid,inside,dead,zones,unique,none))

law TickLife.event_alive:
  for +monster: M.Monsters.State
  for +mode: Maybe<&2,A.AI.Plan>
  for -monsters: List<&2,M.Monsters.State>
  for +tracked: TickLife.Tracked<monster,mode,monsters>
  for +event: {TickLife.event(monster,mode) == True{} : Bool}
  {V.Vitals.dead(M.Monsters.vitals(TickLife.after(monster,mode))) == 0 : U32}

def TickLife.event_alive(monster,mode,monsters,tracked,event):
  match tracked:
    case TickLife.Tracked{inside,key,dead,quiet,unique}:
      %event : {V.Vitals.dead(M.Monsters.vitals(TickLife.after(monster,mode))) == Targets.Targets.pick(_,0,1) : U32}
      dead
