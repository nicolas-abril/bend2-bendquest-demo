# Actual allocator success from available capacity, without a visit-distinctness
# premise. The capacity itself is specified by an actual full 32-bit word.
import Base
import ./nat_cycle.bend as Cycle
import ./word_successor.bend as W
import ./numeric.bend as N
import ./allocation.bend as A
import ./allocation_search.bend as Search
import ./admission_search.bend as AS
import ./admission.bend as J
import ./simulation.bend as S
import ./players.bend as P
import ./game.bend as G

law AllocationComplete.different_gate:
  for +equal: Bool
  for +a: U32
  for +b: U32
  for +different: {G.Bq.Nat.eq(U32.to_nat(a),U32.to_nat(b)) == False{} : Bool}
  for +decision: {U32.is_eq(a,b) == equal : Bool}
  {equal == False{} : Bool}

def AllocationComplete.different_gate(equal,a,b,different,decision):
  match equal:
    case False{}: {==}
    case True{}:
      +same = N.Numeric.u32_eq_sound(a,b,decision)
      Empty.absurd({True{} == False{} : Bool},N.Numeric.true_ne_false((%G.Bq.Nat.eq_refl(U32.to_nat(b)) : {_ == False{} : Bool}; (%same : {G.Bq.Nat.eq(U32.to_nat(_),U32.to_nat(b)) == False{} : Bool}; different))))

law AllocationComplete.different:
  for +a: U32
  for +b: U32
  for +different: {G.Bq.Nat.eq(U32.to_nat(a),U32.to_nat(b)) == False{} : Bool}
  {U32.is_eq(a,b) == False{} : Bool}

def AllocationComplete.different(a,b,different): AllocationComplete.different_gate(U32.is_eq(a,b),a,b,different,{==})

law AllocationComplete.absent:
  for +ids: A.Allocation.Ids
  for +target: U32
  for +absent: Cycle.NatCycle.Absent(U32.to_nat(target),W.WordSuccessor.decode(ids))
  A.Allocation.Absent(target,ids)

def AllocationComplete.absent(ids,target,absent):
  match ids:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match absent:
        case Tuple{different,later}: Tuple{AllocationComplete.different(target,head,different),AllocationComplete.absent(rest,target,later)}

law AllocationComplete.unique:
  for +ids: A.Allocation.Ids
  for +unique: Cycle.NatCycle.Unique(W.WordSuccessor.decode(ids))
  A.Allocation.Unique(ids)

def AllocationComplete.unique(ids,unique):
  match ids:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match unique:
        case Tuple{absent,later}: Tuple{AllocationComplete.absent(rest,head,absent),AllocationComplete.unique(rest,later)}

law AllocationComplete.visits_unique:
  for +fuel: Nat
  for +candidate: U32
  for +maximum: Nat
  for +capacity: W.WordSuccessor.Capacity<32n,maximum>
  for +positive: {U32.is_eq(candidate,0) == False{} : Bool}
  for +budget: {G.Bq.Nat.le(fuel,maximum) == True{} : Bool}
  A.Allocation.Unique(Search.AllocationSearch.visits(fuel,candidate))

def AllocationComplete.visits_unique(fuel,candidate,maximum,capacity,positive,budget):
  AllocationComplete.unique(Search.AllocationSearch.visits(fuel,candidate),(%Equal.sym(List<&2,Nat>,W.WordSuccessor.decode(Search.AllocationSearch.visits(fuel,candidate)),W.WordSuccessor.nat_visits(fuel,maximum,U32.to_nat(candidate)),W.WordSuccessor.visits_refine(fuel,candidate,maximum,capacity)) : Cycle.NatCycle.Unique(_); Cycle.NatCycle.visits_unique(U32.to_nat(candidate),fuel,maximum,W.WordSuccessor.u32_positive_value(candidate,positive),W.WordSuccessor.u32_bound(candidate,maximum,capacity),budget)))

law AllocationComplete.find_complete:
  for +ids: A.Allocation.Ids
  for +hint: U32
  for +maximum: Nat
  for +capacity: W.WordSuccessor.Capacity<32n,maximum>
  for +room: {G.Bq.Nat.le(Succ{A.Allocation.length(ids)},maximum) == True{} : Bool}
  Search.AllocationSearch.Success<ids,A.Allocation.find(ids,hint)>

def AllocationComplete.find_complete(ids,hint,maximum,capacity,room):
  Search.AllocationSearch.find_complete(ids,hint,AllocationComplete.visits_unique(Succ{A.Allocation.length(ids)},A.Allocation.normalize(hint),maximum,capacity,A.Allocation.normalize_positive(hint),room))

law AllocationComplete.admission_complete:
  for +state: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  for +maximum: Nat
  for +capacity: W.WordSuccessor.Capacity<32n,maximum>
  for +room: {G.Bq.Nat.le(Succ{A.Allocation.length(J.Admission.pids(S.Simulation.players(state)))},maximum) == True{} : Bool}
  for +positive: {U32.is_eq(cid,0) == False{} : Bool}
  for +absent: A.Allocation.Absent(cid,J.Admission.cids(S.Simulation.players(state)))
  AS.AdmissionSearch.Success<state,cid,style,name,J.Admission.add(state,cid,style,name)>

def AllocationComplete.admission_complete(state,cid,style,name,maximum,capacity,room,positive,absent):
  AS.AdmissionSearch.add_complete(state,cid,style,name,AllocationComplete.visits_unique(Succ{A.Allocation.length(J.Admission.pids(S.Simulation.players(state)))},A.Allocation.normalize(J.Admission.hint(S.Simulation.meta(state))),maximum,capacity,A.Allocation.normalize_positive(J.Admission.hint(S.Simulation.meta(state))),room),positive,absent)
