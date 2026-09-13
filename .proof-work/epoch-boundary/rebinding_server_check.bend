import Base
import ./main.bend as Application
import ./rebinding.bend as R
import ./server.bend as Live
import ./players.bend as P
import ./players_check.bend as Test
import ./creation_check.bend as F
import ./sessions.bend as S
import ./sessions_check.bend as SS
import ./rebuild.bend as Rebuild
import ./simulation.bend as Sim
import ./disconnect_server_check.bend as Channels

@unsafe
def result(label: String,+connections: List<&1,Live.Bq.Conn>,expected: List<&2,S.Sessions.State>) -> IO(Unit):
  +same = F.same_states(Live.Bq.session_descriptors(connections),expected)
  do IO<Unit>:
    retained : Bool <- Channels.retained_channels(connections)
    Test.verdict(label,Bool.and(same,retained))

@unsafe
def checked(label: String,states: List<&2,S.Sessions.State>,players: List<&2,P.Players.State>,expected: List<&2,S.Sessions.State>) -> IO(Unit):
  do IO<Unit>:
    connections : List<&1,Live.Bq.Conn> <- Channels.make_connections(states)
    result(label,Live.Bq.rebind_conns(connections,players),expected)

@unsafe
def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- checked("server rebind empty",Nil{},Nil{},Nil{})
    Unit <- checked("server rebind fresh waiting unchanged",[SS.state(3,0,0,"")],[F.player(71,1,"Ada")],[SS.state(3,0,0,"")])
    Unit <- checked("server rebind named waiting unchanged",[SS.state(3,1,0,"Cy")],[F.player(71,1,"Ada")],[SS.state(3,1,0,"Cy")])
    Unit <- checked("server rebind playing changes PID",[SS.state(1,2,7,"Ada")],[F.player(71,1,"Ada")],[SS.state(1,2,71,"Ada")])
    Unit <- checked("server rebind opposite roster orders",[SS.state(1,2,7,"Ada"),SS.state(2,2,8,"Bob")],[F.player(82,2,"Bob"),F.player(71,1,"Ada")],[SS.state(1,2,71,"Ada"),SS.state(2,2,82,"Bob")])
    Unit <- checked("server rebind mixed waiting and playing",[SS.state(3,1,0,"Cy"),SS.state(2,2,8,"Bob"),SS.state(4,0,0,""),SS.state(1,2,7,"Ada")],[F.player(71,1,"Ada"),F.player(82,2,"Bob")],[SS.state(3,1,0,"Cy"),SS.state(2,2,82,"Bob"),SS.state(4,0,0,""),SS.state(1,2,71,"Ada")])
    Unit <- checked("server rebind MAX IDs",[SS.state(4294967295,2,7,"Max")],[F.player(4294967295,4294967295,"Max")],[SS.state(4294967295,2,4294967295,"Max")])
    Unit <- checked("server rebind UTF8 identity",[SS.state(1,2,7,"Étoile猫")],[F.player(71,1,"Étoile猫")],[SS.state(1,2,71,"Étoile猫")])
    Unit <- checked("server rebind invalid missing player keeps old PID",[SS.state(1,2,7,"Ada")],Nil{},[SS.state(1,2,7,"Ada")])
    Unit <- checked("server rebind invalid phase preserved",[SS.state(1,4294967295,7,"Ada")],[F.player(71,1,"Ada")],[SS.state(1,4294967295,71,"Ada")])
    Unit <- checked("server rebind invalid duplicate CID first wins",[SS.state(1,2,7,"Ada")],[F.player(71,1,"Ada"),F.player(82,1,"Bob")],[SS.state(1,2,71,"Ada")])
    Unit <- checked("server rebind server retains descriptor name",[SS.state(1,2,7,"Ada")],[F.player(71,1,"Bob")],[SS.state(1,2,71,"Ada")])
    Unit <- checked("server rebind actual reconstruction",[SS.state(1,2,7,"Ada"),SS.state(3,1,0,"Cy"),SS.state(2,2,8,"Bob")],Sim.Simulation.players(Rebuild.Rebuild.run([F.player(7,1,"Ada"),F.player(8,2,"Bob")],F.world(1,Nil{}))),[SS.state(1,2,1,"Ada"),SS.state(3,1,0,"Cy"),SS.state(2,2,2,"Bob")])
    checked("server rebind actual reconstruction wraps",[SS.state(2,2,8,"Bob"),SS.state(1,2,7,"Ada")],Sim.Simulation.players(Rebuild.Rebuild.run([F.player(7,1,"Ada"),F.player(8,2,"Bob")],F.world(4294967295,Nil{}))),[SS.state(2,2,1,"Bob"),SS.state(1,2,4294967295,"Ada")])

#| PASS server rebind empty
#| PASS server rebind fresh waiting unchanged
#| PASS server rebind named waiting unchanged
#| PASS server rebind playing changes PID
#| PASS server rebind opposite roster orders
#| PASS server rebind mixed waiting and playing
#| PASS server rebind MAX IDs
#| PASS server rebind UTF8 identity
#| PASS server rebind invalid missing player keeps old PID
#| PASS server rebind invalid phase preserved
#| PASS server rebind invalid duplicate CID first wins
#| PASS server rebind server retains descriptor name
#| PASS server rebind actual reconstruction
#| PASS server rebind actual reconstruction wraps
