import Base
import ./connection.bend as Net
# Retain the full native effect registry; only this file's main is executed.
import ./main.bend as Application
import ./creation.bend as K
import ./sessions.bend as S
import ./sessions_check.bend as SS
import ./players.bend as P
import ./players_check.bend as Test
import ./simulation.bend as Sim
import ./simulation_check.bend as ST
import ./terrain.bend as T
import ./landscape.bend as L
import ./admission.bend as J
import ./server.bend as Server
import ./compat.bend as C

import ./creation_check.bend as Fixture
# Exercise actual on_create, including its profile/cosmetic gate and channels.
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
def connections(states: List<&2,S.Sessions.State>) -> IO(List<&1,Server.Bq.Conn>):
  match states:
    case Nil{}: IO.pure(List<&1,Server.Bq.Conn>,Nil{})
    case Con{head,rest}:
      do IO<List<&1,Server.Bq.Conn>>:
        first : Server.Bq.Conn <- make_connection(head)
        later : List<&1,Server.Bq.Conn> <- connections(rest)
        IO.pure(List<&1,Server.Bq.Conn>,Con{first,later})

@unsafe
def marker_matches(message: Maybe<&1,C.Bq.String>,expected: C.Bq.String) -> Bool:
  match message:
    case None{}: False{}
    case Some{actual}: S.Sessions.name_eq(P.Players.share_name(actual),P.Players.share_name(expected))

@unsafe
def check_connection(connection: Server.Bq.Conn) -> IO(Bool):
  match connection:
    case Net.Connection.Record{cid,phase,pid,out,name}:
      +out = out
      do IO<Bool>:
        message : Maybe<&1,C.Bq.String> <- Chan.recv(C.Bq.String,out)
        Unit <- Chan.close(C.Bq.String,out)
        IO.pure(Bool,marker_matches(message,name))

@unsafe
def check_connections(connections: List<&1,Server.Bq.Conn>) -> IO(Bool):
  match connections:
    case Nil{}: IO.pure(Bool,True{})
    case Con{head,rest}:
      do IO<Bool>:
        first : Bool <- check_connection(head)
        later : Bool <- check_connections(rest)
        IO.pure(Bool,Bool.and(first,later))

@unsafe
def adapter_result(label: String,result: T.Terrain.World & List<&1,Server.Bq.Conn>,expected: K.Creation.Result) -> IO(Unit):
  match result:
    case Tuple{world,states}:
      +world = world
      +states = states
      +matches = Bool.and(Fixture.same(K.Creation.Result{T.Terrain.simulation(world),Server.Bq.session_descriptors(states)},expected),Fixture.same_maps(T.Terrain.maps(world),L.Landscape.maps(0)))
      do IO<Unit>:
        channels : Bool <- check_connections(states)
        Test.verdict(label,Bool.and(matches,channels))

@unsafe
def adapter_run(label: String,+before: Sim.Simulation.State,+states: List<&2,S.Sessions.State>,+cid: U32,numbers: List<&1,U32>,expected_style: P.Players.Style,permitted: Bool,+log: Chan<C.Bq.String>) -> IO(Unit):
  do IO<Unit>:
    actual : List<&1,Server.Bq.Conn> <- connections(states)
    result : T.Terrain.World & List<&1,Server.Bq.Conn> <- Server.Bq.on_create(T.Terrain.world(L.Landscape.maps(0),before),actual,Server.Bq.Db.Db{7,Nil{},Nil{}},cid,numbers,log)
    Unit <- Chan.close(C.Bq.String,log)
    adapter_result(label,result,K.Creation.create(before,states,cid,expected_style,permitted))

@unsafe
def adapter(label: String,before: K.Creation.Result,cid: U32,numbers: List<&1,U32>,expected_style: P.Players.Style,permitted: Bool) -> IO(Unit):
  match before:
    case K.Creation.Result{world,states}:
      do IO<Unit>:
        log : Chan<C.Bq.String> <- Chan.new(C.Bq.String,128)
        adapter_run(label,world,states,cid,numbers,expected_style,permitted,log)

@unsafe
def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- adapter("server CREATE empty roster",K.Creation.Result{Fixture.world(1,Nil{}),Nil{}},1,[1,2,3,4,0,0],Fixture.style,True{})
    Unit <- adapter("server CREATE before HELLO",K.Creation.Result{Fixture.world(1,Nil{}),[SS.state(1,0,0,"")]},1,[1,2,3,4,0,0],Fixture.style,True{})
    Unit <- adapter("server CREATE create player and binding",K.Creation.Result{Fixture.world(1,Nil{}),[SS.state(1,1,0,"Ada")]},1,[1,2,3,4,0,0],Fixture.style,True{})
    Unit <- adapter("server CREATE zero hint normalized",K.Creation.Result{Fixture.world(0,Nil{}),[SS.state(1,1,0,"Ada")]},1,[1,2,3,4,0,0],Fixture.style,True{})
    Unit <- adapter("server CREATE MAX player ID wraps cursor",K.Creation.Result{Fixture.world(4294967295,Nil{}),[SS.state(1,1,0,"Ada")]},1,[1,2,3,4,0,0],Fixture.style,True{})
    Unit <- adapter("server CREATE MAX connection ID",K.Creation.Result{Fixture.world(1,Nil{}),[SS.state(4294967295,1,0,"Ada")]},4294967295,[1,2,3,4,0,0],Fixture.style,True{})
    Unit <- adapter("server CREATE existing players retained",K.Creation.Result{Fixture.world(1,[Fixture.player(7,3,"Cy")]),[SS.state(3,2,7,"Cy"),SS.state(1,1,0,"Ada")]},1,[1,2,3,4,0,0],Fixture.style,True{})
    Unit <- adapter("server CREATE selection after waiting connection",K.Creation.Result{Fixture.world(1,Nil{}),[SS.state(2,1,0,"Bob"),SS.state(1,1,0,"Ada")]},1,[1,2,3,4,0,0],Fixture.style,True{})
    Unit <- adapter("server CREATE selection among waiting and playing",K.Creation.Result{Fixture.world(1,[Fixture.player(7,3,"Cy")]),[SS.state(2,1,0,"Bob"),SS.state(3,2,7,"Cy"),SS.state(1,1,0,"Ada")]},1,[1,2,3,4,0,0],Fixture.style,True{})
    Unit <- adapter("server CREATE repeated CREATE rejected",K.Creation.Result{Fixture.world(2,[Fixture.player(1,1,"Ada")]),[SS.state(1,2,1,"Ada")]},1,[1,2,3,4,0,0],Fixture.style,True{})
    Unit <- adapter("server CREATE repeated CREATE moves selected only",K.Creation.Result{Fixture.world(2,[Fixture.player(1,1,"Ada")]),[SS.state(2,1,0,"Bob"),SS.state(1,2,1,"Ada")]},1,[1,2,3,4,0,0],Fixture.style,True{})
    Unit <- adapter("server CREATE missing CID unchanged",K.Creation.Result{Fixture.world(1,[Fixture.player(7,3,"Cy")]),[SS.state(2,1,0,"Bob"),SS.state(3,2,7,"Cy"),SS.state(1,1,0,"Ada")]},99,[1,2,3,4,0,0],Fixture.style,True{})
    Unit <- adapter("server CREATE UTF8 identity retained",K.Creation.Result{Fixture.world(1,Nil{}),[SS.state(1,1,0,"Étoile")]},1,[1,2,3,4,0,0],Fixture.style,True{})
    Unit <- adapter("server CREATE occupied PID skipped",K.Creation.Result{Fixture.world(1,[Fixture.player(1,1,"Ada")]),[SS.state(1,2,1,"Ada"),SS.state(2,1,0,"Bob")]},2,[1,2,3,4,0,0],Fixture.style,True{})
    Unit <- adapter("server CREATE rejects unowned hat",K.Creation.Result{Fixture.world(1,Nil{}),[SS.state(1,1,0,"Ada")]},1,[1,2,3,4,1,0],P.Players.Style{1,2,3,4,1,0},False{})
    Unit <- adapter("server CREATE rejects unowned cape",K.Creation.Result{Fixture.world(1,Nil{}),[SS.state(1,1,0,"Ada")]},1,[1,2,3,4,0,1],P.Players.Style{1,2,3,4,0,1},False{})
    adapter("server CREATE normalizes appearance",K.Creation.Result{Fixture.world(1,Nil{}),[SS.state(1,1,0,"Ada")]},1,[7,4,8,11,0,0],Fixture.other_style,True{})

#| PASS server CREATE empty roster
#| PASS server CREATE before HELLO
#| PASS server CREATE create player and binding
#| PASS server CREATE zero hint normalized
#| PASS server CREATE MAX player ID wraps cursor
#| PASS server CREATE MAX connection ID
#| PASS server CREATE existing players retained
#| PASS server CREATE selection after waiting connection
#| PASS server CREATE selection among waiting and playing
#| PASS server CREATE repeated CREATE rejected
#| PASS server CREATE repeated CREATE moves selected only
#| PASS server CREATE missing CID unchanged
#| PASS server CREATE UTF8 identity retained
#| PASS server CREATE occupied PID skipped
#| PASS server CREATE rejects unowned hat
#| PASS server CREATE rejects unowned cape
#| PASS server CREATE normalizes appearance
