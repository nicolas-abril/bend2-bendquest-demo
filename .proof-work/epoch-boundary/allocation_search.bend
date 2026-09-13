# Constructive finite-search completeness for the game's actual ID allocator.
import Base
import ./allocation.bend as A
import ./numeric.bend as N
import ./game.bend as G

# First-match deletion is used only in the cardinality proof, not the allocator.
def AllocationSearch.cut_gate(equal: Bool,head: U32,rest: A.Allocation.Ids,removed: A.Allocation.Ids) -> A.Allocation.Ids:
  match equal:
    case True{}: rest
    case False{}: Con{head,removed}

def AllocationSearch.cut(+id: U32,+ids: A.Allocation.Ids) -> A.Allocation.Ids:
  match ids:
    case Nil{}: Nil{}
    case Con{head,rest}: AllocationSearch.cut_gate(U32.is_eq(id,head),head,rest,AllocationSearch.cut(id,rest))

law AllocationSearch.or_tail:
  for +head: Bool
  for +tail: Bool
  for +absent: {head == False{} : Bool}
  for +present: {Bool.or(head,tail) == True{} : Bool}
  {tail == True{} : Bool}

def AllocationSearch.or_tail(head,tail,absent,present):
  %absent : {Bool.or(_,tail) == True{} : Bool}
  present

law AllocationSearch.cut_length_gate:
  for +equal: Bool
  for +head: U32
  for +rest: A.Allocation.Ids
  for +id: U32
  for +removed: A.Allocation.Ids
  for +decision: {U32.is_eq(id,head) == equal : Bool}
  for +present: {A.Allocation.contains(id,Con{head,rest}) == True{} : Bool}
  for shorter: ({A.Allocation.contains(id,rest) == True{} : Bool} -> {Succ{A.Allocation.length(removed)} == A.Allocation.length(rest) : Nat})
  {Succ{A.Allocation.length(AllocationSearch.cut_gate(equal,head,rest,removed))} == A.Allocation.length(Con{head,rest}) : Nat}

def AllocationSearch.cut_length_gate(equal,head,rest,id,removed,decision,present,shorter):
  match equal:
    case True{}: {==}
    case False{}:
      Equal.cong(Nat,Nat,(n => Succ{n}),Succ{A.Allocation.length(removed)},A.Allocation.length(rest),shorter(AllocationSearch.or_tail(U32.is_eq(id,head),A.Allocation.contains(id,rest),decision,present)))

law AllocationSearch.cut_length:
  for +ids: A.Allocation.Ids
  for +id: U32
  for +present: {A.Allocation.contains(id,ids) == True{} : Bool}
  {Succ{A.Allocation.length(AllocationSearch.cut(id,ids))} == A.Allocation.length(ids) : Nat}

def AllocationSearch.cut_length(ids,id,present):
  match ids:
    case Nil{}: Empty.absurd({1n == 0n : Nat},G.Bq.Bool.false_ne_true(present))
    case Con{head,rest}: AllocationSearch.cut_length_gate(U32.is_eq(id,head),head,rest,id,AllocationSearch.cut(id,rest),{==},present,(inside => AllocationSearch.cut_length(rest,id,inside)))

law AllocationSearch.cut_contains_gate:
  for +equal: Bool
  for +head: U32
  for +rest: A.Allocation.Ids
  for +removed: A.Allocation.Ids
  for +id: U32
  for +query: U32
  for +different: {U32.is_eq(query,id) == False{} : Bool}
  for +decision: {U32.is_eq(id,head) == equal : Bool}
  for +tail: {A.Allocation.contains(query,removed) == A.Allocation.contains(query,rest) : Bool}
  {A.Allocation.contains(query,AllocationSearch.cut_gate(equal,head,rest,removed)) == A.Allocation.contains(query,Con{head,rest}) : Bool}

def AllocationSearch.cut_contains_gate(equal,head,rest,removed,id,query,different,decision,tail):
  match equal:
    case True{}:
      +same = N.Numeric.u32_eq_sound(id,head,decision)
      +missing = {(%same : {U32.is_eq(query,_) == False{} : Bool}; different) : {U32.is_eq(query,head) == False{} : Bool}}
      %Equal.sym(Bool,U32.is_eq(query,head),False{},missing) : {A.Allocation.contains(query,rest) == Bool.or(_,A.Allocation.contains(query,rest)) : Bool}
      {==}
    case False{}:
      %tail : {Bool.or(U32.is_eq(query,head),A.Allocation.contains(query,removed)) == Bool.or(U32.is_eq(query,head),_) : Bool}
      {==}

law AllocationSearch.cut_contains:
  for +ids: A.Allocation.Ids
  for +id: U32
  for +query: U32
  for +different: {U32.is_eq(query,id) == False{} : Bool}
  {A.Allocation.contains(query,AllocationSearch.cut(id,ids)) == A.Allocation.contains(query,ids) : Bool}

def AllocationSearch.cut_contains(ids,id,query,different):
  match ids:
    case Nil{}: {==}
    case Con{head,rest}: AllocationSearch.cut_contains_gate(U32.is_eq(id,head),head,rest,AllocationSearch.cut(id,rest),id,query,different,{==},AllocationSearch.cut_contains(rest,id,query,different))

law AllocationSearch.neq_gate:
  for +equal: Bool
  for +a: U32
  for +b: U32
  for +different: {U32.is_eq(a,b) == False{} : Bool}
  for +decision: {U32.is_eq(b,a) == equal : Bool}
  {equal == False{} : Bool}

def AllocationSearch.neq_gate(equal,a,b,different,decision):
  match equal:
    case False{}: {==}
    case True{}:
      +same = N.Numeric.u32_eq_sound(b,a,decision)
      Empty.absurd({True{} == False{} : Bool},N.Numeric.true_ne_false((%N.Numeric.u32_eq_refl(a) : {_ == False{} : Bool}; (%same : {U32.is_eq(a,_) == False{} : Bool}; different))))

law AllocationSearch.neq_sym:
  for +a: U32
  for +b: U32
  for +different: {U32.is_eq(a,b) == False{} : Bool}
  {U32.is_eq(b,a) == False{} : Bool}

def AllocationSearch.neq_sym(a,b,different): AllocationSearch.neq_gate(U32.is_eq(b,a),a,b,different,{==})

def AllocationSearch.Subset(xs: A.Allocation.Ids,+ys: A.Allocation.Ids) -> Data:
  match xs:
    case Nil{}: Unit
    case Con{head,rest}: Sigma<&2,&2,{A.Allocation.contains(head,ys) == True{} : Bool},(inside => AllocationSearch.Subset(rest,ys))>

law AllocationSearch.subset_cut:
  for +xs: A.Allocation.Ids
  for +ys: A.Allocation.Ids
  for +id: U32
  for +absent: A.Allocation.Absent(id,xs)
  for +subset: AllocationSearch.Subset(xs,ys)
  AllocationSearch.Subset(xs,AllocationSearch.cut(id,ys))

def AllocationSearch.subset_cut(xs,ys,id,absent,subset):
  match xs:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match absent:
        case Tuple{different,later_absent}:
          match subset:
            case Tuple{inside,later_subset}:
              Tuple{(%Equal.sym(Bool,A.Allocation.contains(head,AllocationSearch.cut(id,ys)),A.Allocation.contains(head,ys),AllocationSearch.cut_contains(ys,id,head,AllocationSearch.neq_sym(id,head,different))) : {_ == True{} : Bool}; inside),AllocationSearch.subset_cut(rest,ys,id,later_absent,later_subset)}

law AllocationSearch.cardinality:
  for +xs: A.Allocation.Ids
  for +ys: A.Allocation.Ids
  for +unique: A.Allocation.Unique(xs)
  for +subset: AllocationSearch.Subset(xs,ys)
  {G.Bq.Nat.le(A.Allocation.length(xs),A.Allocation.length(ys)) == True{} : Bool}

def AllocationSearch.cardinality(xs,ys,unique,subset):
  match xs:
    case Nil{}: {==}
    case Con{head,rest}:
      match unique:
        case Tuple{absent,later_unique}:
          match subset:
            case Tuple{inside,later_subset}:
              %AllocationSearch.cut_length(ys,head,inside) : {G.Bq.Nat.le(Succ{A.Allocation.length(rest)},_) == True{} : Bool}
              AllocationSearch.cardinality(rest,AllocationSearch.cut(head,ys),later_unique,AllocationSearch.subset_cut(rest,ys,head,absent,later_subset))

# The exact sequence of candidates the live scan can inspect, including wrap.
def AllocationSearch.visits(fuel: Nat,+candidate: U32) -> A.Allocation.Ids:
  match fuel:
    case Zero{}: Nil{}
    case Succ{rest}: Con{candidate,AllocationSearch.visits(rest,A.Allocation.next(candidate))}

law AllocationSearch.visits_length:
  for +fuel: Nat
  for +candidate: U32
  {A.Allocation.length(AllocationSearch.visits(fuel,candidate)) == fuel : Nat}

def AllocationSearch.visits_length(fuel,candidate):
  match fuel:
    case Zero{}: {==}
    case Succ{rest}:
      %AllocationSearch.visits_length(rest,A.Allocation.next(candidate)) : {Succ{A.Allocation.length(AllocationSearch.visits(rest,A.Allocation.next(candidate)))} == Succ{_} : Nat}
      {==}

def AllocationSearch.found(result: Maybe<&2,A.Allocation.Choice>) -> Bool:
  match result:
    case None{}: False{}
    case Some{choice}: True{}

law AllocationSearch.some_ne_none:
  for +choice: A.Allocation.Choice
  for +same: {Some{choice} == None{} : Maybe<&2,A.Allocation.Choice>}
  Empty

def AllocationSearch.some_ne_none(choice,same):
  N.Numeric.true_ne_false(Equal.cong(Maybe<&2,A.Allocation.Choice>,Bool,(r => AllocationSearch.found(r)),Some{choice},None{},same))

law AllocationSearch.failed_cover:
  for +fuel: Nat
  for +ids: A.Allocation.Ids
  for +candidate: U32
  for +occupied: Bool
  for +decision: {A.Allocation.contains(candidate,ids) == occupied : Bool}
  for +failed: {A.Allocation.scan(fuel,ids,candidate,occupied) == None{} : Maybe<&2,A.Allocation.Choice>}
  AllocationSearch.Subset(AllocationSearch.visits(fuel,candidate),ids)

def AllocationSearch.failed_cover(fuel,ids,candidate,occupied,decision,failed):
  match fuel:
    case Zero{}: Unit{}
    case Succ{rest}:
      match occupied:
        case False{}: Empty.absurd(AllocationSearch.Subset(AllocationSearch.visits(Succ{rest},candidate),ids),AllocationSearch.some_ne_none(A.Allocation.Choice{candidate,A.Allocation.next(candidate)},failed))
        case True{}: Tuple{decision,AllocationSearch.failed_cover(rest,ids,A.Allocation.next(candidate),A.Allocation.contains(A.Allocation.next(candidate),ids),{==},failed)}

law AllocationSearch.cover_failed:
  for +fuel: Nat
  for +ids: A.Allocation.Ids
  for +candidate: U32
  for +occupied: Bool
  for +decision: {A.Allocation.contains(candidate,ids) == occupied : Bool}
  for +covered: AllocationSearch.Subset(AllocationSearch.visits(fuel,candidate),ids)
  {A.Allocation.scan(fuel,ids,candidate,occupied) == None{} : Maybe<&2,A.Allocation.Choice>}

def AllocationSearch.cover_failed(fuel,ids,candidate,occupied,decision,covered):
  match fuel:
    case Zero{}: {==}
    case Succ{rest}:
      match occupied:
        case False{}:
          match covered:
            case Tuple{inside,later}:
              Empty.absurd({Some{A.Allocation.Choice{candidate,A.Allocation.next(candidate)}} == None{} : Maybe<&2,A.Allocation.Choice>},N.Numeric.true_ne_false(Equal.trans(Bool,True{},A.Allocation.contains(candidate,ids),False{},Equal.sym(Bool,A.Allocation.contains(candidate,ids),True{},inside),decision)))
        case True{}:
          match covered:
            case Tuple{inside,later}: AllocationSearch.cover_failed(rest,ids,A.Allocation.next(candidate),A.Allocation.contains(A.Allocation.next(candidate),ids),{==},later)

law AllocationSearch.failure_bound:
  for +fuel: Nat
  for +ids: A.Allocation.Ids
  for +candidate: U32
  for +occupied: Bool
  for +decision: {A.Allocation.contains(candidate,ids) == occupied : Bool}
  for +distinct: A.Allocation.Unique(AllocationSearch.visits(fuel,candidate))
  for +failed: {A.Allocation.scan(fuel,ids,candidate,occupied) == None{} : Maybe<&2,A.Allocation.Choice>}
  {G.Bq.Nat.le(fuel,A.Allocation.length(ids)) == True{} : Bool}

def AllocationSearch.failure_bound(fuel,ids,candidate,occupied,decision,distinct,failed):
  %AllocationSearch.visits_length(fuel,candidate) : {G.Bq.Nat.le(_,A.Allocation.length(ids)) == True{} : Bool}
  AllocationSearch.cardinality(AllocationSearch.visits(fuel,candidate),ids,distinct,AllocationSearch.failed_cover(fuel,ids,candidate,occupied,decision,failed))

law AllocationSearch.cannot_fail:
  for +fuel: Nat
  for +ids: A.Allocation.Ids
  for +candidate: U32
  for +occupied: Bool
  for +decision: {A.Allocation.contains(candidate,ids) == occupied : Bool}
  for +distinct: A.Allocation.Unique(AllocationSearch.visits(fuel,candidate))
  for +more: {G.Bq.Nat.le(Succ{A.Allocation.length(ids)},fuel) == True{} : Bool}
  for +failed: {A.Allocation.scan(fuel,ids,candidate,occupied) == None{} : Maybe<&2,A.Allocation.Choice>}
  Empty

def AllocationSearch.cannot_fail(fuel,ids,candidate,occupied,decision,distinct,more,failed):
  G.Bq.Bool.false_ne_true((%N.Numeric.no_self_successor(A.Allocation.length(ids)) : {_ == True{} : Bool}; N.Numeric.le_trans(Succ{A.Allocation.length(ids)},fuel,A.Allocation.length(ids),more,AllocationSearch.failure_bound(fuel,ids,candidate,occupied,decision,distinct,failed))))

# Success carries the actual returned choice and its established freshness.
type AllocationSearch.Success<-ids: A.Allocation.Ids,-result: Maybe<&2,A.Allocation.Choice>> is Data:
  AllocationSearch.Success{choice: A.Allocation.Choice,exact: {result == Some{choice} : Maybe<&2,A.Allocation.Choice>},fresh: A.Allocation.Fresh<ids,choice>}

law AllocationSearch.result_complete:
  for +result: Maybe<&2,A.Allocation.Choice>
  for +fuel: Nat
  for +ids: A.Allocation.Ids
  for +candidate: U32
  for +occupied: Bool
  for +decision: {A.Allocation.contains(candidate,ids) == occupied : Bool}
  for +distinct: A.Allocation.Unique(AllocationSearch.visits(fuel,candidate))
  for +more: {G.Bq.Nat.le(Succ{A.Allocation.length(ids)},fuel) == True{} : Bool}
  for +exact: {A.Allocation.scan(fuel,ids,candidate,occupied) == result : Maybe<&2,A.Allocation.Choice>}
  for +safe: A.Allocation.Safe(ids,result)
  AllocationSearch.Success<ids,result>

def AllocationSearch.result_complete(result,fuel,ids,candidate,occupied,decision,distinct,more,exact,safe):
  match result:
    case None{}: Empty.absurd(AllocationSearch.Success<ids,None{}>,AllocationSearch.cannot_fail(fuel,ids,candidate,occupied,decision,distinct,more,exact))
    case Some{choice}: AllocationSearch.Success{choice,{==},safe}

law AllocationSearch.scan_complete:
  for +fuel: Nat
  for +ids: A.Allocation.Ids
  for +candidate: U32
  for +occupied: Bool
  for +decision: {A.Allocation.contains(candidate,ids) == occupied : Bool}
  for +positive: {U32.is_eq(candidate,0) == False{} : Bool}
  for +distinct: A.Allocation.Unique(AllocationSearch.visits(fuel,candidate))
  for +more: {G.Bq.Nat.le(Succ{A.Allocation.length(ids)},fuel) == True{} : Bool}
  AllocationSearch.Success<ids,A.Allocation.scan(fuel,ids,candidate,occupied)>

def AllocationSearch.scan_complete(fuel,ids,candidate,occupied,decision,positive,distinct,more):
  AllocationSearch.result_complete(A.Allocation.scan(fuel,ids,candidate,occupied),fuel,ids,candidate,occupied,decision,distinct,more,{==},A.Allocation.scan_safe(fuel,ids,candidate,occupied,positive,decision))

law AllocationSearch.le_refl:
  for +n: Nat
  {G.Bq.Nat.le(n,n) == True{} : Bool}

def AllocationSearch.le_refl(n):
  match n:
    case Zero{}: {==}
    case Succ{rest}: AllocationSearch.le_refl(rest)

# This is the exact remaining word-cycle premise, not an assumed success flag.
# Its discharge for every capacity-valid roster is a separate obligation.
law AllocationSearch.find_complete:
  for +ids: A.Allocation.Ids
  for +hint: U32
  for +distinct: A.Allocation.Unique(AllocationSearch.visits(Succ{A.Allocation.length(ids)},A.Allocation.normalize(hint)))
  AllocationSearch.Success<ids,A.Allocation.find(ids,hint)>

def AllocationSearch.find_complete(ids,hint,distinct):
  AllocationSearch.scan_complete(Succ{A.Allocation.length(ids)},ids,A.Allocation.normalize(hint),A.Allocation.contains(A.Allocation.normalize(hint),ids),{==},A.Allocation.normalize_positive(hint),distinct,AllocationSearch.le_refl(Succ{A.Allocation.length(ids)}))
