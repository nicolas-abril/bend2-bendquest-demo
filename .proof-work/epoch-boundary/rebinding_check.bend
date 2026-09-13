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

@unsafe
def lookup(label: String,+players: List<&2,P.Players.State>,+cid: U32,+fallback: U32,+expected: U32) -> IO(Unit): Test.verdict(label,Bool.and(U32.is_eq(R.Rebinding.lookup(players,cid,fallback),expected),U32.is_eq(Live.Bq.pid_of_cid(players,cid,fallback),expected)))

def checked(label: String,states: List<&2,S.Sessions.State>,players: List<&2,P.Players.State>,expected: List<&2,S.Sessions.State>) -> IO(Unit): Test.verdict(label,F.same_states(R.Rebinding.run(states,players),expected))

@unsafe
def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- lookup("rebind lookup empty keeps default",Nil{},1,19,19)
    Unit <- lookup("rebind lookup first CID",[F.player(71,1,"Ada"),F.player(82,2,"Bob")],1,19,71)
    Unit <- lookup("rebind lookup last CID",[F.player(71,1,"Ada"),F.player(82,2,"Bob")],2,19,82)
    Unit <- lookup("rebind lookup middle CID",[F.player(71,1,"Ada"),F.player(82,2,"Bob"),F.player(93,3,"Cy")],2,19,82)
    Unit <- lookup("rebind lookup absent keeps old PID",[F.player(71,1,"Ada")],9,42,42)
    Unit <- lookup("rebind lookup absent keeps zero",[F.player(71,1,"Ada")],9,0,0)
    Unit <- lookup("rebind lookup absent keeps MAX",[F.player(71,1,"Ada")],9,4294967295,4294967295)
    Unit <- lookup("rebind lookup MAX PID and CID",[F.player(4294967295,4294967295,"Max")],4294967295,19,4294967295)
    Unit <- lookup("rebind lookup CID differs from PID",[F.player(2,1,"Ada"),F.player(1,2,"Bob")],1,19,2)
    Unit <- lookup("rebind lookup duplicate CID first wins",[F.player(71,1,"Ada"),F.player(82,1,"Bob")],1,19,71)
    Unit <- lookup("rebind lookup zero CID legacy match",[F.player(71,0,"Ada")],0,19,71)
    Unit <- lookup("rebind lookup zero PID legacy match",[F.player(0,1,"Ada")],1,19,0)
    Unit <- checked("rebind empty",Nil{},Nil{},Nil{})
    Unit <- checked("rebind fresh waiting unchanged",[SS.state(3,0,0,"")],[F.player(71,1,"Ada")],[SS.state(3,0,0,"")])
    Unit <- checked("rebind named waiting unchanged",[SS.state(3,1,0,"Cy")],[F.player(71,1,"Ada")],[SS.state(3,1,0,"Cy")])
    Unit <- checked("rebind playing changes PID",[SS.state(1,2,7,"Ada")],[F.player(71,1,"Ada")],[SS.state(1,2,71,"Ada")])
    Unit <- checked("rebind opposite roster orders",[SS.state(1,2,7,"Ada"),SS.state(2,2,8,"Bob")],[F.player(82,2,"Bob"),F.player(71,1,"Ada")],[SS.state(1,2,71,"Ada"),SS.state(2,2,82,"Bob")])
    Unit <- checked("rebind mixed waiting and playing",[SS.state(3,1,0,"Cy"),SS.state(2,2,8,"Bob"),SS.state(4,0,0,""),SS.state(1,2,7,"Ada")],[F.player(71,1,"Ada"),F.player(82,2,"Bob")],[SS.state(3,1,0,"Cy"),SS.state(2,2,82,"Bob"),SS.state(4,0,0,""),SS.state(1,2,71,"Ada")])
    Unit <- checked("rebind MAX IDs",[SS.state(4294967295,2,7,"Max")],[F.player(4294967295,4294967295,"Max")],[SS.state(4294967295,2,4294967295,"Max")])
    Unit <- checked("rebind UTF8 identity",[SS.state(1,2,7,"Étoile猫")],[F.player(71,1,"Étoile猫")],[SS.state(1,2,71,"Étoile猫")])
    Unit <- checked("rebind invalid missing player keeps old PID",[SS.state(1,2,7,"Ada")],Nil{},[SS.state(1,2,7,"Ada")])
    Unit <- checked("rebind invalid phase preserved",[SS.state(1,4294967295,7,"Ada")],[F.player(71,1,"Ada")],[SS.state(1,4294967295,71,"Ada")])
    Unit <- checked("rebind invalid duplicate CID first wins",[SS.state(1,2,7,"Ada")],[F.player(71,1,"Ada"),F.player(82,1,"Bob")],[SS.state(1,2,71,"Ada")])
    Unit <- checked("rebind server retains descriptor name",[SS.state(1,2,7,"Ada")],[F.player(71,1,"Bob")],[SS.state(1,2,71,"Ada")])
    Unit <- checked("rebind actual reconstruction",[SS.state(1,2,7,"Ada"),SS.state(3,1,0,"Cy"),SS.state(2,2,8,"Bob")],Sim.Simulation.players(Rebuild.Rebuild.run([F.player(7,1,"Ada"),F.player(8,2,"Bob")],F.world(1,Nil{}))),[SS.state(1,2,1,"Ada"),SS.state(3,1,0,"Cy"),SS.state(2,2,2,"Bob")])
    checked("rebind actual reconstruction wraps",[SS.state(2,2,8,"Bob"),SS.state(1,2,7,"Ada")],Sim.Simulation.players(Rebuild.Rebuild.run([F.player(7,1,"Ada"),F.player(8,2,"Bob")],F.world(4294967295,Nil{}))),[SS.state(2,2,1,"Bob"),SS.state(1,2,4294967295,"Ada")])

#| PASS rebind lookup empty keeps default
#| PASS rebind lookup first CID
#| PASS rebind lookup last CID
#| PASS rebind lookup middle CID
#| PASS rebind lookup absent keeps old PID
#| PASS rebind lookup absent keeps zero
#| PASS rebind lookup absent keeps MAX
#| PASS rebind lookup MAX PID and CID
#| PASS rebind lookup CID differs from PID
#| PASS rebind lookup duplicate CID first wins
#| PASS rebind lookup zero CID legacy match
#| PASS rebind lookup zero PID legacy match
#| PASS rebind empty
#| PASS rebind fresh waiting unchanged
#| PASS rebind named waiting unchanged
#| PASS rebind playing changes PID
#| PASS rebind opposite roster orders
#| PASS rebind mixed waiting and playing
#| PASS rebind MAX IDs
#| PASS rebind UTF8 identity
#| PASS rebind invalid missing player keeps old PID
#| PASS rebind invalid phase preserved
#| PASS rebind invalid duplicate CID first wins
#| PASS rebind server retains descriptor name
#| PASS rebind actual reconstruction
#| PASS rebind actual reconstruction wraps
