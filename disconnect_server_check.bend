import Base
import ./connection.bend as Net
import ./main.bend as Application
import ./disconnect.bend as D
import ./disconnect_check.bend as Fixture
import ./creation.bend as K
import ./creation_check.bend as F
import ./sessions.bend as S
import ./sessions_check.bend as SS
import ./players_check.bend as Test
import ./players.bend as P
import ./simulation.bend as Sim
import ./terrain.bend as T
import ./landscape.bend as L
import ./server.bend as Server
import ./compat.bend as C

@unsafe
def marked_connection(+state: S.Sessions.State,+out: Chan<C.Bq.String>) -> IO(Server.Bq.Conn):
  do IO<Server.Bq.Conn>:
    sent : Bool <- Chan.send(C.Bq.String,out,P.Players.text_name(S.Sessions.name(state)))
    IO.pure(Server.Bq.Conn,Server.Bq.connection_from_descriptor(state,out))

@unsafe
def make_connection(state: S.Sessions.State) -> IO(Server.Bq.Conn):
  do IO<Server.Bq.Conn>:
    out : Chan<C.Bq.String> <- Chan.new(C.Bq.String,128)
    marked_connection(state,out)

@unsafe
def make_connections(states: List<&2,S.Sessions.State>) -> IO(List<&1,Server.Bq.Conn>):
  match states:
    case Nil{}: IO.pure(List<&1,Server.Bq.Conn>,Nil{})
    case Con{head,rest}:
      do IO<List<&1,Server.Bq.Conn>>:
        first : Server.Bq.Conn <- make_connection(head)
        later : List<&1,Server.Bq.Conn> <- make_connections(rest)
        IO.pure(List<&1,Server.Bq.Conn>,Con{first,later})

@unsafe
def marker_matches(message: Maybe<&1,C.Bq.String>,expected: C.Bq.String) -> Bool:
  match message:
    case None{}: False{}
    case Some{actual}: S.Sessions.name_eq(P.Players.share_name(actual),P.Players.share_name(expected))

@unsafe
def retained_channel(connection: Server.Bq.Conn) -> IO(Bool):
  match connection:
    case Net.Connection.Record{cid,phase,pid,out,name}:
      +out = out
      do IO<Bool>:
        message : Maybe<&1,C.Bq.String> <- Chan.recv(C.Bq.String,out)
        open : Bool <- Chan.send(C.Bq.String,out,Nil{})
        Unit <- Chan.close(C.Bq.String,out)
        IO.pure(Bool,Bool.and(open,marker_matches(message,name)))

@unsafe
def retained_channels(connections: List<&1,Server.Bq.Conn>) -> IO(Bool):
  match connections:
    case Nil{}: IO.pure(Bool,True{})
    case Con{head,rest}:
      do IO<Bool>:
        first : Bool <- retained_channel(head)
        later : Bool <- retained_channels(rest)
        IO.pure(Bool,Bool.and(first,later))

@unsafe
def departed_channel(found: Result<&1,&1,Unit,Server.Bq.Conn>) -> IO(Bool):
  match found:
    case Fail{unit}: IO.pure(Bool,True{})
    case Done{connection}:
      match connection:
        case Net.Connection.Record{cid,phase,pid,out,name}:
          do IO<Bool>:
            accepted : Bool <- Chan.send(C.Bq.String,out,Nil{})
            IO.pure(Bool,Bool.not(accepted))

@unsafe
def departed_taken(taken: List<&1,Server.Bq.Conn> & Result<&1,&1,Unit,Server.Bq.Conn>) -> IO(Bool):
  match taken:
    case Tuple{others,found}: departed_channel(found)

@unsafe
def adapter_result(label: String,result: T.Terrain.World & List<&1,Server.Bq.Conn>,expected: K.Creation.Result,closed: Bool) -> IO(Unit):
  match result:
    case Tuple{world,states}:
      +world = world
      +states = states
      +same = Bool.and(F.same(K.Creation.Result{T.Terrain.simulation(world),Server.Bq.session_descriptors(states)},expected),F.same_maps(T.Terrain.maps(world),L.Landscape.maps(0)))
      do IO<Unit>:
        retained : Bool <- retained_channels(states)
        Test.verdict(label,Bool.and(same,Bool.and(closed,retained)))

@unsafe
def adapter_run(label: String,+before: Sim.Simulation.State,+states: List<&2,S.Sessions.State>,+cid: U32,+connections: List<&1,Server.Bq.Conn>,+log: Chan<C.Bq.String>) -> IO(Unit):
  do IO<Unit>:
    result : T.Terrain.World & List<&1,Server.Bq.Conn> <- Server.Bq.on_gone(T.Terrain.world(L.Landscape.maps(0),before),connections,cid,log)
    closed : Bool <- departed_taken(Server.Bq.take_conn(cid,connections))
    Unit <- Chan.close(C.Bq.String,log)
    adapter_result(label,result,D.Disconnect.run(before,states,cid),closed)

@unsafe
def adapter_connections(label: String,+before: Sim.Simulation.State,+states: List<&2,S.Sessions.State>,cid: U32,log: Chan<C.Bq.String>) -> IO(Unit):
  do IO<Unit>:
    actual : List<&1,Server.Bq.Conn> <- make_connections(states)
    adapter_run(label,before,states,cid,actual,log)

@unsafe
def adapter(label: String,before: K.Creation.Result,cid: U32) -> IO(Unit):
  match before:
    case K.Creation.Result{world,states}:
      do IO<Unit>:
        log : Chan<C.Bq.String> <- Chan.new(C.Bq.String,128)
        adapter_connections(label,world,states,cid,log)

@unsafe
def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- adapter("server disconnect empty",K.Creation.Result{Fixture.sample(Nil{},Nil{}),Nil{}},1)
    Unit <- adapter("server disconnect missing CID exact no-op",K.Creation.Result{Fixture.sample([F.player(7,1,"Ada")],[Fixture.mob(1,7)]),[SS.state(1,2,7,"Ada")]},99)
    Unit <- adapter("server disconnect fresh connection only",K.Creation.Result{Fixture.sample(Nil{},[Fixture.mob(1,0)]),[SS.state(4,0,0,"")]},4)
    Unit <- adapter("server disconnect identified connection only",K.Creation.Result{Fixture.sample(Nil{},[Fixture.mob(1,0)]),[SS.state(4,1,0,"Dee")]},4)
    Unit <- adapter("server disconnect waiting retains existing player",K.Creation.Result{Fixture.sample([F.player(7,1,"Ada")],[Fixture.mob(1,7)]),[SS.state(1,2,7,"Ada"),SS.state(4,1,0,"Dee")]},4)
    Unit <- adapter("server disconnect fresh retains existing player",K.Creation.Result{Fixture.sample([F.player(7,1,"Ada")],[Fixture.mob(1,7)]),[SS.state(4,0,0,""),SS.state(1,2,7,"Ada")]},4)
    Unit <- adapter("server disconnect only bound player",K.Creation.Result{Fixture.sample([F.player(7,1,"Ada")],[Fixture.mob(1,7)]),[SS.state(1,2,7,"Ada")]},1)
    Unit <- adapter("server disconnect first player",K.Creation.Result{Fixture.sample([F.player(7,1,"Ada"),F.player(8,2,"Bob"),F.player(9,3,"Cy")],[Fixture.mob(1,7),Fixture.mob(2,8),Fixture.mob(3,9)]),[SS.state(1,2,7,"Ada"),SS.state(2,2,8,"Bob"),SS.state(3,2,9,"Cy")]},1)
    Unit <- adapter("server disconnect middle player",K.Creation.Result{Fixture.sample([F.player(7,1,"Ada"),F.player(8,2,"Bob"),F.player(9,3,"Cy")],[Fixture.mob(1,7),Fixture.mob(2,8),Fixture.mob(3,9)]),[SS.state(1,2,7,"Ada"),SS.state(2,2,8,"Bob"),SS.state(3,2,9,"Cy")]},2)
    Unit <- adapter("server disconnect last player",K.Creation.Result{Fixture.sample([F.player(7,1,"Ada"),F.player(8,2,"Bob"),F.player(9,3,"Cy")],[Fixture.mob(1,7),Fixture.mob(2,8),Fixture.mob(3,9)]),[SS.state(1,2,7,"Ada"),SS.state(2,2,8,"Bob"),SS.state(3,2,9,"Cy")]},3)
    Unit <- adapter("server disconnect independent roster order",K.Creation.Result{Fixture.sample([F.player(7,1,"Ada"),F.player(8,2,"Bob"),F.player(9,3,"Cy")],[Fixture.mob(1,8)]),[SS.state(3,2,9,"Cy"),SS.state(2,2,8,"Bob"),SS.state(1,2,7,"Ada")]},2)
    Unit <- adapter("server disconnect mixed waiting and bound",K.Creation.Result{Fixture.sample([F.player(7,1,"Ada"),F.player(8,2,"Bob")],[Fixture.mob(1,7),Fixture.mob(2,8)]),[SS.state(4,1,0,"Dee"),SS.state(2,2,8,"Bob"),SS.state(5,0,0,""),SS.state(1,2,7,"Ada")]},1)
    Unit <- adapter("server disconnect multiple monster targets cleared",K.Creation.Result{Fixture.sample([F.player(7,1,"Ada"),F.player(8,2,"Bob")],[Fixture.mob(1,7),Fixture.mob(2,7),Fixture.mob(3,8),Fixture.mob(4,0)]),[SS.state(1,2,7,"Ada"),SS.state(2,2,8,"Bob")]},1)
    Unit <- adapter("server disconnect zero CID missing",K.Creation.Result{Fixture.sample([F.player(7,1,"Ada")],[Fixture.mob(1,7)]),[SS.state(1,2,7,"Ada")]},0)
    Unit <- adapter("server disconnect MAX PID and CID",K.Creation.Result{Fixture.sample([F.player(4294967295,4294967295,"Max")],[Fixture.mob(1,4294967295)]),[SS.state(4294967295,2,4294967295,"Max")]},4294967295)
    Unit <- adapter("server disconnect UTF8 identity",K.Creation.Result{Fixture.sample([F.player(7,1,"Étoile"),F.player(8,2,"Bob")],[Fixture.mob(1,7),Fixture.mob(2,8)]),[SS.state(1,2,7,"Étoile"),SS.state(2,2,8,"Bob")]},1)
    adapter("server disconnect other target and counters unchanged",K.Creation.Result{Fixture.sample([F.player(7,1,"Ada"),F.player(8,2,"Bob")],[Fixture.mob(1,8)]),[SS.state(1,2,7,"Ada"),SS.state(2,2,8,"Bob")]},1)

#| PASS server disconnect empty
#| PASS server disconnect missing CID exact no-op
#| PASS server disconnect fresh connection only
#| PASS server disconnect identified connection only
#| PASS server disconnect waiting retains existing player
#| PASS server disconnect fresh retains existing player
#| PASS server disconnect only bound player
#| PASS server disconnect first player
#| PASS server disconnect middle player
#| PASS server disconnect last player
#| PASS server disconnect independent roster order
#| PASS server disconnect mixed waiting and bound
#| PASS server disconnect multiple monster targets cleared
#| PASS server disconnect zero CID missing
#| PASS server disconnect MAX PID and CID
#| PASS server disconnect UTF8 identity
#| PASS server disconnect other target and counters unchanged
