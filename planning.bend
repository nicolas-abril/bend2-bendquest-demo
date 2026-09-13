# Complete lifecycle-aware plans supplied to the actual AI executor.
import Base
import ./population.bend as Pop
import ./pursuit.bend as Q
import ./habitat.bend as H
import ./terrain.bend as T
import ./landscape.bend as L
import ./monsters.bend as M
import ./ai.bend as A
import ./roster.bend as R
import ./simulation.bend as S
import ./locomotion.bend as Walk
import ./players.bend as P

type Planning.Context is Data:
  Planning.Context{target: Q.Pursuit.Target,damage: U32}

def Planning.idle() -> Planning.Context: Planning.Context{Q.Pursuit.Target{0,0,0,False{}},0}

def Planning.tick_plan(result: M.Monsters.Tick,maps: T.Terrain.Maps,context: Planning.Context,tick: U32) -> A.AI.Plan:
  match result:
    case M.Monsters.Tick{monster,phase}:
      match phase:
        case M.Monsters.Dormant{}: A.AI.Rest{}
        case M.Monsters.Rebirth{}: Pop.Population.rebirth(maps,monster,tick)
        case M.Monsters.Active{}:
          match context:
            case Planning.Context{target,damage}: Q.Pursuit.plan(maps,monster,target,tick,damage)

def Planning.plan(monster: M.Monsters.State,maps: T.Terrain.Maps,context: Planning.Context,tick: U32) -> A.AI.Plan:
  Planning.tick_plan(M.Monsters.tick(monster),maps,context,tick)

def Planning.plans(monsters: List<&2,M.Monsters.State>,contexts: List<&2,Planning.Context>,+maps: T.Terrain.Maps,+tick: U32) -> List<&2,A.AI.Plan>:
  match monsters:
    case Nil{}: Nil{}
    case Con{head,rest}:
      match contexts:
        case Nil{}: Con{Planning.plan(head,maps,Planning.idle,tick),Planning.plans(rest,Nil{},maps,tick)}
        case Con{context,later}: Con{Planning.plan(head,maps,context,tick),Planning.plans(rest,later,maps,tick)}

law Planning.tick_plan_on:
  for +seed: U32
  for +result: M.Monsters.Tick
  for +context: Planning.Context
  for +tick: U32
  for +valid: H.Habitat.On(L.Landscape.maps(seed),M.Monsters.tick_state(result))
  H.Habitat.PlanOn(L.Landscape.maps(seed),H.Habitat.pos(M.Monsters.tick_state(result)),Planning.tick_plan(result,L.Landscape.maps(seed),context,tick))

def Planning.tick_plan_on(seed,result,context,tick,valid):
  match result:
    case M.Monsters.Tick{monster,phase}:
      match phase:
        case M.Monsters.Dormant{}: Unit{}
        case M.Monsters.Rebirth{}: Pop.Population.rebirth_on(seed,monster,tick,valid)
        case M.Monsters.Active{}:
          match context:
            case Planning.Context{target,damage}: Q.Pursuit.plan_on(L.Landscape.maps(seed),monster,target,tick,damage,valid)

law Planning.plan_on:
  for +seed: U32
  for +monster: M.Monsters.State
  for +context: Planning.Context
  for +tick: U32
  for +valid: H.Habitat.On(L.Landscape.maps(seed),monster)
  H.Habitat.PlanOn(L.Landscape.maps(seed),H.Habitat.pos(monster),Planning.plan(monster,L.Landscape.maps(seed),context,tick))

def Planning.plan_on(seed,monster,context,tick,valid):
  %H.Habitat.tick_position(monster) : H.Habitat.PlanOn(L.Landscape.maps(seed),_,Planning.plan(monster,L.Landscape.maps(seed),context,tick))
  Planning.tick_plan_on(seed,M.Monsters.tick(monster),context,tick,H.Habitat.tick_on(L.Landscape.maps(seed),monster,valid))

law Planning.step_on:
  for +seed: U32
  for +monster: M.Monsters.State
  for +context: Planning.Context
  for +tick: U32
  for +valid: H.Habitat.On(L.Landscape.maps(seed),monster)
  H.Habitat.On(L.Landscape.maps(seed),A.AI.monster(A.AI.step(monster,Planning.plan(monster,L.Landscape.maps(seed),context,tick))))

def Planning.step_on(seed,monster,context,tick,valid):
  H.Habitat.step_on(L.Landscape.maps(seed),monster,Planning.plan(monster,L.Landscape.maps(seed),context,tick),valid,Planning.plan_on(seed,monster,context,tick,valid))

law Planning.plans_on:
  for +monsters: List<&2,M.Monsters.State>
  for +contexts: List<&2,Planning.Context>
  for +seed: U32
  for +tick: U32
  for +valid: H.Habitat.All(L.Landscape.maps(seed),monsters)
  H.Habitat.Plans(L.Landscape.maps(seed),monsters,Planning.plans(monsters,contexts,L.Landscape.maps(seed),tick))

def Planning.plans_on(monsters,contexts,seed,tick,valid):
  match monsters:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match contexts:
        case Nil{}:
          match valid:
            case Tuple{head_ok,rest_ok}: Tuple{Planning.plan_on(seed,head,Planning.idle,tick,head_ok),Planning.plans_on(rest,Nil{},seed,tick,rest_ok)}
        case Con{context,later}:
          match valid:
            case Tuple{head_ok,rest_ok}: Tuple{Planning.plan_on(seed,head,context,tick,head_ok),Planning.plans_on(rest,later,seed,tick,rest_ok)}

law Planning.run_on:
  for +monsters: List<&2,M.Monsters.State>
  for +contexts: List<&2,Planning.Context>
  for +seed: U32
  for +tick: U32
  for +valid: H.Habitat.All(L.Landscape.maps(seed),monsters)
  H.Habitat.All(L.Landscape.maps(seed),A.AI.monsters(A.AI.run(monsters,Planning.plans(monsters,contexts,L.Landscape.maps(seed),tick))))

def Planning.run_on(monsters,contexts,seed,tick,valid):
  H.Habitat.run_on(L.Landscape.maps(seed),monsters,Planning.plans(monsters,contexts,L.Landscape.maps(seed),tick),valid,Planning.plans_on(monsters,contexts,seed,tick,valid))

def Planning.actions(+monsters: List<&2,M.Monsters.State>,c0: List<&2,Planning.Context>,c1: List<&2,Planning.Context>,c2: List<&2,Planning.Context>,c3: List<&2,Planning.Context>,+maps: T.Terrain.Maps,+tick: U32) -> Walk.Locomotion.Actions:
  p0 p1 p2 p3 = Planning.plans(R.Roster.zone(monsters,0),c0,maps,tick) Planning.plans(R.Roster.zone(monsters,1),c1,maps,tick) Planning.plans(R.Roster.zone(monsters,2),c2,maps,tick) Planning.plans(R.Roster.zone(monsters,3),c3,maps,tick)
  Walk.Locomotion.Actions{p0,p1,p2,p3}

def Planning.finish(prepared: S.Simulation.Prepared,maps: T.Terrain.Maps,c0: List<&2,Planning.Context>,c1: List<&2,Planning.Context>,c2: List<&2,Planning.Context>,c3: List<&2,Planning.Context>,rules: S.Simulation.Rules) -> S.Simulation.Result:
  match prepared:
    case S.Simulation.Prepared{meta,monsters,upkeep,running}:
      match running:
        case False{}: Walk.Locomotion.finish(S.Simulation.Prepared{meta,monsters,upkeep,False{}},Walk.Locomotion.Actions{Nil{},Nil{},Nil{},Nil{}},rules)
        case True{}:
          +ms = monsters
          +wm = meta
          Walk.Locomotion.finish(S.Simulation.Prepared{wm,ms,upkeep,True{}},Planning.actions(ms,c0,c1,c2,c3,maps,S.Simulation.clock(wm)),rules)

law Planning.zones_on:
  for +seed: U32
  for +monsters: List<&2,M.Monsters.State>
  for +c0: List<&2,Planning.Context>
  for +c1: List<&2,Planning.Context>
  for +c2: List<&2,Planning.Context>
  for +c3: List<&2,Planning.Context>
  for +tick: U32
  for +valid: H.Habitat.All(L.Landscape.maps(seed),monsters)
  H.Habitat.All(L.Landscape.maps(seed),A.AI.monsters(A.AI.run_zones(monsters,Planning.plans(R.Roster.zone(monsters,0),c0,L.Landscape.maps(seed),tick),Planning.plans(R.Roster.zone(monsters,1),c1,L.Landscape.maps(seed),tick),Planning.plans(R.Roster.zone(monsters,2),c2,L.Landscape.maps(seed),tick),Planning.plans(R.Roster.zone(monsters,3),c3,L.Landscape.maps(seed),tick))))

def Planning.zones_on(seed,monsters,c0,c1,c2,c3,tick,valid):
  +maps = L.Landscape.maps(seed)
  H.Habitat.run_zones_on(maps,monsters,Planning.plans(R.Roster.zone(monsters,0),c0,maps,tick),Planning.plans(R.Roster.zone(monsters,1),c1,maps,tick),Planning.plans(R.Roster.zone(monsters,2),c2,maps,tick),Planning.plans(R.Roster.zone(monsters,3),c3,maps,tick),valid,Planning.plans_on(R.Roster.zone(monsters,0),c0,seed,tick,H.Habitat.zone_on(maps,monsters,0,valid)),Planning.plans_on(R.Roster.zone(monsters,1),c1,seed,tick,H.Habitat.zone_on(maps,monsters,1,valid)),Planning.plans_on(R.Roster.zone(monsters,2),c2,seed,tick,H.Habitat.zone_on(maps,monsters,2,valid)),Planning.plans_on(R.Roster.zone(monsters,3),c3,seed,tick,H.Habitat.zone_on(maps,monsters,3,valid)))

law Planning.active_finish_on:
  for +maps: T.Terrain.Maps
  for +meta: S.Simulation.Meta
  for +upkeep: P.Players.Result
  for +ai: A.AI.Result
  for +timer: U32
  for +valid: H.Habitat.All(maps,A.AI.monsters(ai))
  H.Habitat.All(maps,S.Simulation.monsters(S.Simulation.state(S.Simulation.finish_active(meta,upkeep,ai,timer))))

def Planning.active_finish_on(maps,meta,upkeep,ai,timer,valid): valid

law Planning.finish_on:
  for +seed: U32
  for +prepared: S.Simulation.Prepared
  for +c0: List<&2,Planning.Context>
  for +c1: List<&2,Planning.Context>
  for +c2: List<&2,Planning.Context>
  for +c3: List<&2,Planning.Context>
  for +rules: S.Simulation.Rules
  for +valid: H.Habitat.All(L.Landscape.maps(seed),S.Simulation.prepared_monsters(prepared))
  H.Habitat.All(L.Landscape.maps(seed),S.Simulation.monsters(S.Simulation.state(Planning.finish(prepared,L.Landscape.maps(seed),c0,c1,c2,c3,rules))))

def Planning.finish_on(seed,prepared,c0,c1,c2,c3,rules,valid):
  match prepared:
    case S.Simulation.Prepared{meta,monsters,upkeep,running}:
      match running:
        case False{}: valid
        case True{}:
          match rules:
            case S.Simulation.Rules{spawn_x,spawn_y,timer}:
              +maps = L.Landscape.maps(seed)
              +tick = S.Simulation.clock(meta)
              Planning.active_finish_on(maps,meta,upkeep,A.AI.run_zones(monsters,Planning.plans(R.Roster.zone(monsters,0),c0,maps,tick),Planning.plans(R.Roster.zone(monsters,1),c1,maps,tick),Planning.plans(R.Roster.zone(monsters,2),c2,maps,tick),Planning.plans(R.Roster.zone(monsters,3),c3,maps,tick)),timer,Planning.zones_on(seed,monsters,c0,c1,c2,c3,tick,valid))

def Planning.rules(timer: U32) -> S.Simulation.Rules:
  S.Simulation.Rules{L.Landscape.spawn_x,L.Landscape.spawn_y,timer}

type Planning.Input is Data:
  Planning.Input{zone0: List<&2,Planning.Context>,zone1: List<&2,Planning.Context>,zone2: List<&2,Planning.Context>,zone3: List<&2,Planning.Context>}

def Planning.tick(+state: S.Simulation.State,input: Planning.Input,+maps: T.Terrain.Maps,+rules: S.Simulation.Rules) -> S.Simulation.Result:
  match input:
    case Planning.Input{c0,c1,c2,c3}: Planning.finish(Walk.Locomotion.begin(state,maps,rules),maps,c0,c1,c2,c3,rules)

law Planning.begin_monsters:
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +rules: S.Simulation.Rules
  {S.Simulation.prepared_monsters(Walk.Locomotion.begin(state,maps,rules)) == S.Simulation.monsters(state) : List<&2,M.Monsters.State>}

def Planning.begin_monsters(state,maps,rules):
  +running = U32.is_eq(S.Simulation.phase(S.Simulation.meta(state)),1)
  S.Simulation.begin_gate_monsters(running,state,Walk.Locomotion.tick_plans(running,S.Simulation.players(state),maps),rules)

law Planning.tick_on:
  for +seed: U32
  for +state: S.Simulation.State
  for +input: Planning.Input
  for +rules: S.Simulation.Rules
  for +valid: H.Habitat.All(L.Landscape.maps(seed),S.Simulation.monsters(state))
  H.Habitat.All(L.Landscape.maps(seed),S.Simulation.monsters(S.Simulation.state(Planning.tick(state,input,L.Landscape.maps(seed),rules))))

def Planning.tick_on(seed,state,input,rules,valid):
  match input:
    case Planning.Input{c0,c1,c2,c3}:
      +maps = L.Landscape.maps(seed)
      Planning.finish_on(seed,Walk.Locomotion.begin(state,maps,rules),c0,c1,c2,c3,rules,
        (%Equal.sym(List<&2,M.Monsters.State>,S.Simulation.prepared_monsters(Walk.Locomotion.begin(state,maps,rules)),S.Simulation.monsters(state),Planning.begin_monsters(state,maps,rules)) : H.Habitat.All(maps,_); valid))

law Planning.finish_refines:
  for +prepared: S.Simulation.Prepared
  for +maps: T.Terrain.Maps
  for +c0: List<&2,Planning.Context>
  for +c1: List<&2,Planning.Context>
  for +c2: List<&2,Planning.Context>
  for +c3: List<&2,Planning.Context>
  for +rules: S.Simulation.Rules
  {Planning.finish(prepared,maps,c0,c1,c2,c3,rules) == Walk.Locomotion.finish(prepared,Planning.actions(S.Simulation.prepared_monsters(prepared),c0,c1,c2,c3,maps,S.Simulation.clock(S.Simulation.prepared_meta(prepared))),rules) : S.Simulation.Result}

def Planning.finish_refines(prepared,maps,c0,c1,c2,c3,rules):
  match prepared:
    case S.Simulation.Prepared{meta,monsters,upkeep,running}:
      match running:
        case True{}: {==}
        case False{}:
          match rules:
            case S.Simulation.Rules{spawn_x,spawn_y,timer}: {==}

law Planning.actions_players:
  for +prepared: S.Simulation.Prepared
  for +maps: T.Terrain.Maps
  for +actions: Walk.Locomotion.Actions
  for +rules: S.Simulation.Rules
  for +valid: Walk.Locomotion.PreparedOn(maps,prepared)
  Walk.Locomotion.All(maps,S.Simulation.players(S.Simulation.state(Walk.Locomotion.finish(prepared,actions,rules))))

def Planning.actions_players(prepared,maps,actions,rules,valid):
  match actions:
    case Walk.Locomotion.Actions{p0,p1,p2,p3}: Walk.Locomotion.finish_on(prepared,maps,p0,p1,p2,p3,rules,valid)

law Planning.finish_players:
  for +prepared: S.Simulation.Prepared
  for +maps: T.Terrain.Maps
  for +c0: List<&2,Planning.Context>
  for +c1: List<&2,Planning.Context>
  for +c2: List<&2,Planning.Context>
  for +c3: List<&2,Planning.Context>
  for +rules: S.Simulation.Rules
  for +valid: Walk.Locomotion.PreparedOn(maps,prepared)
  Walk.Locomotion.All(maps,S.Simulation.players(S.Simulation.state(Planning.finish(prepared,maps,c0,c1,c2,c3,rules))))

def Planning.finish_players(prepared,maps,c0,c1,c2,c3,rules,valid):
  +actions = Planning.actions(S.Simulation.prepared_monsters(prepared),c0,c1,c2,c3,maps,S.Simulation.clock(S.Simulation.prepared_meta(prepared)))
  %Equal.sym(S.Simulation.Result,Planning.finish(prepared,maps,c0,c1,c2,c3,rules),Walk.Locomotion.finish(prepared,actions,rules),Planning.finish_refines(prepared,maps,c0,c1,c2,c3,rules)) : Walk.Locomotion.All(maps,S.Simulation.players(S.Simulation.state(_)))
  Planning.actions_players(prepared,maps,actions,rules,valid)

law Planning.tick_players:
  for +seed: U32
  for +state: S.Simulation.State
  for +input: Planning.Input
  for +timer: U32
  for +valid: Walk.Locomotion.All(L.Landscape.maps(seed),S.Simulation.players(state))
  Walk.Locomotion.All(L.Landscape.maps(seed),S.Simulation.players(S.Simulation.state(Planning.tick(state,input,L.Landscape.maps(seed),Planning.rules(timer)))))

def Planning.tick_players(seed,state,input,timer,valid):
  match input:
    case Planning.Input{c0,c1,c2,c3}:
      +maps = L.Landscape.maps(seed)
      Planning.finish_players(Walk.Locomotion.begin(state,maps,Planning.rules(timer)),maps,c0,c1,c2,c3,Planning.rules(timer),Walk.Locomotion.begin_on(state,maps,Planning.rules(timer),valid,L.Landscape.spawn_on(seed)))

law Planning.actions_ok:
  for +prepared: S.Simulation.Prepared
  for +actions: Walk.Locomotion.Actions
  for +rules: S.Simulation.Rules
  for +valid: S.Simulation.PreparedOK<prepared>
  S.Simulation.OK<S.Simulation.state(Walk.Locomotion.finish(prepared,actions,rules))>

def Planning.actions_ok(prepared,actions,rules,valid):
  match actions:
    case Walk.Locomotion.Actions{p0,p1,p2,p3}: S.Simulation.finish_ok(prepared,p0,p1,p2,p3,rules,valid)

law Planning.finish_ok:
  for +prepared: S.Simulation.Prepared
  for +maps: T.Terrain.Maps
  for +c0: List<&2,Planning.Context>
  for +c1: List<&2,Planning.Context>
  for +c2: List<&2,Planning.Context>
  for +c3: List<&2,Planning.Context>
  for +rules: S.Simulation.Rules
  for +valid: S.Simulation.PreparedOK<prepared>
  S.Simulation.OK<S.Simulation.state(Planning.finish(prepared,maps,c0,c1,c2,c3,rules))>

def Planning.finish_ok(prepared,maps,c0,c1,c2,c3,rules,valid):
  +actions = Planning.actions(S.Simulation.prepared_monsters(prepared),c0,c1,c2,c3,maps,S.Simulation.clock(S.Simulation.prepared_meta(prepared)))
  %Equal.sym(S.Simulation.Result,Planning.finish(prepared,maps,c0,c1,c2,c3,rules),Walk.Locomotion.finish(prepared,actions,rules),Planning.finish_refines(prepared,maps,c0,c1,c2,c3,rules)) : S.Simulation.OK<S.Simulation.state(_)>
  Planning.actions_ok(prepared,actions,rules,valid)

law Planning.tick_ok:
  for +state: S.Simulation.State
  for +input: Planning.Input
  for +maps: T.Terrain.Maps
  for +rules: S.Simulation.Rules
  for +valid: S.Simulation.OK<state>
  S.Simulation.OK<S.Simulation.state(Planning.tick(state,input,maps,rules))>

def Planning.tick_ok(state,input,maps,rules,valid):
  match input:
    case Planning.Input{c0,c1,c2,c3}: Planning.finish_ok(Walk.Locomotion.begin(state,maps,rules),maps,c0,c1,c2,c3,rules,Walk.Locomotion.begin_ok(state,maps,rules,valid))

type Planning.Positions<-seed: U32,-state: S.Simulation.State> is Data:
  Planning.Positions{players: Walk.Locomotion.All(L.Landscape.maps(seed),S.Simulation.players(state)),monsters: H.Habitat.All(L.Landscape.maps(seed),S.Simulation.monsters(state))}

law Planning.initial_positions:
  for +world: U32
  for +seed: U32
  for +now: U32
  Planning.Positions<seed,T.Terrain.simulation(Pop.Population.fresh(world,seed,now))>

def Planning.initial_positions(world,seed,now): Planning.Positions{Unit{},Pop.Population.initial_on(seed)}

law Planning.tick_positions:
  for +seed: U32
  for +state: S.Simulation.State
  for +input: Planning.Input
  for +timer: U32
  for +valid: Planning.Positions<seed,state>
  Planning.Positions<seed,S.Simulation.state(Planning.tick(state,input,L.Landscape.maps(seed),Planning.rules(timer)))>

def Planning.tick_positions(seed,state,input,timer,valid):
  match valid:
    case Planning.Positions{players,monsters}: Planning.Positions{Planning.tick_players(seed,state,input,timer,players),Planning.tick_on(seed,state,input,Planning.rules(timer),monsters)}

def Planning.trace(inputs: List<&2,Planning.Input>,state: S.Simulation.State,+maps: T.Terrain.Maps,+rules: S.Simulation.Rules) -> S.Simulation.State:
  match inputs:
    case Nil{}: state
    case Con{head,rest}: Planning.trace(rest,S.Simulation.state(Planning.tick(state,head,maps,rules)),maps,rules)

law Planning.trace_positions:
  for +inputs: List<&2,Planning.Input>
  for +state: S.Simulation.State
  for +seed: U32
  for +timer: U32
  for +valid: Planning.Positions<seed,state>
  Planning.Positions<seed,Planning.trace(inputs,state,L.Landscape.maps(seed),Planning.rules(timer))>

def Planning.trace_positions(inputs,state,seed,timer,valid):
  match inputs:
    case Nil{}: valid
    case Con{head,rest}: Planning.trace_positions(rest,S.Simulation.state(Planning.tick(state,head,L.Landscape.maps(seed),Planning.rules(timer))),seed,timer,Planning.tick_positions(seed,state,head,timer,valid))

law Planning.trace_ok:
  for +inputs: List<&2,Planning.Input>
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +rules: S.Simulation.Rules
  for +valid: S.Simulation.OK<state>
  S.Simulation.OK<Planning.trace(inputs,state,maps,rules)>

def Planning.trace_ok(inputs,state,maps,rules,valid):
  match inputs:
    case Nil{}: valid
    case Con{head,rest}: Planning.trace_ok(rest,S.Simulation.state(Planning.tick(state,head,maps,rules)),maps,rules,Planning.tick_ok(state,head,maps,rules,valid))
