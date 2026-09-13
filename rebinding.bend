# Pure CID lookup and connection rebinding used by world restart.
import Base
import ./sessions.bend as S
import ./players.bend as P
import ./admission.bend as J
import ./allocation.bend as A
import ./targeting.bend as T
import ./playerids.bend as Id
import ./player_membership.bend as PM
import ./identity.bend as I
import ./numeric.bend as N
import ./connections.bend as C

# Match the server's first-CID lookup, including its old-PID fallback.
def Rebinding.choose(found: Bool,pid: U32,fallback: U32) -> U32:
  match found:
    case True{}: pid
    case False{}: fallback

def Rebinding.lookup(players: List<&2,P.Players.State>,+cid: U32,fallback: U32) -> U32:
  match players:
    case Nil{}: fallback
    case Con{head,rest}:
      +head = head
      Rebinding.choose(U32.is_eq(J.Admission.cid(head),cid),P.Players.id(head),Rebinding.lookup(rest,cid,fallback))

# Preserve lifecycle phase, connection ID and name; replace only player ID.
def Rebinding.repid(state: S.Sessions.State,pid: U32) -> S.Sessions.State:
  match state:
    case S.Sessions.State{cid,phase,old,name}: S.Sessions.State{cid,phase,pid,name}

def Rebinding.one(players: List<&2,P.Players.State>,+state: S.Sessions.State) -> S.Sessions.State:
  Rebinding.repid(state,Rebinding.lookup(players,S.Sessions.cid(state),S.Sessions.pid(state)))

def Rebinding.run(states: List<&2,S.Sessions.State>,+players: List<&2,P.Players.State>) -> List<&2,S.Sessions.State>:
  match states:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{Rebinding.one(players,head),Rebinding.run(rest,players)}

law Rebinding.lookup_absent:
  for +players: List<&2,P.Players.State>
  for +cid: U32
  for +fallback: U32
  for +absent: A.Allocation.Absent(cid,J.Admission.cids(players))
  {Rebinding.lookup(players,cid,fallback) == fallback : U32}

def Rebinding.lookup_absent(players,cid,fallback,absent):
  match players:
    case Nil{}: {==}
    case Con{head,rest}:
      match absent:
        case Tuple{different,later}:
          %Equal.sym(Bool,U32.is_eq(J.Admission.cid(head),cid),False{},I.Identity.neq_sym(cid,J.Admission.cid(head),different)) : {Rebinding.choose(_,P.Players.id(head),Rebinding.lookup(rest,cid,fallback)) == fallback : U32}
          Rebinding.lookup_absent(rest,cid,fallback,later)

law Rebinding.lookup_head:
  for +player: P.Players.State
  for +rest: List<&2,P.Players.State>
  for +fallback: U32
  {Rebinding.lookup(Con{player,rest},J.Admission.cid(player),fallback) == P.Players.id(player) : U32}

def Rebinding.lookup_head(player,rest,fallback):
  %Equal.sym(Bool,U32.is_eq(J.Admission.cid(player),J.Admission.cid(player)),True{},N.Numeric.u32_eq_refl(J.Admission.cid(player))) : {Rebinding.choose(_,P.Players.id(player),Rebinding.lookup(rest,J.Admission.cid(player),fallback)) == P.Players.id(player) : U32}
  {==}

# Uniqueness is essential: without it an earlier record could shadow this CID.
law Rebinding.lookup_member:
  for +player: P.Players.State
  for -players: List<&2,P.Players.State>
  for +inside: T.Targeting.In<player,players>
  for +fallback: U32
  for +unique: A.Allocation.Unique(J.Admission.cids(players))
  {Rebinding.lookup(players,J.Admission.cid(player),fallback) == P.Players.id(player) : U32}

def Rebinding.lookup_member(player,players,inside,fallback,unique):
  match inside:
    case T.Targeting.Here{rest,shape}:
      %Equal.sym(List<&2,P.Players.State>,players,Con{player,rest},shape) : {Rebinding.lookup(_,J.Admission.cid(player),fallback) == P.Players.id(player) : U32}
      Rebinding.lookup_head(player,rest,fallback)
    case T.Targeting.There{head,rest,shape,later}:
      +valid = {(%shape : A.Allocation.Unique(J.Admission.cids(_)); unique) : A.Allocation.Unique(J.Admission.cids(Con{head,rest}))}
      +absent = Id.PlayerIds.unique_head(J.Admission.cid(head),J.Admission.cids(rest),valid)
      +different = PM.PlayerMembership.absent_member(Id.PlayerIds.Connection{},player,rest,later,J.Admission.cid(head),(%Equal.sym(A.Allocation.Ids,Id.PlayerIds.project(Id.PlayerIds.Connection{},rest),J.Admission.cids(rest),Id.PlayerIds.connection_projection(rest)) : A.Allocation.Absent(J.Admission.cid(head),_); absent))
      %Equal.sym(List<&2,P.Players.State>,players,Con{head,rest},shape) : {Rebinding.lookup(_,J.Admission.cid(player),fallback) == P.Players.id(player) : U32}
      %Equal.sym(Bool,U32.is_eq(J.Admission.cid(head),J.Admission.cid(player)),False{},different) : {Rebinding.choose(_,P.Players.id(head),Rebinding.lookup(rest,J.Admission.cid(player),fallback)) == P.Players.id(player) : U32}
      Rebinding.lookup_member(player,rest,later,fallback,Id.PlayerIds.unique_tail(J.Admission.cid(head),J.Admission.cids(rest),valid))

law Rebinding.repid_cid:
  for +state: S.Sessions.State
  for +pid: U32
  {S.Sessions.cid(Rebinding.repid(state,pid)) == S.Sessions.cid(state) : U32}

def Rebinding.repid_cid(state,pid):
  match state:
    case S.Sessions.State{cid,phase,old,name}: {==}

law Rebinding.repid_phase:
  for +state: S.Sessions.State
  for +pid: U32
  {S.Sessions.phase(Rebinding.repid(state,pid)) == S.Sessions.phase(state) : U32}

def Rebinding.repid_phase(state,pid):
  match state:
    case S.Sessions.State{cid,phase,old,name}: {==}

law Rebinding.repid_name:
  for +state: S.Sessions.State
  for +pid: U32
  {S.Sessions.name(Rebinding.repid(state,pid)) == S.Sessions.name(state) : List<&2,Char>}

def Rebinding.repid_name(state,pid):
  match state:
    case S.Sessions.State{cid,phase,old,name}: {==}

law Rebinding.repid_pid:
  for +state: S.Sessions.State
  for +pid: U32
  {S.Sessions.pid(Rebinding.repid(state,pid)) == pid : U32}

def Rebinding.repid_pid(state,pid):
  match state:
    case S.Sessions.State{cid,phase,old,name}: {==}

law Rebinding.repid_same:
  for +state: S.Sessions.State
  {Rebinding.repid(state,S.Sessions.pid(state)) == state : S.Sessions.State}

def Rebinding.repid_same(state):
  match state:
    case S.Sessions.State{cid,phase,pid,name}: {==}

law Rebinding.lifecycle:
  for +stage: Nat
  for +old: U32
  for +pid: U32
  for +name: List<&2,Char>
  for +positive_old: {U32.is_eq(old,0) == False{} : Bool}
  for +positive_new: {U32.is_eq(pid,0) == False{} : Bool}
  for +valid: S.Sessions.Lifecycle(stage,old,name)
  S.Sessions.Lifecycle(stage,pid,name)

def Rebinding.lifecycle(stage,old,pid,name,positive_old,positive_new,valid):
  match stage:
    case Zero{}:
      match valid:
        case Tuple{zero,empty}: Empty.absurd(S.Sessions.Lifecycle(Zero{},pid,name),PM.PlayerMembership.eq_ne(old,0,zero,positive_old))
    case Succ{one}:
      match one:
        case Zero{}:
          match valid:
            case Tuple{zero,named}: Empty.absurd(S.Sessions.Lifecycle(1n,pid,name),PM.PlayerMembership.eq_ne(old,0,zero,positive_old))
        case Succ{two}:
          match two:
            case Zero{}:
              match valid:
                case Tuple{positive,named}: Tuple{positive_new,named}
            case Succ{invalid}: valid

law Rebinding.repid_ok:
  for +state: S.Sessions.State
  for +pid: U32
  for +positive_old: {U32.is_eq(S.Sessions.pid(state),0) == False{} : Bool}
  for +positive_new: {U32.is_eq(pid,0) == False{} : Bool}
  for +valid: S.Sessions.OK<state>
  S.Sessions.OK<Rebinding.repid(state,pid)>

def Rebinding.repid_ok(state,pid,positive_old,positive_new,valid):
  match state:
    case S.Sessions.State{cid,phase,old,name}:
      match valid:
        case S.Sessions.OK{connection,lifecycle}: S.Sessions.OK{connection,Rebinding.lifecycle(U32.to_nat(phase),old,pid,name,positive_old,positive_new,lifecycle)}

law Rebinding.one_absent:
  for +players: List<&2,P.Players.State>
  for +state: S.Sessions.State
  for +absent: A.Allocation.Absent(S.Sessions.cid(state),J.Admission.cids(players))
  {Rebinding.one(players,state) == state : S.Sessions.State}

def Rebinding.one_absent(players,state,absent):
  %Equal.sym(U32,Rebinding.lookup(players,S.Sessions.cid(state),S.Sessions.pid(state)),S.Sessions.pid(state),Rebinding.lookup_absent(players,S.Sessions.cid(state),S.Sessions.pid(state),absent)) : {Rebinding.repid(state,_) == state : S.Sessions.State}
  Rebinding.repid_same(state)

law Rebinding.one_member:
  for +players: List<&2,P.Players.State>
  for +state: S.Sessions.State
  for +player: P.Players.State
  for +inside: T.Targeting.In<player,players>
  for +cid: {S.Sessions.cid(state) == J.Admission.cid(player) : U32}
  for +unique: A.Allocation.Unique(J.Admission.cids(players))
  {Rebinding.one(players,state) == Rebinding.repid(state,P.Players.id(player)) : S.Sessions.State}

def Rebinding.one_member(players,state,player,inside,cid,unique):
  Equal.cong(U32,S.Sessions.State,(pid => Rebinding.repid(state,pid)),Rebinding.lookup(players,S.Sessions.cid(state),S.Sessions.pid(state)),P.Players.id(player),(%Equal.sym(U32,S.Sessions.cid(state),J.Admission.cid(player),cid) : {Rebinding.lookup(players,_,S.Sessions.pid(state)) == P.Players.id(player) : U32}; Rebinding.lookup_member(player,players,inside,S.Sessions.pid(state),unique)))

law Rebinding.one_cid:
  for +players: List<&2,P.Players.State>
  for +state: S.Sessions.State
  {S.Sessions.cid(Rebinding.one(players,state)) == S.Sessions.cid(state) : U32}

def Rebinding.one_cid(players,state): Rebinding.repid_cid(state,Rebinding.lookup(players,S.Sessions.cid(state),S.Sessions.pid(state)))

law Rebinding.one_phase:
  for +players: List<&2,P.Players.State>
  for +state: S.Sessions.State
  {S.Sessions.phase(Rebinding.one(players,state)) == S.Sessions.phase(state) : U32}

def Rebinding.one_phase(players,state): Rebinding.repid_phase(state,Rebinding.lookup(players,S.Sessions.cid(state),S.Sessions.pid(state)))

law Rebinding.one_name:
  for +players: List<&2,P.Players.State>
  for +state: S.Sessions.State
  {S.Sessions.name(Rebinding.one(players,state)) == S.Sessions.name(state) : List<&2,Char>}

def Rebinding.one_name(players,state): Rebinding.repid_name(state,Rebinding.lookup(players,S.Sessions.cid(state),S.Sessions.pid(state)))

law Rebinding.run_cids:
  for +states: List<&2,S.Sessions.State>
  for +players: List<&2,P.Players.State>
  {C.Connections.cids(Rebinding.run(states,players)) == C.Connections.cids(states) : A.Allocation.Ids}

def Rebinding.run_cids(states,players):
  match states:
    case Nil{}: {==}
    case Con{head,rest}:
      %Equal.sym(U32,S.Sessions.cid(Rebinding.one(players,head)),S.Sessions.cid(head),Rebinding.one_cid(players,head)) : {Con{_,C.Connections.cids(Rebinding.run(rest,players))} == Con{S.Sessions.cid(head),C.Connections.cids(rest)} : A.Allocation.Ids}
      %Rebinding.run_cids(rest,players) : {Con{S.Sessions.cid(head),C.Connections.cids(Rebinding.run(rest,players))} == Con{S.Sessions.cid(head),_} : A.Allocation.Ids}
      {==}

law Rebinding.run_unique:
  for +states: List<&2,S.Sessions.State>
  for +players: List<&2,P.Players.State>
  for +unique: A.Allocation.Unique(C.Connections.cids(states))
  A.Allocation.Unique(C.Connections.cids(Rebinding.run(states,players)))

def Rebinding.run_unique(states,players,unique):
  %Equal.sym(A.Allocation.Ids,C.Connections.cids(Rebinding.run(states,players)),C.Connections.cids(states),Rebinding.run_cids(states,players)) : A.Allocation.Unique(_)
  unique

# This relation deliberately permits the PID to change. It records the actual
# replacement player, its roster membership, and unchanged connection/name.
type Rebinding.Target<-players: List<&2,P.Players.State>,-state: S.Sessions.State> is Data:
  Rebinding.Waiting{zero: {S.Sessions.pid(state) == 0 : U32},absent: A.Allocation.Absent(S.Sessions.cid(state),J.Admission.cids(players))}
  Rebinding.Playing{player: P.Players.State,inside: T.Targeting.In<player,players>,old_positive: {U32.is_eq(S.Sessions.pid(state),0) == False{} : Bool},cid: {S.Sessions.cid(state) == J.Admission.cid(player) : U32},name: {S.Sessions.name(state) == C.Connections.player_name(player) : List<&2,Char>}}

def Rebinding.Targets(+players: List<&2,P.Players.State>,states: List<&2,S.Sessions.State>) -> Data:
  match states:
    case Nil{}: Unit
    case Con{head,rest}: Sigma<&2,&2,Rebinding.Target<players,head>,(first => Rebinding.Targets(players,rest))>

law Rebinding.member_positive:
  for +player: P.Players.State
  for +players: List<&2,P.Players.State>
  for +inside: T.Targeting.In<player,players>
  for +nonzero: A.Allocation.Absent(0,Id.PlayerIds.project(Id.PlayerIds.Player{},players))
  {U32.is_eq(P.Players.id(player),0) == False{} : Bool}

def Rebinding.member_positive(player,players,inside,nonzero): I.Identity.neq_sym(0,P.Players.id(player),PM.PlayerMembership.absent_member(Id.PlayerIds.Player{},player,players,inside,0,nonzero))

law Rebinding.repid_link:
  for +players: List<&2,P.Players.State>
  for +state: S.Sessions.State
  for +player: P.Players.State
  for +inside: T.Targeting.In<player,players>
  for +positive: {U32.is_eq(P.Players.id(player),0) == False{} : Bool}
  for +cid: {S.Sessions.cid(state) == J.Admission.cid(player) : U32}
  for +name: {S.Sessions.name(state) == C.Connections.player_name(player) : List<&2,Char>}
  C.Connections.Link<players,Rebinding.repid(state,P.Players.id(player))>

def Rebinding.repid_link(players,state,player,inside,positive,cid,name):
  match state:
    case S.Sessions.State{connection,phase,old,label}: C.Connections.Playing{player,inside,positive,cid,{==},name}

law Rebinding.one_link:
  for +players: List<&2,P.Players.State>
  for +state: S.Sessions.State
  for +target: Rebinding.Target<players,state>
  for +unique: A.Allocation.Unique(J.Admission.cids(players))
  for +nonzero: A.Allocation.Absent(0,Id.PlayerIds.project(Id.PlayerIds.Player{},players))
  C.Connections.Link<players,Rebinding.one(players,state)>

def Rebinding.one_link(players,state,target,unique,nonzero):
  match target:
    case Rebinding.Waiting{zero,absent}:
      %Equal.sym(S.Sessions.State,Rebinding.one(players,state),state,Rebinding.one_absent(players,state,absent)) : C.Connections.Link<players,_>
      C.Connections.Waiting{zero,absent}
    case Rebinding.Playing{player,inside,old_positive,cid,name}:
      %Equal.sym(S.Sessions.State,Rebinding.one(players,state),Rebinding.repid(state,P.Players.id(player)),Rebinding.one_member(players,state,player,inside,cid,unique)) : C.Connections.Link<players,_>
      Rebinding.repid_link(players,state,player,inside,Rebinding.member_positive(player,players,inside,nonzero),cid,name)

law Rebinding.one_ok:
  for +players: List<&2,P.Players.State>
  for +state: S.Sessions.State
  for +target: Rebinding.Target<players,state>
  for +unique: A.Allocation.Unique(J.Admission.cids(players))
  for +nonzero: A.Allocation.Absent(0,Id.PlayerIds.project(Id.PlayerIds.Player{},players))
  for +valid: S.Sessions.OK<state>
  S.Sessions.OK<Rebinding.one(players,state)>

def Rebinding.one_ok(players,state,target,unique,nonzero,valid):
  match target:
    case Rebinding.Waiting{zero,absent}:
      %Equal.sym(S.Sessions.State,Rebinding.one(players,state),state,Rebinding.one_absent(players,state,absent)) : S.Sessions.OK<_>
      valid
    case Rebinding.Playing{player,inside,old_positive,cid,name}:
      %Equal.sym(S.Sessions.State,Rebinding.one(players,state),Rebinding.repid(state,P.Players.id(player)),Rebinding.one_member(players,state,player,inside,cid,unique)) : S.Sessions.OK<_>
      Rebinding.repid_ok(state,P.Players.id(player),old_positive,Rebinding.member_positive(player,players,inside,nonzero),valid)

law Rebinding.run_links:
  for +states: List<&2,S.Sessions.State>
  for +players: List<&2,P.Players.State>
  for +targets: Rebinding.Targets(players,states)
  for +unique: A.Allocation.Unique(J.Admission.cids(players))
  for +nonzero: A.Allocation.Absent(0,Id.PlayerIds.project(Id.PlayerIds.Player{},players))
  C.Connections.Links(players,Rebinding.run(states,players))

def Rebinding.run_links(states,players,targets,unique,nonzero):
  match states:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match targets:
        case Tuple{first,later}: Tuple{Rebinding.one_link(players,head,first,unique,nonzero),Rebinding.run_links(rest,players,later,unique,nonzero)}

law Rebinding.run_all:
  for +states: List<&2,S.Sessions.State>
  for +players: List<&2,P.Players.State>
  for +targets: Rebinding.Targets(players,states)
  for +unique: A.Allocation.Unique(J.Admission.cids(players))
  for +nonzero: A.Allocation.Absent(0,Id.PlayerIds.project(Id.PlayerIds.Player{},players))
  for +valid: C.Connections.All(states)
  C.Connections.All(Rebinding.run(states,players))

def Rebinding.run_all(states,players,targets,unique,nonzero,valid):
  match states:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match targets:
        case Tuple{first,later}:
          match valid:
            case Tuple{before,tail}: Tuple{Rebinding.one_ok(players,head,first,unique,nonzero,before),Rebinding.run_all(rest,players,later,unique,nonzero,tail)}

law Rebinding.run_member:
  for +state: S.Sessions.State
  for -states: List<&2,S.Sessions.State>
  for +inside: C.Connections.In<state,states>
  for +players: List<&2,P.Players.State>
  C.Connections.In<Rebinding.one(players,state),Rebinding.run(states,players)>

def Rebinding.run_member(state,states,inside,players):
  match inside:
    case C.Connections.Here{rest,shape}:
      %Equal.sym(List<&2,S.Sessions.State>,states,Con{state,rest},shape) : C.Connections.In<Rebinding.one(players,state),Rebinding.run(_,players)>
      C.Connections.Here{Rebinding.run(rest,players),{==}}
    case C.Connections.There{head,rest,shape,later}:
      %Equal.sym(List<&2,S.Sessions.State>,states,Con{head,rest},shape) : C.Connections.In<Rebinding.one(players,state),Rebinding.run(_,players)>
      C.Connections.There{Rebinding.one(players,head),Rebinding.run(rest,players),{==},Rebinding.run_member(state,rest,later,players)}

# Reverse correspondence: every new player has an actual old connection with
# the same CID/name. The old PID need not equal the new PID.
type Rebinding.Reserved<-player: P.Players.State,-states: List<&2,S.Sessions.State>> is Data:
  Rebinding.Reserved{state: S.Sessions.State,inside: C.Connections.In<state,states>,cid: {S.Sessions.cid(state) == J.Admission.cid(player) : U32},name: {S.Sessions.name(state) == C.Connections.player_name(player) : List<&2,Char>}}

def Rebinding.Reservations(+states: List<&2,S.Sessions.State>,players: List<&2,P.Players.State>) -> Data:
  match players:
    case Nil{}: Unit
    case Con{head,rest}: Sigma<&2,&2,Rebinding.Reserved<head,states>,(first => Rebinding.Reservations(states,rest))>

law Rebinding.repid_present:
  for +player: P.Players.State
  for +states: List<&2,S.Sessions.State>
  for +state: S.Sessions.State
  for +inside: C.Connections.In<Rebinding.repid(state,P.Players.id(player)),states>
  for +positive: {U32.is_eq(P.Players.id(player),0) == False{} : Bool}
  for +cid: {S.Sessions.cid(state) == J.Admission.cid(player) : U32}
  for +name: {S.Sessions.name(state) == C.Connections.player_name(player) : List<&2,Char>}
  C.Connections.Present<player,states>

def Rebinding.repid_present(player,states,state,inside,positive,cid,name):
  match state:
    case S.Sessions.State{connection,phase,old,label}: C.Connections.Present{S.Sessions.State{connection,phase,P.Players.id(player),label},inside,positive,cid,{==},name}

law Rebinding.run_present:
  for +player: P.Players.State
  for +players: List<&2,P.Players.State>
  for +states: List<&2,S.Sessions.State>
  for +inside: T.Targeting.In<player,players>
  for +reserved: Rebinding.Reserved<player,states>
  for +unique: A.Allocation.Unique(J.Admission.cids(players))
  for +nonzero: A.Allocation.Absent(0,Id.PlayerIds.project(Id.PlayerIds.Player{},players))
  C.Connections.Present<player,Rebinding.run(states,players)>

def Rebinding.run_present(player,players,states,inside,reserved,unique,nonzero):
  match reserved:
    case Rebinding.Reserved{state,member,cid,name}:
      Rebinding.repid_present(player,Rebinding.run(states,players),state,(%Rebinding.one_member(players,state,player,inside,cid,unique) : C.Connections.In<_,Rebinding.run(states,players)>; Rebinding.run_member(state,states,member,players)),Rebinding.member_positive(player,players,inside,nonzero),cid,name)

# Membership witnesses allow the recursion to retain the full lookup roster.
def Rebinding.Members(subset: List<&2,P.Players.State>,+players: List<&2,P.Players.State>) -> Data:
  match subset:
    case Nil{}: Unit
    case Con{head,rest}: Sigma<&2,&2,T.Targeting.In<head,players>,(first => Rebinding.Members(rest,players))>

law Rebinding.members_weaken:
  for +subset: List<&2,P.Players.State>
  for +head: P.Players.State
  for +players: List<&2,P.Players.State>
  for +members: Rebinding.Members(subset,players)
  Rebinding.Members(subset,Con{head,players})

def Rebinding.members_weaken(subset,head,players,members):
  match subset:
    case Nil{}: Unit{}
    case Con{first,rest}:
      match members:
        case Tuple{inside,later}: Tuple{T.Targeting.There{head,players,{==},inside},Rebinding.members_weaken(rest,head,players,later)}

law Rebinding.members_self:
  for +players: List<&2,P.Players.State>
  Rebinding.Members(players,players)

def Rebinding.members_self(players):
  match players:
    case Nil{}: Unit{}
    case Con{head,rest}: Tuple{T.Targeting.Here{rest,{==}},Rebinding.members_weaken(rest,head,rest,Rebinding.members_self(rest))}

law Rebinding.run_covers:
  for +subset: List<&2,P.Players.State>
  for +players: List<&2,P.Players.State>
  for +states: List<&2,S.Sessions.State>
  for +members: Rebinding.Members(subset,players)
  for +reservations: Rebinding.Reservations(states,subset)
  for +unique: A.Allocation.Unique(J.Admission.cids(players))
  for +nonzero: A.Allocation.Absent(0,Id.PlayerIds.project(Id.PlayerIds.Player{},players))
  C.Connections.Covers(Rebinding.run(states,players),subset)

def Rebinding.run_covers(subset,players,states,members,reservations,unique,nonzero):
  match subset:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match members:
        case Tuple{first,later}:
          match reservations:
            case Tuple{reserved,tail}: Tuple{Rebinding.run_present(head,players,states,first,reserved,unique,nonzero),Rebinding.run_covers(rest,players,states,later,tail,unique,nonzero)}

law Rebinding.run_ok:
  for +players: List<&2,P.Players.State>
  for +states: List<&2,S.Sessions.State>
  for +targets: Rebinding.Targets(players,states)
  for +reservations: Rebinding.Reservations(states,players)
  for +unique_players: A.Allocation.Unique(J.Admission.cids(players))
  for +nonzero: A.Allocation.Absent(0,Id.PlayerIds.project(Id.PlayerIds.Player{},players))
  for +valid: C.Connections.All(states)
  for +unique_states: A.Allocation.Unique(C.Connections.cids(states))
  C.Connections.OK<players,Rebinding.run(states,players)>

def Rebinding.run_ok(players,states,targets,reservations,unique_players,nonzero,valid,unique_states):
  C.Connections.OK{Rebinding.run_all(states,players,targets,unique_players,nonzero,valid),Rebinding.run_unique(states,players,unique_states),Rebinding.run_links(states,players,targets,unique_players,nonzero),Rebinding.run_covers(players,players,states,Rebinding.members_self(players),reservations,unique_players,nonzero)}

law Rebinding.one_same:
  for +players: List<&2,P.Players.State>
  for +state: S.Sessions.State
  for +linked: C.Connections.Link<players,state>
  for +unique: A.Allocation.Unique(J.Admission.cids(players))
  {Rebinding.one(players,state) == state : S.Sessions.State}

def Rebinding.one_same(players,state,linked,unique):
  match linked:
    case C.Connections.Waiting{zero,absent}: Rebinding.one_absent(players,state,absent)
    case C.Connections.Playing{player,inside,positive,cid,pid,name}:
      Equal.trans(S.Sessions.State,Rebinding.one(players,state),Rebinding.repid(state,P.Players.id(player)),state,Rebinding.one_member(players,state,player,inside,cid,unique),(%pid : {Rebinding.repid(state,_) == state : S.Sessions.State}; Rebinding.repid_same(state)))

law Rebinding.run_same:
  for +states: List<&2,S.Sessions.State>
  for +players: List<&2,P.Players.State>
  for +linked: C.Connections.Links(players,states)
  for +unique: A.Allocation.Unique(J.Admission.cids(players))
  {Rebinding.run(states,players) == states : List<&2,S.Sessions.State>}

def Rebinding.run_same(states,players,linked,unique):
  match states:
    case Nil{}: {==}
    case Con{head,rest}:
      match linked:
        case Tuple{first,later}:
          %Equal.sym(S.Sessions.State,Rebinding.one(players,head),head,Rebinding.one_same(players,head,first,unique)) : {Con{_,Rebinding.run(rest,players)} == Con{head,rest} : List<&2,S.Sessions.State>}
          %Rebinding.run_same(rest,players,later,unique) : {Con{head,Rebinding.run(rest,players)} == Con{head,_} : List<&2,S.Sessions.State>}
          {==}

law Rebinding.run_idempotent:
  for +states: List<&2,S.Sessions.State>
  for +players: List<&2,P.Players.State>
  for +targets: Rebinding.Targets(players,states)
  for +unique: A.Allocation.Unique(J.Admission.cids(players))
  for +nonzero: A.Allocation.Absent(0,Id.PlayerIds.project(Id.PlayerIds.Player{},players))
  {Rebinding.run(Rebinding.run(states,players),players) == Rebinding.run(states,players) : List<&2,S.Sessions.State>}

def Rebinding.run_idempotent(states,players,targets,unique,nonzero): Rebinding.run_same(Rebinding.run(states,players),players,Rebinding.run_links(states,players,targets,unique,nonzero),unique)
