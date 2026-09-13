# Connection correspondence across reordered and updated player records.
import Base
import ./connections.bend as C
import ./sessions.bend as S
import ./players.bend as P
import ./targeting.bend as T
import ./player_membership.bend as PM
import ./playerids.bend as Id
import ./allocation.bend as A
import ./admission.bend as J
import ./numeric.bend as N

law Bindings.head_member:
  for +session: P.Players.State
  for +head: P.Players.State
  for +rest: List<&2,P.Players.State>
  for +equal: {head == session : P.Players.State}
  T.Targeting.In<session,Con{head,rest}>

def Bindings.head_member(session,head,rest,equal):
  %equal : T.Targeting.In<_,Con{head,rest}>
  T.Targeting.Here{rest,{==}}

law Bindings.swap_later:
  for +session: P.Players.State
  for +first: P.Players.State
  for +second: P.Players.State
  for +rest: List<&2,P.Players.State>
  for +inside: T.Targeting.In<session,Con{first,rest}>
  T.Targeting.In<session,Con{first,Con{second,rest}}>

def Bindings.swap_later(session,first,second,rest,inside):
  match inside:
    case T.Targeting.Here{tail,shape}: Bindings.head_member(session,first,Con{second,rest},PM.PlayerMembership.cons_head(first,session,rest,tail,shape))
    case T.Targeting.There{head,tail,shape,later}:
      T.Targeting.There{first,Con{second,rest},{==},T.Targeting.There{second,rest,{==},(%Equal.sym(List<&2,P.Players.State>,rest,tail,PM.PlayerMembership.cons_tail(first,head,rest,tail,shape)) : T.Targeting.In<session,_>; later)}}

law Bindings.swap_member:
  for +session: P.Players.State
  for +first: P.Players.State
  for +second: P.Players.State
  for +rest: List<&2,P.Players.State>
  for +inside: T.Targeting.In<session,Con{second,Con{first,rest}}>
  T.Targeting.In<session,Con{first,Con{second,rest}}>

def Bindings.swap_member(session,first,second,rest,inside):
  match inside:
    case T.Targeting.Here{tail,shape}: T.Targeting.There{first,Con{second,rest},{==},Bindings.head_member(session,second,rest,PM.PlayerMembership.cons_head(second,session,Con{first,rest},tail,shape))}
    case T.Targeting.There{head,tail,shape,later}: Bindings.swap_later(session,first,second,rest,(%Equal.sym(List<&2,P.Players.State>,Con{first,rest},tail,PM.PlayerMembership.cons_tail(second,head,Con{first,rest},tail,shape)) : T.Targeting.In<session,_>; later))

law Bindings.perm_member:
  for +session: P.Players.State
  for -left: List<&2,P.Players.State>
  for -right: List<&2,P.Players.State>
  for +permutation: P.Players.Perm<left,right>
  for +inside: T.Targeting.In<session,right>
  T.Targeting.In<session,left>

def Bindings.perm_member(session,left,right,permutation,inside):
  match permutation:
    case P.Players.Same{equal}:
      %Equal.sym(List<&2,P.Players.State>,left,right,equal) : T.Targeting.In<session,_>
      inside
    case P.Players.Common{head,lt,rt,ls,rs,tails}:
      match inside:
        case T.Targeting.Here{rest,shape}:
          %Equal.sym(List<&2,P.Players.State>,left,Con{head,lt},ls) : T.Targeting.In<session,_>
          Bindings.head_member(session,head,lt,PM.PlayerMembership.cons_head(head,session,rt,rest,Equal.trans(List<&2,P.Players.State>,Con{head,rt},right,Con{session,rest},Equal.sym(List<&2,P.Players.State>,right,Con{head,rt},rs),shape)))
        case T.Targeting.There{before,rest,shape,later}:
          %Equal.sym(List<&2,P.Players.State>,left,Con{head,lt},ls) : T.Targeting.In<session,_>
          T.Targeting.There{head,lt,{==},Bindings.perm_member(session,lt,rt,tails,(%Equal.sym(List<&2,P.Players.State>,rt,rest,PM.PlayerMembership.cons_tail(head,before,rt,rest,Equal.trans(List<&2,P.Players.State>,Con{head,rt},right,Con{before,rest},Equal.sym(List<&2,P.Players.State>,right,Con{head,rt},rs),shape))) : T.Targeting.In<session,_>; later))}
    case P.Players.Swap{first,second,rest,ls,rs}:
      %Equal.sym(List<&2,P.Players.State>,left,Con{first,Con{second,rest}},ls) : T.Targeting.In<session,_>
      Bindings.swap_member(session,first,second,rest,(%rs : T.Targeting.In<session,_>; inside))
    case P.Players.Then{middle,before,after}: Bindings.perm_member(session,left,middle,before,Bindings.perm_member(session,middle,right,after,inside))


law Bindings.perm_link:
  for +left: List<&2,P.Players.State>
  for +right: List<&2,P.Players.State>
  for +permutation: P.Players.Perm<left,right>
  for +session: S.Sessions.State
  for +valid: C.Connections.Link<right,session>
  C.Connections.Link<left,session>

def Bindings.perm_link(left,right,permutation,session,valid):
  match valid:
    case C.Connections.Waiting{unbound,unused}:
      C.Connections.Waiting{unbound,(%Id.PlayerIds.connection_projection(left) : A.Allocation.Absent(S.Sessions.cid(session),_); Id.PlayerIds.perm_absent(Id.PlayerIds.Connection{},left,right,permutation,S.Sessions.cid(session),(%Equal.sym(A.Allocation.Ids,Id.PlayerIds.project(Id.PlayerIds.Connection{},right),J.Admission.cids(right),Id.PlayerIds.connection_projection(right)) : A.Allocation.Absent(S.Sessions.cid(session),_); unused)))}
    case C.Connections.Playing{player,inside,positive,cid,pid,name}: C.Connections.Playing{player,Bindings.perm_member(player,left,right,permutation,inside),positive,cid,pid,name}

law Bindings.perm_links:
  for +states: List<&2,S.Sessions.State>
  for +left: List<&2,P.Players.State>
  for +right: List<&2,P.Players.State>
  for +permutation: P.Players.Perm<left,right>
  for +valid: C.Connections.Links(right,states)
  C.Connections.Links(left,states)

def Bindings.perm_links(states,left,right,permutation,valid):
  match states:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match valid:
        case Tuple{first,later}: Tuple{Bindings.perm_link(left,right,permutation,head,first),Bindings.perm_links(rest,left,right,permutation,later)}

def Bindings.cover_head(states: List<&2,S.Sessions.State>,head: P.Players.State,rest: List<&2,P.Players.State>,valid: C.Connections.Covers(states,Con{head,rest})) -> C.Connections.Present<head,states>:
  match valid:
    case Tuple{first,later}: first

def Bindings.cover_tail(states: List<&2,S.Sessions.State>,head: P.Players.State,rest: List<&2,P.Players.State>,valid: C.Connections.Covers(states,Con{head,rest})) -> C.Connections.Covers(states,rest):
  match valid:
    case Tuple{first,later}: later

law Bindings.swap_covers:
  for +states: List<&2,S.Sessions.State>
  for +first: P.Players.State
  for +second: P.Players.State
  for +rest: List<&2,P.Players.State>
  for +valid: C.Connections.Covers(states,Con{first,Con{second,rest}})
  C.Connections.Covers(states,Con{second,Con{first,rest}})

def Bindings.swap_covers(states,first,second,rest,valid):
  match valid:
    case Tuple{a,later}:
      match later:
        case Tuple{b,tail}: Tuple{b,Tuple{a,tail}}

law Bindings.perm_covers:
  for +states: List<&2,S.Sessions.State>
  for -left: List<&2,P.Players.State>
  for -right: List<&2,P.Players.State>
  for +permutation: P.Players.Perm<left,right>
  for +valid: C.Connections.Covers(states,right)
  C.Connections.Covers(states,left)

def Bindings.perm_covers(states,left,right,permutation,valid):
  match permutation:
    case P.Players.Same{equal}:
      %Equal.sym(List<&2,P.Players.State>,left,right,equal) : C.Connections.Covers(states,_)
      valid
    case P.Players.Common{head,lt,rt,ls,rs,tails}:
      +given = {(%rs : C.Connections.Covers(states,_); valid) : C.Connections.Covers(states,Con{head,rt})}
      %Equal.sym(List<&2,P.Players.State>,left,Con{head,lt},ls) : C.Connections.Covers(states,_)
      Tuple{Bindings.cover_head(states,head,rt,given),Bindings.perm_covers(states,lt,rt,tails,Bindings.cover_tail(states,head,rt,given))}
    case P.Players.Swap{first,second,rest,ls,rs}:
      %Equal.sym(List<&2,P.Players.State>,left,Con{first,Con{second,rest}},ls) : C.Connections.Covers(states,_)
      Bindings.swap_covers(states,second,first,rest,(%rs : C.Connections.Covers(states,_); valid))
    case P.Players.Then{middle,before,after}: Bindings.perm_covers(states,left,middle,before,Bindings.perm_covers(states,middle,right,after,valid))

law Bindings.perm_ok:
  for +states: List<&2,S.Sessions.State>
  for +left: List<&2,P.Players.State>
  for +right: List<&2,P.Players.State>
  for +permutation: P.Players.Perm<left,right>
  for +valid: C.Connections.OK<right,states>
  C.Connections.OK<left,states>

def Bindings.perm_ok(states,left,right,permutation,valid):
  match valid:
    case C.Connections.OK{sessions,unique,links,covers}: C.Connections.OK{sessions,unique,Bindings.perm_links(states,left,right,permutation,links),Bindings.perm_covers(states,left,right,permutation,covers)}

# Binding equality intentionally permits every non-identity field to change.
type Bindings.Header is Data:
  Bindings.Header{pid: U32,cid: U32,name: List<&2,Char>}

def Bindings.header(player: P.Players.State) -> Bindings.Header:
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
      match meta:
        case P.Players.Meta{score,kills,found,name}: Bindings.Header{pid,cid,name}

def Bindings.pid(header: Bindings.Header) -> U32:
  match header:
    case Bindings.Header{pid,cid,name}: pid

def Bindings.cid(header: Bindings.Header) -> U32:
  match header:
    case Bindings.Header{pid,cid,name}: cid

def Bindings.name(header: Bindings.Header) -> List<&2,Char>:
  match header:
    case Bindings.Header{pid,cid,name}: name

law Bindings.header_pid:
  for +player: P.Players.State
  {Bindings.pid(Bindings.header(player)) == P.Players.id(player) : U32}

def Bindings.header_pid(player):
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
      match meta:
        case P.Players.Meta{score,kills,found,name}: {==}

law Bindings.header_cid:
  for +player: P.Players.State
  {Bindings.cid(Bindings.header(player)) == J.Admission.cid(player) : U32}

def Bindings.header_cid(player):
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
      match meta:
        case P.Players.Meta{score,kills,found,name}: {==}

law Bindings.header_name:
  for +player: P.Players.State
  {Bindings.name(Bindings.header(player)) == C.Connections.player_name(player) : List<&2,Char>}

def Bindings.header_name(player):
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
      match meta:
        case P.Players.Meta{score,kills,found,name}: {==}

def Bindings.headers(players: List<&2,P.Players.State>) -> List<&2,Bindings.Header>:
  match players:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{Bindings.header(head),Bindings.headers(rest)}

# This witness is structural; no lookup or identity equality is assumed.
type Bindings.Aligned<-left: List<&2,P.Players.State>,-right: List<&2,P.Players.State>> is Data:
  Bindings.Empty{ls: {left == Nil{} : List<&2,P.Players.State>},rs: {right == Nil{} : List<&2,P.Players.State>}}
  Bindings.Pair{a: P.Players.State,b: P.Players.State,xs: List<&2,P.Players.State>,ys: List<&2,P.Players.State>,ls: {left == Con{a,xs} : List<&2,P.Players.State>},rs: {right == Con{b,ys} : List<&2,P.Players.State>},same: {Bindings.header(a) == Bindings.header(b) : Bindings.Header},tails: Bindings.Aligned<xs,ys>}

def Bindings.first(headers: List<&2,Bindings.Header>,fallback: Bindings.Header) -> Bindings.Header:
  match headers:
    case Nil{}: fallback
    case Con{head,rest}: head

def Bindings.rest(headers: List<&2,Bindings.Header>) -> List<&2,Bindings.Header>:
  match headers:
    case Nil{}: Nil{}
    case Con{head,rest}: rest

def Bindings.nonempty(headers: List<&2,Bindings.Header>) -> Bool:
  match headers:
    case Nil{}: False{}
    case Con{head,rest}: True{}

law Bindings.nil_cons:
  for +head: Bindings.Header
  for +rest: List<&2,Bindings.Header>
  for +same: {Nil{} == Con{head,rest} : List<&2,Bindings.Header>}
  Empty

def Bindings.nil_cons(head,rest,same): N.Numeric.true_ne_false((%same : {Bindings.nonempty(_) == False{} : Bool}; {==}))

law Bindings.heads_equal:
  for +a: Bindings.Header
  for +b: Bindings.Header
  for +xs: List<&2,Bindings.Header>
  for +ys: List<&2,Bindings.Header>
  for +same: {Con{a,xs} == Con{b,ys} : List<&2,Bindings.Header>}
  {a == b : Bindings.Header}

def Bindings.heads_equal(a,b,xs,ys,same):
  %same : {a == Bindings.first(_,a) : Bindings.Header}
  {==}

law Bindings.tails_equal:
  for +a: Bindings.Header
  for +b: Bindings.Header
  for +xs: List<&2,Bindings.Header>
  for +ys: List<&2,Bindings.Header>
  for +same: {Con{a,xs} == Con{b,ys} : List<&2,Bindings.Header>}
  {xs == ys : List<&2,Bindings.Header>}

def Bindings.tails_equal(a,b,xs,ys,same):
  %same : {xs == Bindings.rest(_) : List<&2,Bindings.Header>}
  {==}

law Bindings.align:
  for +left: List<&2,P.Players.State>
  for +right: List<&2,P.Players.State>
  for +same: {Bindings.headers(left) == Bindings.headers(right) : List<&2,Bindings.Header>}
  Bindings.Aligned<left,right>

def Bindings.align(left,right,same):
  match left:
    case Nil{}:
      match right:
        case Nil{}: Bindings.Empty{{==},{==}}
        case Con{head,rest}: Empty.absurd(Bindings.Aligned<Nil{},Con{head,rest}>,Bindings.nil_cons(Bindings.header(head),Bindings.headers(rest),same))
    case Con{a,xs}:
      match right:
        case Nil{}: Empty.absurd(Bindings.Aligned<Con{a,xs},Nil{}>,Bindings.nil_cons(Bindings.header(a),Bindings.headers(xs),Equal.sym(List<&2,Bindings.Header>,Con{Bindings.header(a),Bindings.headers(xs)},Nil{},same)))
        case Con{b,ys}: Bindings.Pair{a,b,xs,ys,{==},{==},Bindings.heads_equal(Bindings.header(a),Bindings.header(b),Bindings.headers(xs),Bindings.headers(ys),same),Bindings.align(xs,ys,Bindings.tails_equal(Bindings.header(a),Bindings.header(b),Bindings.headers(xs),Bindings.headers(ys),same))}

law Bindings.same_pid:
  for +left: P.Players.State
  for +right: P.Players.State
  for +same: {Bindings.header(left) == Bindings.header(right) : Bindings.Header}
  {P.Players.id(left) == P.Players.id(right) : U32}

def Bindings.same_pid(left,right,same):
  %Bindings.header_pid(left) : {_ == P.Players.id(right) : U32}
  %Bindings.header_pid(right) : {Bindings.pid(Bindings.header(left)) == _ : U32}
  %same : {Bindings.pid(Bindings.header(left)) == Bindings.pid(_) : U32}
  {==}

law Bindings.same_cid:
  for +left: P.Players.State
  for +right: P.Players.State
  for +same: {Bindings.header(left) == Bindings.header(right) : Bindings.Header}
  {J.Admission.cid(left) == J.Admission.cid(right) : U32}

def Bindings.same_cid(left,right,same):
  %Bindings.header_cid(left) : {_ == J.Admission.cid(right) : U32}
  %Bindings.header_cid(right) : {Bindings.cid(Bindings.header(left)) == _ : U32}
  %same : {Bindings.cid(Bindings.header(left)) == Bindings.cid(_) : U32}
  {==}

law Bindings.same_name:
  for +left: P.Players.State
  for +right: P.Players.State
  for +same: {Bindings.header(left) == Bindings.header(right) : Bindings.Header}
  {C.Connections.player_name(left) == C.Connections.player_name(right) : List<&2,Char>}

def Bindings.same_name(left,right,same):
  %Bindings.header_name(left) : {_ == C.Connections.player_name(right) : List<&2,Char>}
  %Bindings.header_name(right) : {Bindings.name(Bindings.header(left)) == _ : List<&2,Char>}
  %same : {Bindings.name(Bindings.header(left)) == Bindings.name(_) : List<&2,Char>}
  {==}

law Bindings.nil_player:
  for +head: P.Players.State
  for +rest: List<&2,P.Players.State>
  for +same: {Nil{} == Con{head,rest} : List<&2,P.Players.State>}
  Empty

def Bindings.nil_player(head,rest,same): Bindings.nil_cons(Bindings.header(head),Bindings.headers(rest),Equal.cong(List<&2,P.Players.State>,List<&2,Bindings.Header>,(players => Bindings.headers(players)),Nil{},Con{head,rest},same))

law Bindings.nil_member:
  for +player: P.Players.State
  for +inside: T.Targeting.In<player,Nil{}>
  Empty

def Bindings.nil_member(player,inside):
  match inside:
    case T.Targeting.Here{rest,shape}: Bindings.nil_player(player,rest,shape)
    case T.Targeting.There{head,rest,shape,later}: Bindings.nil_player(head,rest,shape)

type Bindings.Member<-before: P.Players.State,-players: List<&2,P.Players.State>> is Data:
  Bindings.Member{after: P.Players.State,inside: T.Targeting.In<after,players>,same: {Bindings.header(after) == Bindings.header(before) : Bindings.Header}}

law Bindings.weaken_member:
  for +head: P.Players.State
  for +rest: List<&2,P.Players.State>
  for +player: P.Players.State
  for +member: Bindings.Member<player,rest>
  Bindings.Member<player,Con{head,rest}>

def Bindings.weaken_member(head,rest,player,member):
  match member:
    case Bindings.Member{after,inside,same}: Bindings.Member{after,T.Targeting.There{head,rest,{==},inside},same}

law Bindings.aligned_member:
  for +player: P.Players.State
  for -left: List<&2,P.Players.State>
  for -right: List<&2,P.Players.State>
  for +aligned: Bindings.Aligned<left,right>
  for +inside: T.Targeting.In<player,right>
  Bindings.Member<player,left>

def Bindings.aligned_member(player,left,right,aligned,inside):
  match aligned:
    case Bindings.Empty{ls,rs}: Empty.absurd(Bindings.Member<player,left>,Bindings.nil_member(player,(%rs : T.Targeting.In<player,_>; inside)))
    case Bindings.Pair{a,b,xs,ys,ls,rs,same,tails}:
      match inside:
        case T.Targeting.Here{rest,shape}:
          Bindings.Member{a,T.Targeting.Here{xs,ls},Equal.trans(Bindings.Header,Bindings.header(a),Bindings.header(b),Bindings.header(player),same,Equal.cong(P.Players.State,Bindings.Header,(p => Bindings.header(p)),b,player,PM.PlayerMembership.cons_head(b,player,ys,rest,Equal.trans(List<&2,P.Players.State>,Con{b,ys},right,Con{player,rest},Equal.sym(List<&2,P.Players.State>,right,Con{b,ys},rs),shape))))}
        case T.Targeting.There{head,rest,shape,later}:
          %Equal.sym(List<&2,P.Players.State>,left,Con{a,xs},ls) : Bindings.Member<player,_>
          Bindings.weaken_member(a,xs,player,Bindings.aligned_member(player,xs,ys,tails,(%Equal.sym(List<&2,P.Players.State>,ys,rest,PM.PlayerMembership.cons_tail(b,head,ys,rest,Equal.trans(List<&2,P.Players.State>,Con{b,ys},right,Con{head,rest},Equal.sym(List<&2,P.Players.State>,right,Con{b,ys},rs),shape))) : T.Targeting.In<player,_>; later)))

law Bindings.aligned_absent:
  for -left: List<&2,P.Players.State>
  for -right: List<&2,P.Players.State>
  for +aligned: Bindings.Aligned<left,right>
  for +id: U32
  for +absent: A.Allocation.Absent(id,J.Admission.cids(right))
  A.Allocation.Absent(id,J.Admission.cids(left))

def Bindings.aligned_absent(left,right,aligned,id,absent):
  match aligned:
    case Bindings.Empty{ls,rs}:
      %Equal.sym(List<&2,P.Players.State>,left,Nil{},ls) : A.Allocation.Absent(id,J.Admission.cids(_))
      Unit{}
    case Bindings.Pair{a,b,xs,ys,ls,rs,same,tails}:
      +given = {(%rs : A.Allocation.Absent(id,J.Admission.cids(_)); absent) : A.Allocation.Absent(id,Con{J.Admission.cid(b),J.Admission.cids(ys)})}
      %Equal.sym(List<&2,P.Players.State>,left,Con{a,xs},ls) : A.Allocation.Absent(id,J.Admission.cids(_))
      Tuple{(%Equal.sym(U32,J.Admission.cid(a),J.Admission.cid(b),Bindings.same_cid(a,b,same)) : {U32.is_eq(id,_) == False{} : Bool}; Id.PlayerIds.absent_head(id,J.Admission.cid(b),J.Admission.cids(ys),given)),Bindings.aligned_absent(xs,ys,tails,id,Id.PlayerIds.absent_tail(id,J.Admission.cid(b),J.Admission.cids(ys),given))}

law Bindings.present:
  for +left: P.Players.State
  for +right: P.Players.State
  for +states: List<&2,S.Sessions.State>
  for +same: {Bindings.header(left) == Bindings.header(right) : Bindings.Header}
  for +present: C.Connections.Present<right,states>
  C.Connections.Present<left,states>

def Bindings.present(left,right,states,same,present):
  match present:
    case C.Connections.Present{session,inside,positive,cid,pid,name}:
      C.Connections.Present{session,inside,positive,Equal.trans(U32,S.Sessions.cid(session),J.Admission.cid(right),J.Admission.cid(left),cid,Equal.sym(U32,J.Admission.cid(left),J.Admission.cid(right),Bindings.same_cid(left,right,same))),Equal.trans(U32,S.Sessions.pid(session),P.Players.id(right),P.Players.id(left),pid,Equal.sym(U32,P.Players.id(left),P.Players.id(right),Bindings.same_pid(left,right,same))),Equal.trans(List<&2,Char>,S.Sessions.name(session),C.Connections.player_name(right),C.Connections.player_name(left),name,Equal.sym(List<&2,Char>,C.Connections.player_name(left),C.Connections.player_name(right),Bindings.same_name(left,right,same)))}

law Bindings.aligned_covers:
  for +states: List<&2,S.Sessions.State>
  for -left: List<&2,P.Players.State>
  for -right: List<&2,P.Players.State>
  for +aligned: Bindings.Aligned<left,right>
  for +covers: C.Connections.Covers(states,right)
  C.Connections.Covers(states,left)

def Bindings.aligned_covers(states,left,right,aligned,covers):
  match aligned:
    case Bindings.Empty{ls,rs}:
      %Equal.sym(List<&2,P.Players.State>,left,Nil{},ls) : C.Connections.Covers(states,_)
      Unit{}
    case Bindings.Pair{a,b,xs,ys,ls,rs,same,tails}:
      +given = {(%rs : C.Connections.Covers(states,_); covers) : C.Connections.Covers(states,Con{b,ys})}
      %Equal.sym(List<&2,P.Players.State>,left,Con{a,xs},ls) : C.Connections.Covers(states,_)
      Tuple{Bindings.present(a,b,states,same,Bindings.cover_head(states,b,ys,given)),Bindings.aligned_covers(states,xs,ys,tails,Bindings.cover_tail(states,b,ys,given))}

law Bindings.playing:
  for +player: P.Players.State
  for +players: List<&2,P.Players.State>
  for +session: S.Sessions.State
  for +member: Bindings.Member<player,players>
  for +positive: {U32.is_eq(S.Sessions.pid(session),0) == False{} : Bool}
  for +cid: {S.Sessions.cid(session) == J.Admission.cid(player) : U32}
  for +pid: {S.Sessions.pid(session) == P.Players.id(player) : U32}
  for +name: {S.Sessions.name(session) == C.Connections.player_name(player) : List<&2,Char>}
  C.Connections.Link<players,session>

def Bindings.playing(player,players,session,member,positive,cid,pid,name):
  match member:
    case Bindings.Member{after,inside,same}: C.Connections.Playing{after,inside,positive,Equal.trans(U32,S.Sessions.cid(session),J.Admission.cid(player),J.Admission.cid(after),cid,Equal.sym(U32,J.Admission.cid(after),J.Admission.cid(player),Bindings.same_cid(after,player,same))),Equal.trans(U32,S.Sessions.pid(session),P.Players.id(player),P.Players.id(after),pid,Equal.sym(U32,P.Players.id(after),P.Players.id(player),Bindings.same_pid(after,player,same))),Equal.trans(List<&2,Char>,S.Sessions.name(session),C.Connections.player_name(player),C.Connections.player_name(after),name,Equal.sym(List<&2,Char>,C.Connections.player_name(after),C.Connections.player_name(player),Bindings.same_name(after,player,same)))}

law Bindings.aligned_link:
  for +left: List<&2,P.Players.State>
  for +right: List<&2,P.Players.State>
  for +aligned: Bindings.Aligned<left,right>
  for +session: S.Sessions.State
  for +linked: C.Connections.Link<right,session>
  C.Connections.Link<left,session>

def Bindings.aligned_link(left,right,aligned,session,linked):
  match linked:
    case C.Connections.Waiting{unbound,unused}: C.Connections.Waiting{unbound,Bindings.aligned_absent(left,right,aligned,S.Sessions.cid(session),unused)}
    case C.Connections.Playing{player,inside,positive,cid,pid,name}: Bindings.playing(player,left,session,Bindings.aligned_member(player,left,right,aligned,inside),positive,cid,pid,name)

law Bindings.aligned_links:
  for +states: List<&2,S.Sessions.State>
  for +left: List<&2,P.Players.State>
  for +right: List<&2,P.Players.State>
  for +aligned: Bindings.Aligned<left,right>
  for +links: C.Connections.Links(right,states)
  C.Connections.Links(left,states)

def Bindings.aligned_links(states,left,right,aligned,links):
  match states:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match links:
        case Tuple{first,later}: Tuple{Bindings.aligned_link(left,right,aligned,head,first),Bindings.aligned_links(rest,left,right,aligned,later)}

law Bindings.aligned_ok:
  for +states: List<&2,S.Sessions.State>
  for +left: List<&2,P.Players.State>
  for +right: List<&2,P.Players.State>
  for +aligned: Bindings.Aligned<left,right>
  for +valid: C.Connections.OK<right,states>
  C.Connections.OK<left,states>

def Bindings.aligned_ok(states,left,right,aligned,valid):
  match valid:
    case C.Connections.OK{sessions,unique,links,covers}: C.Connections.OK{sessions,unique,Bindings.aligned_links(states,left,right,aligned,links),Bindings.aligned_covers(states,left,right,aligned,covers)}

law Bindings.same_ok:
  for +states: List<&2,S.Sessions.State>
  for +left: List<&2,P.Players.State>
  for +right: List<&2,P.Players.State>
  for +same: {Bindings.headers(left) == Bindings.headers(right) : List<&2,Bindings.Header>}
  for +valid: C.Connections.OK<right,states>
  C.Connections.OK<left,states>

def Bindings.same_ok(states,left,right,same,valid): Bindings.aligned_ok(states,left,right,Bindings.align(left,right,same),valid)

type Bindings.Conserved<-before: List<&2,P.Players.State>,-after: List<&2,P.Players.State>> is Data:
  Bindings.Conserved{ordered: List<&2,P.Players.State>,permutation: P.Players.Perm<ordered,before>,headers: {Bindings.headers(after) == Bindings.headers(ordered) : List<&2,Bindings.Header>}}

law Bindings.conserved_ok:
  for +states: List<&2,S.Sessions.State>
  for +before: List<&2,P.Players.State>
  for +after: List<&2,P.Players.State>
  for +conserved: Bindings.Conserved<before,after>
  for +valid: C.Connections.OK<before,states>
  C.Connections.OK<after,states>

def Bindings.conserved_ok(states,before,after,conserved,valid):
  match conserved:
    case Bindings.Conserved{ordered,permutation,headers}: Bindings.same_ok(states,after,ordered,headers,Bindings.perm_ok(states,ordered,before,permutation,valid))
