# Bendquest proto. Current Bend syntax; see README.md for the port notes.
import Base
import ./compat.bend as C
import ./support.bend as Support

law Bq.read_u32:
  (@+s_0: C.Bq.String -> U32)

type Bq.Msg is Type:
  Bq.Msg.Msg{tag_0: C.Bq.String, ns_1: List<&1, U32>, text_2: C.Bq.String}

law Bq.is:
  (@+m_tag_0: C.Bq.String -> (@+t_1: C.Bq.String -> Bool))

law Bq.fin_word:
  (@+w_0: C.Bq.String -> (@+ns_1: List<&1, U32> -> List<&1, U32>))

law Bq.take_nums_go:
  (@+s_0: C.Bq.String -> (@+w_1: C.Bq.String -> C.Bq.Pair.Pair(List<&1, U32>, (__2 => C.Bq.String))))

law Bq.take_nums:
  (@+s_0: C.Bq.String -> C.Bq.Pair.Pair(List<&1, U32>, (__1 => C.Bq.String)))

law Bq.take_word:
  (@+s_0: C.Bq.String -> C.Bq.Pair.Pair(C.Bq.String, (__1 => C.Bq.String)))

law Bq.wire_dec:
  (@+line_0: C.Bq.String -> Bq.Msg)

law Bq.split_lines:
  (@+s_0: C.Bq.String -> (@+acc_1: C.Bq.String -> C.Bq.Pair.Pair(C.Bq.String, (__2 => List<&1, C.Bq.String>))))

law Bq.feed:
  (@+buf_0: C.Bq.String -> (@+chunk_1: C.Bq.String -> C.Bq.Pair.Pair(C.Bq.String, (__2 => List<&1, C.Bq.String>))))

law Bq.nums_enc:
  (@+ns_0: List<&1, U32> -> C.Bq.String)

law Bq.wire_enc:
  (@+tag_0: C.Bq.String -> (@+ns_1: List<&1, U32> -> (@+text_2: C.Bq.String -> C.Bq.String)))

@unsafe
def Bq.read_u32():
  (s_0 => Support.Bq.Result.or(C.Bq.Pair.Pair(U32, (__1 => C.Bq.String)), U32, 0, Support.Bq.Parser.read(U32, Support.Bq.U32.parse, s_0)))

@unsafe
def Bq.is():
  (m_tag_0 => (t_1 => Support.Bq.String.eq(m_tag_0, t_1)))

@unsafe
def Bq.fin_word():
  \{Nil: (ns_0 => ns_0); \{Con: (c_0 => (rest_1 => (ns_2 => Con{Bq.read_u32(Support.Bq.String.reverse(Con{c_0, rest_1})), ns_2}))); \{}}}

@unsafe
def Bq.take_nums_go():
  \{Nil: (w_0 => Tuple{Bq.fin_word(w_0, Nil{}), Nil{}}); \{Con: (c_0 => (rest_1 => (w_2 => (+code_3 = Support.Bq.Char.code(c_0); (+apply_46 = {(rest_0 => (code_1 => (w_2 => (word => C.Bq.word_case(Sigma<&1, &1, List<&1, U32>, (__4 => List<&1, Char>)>, word, 0, (unit => (+apply_47 = {(rest_0 => (code_1 => (w_2 => (word => C.Bq.word_case(Sigma<&1, &1, List<&1, U32>, (__4 => List<&1, Char>)>, word, 0, (unit => Bq.take_nums_go(rest_0, Con{Chr{code_1}, w_2})), (_34_3 => Tuple{Bq.fin_word(w_2, Nil{}), rest_0}), 0))))) : (@+rest_0: List<&1, Char> -> (@+code_1: U32 -> (@+w_2: C.Bq.String -> (@+___3: U32 -> Sigma<&1, &1, List<&1, U32>, (__4 => List<&1, Char>)>))))}; apply_47(rest_0, code_1, w_2, C.Bq.bit(U32.is_eq(code_1, 124))))), (_36_3 => (+apply_48 = {(w_0 => \{Tuple: (fst_1 => (snd_2 => Tuple{Bq.fin_word(w_0, fst_1), snd_2})); \{}}) : (@+w_0: C.Bq.String -> (@+___1: Sigma<&1, &1, List<&1, U32>, (__1 => List<&1, Char>)> -> Sigma<&1, &1, List<&1, U32>, (__2 => List<&1, Char>)>))}; apply_48(w_2, Bq.take_nums_go(rest_0, Nil{})))), 0))))) : (@+rest_0: List<&1, Char> -> (@+code_1: U32 -> (@+w_2: C.Bq.String -> (@+___3: U32 -> Sigma<&1, &1, List<&1, U32>, (__4 => List<&1, Char>)>))))}; apply_46(rest_1, code_3, w_2, C.Bq.bit(U32.is_eq(code_3, 32)))))))); \{}}}

@unsafe
def Bq.take_nums():
  (s_0 => Bq.take_nums_go(s_0, Nil{}))

@unsafe
def Bq.take_word():
  \{Nil: Tuple{Nil{}, Nil{}}; \{Con: (c_0 => (rest_1 => (+code_2 = Support.Bq.Char.code(c_0); (+apply_49 = {(code_0 => (rest_1 => (word => C.Bq.word_case(Sigma<&1, &1, List<&1, Char>, (__3 => List<&1, Char>)>, word, 0, (unit => (+apply_50 = {(code_0 => \{Tuple: (fst_1 => (snd_2 => Tuple{Con{Chr{code_0}, fst_1}, snd_2})); \{}}) : (@+code_0: U32 -> (@+___1: Sigma<&1, &1, List<&1, Char>, (__1 => List<&1, Char>)> -> Sigma<&1, &1, List<&1, Char>, (__2 => List<&1, Char>)>))}; apply_50(code_0, Bq.take_word(rest_1)))), (_19_2 => Tuple{Nil{}, rest_1}), 0)))) : (@+code_0: U32 -> (@+rest_1: List<&1, Char> -> (@+___2: U32 -> Sigma<&1, &1, List<&1, Char>, (__3 => List<&1, Char>)>)))}; apply_49(code_2, rest_1, C.Bq.bit(U32.is_eq(code_2, 32))))))); \{}}}

@unsafe
def Bq.wire_dec():
  (line_0 => (+apply_51 = {\{Tuple: (fst_0 => (snd_1 => (+apply_52 = {(fst_0 => \{Tuple: (fst_1 => (snd_2 => Bq.Msg.Msg{fst_0, fst_1, snd_2})); \{}}) : (@+fst_0: C.Bq.String -> (@+___1: Sigma<&1, &1, List<&1, U32>, (__1 => List<&1, Char>)> -> Bq.Msg))}; apply_52(fst_0, Bq.take_nums(snd_1))))); \{}} : (@+___0: Sigma<&1, &1, List<&1, Char>, (__0 => List<&1, Char>)> -> Bq.Msg)}; apply_51(Bq.take_word(line_0))))

@unsafe
def Bq.split_lines():
  \{Nil: (acc_0 => Tuple{Support.Bq.String.reverse(acc_0), Nil{}}); \{Con: (c_0 => (rest_1 => (acc_2 => (+code_3 = Support.Bq.Char.code(c_0); (+apply_53 = {(rest_0 => (code_1 => (acc_2 => (word => C.Bq.word_case(Sigma<&1, &1, List<&1, Char>, (__4 => List<&1, List<&1, Char>>)>, word, 0, (unit => (+apply_54 = {(rest_0 => (code_1 => (acc_2 => (word => C.Bq.word_case(Sigma<&1, &1, List<&1, Char>, (__4 => List<&1, List<&1, Char>>)>, word, 0, (unit => Bq.split_lines(rest_0, Con{Chr{code_1}, acc_2})), (_54_3 => Bq.split_lines(rest_0, acc_2)), 0))))) : (@+rest_0: List<&1, Char> -> (@+code_1: U32 -> (@+acc_2: C.Bq.String -> (@+___3: U32 -> Sigma<&1, &1, List<&1, Char>, (__4 => List<&1, List<&1, Char>>)>))))}; apply_54(rest_0, code_1, acc_2, C.Bq.bit(U32.is_eq(code_1, 13))))), (_56_3 => (+apply_55 = {(acc_0 => \{Tuple: (fst_1 => (snd_2 => Tuple{fst_1, Con{Support.Bq.String.reverse(acc_0), snd_2}})); \{}}) : (@+acc_0: C.Bq.String -> (@+___1: Sigma<&1, &1, List<&1, Char>, (__1 => List<&1, List<&1, Char>>)> -> Sigma<&1, &1, List<&1, Char>, (__2 => List<&1, List<&1, Char>>)>))}; apply_55(acc_2, Bq.split_lines(rest_0, Nil{})))), 0))))) : (@+rest_0: List<&1, Char> -> (@+code_1: U32 -> (@+acc_2: C.Bq.String -> (@+___3: U32 -> Sigma<&1, &1, List<&1, Char>, (__4 => List<&1, List<&1, Char>>)>))))}; apply_53(rest_1, code_3, acc_2, C.Bq.bit(U32.is_eq(code_3, 10)))))))); \{}}}

@unsafe
def Bq.feed():
  (buf_0 => (chunk_1 => Bq.split_lines(Support.Bq.List.concat(Char, buf_0, chunk_1), Nil{})))

@unsafe
def Bq.nums_enc():
  \{Nil: Nil{}; \{Con: (n_0 => (rest_1 => Support.Bq.List.concat(Char, C.Bq.text(" "), Support.Bq.List.concat(Char, Support.Bq.U32.show(n_0), Bq.nums_enc(rest_1))))); \{}}}

@unsafe
def Bq.wire_enc():
  (tag_0 => (ns_1 => (text_2 => (+apply_62 = {(tag_0 => (ns_1 => (text_2 => \{True: Support.Bq.List.concat(Char, tag_0, Support.Bq.List.concat(Char, Bq.nums_enc(ns_1), C.Bq.text("\n"))); \{False: Support.Bq.List.concat(Char, tag_0, Support.Bq.List.concat(Char, Bq.nums_enc(ns_1), Support.Bq.List.concat(Char, C.Bq.text(" |"), Support.Bq.List.concat(Char, text_2, C.Bq.text("\n"))))); \{}}}))) : (@+tag_0: C.Bq.String -> (@+ns_1: List<&1, U32> -> (@+text_2: C.Bq.String -> (@+___3: Bool -> List<&1, Char>))))}; apply_62(tag_0, ns_1, text_2, Support.Bq.Bool.from_u32(C.Bq.bit(U32.is_eq(Support.Bq.String.length(text_2), 0))))))))
