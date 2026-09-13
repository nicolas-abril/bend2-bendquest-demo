import Base
import ./main.bend as Application
import ./connection.bend as C
import ./sessions.bend as S
import ./players.bend as P
import ./sessions_check.bend as SS
import ./creation_check.bend as F
import ./players_check.bend as Test
import ./server.bend as Live

def channel_eq(a: Chan<List<&1,Char>>,b: Chan<List<&1,Char>>) -> Bool:
  match a:
    case Chan{slot,gen}:
      match b:
        case Chan{other,other_gen}: Bool.and(U32.is_eq(slot,other),U32.is_eq(gen,other_gen))

def same(a: C.Connection.Record,b: C.Connection.Record) -> Bool:
  match a:
    case C.Connection.Record{cid,phase,pid,out,name}:
      match b:
        case C.Connection.Record{other_cid,other_phase,other_pid,other_out,other_name}: Bool.and(U32.is_eq(cid,other_cid),Bool.and(U32.is_eq(phase,other_phase),Bool.and(U32.is_eq(pid,other_pid),Bool.and(channel_eq(out,other_out),S.Sessions.name_eq(P.Players.share_name(name),P.Players.share_name(other_name))))))

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

# Synthetic handles are only compared as data; no channel effects use them.
def record(cid: U32,phase: U32,pid: U32,name: String,slot: U32,gen: U32) -> C.Connection.Record: C.Connection.from_descriptor(SS.state(cid,phase,pid,name),Chan{slot,gen})

@unsafe
def roundtrip(label: String,+state: S.Sessions.State,+out: Chan<List<&1,Char>>) -> IO(Unit): Test.verdict(label,Bool.and(SS.same(C.Connection.descriptor(C.Connection.from_descriptor(state,out)),state),same(Live.Bq.connection_from_descriptor(state,out),C.Connection.from_descriptor(state,out))))

@unsafe
def checked(label: String,+connections: List<&1,C.Connection.Record>,+players: List<&2,P.Players.State>,+expected: List<&1,C.Connection.Record>) -> IO(Unit): Test.verdict(label,Bool.and(same_list(C.Connection.rebind(connections,players),expected),same_list(Live.Bq.rebind_conns(connections,players),expected)))

@unsafe
def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- roundtrip("channel descriptor fresh",SS.state(1,0,0,""),Chan{12,34})
    Unit <- roundtrip("channel descriptor waiting Unicode",SS.state(1,1,0,"Étoile猫"),Chan{12,34})
    Unit <- roundtrip("channel descriptor playing",SS.state(1,2,7,"Ada"),Chan{12,34})
    Unit <- roundtrip("channel descriptor MAX",SS.state(4294967295,4294967295,4294967295,"Max"),Chan{4294967295,4294967295})
    Unit <- checked("channel rebind empty",Nil{},Nil{},Nil{})
    Unit <- checked("channel rebind fresh retained",[record(3,0,0,"",12,34)],[F.player(71,1,"Ada")],[record(3,0,0,"",12,34)])
    Unit <- checked("channel rebind waiting retained",[record(3,1,0,"Cy",12,34)],[F.player(71,1,"Ada")],[record(3,1,0,"Cy",12,34)])
    Unit <- checked("channel rebind playing retains handle",[record(1,2,7,"Ada",12,34)],[F.player(71,1,"Ada")],[record(1,2,71,"Ada",12,34)])
    Unit <- checked("channel rebind opposite roster orders",[record(1,2,7,"Ada",12,34),record(2,2,8,"Bob",56,78)],[F.player(82,2,"Bob"),F.player(71,1,"Ada")],[record(1,2,71,"Ada",12,34),record(2,2,82,"Bob",56,78)])
    Unit <- checked("channel rebind equal slots distinct generations",[record(1,2,7,"Ada",12,34),record(2,2,8,"Bob",12,78)],[F.player(82,2,"Bob"),F.player(71,1,"Ada")],[record(1,2,71,"Ada",12,34),record(2,2,82,"Bob",12,78)])
    Unit <- checked("channel rebind Unicode raw name",[record(1,2,7,"Étoile猫",12,34)],[F.player(71,1,"Étoile猫")],[record(1,2,71,"Étoile猫",12,34)])
    Unit <- checked("channel rebind MAX IDs and handle",[record(4294967295,2,7,"Max",4294967295,4294967295)],[F.player(4294967295,4294967295,"Max")],[record(4294967295,2,4294967295,"Max",4294967295,4294967295)])
    Unit <- checked("channel rebind missing keeps PID",[record(1,2,7,"Ada",12,34)],Nil{},[record(1,2,7,"Ada",12,34)])
    Unit <- checked("channel rebind duplicate takes first",[record(1,2,7,"Ada",12,34)],[F.player(71,1,"Ada"),F.player(82,1,"Bob")],[record(1,2,71,"Ada",12,34)])
    checked("channel rebind retains original phase and name",[record(1,4294967295,7,"Ada",12,34)],[F.player(71,1,"Bob")],[record(1,4294967295,71,"Ada",12,34)])

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
