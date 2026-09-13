# Cardinality of distinct positive naturals bounded by an exact capacity.
import Base
import ./nat_cycle.bend as C
import ./numeric.bend as N
import ./allocation_search.bend as Search
import ./game.bend as G

def NatCapacity.length(values: List<&2,Nat>) -> Nat:
  match values:
    case Nil{}: 0n
    case Con{head,rest}: Succ{NatCapacity.length(rest)}

def NatCapacity.Bounded(+maximum: Nat,values: List<&2,Nat>) -> Data:
  match values:
    case Nil{}: Unit
    case Con{head,rest}: Sigma<&2,&2,{G.Bq.Nat.le(head,maximum) == True{} : Bool},(bounded => NatCapacity.Bounded(maximum,rest))>

# Remove zero/one and lower every larger value by one. Positivity excludes zero;
# uniqueness permits at most one removed one, so length drops by at most one.
def NatCapacity.lower(values: List<&2,Nat>) -> List<&2,Nat>:
  match values:
    case Nil{}: Nil{}
    case Con{head,rest}:
      match head:
        case Zero{}: NatCapacity.lower(rest)
        case Succ{p}:
          match p:
            case Zero{}: NatCapacity.lower(rest)
            case Succ{q}: Con{Succ{q},NatCapacity.lower(rest)}

law NatCapacity.lower_absent:
  for +values: List<&2,Nat>
  for +target: Nat
  for +absent: C.NatCycle.Absent(Succ{target},values)
  C.NatCycle.Absent(target,NatCapacity.lower(values))

def NatCapacity.lower_absent(values,target,absent):
  match values:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match head:
        case Zero{}:
          match absent:
            case Tuple{different,later}:
              NatCapacity.lower_absent(rest,target,later)
        case Succ{p}:
          match p:
            case Zero{}:
              match absent:
                case Tuple{different,later}:
                  NatCapacity.lower_absent(rest,target,later)
            case Succ{q}:
              match absent:
                case Tuple{different,later}:
                  Tuple{different,NatCapacity.lower_absent(rest,target,later)}

law NatCapacity.lower_unique:
  for +values: List<&2,Nat>
  for +unique: C.NatCycle.Unique(values)
  C.NatCycle.Unique(NatCapacity.lower(values))

def NatCapacity.lower_unique(values,unique):
  match values:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match head:
        case Zero{}:
          match unique:
            case Tuple{absent,later}:
              NatCapacity.lower_unique(rest,later)
        case Succ{p}:
          match p:
            case Zero{}:
              match unique:
                case Tuple{absent,later}:
                  NatCapacity.lower_unique(rest,later)
            case Succ{q}:
              match unique:
                case Tuple{absent,later}:
                  Tuple{NatCapacity.lower_absent(rest,Succ{q},absent),NatCapacity.lower_unique(rest,later)}

law NatCapacity.lower_positive:
  for +values: List<&2,Nat>
  C.NatCycle.Positive(NatCapacity.lower(values))

def NatCapacity.lower_positive(values):
  match values:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match head:
        case Zero{}: NatCapacity.lower_positive(rest)
        case Succ{p}:
          match p:
            case Zero{}: NatCapacity.lower_positive(rest)
            case Succ{q}: Tuple{{==},NatCapacity.lower_positive(rest)}

law NatCapacity.lower_bounded:
  for +values: List<&2,Nat>
  for +maximum: Nat
  for +bounded: NatCapacity.Bounded(Succ{maximum},values)
  NatCapacity.Bounded(maximum,NatCapacity.lower(values))

def NatCapacity.lower_bounded(values,maximum,bounded):
  match values:
    case Nil{}: Unit{}
    case Con{head,rest}:
      match head:
        case Zero{}:
          match bounded:
            case Tuple{first,later}:
              NatCapacity.lower_bounded(rest,maximum,later)
        case Succ{p}:
          match p:
            case Zero{}:
              match bounded:
                case Tuple{first,later}:
                  NatCapacity.lower_bounded(rest,maximum,later)
            case Succ{q}:
              match bounded:
                case Tuple{first,later}:
                  Tuple{first,NatCapacity.lower_bounded(rest,maximum,later)}

law NatCapacity.lower_length:
  for +values: List<&2,Nat>
  for +positive: C.NatCycle.Positive(values)
  for +absent: C.NatCycle.Absent(1n,values)
  {NatCapacity.length(NatCapacity.lower(values)) == NatCapacity.length(values) : Nat}

def NatCapacity.lower_length(values,positive,absent):
  match values:
    case Nil{}: {==}
    case Con{head,rest}:
      match head:
        case Zero{}:
          match positive:
            case Tuple{first,later}:
              match absent:
                case Tuple{different,tail}:
                  Empty.absurd({NatCapacity.length(NatCapacity.lower(rest)) == Succ{NatCapacity.length(rest)} : Nat},G.Bq.Bool.false_ne_true(first))
        case Succ{p}:
          match p:
            case Zero{}:
              match positive:
                case Tuple{first,later}:
                  match absent:
                    case Tuple{different,tail}:
                      Empty.absurd({NatCapacity.length(NatCapacity.lower(rest)) == Succ{NatCapacity.length(rest)} : Nat},N.Numeric.true_ne_false(different))
            case Succ{q}:
              match positive:
                case Tuple{first,later}:
                  match absent:
                    case Tuple{different,tail}:
                      %NatCapacity.lower_length(rest,later,tail) : {Succ{NatCapacity.length(NatCapacity.lower(rest))} == Succ{_} : Nat}
                      {==}

law NatCapacity.length_drop:
  for +values: List<&2,Nat>
  for +positive: C.NatCycle.Positive(values)
  for +unique: C.NatCycle.Unique(values)
  {G.Bq.Nat.le(NatCapacity.length(values),Succ{NatCapacity.length(NatCapacity.lower(values))}) == True{} : Bool}

def NatCapacity.length_drop(values,positive,unique):
  match values:
    case Nil{}: {==}
    case Con{head,rest}:
      match head:
        case Zero{}:
          match positive:
            case Tuple{first,later}:
              match unique:
                case Tuple{absent,tail}:
                  Empty.absurd({G.Bq.Nat.le(Succ{NatCapacity.length(rest)},Succ{NatCapacity.length(NatCapacity.lower(rest))}) == True{} : Bool},G.Bq.Bool.false_ne_true(first))
        case Succ{p}:
          match p:
            case Zero{}:
              match positive:
                case Tuple{first,later}:
                  match unique:
                    case Tuple{absent,tail}:
                      %Equal.sym(Nat,NatCapacity.length(NatCapacity.lower(rest)),NatCapacity.length(rest),NatCapacity.lower_length(rest,later,absent)) : {G.Bq.Nat.le(NatCapacity.length(rest),_) == True{} : Bool}
                      Search.AllocationSearch.le_refl(NatCapacity.length(rest))
            case Succ{q}:
              match positive:
                case Tuple{first,later}:
                  match unique:
                    case Tuple{absent,tail}:
                      NatCapacity.length_drop(rest,later,tail)

law NatCapacity.capacity:
  for +maximum: Nat
  for +values: List<&2,Nat>
  for +positive: C.NatCycle.Positive(values)
  for +bounded: NatCapacity.Bounded(maximum,values)
  for +unique: C.NatCycle.Unique(values)
  {G.Bq.Nat.le(NatCapacity.length(values),maximum) == True{} : Bool}

def NatCapacity.capacity(maximum,values,positive,bounded,unique):
  match maximum:
    case Zero{}:
      match values:
        case Nil{}: {==}
        case Con{head,rest}:
          match positive:
            case Tuple{first,later}:
              match bounded:
                case Tuple{upper,tail}: Empty.absurd({False{} == True{} : Bool},G.Bq.Bool.false_ne_true(N.Numeric.le_trans(1n,head,0n,first,upper)))
    case Succ{p}:
      N.Numeric.le_trans(NatCapacity.length(values),Succ{NatCapacity.length(NatCapacity.lower(values))},Succ{p},NatCapacity.length_drop(values,positive,unique),NatCapacity.capacity(p,NatCapacity.lower(values),NatCapacity.lower_positive(values),NatCapacity.lower_bounded(values,p,bounded),NatCapacity.lower_unique(values,unique)))
