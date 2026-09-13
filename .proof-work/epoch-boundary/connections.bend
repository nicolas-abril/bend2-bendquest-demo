# Connection roster invariants and bidirectional world-player correspondence.
import Base
import ./sessions.bend as S
import ./players.bend as P
import ./admission.bend as J
import ./allocation.bend as A
import ./targeting.bend as T
import ./identity.bend as Id
import ./worldstate.bend as W
import ./simulation.bend as Sim
import ./population.bend as Pop
import ./terrain.bend as Terrain

# IDs and names are checked against actual player records, not just ID lists.
def Connections.player_name(player: P.Players.State) -> List<&2,Char>:
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
      match meta:
        case P.Players.Meta{score,kills,found,name}: name

type Connections.In<-session: S.Sessions.State,-states: List<&2,S.Sessions.State>> is Data:
  Connections.Here{rest: List<&2,S.Sessions.State>,shape: {states == Con{session,rest} : List<&2,S.Sessions.State>}}
  Connections.There{head: S.Sessions.State,rest: List<&2,S.Sessions.State>,shape: {states == Con{head,rest} : List<&2,S.Sessions.State>},inside: Connections.In<session,rest>}

type Connections.Link<-players: List<&2,P.Players.State>,-session: S.Sessions.State> is Data:
  Connections.Waiting{unbound: {S.Sessions.pid(session) == 0 : U32},unused: A.Allocation.Absent(S.Sessions.cid(session),J.Admission.cids(players))}
  Connections.Playing{player: P.Players.State,inside: T.Targeting.In<player,players>,positive: {U32.is_eq(S.Sessions.pid(session),0) == False{} : Bool},cid: {S.Sessions.cid(session) == J.Admission.cid(player) : U32},pid: {S.Sessions.pid(session) == P.Players.id(player) : U32},name: {S.Sessions.name(session) == Connections.player_name(player) : List<&2,Char>}}

type Connections.Present<-player: P.Players.State,-states: List<&2,S.Sessions.State>> is Data:
  Connections.Present{session: S.Sessions.State,inside: Connections.In<session,states>,positive: {U32.is_eq(S.Sessions.pid(session),0) == False{} : Bool},cid: {S.Sessions.cid(session) == J.Admission.cid(player) : U32},pid: {S.Sessions.pid(session) == P.Players.id(player) : U32},name: {S.Sessions.name(session) == Connections.player_name(player) : List<&2,Char>}}

def Connections.All(states: List<&2,S.Sessions.State>) -> Data:
  match states:
    case Nil{}: Unit
    case Con{head,rest}: Sigma<&2,&2,S.Sessions.OK<head>,(first => Connections.All(rest))>

def Connections.Links(+players: List<&2,P.Players.State>,states: List<&2,S.Sessions.State>) -> Data:
  match states:
    case Nil{}: Unit
    case Con{head,rest}: Sigma<&2,&2,Connections.Link<players,head>,(first => Connections.Links(players,rest))>

def Connections.Covers(+states: List<&2,S.Sessions.State>,players: List<&2,P.Players.State>) -> Data:
  match players:
    case Nil{}: Unit
    case Con{head,rest}: Sigma<&2,&2,Connections.Present<head,states>,(first => Connections.Covers(states,rest))>

def Connections.cids(states: List<&2,S.Sessions.State>) -> A.Allocation.Ids:
  match states:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{S.Sessions.cid(head),Connections.cids(rest)}

type Connections.OK<-players: List<&2,P.Players.State>,-states: List<&2,S.Sessions.State>> is Data:
  Connections.OK{sessions: Connections.All(states),unique: A.Allocation.Unique(Connections.cids(states)),links: Connections.Links(players,states),covers: Connections.Covers(states,players)}

law Connections.empty: Connections.OK<Nil{},Nil{}>
def Connections.empty(): Connections.OK{Unit{},Unit{},Unit{},Unit{}}

def Connections.binding_cid(binding: S.Sessions.Binding) -> U32:
  match binding:
    case S.Sessions.Binding{cid,pid}: cid

def Connections.binding_pid(binding: S.Sessions.Binding) -> U32:
  match binding:
    case S.Sessions.Binding{cid,pid}: pid

law Connections.cid_binding:
  for +state: S.Sessions.State
  {Connections.binding_cid(S.Sessions.binding(state)) == S.Sessions.cid(state) : U32}

def Connections.cid_binding(state):
  match state:
    case S.Sessions.State{cid,phase,pid,name}: {==}

law Connections.pid_binding:
  for +state: S.Sessions.State
  {Connections.binding_pid(S.Sessions.binding(state)) == S.Sessions.pid(state) : U32}

def Connections.pid_binding(state):
  match state:
    case S.Sessions.State{cid,phase,pid,name}: {==}

law Connections.hello_cid:
  for +state: S.Sessions.State
  for +name: List<&2,Char>
  for +others: List<&2,S.Sessions.State>
  {S.Sessions.cid(S.Sessions.state(S.Sessions.hello(state,name,others))) == S.Sessions.cid(state) : U32}

def Connections.hello_cid(state,name,others):
  +after = S.Sessions.state(S.Sessions.hello(state,name,others))
  %Connections.cid_binding(after) : {_ == S.Sessions.cid(state) : U32}
  %Connections.cid_binding(state) : {Connections.binding_cid(S.Sessions.binding(after)) == _ : U32}
  %S.Sessions.hello_binding(state,name,others) : {Connections.binding_cid(S.Sessions.binding(after)) == Connections.binding_cid(_) : U32}
  {==}

law Connections.hello_pid:
  for +state: S.Sessions.State
  for +name: List<&2,Char>
  for +others: List<&2,S.Sessions.State>
  {S.Sessions.pid(S.Sessions.state(S.Sessions.hello(state,name,others))) == S.Sessions.pid(state) : U32}

def Connections.hello_pid(state,name,others):
  +after = S.Sessions.state(S.Sessions.hello(state,name,others))
  %Connections.pid_binding(after) : {_ == S.Sessions.pid(state) : U32}
  %Connections.pid_binding(state) : {Connections.binding_pid(S.Sessions.binding(after)) == _ : U32}
  %S.Sessions.hello_binding(state,name,others) : {Connections.binding_pid(S.Sessions.binding(after)) == Connections.binding_pid(_) : U32}
  {==}

law Connections.hello_link:
  for +players: List<&2,P.Players.State>
  for +state: S.Sessions.State
  for +name: List<&2,Char>
  for +others: List<&2,S.Sessions.State>
  for +valid: Connections.Link<players,state>
  Connections.Link<players,S.Sessions.state(S.Sessions.hello(state,name,others))>

def Connections.hello_link(players,state,name,others,valid):
  match valid:
    case Connections.Waiting{unbound,unused}:
      Connections.Waiting{Equal.trans(U32,S.Sessions.pid(S.Sessions.state(S.Sessions.hello(state,name,others))),S.Sessions.pid(state),0,Connections.hello_pid(state,name,others),unbound),(%Equal.sym(U32,S.Sessions.cid(S.Sessions.state(S.Sessions.hello(state,name,others))),S.Sessions.cid(state),Connections.hello_cid(state,name,others)) : A.Allocation.Absent(_,J.Admission.cids(players)); unused)}
    case Connections.Playing{player,inside,positive,cid,pid,old_name}:
      %Equal.sym(S.Sessions.Result,S.Sessions.hello(state,name,others),S.Sessions.Result{state,S.Sessions.Locked{}},S.Sessions.bound_locked(state,name,others,positive)) : Connections.Link<players,S.Sessions.state(_)>
      Connections.Playing{player,inside,positive,cid,pid,old_name}

def Connections.head(states: List<&2,S.Sessions.State>,fallback: S.Sessions.State) -> S.Sessions.State:
  match states:
    case Nil{}: fallback
    case Con{head,rest}: head

def Connections.tail(states: List<&2,S.Sessions.State>) -> List<&2,S.Sessions.State>:
  match states:
    case Nil{}: Nil{}
    case Con{head,rest}: rest

law Connections.cons_head:
  for +a: S.Sessions.State
  for +b: S.Sessions.State
  for +xs: List<&2,S.Sessions.State>
  for +ys: List<&2,S.Sessions.State>
  for +same: {Con{a,xs} == Con{b,ys} : List<&2,S.Sessions.State>}
  {a == b : S.Sessions.State}

def Connections.cons_head(a,b,xs,ys,same):
  %same : {a == Connections.head(_,a) : S.Sessions.State}
  {==}

law Connections.cons_tail:
  for +a: S.Sessions.State
  for +b: S.Sessions.State
  for +xs: List<&2,S.Sessions.State>
  for +ys: List<&2,S.Sessions.State>
  for +same: {Con{a,xs} == Con{b,ys} : List<&2,S.Sessions.State>}
  {xs == ys : List<&2,S.Sessions.State>}

def Connections.cons_tail(a,b,xs,ys,same):
  %same : {xs == Connections.tail(_) : List<&2,S.Sessions.State>}
  {==}

law Connections.hello_present:
  for +player: P.Players.State
  for +head: S.Sessions.State
  for +others: List<&2,S.Sessions.State>
  for +name: List<&2,Char>
  for +present: Connections.Present<player,Con{head,others}>
  Connections.Present<player,Con{S.Sessions.state(S.Sessions.hello(head,name,others)),others}>

def Connections.hello_present(player,head,others,name,present):
  match present:
    case Connections.Present{session,inside,positive,cid,pid,old_name}:
      match inside:
        case Connections.Here{rest,shape}:
          +equal = Connections.cons_head(head,session,others,rest,shape)
          +bound = {(%Equal.sym(S.Sessions.State,head,session,equal) : {U32.is_eq(S.Sessions.pid(_),0) == False{} : Bool}; positive) : {U32.is_eq(S.Sessions.pid(head),0) == False{} : Bool}}
          %Equal.sym(S.Sessions.Result,S.Sessions.hello(head,name,others),S.Sessions.Result{head,S.Sessions.Locked{}},S.Sessions.bound_locked(head,name,others,bound)) : Connections.Present<player,Con{S.Sessions.state(_),others}>
          Connections.Present{session,Connections.Here{rest,shape},positive,cid,pid,old_name}
        case Connections.There{before,rest,shape,later}:
          Connections.Present{session,Connections.There{S.Sessions.state(S.Sessions.hello(head,name,others)),others,{==},(%Equal.sym(List<&2,S.Sessions.State>,others,rest,Connections.cons_tail(head,before,others,rest,shape)) : Connections.In<session,_>; later)},positive,cid,pid,old_name}

law Connections.hello_covers:
  for +players: List<&2,P.Players.State>
  for +head: S.Sessions.State
  for +others: List<&2,S.Sessions.State>
  for +name: List<&2,Char>
  for +valid: Connections.Covers(Con{head,others},players)
  Connections.Covers(Con{S.Sessions.state(S.Sessions.hello(head,name,others)),others},players)

def Connections.hello_covers(players,head,others,name,valid):
  match players:
    case Nil{}: Unit{}
    case Con{player,rest}:
      match valid:
        case Tuple{first,later}: Tuple{Connections.hello_present(player,head,others,name,first),Connections.hello_covers(rest,head,others,name,later)}

law Connections.hello_unique:
  for +head: S.Sessions.State
  for +others: List<&2,S.Sessions.State>
  for +name: List<&2,Char>
  for +valid: A.Allocation.Unique(Connections.cids(Con{head,others}))
  A.Allocation.Unique(Connections.cids(Con{S.Sessions.state(S.Sessions.hello(head,name,others)),others}))

def Connections.hello_unique(head,others,name,valid):
  %Equal.sym(U32,S.Sessions.cid(S.Sessions.state(S.Sessions.hello(head,name,others))),S.Sessions.cid(head),Connections.hello_cid(head,name,others)) : A.Allocation.Unique(Con{_,Connections.cids(others)})
  valid

law Connections.hello_ok:
  for +players: List<&2,P.Players.State>
  for +head: S.Sessions.State
  for +others: List<&2,S.Sessions.State>
  for +name: List<&2,Char>
  for +valid: Connections.OK<players,Con{head,others}>
  Connections.OK<players,Con{S.Sessions.state(S.Sessions.hello(head,name,others)),others}>

def Connections.hello_ok(players,head,others,name,valid):
  match valid:
    case Connections.OK{sessions,unique,links,covers}:
      match sessions:
        case Tuple{first,later}:
          match links:
            case Tuple{linked,rest}: Connections.OK{Tuple{S.Sessions.hello_ok(head,name,others,first),later},Connections.hello_unique(head,others,name,unique),Tuple{Connections.hello_link(players,head,name,others,linked),rest},Connections.hello_covers(players,head,others,name,covers)}

def Connections.absent_head(id: U32,session: S.Sessions.State,rest: List<&2,S.Sessions.State>,valid: A.Allocation.Absent(id,Connections.cids(Con{session,rest}))) -> {U32.is_eq(id,S.Sessions.cid(session)) == False{} : Bool}:
  match valid:
    case Tuple{head,tail}: head

def Connections.absent_tail(id: U32,session: S.Sessions.State,rest: List<&2,S.Sessions.State>,valid: A.Allocation.Absent(id,Connections.cids(Con{session,rest}))) -> A.Allocation.Absent(id,Connections.cids(rest)):
  match valid:
    case Tuple{head,tail}: tail

law Connections.absent_member:
  for +session: S.Sessions.State
  for -states: List<&2,S.Sessions.State>
  for +inside: Connections.In<session,states>
  for +id: U32
  for +unused: A.Allocation.Absent(id,Connections.cids(states))
  {U32.is_eq(id,S.Sessions.cid(session)) == False{} : Bool}

def Connections.absent_member(session,states,inside,id,unused):
  match inside:
    case Connections.Here{rest,shape}: Connections.absent_head(id,session,rest,(%shape : A.Allocation.Absent(id,Connections.cids(_)); unused))
    case Connections.There{head,rest,shape,later}: Connections.absent_member(session,rest,later,id,Connections.absent_tail(id,head,rest,(%shape : A.Allocation.Absent(id,Connections.cids(_)); unused)))

law Connections.present_absent:
  for +player: P.Players.State
  for +states: List<&2,S.Sessions.State>
  for +id: U32
  for +unused: A.Allocation.Absent(id,Connections.cids(states))
  for +present: Connections.Present<player,states>
  {U32.is_eq(id,J.Admission.cid(player)) == False{} : Bool}

def Connections.present_absent(player,states,id,unused,present):
  match present:
    case Connections.Present{session,inside,positive,cid,pid,name}:
      %cid : {U32.is_eq(id,_) == False{} : Bool}
      Connections.absent_member(session,states,inside,id,unused)

law Connections.unused_players:
  for +players: List<&2,P.Players.State>
  for +states: List<&2,S.Sessions.State>
  for +id: U32
  for +unused: A.Allocation.Absent(id,Connections.cids(states))
  for +covers: Connections.Covers(states,players)
  A.Allocation.Absent(id,J.Admission.cids(players))

def Connections.unused_players(players,states,id,unused,covers):
  match players:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match covers:
        case Tuple{first,later}: Tuple{Connections.present_absent(head,states,id,unused,first),Connections.unused_players(rest,states,id,unused,later)}

law Connections.weaken_present:
  for +head: S.Sessions.State
  for +states: List<&2,S.Sessions.State>
  for +player: P.Players.State
  for +present: Connections.Present<player,states>
  Connections.Present<player,Con{head,states}>

def Connections.weaken_present(head,states,player,present):
  match present:
    case Connections.Present{session,inside,positive,cid,pid,name}: Connections.Present{session,Connections.There{head,states,{==},inside},positive,cid,pid,name}

law Connections.weaken_covers:
  for +players: List<&2,P.Players.State>
  for +head: S.Sessions.State
  for +states: List<&2,S.Sessions.State>
  for +covers: Connections.Covers(states,players)
  Connections.Covers(Con{head,states},players)

def Connections.weaken_covers(players,head,states,covers):
  match players:
    case Nil{}: Unit{}
    case Con{player,rest}:
      match covers:
        case Tuple{first,later}: Tuple{Connections.weaken_present(head,states,player,first),Connections.weaken_covers(rest,head,states,later)}

law Connections.join_ok:
  for +players: List<&2,P.Players.State>
  for +states: List<&2,S.Sessions.State>
  for +choice: A.Allocation.Choice
  for +fresh: A.Allocation.Fresh<Connections.cids(states),choice>
  for +valid: Connections.OK<players,states>
  Connections.OK<players,Con{S.Sessions.fresh(A.Allocation.id(choice)),states}>

def Connections.join_ok(players,states,choice,fresh,valid):
  match fresh:
    case A.Allocation.Fresh{positive,absent,next_positive}:
      match valid:
        case Connections.OK{sessions,unique,links,covers}:
          Connections.OK{Tuple{S.Sessions.fresh_ok(A.Allocation.id(choice),positive),sessions},Tuple{absent,unique},Tuple{Connections.Waiting{{==},Connections.unused_players(players,states,A.Allocation.id(choice),absent,covers)},links},Connections.weaken_covers(players,S.Sessions.fresh(A.Allocation.id(choice)),states,covers)}

# Rejected allocation is an exact no-op. Successful allocation uses the existing
# checked bounded search over active connection IDs, including wraparound.
def Connections.admit(choice: Maybe<&2,A.Allocation.Choice>,states: List<&2,S.Sessions.State>) -> List<&2,S.Sessions.State>:
  match choice:
    case None{}: states
    case Some{selected}: Con{S.Sessions.fresh(A.Allocation.id(selected)),states}

law Connections.admit_ok:
  for +choice: Maybe<&2,A.Allocation.Choice>
  for +players: List<&2,P.Players.State>
  for +states: List<&2,S.Sessions.State>
  for +safe: A.Allocation.Safe(Connections.cids(states),choice)
  for +valid: Connections.OK<players,states>
  Connections.OK<players,Connections.admit(choice,states)>

def Connections.admit_ok(choice,players,states,safe,valid):
  match choice:
    case None{}: valid
    case Some{selected}: Connections.join_ok(players,states,selected,safe,valid)

law Connections.allocate_ok:
  for +players: List<&2,P.Players.State>
  for +states: List<&2,S.Sessions.State>
  for +hint: U32
  for +valid: Connections.OK<players,states>
  Connections.OK<players,Connections.admit(A.Allocation.find(Connections.cids(states),hint),states)>

def Connections.allocate_ok(players,states,hint,valid): Connections.admit_ok(A.Allocation.find(Connections.cids(states),hint),players,states,A.Allocation.find_safe(Connections.cids(states),hint),valid)

law Connections.all_nonzero:
  for +states: List<&2,S.Sessions.State>
  for +valid: Connections.All(states)
  A.Allocation.Absent(0,Connections.cids(states))

def Connections.all_nonzero(states,valid):
  match states:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match valid:
        case Tuple{first,later}:
          match first:
            case S.Sessions.OK{cid,lifecycle}: Tuple{Id.Identity.neq_sym(S.Sessions.cid(head),0,cid),Connections.all_nonzero(rest,later)}

# This is the pure world plus the full bidirectional connection/player relation.
# Preservation through CREATE/disconnect/world replacement and the effectful
# selection/dispatch adapters remains to be connected to this invariant.
type Connections.WorldOK<-seed: U32,-world: Sim.Simulation.State,-states: List<&2,S.Sessions.State>> is Data:
  Connections.WorldOK{world_ok: W.WorldState.OK<seed,world>,connections: Connections.OK<Sim.Simulation.players(world),states>}

law Connections.fresh_world:
  for +world: U32
  for +seed: U32
  for +now: U32
  Connections.WorldOK<seed,Terrain.Terrain.simulation(Pop.Population.fresh(world,seed,now)),Nil{}>

def Connections.fresh_world(world,seed,now): Connections.WorldOK{W.WorldState.fresh(world,seed,now),Connections.empty}

law Connections.join_world:
  for +seed: U32
  for +world: Sim.Simulation.State
  for +states: List<&2,S.Sessions.State>
  for +hint: U32
  for +valid: Connections.WorldOK<seed,world,states>
  Connections.WorldOK<seed,world,Connections.admit(A.Allocation.find(Connections.cids(states),hint),states)>

def Connections.join_world(seed,world,states,hint,valid):
  match valid:
    case Connections.WorldOK{world_ok,connections}: Connections.WorldOK{world_ok,Connections.allocate_ok(Sim.Simulation.players(world),states,hint,connections)}

law Connections.hello_world:
  for +seed: U32
  for +world: Sim.Simulation.State
  for +head: S.Sessions.State
  for +others: List<&2,S.Sessions.State>
  for +name: List<&2,Char>
  for +valid: Connections.WorldOK<seed,world,Con{head,others}>
  Connections.WorldOK<seed,world,Con{S.Sessions.state(S.Sessions.hello(head,name,others)),others}>

def Connections.hello_world(seed,world,head,others,name,valid):
  match valid:
    case Connections.WorldOK{world_ok,connections}: Connections.WorldOK{world_ok,Connections.hello_ok(Sim.Simulation.players(world),head,others,name,connections)}
