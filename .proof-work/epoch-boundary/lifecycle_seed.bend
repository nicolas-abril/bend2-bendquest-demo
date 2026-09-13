# Stored seed preservation through connection lifecycle and mixed tick inputs.
import Base
import ./world_seed.bend as W
import ./simulation.bend as S
import ./players.bend as P
import ./sessions.bend as Sess
import ./admission.bend as J
import ./creation.bend as K
import ./selection.bend as Q
import ./disconnect.bend as D
import ./frame_bindings.bend as F
import ./tick_bindings.bend as Tick
import ./landscape.bend as L
import ./planning.bend as Plan

def LifecycleSeed.of(result: K.Creation.Result) -> U32: W.WorldSeed.of(K.Creation.world(result))

law LifecycleSeed.finish_gate:
  for +failed: Bool
  for +result: J.Admission.Result
  for +before: S.Simulation.State
  for +head: Sess.Sessions.State
  for +others: List<&2,Sess.Sessions.State>
  for +same: {W.WorldSeed.of(J.Admission.state(result)) == W.WorldSeed.of(before) : U32}
  {LifecycleSeed.of(K.Creation.finish_gate(failed,result,before,head,others)) == W.WorldSeed.of(before) : U32}

def LifecycleSeed.finish_gate(failed,result,before,head,others,same):
  match failed:
    case True{}: {==}
    case False{}: same

law LifecycleSeed.finish:
  for +result: J.Admission.Result
  for +before: S.Simulation.State
  for +head: Sess.Sessions.State
  for +others: List<&2,Sess.Sessions.State>
  for +same: {W.WorldSeed.of(J.Admission.state(result)) == W.WorldSeed.of(before) : U32}
  {LifecycleSeed.of(K.Creation.finish(result,before,head,others)) == W.WorldSeed.of(before) : U32}

def LifecycleSeed.finish(result,before,head,others,same): LifecycleSeed.finish_gate(U32.is_eq(J.Admission.pid(result),0),result,before,head,others,same)

law LifecycleSeed.allow:
  for +permitted: Bool
  for +before: S.Simulation.State
  for +head: Sess.Sessions.State
  for +others: List<&2,Sess.Sessions.State>
  for +style: P.Players.Style
  {LifecycleSeed.of(K.Creation.allow(permitted,before,head,others,style)) == W.WorldSeed.of(before) : U32}

def LifecycleSeed.allow(permitted,before,head,others,style):
  match permitted:
    case False{}: {==}
    case True{}: LifecycleSeed.finish(J.Admission.add(before,Sess.Sessions.cid(head),style,Sess.Sessions.name(head)),before,head,others,W.WorldSeed.admission(before,Sess.Sessions.cid(head),style,Sess.Sessions.name(head)))

law LifecycleSeed.ready:
  for +ready: Bool
  for +permitted: Bool
  for +before: S.Simulation.State
  for +head: Sess.Sessions.State
  for +others: List<&2,Sess.Sessions.State>
  for +style: P.Players.Style
  {LifecycleSeed.of(K.Creation.ready_gate(ready,permitted,before,head,others,style)) == W.WorldSeed.of(before) : U32}

def LifecycleSeed.ready(ready,permitted,before,head,others,style):
  match ready:
    case False{}: {==}
    case True{}: LifecycleSeed.allow(permitted,before,head,others,style)

law LifecycleSeed.taken:
  for +taken: Q.Selection.Take
  for +before: S.Simulation.State
  for +style: P.Players.Style
  for +permitted: Bool
  {LifecycleSeed.of(K.Creation.taken(taken,before,style,permitted)) == W.WorldSeed.of(before) : U32}

def LifecycleSeed.taken(taken,before,style,permitted):
  match taken:
    case Q.Selection.Take{others,found}:
      match found:
        case None{}: {==}
        case Some{head}: LifecycleSeed.ready(U32.is_eq(Sess.Sessions.phase(head),1),permitted,before,head,others,style)

law LifecycleSeed.create:
  for +before: S.Simulation.State
  for +states: List<&2,Sess.Sessions.State>
  for +cid: U32
  for +style: P.Players.Style
  for +permitted: Bool
  {LifecycleSeed.of(K.Creation.create(before,states,cid,style,permitted)) == W.WorldSeed.of(before) : U32}

def LifecycleSeed.create(before,states,cid,style,permitted): LifecycleSeed.taken(Q.Selection.take(states,cid),before,style,permitted)

law LifecycleSeed.connection:
  for +input: K.Creation.Input
  for +result: K.Creation.Result
  {LifecycleSeed.of(K.Creation.step(input,result)) == LifecycleSeed.of(result) : U32}

def LifecycleSeed.connection(input,result):
  match input:
    case K.Creation.Connect{hint}:
      match result:
        case K.Creation.Result{world,states}: {==}
    case K.Creation.Hello{cid,name}:
      match result:
        case K.Creation.Result{world,states}: {==}
    case K.Creation.Create{cid,style,permitted}:
      match result:
        case K.Creation.Result{world,states}: LifecycleSeed.create(world,states,cid,style,permitted)

law LifecycleSeed.departed:
  for +taken: Q.Selection.Take
  for +world: S.Simulation.State
  {LifecycleSeed.of(D.Disconnect.taken(taken,world)) == W.WorldSeed.of(world) : U32}

def LifecycleSeed.departed(taken,world):
  match taken:
    case Q.Selection.Take{others,found}:
      match found:
        case None{}: {==}
        case Some{head}: W.WorldSeed.remove(world,Sess.Sessions.pid(head))

law LifecycleSeed.lifecycle:
  for +input: D.Disconnect.Input
  for +result: K.Creation.Result
  {LifecycleSeed.of(D.Disconnect.step(input,result)) == LifecycleSeed.of(result) : U32}

def LifecycleSeed.lifecycle(input,result):
  match input:
    case D.Disconnect.Connection{input}: LifecycleSeed.connection(input,result)
    case D.Disconnect.Gone{cid}:
      match result:
        case K.Creation.Result{world,states}: LifecycleSeed.departed(Q.Selection.take(states,cid),world)

law LifecycleSeed.frame:
  for +input: F.FrameBindings.Input
  for +seed: U32
  for +result: K.Creation.Result
  {LifecycleSeed.of(F.FrameBindings.step(input,seed,result)) == LifecycleSeed.of(result) : U32}

def LifecycleSeed.frame(input,seed,result):
  match input:
    case F.FrameBindings.Lifecycle{input}: LifecycleSeed.lifecycle(input,result)
    case F.FrameBindings.Action{command}:
      match result:
        case K.Creation.Result{world,states}: W.WorldSeed.change(F.FrameBindings.change(command),world,L.Landscape.maps(seed))

law LifecycleSeed.tick:
  for +input: Tick.TickBindings.Input
  for +seed: U32
  for +result: K.Creation.Result
  {LifecycleSeed.of(Tick.TickBindings.step(input,seed,result)) == LifecycleSeed.of(result) : U32}

def LifecycleSeed.tick(input,seed,result):
  match input:
    case Tick.TickBindings.Command{input}: LifecycleSeed.frame(input,seed,result)
    case Tick.TickBindings.Tick{damages,timer}:
      match result:
        case K.Creation.Result{world,states}: W.WorldSeed.run_tick(damages,world,L.Landscape.maps(seed),Plan.Planning.rules(timer))
