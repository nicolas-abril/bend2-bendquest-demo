# Nonzero U32 IDs, with bounded search and no collision on wraparound.
import Base
import ./numeric.bend as N

def Allocation.Ids() -> Data: List<&2,U32>

def Allocation.length(ids: Allocation.Ids) -> Nat:
  match ids:
    case Nil{}: 0n
    case Con{head,rest}: Succ{Allocation.length(rest)}

def Allocation.contains(+id: U32,ids: Allocation.Ids) -> Bool:
  match ids:
    case Nil{}: False{}
    case Con{head,rest}: Bool.or(U32.is_eq(id,head),Allocation.contains(id,rest))

def Allocation.Absent(+id: U32,ids: Allocation.Ids) -> Data:
  match ids:
    case Nil{}: Unit
    case Con{head,rest}: Sigma<&2,&2,{U32.is_eq(id,head) == False{} : Bool},(different => Allocation.Absent(id,rest))>

def Allocation.Unique(ids: Allocation.Ids) -> Data:
  match ids:
    case Nil{}: Unit
    case Con{head,rest}: Sigma<&2,&2,Allocation.Absent(head,rest),(absent => Allocation.Unique(rest))>

def Allocation.normalize_gate(zero: Bool,id: U32) -> U32:
  match zero:
    case True{}: 1
    case False{}: id

def Allocation.normalize(+id: U32) -> U32: Allocation.normalize_gate(U32.is_eq(id,0),id)

def Allocation.next(id: U32) -> U32: Allocation.normalize(U32.add(id,1))

type Allocation.Choice is Data:
  Allocation.Choice{id: U32,next: U32}

def Allocation.id(choice: Allocation.Choice) -> U32:
  match choice:
    case Allocation.Choice{id,next}: id

def Allocation.cursor(choice: Allocation.Choice) -> U32:
  match choice:
    case Allocation.Choice{id,next}: next

def Allocation.scan(fuel: Nat,+ids: Allocation.Ids,+candidate: U32,occupied: Bool) -> Maybe<&2,Allocation.Choice>:
  match fuel:
    case Zero{}: None{}
    case Succ{rest}:
      match occupied:
        case False{}: Some{Allocation.Choice{candidate,Allocation.next(candidate)}}
        case True{}:
          +next = Allocation.next(candidate)
          Allocation.scan(rest,ids,next,Allocation.contains(next,ids))

def Allocation.find(+ids: Allocation.Ids,hint: U32) -> Maybe<&2,Allocation.Choice>:
  +candidate = Allocation.normalize(hint)
  Allocation.scan(Succ{Allocation.length(ids)},ids,candidate,Allocation.contains(candidate,ids))

type Allocation.Fresh<-ids: Allocation.Ids,-choice: Allocation.Choice> is Data:
  Allocation.Fresh{positive: {U32.is_eq(Allocation.id(choice),0) == False{} : Bool},absent: Allocation.Absent(Allocation.id(choice),ids),next_positive: {U32.is_eq(Allocation.cursor(choice),0) == False{} : Bool}}

def Allocation.Safe(+ids: Allocation.Ids,result: Maybe<&2,Allocation.Choice>) -> Data:
  match result:
    case None{}: Unit
    case Some{choice}: Allocation.Fresh<ids,choice>

law Allocation.or_false:
  for +left: Bool
  for +right: Bool
  for +given: {Bool.or(left,right) == False{} : Bool}
  Sigma<&2,&2,{left == False{} : Bool},(a => {right == False{} : Bool})>

def Allocation.or_false(left,right,given):
  match left:
    case False{}: Tuple{{==},given}
    case True{}: Empty.absurd(Sigma<&2,&2,{True{} == False{} : Bool},(a => {right == False{} : Bool})>,N.Numeric.true_ne_false(given))

def Allocation.false_left(left: Bool,right: Bool,given: Sigma<&2,&2,{left == False{} : Bool},(a => {right == False{} : Bool})>) -> {left == False{} : Bool}:
  match given:
    case Tuple{a,b}: a

def Allocation.false_right(left: Bool,right: Bool,given: Sigma<&2,&2,{left == False{} : Bool},(a => {right == False{} : Bool})>) -> {right == False{} : Bool}:
  match given:
    case Tuple{a,b}: b

law Allocation.contains_absent:
  for +ids: Allocation.Ids
  for +id: U32
  for +missing: {Allocation.contains(id,ids) == False{} : Bool}
  Allocation.Absent(id,ids)

def Allocation.contains_absent(ids,id,missing):
  match ids:
    case Nil{}: Unit{}
    case Con{head,rest}:
      +parts = Allocation.or_false(U32.is_eq(id,head),Allocation.contains(id,rest),missing)
      Tuple{Allocation.false_left(U32.is_eq(id,head),Allocation.contains(id,rest),parts),Allocation.contains_absent(rest,id,Allocation.false_right(U32.is_eq(id,head),Allocation.contains(id,rest),parts))}

law Allocation.absent_contains:
  for +ids: Allocation.Ids
  for +id: U32
  for +valid: Allocation.Absent(id,ids)
  {Allocation.contains(id,ids) == False{} : Bool}

def Allocation.absent_contains(ids,id,valid):
  match ids:
    case Nil{}: {==}
    case Con{head,rest}:
      match valid:
        case Tuple{different,tail}:
          %Equal.sym(Bool,U32.is_eq(id,head),False{},different) : {Bool.or(_,Allocation.contains(id,rest)) == False{} : Bool}
          Allocation.absent_contains(rest,id,tail)

law Allocation.normalize_gate_positive:
  for +zero: Bool
  for +id: U32
  for +decision: {U32.is_eq(id,0) == zero : Bool}
  {U32.is_eq(Allocation.normalize_gate(zero,id),0) == False{} : Bool}

def Allocation.normalize_gate_positive(zero,id,decision):
  match zero:
    case True{}: {==}
    case False{}: decision

law Allocation.normalize_positive:
  for +id: U32
  {U32.is_eq(Allocation.normalize(id),0) == False{} : Bool}

def Allocation.normalize_positive(id): Allocation.normalize_gate_positive(U32.is_eq(id,0),id,{==})

law Allocation.normalize_nonzero:
  for +id: U32
  for +positive: {U32.is_eq(id,0) == False{} : Bool}
  {Allocation.normalize(id) == id : U32}

def Allocation.normalize_nonzero(id,positive):
  %Equal.sym(Bool,U32.is_eq(id,0),False{},positive) : {Allocation.normalize_gate(_,id) == id : U32}
  {==}

law Allocation.next_positive:
  for +id: U32
  {U32.is_eq(Allocation.next(id),0) == False{} : Bool}

def Allocation.next_positive(id): Allocation.normalize_positive(U32.add(id,1))

law Allocation.wrap:
  {Allocation.next(4294967295) == 1 : U32}

def Allocation.wrap(): {==}

law Allocation.scan_safe:
  for +fuel: Nat
  for +ids: Allocation.Ids
  for +candidate: U32
  for +occupied: Bool
  for +positive: {U32.is_eq(candidate,0) == False{} : Bool}
  for +decision: {Allocation.contains(candidate,ids) == occupied : Bool}
  Allocation.Safe(ids,Allocation.scan(fuel,ids,candidate,occupied))

def Allocation.scan_safe(fuel,ids,candidate,occupied,positive,decision):
  match fuel:
    case Zero{}: Unit{}
    case Succ{rest}:
      match occupied:
        case False{}: Allocation.Fresh{positive,Allocation.contains_absent(ids,candidate,decision),Allocation.next_positive(candidate)}
        case True{}: Allocation.scan_safe(rest,ids,Allocation.next(candidate),Allocation.contains(Allocation.next(candidate),ids),Allocation.next_positive(candidate),{==})

law Allocation.find_safe:
  for +ids: Allocation.Ids
  for +hint: U32
  Allocation.Safe(ids,Allocation.find(ids,hint))

def Allocation.find_safe(ids,hint):
  Allocation.scan_safe(Succ{Allocation.length(ids)},ids,Allocation.normalize(hint),Allocation.contains(Allocation.normalize(hint),ids),Allocation.normalize_positive(hint),{==})

law Allocation.find_free:
  for +ids: Allocation.Ids
  for +hint: U32
  for +missing: {Allocation.contains(Allocation.normalize(hint),ids) == False{} : Bool}
  {Allocation.find(ids,hint) == Some{Allocation.Choice{Allocation.normalize(hint),Allocation.next(Allocation.normalize(hint))}} : Maybe<&2,Allocation.Choice>}

def Allocation.find_free(ids,hint,missing):
  %Equal.sym(Bool,Allocation.contains(Allocation.normalize(hint),ids),False{},missing) : {Allocation.scan(Succ{Allocation.length(ids)},ids,Allocation.normalize(hint),_) == Some{Allocation.Choice{Allocation.normalize(hint),Allocation.next(Allocation.normalize(hint))}} : Maybe<&2,Allocation.Choice>}
  {==}

law Allocation.extend_unique:
  for +ids: Allocation.Ids
  for +choice: Allocation.Choice
  for +fresh: Allocation.Fresh<ids,choice>
  for +valid: Allocation.Unique(ids)
  Allocation.Unique(Con{Allocation.id(choice),ids})

def Allocation.extend_unique(ids,choice,fresh,valid):
  match fresh:
    case Allocation.Fresh{positive,absent,next_positive}: Tuple{absent,valid}
