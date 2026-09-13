# Capacity follows from distinct positive IDs; it is not a roster-size assumption.
import Base
import ./nat_cycle.bend as C
import ./nat_capacity.bend as NC
import ./word_successor.bend as W
import ./numeric.bend as N
import ./allocation.bend as A
import ./allocation_search.bend as Search
import ./allocation_complete.bend as Complete
import ./admission.bend as J
import ./admission_search.bend as AS
import ./players.bend as P
import ./simulation.bend as S
import ./game.bend as G

law IdCapacity.value_injective:
  for +a: U32
  for +b: U32
  for +same: {U32.to_nat(a) == U32.to_nat(b) : Nat}
  {a == b : U32}

def IdCapacity.value_injective(a,b,same):
  Equal.trans(U32,a,U32.from_nat(U32.to_nat(a)),b,Equal.sym(U32,U32.from_nat(U32.to_nat(a)),a,N.Numeric.u32_roundtrip(a)),Equal.trans(U32,U32.from_nat(U32.to_nat(a)),U32.from_nat(U32.to_nat(b)),b,Equal.cong(Nat,U32,(n => U32.from_nat(n)),U32.to_nat(a),U32.to_nat(b),same),N.Numeric.u32_roundtrip(b)))

law IdCapacity.different_gate:
  for +equal: Bool
  for +a: U32
  for +b: U32
  for +different: {U32.is_eq(a,b) == False{} : Bool}
  for +decision: {G.Bq.Nat.eq(U32.to_nat(a),U32.to_nat(b)) == equal : Bool}
  {equal == False{} : Bool}

def IdCapacity.different_gate(equal,a,b,different,decision):
  match equal:
    case False{}: {==}
    case True{}:
      +same = IdCapacity.value_injective(a,b,C.NatCycle.eq_sound(U32.to_nat(a),U32.to_nat(b),decision))
      Empty.absurd({True{} == False{} : Bool},N.Numeric.true_ne_false((%N.Numeric.u32_eq_refl(b) : {_ == False{} : Bool}; (%same : {U32.is_eq(_,b) == False{} : Bool}; different))))

law IdCapacity.different:
  for +a: U32
  for +b: U32
  for +different: {U32.is_eq(a,b) == False{} : Bool}
  {G.Bq.Nat.eq(U32.to_nat(a),U32.to_nat(b)) == False{} : Bool}

def IdCapacity.different(a,b,different): IdCapacity.different_gate(G.Bq.Nat.eq(U32.to_nat(a),U32.to_nat(b)),a,b,different,{==})

law IdCapacity.absent:
  for +ids: A.Allocation.Ids
  for +target: U32
  for +absent: A.Allocation.Absent(target,ids)
  C.NatCycle.Absent(U32.to_nat(target),W.WordSuccessor.decode(ids))

def IdCapacity.absent(ids,target,absent):
  match ids:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match absent:
        case Tuple{different,later}: Tuple{IdCapacity.different(target,head,different),IdCapacity.absent(rest,target,later)}

law IdCapacity.unique:
  for +ids: A.Allocation.Ids
  for +unique: A.Allocation.Unique(ids)
  C.NatCycle.Unique(W.WordSuccessor.decode(ids))

def IdCapacity.unique(ids,unique):
  match ids:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match unique:
        case Tuple{absent,later}: Tuple{IdCapacity.absent(rest,head,absent),IdCapacity.unique(rest,later)}

law IdCapacity.positive:
  for +ids: A.Allocation.Ids
  for +nonzero: A.Allocation.Absent(0,ids)
  C.NatCycle.Positive(W.WordSuccessor.decode(ids))

def IdCapacity.positive(ids,nonzero):
  match ids:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match nonzero:
        case Tuple{first,later}: Tuple{W.WordSuccessor.u32_positive_value(head,Search.AllocationSearch.neq_sym(0,head,first)),IdCapacity.positive(rest,later)}

law IdCapacity.bounded:
  for +ids: A.Allocation.Ids
  for +maximum: Nat
  for +capacity: W.WordSuccessor.Capacity<32n,maximum>
  NC.NatCapacity.Bounded(maximum,W.WordSuccessor.decode(ids))

def IdCapacity.bounded(ids,maximum,capacity):
  match ids:
    case Nil{}: Unit{}
    case Con{head,rest}: Tuple{W.WordSuccessor.u32_bound(head,maximum,capacity),IdCapacity.bounded(rest,maximum,capacity)}

law IdCapacity.decode_length:
  for +ids: A.Allocation.Ids
  {NC.NatCapacity.length(W.WordSuccessor.decode(ids)) == A.Allocation.length(ids) : Nat}

def IdCapacity.decode_length(ids):
  match ids:
    case Nil{}: {==}
    case Con{head,rest}:
      %IdCapacity.decode_length(rest) : {Succ{NC.NatCapacity.length(W.WordSuccessor.decode(rest))} == Succ{_} : Nat}
      {==}

law IdCapacity.capacity:
  for +ids: A.Allocation.Ids
  for +maximum: Nat
  for +capacity: W.WordSuccessor.Capacity<32n,maximum>
  for +unique: A.Allocation.Unique(ids)
  for +nonzero: A.Allocation.Absent(0,ids)
  {G.Bq.Nat.le(A.Allocation.length(ids),maximum) == True{} : Bool}

def IdCapacity.capacity(ids,maximum,capacity,unique,nonzero):
  %IdCapacity.decode_length(ids) : {G.Bq.Nat.le(_,maximum) == True{} : Bool}
  NC.NatCapacity.capacity(maximum,W.WordSuccessor.decode(ids),IdCapacity.positive(ids,nonzero),IdCapacity.bounded(ids,maximum,capacity),IdCapacity.unique(ids,unique))

law IdCapacity.room:
  for +ids: A.Allocation.Ids
  for +available: U32
  for +maximum: Nat
  for +capacity: W.WordSuccessor.Capacity<32n,maximum>
  for +unique: A.Allocation.Unique(ids)
  for +nonzero: A.Allocation.Absent(0,ids)
  for +positive: {U32.is_eq(available,0) == False{} : Bool}
  for +absent: A.Allocation.Absent(available,ids)
  {G.Bq.Nat.le(Succ{A.Allocation.length(ids)},maximum) == True{} : Bool}

def IdCapacity.room(ids,available,maximum,capacity,unique,nonzero,positive,absent):
  IdCapacity.capacity(Con{available,ids},maximum,capacity,Tuple{absent,unique},Tuple{Search.AllocationSearch.neq_sym(available,0,positive),nonzero})

law IdCapacity.find_from_range:
  for +range: W.WordSuccessor.Range<32n>
  for +ids: A.Allocation.Ids
  for +hint: U32
  for +available: U32
  for +unique: A.Allocation.Unique(ids)
  for +nonzero: A.Allocation.Absent(0,ids)
  for +positive: {U32.is_eq(available,0) == False{} : Bool}
  for +absent: A.Allocation.Absent(available,ids)
  Search.AllocationSearch.Success<ids,A.Allocation.find(ids,hint)>

def IdCapacity.find_from_range(range,ids,hint,available,unique,nonzero,positive,absent):
  match range:
    case W.WordSuccessor.Range{maximum,capacity}: Complete.AllocationComplete.find_complete(ids,hint,maximum,capacity,IdCapacity.room(ids,available,maximum,capacity,unique,nonzero,positive,absent))

law IdCapacity.find_available:
  for +ids: A.Allocation.Ids
  for +hint: U32
  for +available: U32
  for +unique: A.Allocation.Unique(ids)
  for +nonzero: A.Allocation.Absent(0,ids)
  for +positive: {U32.is_eq(available,0) == False{} : Bool}
  for +absent: A.Allocation.Absent(available,ids)
  Search.AllocationSearch.Success<ids,A.Allocation.find(ids,hint)>

def IdCapacity.find_available(ids,hint,available,unique,nonzero,positive,absent): IdCapacity.find_from_range(W.WordSuccessor.u32_range,ids,hint,available,unique,nonzero,positive,absent)

law IdCapacity.player_lengths:
  for +players: List<&2,P.Players.State>
  {A.Allocation.length(J.Admission.pids(players)) == A.Allocation.length(J.Admission.cids(players)) : Nat}

def IdCapacity.player_lengths(players):
  match players:
    case Nil{}: {==}
    case Con{head,rest}:
      %IdCapacity.player_lengths(rest) : {Succ{A.Allocation.length(J.Admission.pids(rest))} == Succ{_} : Nat}
      {==}

law IdCapacity.admission_from_range:
  for +range: W.WordSuccessor.Range<32n>
  for +state: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  for +unique: A.Allocation.Unique(J.Admission.cids(S.Simulation.players(state)))
  for +nonzero: A.Allocation.Absent(0,J.Admission.cids(S.Simulation.players(state)))
  for +positive: {U32.is_eq(cid,0) == False{} : Bool}
  for +absent: A.Allocation.Absent(cid,J.Admission.cids(S.Simulation.players(state)))
  AS.AdmissionSearch.Success<state,cid,style,name,J.Admission.add(state,cid,style,name)>

def IdCapacity.admission_from_range(range,state,cid,style,name,unique,nonzero,positive,absent):
  match range:
    case W.WordSuccessor.Range{maximum,capacity}:
      Complete.AllocationComplete.admission_complete(state,cid,style,name,maximum,capacity,(%Equal.sym(Nat,A.Allocation.length(J.Admission.pids(S.Simulation.players(state))),A.Allocation.length(J.Admission.cids(S.Simulation.players(state))),IdCapacity.player_lengths(S.Simulation.players(state))) : {G.Bq.Nat.le(Succ{_},maximum) == True{} : Bool}; IdCapacity.room(J.Admission.cids(S.Simulation.players(state)),cid,maximum,capacity,unique,nonzero,positive,absent)),positive,absent)

# Any new nonzero CID on a valid CID roster guarantees room for the PID search.
# No candidate-distinctness, numeric capacity, or roster-size premise remains.
law IdCapacity.admission_available:
  for +state: S.Simulation.State
  for +cid: U32
  for +style: P.Players.Style
  for +name: List<&2,Char>
  for +unique: A.Allocation.Unique(J.Admission.cids(S.Simulation.players(state)))
  for +nonzero: A.Allocation.Absent(0,J.Admission.cids(S.Simulation.players(state)))
  for +positive: {U32.is_eq(cid,0) == False{} : Bool}
  for +absent: A.Allocation.Absent(cid,J.Admission.cids(S.Simulation.players(state)))
  AS.AdmissionSearch.Success<state,cid,style,name,J.Admission.add(state,cid,style,name)>

def IdCapacity.admission_available(state,cid,style,name,unique,nonzero,positive,absent): IdCapacity.admission_from_range(W.WordSuccessor.u32_range,state,cid,style,name,unique,nonzero,positive,absent)
