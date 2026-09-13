import Base
import ./connection.bend as Net
import ./selection.bend as Q
import ./sessions.bend as S
import ./sessions_check.bend as ST
import ./players_check.bend as Test
import ./players.bend as P
import ./compat.bend as C
import ./server.bend as Server

def same_states(left: List<&2,S.Sessions.State>,right: List<&2,S.Sessions.State>) -> Bool:
  match left:
    case Nil{}:
      match right:
        case Nil{}: True{}
        case Con{head,rest}: False{}
    case Con{head,rest}:
      match right:
        case Nil{}: False{}
        case Con{other,later}: Bool.and(ST.same(head,other),same_states(rest,later))

def same_found(left: Maybe<&2,S.Sessions.State>,right: Maybe<&2,S.Sessions.State>) -> Bool:
  match left:
    case None{}:
      match right:
        case None{}: True{}
        case Some{head}: False{}
    case Some{head}:
      match right:
        case None{}: False{}
        case Some{other}: ST.same(head,other)

def same_taken(left: Q.Selection.Take,right: Q.Selection.Take) -> Bool:
  match left:
    case Q.Selection.Take{others,found}:
      match right:
        case Q.Selection.Take{rest,selected}: Bool.and(same_states(others,rest),same_found(found,selected))

def checked(label: String,states: List<&2,S.Sessions.State>,cid: U32,others: List<&2,S.Sessions.State>,found: Maybe<&2,S.Sessions.State>) -> IO(Unit): Test.verdict(label,same_taken(Q.Selection.take(states,cid),Q.Selection.Take{others,found}))

# The channel-bearing legacy adapter is exercised separately from the safe laws.
@unsafe
def connection_out(+state: S.Sessions.State,+out: Chan<C.Bq.String>) -> IO(Server.Bq.Conn):
  do IO<Server.Bq.Conn>:
    sent : Bool <- Chan.send(C.Bq.String,out,P.Players.text_name(S.Sessions.name(state)))
    IO.pure(Server.Bq.Conn,Server.Bq.connection_from_descriptor(state,out))

@unsafe
def connection(state: S.Sessions.State) -> IO(Server.Bq.Conn):
  do IO<Server.Bq.Conn>:
    out : Chan<C.Bq.String> <- Chan.new(C.Bq.String,1)
    connection_out(state,out)

@unsafe
def connections(states: List<&2,S.Sessions.State>) -> IO(List<&1,Server.Bq.Conn>):
  match states:
    case Nil{}: IO.pure(List<&1,Server.Bq.Conn>,Nil{})
    case Con{head,rest}:
      do IO<List<&1,Server.Bq.Conn>>:
        first : Server.Bq.Conn <- connection(head)
        later : List<&1,Server.Bq.Conn> <- connections(rest)
        IO.pure(List<&1,Server.Bq.Conn>,Con{first,later})

@unsafe
def found_descriptor(found: Result<&1,&1,Unit,Server.Bq.Conn>) -> Maybe<&2,S.Sessions.State>:
  match found:
    case Fail{unit}: None{}
    case Done{connection}: Some{Server.Bq.session_descriptor(connection)}

@unsafe
def project(taken: Sigma<&1,&1,List<&1,Server.Bq.Conn>,(others => Result<&1,&1,Unit,Server.Bq.Conn>)>) -> Q.Selection.Take:
  match taken:
    case Tuple{others,found}: Q.Selection.Take{Server.Bq.session_descriptors(others),found_descriptor(found)}

@unsafe
def restore(taken: Sigma<&1,&1,List<&1,Server.Bq.Conn>,(others => Result<&1,&1,Unit,Server.Bq.Conn>)>) -> List<&1,Server.Bq.Conn>:
  match taken:
    case Tuple{others,found}:
      match found:
        case Fail{unit}: others
        case Done{head}: Con{head,others}

@unsafe
def message_matches(message: Maybe<&1,C.Bq.String>,expected: C.Bq.String) -> Bool:
  match message:
    case None{}: False{}
    case Some{actual}: S.Sessions.name_eq(P.Players.share_name(actual),P.Players.share_name(expected))

@unsafe
def channel_matches(connection: Server.Bq.Conn) -> IO(Bool):
  match connection:
    case Net.Connection.Record{cid,phase,pid,out,name}:
      +out = out
      do IO<Bool>:
        message : Maybe<&1,C.Bq.String> <- Chan.recv(C.Bq.String,out)
        Unit <- Chan.close(C.Bq.String,out)
        IO.pure(Bool,message_matches(message,name))

@unsafe
def channels_match(connections: List<&1,Server.Bq.Conn>) -> IO(Bool):
  match connections:
    case Nil{}: IO.pure(Bool,True{})
    case Con{head,rest}:
      do IO<Bool>:
        first : Bool <- channel_matches(head)
        later : Bool <- channels_match(rest)
        IO.pure(Bool,Bool.and(first,later))

@unsafe
def adapter_taken(label: String,states: List<&2,S.Sessions.State>,cid: U32,+taken: Sigma<&1,&1,List<&1,Server.Bq.Conn>,(others => Result<&1,&1,Unit,Server.Bq.Conn>)>) -> IO(Unit):
  +same = same_taken(project(taken),Q.Selection.take(states,cid))
  do IO<Unit>:
    channels : Bool <- channels_match(restore(taken))
    Test.verdict(label,Bool.and(same,channels))

@unsafe
def adapter(label: String,+states: List<&2,S.Sessions.State>,+cid: U32) -> IO(Unit):
  do IO<Unit>:
    actual : List<&1,Server.Bq.Conn> <- connections(states)
    adapter_taken(label,states,cid,Server.Bq.take_conn(cid,actual))

@unsafe
def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- checked("select empty",Nil{},1,Nil{},None{})
    Unit <- checked("select singleton hit",[ST.state(1,0,0,"fresh")],1,Nil{},Some{ST.state(1,0,0,"fresh")})
    Unit <- checked("select singleton miss",[ST.state(1,0,0,"fresh")],2,[ST.state(1,0,0,"fresh")],None{})
    Unit <- checked("select first",[ST.state(1,0,0,"fresh"),ST.state(2,1,0,"Étoile"),ST.state(3,2,17,"playing")],1,[ST.state(2,1,0,"Étoile"),ST.state(3,2,17,"playing")],Some{ST.state(1,0,0,"fresh")})
    Unit <- checked("select middle",[ST.state(1,0,0,"fresh"),ST.state(2,1,0,"Étoile"),ST.state(3,2,17,"playing")],2,[ST.state(1,0,0,"fresh"),ST.state(3,2,17,"playing")],Some{ST.state(2,1,0,"Étoile")})
    Unit <- checked("select last",[ST.state(1,0,0,"fresh"),ST.state(2,1,0,"Étoile"),ST.state(3,2,17,"playing")],3,[ST.state(1,0,0,"fresh"),ST.state(2,1,0,"Étoile")],Some{ST.state(3,2,17,"playing")})
    Unit <- checked("select missing",[ST.state(1,0,0,"fresh"),ST.state(2,1,0,"Étoile"),ST.state(3,2,17,"playing")],4,[ST.state(1,0,0,"fresh"),ST.state(2,1,0,"Étoile"),ST.state(3,2,17,"playing")],None{})
    Unit <- checked("select zero absent",[ST.state(1,0,0,"fresh"),ST.state(2,1,0,"Étoile"),ST.state(3,2,17,"playing")],0,[ST.state(1,0,0,"fresh"),ST.state(2,1,0,"Étoile"),ST.state(3,2,17,"playing")],None{})
    Unit <- checked("select MAX absent",[ST.state(1,0,0,"fresh"),ST.state(2,1,0,"Étoile"),ST.state(3,2,17,"playing")],4294967295,[ST.state(1,0,0,"fresh"),ST.state(2,1,0,"Étoile"),ST.state(3,2,17,"playing")],None{})
    Unit <- checked("select zero present",[ST.state(1,0,0,"fresh"),ST.state(0,0,0,"zero"),ST.state(3,2,17,"playing")],0,[ST.state(1,0,0,"fresh"),ST.state(3,2,17,"playing")],Some{ST.state(0,0,0,"zero")})
    Unit <- checked("select MAX present",[ST.state(1,0,0,"fresh"),ST.state(4294967295,2,4294967295,"maximum"),ST.state(3,2,17,"playing")],4294967295,[ST.state(1,0,0,"fresh"),ST.state(3,2,17,"playing")],Some{ST.state(4294967295,2,4294967295,"maximum")})
    Unit <- checked("select duplicate first",[ST.state(1,0,0,"fresh"),ST.state(2,1,0,"Étoile"),ST.state(2,2,18,"duplicate"),ST.state(3,2,17,"playing")],2,[ST.state(1,0,0,"fresh"),ST.state(2,2,18,"duplicate"),ST.state(3,2,17,"playing")],Some{ST.state(2,1,0,"Étoile")})
    Unit <- checked("select duplicate reversed",[ST.state(1,0,0,"fresh"),ST.state(2,2,18,"duplicate"),ST.state(2,1,0,"Étoile"),ST.state(3,2,17,"playing")],2,[ST.state(1,0,0,"fresh"),ST.state(2,1,0,"Étoile"),ST.state(3,2,17,"playing")],Some{ST.state(2,2,18,"duplicate")})
    Unit <- checked("select duplicate head",[ST.state(2,1,0,"Étoile"),ST.state(2,2,18,"duplicate"),ST.state(1,0,0,"fresh")],2,[ST.state(2,2,18,"duplicate"),ST.state(1,0,0,"fresh")],Some{ST.state(2,1,0,"Étoile")})
    Unit <- checked("select payload retained",[ST.state(4294967295,2,4294967295,"maximum"),ST.state(0,0,0,"zero"),ST.state(2,2,18,"duplicate"),ST.state(2,1,0,"Étoile"),ST.state(3,2,17,"playing"),ST.state(1,0,0,"fresh")],3,[ST.state(4294967295,2,4294967295,"maximum"),ST.state(0,0,0,"zero"),ST.state(2,2,18,"duplicate"),ST.state(2,1,0,"Étoile"),ST.state(1,0,0,"fresh")],Some{ST.state(3,2,17,"playing")})
    Unit <- Test.verdict("selected HELLO missing CID no-op",same_states(Q.Selection.hello([ST.state(1,0,0,"fresh"),ST.state(2,1,0,"Étoile"),ST.state(3,2,17,"playing")],7,ST.name("Ada")),[ST.state(1,0,0,"fresh"),ST.state(2,1,0,"Étoile"),ST.state(3,2,17,"playing")]))
    Unit <- Test.verdict("selected HELLO late playing stays bound",same_states(Q.Selection.hello([ST.state(1,0,0,"fresh"),ST.state(2,1,0,"Étoile"),ST.state(3,2,17,"playing")],3,ST.name("renamed")),[ST.state(3,2,17,"playing"),ST.state(1,0,0,"fresh"),ST.state(2,1,0,"Étoile")]))
    Unit <- Test.verdict("selected HELLO middle pre-create rename",same_states(Q.Selection.hello([ST.state(1,0,0,"fresh"),ST.state(2,1,0,"Étoile"),ST.state(3,2,17,"playing")],2,ST.name("Ada")),[ST.state(2,1,0,"Ada"),ST.state(1,0,0,"fresh"),ST.state(3,2,17,"playing")]))
    Unit <- Test.verdict("selected HELLO online collision retains descriptor",same_states(Q.Selection.hello([ST.state(1,0,0,"fresh"),ST.state(2,1,0,"Étoile"),ST.state(3,2,17,"playing")],1,ST.name("Étoile")),[ST.state(1,0,0,"fresh"),ST.state(2,1,0,"Étoile"),ST.state(3,2,17,"playing")]))
    Unit <- Test.verdict("selected HELLO later reservation checked",same_states(Q.Selection.hello([ST.state(1,0,0,"fresh"),ST.state(3,2,17,"playing"),ST.state(2,1,0,"Étoile")],1,ST.name("Étoile")),[ST.state(1,0,0,"fresh"),ST.state(3,2,17,"playing"),ST.state(2,1,0,"Étoile")]))
    Unit <- Test.verdict("selected HELLO empty rejected after reordering",same_states(Q.Selection.hello([ST.state(1,0,0,"fresh"),ST.state(2,1,0,"Étoile"),ST.state(3,2,17,"playing")],2,ST.name("")),[ST.state(2,1,0,"Étoile"),ST.state(1,0,0,"fresh"),ST.state(3,2,17,"playing")]))
    Unit <- Test.verdict("selected HELLO UTF8 selected profile",same_states(Q.Selection.hello([ST.state(1,0,0,"fresh"),ST.state(2,1,0,"Étoile"),ST.state(3,2,17,"playing")],1,ST.name("été")),[ST.state(1,1,0,"été"),ST.state(2,1,0,"Étoile"),ST.state(3,2,17,"playing")]))
    Unit <- Test.verdict("selected HELLO MAX binding locked",same_states(Q.Selection.hello([ST.state(1,0,0,"fresh"),ST.state(4294967295,2,4294967295,"maximum"),ST.state(2,1,0,"Étoile")],4294967295,ST.name("Bob")),[ST.state(4294967295,2,4294967295,"maximum"),ST.state(1,0,0,"fresh"),ST.state(2,1,0,"Étoile")]))
    Unit <- adapter("legacy descriptor/channel empty",Nil{},1)
    Unit <- adapter("legacy descriptor/channel singleton hit",[ST.state(1,0,0,"fresh")],1)
    Unit <- adapter("legacy descriptor/channel singleton miss",[ST.state(1,0,0,"fresh")],2)
    Unit <- adapter("legacy descriptor/channel first",[ST.state(1,0,0,"fresh"),ST.state(2,1,0,"Étoile"),ST.state(3,2,17,"playing")],1)
    Unit <- adapter("legacy descriptor/channel middle",[ST.state(1,0,0,"fresh"),ST.state(2,1,0,"Étoile"),ST.state(3,2,17,"playing")],2)
    Unit <- adapter("legacy descriptor/channel last",[ST.state(1,0,0,"fresh"),ST.state(2,1,0,"Étoile"),ST.state(3,2,17,"playing")],3)
    Unit <- adapter("legacy descriptor/channel missing",[ST.state(1,0,0,"fresh"),ST.state(2,1,0,"Étoile"),ST.state(3,2,17,"playing")],4)
    Unit <- adapter("legacy descriptor/channel zero absent",[ST.state(1,0,0,"fresh"),ST.state(2,1,0,"Étoile"),ST.state(3,2,17,"playing")],0)
    Unit <- adapter("legacy descriptor/channel MAX absent",[ST.state(1,0,0,"fresh"),ST.state(2,1,0,"Étoile"),ST.state(3,2,17,"playing")],4294967295)
    Unit <- adapter("legacy descriptor/channel zero present",[ST.state(1,0,0,"fresh"),ST.state(0,0,0,"zero"),ST.state(3,2,17,"playing")],0)
    Unit <- adapter("legacy descriptor/channel MAX present",[ST.state(1,0,0,"fresh"),ST.state(4294967295,2,4294967295,"maximum"),ST.state(3,2,17,"playing")],4294967295)
    Unit <- adapter("legacy descriptor/channel duplicate first",[ST.state(1,0,0,"fresh"),ST.state(2,1,0,"Étoile"),ST.state(2,2,18,"duplicate"),ST.state(3,2,17,"playing")],2)
    Unit <- adapter("legacy descriptor/channel duplicate reversed",[ST.state(1,0,0,"fresh"),ST.state(2,2,18,"duplicate"),ST.state(2,1,0,"Étoile"),ST.state(3,2,17,"playing")],2)
    Unit <- adapter("legacy descriptor/channel duplicate head",[ST.state(2,1,0,"Étoile"),ST.state(2,2,18,"duplicate"),ST.state(1,0,0,"fresh")],2)
    adapter("legacy descriptor/channel payload retained",[ST.state(4294967295,2,4294967295,"maximum"),ST.state(0,0,0,"zero"),ST.state(2,2,18,"duplicate"),ST.state(2,1,0,"Étoile"),ST.state(3,2,17,"playing"),ST.state(1,0,0,"fresh")],3)

#| PASS select empty
#| PASS select singleton hit
#| PASS select singleton miss
#| PASS select first
#| PASS select middle
#| PASS select last
#| PASS select missing
#| PASS select zero absent
#| PASS select MAX absent
#| PASS select zero present
#| PASS select MAX present
#| PASS select duplicate first
#| PASS select duplicate reversed
#| PASS select duplicate head
#| PASS select payload retained
#| PASS selected HELLO missing CID no-op
#| PASS selected HELLO late playing stays bound
#| PASS selected HELLO middle pre-create rename
#| PASS selected HELLO online collision retains descriptor
#| PASS selected HELLO later reservation checked
#| PASS selected HELLO empty rejected after reordering
#| PASS selected HELLO UTF8 selected profile
#| PASS selected HELLO MAX binding locked
#| PASS legacy descriptor/channel empty
#| PASS legacy descriptor/channel singleton hit
#| PASS legacy descriptor/channel singleton miss
#| PASS legacy descriptor/channel first
#| PASS legacy descriptor/channel middle
#| PASS legacy descriptor/channel last
#| PASS legacy descriptor/channel missing
#| PASS legacy descriptor/channel zero absent
#| PASS legacy descriptor/channel MAX absent
#| PASS legacy descriptor/channel zero present
#| PASS legacy descriptor/channel MAX present
#| PASS legacy descriptor/channel duplicate first
#| PASS legacy descriptor/channel duplicate reversed
#| PASS legacy descriptor/channel duplicate head
#| PASS legacy descriptor/channel payload retained
