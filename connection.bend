import Base
import ./sessions.bend as S
import ./players.bend as P
import ./rebinding.bend as R

type Connection.Record is Type:
  Connection.Record{cid: U32,phase: U32,pid: U32,out: Chan<List<&1,Char>>,name: List<&1,Char>}

def Connection.descriptor(connection: Connection.Record) -> S.Sessions.State:
  match connection:
    case Connection.Record{cid,phase,pid,out,name}: S.Sessions.State{cid,phase,pid,P.Players.share_name(name)}

def Connection.repid(connection: Connection.Record,pid: U32) -> Connection.Record:
  match connection:
    case Connection.Record{cid,phase,old,out,name}: Connection.Record{cid,phase,pid,out,name}

def Connection.channel(connection: Connection.Record) -> Chan<List<&1,Char>>:
  match connection:
    case Connection.Record{cid,phase,pid,out,name}: out

law Connection.repid_descriptor:
  for connection: Connection.Record
  for +pid: U32
  {Connection.descriptor(Connection.repid(connection,pid)) == R.Rebinding.repid(Connection.descriptor(connection),pid) : S.Sessions.State}

def Connection.repid_descriptor(connection,pid):
  match connection:
    case Connection.Record{cid,phase,old,out,name}: {==}

law Connection.repid_channel:
  for connection: Connection.Record
  for +pid: U32
  {Connection.channel(Connection.repid(connection,pid)) == Connection.channel(connection) : Chan<List<&1,Char>>}

def Connection.repid_channel(connection,pid):
  match connection:
    case Connection.Record{cid,phase,old,out,name}: {==}

# The descriptor is shared data; names in live connection records retain their
# original affine list representation.
def Connection.from_descriptor(state: S.Sessions.State,out: Chan<List<&1,Char>>) -> Connection.Record:
  match state:
    case S.Sessions.State{cid,phase,pid,name}: Connection.Record{cid,phase,pid,out,P.Players.text_name(name)}

def Connection.descriptors(connections: List<&1,Connection.Record>) -> List<&2,S.Sessions.State>:
  match connections:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{Connection.descriptor(head),Connection.descriptors(rest)}

def Connection.channels(connections: List<&1,Connection.Record>) -> List<&2,Chan<List<&1,Char>>>:
  match connections:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{Connection.channel(head),Connection.channels(rest)}

def Connection.name(connection: Connection.Record) -> List<&1,Char>:
  match connection:
    case Connection.Record{cid,phase,pid,out,name}: name

def Connection.names(connections: List<&1,Connection.Record>) -> List<&1,List<&1,Char>>:
  match connections:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{Connection.name(head),Connection.names(rest)}

def Connection.one(players: List<&2,P.Players.State>,connection: Connection.Record) -> Connection.Record:
  match connection:
    case Connection.Record{cid,phase,pid,out,name}:
      +cid = cid
      Connection.Record{cid,phase,R.Rebinding.lookup(players,cid,pid),out,name}

def Connection.rebind(connections: List<&1,Connection.Record>,+players: List<&2,P.Players.State>) -> List<&1,Connection.Record>:
  match connections:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{Connection.one(players,head),Connection.rebind(rest,players)}

law Connection.name_round_trip:
  for name: List<&1,Char>
  {P.Players.text_name(P.Players.share_name(name)) == name : List<&1,Char>}

def Connection.name_round_trip(name):
  match name:
    case Nil{}: {==}
    case Con{head,rest}:
      %Connection.name_round_trip(rest) : {Con{head,P.Players.text_name(P.Players.share_name(rest))} == Con{head,_} : List<&1,Char>}
      {==}

law Connection.from_descriptor_exact:
  for +state: S.Sessions.State
  for +out: Chan<List<&1,Char>>
  {Connection.descriptor(Connection.from_descriptor(state,out)) == state : S.Sessions.State}

def Connection.from_descriptor_exact(state,out):
  match state:
    case S.Sessions.State{cid,phase,pid,name}:
      %P.Players.name_round_trip(name) : {S.Sessions.State{cid,phase,pid,P.Players.share_name(P.Players.text_name(name))} == S.Sessions.State{cid,phase,pid,_} : S.Sessions.State}
      {==}

law Connection.from_descriptor_channel:
  for +state: S.Sessions.State
  for +out: Chan<List<&1,Char>>
  {Connection.channel(Connection.from_descriptor(state,out)) == out : Chan<List<&1,Char>>}

def Connection.from_descriptor_channel(state,out):
  match state:
    case S.Sessions.State{cid,phase,pid,name}: {==}

law Connection.connection_round_trip:
  for connection: Connection.Record
  {Connection.from_descriptor(Connection.descriptor(connection),Connection.channel(connection)) == connection : Connection.Record}

def Connection.connection_round_trip(connection):
  match connection:
    case Connection.Record{cid,phase,pid,out,name}:
      %Connection.name_round_trip(name) : {Connection.Record{cid,phase,pid,out,P.Players.text_name(P.Players.share_name(name))} == Connection.Record{cid,phase,pid,out,_} : Connection.Record}
      {==}

law Connection.one_descriptor:
  for +players: List<&2,P.Players.State>
  for connection: Connection.Record
  {Connection.descriptor(Connection.one(players,connection)) == R.Rebinding.one(players,Connection.descriptor(connection)) : S.Sessions.State}

def Connection.one_descriptor(players,connection):
  match connection:
    case Connection.Record{cid,phase,pid,out,name}: {==}

law Connection.one_channel:
  for +players: List<&2,P.Players.State>
  for connection: Connection.Record
  {Connection.channel(Connection.one(players,connection)) == Connection.channel(connection) : Chan<List<&1,Char>>}

def Connection.one_channel(players,connection):
  match connection:
    case Connection.Record{cid,phase,pid,out,name}: {==}

law Connection.one_name:
  for +players: List<&2,P.Players.State>
  for connection: Connection.Record
  {Connection.name(Connection.one(players,connection)) == Connection.name(connection) : List<&1,Char>}

def Connection.one_name(players,connection):
  match connection:
    case Connection.Record{cid,phase,pid,out,name}: {==}

law Connection.rebind_descriptors:
  for connections: List<&1,Connection.Record>
  for +players: List<&2,P.Players.State>
  {Connection.descriptors(Connection.rebind(connections,players)) == R.Rebinding.run(Connection.descriptors(connections),players) : List<&2,S.Sessions.State>}

def Connection.rebind_descriptors(connections,players):
  match connections:
    case Nil{}: {==}
    case Con{head,rest}:
      %Equal.sym(S.Sessions.State,Connection.descriptor(Connection.one(players,head)),R.Rebinding.one(players,Connection.descriptor(head)),Connection.one_descriptor(players,head)) : {Con{_,Connection.descriptors(Connection.rebind(rest,players))} == Con{R.Rebinding.one(players,Connection.descriptor(head)),R.Rebinding.run(Connection.descriptors(rest),players)} : List<&2,S.Sessions.State>}
      %Connection.rebind_descriptors(rest,players) : {Con{R.Rebinding.one(players,Connection.descriptor(head)),Connection.descriptors(Connection.rebind(rest,players))} == Con{R.Rebinding.one(players,Connection.descriptor(head)),_} : List<&2,S.Sessions.State>}
      {==}

law Connection.rebind_channels:
  for connections: List<&1,Connection.Record>
  for +players: List<&2,P.Players.State>
  {Connection.channels(Connection.rebind(connections,players)) == Connection.channels(connections) : List<&2,Chan<List<&1,Char>>>}

def Connection.rebind_channels(connections,players):
  match connections:
    case Nil{}: {==}
    case Con{head,rest}:
      %Equal.sym(Chan<List<&1,Char>>,Connection.channel(Connection.one(players,head)),Connection.channel(head),Connection.one_channel(players,head)) : {Con{_,Connection.channels(Connection.rebind(rest,players))} == Con{Connection.channel(head),Connection.channels(rest)} : List<&2,Chan<List<&1,Char>>>}
      %Connection.rebind_channels(rest,players) : {Con{Connection.channel(head),Connection.channels(Connection.rebind(rest,players))} == Con{Connection.channel(head),_} : List<&2,Chan<List<&1,Char>>>}
      {==}

law Connection.rebind_names:
  for connections: List<&1,Connection.Record>
  for +players: List<&2,P.Players.State>
  {Connection.names(Connection.rebind(connections,players)) == Connection.names(connections) : List<&1,List<&1,Char>>}

def Connection.rebind_names(connections,players):
  match connections:
    case Nil{}: {==}
    case Con{head,rest}:
      %Equal.sym(List<&1,Char>,Connection.name(Connection.one(players,head)),Connection.name(head),Connection.one_name(players,head)) : {Con{_,Connection.names(Connection.rebind(rest,players))} == Con{Connection.name(head),Connection.names(rest)} : List<&1,List<&1,Char>>}
      %Connection.rebind_names(rest,players) : {Con{Connection.name(head),Connection.names(Connection.rebind(rest,players))} == Con{Connection.name(head),_} : List<&1,List<&1,Char>>}
      {==}

# Reify the descriptor and its refinement evidence in one affine traversal.
# This permits a validity proof to consume the connection roster only once.
type Connection.Described<-connection: Connection.Record,-players: List<&2,P.Players.State>> is Data:
  Connection.Described{state: S.Sessions.State,before: {Connection.descriptor(connection) == state : S.Sessions.State},after: {Connection.descriptor(Connection.one(players,connection)) == R.Rebinding.one(players,state) : S.Sessions.State}}

type Connection.Rebound<-connections: List<&1,Connection.Record>,-players: List<&2,P.Players.State>> is Data:
  Connection.Rebound{states: List<&2,S.Sessions.State>,before: {Connection.descriptors(connections) == states : List<&2,S.Sessions.State>},after: {Connection.descriptors(Connection.rebind(connections,players)) == R.Rebinding.run(states,players) : List<&2,S.Sessions.State>}}

law Connection.describe_one:
  for +players: List<&2,P.Players.State>
  for connection: Connection.Record
  Connection.Described<connection,players>

def Connection.describe_one(players,connection):
  match connection:
    case Connection.Record{cid,phase,pid,out,name}:
      +state = {S.Sessions.State{cid,phase,pid,P.Players.share_name(name)} : S.Sessions.State}
      Connection.Described{state,{==},{==}}

law Connection.describe_cons:
  for -head: Connection.Record
  for -rest: List<&1,Connection.Record>
  for +players: List<&2,P.Players.State>
  for +first: Connection.Described<head,players>
  for +later: Connection.Rebound<rest,players>
  Connection.Rebound<Con{head,rest},players>

def Connection.describe_cons(head,rest,players,first,later):
  match first:
    case Connection.Described{state,before,after}:
      match later:
        case Connection.Rebound{states,before_tail,after_tail}:
          Connection.Rebound{Con{state,states},(%before : {Con{Connection.descriptor(head),Connection.descriptors(rest)} == Con{_,states} : List<&2,S.Sessions.State>}; %before_tail : {Con{Connection.descriptor(head),Connection.descriptors(rest)} == Con{Connection.descriptor(head),_} : List<&2,S.Sessions.State>}; {==}),(%after : {Con{Connection.descriptor(Connection.one(players,head)),Connection.descriptors(Connection.rebind(rest,players))} == Con{_,R.Rebinding.run(states,players)} : List<&2,S.Sessions.State>}; %after_tail : {Con{Connection.descriptor(Connection.one(players,head)),Connection.descriptors(Connection.rebind(rest,players))} == Con{Connection.descriptor(Connection.one(players,head)),_} : List<&2,S.Sessions.State>}; {==})}

law Connection.describe:
  for connections: List<&1,Connection.Record>
  for +players: List<&2,P.Players.State>
  Connection.Rebound<connections,players>

def Connection.describe(connections,players):
  match connections:
    case Nil{}: Connection.Rebound{Nil{},{==},{==}}
    case Con{head,rest}: Connection.describe_cons(head,rest,players,Connection.describe_one(players,head),Connection.describe(rest,players))
