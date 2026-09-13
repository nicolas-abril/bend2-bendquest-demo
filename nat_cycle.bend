# Distinct prefixes of the exact positive natural-number allocation cycle.
import Base
import ./word_successor.bend as W
import ./numeric.bend as N
import ./allocation_search.bend as Search
import ./game.bend as G

def NatCycle.Absent(+id: Nat,values: List<&2,Nat>) -> Data:
  match values:
    case Nil{}: Unit
    case Con{head,rest}: Sigma<&2,&2,{G.Bq.Nat.eq(id,head) == False{} : Bool},(different => NatCycle.Absent(id,rest))>

def NatCycle.Unique(values: List<&2,Nat>) -> Data:
  match values:
    case Nil{}: Unit
    case Con{head,rest}: Sigma<&2,&2,NatCycle.Absent(head,rest),(absent => NatCycle.Unique(rest))>

def NatCycle.Positive(values: List<&2,Nat>) -> Data:
  match values:
    case Nil{}: Unit
    case Con{head,rest}: Sigma<&2,&2,{G.Bq.Nat.le(1n,head) == True{} : Bool},(positive => NatCycle.Positive(rest))>

def NatCycle.ascending(count: Nat,+start: Nat) -> List<&2,Nat>:
  match count:
    case Zero{}: Nil{}
    case Succ{rest}: Con{start,NatCycle.ascending(rest,Succ{start})}

law NatCycle.ascending_absent:
  for +count: Nat
  for +target: Nat
  for +start: Nat
  for +below: {G.Bq.Nat.le(Succ{target},start) == True{} : Bool}
  NatCycle.Absent(target,NatCycle.ascending(count,start))

def NatCycle.ascending_absent(count,target,start,below):
  match count:
    case Zero{}: Unit{}
    case Succ{rest}: Tuple{W.WordSuccessor.nat_eq_below(target,start,below),NatCycle.ascending_absent(rest,target,Succ{start},G.Bq.le_succ_r(Succ{target},start,below))}

law NatCycle.ascending_unique:
  for +count: Nat
  for +start: Nat
  NatCycle.Unique(NatCycle.ascending(count,start))

def NatCycle.ascending_unique(count,start):
  match count:
    case Zero{}: Unit{}
    case Succ{rest}: Tuple{NatCycle.ascending_absent(rest,start,Succ{start},Search.AllocationSearch.le_refl(Succ{start})),NatCycle.ascending_unique(rest,Succ{start})}

law NatCycle.positive_add:
  for +start: Nat
  for +rest: Nat
  {G.Bq.Nat.le(Succ{start},G.Bq.Nat.add(start,Succ{rest})) == True{} : Bool}

def NatCycle.positive_add(start,rest):
  match start:
    case Zero{}: {==}
    case Succ{p}: NatCycle.positive_add(p,rest)

law NatCycle.room_drop:
  for +start: Nat
  for +rest: Nat
  for +maximum: Nat
  for +room: {G.Bq.Nat.le(G.Bq.Nat.add(start,Succ{rest}),Succ{maximum}) == True{} : Bool}
  {G.Bq.Nat.le(G.Bq.Nat.add(start,rest),maximum) == True{} : Bool}

def NatCycle.room_drop(start,rest,maximum,room):
  %G.Bq.Nat.add_succ(start,rest) : {G.Bq.Nat.le(_,Succ{maximum}) == True{} : Bool}
  room

law NatCycle.room_next:
  for +start: Nat
  for +rest: Nat
  for +maximum: Nat
  for +room: {G.Bq.Nat.le(G.Bq.Nat.add(start,Succ{rest}),Succ{maximum}) == True{} : Bool}
  {G.Bq.Nat.le(G.Bq.Nat.add(Succ{start},rest),Succ{maximum}) == True{} : Bool}

def NatCycle.room_next(start,rest,maximum,room):
  %G.Bq.Nat.add_succ(start,rest) : {G.Bq.Nat.le(_,Succ{maximum}) == True{} : Bool}
  room

law NatCycle.visits_ascending:
  for +fuel: Nat
  for +maximum: Nat
  for +start: Nat
  for +room: {G.Bq.Nat.le(G.Bq.Nat.add(start,fuel),Succ{maximum}) == True{} : Bool}
  {W.WordSuccessor.nat_visits(fuel,maximum,start) == NatCycle.ascending(fuel,start) : List<&2,Nat>}

def NatCycle.visits_ascending(fuel,maximum,start,room):
  match fuel:
    case Zero{}: {==}
    case Succ{rest}:
      match rest:
        case Zero{}: {==}
        case Succ{p}:
          +advance = W.WordSuccessor.nat_next_advance(maximum,start,N.Numeric.le_trans(Succ{start},G.Bq.Nat.add(start,Succ{p}),maximum,NatCycle.positive_add(start,p),NatCycle.room_drop(start,Succ{p},maximum,room)))
          %Equal.sym(Nat,W.WordSuccessor.nat_next(maximum,start),Succ{start},advance) : {Con{start,W.WordSuccessor.nat_visits(Succ{p},maximum,_)} == Con{start,NatCycle.ascending(Succ{p},Succ{start})} : List<&2,Nat>}
          %NatCycle.visits_ascending(Succ{p},maximum,Succ{start},NatCycle.room_next(start,Succ{p},maximum,room)) : {Con{start,W.WordSuccessor.nat_visits(Succ{p},maximum,Succ{start})} == Con{start,_} : List<&2,Nat>}
          {==}

law NatCycle.from_one:
  for +fuel: Nat
  for +maximum: Nat
  for +budget: {G.Bq.Nat.le(fuel,maximum) == True{} : Bool}
  NatCycle.Unique(W.WordSuccessor.nat_visits(fuel,maximum,1n))

def NatCycle.from_one(fuel,maximum,budget):
  %Equal.sym(List<&2,Nat>,W.WordSuccessor.nat_visits(fuel,maximum,1n),NatCycle.ascending(fuel,1n),NatCycle.visits_ascending(fuel,maximum,1n,budget)) : NatCycle.Unique(_)
  NatCycle.ascending_unique(fuel,1n)

# Successor is injective on positive inputs. Zero must be excluded because both
# zero and the endpoint would otherwise map to one.
def NatCycle.pred(n: Nat) -> Nat:
  match n:
    case Zero{}: 0n
    case Succ{p}: p

law NatCycle.succ_injective:
  for +a: Nat
  for +b: Nat
  for +same: {Succ{a} == Succ{b} : Nat}
  {a == b : Nat}

def NatCycle.succ_injective(a,b,same): Equal.cong(Nat,Nat,(n => NatCycle.pred(n)),Succ{a},Succ{b},same)

law NatCycle.eq_sound:
  for +a: Nat
  for +b: Nat
  for +same: {G.Bq.Nat.eq(a,b) == True{} : Bool}
  {a == b : Nat}

def NatCycle.eq_sound(a,b,same):
  match a:
    case Zero{}:
      match b:
        case Zero{}: {==}
        case Succ{p}: Empty.absurd({0n == Succ{p} : Nat},G.Bq.Bool.false_ne_true(same))
    case Succ{p}:
      match b:
        case Zero{}: Empty.absurd({Succ{p} == 0n : Nat},G.Bq.Bool.false_ne_true(same))
        case Succ{q}:
          %NatCycle.eq_sound(p,q,same) : {Succ{p} == Succ{_} : Nat}
          {==}

law NatCycle.zero_not_positive:
  for +value: Nat
  for +zero: {0n == value : Nat}
  for +positive: {G.Bq.Nat.le(1n,value) == True{} : Bool}
  Empty

def NatCycle.zero_not_positive(value,zero,positive):
  G.Bq.Bool.false_ne_true((%Equal.sym(Nat,0n,value,zero) : {G.Bq.Nat.le(1n,_) == True{} : Bool}; positive))

law NatCycle.injective_gate:
  for +left: Bool
  for +right: Bool
  for +maximum: Nat
  for +a: Nat
  for +b: Nat
  for +positive_a: {G.Bq.Nat.le(1n,a) == True{} : Bool}
  for +positive_b: {G.Bq.Nat.le(1n,b) == True{} : Bool}
  for +decision_a: {G.Bq.Nat.eq(a,maximum) == left : Bool}
  for +decision_b: {G.Bq.Nat.eq(b,maximum) == right : Bool}
  for +same: {W.WordSuccessor.nat_gate(left,a) == W.WordSuccessor.nat_gate(right,b) : Nat}
  {a == b : Nat}

def NatCycle.injective_gate(left,right,maximum,a,b,positive_a,positive_b,decision_a,decision_b,same):
  match left:
    case True{}:
      match right:
        case True{}: Equal.trans(Nat,a,maximum,b,NatCycle.eq_sound(a,maximum,decision_a),Equal.sym(Nat,b,maximum,NatCycle.eq_sound(b,maximum,decision_b)))
        case False{}: Empty.absurd({a == b : Nat},NatCycle.zero_not_positive(b,NatCycle.succ_injective(0n,b,same),positive_b))
    case False{}:
      match right:
        case True{}: Empty.absurd({a == b : Nat},NatCycle.zero_not_positive(a,NatCycle.succ_injective(0n,a,Equal.sym(Nat,Succ{a},1n,same)),positive_a))
        case False{}: NatCycle.succ_injective(a,b,same)

law NatCycle.next_injective:
  for +maximum: Nat
  for +a: Nat
  for +b: Nat
  for +positive_a: {G.Bq.Nat.le(1n,a) == True{} : Bool}
  for +positive_b: {G.Bq.Nat.le(1n,b) == True{} : Bool}
  for +same: {W.WordSuccessor.nat_next(maximum,a) == W.WordSuccessor.nat_next(maximum,b) : Nat}
  {a == b : Nat}

def NatCycle.next_injective(maximum,a,b,positive_a,positive_b,same): NatCycle.injective_gate(G.Bq.Nat.eq(a,maximum),G.Bq.Nat.eq(b,maximum),maximum,a,b,positive_a,positive_b,{==},{==},same)

law NatCycle.next_different_gate:
  for +equal: Bool
  for +maximum: Nat
  for +a: Nat
  for +b: Nat
  for +positive_a: {G.Bq.Nat.le(1n,a) == True{} : Bool}
  for +positive_b: {G.Bq.Nat.le(1n,b) == True{} : Bool}
  for +different: {G.Bq.Nat.eq(a,b) == False{} : Bool}
  for +decision: {G.Bq.Nat.eq(W.WordSuccessor.nat_next(maximum,a),W.WordSuccessor.nat_next(maximum,b)) == equal : Bool}
  {equal == False{} : Bool}

def NatCycle.next_different_gate(equal,maximum,a,b,positive_a,positive_b,different,decision):
  match equal:
    case False{}: {==}
    case True{}:
      +same = NatCycle.next_injective(maximum,a,b,positive_a,positive_b,NatCycle.eq_sound(W.WordSuccessor.nat_next(maximum,a),W.WordSuccessor.nat_next(maximum,b),decision))
      Empty.absurd({True{} == False{} : Bool},N.Numeric.true_ne_false((%G.Bq.Nat.eq_refl(b) : {_ == False{} : Bool}; (%same : {G.Bq.Nat.eq(_,b) == False{} : Bool}; different))))

law NatCycle.next_different:
  for +maximum: Nat
  for +a: Nat
  for +b: Nat
  for +positive_a: {G.Bq.Nat.le(1n,a) == True{} : Bool}
  for +positive_b: {G.Bq.Nat.le(1n,b) == True{} : Bool}
  for +different: {G.Bq.Nat.eq(a,b) == False{} : Bool}
  {G.Bq.Nat.eq(W.WordSuccessor.nat_next(maximum,a),W.WordSuccessor.nat_next(maximum,b)) == False{} : Bool}

def NatCycle.next_different(maximum,a,b,positive_a,positive_b,different): NatCycle.next_different_gate(G.Bq.Nat.eq(W.WordSuccessor.nat_next(maximum,a),W.WordSuccessor.nat_next(maximum,b)),maximum,a,b,positive_a,positive_b,different,{==})

def NatCycle.map_next(+maximum: Nat,values: List<&2,Nat>) -> List<&2,Nat>:
  match values:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{W.WordSuccessor.nat_next(maximum,head),NatCycle.map_next(maximum,rest)}

law NatCycle.map_absent:
  for +values: List<&2,Nat>
  for +maximum: Nat
  for +target: Nat
  for +positive: NatCycle.Positive(values)
  for +target_positive: {G.Bq.Nat.le(1n,target) == True{} : Bool}
  for +absent: NatCycle.Absent(target,values)
  NatCycle.Absent(W.WordSuccessor.nat_next(maximum,target),NatCycle.map_next(maximum,values))

def NatCycle.map_absent(values,maximum,target,positive,target_positive,absent):
  match values:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match positive:
        case Tuple{first,later}:
          match absent:
            case Tuple{different,tail}: Tuple{NatCycle.next_different(maximum,target,head,target_positive,first,different),NatCycle.map_absent(rest,maximum,target,later,target_positive,tail)}

law NatCycle.map_unique:
  for +values: List<&2,Nat>
  for +maximum: Nat
  for +positive: NatCycle.Positive(values)
  for +unique: NatCycle.Unique(values)
  NatCycle.Unique(NatCycle.map_next(maximum,values))

def NatCycle.map_unique(values,maximum,positive,unique):
  match values:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match positive:
        case Tuple{first,later}:
          match unique:
            case Tuple{absent,tail}: Tuple{NatCycle.map_absent(rest,maximum,head,later,first,absent),NatCycle.map_unique(rest,maximum,later,tail)}

law NatCycle.gate_positive:
  for +full: Bool
  for +value: Nat
  {G.Bq.Nat.le(1n,W.WordSuccessor.nat_gate(full,value)) == True{} : Bool}

def NatCycle.gate_positive(full,value):
  match full:
    case False{}: {==}
    case True{}: {==}

law NatCycle.next_positive:
  for +maximum: Nat
  for +value: Nat
  {G.Bq.Nat.le(1n,W.WordSuccessor.nat_next(maximum,value)) == True{} : Bool}

def NatCycle.next_positive(maximum,value): NatCycle.gate_positive(G.Bq.Nat.eq(value,maximum),value)

law NatCycle.visits_positive:
  for +fuel: Nat
  for +maximum: Nat
  for +candidate: Nat
  for +positive: {G.Bq.Nat.le(1n,candidate) == True{} : Bool}
  NatCycle.Positive(W.WordSuccessor.nat_visits(fuel,maximum,candidate))

def NatCycle.visits_positive(fuel,maximum,candidate,positive):
  match fuel:
    case Zero{}: Unit{}
    case Succ{rest}: Tuple{positive,NatCycle.visits_positive(rest,maximum,W.WordSuccessor.nat_next(maximum,candidate),NatCycle.next_positive(maximum,candidate))}

law NatCycle.map_visits:
  for +fuel: Nat
  for +maximum: Nat
  for +candidate: Nat
  {NatCycle.map_next(maximum,W.WordSuccessor.nat_visits(fuel,maximum,candidate)) == W.WordSuccessor.nat_visits(fuel,maximum,W.WordSuccessor.nat_next(maximum,candidate)) : List<&2,Nat>}

def NatCycle.map_visits(fuel,maximum,candidate):
  match fuel:
    case Zero{}: {==}
    case Succ{rest}:
      %NatCycle.map_visits(rest,maximum,W.WordSuccessor.nat_next(maximum,candidate)) : {Con{W.WordSuccessor.nat_next(maximum,candidate),NatCycle.map_next(maximum,W.WordSuccessor.nat_visits(rest,maximum,W.WordSuccessor.nat_next(maximum,candidate)))} == Con{W.WordSuccessor.nat_next(maximum,candidate),_} : List<&2,Nat>}
      {==}

law NatCycle.shift_unique:
  for +fuel: Nat
  for +maximum: Nat
  for +candidate: Nat
  for +positive: {G.Bq.Nat.le(1n,candidate) == True{} : Bool}
  for +unique: NatCycle.Unique(W.WordSuccessor.nat_visits(fuel,maximum,candidate))
  NatCycle.Unique(W.WordSuccessor.nat_visits(fuel,maximum,W.WordSuccessor.nat_next(maximum,candidate)))

def NatCycle.shift_unique(fuel,maximum,candidate,positive,unique):
  %NatCycle.map_visits(fuel,maximum,candidate) : NatCycle.Unique(_)
  NatCycle.map_unique(W.WordSuccessor.nat_visits(fuel,maximum,candidate),maximum,NatCycle.visits_positive(fuel,maximum,candidate,positive),unique)

# Establish the prefix at one, then shift it to each positive in-range start.
# This proves distinctness through wrap, without assuming a distinct cycle.
law NatCycle.visits_unique:
  for +candidate: Nat
  for +fuel: Nat
  for +maximum: Nat
  for +positive: {G.Bq.Nat.le(1n,candidate) == True{} : Bool}
  for +bounded: {G.Bq.Nat.le(candidate,maximum) == True{} : Bool}
  for +budget: {G.Bq.Nat.le(fuel,maximum) == True{} : Bool}
  NatCycle.Unique(W.WordSuccessor.nat_visits(fuel,maximum,candidate))

def NatCycle.visits_unique(candidate,fuel,maximum,positive,bounded,budget):
  match candidate:
    case Zero{}: Empty.absurd(NatCycle.Unique(W.WordSuccessor.nat_visits(fuel,maximum,0n)),G.Bq.Bool.false_ne_true(positive))
    case Succ{p}:
      match p:
        case Zero{}: NatCycle.from_one(fuel,maximum,budget)
        case Succ{q}:
          %W.WordSuccessor.nat_next_advance(maximum,Succ{q},bounded) : NatCycle.Unique(W.WordSuccessor.nat_visits(fuel,maximum,_))
          NatCycle.shift_unique(fuel,maximum,Succ{q},{==},NatCycle.visits_unique(Succ{q},fuel,maximum,{==},G.Bq.le_step_down(Succ{q},maximum,bounded),budget))
