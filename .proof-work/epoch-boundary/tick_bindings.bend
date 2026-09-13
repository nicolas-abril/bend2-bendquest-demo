# Connection correspondence through upkeep, AI attacks and complete game ticks.
import Base
import ./bindings.bend as Bind
import ./connections.bend as Conn
import ./sessions.bend as Sess
import ./players.bend as P
import ./vitals.bend as V
import ./simulation.bend as S
import ./ai.bend as AI
import ./planning.bend as Plan
import ./terrain.bend as T
import ./locomotion.bend as Walk
import ./worldstate.bend as W
import ./ai_refs.bend as AR
import ./landscape.bend as L
import ./creation.bend as K
import ./frame_bindings.bend as F
import ./population.bend as Pop

law TickBindings.finish_hit_header:
  for +player: P.Players.State
  for +hit: V.Vitals.Hit
  {Bind.Bindings.header(P.Players.player(P.Players.finish_hit(player,hit))) == Bind.Bindings.header(player) : Bind.Bindings.Header}

def TickBindings.finish_hit_header(player,hit):
  match player:
    case P.Players.State{pid,cid,hero,pos,old,style,quest,meta}:
      match meta:
        case P.Players.Meta{score,kills,found,name}:
          match hit:
            case V.Vitals.Hit{vitals,fell}:
              match fell:
                case False{}: {==}
                case True{}: {==}

law TickBindings.finish_upkeep_header:
  for +player: P.Players.State
  for +plan: P.Players.Plan
  for +result: V.Vitals.Upkeep
  for +spawn_x: U32
  for +spawn_y: U32
  {Bind.Bindings.header(P.Players.player(P.Players.finish_upkeep(player,plan,result,spawn_x,spawn_y))) == Bind.Bindings.header(player) : Bind.Bindings.Header}

def TickBindings.finish_upkeep_header(player,plan,result,spawn_x,spawn_y):
  match player:
    case P.Players.State{pid,cid,hero,pos,old,style,quest,meta}:
      match meta:
        case P.Players.Meta{score,kills,found,name}:
          match result:
            case V.Vitals.Upkeep{vitals,revived,walk}:
              match revived:
                case False{}: {==}
                case True{}: {==}

law TickBindings.hurt_header:
  for +player: P.Players.State
  for +attack: U32
  for +timer: U32
  {Bind.Bindings.header(P.Players.player(P.Players.hurt(player,attack,timer))) == Bind.Bindings.header(player) : Bind.Bindings.Header}

def TickBindings.hurt_header(player,attack,timer): TickBindings.finish_hit_header(player,V.Vitals.hit(P.Players.vitals(player),P.Players.mob_hit(attack,P.Players.hero(player)),timer))

law TickBindings.upkeep_header:
  for +player: P.Players.State
  for +plan: P.Players.Plan
  for +tick: U32
  for +spawn_x: U32
  for +spawn_y: U32
  {Bind.Bindings.header(P.Players.player(P.Players.upkeep(player,plan,tick,spawn_x,spawn_y))) == Bind.Bindings.header(player) : Bind.Bindings.Header}

def TickBindings.upkeep_header(player,plan,tick,spawn_x,spawn_y): TickBindings.finish_upkeep_header(player,plan,V.Vitals.upkeep_hero(P.Players.vitals(player),P.Players.regen(tick,V.Vitals.hp(P.Players.vitals(player)),P.Players.maximum(player)),P.Players.hero(player),4294967295),spawn_x,spawn_y)

law TickBindings.prepend_projection:
  for +step: P.Players.Step
  for +result: P.Players.Result
  {Bind.Bindings.headers(P.Players.roster(P.Players.prepend_step(step,result))) == Con{Bind.Bindings.header(P.Players.player(step)),Bind.Bindings.headers(P.Players.roster(result))} : List<&2,Bind.Bindings.Header>}

def TickBindings.prepend_projection(step,result):
  match step:
    case P.Players.Step{player,event}:
      match result:
        case P.Players.Result{players,events}: {==}

law TickBindings.hit_taken_projection:
  for +taken: P.Players.Take
  for +attack: U32
  for +timer: U32
  {Bind.Bindings.headers(P.Players.roster(P.Players.hit_taken(taken,attack,timer))) == Bind.Bindings.headers(P.Players.restore(taken)) : List<&2,Bind.Bindings.Header>}

def TickBindings.hit_taken_projection(taken,attack,timer):
  match taken:
    case P.Players.Take{others,found}:
      match found:
        case None{}: {==}
        case Some{player}:
          %Equal.sym(List<&2,Bind.Bindings.Header>,Bind.Bindings.headers(P.Players.roster(P.Players.prepend_step(P.Players.hurt(player,attack,timer),P.Players.Result{others,Nil{}}))),Con{Bind.Bindings.header(P.Players.player(P.Players.hurt(player,attack,timer))),Bind.Bindings.headers(others)},TickBindings.prepend_projection(P.Players.hurt(player,attack,timer),P.Players.Result{others,Nil{}})) : {_ == Bind.Bindings.headers(Con{player,others}) : List<&2,Bind.Bindings.Header>}
          %TickBindings.hurt_header(player,attack,timer) : {Con{Bind.Bindings.header(P.Players.player(P.Players.hurt(player,attack,timer))),Bind.Bindings.headers(others)} == Con{_,Bind.Bindings.headers(others)} : List<&2,Bind.Bindings.Header>}
          {==}

law TickBindings.prepend_same_projection:
  for +step: P.Players.Step
  for +result: P.Players.Result
  for +head: P.Players.State
  for +rest: List<&2,P.Players.State>
  for +same: {Bind.Bindings.header(P.Players.player(step)) == Bind.Bindings.header(head) : Bind.Bindings.Header}
  for +tail: {Bind.Bindings.headers(P.Players.roster(result)) == Bind.Bindings.headers(rest) : List<&2,Bind.Bindings.Header>}
  {Bind.Bindings.headers(P.Players.roster(P.Players.prepend_step(step,result))) == Bind.Bindings.headers(Con{head,rest}) : List<&2,Bind.Bindings.Header>}

def TickBindings.prepend_same_projection(step,result,head,rest,same,tail):
  %same : {Bind.Bindings.headers(P.Players.roster(P.Players.prepend_step(step,result))) == Con{_,Bind.Bindings.headers(rest)} : List<&2,Bind.Bindings.Header>}
  %tail : {Bind.Bindings.headers(P.Players.roster(P.Players.prepend_step(step,result))) == Con{Bind.Bindings.header(P.Players.player(step)),_} : List<&2,Bind.Bindings.Header>}
  TickBindings.prepend_projection(step,result)

law TickBindings.upkeep_projection:
  for +players: List<&2,P.Players.State>
  for +plans: List<&2,P.Players.Plan>
  for +tick: U32
  for +spawn_x: U32
  for +spawn_y: U32
  {Bind.Bindings.headers(P.Players.roster(P.Players.upkeep_all(players,plans,tick,spawn_x,spawn_y))) == Bind.Bindings.headers(players) : List<&2,Bind.Bindings.Header>}

def TickBindings.upkeep_projection(players,plans,tick,spawn_x,spawn_y):
  match players:
    case Nil{}: {==}
    case Con{head,rest}:
      match plans:
        case Nil{}: TickBindings.prepend_same_projection(P.Players.upkeep(head,P.Players.stay(head),tick,spawn_x,spawn_y),P.Players.upkeep_all(rest,Nil{},tick,spawn_x,spawn_y),head,rest,TickBindings.upkeep_header(head,P.Players.stay(head),tick,spawn_x,spawn_y),TickBindings.upkeep_projection(rest,Nil{},tick,spawn_x,spawn_y))
        case Con{plan,later}: TickBindings.prepend_same_projection(P.Players.upkeep(head,plan,tick,spawn_x,spawn_y),P.Players.upkeep_all(rest,later,tick,spawn_x,spawn_y),head,rest,TickBindings.upkeep_header(head,plan,tick,spawn_x,spawn_y),TickBindings.upkeep_projection(rest,later,tick,spawn_x,spawn_y))

law TickBindings.begin_gate_projection:
  for +running: Bool
  for +state: S.Simulation.State
  for +plans: List<&2,P.Players.Plan>
  for +rules: S.Simulation.Rules
  {Bind.Bindings.headers(P.Players.roster(S.Simulation.prepared_upkeep(S.Simulation.begin_gate(running,state,plans,rules)))) == Bind.Bindings.headers(S.Simulation.players(state)) : List<&2,Bind.Bindings.Header>}

def TickBindings.begin_gate_projection(running,state,plans,rules):
  match running:
    case False{}:
      match state:
        case S.Simulation.State{meta,players,monsters}: {==}
    case True{}:
      match state:
        case S.Simulation.State{meta,players,monsters}:
          match rules:
            case S.Simulation.Rules{spawn_x,spawn_y,timer}: TickBindings.upkeep_projection(players,plans,S.Simulation.clock(meta),spawn_x,spawn_y)

law TickBindings.begin_projection:
  for +state: S.Simulation.State
  for +plans: List<&2,P.Players.Plan>
  for +rules: S.Simulation.Rules
  {Bind.Bindings.headers(P.Players.roster(S.Simulation.prepared_upkeep(S.Simulation.begin(state,plans,rules)))) == Bind.Bindings.headers(S.Simulation.players(state)) : List<&2,Bind.Bindings.Header>}

def TickBindings.begin_projection(state,plans,rules): TickBindings.begin_gate_projection(U32.is_eq(S.Simulation.phase(S.Simulation.meta(state)),1),state,plans,rules)

law TickBindings.strike:
  for +states: List<&2,Sess.Sessions.State>
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +attack: U32
  for +timer: U32
  for +valid: Conn.Connections.OK<players,states>
  Conn.Connections.OK<P.Players.roster(P.Players.strike(players,target,attack,timer)),states>

def TickBindings.strike(states,players,target,attack,timer,valid):
  Bind.Bindings.conserved_ok(states,players,P.Players.roster(P.Players.strike(players,target,attack,timer)),Bind.Bindings.Conserved{P.Players.restore(P.Players.take(players,target)),P.Players.take_restores(players,target),TickBindings.hit_taken_projection(P.Players.take(players,target),attack,timer)},valid)

law TickBindings.apply_hits:
  for +hits: List<&2,P.Players.Attack>
  for +states: List<&2,Sess.Sessions.State>
  for +players: List<&2,P.Players.State>
  for +timer: U32
  for +valid: Conn.Connections.OK<players,states>
  Conn.Connections.OK<P.Players.roster(P.Players.apply_hits(hits,players,timer)),states>

def TickBindings.apply_hits(hits,states,players,timer,valid):
  match hits:
    case Nil{}: valid
    case Con{head,rest}:
      match head:
        case P.Players.Attack{target,attack}:
          +first = P.Players.strike(players,target,attack,timer)
          +later = P.Players.apply_hits(rest,P.Players.roster(first),timer)
          %Equal.sym(List<&2,P.Players.State>,P.Players.roster(P.Players.before(first,later)),P.Players.roster(later),P.Players.before_roster(first,later)) : Conn.Connections.OK<_,states>
          TickBindings.apply_hits(rest,states,P.Players.roster(first),timer,TickBindings.strike(states,players,target,attack,timer,valid))

law TickBindings.finish:
  for +states: List<&2,Sess.Sessions.State>
  for +prepared: S.Simulation.Prepared
  for +p0: List<&2,AI.AI.Plan>
  for +p1: List<&2,AI.AI.Plan>
  for +p2: List<&2,AI.AI.Plan>
  for +p3: List<&2,AI.AI.Plan>
  for +rules: S.Simulation.Rules
  for +valid: Conn.Connections.OK<P.Players.roster(S.Simulation.prepared_upkeep(prepared)),states>
  Conn.Connections.OK<S.Simulation.players(S.Simulation.state(S.Simulation.finish(prepared,p0,p1,p2,p3,rules))),states>

def TickBindings.finish(states,prepared,p0,p1,p2,p3,rules,valid):
  match prepared:
    case S.Simulation.Prepared{meta,monsters,upkeep,running}:
      match running:
        case False{}: valid
        case True{}:
          match rules:
            case S.Simulation.Rules{spawn_x,spawn_y,timer}: TickBindings.apply_hits(S.Simulation.attacks(S.Simulation.ai_hits(AI.AI.run_zones(monsters,p0,p1,p2,p3))),states,P.Players.roster(upkeep),timer,valid)

law TickBindings.actions:
  for +states: List<&2,Sess.Sessions.State>
  for +prepared: S.Simulation.Prepared
  for +actions: Walk.Locomotion.Actions
  for +rules: S.Simulation.Rules
  for +valid: Conn.Connections.OK<P.Players.roster(S.Simulation.prepared_upkeep(prepared)),states>
  Conn.Connections.OK<S.Simulation.players(S.Simulation.state(Walk.Locomotion.finish(prepared,actions,rules))),states>

def TickBindings.actions(states,prepared,actions,rules,valid):
  match actions:
    case Walk.Locomotion.Actions{p0,p1,p2,p3}: TickBindings.finish(states,prepared,p0,p1,p2,p3,rules,valid)

law TickBindings.planning_finish:
  for +states: List<&2,Sess.Sessions.State>
  for +prepared: S.Simulation.Prepared
  for +maps: T.Terrain.Maps
  for +c0: List<&2,Plan.Planning.Context>
  for +c1: List<&2,Plan.Planning.Context>
  for +c2: List<&2,Plan.Planning.Context>
  for +c3: List<&2,Plan.Planning.Context>
  for +rules: S.Simulation.Rules
  for +valid: Conn.Connections.OK<P.Players.roster(S.Simulation.prepared_upkeep(prepared)),states>
  Conn.Connections.OK<S.Simulation.players(S.Simulation.state(Plan.Planning.finish(prepared,maps,c0,c1,c2,c3,rules))),states>

def TickBindings.planning_finish(states,prepared,maps,c0,c1,c2,c3,rules,valid):
  +actions = Plan.Planning.actions(S.Simulation.prepared_monsters(prepared),c0,c1,c2,c3,maps,S.Simulation.clock(S.Simulation.prepared_meta(prepared)))
  %Equal.sym(S.Simulation.Result,Plan.Planning.finish(prepared,maps,c0,c1,c2,c3,rules),Walk.Locomotion.finish(prepared,actions,rules),Plan.Planning.finish_refines(prepared,maps,c0,c1,c2,c3,rules)) : Conn.Connections.OK<S.Simulation.players(S.Simulation.state(_)),states>
  TickBindings.actions(states,prepared,actions,rules,valid)

law TickBindings.planning_tick:
  for +states: List<&2,Sess.Sessions.State>
  for +state: S.Simulation.State
  for +input: Plan.Planning.Input
  for +maps: T.Terrain.Maps
  for +rules: S.Simulation.Rules
  for +valid: Conn.Connections.OK<S.Simulation.players(state),states>
  Conn.Connections.OK<S.Simulation.players(S.Simulation.state(Plan.Planning.tick(state,input,maps,rules))),states>

def TickBindings.planning_tick(states,state,input,maps,rules,valid):
  match input:
    case Plan.Planning.Input{c0,c1,c2,c3}:
      +running = U32.is_eq(S.Simulation.phase(S.Simulation.meta(state)),1)
      +plans = Walk.Locomotion.tick_plans(running,S.Simulation.players(state),maps)
      +prepared = Walk.Locomotion.begin(state,maps,rules)
      TickBindings.planning_finish(states,prepared,maps,c0,c1,c2,c3,rules,Bind.Bindings.same_ok(states,P.Players.roster(S.Simulation.prepared_upkeep(prepared)),S.Simulation.players(state),TickBindings.begin_gate_projection(running,state,plans,rules),valid))

law TickBindings.tick:
  for +states: List<&2,Sess.Sessions.State>
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +d0: List<&2,U32>
  for +d1: List<&2,U32>
  for +d2: List<&2,U32>
  for +d3: List<&2,U32>
  for +rules: S.Simulation.Rules
  for +valid: Conn.Connections.OK<S.Simulation.players(state),states>
  Conn.Connections.OK<S.Simulation.players(S.Simulation.state(AR.AIRefs.tick(state,maps,d0,d1,d2,d3,rules))),states>

def TickBindings.tick(states,state,maps,d0,d1,d2,d3,rules,valid):
  +input = W.WorldState.input(Walk.Locomotion.begin(state,maps,rules),d0,d1,d2,d3)
  %Equal.sym(S.Simulation.Result,AR.AIRefs.tick(state,maps,d0,d1,d2,d3,rules),Plan.Planning.tick(state,input,maps,rules),W.WorldState.tick_refines(state,maps,d0,d1,d2,d3,rules)) : Conn.Connections.OK<S.Simulation.players(S.Simulation.state(_)),states>
  TickBindings.planning_tick(states,state,input,maps,rules,valid)

law TickBindings.run_tick:
  for +damages: AR.AIRefs.Damages
  for +states: List<&2,Sess.Sessions.State>
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +rules: S.Simulation.Rules
  for +valid: Conn.Connections.OK<S.Simulation.players(state),states>
  Conn.Connections.OK<S.Simulation.players(AR.AIRefs.run_tick(damages,state,maps,rules)),states>

def TickBindings.run_tick(damages,states,state,maps,rules,valid):
  match damages:
    case AR.AIRefs.Damages{d0,d1,d2,d3}: TickBindings.tick(states,state,maps,d0,d1,d2,d3,rules,valid)

law TickBindings.world:
  for +damages: AR.AIRefs.Damages
  for +seed: U32
  for +state: S.Simulation.State
  for +states: List<&2,Sess.Sessions.State>
  for +timer: U32
  for +valid: Conn.Connections.WorldOK<seed,state,states>
  Conn.Connections.WorldOK<seed,AR.AIRefs.run_tick(damages,state,L.Landscape.maps(seed),Plan.Planning.rules(timer)),states>

def TickBindings.world(damages,seed,state,states,timer,valid):
  match valid:
    case Conn.Connections.WorldOK{world_ok,connections}: Conn.Connections.WorldOK{W.WorldState.run_tick(damages,seed,state,timer,world_ok),TickBindings.run_tick(damages,states,state,L.Landscape.maps(seed),Plan.Planning.rules(timer),connections)}

# Each tick uses the canonical spawn location. Damage and timers are unrestricted.
# Scheduling, authentication and the effectful dispatcher remain separate.
type TickBindings.Input is Data:
  TickBindings.Command{input: F.FrameBindings.Input}
  TickBindings.Tick{damages: AR.AIRefs.Damages,timer: U32}

def TickBindings.step(input: TickBindings.Input,seed: U32,result: K.Creation.Result) -> K.Creation.Result:
  match input:
    case TickBindings.Command{input}: F.FrameBindings.step(input,seed,result)
    case TickBindings.Tick{damages,timer}:
      match result:
        case K.Creation.Result{world,states}: K.Creation.Result{AR.AIRefs.run_tick(damages,world,L.Landscape.maps(seed),Plan.Planning.rules(timer)),states}

def TickBindings.trace(inputs: List<&2,TickBindings.Input>,+seed: U32,result: K.Creation.Result) -> K.Creation.Result:
  match inputs:
    case Nil{}: result
    case Con{head,rest}: TickBindings.trace(rest,seed,TickBindings.step(head,seed,result))

law TickBindings.step_ok:
  for +input: TickBindings.Input
  for +seed: U32
  for +result: K.Creation.Result
  for +valid: K.Creation.OK(seed,result)
  K.Creation.OK(seed,TickBindings.step(input,seed,result))

def TickBindings.step_ok(input,seed,result,valid):
  match input:
    case TickBindings.Command{input}: F.FrameBindings.step_ok(input,seed,result,valid)
    case TickBindings.Tick{damages,timer}:
      match result:
        case K.Creation.Result{world,states}: TickBindings.world(damages,seed,world,states,timer,valid)

law TickBindings.trace_ok:
  for +inputs: List<&2,TickBindings.Input>
  for +seed: U32
  for +result: K.Creation.Result
  for +valid: K.Creation.OK(seed,result)
  K.Creation.OK(seed,TickBindings.trace(inputs,seed,result))

def TickBindings.trace_ok(inputs,seed,result,valid):
  match inputs:
    case Nil{}: valid
    case Con{head,rest}: TickBindings.trace_ok(rest,seed,TickBindings.step(head,seed,result),TickBindings.step_ok(head,seed,result,valid))

law TickBindings.fresh_trace:
  for +inputs: List<&2,TickBindings.Input>
  for +world: U32
  for +seed: U32
  for +now: U32
  K.Creation.OK(seed,TickBindings.trace(inputs,seed,K.Creation.Result{T.Terrain.simulation(Pop.Population.fresh(world,seed,now)),Nil{}}))

def TickBindings.fresh_trace(inputs,world,seed,now): TickBindings.trace_ok(inputs,seed,K.Creation.Result{T.Terrain.simulation(Pop.Population.fresh(world,seed,now)),Nil{}},Conn.Connections.fresh_world(world,seed,now))
