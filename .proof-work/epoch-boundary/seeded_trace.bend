# Mixed traces whose selected map seed agrees with the stored world seed.
import Base
import ./world_clock.bend as Clock
import ./restart_trace.bend as Trace
import ./restart_metadata.bend as Meta
import ./seeded_world.bend as SW
import ./world_seed.bend as W
import ./lifecycle_seed.bend as Life
import ./creation.bend as K
import ./connections.bend as C
import ./sessions.bend as Sess
import ./simulation.bend as S
import ./terrain.bend as T
import ./population.bend as Pop
import ./landscape.bend as L
import ./tick_bindings.bend as Tick

type SeededTrace.OK<-state: Trace.RestartTrace.State> is Data:
  SeededTrace.OK{valid: Trace.RestartTrace.OK(state),stored: {W.WorldSeed.of(K.Creation.world(Trace.RestartTrace.result(state))) == Trace.RestartTrace.seed(state) : U32}}

def SeededTrace.world(+state: Trace.RestartTrace.State) -> T.Terrain.World:
  T.Terrain.world(L.Landscape.maps(Trace.RestartTrace.seed(state)),K.Creation.world(Trace.RestartTrace.result(state)))

def SeededTrace.states(state: Trace.RestartTrace.State) -> List<&2,Sess.Sessions.State>:
  K.Creation.states(Trace.RestartTrace.result(state))

law SeededTrace.step_seed:
  for +input: Trace.RestartTrace.Input
  for +state: Trace.RestartTrace.State
  for +stored: {W.WorldSeed.of(K.Creation.world(Trace.RestartTrace.result(state))) == Trace.RestartTrace.seed(state) : U32}
  {W.WorldSeed.of(K.Creation.world(Trace.RestartTrace.result(Trace.RestartTrace.step(input,state)))) == Trace.RestartTrace.seed(Trace.RestartTrace.step(input,state)) : U32}

def SeededTrace.step_seed(input,state,stored):
  match input:
    case Trace.RestartTrace.Advance{input}:
      match state:
        case Trace.RestartTrace.State{seed,result}: Equal.trans(U32,Life.LifecycleSeed.of(Tick.TickBindings.step(input,seed,result)),Life.LifecycleSeed.of(result),seed,Life.LifecycleSeed.tick(input,seed,result),stored)
    case Trace.RestartTrace.Time{now}:
      match state:
        case Trace.RestartTrace.State{seed,result}:
          match result:
            case K.Creation.Result{world,states}: Equal.trans(U32,W.WorldSeed.of(Clock.WorldClock.state(world,now)),W.WorldSeed.of(world),seed,Clock.WorldClock.state_seed(world,now),stored)
    case Trace.RestartTrace.Replace{world,seed,now}:
      match state:
        case Trace.RestartTrace.State{old_seed,result}:
          match result:
            case K.Creation.Result{before,states}: Meta.RestartMetadata.fresh_seed(S.Simulation.players(before),world,seed,now)

law SeededTrace.step_ok:
  for +input: Trace.RestartTrace.Input
  for +state: Trace.RestartTrace.State
  for +valid: SeededTrace.OK<state>
  SeededTrace.OK<Trace.RestartTrace.step(input,state)>

def SeededTrace.step_ok(input,state,valid):
  match valid:
    case SeededTrace.OK{world,stored}: SeededTrace.OK{Trace.RestartTrace.step_ok(input,state,world),SeededTrace.step_seed(input,state,stored)}

law SeededTrace.trace_ok:
  for +inputs: List<&2,Trace.RestartTrace.Input>
  for +state: Trace.RestartTrace.State
  for +valid: SeededTrace.OK<state>
  SeededTrace.OK<Trace.RestartTrace.trace(inputs,state)>

def SeededTrace.trace_ok(inputs,state,valid):
  match inputs:
    case Nil{}: valid
    case Con{head,rest}: SeededTrace.trace_ok(rest,Trace.RestartTrace.step(head,state),SeededTrace.step_ok(head,state,valid))

law SeededTrace.fresh_trace:
  for +inputs: List<&2,Trace.RestartTrace.Input>
  for +world: U32
  for +seed: U32
  for +now: U32
  SeededTrace.OK<Trace.RestartTrace.trace(inputs,Trace.RestartTrace.State{seed,K.Creation.Result{T.Terrain.simulation(Pop.Population.fresh(world,seed,now)),Nil{}}})>

def SeededTrace.fresh_trace(inputs,world,seed,now): SeededTrace.trace_ok(inputs,Trace.RestartTrace.State{seed,K.Creation.Result{T.Terrain.simulation(Pop.Population.fresh(world,seed,now)),Nil{}}},SeededTrace.OK{C.Connections.fresh_world(world,seed,now),{==}})

law SeededTrace.world_simulation:
  for +state: Trace.RestartTrace.State
  {T.Terrain.simulation(SeededTrace.world(state)) == K.Creation.world(Trace.RestartTrace.result(state)) : S.Simulation.State}

def SeededTrace.world_simulation(state): T.Terrain.world_simulation(L.Landscape.maps(Trace.RestartTrace.seed(state)),K.Creation.world(Trace.RestartTrace.result(state)))

law SeededTrace.world_maps:
  for +state: Trace.RestartTrace.State
  {T.Terrain.maps(SeededTrace.world(state)) == L.Landscape.maps(Trace.RestartTrace.seed(state)) : T.Terrain.Maps}

def SeededTrace.world_maps(state): T.Terrain.world_maps(L.Landscape.maps(Trace.RestartTrace.seed(state)),K.Creation.world(Trace.RestartTrace.result(state)))

law SeededTrace.as_world:
  for +state: Trace.RestartTrace.State
  for +valid: SeededTrace.OK<state>
  SW.SeededWorld.OK<SeededTrace.world(state),SeededTrace.states(state)>

def SeededTrace.as_world(state,valid):
  match state:
    case Trace.RestartTrace.State{seed,result}:
      match valid:
        case SeededTrace.OK{world,stored}:
          +packed = {Trace.RestartTrace.State{seed,result} : Trace.RestartTrace.State}
          SW.SeededWorld.from_external(SeededTrace.world(packed),SeededTrace.states(packed),seed,Equal.trans(U32,SW.SeededWorld.seed(SeededTrace.world(packed)),W.WorldSeed.of(K.Creation.world(result)),seed,Equal.cong(S.Simulation.State,U32,(s => W.WorldSeed.of(s)),T.Terrain.simulation(SeededTrace.world(packed)),K.Creation.world(result),SeededTrace.world_simulation(packed)),stored),(%Equal.sym(S.Simulation.State,T.Terrain.simulation(SeededTrace.world(packed)),K.Creation.world(result),SeededTrace.world_simulation(packed)) : C.Connections.WorldOK<seed,_,K.Creation.states(result)>; world),SeededTrace.world_maps(packed))

law SeededTrace.world_trace:
  for +inputs: List<&2,Trace.RestartTrace.Input>
  for +state: Trace.RestartTrace.State
  for +valid: SeededTrace.OK<state>
  SW.SeededWorld.OK<SeededTrace.world(Trace.RestartTrace.trace(inputs,state)),SeededTrace.states(Trace.RestartTrace.trace(inputs,state))>

def SeededTrace.world_trace(inputs,state,valid): SeededTrace.as_world(Trace.RestartTrace.trace(inputs,state),SeededTrace.trace_ok(inputs,state,valid))

law SeededTrace.fresh_world_trace:
  for +inputs: List<&2,Trace.RestartTrace.Input>
  for +world: U32
  for +seed: U32
  for +now: U32
  SW.SeededWorld.OK<SeededTrace.world(Trace.RestartTrace.trace(inputs,Trace.RestartTrace.State{seed,K.Creation.Result{T.Terrain.simulation(Pop.Population.fresh(world,seed,now)),Nil{}}})),SeededTrace.states(Trace.RestartTrace.trace(inputs,Trace.RestartTrace.State{seed,K.Creation.Result{T.Terrain.simulation(Pop.Population.fresh(world,seed,now)),Nil{}}}))>

def SeededTrace.fresh_world_trace(inputs,world,seed,now): SeededTrace.as_world(Trace.RestartTrace.trace(inputs,Trace.RestartTrace.State{seed,K.Creation.Result{T.Terrain.simulation(Pop.Population.fresh(world,seed,now)),Nil{}}}),SeededTrace.fresh_trace(inputs,world,seed,now))
