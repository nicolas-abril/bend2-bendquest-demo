# Bendquest ior. Current Bend syntax; see README.md for the port notes.
import Base
import ./compat.bend as C

law Bq.IOR:
  (@-E_0: Type -> (@-A_1: Type -> Type))

law Bq.IOR.run:
  (@-E_0: Type -> (@-A_1: Type -> (@+x_2: Bq.IOR(E_0, A_1) -> IO(Result<&1, &1, E_0, A_1>))))

law Bq.IOR.step:
  (@-E_0: Type -> (@-A_1: Type -> (@-B_2: Type -> (@+f_3: (@+__3: A_1 -> Bq.IOR(E_0, B_2)) -> (@+r_4: Result<&1, &1, E_0, A_1> -> Bq.IOR(E_0, B_2))))))

law Bq.IOR.bind:
  (@-E_0: Type -> (@-A_1: Type -> (@-B_2: Type -> (@+x_3: Bq.IOR(E_0, A_1) -> (@+f_4: (@+__4: A_1 -> Bq.IOR(E_0, B_2)) -> Bq.IOR(E_0, B_2))))))

law Bq.IOR.lift:
  (@-E_0: Type -> (@-A_1: Type -> (@+x_2: IO(A_1) -> Bq.IOR(E_0, A_1))))

law Bq.IOR.pure:
  (@-E_0: Type -> (@-A_1: Type -> (@+value_2: A_1 -> Bq.IOR(E_0, A_1))))

@unsafe
def Bq.IOR():
  (E_0 => (A_1 => IO(Result<&1, &1, E_0, A_1>)))

@unsafe
def Bq.IOR.run():
  (E_0 => (A_1 => (x_2 => x_2)))

@unsafe
def Bq.IOR.step():
  (E_0 => (A_1 => (B_2 => (f_3 => \{Done: (v_4 => f_3(v_4)); \{Fail: (e_4 => C.Bq.IO.pure(Result<&1, &1, E_0, B_2>, Fail{e_4})); \{}}}))))

@unsafe
def Bq.IOR.bind():
  (E_0 => (A_1 => (B_2 => (x_3 => (f_4 => C.Bq.IO.bind(Result<&1, &1, E_0, A_1>, Result<&1, &1, E_0, B_2>, x_3, (r_5 => Bq.IOR.step(E_0, A_1, B_2, f_4, r_5))))))))

@unsafe
def Bq.IOR.lift():
  (E_0 => (A_1 => (x_2 => C.Bq.IO.bind(A_1, Result<&1, &1, E_0, A_1>, x_2, (v_3 => C.Bq.IO.pure(Result<&1, &1, E_0, A_1>, Done{v_3}))))))

@unsafe
def Bq.IOR.pure():
  (E_0 => (A_1 => (value_2 => C.Bq.IO.pure(Result<&1, &1, E_0, A_1>, Done{value_2}))))
