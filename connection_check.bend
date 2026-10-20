import Base
import ./main.bend as Application
import ./connection.bend as C
import ./sessions.bend as S
import ./players.bend as P
import ./sessions_check.bend as SS
import ./creation_check.bend as F
import ./players_check.bend as Test
import ./server.bend as Live

def same(a: C.Connection.Record,b: C.Connection.Record) -> Bool:
  match a:
    case C.Connection.Record{cid,phase,pid,out,name}:
      match b:
        case C.Connection.Record{other_cid,other_phase,other_pid,other_out,other_name}: Bool.and(U32.is_eq(cid,other_cid),Bool.and(U32.is_eq(phase,other_phase),Bool.and(U32.is_eq(pid,other_pid),S.Sessions.name_eq(P.Players.share_name(name),P.Players.share_name(other_name)))))

def same_list(a: List<&1,C.Connection.Record>,b: List<&1,C.Connection.Record>) -> Bool:
  match a:
    case Nil{}:
      match b:
        case Nil{}: True{}
        case Con{head,rest}: False{}
    case Con{head,rest}:
      match b:
        case Nil{}: False{}
        case Con{other,later}: Bool.and(same(head,other),same_list(rest,later))

# A channel is an opaque handle: the checks share two real ones made in main
# and a record's channel is not compared, only carried.
def record(cid: U32,phase: U32,pid: U32,name: String,+out: Chan(List<&1,Char>)) -> C.Connection.Record: C.Connection.from_descriptor(SS.state(cid,phase,pid,name),out)

@unsafe
def roundtrip(label: String,+state: S.Sessions.State,+out: Chan(List<&1,Char>)) -> IO(Unit): Test.verdict(label,Bool.and(SS.same(C.Connection.descriptor(C.Connection.from_descriptor(state,out)),state),same(Live.Bq.connection_from_descriptor(state,out),C.Connection.from_descriptor(state,out))))

@unsafe
def checked(label: String,+connections: List<&1,C.Connection.Record>,+players: List<&2,P.Players.State>,+expected: List<&1,C.Connection.Record>) -> IO(Unit): Test.verdict(label,Bool.and(same_list(C.Connection.rebind(connections,players),expected),same_list(Live.Bq.rebind_conns(connections,players),expected)))

@unsafe
def main() -> IO(Unit):
  do IO<Unit>:
    +c : Chan(List<&1,Char>) <- Chan.new(List<&1,Char>, 1)
    +d : Chan(List<&1,Char>) <- Chan.new(List<&1,Char>, 1)
    Unit <- roundtrip("channel descriptor fresh",SS.state(1,0,0,""),c)
    Unit <- roundtrip("channel descriptor waiting Unicode",SS.state(1,1,0,"Étoile猫"),c)
    Unit <- roundtrip("channel descriptor playing",SS.state(1,2,7,"Ada"),c)
    Unit <- roundtrip("channel descriptor MAX",SS.state(4294967295,4294967295,4294967295,"Max"),d)
    Unit <- checked("channel rebind empty",Nil{},Nil{},Nil{})
    Unit <- checked("channel rebind fresh retained",[record(3,0,0,"",c)],[F.player(71,1,"Ada")],[record(3,0,0,"",c)])
    Unit <- checked("channel rebind waiting retained",[record(3,1,0,"Cy",c)],[F.player(71,1,"Ada")],[record(3,1,0,"Cy",c)])
    Unit <- checked("channel rebind playing retains handle",[record(1,2,7,"Ada",c)],[F.player(71,1,"Ada")],[record(1,2,71,"Ada",c)])
    Unit <- checked("channel rebind opposite roster orders",[record(1,2,7,"Ada",c),record(2,2,8,"Bob",d)],[F.player(82,2,"Bob"),F.player(71,1,"Ada")],[record(1,2,71,"Ada",c),record(2,2,82,"Bob",d)])
    Unit <- checked("channel rebind equal slots distinct generations",[record(1,2,7,"Ada",c),record(2,2,8,"Bob",d)],[F.player(82,2,"Bob"),F.player(71,1,"Ada")],[record(1,2,71,"Ada",c),record(2,2,82,"Bob",d)])
    Unit <- checked("channel rebind Unicode raw name",[record(1,2,7,"Étoile猫",c)],[F.player(71,1,"Étoile猫")],[record(1,2,71,"Étoile猫",c)])
    Unit <- checked("channel rebind MAX IDs and handle",[record(4294967295,2,7,"Max",d)],[F.player(4294967295,4294967295,"Max")],[record(4294967295,2,4294967295,"Max",d)])
    Unit <- checked("channel rebind missing keeps PID",[record(1,2,7,"Ada",c)],Nil{},[record(1,2,7,"Ada",c)])
    Unit <- checked("channel rebind duplicate takes first",[record(1,2,7,"Ada",c)],[F.player(71,1,"Ada"),F.player(82,1,"Bob")],[record(1,2,71,"Ada",c)])
    checked("channel rebind retains original phase and name",[record(1,4294967295,7,"Ada",c)],[F.player(71,1,"Bob")],[record(1,4294967295,71,"Ada",c)])

#| PASS channel descriptor fresh
#| PASS channel descriptor waiting Unicode
#| PASS channel descriptor playing
#| PASS channel descriptor MAX
#| PASS channel rebind empty
#| PASS channel rebind fresh retained
#| PASS channel rebind waiting retained
#| PASS channel rebind playing retains handle
#| PASS channel rebind opposite roster orders
#| PASS channel rebind equal slots distinct generations
#| PASS channel rebind Unicode raw name
#| PASS channel rebind MAX IDs and handle
#| PASS channel rebind missing keeps PID
#| PASS channel rebind duplicate takes first
#| PASS channel rebind retains original phase and name
