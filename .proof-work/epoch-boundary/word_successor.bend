# Exact binary-word successor semantics for the live nonzero-ID allocator.
import Base
import ./numeric.bend as N
import ./allocation.bend as A
import ./allocation_search.bend as Search
import ./game.bend as G

law WordSuccessor.adc_zero:
  for +n: Nat
  for +word: Word(n)
  {Word.adc(n,word,Word.zero(n),False{},False{}) == word : Word(n)}

def WordSuccessor.adc_zero(n,word):
  match n:
    case Zero{}:
      match word:
        case WNil{}: {==}
    case Succ{p}:
      match word:
        case WCon{False{},tail}:
          %WordSuccessor.adc_zero(p,tail) : {WCon{False{},Word.adc(p,tail,Word.zero(p),False{},False{})} == WCon{False{},_} : Word(Succ{p})}
          {==}
        case WCon{True{},tail}:
          %WordSuccessor.adc_zero(p,tail) : {WCon{True{},Word.adc(p,tail,Word.zero(p),False{},False{})} == WCon{True{},_} : Word(Succ{p})}
          {==}

law WordSuccessor.adc_carry:
  for +n: Nat
  for +word: Word(n)
  {Word.adc(n,word,Word.zero(n),False{},True{}) == Word.inc(n,word) : Word(n)}

def WordSuccessor.adc_carry(n,word):
  match n:
    case Zero{}:
      match word:
        case WNil{}: {==}
    case Succ{p}:
      match word:
        case WCon{False{},tail}:
          %WordSuccessor.adc_zero(p,tail) : {WCon{True{},Word.adc(p,tail,Word.zero(p),False{},False{})} == WCon{True{},_} : Word(Succ{p})}
          {==}
        case WCon{True{},tail}:
          %WordSuccessor.adc_carry(p,tail) : {WCon{False{},Word.adc(p,tail,Word.zero(p),False{},True{})} == WCon{False{},_} : Word(Succ{p})}
          {==}

law WordSuccessor.add_one:
  for +n: Nat
  for +word: Word(n)
  {Word.add(n,word,Word.inc(n,Word.zero(n))) == Word.inc(n,word) : Word(n)}

def WordSuccessor.add_one(n,word):
  match n:
    case Zero{}:
      match word:
        case WNil{}: {==}
    case Succ{p}:
      match word:
        case WCon{False{},tail}:
          %WordSuccessor.adc_zero(p,tail) : {WCon{True{},Word.adc(p,tail,Word.zero(p),False{},False{})} == WCon{True{},_} : Word(Succ{p})}
          {==}
        case WCon{True{},tail}:
          %WordSuccessor.adc_carry(p,tail) : {WCon{False{},Word.adc(p,tail,Word.zero(p),False{},True{})} == WCon{False{},_} : Word(Succ{p})}
          {==}

law WordSuccessor.u32_add_one:
  for +word: U32
  {U32.add(word,1) == U32.inc(word) : U32}

def WordSuccessor.u32_add_one(word):
  match word:
    case U32{bits}:
      %WordSuccessor.add_one(32n,bits) : {U32{Word.add(32n,bits,Word.inc(32n,Word.zero(32n)))} == U32{_} : U32}
      {==}

def WordSuccessor.zero(n: Nat,word: Word(n)) -> Bool:
  match n:
    case Zero{}: True{}
    case Succ{p}:
      match word:
        case WCon{bit,tail}: Bool.and(Bool.not(bit),WordSuccessor.zero(p,tail))

law WordSuccessor.zero_cmp_fin:
  for +bit: Bool
  for +tail: Cmp
  {Cmp.is_eq(Word.cmp.fin(bit,False{},tail)) == Bool.and(Bool.not(bit),Cmp.is_eq(tail)) : Bool}

def WordSuccessor.zero_cmp_fin(bit,tail):
  match bit:
    case False{}:
      match tail:
        case LT{}: {==}
        case EQ{}: {==}
        case GT{}: {==}
    case True{}:
      match tail:
        case LT{}: {==}
        case EQ{}: {==}
        case GT{}: {==}

law WordSuccessor.zero_cmp:
  for +n: Nat
  for +word: Word(n)
  {Cmp.is_eq(Word.cmp(n,word,Word.zero(n))) == WordSuccessor.zero(n,word) : Bool}

def WordSuccessor.zero_cmp(n,word):
  match n:
    case Zero{}: {==}
    case Succ{p}:
      match word:
        case WCon{bit,tail}:
          %WordSuccessor.zero_cmp(p,tail) : {Cmp.is_eq(Word.cmp.fin(bit,False{},Word.cmp(p,tail,Word.zero(p)))) == Bool.and(Bool.not(bit),_) : Bool}
          WordSuccessor.zero_cmp_fin(bit,Word.cmp(p,tail,Word.zero(p)))

law WordSuccessor.inc_zero:
  for +n: Nat
  for +word: Word(n)
  {WordSuccessor.zero(n,Word.inc(n,word)) == N.Numeric.full(n,word) : Bool}

def WordSuccessor.inc_zero(n,word):
  match n:
    case Zero{}: {==}
    case Succ{p}:
      match word:
        case WCon{False{},tail}: {==}
        case WCon{True{},tail}: WordSuccessor.inc_zero(p,tail)

law WordSuccessor.u32_inc_zero:
  for +bits: Word(32n)
  {U32.is_eq(U32.inc(U32{bits}),0) == N.Numeric.full(32n,bits) : Bool}

def WordSuccessor.u32_inc_zero(bits):
  %WordSuccessor.inc_zero(32n,bits) : {Cmp.is_eq(Word.cmp(32n,Word.inc(32n,bits),Word.zero(32n))) == _ : Bool}
  WordSuccessor.zero_cmp(32n,Word.inc(32n,bits))

law WordSuccessor.full_inc:
  for +n: Nat
  for +word: Word(n)
  for +full: {N.Numeric.full(n,word) == True{} : Bool}
  {Word.inc(n,word) == Word.zero(n) : Word(n)}

def WordSuccessor.full_inc(n,word,full):
  match n:
    case Zero{}: {==}
    case Succ{p}:
      match word:
        case WCon{False{},tail}: Empty.absurd({WCon{True{},tail} == Word.zero(Succ{p}) : Word(Succ{p})},G.Bq.Bool.false_ne_true(full))
        case WCon{True{},tail}:
          %WordSuccessor.full_inc(p,tail,full) : {WCon{False{},Word.inc(p,tail)} == WCon{False{},_} : Word(Succ{p})}
          {==}

law WordSuccessor.one_value:
  for +n: Nat
  {Word.to_nat(Succ{n},Word.inc(Succ{n},Word.zero(Succ{n}))) == 1n : Nat}

def WordSuccessor.one_value(n):
  %Equal.sym(Nat,Word.to_nat(n,Word.zero(n)),0n,N.Numeric.zero_value(n)) : {Succ{Nat.double(_)} == 1n : Nat}
  {==}

# Binary full flags carry both the endpoint and strict-before-end evidence.
law WordSuccessor.nonfull_below:
  for +n: Nat
  for +word: Word(n)
  for +room: {N.Numeric.full(n,word) == False{} : Bool}
  {G.Bq.Nat.le(Succ{Word.to_nat(n,word)},N.Numeric.limit(n)) == True{} : Bool}

def WordSuccessor.nonfull_below(n,word,room):
  match n:
    case Zero{}: Empty.absurd({False{} == True{} : Bool},N.Numeric.true_ne_false(room))
    case Succ{p}:
      match word:
        case WCon{False{},tail}: N.Numeric.double_le(Word.to_nat(p,tail),N.Numeric.limit(p),N.Numeric.word_bounded(p,tail))
        case WCon{True{},tail}: G.Bq.le_step_down(Succ{Nat.double(Word.to_nat(p,tail))},Nat.double(N.Numeric.limit(p)),N.Numeric.double_le(Succ{Word.to_nat(p,tail)},N.Numeric.limit(p),WordSuccessor.nonfull_below(p,tail,room)))

law WordSuccessor.nat_eq_below:
  for +a: Nat
  for +b: Nat
  for +below: {G.Bq.Nat.le(Succ{a},b) == True{} : Bool}
  {G.Bq.Nat.eq(a,b) == False{} : Bool}

def WordSuccessor.nat_eq_below(a,b,below):
  match a:
    case Zero{}:
      match b:
        case Zero{}: Empty.absurd({True{} == False{} : Bool},G.Bq.Bool.false_ne_true(below))
        case Succ{p}: {==}
    case Succ{p}:
      match b:
        case Zero{}: Empty.absurd({False{} == False{} : Bool},G.Bq.Bool.false_ne_true(below))
        case Succ{q}: WordSuccessor.nat_eq_below(p,q,below)

law WordSuccessor.full_eq_gate:
  for +flag: Bool
  for +n: Nat
  for +word: Word(n)
  for +decision: {N.Numeric.full(n,word) == flag : Bool}
  {G.Bq.Nat.eq(Word.to_nat(n,word),N.Numeric.limit(n)) == flag : Bool}

def WordSuccessor.full_eq_gate(flag,n,word,decision):
  match flag:
    case True{}:
      %Equal.sym(Nat,Word.to_nat(n,word),N.Numeric.limit(n),N.Numeric.full_value(n,word,decision)) : {G.Bq.Nat.eq(_,N.Numeric.limit(n)) == True{} : Bool}
      G.Bq.Nat.eq_refl(N.Numeric.limit(n))
    case False{}: WordSuccessor.nat_eq_below(Word.to_nat(n,word),N.Numeric.limit(n),WordSuccessor.nonfull_below(n,word,decision))

law WordSuccessor.full_eq:
  for +n: Nat
  for +word: Word(n)
  {G.Bq.Nat.eq(Word.to_nat(n,word),N.Numeric.limit(n)) == N.Numeric.full(n,word) : Bool}

def WordSuccessor.full_eq(n,word): WordSuccessor.full_eq_gate(N.Numeric.full(n,word),n,word,{==})

def WordSuccessor.nat_gate(full: Bool,value: Nat) -> Nat:
  match full:
    case True{}: 1n
    case False{}: Succ{value}

def WordSuccessor.nat_next(maximum: Nat,+value: Nat) -> Nat:
  WordSuccessor.nat_gate(G.Bq.Nat.eq(value,maximum),value)

def WordSuccessor.word_gate(+n: Nat,full: Bool,word: Word(n)) -> Word(n):
  match full:
    case True{}: Word.inc(n,Word.zero(n))
    case False{}: Word.inc(n,word)

def WordSuccessor.word_next(+n: Nat,+word: Word(n)) -> Word(n):
  WordSuccessor.word_gate(n,N.Numeric.full(n,word),word)

law WordSuccessor.word_value_gate:
  for +n: Nat
  for +full: Bool
  for +word: Word(Succ{n})
  for +decision: {N.Numeric.full(Succ{n},word) == full : Bool}
  {Word.to_nat(Succ{n},WordSuccessor.word_gate(Succ{n},full,word)) == WordSuccessor.nat_gate(full,Word.to_nat(Succ{n},word)) : Nat}

def WordSuccessor.word_value_gate(n,full,word,decision):
  match full:
    case True{}: WordSuccessor.one_value(n)
    case False{}: N.Numeric.inc_exact(Succ{n},word,decision)

law WordSuccessor.word_next_value:
  for +n: Nat
  for +word: Word(Succ{n})
  {Word.to_nat(Succ{n},WordSuccessor.word_next(Succ{n},word)) == WordSuccessor.nat_next(N.Numeric.limit(Succ{n}),Word.to_nat(Succ{n},word)) : Nat}

def WordSuccessor.word_next_value(n,word):
  %Equal.sym(Bool,G.Bq.Nat.eq(Word.to_nat(Succ{n},word),N.Numeric.limit(Succ{n})),N.Numeric.full(Succ{n},word),WordSuccessor.full_eq(Succ{n},word)) : {Word.to_nat(Succ{n},WordSuccessor.word_next(Succ{n},word)) == WordSuccessor.nat_gate(_,Word.to_nat(Succ{n},word)) : Nat}
  WordSuccessor.word_value_gate(n,N.Numeric.full(Succ{n},word),word,{==})

law WordSuccessor.u32_gate:
  for +full: Bool
  for +bits: Word(32n)
  {A.Allocation.normalize_gate(full,U32.inc(U32{bits})) == U32{WordSuccessor.word_gate(32n,full,bits)} : U32}

def WordSuccessor.u32_gate(full,bits):
  match full:
    case False{}: {==}
    case True{}: {==}

law WordSuccessor.u32_refines:
  for +bits: Word(32n)
  {A.Allocation.next(U32{bits}) == U32{WordSuccessor.word_next(32n,bits)} : U32}

def WordSuccessor.u32_refines(bits):
  %Equal.sym(U32,U32.add(U32{bits},1),U32.inc(U32{bits}),WordSuccessor.u32_add_one(U32{bits})) : {A.Allocation.normalize(_) == U32{WordSuccessor.word_next(32n,bits)} : U32}
  %Equal.sym(Bool,U32.is_eq(U32.inc(U32{bits}),0),N.Numeric.full(32n,bits),WordSuccessor.u32_inc_zero(bits)) : {A.Allocation.normalize_gate(_,U32.inc(U32{bits})) == U32{WordSuccessor.word_next(32n,bits)} : U32}
  WordSuccessor.u32_gate(N.Numeric.full(32n,bits),bits)

# An actual full word specifies capacity without expanding a closed unary MAX.
# It is exact capacity evidence, not an assumed cardinality bound.
type WordSuccessor.Capacity<-n: Nat,-maximum: Nat> is Data:
  WordSuccessor.Capacity{word: Word(n),full: {N.Numeric.full(n,word) == True{} : Bool},exact: {Word.to_nat(n,word) == maximum : Nat}}

law WordSuccessor.capacity:
  for +n: Nat
  for +word: Word(n)
  for +full: {N.Numeric.full(n,word) == True{} : Bool}
  WordSuccessor.Capacity<n,Word.to_nat(n,word)>

def WordSuccessor.capacity(n,word,full): WordSuccessor.Capacity{word,full,{==}}

law WordSuccessor.capacity_exact:
  for +n: Nat
  for +maximum: Nat
  for +capacity: WordSuccessor.Capacity<n,maximum>
  {N.Numeric.limit(n) == maximum : Nat}

def WordSuccessor.capacity_exact(n,maximum,capacity):
  match capacity:
    case WordSuccessor.Capacity{word,full,exact}: Equal.trans(Nat,N.Numeric.limit(n),Word.to_nat(n,word),maximum,Equal.sym(Nat,Word.to_nat(n,word),N.Numeric.limit(n),N.Numeric.full_value(n,word,full)),exact)

law WordSuccessor.full_eq_at:
  for +n: Nat
  for +word: Word(n)
  for +maximum: Nat
  for +capacity: WordSuccessor.Capacity<n,maximum>
  {G.Bq.Nat.eq(Word.to_nat(n,word),maximum) == N.Numeric.full(n,word) : Bool}

def WordSuccessor.full_eq_at(n,word,maximum,capacity):
  %WordSuccessor.capacity_exact(n,maximum,capacity) : {G.Bq.Nat.eq(Word.to_nat(n,word),_) == N.Numeric.full(n,word) : Bool}
  WordSuccessor.full_eq(n,word)

law WordSuccessor.word_next_value_at:
  for +n: Nat
  for +word: Word(Succ{n})
  for +maximum: Nat
  for +capacity: WordSuccessor.Capacity<Succ{n},maximum>
  {Word.to_nat(Succ{n},WordSuccessor.word_next(Succ{n},word)) == WordSuccessor.nat_next(maximum,Word.to_nat(Succ{n},word)) : Nat}

def WordSuccessor.word_next_value_at(n,word,maximum,capacity):
  %Equal.sym(Bool,G.Bq.Nat.eq(Word.to_nat(Succ{n},word),maximum),N.Numeric.full(Succ{n},word),WordSuccessor.full_eq_at(Succ{n},word,maximum,capacity)) : {Word.to_nat(Succ{n},WordSuccessor.word_next(Succ{n},word)) == WordSuccessor.nat_gate(_,Word.to_nat(Succ{n},word)) : Nat}
  WordSuccessor.word_value_gate(n,N.Numeric.full(Succ{n},word),word,{==})

law WordSuccessor.u32_next_value:
  for +word: U32
  for +maximum: Nat
  for +capacity: WordSuccessor.Capacity<32n,maximum>
  {U32.to_nat(A.Allocation.next(word)) == WordSuccessor.nat_next(maximum,U32.to_nat(word)) : Nat}

def WordSuccessor.u32_next_value(word,maximum,capacity):
  match word:
    case U32{bits}:
      %Equal.sym(U32,A.Allocation.next(U32{bits}),U32{WordSuccessor.word_next(32n,bits)},WordSuccessor.u32_refines(bits)) : {U32.to_nat(_) == WordSuccessor.nat_next(maximum,U32.to_nat(U32{bits})) : Nat}
      WordSuccessor.word_next_value_at(31n,bits,maximum,capacity)

law WordSuccessor.nat_next_wrap:
  for +maximum: Nat
  {WordSuccessor.nat_next(maximum,maximum) == 1n : Nat}

def WordSuccessor.nat_next_wrap(maximum):
  %Equal.sym(Bool,G.Bq.Nat.eq(maximum,maximum),True{},G.Bq.Nat.eq_refl(maximum)) : {WordSuccessor.nat_gate(_,maximum) == 1n : Nat}
  {==}

law WordSuccessor.nat_next_advance:
  for +maximum: Nat
  for +value: Nat
  for +below: {G.Bq.Nat.le(Succ{value},maximum) == True{} : Bool}
  {WordSuccessor.nat_next(maximum,value) == Succ{value} : Nat}

def WordSuccessor.nat_next_advance(maximum,value,below):
  %Equal.sym(Bool,G.Bq.Nat.eq(value,maximum),False{},WordSuccessor.nat_eq_below(value,maximum,below)) : {WordSuccessor.nat_gate(_,value) == Succ{value} : Nat}
  {==}

law WordSuccessor.double_zero:
  for +value: Nat
  {G.Bq.Nat.eq(Nat.double(value),0n) == G.Bq.Nat.eq(value,0n) : Bool}

def WordSuccessor.double_zero(value):
  match value:
    case Zero{}: {==}
    case Succ{p}: {==}

law WordSuccessor.zero_value:
  for +n: Nat
  for +word: Word(n)
  {G.Bq.Nat.eq(Word.to_nat(n,word),0n) == WordSuccessor.zero(n,word) : Bool}

def WordSuccessor.zero_value(n,word):
  match n:
    case Zero{}: {==}
    case Succ{p}:
      match word:
        case WCon{False{},tail}:
          %WordSuccessor.zero_value(p,tail) : {G.Bq.Nat.eq(Nat.double(Word.to_nat(p,tail)),0n) == _ : Bool}
          WordSuccessor.double_zero(Word.to_nat(p,tail))
        case WCon{True{},tail}: {==}

law WordSuccessor.u32_zero_value:
  for +word: U32
  {G.Bq.Nat.eq(U32.to_nat(word),0n) == U32.is_eq(word,0) : Bool}

def WordSuccessor.u32_zero_value(word):
  match word:
    case U32{bits}:
      %Equal.sym(Bool,Cmp.is_eq(Word.cmp(32n,bits,Word.zero(32n))),WordSuccessor.zero(32n,bits),WordSuccessor.zero_cmp(32n,bits)) : {G.Bq.Nat.eq(Word.to_nat(32n,bits),0n) == _ : Bool}
      WordSuccessor.zero_value(32n,bits)

law WordSuccessor.nat_nonzero:
  for +value: Nat
  for +nonzero: {G.Bq.Nat.eq(value,0n) == False{} : Bool}
  {G.Bq.Nat.le(1n,value) == True{} : Bool}

def WordSuccessor.nat_nonzero(value,nonzero):
  match value:
    case Zero{}: Empty.absurd({False{} == True{} : Bool},N.Numeric.true_ne_false(nonzero))
    case Succ{p}: {==}

law WordSuccessor.u32_positive_value:
  for +word: U32
  for +positive: {U32.is_eq(word,0) == False{} : Bool}
  {G.Bq.Nat.le(1n,U32.to_nat(word)) == True{} : Bool}

def WordSuccessor.u32_positive_value(word,positive):
  WordSuccessor.nat_nonzero(U32.to_nat(word),(%Equal.sym(Bool,G.Bq.Nat.eq(U32.to_nat(word),0n),U32.is_eq(word,0),WordSuccessor.u32_zero_value(word)) : {_ == False{} : Bool}; positive))

law WordSuccessor.normalized_positive:
  for +word: U32
  {G.Bq.Nat.le(1n,U32.to_nat(A.Allocation.normalize(word))) == True{} : Bool}

def WordSuccessor.normalized_positive(word): WordSuccessor.u32_positive_value(A.Allocation.normalize(word),A.Allocation.normalize_positive(word))

law WordSuccessor.word_bound:
  for +n: Nat
  for +word: Word(n)
  for +maximum: Nat
  for +capacity: WordSuccessor.Capacity<n,maximum>
  {G.Bq.Nat.le(Word.to_nat(n,word),maximum) == True{} : Bool}

def WordSuccessor.word_bound(n,word,maximum,capacity):
  %WordSuccessor.capacity_exact(n,maximum,capacity) : {G.Bq.Nat.le(Word.to_nat(n,word),_) == True{} : Bool}
  N.Numeric.word_bounded(n,word)

law WordSuccessor.u32_bound:
  for +word: U32
  for +maximum: Nat
  for +capacity: WordSuccessor.Capacity<32n,maximum>
  {G.Bq.Nat.le(U32.to_nat(word),maximum) == True{} : Bool}

def WordSuccessor.u32_bound(word,maximum,capacity):
  match word:
    case U32{bits}: WordSuccessor.word_bound(32n,bits,maximum,capacity)

law WordSuccessor.capacity_positive:
  for +n: Nat
  for +maximum: Nat
  for +capacity: WordSuccessor.Capacity<Succ{n},maximum>
  {G.Bq.Nat.le(1n,maximum) == True{} : Bool}

def WordSuccessor.capacity_positive(n,maximum,capacity):
  match capacity:
    case WordSuccessor.Capacity{word,full,exact}:
      match word:
        case WCon{False{},tail}: Empty.absurd({G.Bq.Nat.le(1n,maximum) == True{} : Bool},G.Bq.Bool.false_ne_true(full))
        case WCon{True{},tail}:
          %exact : {G.Bq.Nat.le(1n,_) == True{} : Bool}
          {==}

def WordSuccessor.decode(ids: A.Allocation.Ids) -> List<&2,Nat>:
  match ids:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{U32.to_nat(head),WordSuccessor.decode(rest)}

def WordSuccessor.nat_visits(fuel: Nat,+maximum: Nat,+candidate: Nat) -> List<&2,Nat>:
  match fuel:
    case Zero{}: Nil{}
    case Succ{rest}: Con{candidate,WordSuccessor.nat_visits(rest,maximum,WordSuccessor.nat_next(maximum,candidate))}

law WordSuccessor.visits_refine:
  for +fuel: Nat
  for +candidate: U32
  for +maximum: Nat
  for +capacity: WordSuccessor.Capacity<32n,maximum>
  {WordSuccessor.decode(Search.AllocationSearch.visits(fuel,candidate)) == WordSuccessor.nat_visits(fuel,maximum,U32.to_nat(candidate)) : List<&2,Nat>}

def WordSuccessor.visits_refine(fuel,candidate,maximum,capacity):
  match fuel:
    case Zero{}: {==}
    case Succ{rest}:
      %WordSuccessor.u32_next_value(candidate,maximum,capacity) : {Con{U32.to_nat(candidate),WordSuccessor.decode(Search.AllocationSearch.visits(rest,A.Allocation.next(candidate)))} == Con{U32.to_nat(candidate),WordSuccessor.nat_visits(rest,maximum,_)} : List<&2,Nat>}
      %WordSuccessor.visits_refine(rest,A.Allocation.next(candidate),maximum,capacity) : {Con{U32.to_nat(candidate),WordSuccessor.decode(Search.AllocationSearch.visits(rest,A.Allocation.next(candidate)))} == Con{U32.to_nat(candidate),_} : List<&2,Nat>}
      {==}

law WordSuccessor.find_visits:
  for +ids: A.Allocation.Ids
  for +hint: U32
  for +maximum: Nat
  for +capacity: WordSuccessor.Capacity<32n,maximum>
  {WordSuccessor.decode(Search.AllocationSearch.visits(Succ{A.Allocation.length(ids)},A.Allocation.normalize(hint))) == WordSuccessor.nat_visits(Succ{A.Allocation.length(ids)},maximum,U32.to_nat(A.Allocation.normalize(hint))) : List<&2,Nat>}

def WordSuccessor.find_visits(ids,hint,maximum,capacity): WordSuccessor.visits_refine(Succ{A.Allocation.length(ids)},A.Allocation.normalize(hint),maximum,capacity)

# Constructive capacity existence, including a packed U32 witness that does not
# expose the closed maximum as an index during specialization.
def WordSuccessor.ones(n: Nat) -> Word(n):
  match n:
    case Zero{}: WNil{}
    case Succ{p}: WCon{True{},WordSuccessor.ones(p)}

law WordSuccessor.ones_full:
  for +n: Nat
  {N.Numeric.full(n,WordSuccessor.ones(n)) == True{} : Bool}

def WordSuccessor.ones_full(n):
  match n:
    case Zero{}: {==}
    case Succ{p}: WordSuccessor.ones_full(p)

type WordSuccessor.Range<-n: Nat> is Data:
  WordSuccessor.Range{maximum: Nat,capacity: WordSuccessor.Capacity<n,maximum>}

law WordSuccessor.range:
  for +n: Nat
  WordSuccessor.Range<n>

def WordSuccessor.range(n):
  WordSuccessor.Range{Word.to_nat(n,WordSuccessor.ones(n)),WordSuccessor.capacity(n,WordSuccessor.ones(n),WordSuccessor.ones_full(n))}

law WordSuccessor.u32_range:
  WordSuccessor.Range<32n>

def WordSuccessor.u32_range(): WordSuccessor.range(32n)
