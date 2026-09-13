# Bounds for the actual Base word division used by seeded spawn placement.
import Base
import ./game.bend as G
import ./numeric.bend as N

def Remainders.rem(-n: Nat,pair: Word(n) & U32) -> U32:
  match pair:
    case Tuple{quotient,remainder}: remainder

def Remainders.finish(s: U32,b: U32,large: Bool) -> U32:
  match large:
    case True{}: U32.sub(s,b)
    case False{}: s

def Remainders.shift(+b: U32,pair: Bool & Word(32n)) -> U32:
  match pair:
    case Tuple{carry,word}:
      +value = {U32{word} : U32}
      Remainders.finish(value,b,Bool.or(carry,U32.is_ge(value,b)))

def Remainders.next(bit: Bool,b: U32,r: U32) -> U32:
  match r:
    case U32{word}: Remainders.shift(b,Word.shl.out(32n,bit,word))

law Remainders.finish_exact:
  for +p: Nat
  for +q: Word(p)
  for +s: U32
  for +b: U32
  for +large: Bool
  {Remainders.rem(Succ{p},U32.divmod.go.fin(p,q,s,b,large)) == Remainders.finish(s,b,large) : U32}

def Remainders.finish_exact(p,q,s,b,large):
  match large:
    case True{}: {==}
    case False{}: {==}

law Remainders.shift_exact:
  for +p: Nat
  for +q: Word(p)
  for +b: U32
  for pair: Bool & Word(32n)
  {Remainders.rem(Succ{p},U32.divmod.go.shl(p,q,b,pair)) == Remainders.shift(b,pair) : U32}

def Remainders.shift_exact(p,q,b,pair):
  match pair:
    case Tuple{carry,word}:
      +bits = word
      Remainders.finish_exact(p,q,U32{bits},b,Bool.or(carry,U32.is_ge(U32{bits},b)))

law Remainders.next_exact:
  for +p: Nat
  for +bit: Bool
  for +b: U32
  for +q: Word(p)
  for +r: U32
  {Remainders.rem(Succ{p},U32.divmod.go.rec(p,bit,b,Tuple{q,r})) == Remainders.next(bit,b,r) : U32}

def Remainders.next_exact(p,bit,b,q,r):
  match r:
    case U32{word}: Remainders.shift_exact(p,q,b,Word.shl.out(32n,bit,word))

law Remainders.mod_finish:
  for pair: Word(32n) & U32
  {U32.mod.fin(pair) == Remainders.rem(32n,pair) : U32}

def Remainders.mod_finish(pair):
  match pair:
    case Tuple{q,r}: {==}

law Remainders.step_13_nat:
  for +n: Nat
  for +bit: Bool
  for +bound: {G.Bq.Nat.lt(n,13n) == True{} : Bool}
  {G.Bq.Nat.lt(U32.to_nat(Remainders.next(bit,13,U32.from_nat(n))),13n) == True{} : Bool}

def Remainders.step_13_nat(n,bit,bound):
  match n:
    case 0n:
      match bit:
        case False{}: {==}
        case True{}: {==}
    case 1n:
      match bit:
        case False{}: {==}
        case True{}: {==}
    case 2n:
      match bit:
        case False{}: {==}
        case True{}: {==}
    case 3n:
      match bit:
        case False{}: {==}
        case True{}: {==}
    case 4n:
      match bit:
        case False{}: {==}
        case True{}: {==}
    case 5n:
      match bit:
        case False{}: {==}
        case True{}: {==}
    case 6n:
      match bit:
        case False{}: {==}
        case True{}: {==}
    case 7n:
      match bit:
        case False{}: {==}
        case True{}: {==}
    case 8n:
      match bit:
        case False{}: {==}
        case True{}: {==}
    case 9n:
      match bit:
        case False{}: {==}
        case True{}: {==}
    case 10n:
      match bit:
        case False{}: {==}
        case True{}: {==}
    case 11n:
      match bit:
        case False{}: {==}
        case True{}: {==}
    case 12n:
      match bit:
        case False{}: {==}
        case True{}: {==}
    case 13n+rest:
      Empty.absurd({G.Bq.Nat.lt(U32.to_nat(Remainders.next(bit,13,U32.from_nat(13n+rest))),13n) == True{} : Bool},G.Bq.Bool.false_ne_true(bound))

law Remainders.step_13:
  for +bit: Bool
  for +r: U32
  for +bound: {G.Bq.Nat.lt(U32.to_nat(r),13n) == True{} : Bool}
  {G.Bq.Nat.lt(U32.to_nat(Remainders.next(bit,13,r)),13n) == True{} : Bool}

def Remainders.step_13(bit,r,bound):
  %N.Numeric.u32_roundtrip(r) : {G.Bq.Nat.lt(U32.to_nat(Remainders.next(bit,13,_)),13n) == True{} : Bool}
  Remainders.step_13_nat(U32.to_nat(r),bit,bound)

law Remainders.rec_13:
  for +p: Nat
  for +bit: Bool
  for pair: Word(p) & U32
  for +bound: {G.Bq.Nat.lt(U32.to_nat(Remainders.rem(p,pair)),13n) == True{} : Bool}
  {G.Bq.Nat.lt(U32.to_nat(Remainders.rem(Succ{p},U32.divmod.go.rec(p,bit,13,pair))),13n) == True{} : Bool}

def Remainders.rec_13(p,bit,pair,bound):
  match pair:
    case Tuple{q,r}:
      +quotient = q
      +remainder = r
      %Equal.sym(U32,Remainders.rem(Succ{p},U32.divmod.go.rec(p,bit,13,Tuple{quotient,remainder})),Remainders.next(bit,13,remainder),Remainders.next_exact(p,bit,13,quotient,remainder)) : {G.Bq.Nat.lt(U32.to_nat(_),13n) == True{} : Bool}
      Remainders.step_13(bit,remainder,bound)

law Remainders.go_13:
  for +m: Nat
  for +word: Word(m)
  {G.Bq.Nat.lt(U32.to_nat(Remainders.rem(m,U32.divmod.go(m,word,13))),13n) == True{} : Bool}

def Remainders.go_13(m,word):
  match m:
    case Zero{}:
      match word:
        case WNil{}: {==}
    case Succ{p}:
      match word:
        case WCon{bit,rest}:
          Remainders.rec_13(p,bit,U32.divmod.go(p,rest,13),Remainders.go_13(p,rest))

law Remainders.mod_13:
  for +word: U32
  {G.Bq.Nat.lt(U32.to_nat(U32.mod(word,13)),13n) == True{} : Bool}

def Remainders.mod_13(word):
  match word:
    case U32{bits}:
      %Equal.sym(U32,U32.mod.fin(U32.divmod.go(32n,bits,13)),Remainders.rem(32n,U32.divmod.go(32n,bits,13)),Remainders.mod_finish(U32.divmod.go(32n,bits,13))) : {G.Bq.Nat.lt(U32.to_nat(_),13n) == True{} : Bool}
      Remainders.go_13(32n,bits)

law Remainders.step_26_nat:
  for +n: Nat
  for +bit: Bool
  for +bound: {G.Bq.Nat.lt(n,26n) == True{} : Bool}
  {G.Bq.Nat.lt(U32.to_nat(Remainders.next(bit,26,U32.from_nat(n))),26n) == True{} : Bool}

def Remainders.step_26_nat(n,bit,bound):
  match n:
    case 0n:
      match bit:
        case False{}: {==}
        case True{}: {==}
    case 1n:
      match bit:
        case False{}: {==}
        case True{}: {==}
    case 2n:
      match bit:
        case False{}: {==}
        case True{}: {==}
    case 3n:
      match bit:
        case False{}: {==}
        case True{}: {==}
    case 4n:
      match bit:
        case False{}: {==}
        case True{}: {==}
    case 5n:
      match bit:
        case False{}: {==}
        case True{}: {==}
    case 6n:
      match bit:
        case False{}: {==}
        case True{}: {==}
    case 7n:
      match bit:
        case False{}: {==}
        case True{}: {==}
    case 8n:
      match bit:
        case False{}: {==}
        case True{}: {==}
    case 9n:
      match bit:
        case False{}: {==}
        case True{}: {==}
    case 10n:
      match bit:
        case False{}: {==}
        case True{}: {==}
    case 11n:
      match bit:
        case False{}: {==}
        case True{}: {==}
    case 12n:
      match bit:
        case False{}: {==}
        case True{}: {==}
    case 13n:
      match bit:
        case False{}: {==}
        case True{}: {==}
    case 14n:
      match bit:
        case False{}: {==}
        case True{}: {==}
    case 15n:
      match bit:
        case False{}: {==}
        case True{}: {==}
    case 16n:
      match bit:
        case False{}: {==}
        case True{}: {==}
    case 17n:
      match bit:
        case False{}: {==}
        case True{}: {==}
    case 18n:
      match bit:
        case False{}: {==}
        case True{}: {==}
    case 19n:
      match bit:
        case False{}: {==}
        case True{}: {==}
    case 20n:
      match bit:
        case False{}: {==}
        case True{}: {==}
    case 21n:
      match bit:
        case False{}: {==}
        case True{}: {==}
    case 22n:
      match bit:
        case False{}: {==}
        case True{}: {==}
    case 23n:
      match bit:
        case False{}: {==}
        case True{}: {==}
    case 24n:
      match bit:
        case False{}: {==}
        case True{}: {==}
    case 25n:
      match bit:
        case False{}: {==}
        case True{}: {==}
    case 26n+rest:
      Empty.absurd({G.Bq.Nat.lt(U32.to_nat(Remainders.next(bit,26,U32.from_nat(26n+rest))),26n) == True{} : Bool},G.Bq.Bool.false_ne_true(bound))

law Remainders.step_26:
  for +bit: Bool
  for +r: U32
  for +bound: {G.Bq.Nat.lt(U32.to_nat(r),26n) == True{} : Bool}
  {G.Bq.Nat.lt(U32.to_nat(Remainders.next(bit,26,r)),26n) == True{} : Bool}

def Remainders.step_26(bit,r,bound):
  %N.Numeric.u32_roundtrip(r) : {G.Bq.Nat.lt(U32.to_nat(Remainders.next(bit,26,_)),26n) == True{} : Bool}
  Remainders.step_26_nat(U32.to_nat(r),bit,bound)

law Remainders.rec_26:
  for +p: Nat
  for +bit: Bool
  for pair: Word(p) & U32
  for +bound: {G.Bq.Nat.lt(U32.to_nat(Remainders.rem(p,pair)),26n) == True{} : Bool}
  {G.Bq.Nat.lt(U32.to_nat(Remainders.rem(Succ{p},U32.divmod.go.rec(p,bit,26,pair))),26n) == True{} : Bool}

def Remainders.rec_26(p,bit,pair,bound):
  match pair:
    case Tuple{q,r}:
      +quotient = q
      +remainder = r
      %Equal.sym(U32,Remainders.rem(Succ{p},U32.divmod.go.rec(p,bit,26,Tuple{quotient,remainder})),Remainders.next(bit,26,remainder),Remainders.next_exact(p,bit,26,quotient,remainder)) : {G.Bq.Nat.lt(U32.to_nat(_),26n) == True{} : Bool}
      Remainders.step_26(bit,remainder,bound)

law Remainders.go_26:
  for +m: Nat
  for +word: Word(m)
  {G.Bq.Nat.lt(U32.to_nat(Remainders.rem(m,U32.divmod.go(m,word,26))),26n) == True{} : Bool}

def Remainders.go_26(m,word):
  match m:
    case Zero{}:
      match word:
        case WNil{}: {==}
    case Succ{p}:
      match word:
        case WCon{bit,rest}:
          Remainders.rec_26(p,bit,U32.divmod.go(p,rest,26),Remainders.go_26(p,rest))

law Remainders.mod_26:
  for +word: U32
  {G.Bq.Nat.lt(U32.to_nat(U32.mod(word,26)),26n) == True{} : Bool}

def Remainders.mod_26(word):
  match word:
    case U32{bits}:
      %Equal.sym(U32,U32.mod.fin(U32.divmod.go(32n,bits,26)),Remainders.rem(32n,U32.divmod.go(32n,bits,26)),Remainders.mod_finish(U32.divmod.go(32n,bits,26))) : {G.Bq.Nat.lt(U32.to_nat(_),26n) == True{} : Bool}
      Remainders.go_26(32n,bits)
