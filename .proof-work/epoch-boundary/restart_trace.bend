# Mixed pure lifecycle, gameplay, ticks and restarts with changing world seeds.
import Base
import ./world_clock.bend as Clock
import ./restart.bend as R
import ./tick_bindings.bend as Tick
import ./creation.bend as K
import ./connections.bend as C
import ./terrain.bend as T
import ./population.bend as Pop

type RestartTrace.State is Data:
  RestartTrace.State{seed: U32,result: K.Creation.Result}

def RestartTrace.seed(state: RestartTrace.State) -> U32:
  match state:
    case RestartTrace.State{seed,result}: seed

def RestartTrace.result(state: RestartTrace.State) -> K.Creation.Result:
  match state:
    case RestartTrace.State{seed,result}: result

def RestartTrace.OK(state: RestartTrace.State) -> Data:
  match state:
    case RestartTrace.State{seed,result}: K.Creation.OK(seed,result)

def RestartTrace.restarted(seed: U32,result: R.Restart.Result) -> RestartTrace.State:
  match result:
    case R.Restart.Result{world,states}: RestartTrace.State{seed,K.Creation.Result{T.Terrain.simulation(world),states}}

type RestartTrace.Input is Data:
  RestartTrace.Advance{input: Tick.TickBindings.Input}
  RestartTrace.Time{now: U32}
  RestartTrace.Replace{world: U32,seed: U32,now: U32}

def RestartTrace.step(input: RestartTrace.Input,state: RestartTrace.State) -> RestartTrace.State:
  match input:
    case RestartTrace.Advance{input}:
      match state:
        case RestartTrace.State{seed,result}:
          +seed = seed
          RestartTrace.State{seed,Tick.TickBindings.step(input,seed,result)}
    case RestartTrace.Time{now}:
      match state:
        case RestartTrace.State{seed,result}:
          match result:
            case K.Creation.Result{world,states}: RestartTrace.State{seed,K.Creation.Result{Clock.WorldClock.state(world,now),states}}
    case RestartTrace.Replace{world,seed,now}:
      match state:
        case RestartTrace.State{old_seed,result}:
          match result:
            case K.Creation.Result{before,states}:
              +seed = seed
              RestartTrace.restarted(seed,R.Restart.run(before,states,world,seed,now))

def RestartTrace.trace(inputs: List<&2,RestartTrace.Input>,state: RestartTrace.State) -> RestartTrace.State:
  match inputs:
    case Nil{}: state
    case Con{head,rest}: RestartTrace.trace(rest,RestartTrace.step(head,state))

law RestartTrace.restarted_ok:
  for +seed: U32
  for +result: R.Restart.Result
  for +valid: R.Restart.OK(seed,result)
  RestartTrace.OK(RestartTrace.restarted(seed,result))

def RestartTrace.restarted_ok(seed,result,valid):
  match result:
    case R.Restart.Result{world,states}: valid

law RestartTrace.step_ok:
  for +input: RestartTrace.Input
  for +state: RestartTrace.State
  for +valid: RestartTrace.OK(state)
  RestartTrace.OK(RestartTrace.step(input,state))

def RestartTrace.step_ok(input,state,valid):
  match input:
    case RestartTrace.Advance{input}:
      match state:
        case RestartTrace.State{seed,result}: Tick.TickBindings.step_ok(input,seed,result,valid)
    case RestartTrace.Time{now}:
      match state:
        case RestartTrace.State{seed,result}:
          match result:
            case K.Creation.Result{world,states}: Clock.WorldClock.connections(seed,world,now,states,valid)
    case RestartTrace.Replace{world,seed,now}:
      match state:
        case RestartTrace.State{old_seed,result}:
          match result:
            case K.Creation.Result{before,states}: RestartTrace.restarted_ok(seed,R.Restart.run(before,states,world,seed,now),R.Restart.run_ok(old_seed,before,states,world,seed,now,valid))

law RestartTrace.trace_ok:
  for +inputs: List<&2,RestartTrace.Input>
  for +state: RestartTrace.State
  for +valid: RestartTrace.OK(state)
  RestartTrace.OK(RestartTrace.trace(inputs,state))

def RestartTrace.trace_ok(inputs,state,valid):
  match inputs:
    case Nil{}: valid
    case Con{head,rest}: RestartTrace.trace_ok(rest,RestartTrace.step(head,state),RestartTrace.step_ok(head,state,valid))

law RestartTrace.fresh_trace:
  for +inputs: List<&2,RestartTrace.Input>
  for +world: U32
  for +seed: U32
  for +now: U32
  RestartTrace.OK(RestartTrace.trace(inputs,RestartTrace.State{seed,K.Creation.Result{T.Terrain.simulation(Pop.Population.fresh(world,seed,now)),Nil{}}}))

def RestartTrace.fresh_trace(inputs,world,seed,now): RestartTrace.trace_ok(inputs,RestartTrace.State{seed,K.Creation.Result{T.Terrain.simulation(Pop.Population.fresh(world,seed,now)),Nil{}}},C.Connections.fresh_world(world,seed,now))
