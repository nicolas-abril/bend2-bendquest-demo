# Bendquest support. Current Bend syntax; see README.md for the port notes.
import Base
import ./compat.bend as C

law Bq.Result.or:
  (@-E_0: Type -> (@-A_1: Type -> (@+d_2: A_1 -> (@+r_3: Result<&1, &1, E_0, A_1> -> A_1))))

law Bq.Parser:
  (@-A_0: Type -> Type)

law Bq.Parser.read:
  (@-A_0: Type -> (@+p_1: Bq.Parser(A_0) -> (@+s_2: C.Bq.String -> Result<&1, &1, C.Bq.Pair.Pair(U32, (__3 => C.Bq.String)), A_0>)))

law Bq.Char.code:
  (@+c_0: Char -> U32)

law Bq.U32.parse_fold:
  (@+ds_0: C.Bq.String -> (@+acc_1: U32 -> U32))

law Bq.Bool.from_u32:
  (@+x_0: U32 -> Bool)

law Bq.Char.is_digit:
  (@+c_0: Char -> Bool)

law Bq.List.reverse_go:
  (@-A_0: Type -> (@+xs_1: List<&1, A_0> -> (@+acc_2: List<&1, A_0> -> List<&1, A_0>)))

law Bq.List.reverse:
  (@-A_0: Type -> (@+xs_1: List<&1, A_0> -> List<&1, A_0>))

law Bq.String.reverse:
  (@+s_0: C.Bq.String -> C.Bq.String)

law Bq.Parser.digits_go:
  (@+s_0: C.Bq.String -> (@+acc_1: C.Bq.String -> C.Bq.Pair.Pair(C.Bq.String, (__2 => C.Bq.String))))

law Bq.Parser.digits_at:
  (@+s_0: C.Bq.String -> Result<&1, &1, C.Bq.Pair.Pair(U32, (__1 => C.Bq.String)), C.Bq.Pair.Pair(C.Bq.String, (__1 => C.Bq.String))>)

law Bq.U32.parse_go:
  (@+s_0: C.Bq.String -> Result<&1, &1, C.Bq.Pair.Pair(U32, (__1 => C.Bq.String)), C.Bq.Pair.Pair(C.Bq.String, (__1 => U32))>)

law Bq.U32.parse:
  Bq.Parser(U32)

law Bq.Bool.and:
  (@+a_0: Bool -> (@+b_1: Bool -> Bool))

law Bq.Char.eq:
  (@+x_0: Char -> (@+y_1: Char -> Bool))

law Bq.String.eq:
  (@+x_0: C.Bq.String -> (@+y_1: C.Bq.String -> Bool))

law Bq.List.length:
  (@-A_0: Type -> (@+xs_1: List<&1, A_0> -> U32))

law Bq.List.concat:
  (@-A_0: Type -> (@+xs_1: List<&1, A_0> -> (@+ys_2: List<&1, A_0> -> List<&1, A_0>)))

law Bq.List.take:
  (@-A_0: Type -> (@+n_1: U32 -> (@+xs_2: List<&1, A_0> -> List<&1, A_0>)))

law Bq.List.map_0:
  (@+xs_0: List<&1, Char> -> List<&1, U32>)

law Bq.U32.max:
  (@+a_0: U32 -> (@+b_1: U32 -> U32))

law Bq.U32.MAX_VALUE:
  U32

law Bq.U32.show_go:
  (@+f_0: U32 -> (@+n_1: U32 -> (@+acc_2: C.Bq.String -> C.Bq.String)))

law Bq.U32.show:
  (@+n_0: U32 -> C.Bq.String)

law Bq.Bag:
  Type

law Bq.Maybe:
  (@-A_0: Type -> Type)

law Bq.String.length:
  (@+s_0: C.Bq.String -> U32)

law Bq.Maybe.none:
  (@-A_0: Type -> Bq.Maybe(A_0))

law Bq.Maybe.some:
  (@-A_0: Type -> (@+value_1: A_0 -> Bq.Maybe(A_0)))

law Bq.U32.min:
  (@+a_0: U32 -> (@+b_1: U32 -> U32))

law Bq.Nat.to_u32:
  (@+n_0: Nat -> U32)

law Bq.Nat.sub:
  (@+a_0: Nat -> (@+b_1: Nat -> Nat))

law Bq.Bag.sub:
  (@+a_0: Bq.Bag -> (@+b_1: Bq.Bag -> Bq.Bag))

law Bq.Nat.le:
  (@+a_0: Nat -> (@+b_1: Nat -> Bool))

law Bq.Nat.add:
  (@+a_0: Nat -> (@+b_1: Nat -> Nat))

law Bq.Bag.add:
  (@+a_0: Bq.Bag -> (@+b_1: Bq.Bag -> Bq.Bag))

law Bq.Bag.le:
  (@+a_0: Bq.Bag -> (@+b_1: Bq.Bag -> Bool))

law Bq.Bool.not:
  (@+a_0: Bool -> Bool)

law Bq.Nat.lt:
  (@+a_0: Nat -> (@+b_1: Nat -> Bool))

law Bq.Nat.mul:
  (@+a_0: Nat -> (@+b_1: Nat -> Nat))

law Bq.Nat.dbl:
  (@+n_0: Nat -> Nat)

law Bq.Nat.pred:
  (@+n_0: Nat -> Nat)

law Bq.Nat.from_u32:
  (@+x_0: U32 -> Nat)

law Bq.List.flatten:
  (@-A_0: Type -> (@+xss_1: List<&1, List<&1, A_0>> -> List<&1, A_0>))

law Bq.String.flatten:
  (@+xs_0: List<&1, C.Bq.String> -> C.Bq.String)

law Bq.Char.is_space:
  (@+c_0: Char -> Bool)

law Bq.String.trim_go:
  (@+s_0: C.Bq.String -> C.Bq.String)

law Bq.String.trim:
  (@+s_0: C.Bq.String -> C.Bq.String)

law Bq.List.drop:
  (@-A_0: Type -> (@+n_1: U32 -> (@+xs_2: List<&1, A_0> -> List<&1, A_0>)))

law Bq.List.map_2:
  (@+xs_0: List<&1, Char> -> List<&1, U32>)

law Bq.Bool.or:
  (@+a_0: Bool -> (@+b_1: Bool -> Bool))

@unsafe
def Bq.Result.or():
  (E_0 => (A_1 => (d_2 => \{Done: (value_3 => value_3); \{Fail: (error_3 => d_2); \{}}})))

@unsafe
def Bq.Parser():
  (A_0 => (@+__1: C.Bq.String -> Result<&1, &1, C.Bq.Pair.Pair(U32, (__2 => C.Bq.String)), C.Bq.Pair.Pair(C.Bq.String, (__2 => A_0))>))

@unsafe
def Bq.Parser.read():
  (A_0 => (p_1 => (s_2 => (+apply_1 = {(A_0 => \{Done: (value_1 => (+apply_2 = {(A_0 => \{Tuple: (fst_1 => (snd_2 => Done{snd_2})); \{}}) : (@-A_0: Type -> (@+___1: Sigma<&1, &1, List<&1, Char>, (__1 => A_0)> -> Result<&1, &1, Sigma<&1, &1, U32, (__2 => List<&1, Char>)>, A_0>))}; apply_2(A_0, value_1))); \{Fail: (error_1 => Fail{error_1}); \{}}}) : (@-A_0: Type -> (@+___1: Result<&1, &1, Sigma<&1, &1, U32, (__1 => List<&1, Char>)>, Sigma<&1, &1, List<&1, Char>, (__1 => A_0)>> -> Result<&1, &1, Sigma<&1, &1, U32, (__2 => List<&1, Char>)>, A_0>))}; apply_1(A_0, p_1(s_2))))))

@unsafe
def Bq.Char.code():
  \{Chr: (n_0 => n_0); \{}}

@unsafe
def Bq.U32.parse_fold():
  \{Con: (c_0 => (t_1 => (acc_2 => Bq.U32.parse_fold(t_1, ((acc_2 * 10 : U32) + (Bq.Char.code(c_0) - 48 : U32) : U32))))); \{Nil: (acc_0 => acc_0); \{}}}

@unsafe
def Bq.Bool.from_u32():
  (word => C.Bq.word_case(Bool, word, 0, (unit => False{}), (k_0 => True{}), 0))

@unsafe
def Bq.Char.is_digit():
  (c_0 => (+n_1 = Bq.Char.code(c_0); Bq.Bool.from_u32(C.Bq.word_and(C.Bq.bit(U32.is_ge(n_1, 48)), C.Bq.bit(U32.is_le(n_1, 57))))))

@unsafe
def Bq.List.reverse_go():
  (A_0 => \{Con: (h_1 => (t_2 => (acc_3 => Bq.List.reverse_go(A_0, t_2, Con{h_1, acc_3})))); \{Nil: (acc_1 => acc_1); \{}}})

@unsafe
def Bq.List.reverse():
  (A_0 => (xs_1 => Bq.List.reverse_go(A_0, xs_1, Nil{})))

@unsafe
def Bq.String.reverse():
  (s_0 => Bq.List.reverse(Char, s_0))

@unsafe
def Bq.Parser.digits_go():
  \{Con: (c_0 => (t_1 => (acc_2 => (+d_3 = Bq.Char.is_digit(c_0); (+apply_3 = {(c_0 => (t_1 => (acc_2 => \{False: Tuple{Con{c_0, t_1}, Bq.String.reverse(acc_2)}; \{True: Bq.Parser.digits_go(t_1, Con{c_0, acc_2}); \{}}}))) : (@+c_0: Char -> (@+t_1: List<&1, Char> -> (@+acc_2: C.Bq.String -> (@+___3: Bool -> Sigma<&1, &1, List<&1, Char>, (__4 => List<&1, Char>)>))))}; apply_3(c_0, t_1, acc_2, d_3)))))); \{Nil: (acc_0 => Tuple{Nil{}, Bq.String.reverse(acc_0)}); \{}}}

@unsafe
def Bq.Parser.digits_at():
  (s_0 => (+apply_4 = {\{Tuple: (fst_0 => (snd_1 => (+apply_5 = {(fst_0 => \{Con: (head_1 => (tail_2 => Done{Tuple{fst_0, Con{head_1, tail_2}}})); \{Nil: Fail{Tuple{0, C.Bq.text("expected digits")}}; \{}}}) : (@+fst_0: C.Bq.String -> (@+___1: List<&1, Char> -> Result<&1, &1, Sigma<&1, &1, U32, (__2 => List<&1, Char>)>, Sigma<&1, &1, List<&1, Char>, (__2 => List<&1, Char>)>>))}; apply_5(fst_0, snd_1)))); \{}} : (@+___0: Sigma<&1, &1, List<&1, Char>, (__0 => List<&1, Char>)> -> Result<&1, &1, Sigma<&1, &1, U32, (__1 => List<&1, Char>)>, Sigma<&1, &1, List<&1, Char>, (__1 => List<&1, Char>)>>)}; apply_4(Bq.Parser.digits_go(s_0, Nil{}))))

@unsafe
def Bq.U32.parse_go():
  (s_0 => (+apply_6 = {\{Done: (value_0 => (+apply_7 = {\{Tuple: (fst_0 => (snd_1 => Done{Tuple{fst_0, Bq.U32.parse_fold(snd_1, 0)}})); \{}} : (@+___0: Sigma<&1, &1, List<&1, Char>, (__0 => List<&1, Char>)> -> Result<&1, &1, Sigma<&1, &1, U32, (__1 => List<&1, Char>)>, Sigma<&1, &1, List<&1, Char>, (__1 => U32)>>)}; apply_7(value_0))); \{Fail: (error_0 => Fail{error_0}); \{}}} : (@+___0: Result<&1, &1, Sigma<&1, &1, U32, (__0 => List<&1, Char>)>, Sigma<&1, &1, List<&1, Char>, (__0 => List<&1, Char>)>> -> Result<&1, &1, Sigma<&1, &1, U32, (__1 => List<&1, Char>)>, Sigma<&1, &1, List<&1, Char>, (__1 => U32)>>)}; apply_6(Bq.Parser.digits_at(s_0))))

@unsafe
def Bq.U32.parse():
  (s_0 => Bq.U32.parse_go(s_0))

@unsafe
def Bq.Bool.and():
  \{True: (b_0 => b_0); \{False: (b_0 => False{}); \{}}}

@unsafe
def Bq.Char.eq():
  (x_0 => (y_1 => Bq.Bool.from_u32(C.Bq.bit(U32.is_eq(Bq.Char.code(x_0), Bq.Char.code(y_1))))))

@unsafe
def Bq.String.eq():
  \{Con: (a_0 => (xs_1 => \{Con: (b_2 => (ys_3 => Bq.Bool.and(Bq.Char.eq(a_0, b_2), Bq.String.eq(xs_1, ys_3)))); (y2_2 => False{})})); \{Nil: \{Nil: True{}; (y2_0 => False{})}; \{}}}

@unsafe
def Bq.List.length():
  (A_0 => \{Con: (h_1 => (t_2 => (1 + Bq.List.length(A_0, t_2) : U32))); \{Nil: 0; \{}}})

@unsafe
def Bq.List.concat():
  (A_0 => \{Con: (h_1 => (t_2 => (ys_3 => Con{h_1, Bq.List.concat(A_0, t_2, ys_3)}))); \{Nil: (ys_1 => ys_1); \{}}})

@unsafe
def Bq.List.take():
  (A_0 => (word => C.Bq.word_case((@+xs_2: List<&1, A_0> -> List<&1, A_0>), word, 0, (unit => (xs_1 => Nil{})), (m_1 => \{Con: (h_2 => (t_3 => Con{h_2, Bq.List.take(A_0, (m_1 - 1 : U32), t_3)})); \{Nil: Nil{}; \{}}}), 0)))

@unsafe
def Bq.List.map_0():
  \{Con: (h_0 => (t_1 => Con{Bq.Char.code(h_0), Bq.List.map_0(t_1)})); \{Nil: Nil{}; \{}}}

@unsafe
def Bq.U32.max():
  (a_0 => (b_1 => (+apply_13 = {(a_0 => (b_1 => (word => C.Bq.word_case(U32, word, 0, (unit => a_0), (k_2 => b_1), 0)))) : (@+a_0: U32 -> (@+b_1: U32 -> (@+___2: U32 -> U32)))}; apply_13(a_0, b_1, C.Bq.bit(U32.is_lt(a_0, b_1))))))

@unsafe
def Bq.U32.MAX_VALUE():
  4294967295

@unsafe
def Bq.U32.show_go():
  (word => C.Bq.word_case((@+n_1: U32 -> (@+acc_2: C.Bq.String -> C.Bq.String)), word, 0, (unit => (n_0 => (acc_1 => acc_1))), (g_0 => (word => C.Bq.word_case((@+acc_2: C.Bq.String -> C.Bq.String), word, 0, (unit => (acc_1 => acc_1)), (m_1 => (acc_2 => Bq.U32.show_go(g_0, (m_1 / 10 : U32), Con{Chr{(48 + (m_1 % 10 : U32) : U32)}, acc_2}))), 0))), 1))

@unsafe
def Bq.U32.show():
  (word => C.Bq.word_case(C.Bq.String, word, 0, (unit => C.Bq.text("0")), (m_0 => Bq.U32.show_go(10, m_0, Nil{})), 0))

@unsafe
def Bq.Bag():
  List<&1, Nat>

@unsafe
def Bq.Maybe():
  (A_0 => Result<&1, &1, Unit, A_0>)

@unsafe
def Bq.String.length():
  (s_0 => Bq.List.length(Char, s_0))

@unsafe
def Bq.Maybe.none():
  (A_0 => Fail{Unit{}})

@unsafe
def Bq.Maybe.some():
  (A_0 => (value_1 => Done{value_1}))

@unsafe
def Bq.U32.min():
  (a_0 => (b_1 => (+apply_76 = {(b_0 => (a_1 => (word => C.Bq.word_case(U32, word, 0, (unit => b_0), (k_2 => a_1), 0)))) : (@+b_0: U32 -> (@+a_1: U32 -> (@+___2: U32 -> U32)))}; apply_76(b_1, a_0, C.Bq.bit(U32.is_lt(a_0, b_1))))))

@unsafe
def Bq.Nat.to_u32():
  \{Zero: 0; \{Succ: (p_0 => (1 + Bq.Nat.to_u32(p_0) : U32)); \{}}}

@unsafe
def Bq.Nat.sub():
  \{Zero: (b_0 => 0n); \{Succ: (ap_0 => \{Zero: Succ{ap_0}; \{Succ: (bp_1 => Bq.Nat.sub(ap_0, bp_1)); \{}}}); \{}}}

@unsafe
def Bq.Bag.sub():
  \{Con: (x_0 => (xs_1 => \{Con: (y_2 => (ys_3 => Con{Bq.Nat.sub(x_0, y_2), Bq.Bag.sub(xs_1, ys_3)})); \{Nil: Con{x_0, xs_1}; \{}}})); \{Nil: (b_0 => Nil{}); \{}}}

@unsafe
def Bq.Nat.le():
  \{Zero: (b_0 => True{}); \{Succ: (ap_0 => \{Zero: False{}; \{Succ: (bp_1 => Bq.Nat.le(ap_0, bp_1)); \{}}}); \{}}}

@unsafe
def Bq.Nat.add():
  \{Zero: (b_0 => b_0); \{Succ: (ap_0 => (b_1 => Succ{Bq.Nat.add(ap_0, b_1)})); \{}}}

@unsafe
def Bq.Bag.add():
  \{Con: (x_0 => (xs_1 => \{Con: (y_2 => (ys_3 => Con{Bq.Nat.add(x_0, y_2), Bq.Bag.add(xs_1, ys_3)})); \{Nil: Con{x_0, xs_1}; \{}}})); \{Nil: (b_0 => b_0); \{}}}

@unsafe
def Bq.Bag.le():
  \{Con: (x_0 => (xs_1 => \{Con: (y_2 => (ys_3 => Bq.Bool.and(Bq.Nat.le(x_0, y_2), Bq.Bag.le(xs_1, ys_3)))); \{Nil: False{}; \{}}})); \{Nil: (b_0 => True{}); \{}}}

@unsafe
def Bq.Bool.not():
  \{True: False{}; \{False: True{}; \{}}}

@unsafe
def Bq.Nat.lt():
  (a_0 => (b_1 => Bq.Nat.le(Succ{a_0}, b_1)))

@unsafe
def Bq.Nat.mul():
  \{Zero: (b_0 => 0n); \{Succ: (ap_0 => (b_1 => Bq.Nat.add(b_1, Bq.Nat.mul(ap_0, b_1)))); \{}}}

@unsafe
def Bq.Nat.dbl():
  \{Zero: 0n; \{Succ: (p_0 => Succ{Succ{Bq.Nat.dbl(p_0)}}); \{}}}

@unsafe
def Bq.Nat.pred():
  \{Zero: 0n; \{Succ: (p_0 => p_0); \{}}}

@unsafe
def Bq.Nat.from_u32():
  (word => C.Bq.word_case(Nat, word, 0, (unit => 0n), (p_0 => Succ{Bq.Nat.from_u32(p_0)}), 1))

@unsafe
def Bq.List.flatten():
  (A_0 => \{Con: (h_1 => (t_2 => Bq.List.concat(A_0, h_1, Bq.List.flatten(A_0, t_2)))); \{Nil: Nil{}; \{}}})

@unsafe
def Bq.String.flatten():
  (xs_0 => Bq.List.flatten(Char, xs_0))

@unsafe
def Bq.Char.is_space():
  (c_0 => (+n_1 = Bq.Char.code(c_0); Bq.Bool.from_u32(C.Bq.word_or(C.Bq.bit(U32.is_eq(n_1, 32)), C.Bq.word_and(C.Bq.bit(U32.is_ge(n_1, 9)), C.Bq.bit(U32.is_le(n_1, 13)))))))

@unsafe
def Bq.String.trim_go():
  \{Con: (c_0 => (t_1 => (+ws_2 = Bq.Char.is_space(c_0); (+apply_536 = {(c_0 => (t_1 => \{False: Con{c_0, t_1}; \{True: Bq.String.trim_go(t_1); \{}}})) : (@+c_0: Char -> (@+t_1: List<&1, Char> -> (@+___2: Bool -> List<&1, Char>)))}; apply_536(c_0, t_1, ws_2))))); \{Nil: Nil{}; \{}}}

@unsafe
def Bq.String.trim():
  (s_0 => Bq.String.reverse(Bq.String.trim_go(Bq.String.reverse(Bq.String.trim_go(s_0)))))

@unsafe
def Bq.List.drop():
  (A_0 => (word => C.Bq.word_case((@+xs_2: List<&1, A_0> -> List<&1, A_0>), word, 0, (unit => (xs_1 => xs_1)), (m_1 => \{Con: (h_2 => (t_3 => Bq.List.drop(A_0, (m_1 - 1 : U32), t_3))); \{Nil: Nil{}; \{}}}), 0)))

@unsafe
def Bq.List.map_2():
  \{Con: (h_0 => (t_1 => Con{Bq.Char.code(h_0), Bq.List.map_2(t_1)})); \{Nil: Nil{}; \{}}}

@unsafe
def Bq.Bool.or():
  \{True: (b_0 => True{}); \{False: (b_0 => b_0); \{}}}
