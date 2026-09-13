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
import ./disconnect_server_check.bend as Channels

def same(+a: R.Restart.Result,+b: R.Restart.Result) -> Bool: Bool.and(Old.same(R.Restart.world(a),R.Restart.world(b)),F.same_states(R.Restart.states(a),R.Restart.states(b)))

def initial() -> Trace.RestartTrace.State: Trace.RestartTrace.State{0,K.Creation.Result{F.world(99,[F.player(7,1,"Ada"),F.player(8,2,"Bob")]),[SS.state(1,2,7,"Ada"),SS.state(2,2,8,"Bob")]}}

def connection(input: K.Creation.Input) -> Trace.RestartTrace.Input: Trace.RestartTrace.Advance{Tick.TickBindings.Command{Frame.FrameBindings.Lifecycle{D.Disconnect.Connection{input}}}}
def gone(cid: U32) -> Trace.RestartTrace.Input: Trace.RestartTrace.Advance{Tick.TickBindings.Command{Frame.FrameBindings.Lifecycle{D.Disconnect.Gone{cid}}}}
def tick() -> Trace.RestartTrace.Input: Trace.RestartTrace.Advance{Tick.TickBindings.Tick{AI.AIRefs.Damages{Nil{},Nil{},Nil{},Nil{}},60}}

def traced(label: String,+inputs: List<&2,Trace.RestartTrace.Input>,expected_seed: U32,expected: List<&2,S.Sessions.State>) -> IO(Unit):
  +after = Trace.RestartTrace.trace(inputs,initial)
  Test.verdict(label,Bool.and(U32.is_eq(Trace.RestartTrace.seed(after),expected_seed),F.same_states(K.Creation.states(Trace.RestartTrace.result(after)),expected)))

@unsafe
def result(label: String,+world: T.Terrain.World,+connections: List<&1,Live.Bq.Conn>,expected: R.Restart.Result) -> IO(Unit):
  +equal = same(R.Restart.Result{world,Live.Bq.session_descriptors(connections)},expected)
  do IO<Unit>:
    retained : Bool <- Channels.retained_channels(connections)
    Test.verdict(label,Bool.and(equal,retained))

@unsafe
def adapter(label: String,+world: T.Terrain.World,states: List<&2,S.Sessions.State>,expected: R.Restart.Result) -> IO(Unit):
  do IO<Unit>:
    connections : List<&1,Live.Bq.Conn> <- Channels.make_connections(states)
    result(label,world,Live.Bq.rebind_conns(connections,Sim.Simulation.players(T.Terrain.simulation(world))),expected)

@unsafe
def checked(label: String,+players: List<&2,P.Players.State>,+states: List<&2,S.Sessions.State>,+world: U32,+seed: U32,+now: U32) -> IO(Unit):
  adapter(label,Live.Bq.readd_plrs(Pop.Population.fresh(world,seed,now),players),states,R.Restart.run(F.world(99,players),states,world,seed,now))

@unsafe
def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- checked("server restart empty seed zero",Nil{},Nil{},1,0,0)
    Unit <- checked("server restart empty MAX values",Nil{},Nil{},4294967295,4294967295,4294967295)
    Unit <- checked("server restart only waiting",Nil{},[SS.state(1,0,0,""),SS.state(2,1,0,"Bob")],8,72,91)
    Unit <- checked("server restart one player",[F.player(7,1,"Ada")],[SS.state(1,2,7,"Ada")],8,123,91)
    Unit <- checked("server restart opposite orders",[F.player(8,2,"Bob"),F.player(7,1,"Ada")],[SS.state(1,2,7,"Ada"),SS.state(2,2,8,"Bob")],8,123,91)
    Unit <- checked("server restart mixed waiting and playing",[F.player(7,1,"Ada"),F.player(8,2,"Bob")],[SS.state(3,1,0,"Cy"),SS.state(2,2,8,"Bob"),SS.state(4,0,0,""),SS.state(1,2,7,"Ada")],8,123,91)
    Unit <- checked("server restart changed gameplay and styles",[Old.styled(7,1,"Ada"),Old.styled(8,2,"Bob")],[SS.state(1,2,7,"Ada"),SS.state(2,2,8,"Bob")],8,123,91)
    Unit <- checked("server restart Unicode profiles",[Old.styled(7,1,"Étoile猫"),F.player(8,2,"Bob")],[SS.state(1,2,7,"Étoile猫"),SS.state(2,2,8,"Bob")],8,4294967295,91)
    Unit <- checked("server restart MAX old IDs",[F.player(4294967295,4294967295,"Max")],[SS.state(4294967295,2,4294967295,"Max")],0,4294967295,0)
    Unit <- checked("server restart invalid duplicate CID legacy behavior",[F.player(7,1,"Ada"),F.player(8,1,"Bob")],[SS.state(1,2,7,"Ada")],8,123,91)
    Unit <- checked("server restart invalid zero CID legacy behavior",[F.player(7,0,"Ada")],[SS.state(0,2,7,"Ada")],8,123,91)
    checked("server restart invalid missing player legacy fallback",[F.player(7,1,"Ada")],[SS.state(1,2,7,"Ada"),SS.state(2,2,8,"Bob")],8,123,91)

#| PASS server restart empty seed zero
#| PASS server restart empty MAX values
#| PASS server restart only waiting
#| PASS server restart one player
#| PASS server restart opposite orders
#| PASS server restart mixed waiting and playing
#| PASS server restart changed gameplay and styles
#| PASS server restart Unicode profiles
#| PASS server restart MAX old IDs
#| PASS server restart invalid duplicate CID legacy behavior
#| PASS server restart invalid zero CID legacy behavior
#| PASS server restart invalid missing player legacy fallback
