# Full player-record membership, uniqueness, and deletion witnesses.
import Base
import ./players.bend as P
import ./targeting.bend as T
import ./playerids.bend as Id
import ./admission.bend as J
import ./allocation.bend as A
import ./numeric.bend as N
import ./identity.bend as I

def PlayerMembership.head(players: List<&2,P.Players.State>,fallback: P.Players.State) -> P.Players.State:
  match players:
    case Nil{}: fallback
    case Con{head,rest}: head

def PlayerMembership.tail(players: List<&2,P.Players.State>) -> List<&2,P.Players.State>:
  match players:
    case Nil{}: Nil{}
    case Con{head,rest}: rest

law PlayerMembership.cons_head:
  for +a: P.Players.State
  for +b: P.Players.State
  for +xs: List<&2,P.Players.State>
  for +ys: List<&2,P.Players.State>
  for +same: {Con{a,xs} == Con{b,ys} : List<&2,P.Players.State>}
  {a == b : P.Players.State}

def PlayerMembership.cons_head(a,b,xs,ys,same):
  %same : {a == PlayerMembership.head(_,a) : P.Players.State}
  {==}

law PlayerMembership.cons_tail:
  for +a: P.Players.State
  for +b: P.Players.State
  for +xs: List<&2,P.Players.State>
  for +ys: List<&2,P.Players.State>
  for +same: {Con{a,xs} == Con{b,ys} : List<&2,P.Players.State>}
  {xs == ys : List<&2,P.Players.State>}

def PlayerMembership.cons_tail(a,b,xs,ys,same):
  %same : {xs == PlayerMembership.tail(_) : List<&2,P.Players.State>}
  {==}

law PlayerMembership.absent_member:
  for +kind: Id.PlayerIds.Kind
  for +player: P.Players.State
  for -players: List<&2,P.Players.State>
  for +inside: T.Targeting.In<player,players>
  for +id: U32
  for +absent: A.Allocation.Absent(id,Id.PlayerIds.project(kind,players))
  {U32.is_eq(id,Id.PlayerIds.key(kind,player)) == False{} : Bool}

def PlayerMembership.absent_member(kind,player,players,inside,id,absent):
  match inside:
    case T.Targeting.Here{rest,shape}: Id.PlayerIds.absent_head(id,Id.PlayerIds.key(kind,player),Id.PlayerIds.project(kind,rest),(%shape : A.Allocation.Absent(id,Id.PlayerIds.project(kind,_)); absent))
    case T.Targeting.There{head,rest,shape,later}: PlayerMembership.absent_member(kind,player,rest,later,id,Id.PlayerIds.absent_tail(id,Id.PlayerIds.key(kind,head),Id.PlayerIds.project(kind,rest),(%shape : A.Allocation.Absent(id,Id.PlayerIds.project(kind,_)); absent)))

law PlayerMembership.eq_ne:
  for +a: U32
  for +b: U32
  for +same: {a == b : U32}
  for +different: {U32.is_eq(a,b) == False{} : Bool}
  Empty

def PlayerMembership.eq_ne(a,b,same,different):
  N.Numeric.true_ne_false((%N.Numeric.u32_eq_refl(b) : {_ == False{} : Bool}; (%same : {U32.is_eq(_,b) == False{} : Bool}; different)))

law PlayerMembership.at_head:
  for +head: P.Players.State
  for +rest: List<&2,P.Players.State>
  for +player: P.Players.State
  for +inside: T.Targeting.In<player,Con{head,rest}>
  for +absent: A.Allocation.Absent(P.Players.id(head),Id.PlayerIds.project(Id.PlayerIds.Player{},rest))
  for +same: {P.Players.id(head) == P.Players.id(player) : U32}
  {head == player : P.Players.State}

def PlayerMembership.at_head(head,rest,player,inside,absent,same):
  match inside:
    case T.Targeting.Here{tail,shape}: PlayerMembership.cons_head(head,player,rest,tail,shape)
    case T.Targeting.There{before,tail,shape,later}:
      Empty.absurd({head == player : P.Players.State},PlayerMembership.eq_ne(P.Players.id(head),P.Players.id(player),same,PlayerMembership.absent_member(Id.PlayerIds.Player{},player,rest,(%Equal.sym(List<&2,P.Players.State>,rest,tail,PlayerMembership.cons_tail(head,before,rest,tail,shape)) : T.Targeting.In<player,_>; later),P.Players.id(head),absent)))

law PlayerMembership.same_id:
  for +a: P.Players.State
  for +b: P.Players.State
  for -players: List<&2,P.Players.State>
  for +first: T.Targeting.In<a,players>
  for +second: T.Targeting.In<b,players>
  for +unique: A.Allocation.Unique(Id.PlayerIds.project(Id.PlayerIds.Player{},players))
  for +same: {P.Players.id(a) == P.Players.id(b) : U32}
  {a == b : P.Players.State}

def PlayerMembership.same_id(a,b,players,first,second,unique,same):
  match first:
    case T.Targeting.Here{rest,shape}:
      PlayerMembership.at_head(a,rest,b,(%shape : T.Targeting.In<b,_>; second),Id.PlayerIds.unique_head(P.Players.id(a),Id.PlayerIds.project(Id.PlayerIds.Player{},rest),(%shape : A.Allocation.Unique(Id.PlayerIds.project(Id.PlayerIds.Player{},_)); unique)),same)
    case T.Targeting.There{head,rest,shape,later}:
      match second:
        case T.Targeting.Here{other_rest,other_shape}:
          +equal = PlayerMembership.cons_head(head,b,rest,other_rest,Equal.trans(List<&2,P.Players.State>,Con{head,rest},players,Con{b,other_rest},Equal.sym(List<&2,P.Players.State>,players,Con{head,rest},shape),other_shape))
          Empty.absurd({a == b : P.Players.State},PlayerMembership.eq_ne(P.Players.id(head),P.Players.id(a),Equal.trans(U32,P.Players.id(head),P.Players.id(b),P.Players.id(a),Equal.cong(P.Players.State,U32,(p => P.Players.id(p)),head,b,equal),Equal.sym(U32,P.Players.id(a),P.Players.id(b),same)),PlayerMembership.absent_member(Id.PlayerIds.Player{},a,rest,later,P.Players.id(head),Id.PlayerIds.unique_head(P.Players.id(head),Id.PlayerIds.project(Id.PlayerIds.Player{},rest),(%shape : A.Allocation.Unique(Id.PlayerIds.project(Id.PlayerIds.Player{},_)); unique)))))
        case T.Targeting.There{other_head,other_rest,other_shape,other_later}:
          PlayerMembership.same_id(a,b,rest,later,(%Equal.sym(List<&2,P.Players.State>,rest,other_rest,PlayerMembership.cons_tail(head,other_head,rest,other_rest,Equal.trans(List<&2,P.Players.State>,Con{head,rest},players,Con{other_head,other_rest},Equal.sym(List<&2,P.Players.State>,players,Con{head,rest},shape),other_shape))) : T.Targeting.In<b,_>; other_later),Id.PlayerIds.unique_tail(P.Players.id(head),Id.PlayerIds.project(Id.PlayerIds.Player{},rest),(%shape : A.Allocation.Unique(Id.PlayerIds.project(Id.PlayerIds.Player{},_)); unique)),same)

law PlayerMembership.different_gate:
  for +equal: Bool
  for +a: P.Players.State
  for +b: P.Players.State
  for +players: List<&2,P.Players.State>
  for +first: T.Targeting.In<a,players>
  for +second: T.Targeting.In<b,players>
  for +unique: A.Allocation.Unique(Id.PlayerIds.project(Id.PlayerIds.Player{},players))
  for +different: {U32.is_eq(J.Admission.cid(a),J.Admission.cid(b)) == False{} : Bool}
  for +decision: {U32.is_eq(P.Players.id(a),P.Players.id(b)) == equal : Bool}
  {equal == False{} : Bool}

def PlayerMembership.different_gate(equal,a,b,players,first,second,unique,different,decision):
  match equal:
    case False{}: {==}
    case True{}:
      +same = PlayerMembership.same_id(a,b,players,first,second,unique,N.Numeric.u32_eq_sound(P.Players.id(a),P.Players.id(b),decision))
      Empty.absurd({True{} == False{} : Bool},PlayerMembership.eq_ne(J.Admission.cid(a),J.Admission.cid(b),Equal.cong(P.Players.State,U32,(p => J.Admission.cid(p)),a,b,same),different))

law PlayerMembership.different_pid:
  for +a: P.Players.State
  for +b: P.Players.State
  for +players: List<&2,P.Players.State>
  for +first: T.Targeting.In<a,players>
  for +second: T.Targeting.In<b,players>
  for +unique: A.Allocation.Unique(Id.PlayerIds.project(Id.PlayerIds.Player{},players))
  for +different: {U32.is_eq(J.Admission.cid(a),J.Admission.cid(b)) == False{} : Bool}
  {U32.is_eq(P.Players.id(a),P.Players.id(b)) == False{} : Bool}

def PlayerMembership.different_pid(a,b,players,first,second,unique,different): PlayerMembership.different_gate(U32.is_eq(P.Players.id(a),P.Players.id(b)),a,b,players,first,second,unique,different,{==})

# Erase by PID. On unique rosters this refines the server's first-match removal.
def PlayerMembership.filter_gate(matches: Bool,head: P.Players.State,rest: List<&2,P.Players.State>) -> List<&2,P.Players.State>:
  match matches:
    case True{}: rest
    case False{}: Con{head,rest}

def PlayerMembership.filter(players: List<&2,P.Players.State>,+target: U32) -> List<&2,P.Players.State>:
  match players:
    case Nil{}: Nil{}
    case Con{head,rest}:
      +head = head
      PlayerMembership.filter_gate(U32.is_eq(P.Players.id(head),target),head,PlayerMembership.filter(rest,target))

law PlayerMembership.filter_absent:
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +absent: A.Allocation.Absent(target,Id.PlayerIds.project(Id.PlayerIds.Player{},players))
  {PlayerMembership.filter(players,target) == players : List<&2,P.Players.State>}

def PlayerMembership.filter_absent(players,target,absent):
  match players:
    case Nil{}: {==}
    case Con{head,rest}:
      match absent:
        case Tuple{different,later}:
          %Equal.sym(Bool,U32.is_eq(P.Players.id(head),target),False{},I.Identity.neq_sym(target,P.Players.id(head),different)) : {PlayerMembership.filter_gate(_,head,PlayerMembership.filter(rest,target)) == Con{head,rest} : List<&2,P.Players.State>}
          %PlayerMembership.filter_absent(rest,target,later) : {Con{head,PlayerMembership.filter(rest,target)} == Con{head,_} : List<&2,P.Players.State>}
          {==}

law PlayerMembership.scan_filter:
  for +tail: List<&2,P.Players.State>
  for +head: P.Players.State
  for +matches: Bool
  for +target: U32
  for +decision: {U32.is_eq(P.Players.id(head),target) == matches : Bool}
  for +unique: A.Allocation.Unique(Id.PlayerIds.project(Id.PlayerIds.Player{},Con{head,tail}))
  {P.Players.others(P.Players.scan(tail,head,matches,target)) == PlayerMembership.filter_gate(matches,head,PlayerMembership.filter(tail,target)) : List<&2,P.Players.State>}

def PlayerMembership.scan_filter(tail,head,matches,target,decision,unique):
  match tail:
    case Nil{}:
      match matches:
        case True{}: {==}
        case False{}: {==}
    case Con{next,rest}:
      match matches:
        case True{}:
          Equal.sym(List<&2,P.Players.State>,PlayerMembership.filter(Con{next,rest},target),Con{next,rest},PlayerMembership.filter_absent(Con{next,rest},target,(%N.Numeric.u32_eq_sound(P.Players.id(head),target,decision) : A.Allocation.Absent(_,Id.PlayerIds.project(Id.PlayerIds.Player{},Con{next,rest})); Id.PlayerIds.unique_head(P.Players.id(head),Id.PlayerIds.project(Id.PlayerIds.Player{},Con{next,rest}),unique))))
        case False{}:
          %Equal.sym(List<&2,P.Players.State>,P.Players.others(P.Players.prepend(head,P.Players.scan(rest,next,U32.is_eq(P.Players.id(next),target),target))),Con{head,P.Players.others(P.Players.scan(rest,next,U32.is_eq(P.Players.id(next),target),target))},P.Players.prepend_others(head,P.Players.scan(rest,next,U32.is_eq(P.Players.id(next),target),target))) : {_ == Con{head,PlayerMembership.filter(Con{next,rest},target)} : List<&2,P.Players.State>}
          %PlayerMembership.scan_filter(rest,next,U32.is_eq(P.Players.id(next),target),target,{==},Id.PlayerIds.unique_tail(P.Players.id(head),Id.PlayerIds.project(Id.PlayerIds.Player{},Con{next,rest}),unique)) : {Con{head,P.Players.others(P.Players.scan(rest,next,U32.is_eq(P.Players.id(next),target),target))} == Con{head,_} : List<&2,P.Players.State>}
          {==}

law PlayerMembership.take_filter:
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +unique: A.Allocation.Unique(Id.PlayerIds.project(Id.PlayerIds.Player{},players))
  {P.Players.others(P.Players.take(players,target)) == PlayerMembership.filter(players,target) : List<&2,P.Players.State>}

def PlayerMembership.take_filter(players,target,unique):
  match players:
    case Nil{}: {==}
    case Con{head,rest}: PlayerMembership.scan_filter(rest,head,U32.is_eq(P.Players.id(head),target),target,{==},unique)

law PlayerMembership.filter_later:
  for +matches: Bool
  for +head: P.Players.State
  for +rest: List<&2,P.Players.State>
  for +player: P.Players.State
  for +inside: T.Targeting.In<player,rest>
  T.Targeting.In<player,PlayerMembership.filter_gate(matches,head,rest)>

def PlayerMembership.filter_later(matches,head,rest,player,inside):
  match matches:
    case True{}: inside
    case False{}: T.Targeting.There{head,rest,{==},inside}

law PlayerMembership.filter_member:
  for +player: P.Players.State
  for -players: List<&2,P.Players.State>
  for +inside: T.Targeting.In<player,players>
  for +target: U32
  for +different: {U32.is_eq(P.Players.id(player),target) == False{} : Bool}
  T.Targeting.In<player,PlayerMembership.filter(players,target)>

def PlayerMembership.filter_member(player,players,inside,target,different):
  match inside:
    case T.Targeting.Here{rest,shape}:
      %Equal.sym(List<&2,P.Players.State>,players,Con{player,rest},shape) : T.Targeting.In<player,PlayerMembership.filter(_,target)>
      %Equal.sym(Bool,U32.is_eq(P.Players.id(player),target),False{},different) : T.Targeting.In<player,PlayerMembership.filter_gate(_,player,PlayerMembership.filter(rest,target))>
      T.Targeting.Here{PlayerMembership.filter(rest,target),{==}}
    case T.Targeting.There{head,rest,shape,later}:
      %Equal.sym(List<&2,P.Players.State>,players,Con{head,rest},shape) : T.Targeting.In<player,PlayerMembership.filter(_,target)>
      PlayerMembership.filter_later(U32.is_eq(P.Players.id(head),target),head,PlayerMembership.filter(rest,target),player,PlayerMembership.filter_member(player,rest,later,target,different))

law PlayerMembership.filter_absence_gate:
  for +matches: Bool
  for +kind: Id.PlayerIds.Kind
  for +head: P.Players.State
  for +rest: List<&2,P.Players.State>
  for +id: U32
  for +different: {U32.is_eq(id,Id.PlayerIds.key(kind,head)) == False{} : Bool}
  for +absent: A.Allocation.Absent(id,Id.PlayerIds.project(kind,rest))
  A.Allocation.Absent(id,Id.PlayerIds.project(kind,PlayerMembership.filter_gate(matches,head,rest)))

def PlayerMembership.filter_absence_gate(matches,kind,head,rest,id,different,absent):
  match matches:
    case True{}: absent
    case False{}: Tuple{different,absent}

law PlayerMembership.filter_absence:
  for +players: List<&2,P.Players.State>
  for +kind: Id.PlayerIds.Kind
  for +target: U32
  for +id: U32
  for +absent: A.Allocation.Absent(id,Id.PlayerIds.project(kind,players))
  A.Allocation.Absent(id,Id.PlayerIds.project(kind,PlayerMembership.filter(players,target)))

def PlayerMembership.filter_absence(players,kind,target,id,absent):
  match players:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match absent:
        case Tuple{different,later}: PlayerMembership.filter_absence_gate(U32.is_eq(P.Players.id(head),target),kind,head,PlayerMembership.filter(rest,target),id,different,PlayerMembership.filter_absence(rest,kind,target,id,later))

law PlayerMembership.no_target_gate:
  for +matches: Bool
  for +head: P.Players.State
  for +rest: List<&2,P.Players.State>
  for +target: U32
  for +decision: {U32.is_eq(P.Players.id(head),target) == matches : Bool}
  for +absent: A.Allocation.Absent(target,Id.PlayerIds.project(Id.PlayerIds.Player{},rest))
  A.Allocation.Absent(target,Id.PlayerIds.project(Id.PlayerIds.Player{},PlayerMembership.filter_gate(matches,head,rest)))

def PlayerMembership.no_target_gate(matches,head,rest,target,decision,absent):
  match matches:
    case True{}: absent
    case False{}: Tuple{I.Identity.neq_sym(P.Players.id(head),target,decision),absent}

law PlayerMembership.filter_no_target:
  for +players: List<&2,P.Players.State>
  for +target: U32
  A.Allocation.Absent(target,Id.PlayerIds.project(Id.PlayerIds.Player{},PlayerMembership.filter(players,target)))

def PlayerMembership.filter_no_target(players,target):
  match players:
    case Nil{}: Unit{}
    case Con{head,rest}: PlayerMembership.no_target_gate(U32.is_eq(P.Players.id(head),target),head,PlayerMembership.filter(rest,target),target,{==},PlayerMembership.filter_no_target(rest,target))
