import Base
import ./main.bend as Application
import ./restart.bend as R
import ./restart_trace.bend as Trace
import ./rebuild_check.bend as Old
import ./server.bend as Live
import ./players.bend as P
import ./players_check.bend as Test
import ./creation_check.bend as F
import ./sessions.bend as S
import ./sessions_check.bend as SS
import ./simulation.bend as Sim
import ./terrain.bend as T
import ./population.bend as Pop
import ./creation.bend as K
import ./disconnect.bend as D
import ./frame_bindings.bend as Frame
import ./tick_bindings.bend as Tick
import ./ai_refs.bend as AI

def same(+a: R.Restart.Result,+b: R.Restart.Result) -> Bool: Bool.and(Old.same(R.Restart.world(a),R.Restart.world(b)),F.same_states(R.Restart.states(a),R.Restart.states(b)))

def initial() -> Trace.RestartTrace.State: Trace.RestartTrace.State{0,K.Creation.Result{F.world(99,[F.player(7,1,"Ada"),F.player(8,2,"Bob")]),[SS.state(1,2,7,"Ada"),SS.state(2,2,8,"Bob")]}}

def connection(input: K.Creation.Input) -> Trace.RestartTrace.Input: Trace.RestartTrace.Advance{Tick.TickBindings.Command{Frame.FrameBindings.Lifecycle{D.Disconnect.Connection{input}}}}
def gone(cid: U32) -> Trace.RestartTrace.Input: Trace.RestartTrace.Advance{Tick.TickBindings.Command{Frame.FrameBindings.Lifecycle{D.Disconnect.Gone{cid}}}}
def tick() -> Trace.RestartTrace.Input: Trace.RestartTrace.Advance{Tick.TickBindings.Tick{AI.AIRefs.Damages{Nil{},Nil{},Nil{},Nil{}},60}}

def traced(label: String,+inputs: List<&2,Trace.RestartTrace.Input>,expected_seed: U32,expected: List<&2,S.Sessions.State>) -> IO(Unit):
  +after = Trace.RestartTrace.trace(inputs,initial)
  Test.verdict(label,Bool.and(U32.is_eq(Trace.RestartTrace.seed(after),expected_seed),F.same_states(K.Creation.states(Trace.RestartTrace.result(after)),expected)))

@unsafe
def previous_one(+players: List<&2,P.Players.State>,state: S.Sessions.State) -> S.Sessions.State:
  match state:
    case S.Sessions.State{cid,phase,pid,name}:
      +cid = cid
      S.Sessions.State{cid,phase,Live.Bq.pid_of_cid(players,cid,pid),name}

@unsafe
def previous_states(states: List<&2,S.Sessions.State>,+players: List<&2,P.Players.State>) -> List<&2,S.Sessions.State>:
  match states:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{previous_one(players,head),previous_states(rest,players)}

@unsafe
def previous_result(+world: T.Terrain.World,states: List<&2,S.Sessions.State>) -> R.Restart.Result: R.Restart.Result{world,previous_states(states,Sim.Simulation.players(T.Terrain.simulation(world)))}

@unsafe
def checked(label: String,+players: List<&2,P.Players.State>,+states: List<&2,S.Sessions.State>,+world: U32,+seed: U32,+now: U32) -> IO(Unit):
  Test.verdict(label,same(R.Restart.run(F.world(99,players),states,world,seed,now),previous_result(Old.previous(Pop.Population.fresh(world,seed,now),players),states)))

@unsafe
def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- checked("restart empty seed zero",Nil{},Nil{},1,0,0)
    Unit <- checked("restart empty MAX values",Nil{},Nil{},4294967295,4294967295,4294967295)
    Unit <- checked("restart only waiting",Nil{},[SS.state(1,0,0,""),SS.state(2,1,0,"Bob")],8,72,91)
    Unit <- checked("restart one player",[F.player(7,1,"Ada")],[SS.state(1,2,7,"Ada")],8,123,91)
    Unit <- checked("restart opposite orders",[F.player(8,2,"Bob"),F.player(7,1,"Ada")],[SS.state(1,2,7,"Ada"),SS.state(2,2,8,"Bob")],8,123,91)
    Unit <- checked("restart mixed waiting and playing",[F.player(7,1,"Ada"),F.player(8,2,"Bob")],[SS.state(3,1,0,"Cy"),SS.state(2,2,8,"Bob"),SS.state(4,0,0,""),SS.state(1,2,7,"Ada")],8,123,91)
    Unit <- checked("restart changed gameplay and styles",[Old.styled(7,1,"Ada"),Old.styled(8,2,"Bob")],[SS.state(1,2,7,"Ada"),SS.state(2,2,8,"Bob")],8,123,91)
    Unit <- checked("restart Unicode profiles",[Old.styled(7,1,"Étoile猫"),F.player(8,2,"Bob")],[SS.state(1,2,7,"Étoile猫"),SS.state(2,2,8,"Bob")],8,4294967295,91)
    Unit <- checked("restart MAX old IDs",[F.player(4294967295,4294967295,"Max")],[SS.state(4294967295,2,4294967295,"Max")],0,4294967295,0)
    Unit <- checked("restart invalid duplicate CID legacy behavior",[F.player(7,1,"Ada"),F.player(8,1,"Bob")],[SS.state(1,2,7,"Ada")],8,123,91)
    Unit <- checked("restart invalid zero CID legacy behavior",[F.player(7,0,"Ada")],[SS.state(0,2,7,"Ada")],8,123,91)
    Unit <- checked("restart invalid missing player legacy fallback",[F.player(7,1,"Ada")],[SS.state(1,2,7,"Ada"),SS.state(2,2,8,"Bob")],8,123,91)
    Unit <- traced("restart trace empty trace",Nil{},0,[SS.state(1,2,7,"Ada"),SS.state(2,2,8,"Bob")])
    Unit <- traced("restart trace single restart",[Trace.RestartTrace.Replace{8,123,91}],123,[SS.state(1,2,1,"Ada"),SS.state(2,2,2,"Bob")])
    Unit <- traced("restart trace two restarts reverse allocation",[Trace.RestartTrace.Replace{8,123,91},Trace.RestartTrace.Replace{9,4294967295,100}],4294967295,[SS.state(1,2,2,"Ada"),SS.state(2,2,1,"Bob")])
    Unit <- traced("restart trace restart then disconnect",[Trace.RestartTrace.Replace{8,123,91},gone(1)],123,[SS.state(2,2,2,"Bob")])
    Unit <- traced("restart trace restart disconnect restart",[Trace.RestartTrace.Replace{8,123,91},gone(1),Trace.RestartTrace.Replace{9,4294967295,100}],4294967295,[SS.state(2,2,1,"Bob")])
    Unit <- traced("restart trace restart then create",[Trace.RestartTrace.Replace{8,123,91},connection(K.Creation.Connect{3}),connection(K.Creation.Hello{3,SS.name("Cy")}),connection(K.Creation.Create{3,F.style,True{}})],123,[SS.state(3,2,3,"Cy"),SS.state(1,2,1,"Ada"),SS.state(2,2,2,"Bob")])
    Unit <- traced("restart trace restart create restart",[Trace.RestartTrace.Replace{8,123,91},connection(K.Creation.Connect{3}),connection(K.Creation.Hello{3,SS.name("Cy")}),connection(K.Creation.Create{3,F.style,True{}}),Trace.RestartTrace.Replace{9,4294967295,100}],4294967295,[SS.state(3,2,1,"Cy"),SS.state(1,2,3,"Ada"),SS.state(2,2,2,"Bob")])
    Unit <- traced("restart trace restart tick restart",[Trace.RestartTrace.Replace{8,123,91},tick,Trace.RestartTrace.Replace{9,4294967295,100},tick],4294967295,[SS.state(1,2,2,"Ada"),SS.state(2,2,1,"Bob")])
    traced("restart trace bound rename after restart",[Trace.RestartTrace.Replace{8,123,91},connection(K.Creation.Hello{2,SS.name("Other")})],123,[SS.state(2,2,2,"Bob"),SS.state(1,2,1,"Ada")])

#| PASS restart empty seed zero
#| PASS restart empty MAX values
#| PASS restart only waiting
#| PASS restart one player
#| PASS restart opposite orders
#| PASS restart mixed waiting and playing
#| PASS restart changed gameplay and styles
#| PASS restart Unicode profiles
#| PASS restart MAX old IDs
#| PASS restart invalid duplicate CID legacy behavior
#| PASS restart invalid zero CID legacy behavior
#| PASS restart invalid missing player legacy fallback
#| PASS restart trace empty trace
#| PASS restart trace single restart
#| PASS restart trace two restarts reverse allocation
#| PASS restart trace restart then disconnect
#| PASS restart trace restart disconnect restart
#| PASS restart trace restart then create
#| PASS restart trace restart create restart
#| PASS restart trace restart tick restart
#| PASS restart trace bound rename after restart
