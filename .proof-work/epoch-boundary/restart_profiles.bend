# CID/name/profile correspondence across changed player IDs.
import Base
import ./rebuild.bend as Rebuild
import ./bindings.bend as B
import ./connections.bend as C
import ./sessions.bend as S
import ./players.bend as P
import ./targeting.bend as T
import ./player_membership.bend as PM
import ./playerids.bend as Id
import ./allocation.bend as A
import ./admission.bend as J
import ./numeric.bend as N
import ./rebinding.bend as R

def RestartProfiles.cid(profile: Rebuild.Rebuild.Profile) -> U32:
  match profile:
    case Rebuild.Rebuild.Profile{cid,style,name}: cid

def RestartProfiles.name(profile: Rebuild.Rebuild.Profile) -> List<&2,Char>:
  match profile:
    case Rebuild.Rebuild.Profile{cid,style,name}: name

law RestartProfiles.header_cid:
  for +player: P.Players.State
  {RestartProfiles.cid(Rebuild.Rebuild.profile(player)) == J.Admission.cid(player) : U32}
def RestartProfiles.header_cid(player): {==}

law RestartProfiles.header_name:
  for +player: P.Players.State
  {RestartProfiles.name(Rebuild.Rebuild.profile(player)) == C.Connections.player_name(player) : List<&2,Char>}
def RestartProfiles.header_name(player): {==}

type RestartProfiles.Aligned<-left: List<&2,P.Players.State>,-right: List<&2,P.Players.State>> is Data:
  RestartProfiles.Empty{ls: {left == Nil{} : List<&2,P.Players.State>},rs: {right == Nil{} : List<&2,P.Players.State>}}
  RestartProfiles.Pair{a: P.Players.State,b: P.Players.State,xs: List<&2,P.Players.State>,ys: List<&2,P.Players.State>,ls: {left == Con{a,xs} : List<&2,P.Players.State>},rs: {right == Con{b,ys} : List<&2,P.Players.State>},same: {Rebuild.Rebuild.profile(a) == Rebuild.Rebuild.profile(b) : Rebuild.Rebuild.Profile},tails: RestartProfiles.Aligned<xs,ys>}

def RestartProfiles.first(headers: List<&2,Rebuild.Rebuild.Profile>,fallback: Rebuild.Rebuild.Profile) -> Rebuild.Rebuild.Profile:
  match headers:
    case Nil{}: fallback
    case Con{head,rest}: head

def RestartProfiles.rest(headers: List<&2,Rebuild.Rebuild.Profile>) -> List<&2,Rebuild.Rebuild.Profile>:
  match headers:
    case Nil{}: Nil{}
    case Con{head,rest}: rest

def RestartProfiles.nonempty(headers: List<&2,Rebuild.Rebuild.Profile>) -> Bool:
  match headers:
    case Nil{}: False{}
    case Con{head,rest}: True{}

law RestartProfiles.nil_cons:
  for +head: Rebuild.Rebuild.Profile
  for +rest: List<&2,Rebuild.Rebuild.Profile>
  for +same: {Nil{} == Con{head,rest} : List<&2,Rebuild.Rebuild.Profile>}
  Empty

def RestartProfiles.nil_cons(head,rest,same): N.Numeric.true_ne_false((%same : {RestartProfiles.nonempty(_) == False{} : Bool}; {==}))

law RestartProfiles.heads_equal:
  for +a: Rebuild.Rebuild.Profile
  for +b: Rebuild.Rebuild.Profile
  for +xs: List<&2,Rebuild.Rebuild.Profile>
  for +ys: List<&2,Rebuild.Rebuild.Profile>
  for +same: {Con{a,xs} == Con{b,ys} : List<&2,Rebuild.Rebuild.Profile>}
  {a == b : Rebuild.Rebuild.Profile}

def RestartProfiles.heads_equal(a,b,xs,ys,same):
  %same : {a == RestartProfiles.first(_,a) : Rebuild.Rebuild.Profile}
  {==}

law RestartProfiles.tails_equal:
  for +a: Rebuild.Rebuild.Profile
  for +b: Rebuild.Rebuild.Profile
  for +xs: List<&2,Rebuild.Rebuild.Profile>
  for +ys: List<&2,Rebuild.Rebuild.Profile>
  for +same: {Con{a,xs} == Con{b,ys} : List<&2,Rebuild.Rebuild.Profile>}
  {xs == ys : List<&2,Rebuild.Rebuild.Profile>}

def RestartProfiles.tails_equal(a,b,xs,ys,same):
  %same : {xs == RestartProfiles.rest(_) : List<&2,Rebuild.Rebuild.Profile>}
  {==}

law RestartProfiles.align:
  for +left: List<&2,P.Players.State>
  for +right: List<&2,P.Players.State>
  for +same: {Rebuild.Rebuild.profiles(left) == Rebuild.Rebuild.profiles(right) : List<&2,Rebuild.Rebuild.Profile>}
  RestartProfiles.Aligned<left,right>

def RestartProfiles.align(left,right,same):
  match left:
    case Nil{}:
      match right:
        case Nil{}: RestartProfiles.Empty{{==},{==}}
        case Con{head,rest}: Empty.absurd(RestartProfiles.Aligned<Nil{},Con{head,rest}>,RestartProfiles.nil_cons(Rebuild.Rebuild.profile(head),Rebuild.Rebuild.profiles(rest),same))
    case Con{a,xs}:
      match right:
        case Nil{}: Empty.absurd(RestartProfiles.Aligned<Con{a,xs},Nil{}>,RestartProfiles.nil_cons(Rebuild.Rebuild.profile(a),Rebuild.Rebuild.profiles(xs),Equal.sym(List<&2,Rebuild.Rebuild.Profile>,Con{Rebuild.Rebuild.profile(a),Rebuild.Rebuild.profiles(xs)},Nil{},same)))
        case Con{b,ys}: RestartProfiles.Pair{a,b,xs,ys,{==},{==},RestartProfiles.heads_equal(Rebuild.Rebuild.profile(a),Rebuild.Rebuild.profile(b),Rebuild.Rebuild.profiles(xs),Rebuild.Rebuild.profiles(ys),same),RestartProfiles.align(xs,ys,RestartProfiles.tails_equal(Rebuild.Rebuild.profile(a),Rebuild.Rebuild.profile(b),Rebuild.Rebuild.profiles(xs),Rebuild.Rebuild.profiles(ys),same))}

law RestartProfiles.same_cid:
  for +left: P.Players.State
  for +right: P.Players.State
  for +same: {Rebuild.Rebuild.profile(left) == Rebuild.Rebuild.profile(right) : Rebuild.Rebuild.Profile}
  {J.Admission.cid(left) == J.Admission.cid(right) : U32}

def RestartProfiles.same_cid(left,right,same):
  %RestartProfiles.header_cid(left) : {_ == J.Admission.cid(right) : U32}
  %RestartProfiles.header_cid(right) : {RestartProfiles.cid(Rebuild.Rebuild.profile(left)) == _ : U32}
  %same : {RestartProfiles.cid(Rebuild.Rebuild.profile(left)) == RestartProfiles.cid(_) : U32}
  {==}

law RestartProfiles.same_name:
  for +left: P.Players.State
  for +right: P.Players.State
  for +same: {Rebuild.Rebuild.profile(left) == Rebuild.Rebuild.profile(right) : Rebuild.Rebuild.Profile}
  {C.Connections.player_name(left) == C.Connections.player_name(right) : List<&2,Char>}

def RestartProfiles.same_name(left,right,same):
  %RestartProfiles.header_name(left) : {_ == C.Connections.player_name(right) : List<&2,Char>}
  %RestartProfiles.header_name(right) : {RestartProfiles.name(Rebuild.Rebuild.profile(left)) == _ : List<&2,Char>}
  %same : {RestartProfiles.name(Rebuild.Rebuild.profile(left)) == RestartProfiles.name(_) : List<&2,Char>}
  {==}

type RestartProfiles.Member<-before: P.Players.State,-players: List<&2,P.Players.State>> is Data:
  RestartProfiles.Member{after: P.Players.State,inside: T.Targeting.In<after,players>,same: {Rebuild.Rebuild.profile(after) == Rebuild.Rebuild.profile(before) : Rebuild.Rebuild.Profile}}

law RestartProfiles.weaken_member:
  for +head: P.Players.State
  for +rest: List<&2,P.Players.State>
  for +player: P.Players.State
  for +member: RestartProfiles.Member<player,rest>
  RestartProfiles.Member<player,Con{head,rest}>

def RestartProfiles.weaken_member(head,rest,player,member):
  match member:
    case RestartProfiles.Member{after,inside,same}: RestartProfiles.Member{after,T.Targeting.There{head,rest,{==},inside},same}

law RestartProfiles.aligned_member:
  for +player: P.Players.State
  for -left: List<&2,P.Players.State>
  for -right: List<&2,P.Players.State>
  for +aligned: RestartProfiles.Aligned<left,right>
  for +inside: T.Targeting.In<player,right>
  RestartProfiles.Member<player,left>

def RestartProfiles.aligned_member(player,left,right,aligned,inside):
  match aligned:
    case RestartProfiles.Empty{ls,rs}: Empty.absurd(RestartProfiles.Member<player,left>,B.Bindings.nil_member(player,(%rs : T.Targeting.In<player,_>; inside)))
    case RestartProfiles.Pair{a,b,xs,ys,ls,rs,same,tails}:
      match inside:
        case T.Targeting.Here{rest,shape}:
          RestartProfiles.Member{a,T.Targeting.Here{xs,ls},Equal.trans(Rebuild.Rebuild.Profile,Rebuild.Rebuild.profile(a),Rebuild.Rebuild.profile(b),Rebuild.Rebuild.profile(player),same,Equal.cong(P.Players.State,Rebuild.Rebuild.Profile,(p => Rebuild.Rebuild.profile(p)),b,player,PM.PlayerMembership.cons_head(b,player,ys,rest,Equal.trans(List<&2,P.Players.State>,Con{b,ys},right,Con{player,rest},Equal.sym(List<&2,P.Players.State>,right,Con{b,ys},rs),shape))))}
        case T.Targeting.There{head,rest,shape,later}:
          %Equal.sym(List<&2,P.Players.State>,left,Con{a,xs},ls) : RestartProfiles.Member<player,_>
          RestartProfiles.weaken_member(a,xs,player,RestartProfiles.aligned_member(player,xs,ys,tails,(%Equal.sym(List<&2,P.Players.State>,ys,rest,PM.PlayerMembership.cons_tail(b,head,ys,rest,Equal.trans(List<&2,P.Players.State>,Con{b,ys},right,Con{head,rest},Equal.sym(List<&2,P.Players.State>,right,Con{b,ys},rs),shape))) : T.Targeting.In<player,_>; later)))

law RestartProfiles.aligned_absent:
  for -left: List<&2,P.Players.State>
  for -right: List<&2,P.Players.State>
  for +aligned: RestartProfiles.Aligned<left,right>
  for +id: U32
  for +absent: A.Allocation.Absent(id,J.Admission.cids(right))
  A.Allocation.Absent(id,J.Admission.cids(left))

def RestartProfiles.aligned_absent(left,right,aligned,id,absent):
  match aligned:
    case RestartProfiles.Empty{ls,rs}:
      %Equal.sym(List<&2,P.Players.State>,left,Nil{},ls) : A.Allocation.Absent(id,J.Admission.cids(_))
      Unit{}
    case RestartProfiles.Pair{a,b,xs,ys,ls,rs,same,tails}:
      +given = {(%rs : A.Allocation.Absent(id,J.Admission.cids(_)); absent) : A.Allocation.Absent(id,Con{J.Admission.cid(b),J.Admission.cids(ys)})}
      %Equal.sym(List<&2,P.Players.State>,left,Con{a,xs},ls) : A.Allocation.Absent(id,J.Admission.cids(_))
      Tuple{(%Equal.sym(U32,J.Admission.cid(a),J.Admission.cid(b),RestartProfiles.same_cid(a,b,same)) : {U32.is_eq(id,_) == False{} : Bool}; Id.PlayerIds.absent_head(id,J.Admission.cid(b),J.Admission.cids(ys),given)),RestartProfiles.aligned_absent(xs,ys,tails,id,Id.PlayerIds.absent_tail(id,J.Admission.cid(b),J.Admission.cids(ys),given))}


law RestartProfiles.reserved:
  for +left: P.Players.State
  for +right: P.Players.State
  for +states: List<&2,S.Sessions.State>
  for +same: {Rebuild.Rebuild.profile(left) == Rebuild.Rebuild.profile(right) : Rebuild.Rebuild.Profile}
  for +present: C.Connections.Present<right,states>
  R.Rebinding.Reserved<left,states>

def RestartProfiles.reserved(left,right,states,same,present):
  match present:
    case C.Connections.Present{session,inside,positive,cid,pid,name}:
      R.Rebinding.Reserved{session,inside,Equal.trans(U32,S.Sessions.cid(session),J.Admission.cid(right),J.Admission.cid(left),cid,Equal.sym(U32,J.Admission.cid(left),J.Admission.cid(right),RestartProfiles.same_cid(left,right,same))),Equal.trans(List<&2,Char>,S.Sessions.name(session),C.Connections.player_name(right),C.Connections.player_name(left),name,Equal.sym(List<&2,Char>,C.Connections.player_name(left),C.Connections.player_name(right),RestartProfiles.same_name(left,right,same)))}

law RestartProfiles.aligned_reservations:
  for +states: List<&2,S.Sessions.State>
  for -left: List<&2,P.Players.State>
  for -right: List<&2,P.Players.State>
  for +aligned: RestartProfiles.Aligned<left,right>
  for +covers: C.Connections.Covers(states,right)
  R.Rebinding.Reservations(states,left)

def RestartProfiles.aligned_reservations(states,left,right,aligned,covers):
  match aligned:
    case RestartProfiles.Empty{ls,rs}:
      %Equal.sym(List<&2,P.Players.State>,left,Nil{},ls) : R.Rebinding.Reservations(states,_)
      Unit{}
    case RestartProfiles.Pair{a,b,xs,ys,ls,rs,same,tails}:
      +given = {(%rs : C.Connections.Covers(states,_); covers) : C.Connections.Covers(states,Con{b,ys})}
      %Equal.sym(List<&2,P.Players.State>,left,Con{a,xs},ls) : R.Rebinding.Reservations(states,_)
      Tuple{RestartProfiles.reserved(a,b,states,same,B.Bindings.cover_head(states,b,ys,given)),RestartProfiles.aligned_reservations(states,xs,ys,tails,B.Bindings.cover_tail(states,b,ys,given))}

law RestartProfiles.playing:
  for +player: P.Players.State
  for +players: List<&2,P.Players.State>
  for +session: S.Sessions.State
  for +member: RestartProfiles.Member<player,players>
  for +positive: {U32.is_eq(S.Sessions.pid(session),0) == False{} : Bool}
  for +cid: {S.Sessions.cid(session) == J.Admission.cid(player) : U32}
  for +name: {S.Sessions.name(session) == C.Connections.player_name(player) : List<&2,Char>}
  R.Rebinding.Target<players,session>

def RestartProfiles.playing(player,players,session,member,positive,cid,name):
  match member:
    case RestartProfiles.Member{after,inside,same}: R.Rebinding.Playing{after,inside,positive,Equal.trans(U32,S.Sessions.cid(session),J.Admission.cid(player),J.Admission.cid(after),cid,Equal.sym(U32,J.Admission.cid(after),J.Admission.cid(player),RestartProfiles.same_cid(after,player,same))),Equal.trans(List<&2,Char>,S.Sessions.name(session),C.Connections.player_name(player),C.Connections.player_name(after),name,Equal.sym(List<&2,Char>,C.Connections.player_name(after),C.Connections.player_name(player),RestartProfiles.same_name(after,player,same)))}

law RestartProfiles.aligned_target:
  for +left: List<&2,P.Players.State>
  for +right: List<&2,P.Players.State>
  for +aligned: RestartProfiles.Aligned<left,right>
  for +session: S.Sessions.State
  for +linked: C.Connections.Link<right,session>
  R.Rebinding.Target<left,session>

def RestartProfiles.aligned_target(left,right,aligned,session,linked):
  match linked:
    case C.Connections.Waiting{unbound,unused}: R.Rebinding.Waiting{unbound,RestartProfiles.aligned_absent(left,right,aligned,S.Sessions.cid(session),unused)}
    case C.Connections.Playing{player,inside,positive,cid,pid,name}: RestartProfiles.playing(player,left,session,RestartProfiles.aligned_member(player,left,right,aligned,inside),positive,cid,name)

law RestartProfiles.aligned_targets:
  for +states: List<&2,S.Sessions.State>
  for +left: List<&2,P.Players.State>
  for +right: List<&2,P.Players.State>
  for +aligned: RestartProfiles.Aligned<left,right>
  for +links: C.Connections.Links(right,states)
  R.Rebinding.Targets(left,states)

def RestartProfiles.aligned_targets(states,left,right,aligned,links):
  match states:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match links:
        case Tuple{first,later}: Tuple{RestartProfiles.aligned_target(left,right,aligned,head,first),RestartProfiles.aligned_targets(rest,left,right,aligned,later)}

type RestartProfiles.Correspondence<-players: List<&2,P.Players.State>,-states: List<&2,S.Sessions.State>> is Data:
  RestartProfiles.Correspondence{targets: R.Rebinding.Targets(players,states),reservations: R.Rebinding.Reservations(states,players)}

law RestartProfiles.correspondence:
  for +left: List<&2,P.Players.State>
  for +right: List<&2,P.Players.State>
  for +states: List<&2,S.Sessions.State>
  for +same: {Rebuild.Rebuild.profiles(left) == Rebuild.Rebuild.profiles(right) : List<&2,Rebuild.Rebuild.Profile>}
  for +valid: C.Connections.OK<right,states>
  RestartProfiles.Correspondence<left,states>

def RestartProfiles.correspondence(left,right,states,same,valid):
  match valid:
    case C.Connections.OK{sessions,unique,links,covers}:
      +aligned = RestartProfiles.align(left,right,same)
      RestartProfiles.Correspondence{RestartProfiles.aligned_targets(states,left,right,aligned,links),RestartProfiles.aligned_reservations(states,left,right,aligned,covers)}
