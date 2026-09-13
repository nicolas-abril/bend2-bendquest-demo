import Base

def Bq.String() -> Type:
  List<Char>

@unsafe
def Bq.Pair.Pair(-A: Type, -B: @+x: A -> Type) -> Type:
  Sigma<&1, &1, A, x => B(x)>

type Bq.TCP is Data:
  Bq.TCP.TCP{fd: U32}

type Bq.Bytes is Type:
  Bq.Bytes.Bytes{len: U32, data: List<U32>}

@unsafe
def Bq.word_pick(-R: Type, eq: Bool, +n: U32, z: @+u: Unit -> R, s: @+n: U32 -> R, sub: U32) -> R:
  match eq:
    case True{}:
      z(Unit{})
    case False{}:
      s((n - sub : U32))

@unsafe
def Bq.word_case(-R: Type, +n: U32, k: U32, z: @+u: Unit -> R, s: @+n: U32 -> R, sub: U32) -> R:
  Bq.word_pick(R, U32.is_eq(n, k), n, z, s, sub)

@unsafe
def Bq.IO.pure(-A: Type, +x: A) -> IO(A):
  IO.pure(A, x)

@unsafe
def Bq.IO.bind(-A: Type, -B: Type, +m: IO(A), +f: @+x: A -> IO(B)) -> IO(B):
  IO.bind(A, B, m, x => f(x))

@unsafe
def Bq.IO.spawn(+act: IO(Unit)) -> IO(Unit):
  IO.spawn(Unit, act)

@unsafe
def Bq.IO.sleep(+ms: U32) -> IO(Unit):
  IO.sleep(ms)

# The game uses this adapter only for TCP connect/send and channel sends.
# Native TCP effects enforce deadlines; full channels drop sends immediately.
@unsafe
def Bq.IO.timeout(-A: Type, +ms: U32, +act: IO(A)) -> IO(Result<&1, &1, Bq.Pair.Pair(U32, _ => Bq.String), A>):
  IO.bind(A, Result<&1, &1, Bq.Pair.Pair(U32, _ => Bq.String), A>, act,
    x => IO.pure(Result<&1, &1, Bq.Pair.Pair(U32, _ => Bq.String), A>, Done{x}))

@unsafe
def Bq.Chan.new(-A: Type, +room: U32) -> IO(Chan<A>):
  Chan.new(A, room)

@unsafe
def Bq.Chan.close(-A: Type, +c: Chan<A>) -> IO(Bool):
  IO.bind(Unit, Bool, Chan.close(A, c), u => IO.pure(Bool, True{}))

@unsafe
def Bq.Chan.send(-A: Type, +c: Chan<A>, +x: A) -> IO(Result<&1, &1, Bq.Pair.Pair(U32, _ => Bq.String), Unit>):
  import "./effs/compat.c"

@unsafe
def Bq.Chan.result(-A: Type, +m: Maybe<A>) -> Result<&1, &1, Bq.Pair.Pair(U32, _ => Bq.String), A>:
  match m:
    case None{}:
      Fail{Tuple{0, Nil{}}}
    case Some{x}:
      Done{x}

@unsafe
def Bq.Chan.recv(-A: Type, +c: Chan<A>) -> IO(Result<&1, &1, Bq.Pair.Pair(U32, _ => Bq.String), A>):
  IO.bind(Maybe<A>, Result<&1, &1, Bq.Pair.Pair(U32, _ => Bq.String), A>, Chan.recv(A, c),
    m => IO.pure(Result<&1, &1, Bq.Pair.Pair(U32, _ => Bq.String), A>, Bq.Chan.result(A, m)))

@unsafe
def Bq.Chan.poll(-A: Type, +c: Chan<A>) -> IO(Result<&1, &1, Unit, A>):
  import "./effs/compat.c"

@unsafe
def Bq.Bytes.length(+xs: List<U32>) -> U32:
  match xs:
    case Nil{}:
      0
    case Con{h, t}:
      (1 + Bq.Bytes.length(t) : U32)

@unsafe
def Bq.Bytes.pack(+xs: List<U32>) -> Bq.Bytes:
  Bq.Bytes.Bytes{Bq.Bytes.length(xs), xs}

@unsafe
def Bq.Bytes.to_list(+b: Bq.Bytes) -> List<U32>:
  Bq.Bytes.Bytes{n, xs} = b
  xs

def Bq.bit(b: Bool) -> U32:
  match b:
    case True{}:
      1
    case False{}:
      0

# UTF-8 codecs retained from the original game prelude.
def Bq.Bytes.code(c: Char) -> U32:
  Chr{n} = c
  n

law Bq.Bytes.encode:
  (@+s_0: Bq.String -> List<&1, U32>)

@unsafe
def Bq.Bytes.encode():
  \{Con: (c_0 => (t_1 => (+n_2 = Bq.Bytes.code(c_0); (+one_3 = Bq.bit(U32.is_lt(n_2, 128)); (+apply_1 = {(n_0 => (t_1 => (word => Bq.word_case(List<&1, U32>, word, 0, (unit => (+two_2 = Bq.bit(U32.is_lt(n_0, 2048)); (+apply_2 = {(n_0 => (t_1 => (word => Bq.word_case(List<&1, U32>, word, 0, (unit => (+three_2 = Bq.bit(U32.is_lt(n_0, 65536)); (+apply_3 = {(n_0 => (t_1 => (word => Bq.word_case(List<&1, U32>, word, 0, (unit => (+b1_2 = (240 + U32.shrn(n_0, U32.to_nat(18)) : U32); (+b2_3 = (128 + (U32.shrn(n_0, U32.to_nat(12)) % 64 : U32) : U32); (+b3_4 = (128 + (U32.shrn(n_0, U32.to_nat(6)) % 64 : U32) : U32); (+b4_5 = (128 + (n_0 % 64 : U32) : U32); Con{b1_2, Con{b2_3, Con{b3_4, Con{b4_5, Bq.Bytes.encode(t_1)}}}}))))), (k_2 => (+b1_3 = (224 + U32.shrn(n_0, U32.to_nat(12)) : U32); (+b2_4 = (128 + (U32.shrn(n_0, U32.to_nat(6)) % 64 : U32) : U32); (+b3_5 = (128 + (n_0 % 64 : U32) : U32); Con{b1_3, Con{b2_4, Con{b3_5, Bq.Bytes.encode(t_1)}}})))), 0)))) : (@+n_0: U32 -> (@+t_1: List<&1, Char> -> (@+___2: U32 -> List<&1, U32>)))}; apply_3(n_0, t_1, three_2)))), (k_2 => (+b1_3 = (192 + U32.shrn(n_0, U32.to_nat(6)) : U32); (+b2_4 = (128 + (n_0 % 64 : U32) : U32); Con{b1_3, Con{b2_4, Bq.Bytes.encode(t_1)}}))), 0)))) : (@+n_0: U32 -> (@+t_1: List<&1, Char> -> (@+___2: U32 -> List<&1, U32>)))}; apply_2(n_0, t_1, two_2)))), (k_2 => Con{n_0, Bq.Bytes.encode(t_1)}), 0)))) : (@+n_0: U32 -> (@+t_1: List<&1, Char> -> (@+___2: U32 -> List<&1, U32>)))}; apply_1(n_2, t_1, one_3)))))); \{Nil: Nil{}; \{}}}

law Bq.Bytes.decode:
  (@+bs_0: List<&1, U32> -> Bq.String)

@unsafe
def Bq.Bytes.decode():
  \{Nil: Nil{}; \{Con: (a_0 => (bs_1 => (+ascii_2 = Bq.bit(U32.is_lt(a_0, 192)); (+apply_4 = {(a_0 => (bs_1 => (word => Bq.word_case(List<&1, Char>, word, 0, (unit => (+three_2 = Bq.bit(U32.is_lt(a_0, 224)); (+apply_5 = {(a_0 => (bs_1 => (word => Bq.word_case(List<&1, Char>, word, 0, (unit => (+four_2 = Bq.bit(U32.is_lt(a_0, 240)); (+apply_6 = {(bs_0 => (a_1 => (word => Bq.word_case(List<&1, Char>, word, 0, (unit => (+bs___2 = bs_0; (+apply_7 = {(a_0 => \{Con: (head_1 => (tail_2 => (+apply_8 = {(a_0 => (head_1 => \{Con: (head_2 => (tail_3 => (+apply_9 = {(a_0 => (head_1 => (head_2 => \{Con: (head_3 => (tail_4 => Con{Chr{((U32.shln((a_0 - 240 : U32), U32.to_nat(18)) + U32.shln((head_1 - 128 : U32), U32.to_nat(12)) : U32) + (U32.shln((head_2 - 128 : U32), U32.to_nat(6)) + (head_3 - 128 : U32) : U32) : U32)}, Bq.Bytes.decode(tail_4)})); \{Nil: [Chr{65533}]; \{}}}))) : (@+a_0: U32 -> (@+head_1: U32 -> (@+head_2: U32 -> (@+___3: List<&1, U32> -> List<&1, Char>))))}; apply_9(a_0, head_1, head_2, tail_3)))); \{Nil: [Chr{65533}]; \{}}})) : (@+a_0: U32 -> (@+head_1: U32 -> (@+___2: List<&1, U32> -> List<&1, Char>)))}; apply_8(a_0, head_1, tail_2)))); \{Nil: [Chr{65533}]; \{}}}) : (@+a_0: U32 -> (@+___1: List<&1, U32> -> List<&1, Char>))}; apply_7(a_1, bs___2)))), (k_2 => (+bs____3 = bs_0; (+apply_10 = {(a_0 => \{Con: (head_1 => (tail_2 => (+apply_11 = {(a_0 => (head_1 => \{Con: (head_2 => (tail_3 => Con{Chr{((U32.shln((a_0 - 224 : U32), U32.to_nat(12)) + U32.shln((head_1 - 128 : U32), U32.to_nat(6)) : U32) + (head_2 - 128 : U32) : U32)}, Bq.Bytes.decode(tail_3)})); \{Nil: [Chr{65533}]; \{}}})) : (@+a_0: U32 -> (@+head_1: U32 -> (@+___2: List<&1, U32> -> List<&1, Char>)))}; apply_11(a_0, head_1, tail_2)))); \{Nil: [Chr{65533}]; \{}}}) : (@+a_0: U32 -> (@+___1: List<&1, U32> -> List<&1, Char>))}; apply_10(a_1, bs____3)))), 0)))) : (@+bs_0: List<&1, U32> -> (@+a_1: U32 -> (@+___2: U32 -> List<&1, Char>)))}; apply_6(bs_1, a_0, four_2)))), (k_2 => (+bs__3 = bs_1; (+apply_12 = {(a_0 => \{Con: (head_1 => (tail_2 => Con{Chr{(U32.shln((a_0 - 192 : U32), U32.to_nat(6)) + (head_1 - 128 : U32) : U32)}, Bq.Bytes.decode(tail_2)})); \{Nil: [Chr{65533}]; \{}}}) : (@+a_0: U32 -> (@+___1: List<&1, U32> -> List<&1, Char>))}; apply_12(a_0, bs__3)))), 0)))) : (@+a_0: U32 -> (@+bs_1: List<&1, U32> -> (@+___2: U32 -> List<&1, Char>)))}; apply_5(a_0, bs_1, three_2)))), (k_2 => Con{Chr{a_0}, Bq.Bytes.decode(bs_1)}), 0)))) : (@+a_0: U32 -> (@+bs_1: List<&1, U32> -> (@+___2: U32 -> List<&1, Char>)))}; apply_4(a_0, bs_1, ascii_2))))); \{}}}

@unsafe
def Bq.Bytes.from_string(+s: Bq.String) -> Bq.Bytes:
  Bq.Bytes.pack(Bq.Bytes.encode(s))

@unsafe
def Bq.Bytes.to_string(+b: Bq.Bytes) -> Bq.String:
  Bq.Bytes.decode(Bq.Bytes.to_list(b))

@unsafe
def Bq.IO.now() -> IO(U32):
  import "./effs/compat.c"

@unsafe
def Bq.IO.now_ms() -> IO(U32):
  import "./effs/compat.c"

@unsafe
def Bq.IO.print(+text_0: Bq.String) -> IO(Unit):
  import "./effs/compat.c"

@unsafe
def Bq.IO.print_err(+text_0: Bq.String) -> IO(Unit):
  import "./effs/compat.c"

@unsafe
def Bq.IO.args() -> IO(List<&1, Bq.String>):
  import "./effs/compat.c"

@unsafe
def Bq.IO.get_env(+name_0: Bq.String) -> IO(Result<&1, &1, Bq.Pair.Pair(U32, (__1 => Bq.String)), Bq.String>):
  import "./effs/compat.c"

@unsafe
def Bq.IO.read_text(+path_0: Bq.String) -> IO(Result<&1, &1, Bq.Pair.Pair(U32, (__1 => Bq.String)), Bq.String>):
  import "./effs/compat.c"

@unsafe
def Bq.IO.write_text(+path_0: Bq.String, +text_1: Bq.String) -> IO(Result<&1, &1, Bq.Pair.Pair(U32, (__2 => Bq.String)), Unit>):
  import "./effs/compat.c"

@unsafe
def Bq.IO.rand_word() -> IO(U32):
  import "./effs/compat.c"

@unsafe
def Bq.IO.exec(+cmd_0: Bq.String) -> IO(Result<&1, &1, Bq.Pair.Pair(U32, (__1 => Bq.String)), Bq.Bytes>):
  import "./effs/compat.c"

@unsafe
def Bq.TCP.listen(+port_0: U32) -> IO(Result<&1, &1, Bq.Pair.Pair(U32, (__1 => Bq.String)), Bq.TCP>):
  import "./effs/compat.c"

@unsafe
def Bq.TCP.accept(+l_0: Bq.TCP) -> IO(Result<&1, &1, Bq.Pair.Pair(U32, (__1 => Bq.String)), Bq.TCP>):
  import "./effs/compat.c"

@unsafe
def Bq.TCP.connect(+host_0: Bq.String, +port_1: U32) -> IO(Result<&1, &1, Bq.Pair.Pair(U32, (__2 => Bq.String)), Bq.TCP>):
  import "./effs/compat.c"

@unsafe
def Bq.TCP.send(+s_0: Bq.TCP, +data_1: Bq.Bytes) -> IO(Result<&1, &1, Bq.Pair.Pair(U32, (__2 => Bq.String)), Unit>):
  import "./effs/compat.c"

@unsafe
def Bq.TCP.recv(+s_0: Bq.TCP, +max_1: U32) -> IO(Result<&1, &1, Bq.Pair.Pair(U32, (__2 => Bq.String)), Bq.Bytes>):
  import "./effs/compat.c"

@unsafe
def Bq.TCP.close(+s_0: Bq.TCP) -> IO(Unit):
  import "./effs/compat.c"

def Bq.word_and(a: U32, b: U32) -> U32:
  Bq.bit(Bool.and(U32.is_ne(a, 0), U32.is_ne(b, 0)))

def Bq.word_or(a: U32, b: U32) -> U32:
  Bq.bit(Bool.or(U32.is_ne(a, 0), U32.is_ne(b, 0)))

# The game uses character lists for both sprite rows and editable text.
def Bq.text(s: String) -> Bq.String:
  match s:
    case SNil{}:
      Nil{}
    case SCon{h, t}:
      Con{h, Bq.text(t)}

# A standalone game owns the process. Spawned readers may still be parked
# after the window closes; finish after the game's shutdown action returns.
def Bq.IO.finish() -> IO(Unit):
  import "./effs/compat.c"
