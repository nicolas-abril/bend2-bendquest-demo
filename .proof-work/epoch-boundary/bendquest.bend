# Bendquest bendquest. Current Bend syntax; see README.md for the port notes.
import Base
import ./compat.bend as C
import ./proto.bend as Proto
import ./support.bend as Support
import ./server.bend as Server
import ./client.bend as Client

law Bq.port_of:
  (@+rest_0: List<&1, C.Bq.String> -> U32)

law Bq.pick_mode:
  (@+args_0: List<&1, C.Bq.String> -> U32)

law Bq.log_printer:
  (@+fuel_0: U32 -> (@+lg_1: Chan<C.Bq.String> -> IO(Unit)))

law Bq.stat_drain:
  (@+fuel_0: U32 -> (@+stat_1: Chan<C.Bq.String> -> IO(Unit)))

law Bq.headless:
  (@+port_0: U32 -> IO(Unit))

law Bq.start:
  IO(Unit)

@unsafe
def Bq.port_of():
  \{Nil: 4977; \{Con: (p_0 => (more_1 => Proto.Bq.read_u32(p_0))); \{}}}

@unsafe
def Bq.pick_mode():
  \{Nil: 0; \{Con: (a_0 => (rest_1 => (+apply_8 = {(rest_0 => \{True: (1 + Bq.port_of(rest_0) : U32); \{False: Bq.pick_mode(rest_0); \{}}}) : (@+rest_0: List<&1, C.Bq.String> -> (@+___1: Bool -> U32))}; apply_8(rest_1, Support.Bq.String.eq(a_0, C.Bq.text("server")))))); \{}}}

@unsafe
def Bq.log_printer():
  (word => C.Bq.word_case((@+lg_1: Chan<C.Bq.String> -> IO(Unit)), word, 0, (unit => (lg_0 => C.Bq.IO.pure(Unit, Unit{}))), (f_0 => (lg_1 => C.Bq.IO.bind(Result<&1, &1, C.Bq.Pair.Pair(U32, (__2 => C.Bq.String)), C.Bq.String>, Unit, C.Bq.Chan.recv(C.Bq.String, lg_1), \{Done: (line_2 => C.Bq.IO.bind(Unit, Unit, C.Bq.IO.print(Support.Bq.List.concat(Char, C.Bq.text("[bendquest] "), line_2)), (__3 => Bq.log_printer(f_0, lg_1)))); \{Fail: (e_2 => C.Bq.IO.pure(Unit, Unit{})); \{}}}))), 1))

@unsafe
def Bq.stat_drain():
  (word => C.Bq.word_case((@+stat_1: Chan<C.Bq.String> -> IO(Unit)), word, 0, (unit => (stat_0 => C.Bq.IO.pure(Unit, Unit{}))), (f_0 => (stat_1 => C.Bq.IO.bind(Result<&1, &1, C.Bq.Pair.Pair(U32, (__2 => C.Bq.String)), C.Bq.String>, Unit, C.Bq.Chan.recv(C.Bq.String, stat_1), \{Done: (line_2 => Bq.stat_drain(f_0, stat_1)); \{Fail: (e_2 => C.Bq.IO.pure(Unit, Unit{})); \{}}}))), 1))

@unsafe
def Bq.headless():
  (port_0 => C.Bq.IO.bind(Chan<C.Bq.String>, Unit, C.Bq.Chan.new(C.Bq.String, 256), (lg_1 => C.Bq.IO.bind(Chan<U32>, Unit, C.Bq.Chan.new(U32, 8), (ctl_2 => C.Bq.IO.bind(Chan<C.Bq.String>, Unit, C.Bq.Chan.new(C.Bq.String, 64), (stat_3 => C.Bq.IO.bind(Unit, Unit, C.Bq.IO.spawn(Bq.log_printer(Support.Bq.U32.MAX_VALUE, lg_1)), (__4 => C.Bq.IO.bind(Unit, Unit, C.Bq.IO.spawn(Bq.stat_drain(Support.Bq.U32.MAX_VALUE, stat_3)), (__5 => C.Bq.IO.bind(Unit, Unit, C.Bq.IO.print(Support.Bq.List.concat(Char, C.Bq.text("[bendquest] headless server starting on port "), Support.Bq.U32.show(port_0))), (__6 => Server.Bq.server_start(port_0, lg_1, ctl_2, stat_3))))))))))))))

@unsafe
def Bq.start():
  C.Bq.IO.bind(List<&1, C.Bq.String>, Unit, C.Bq.IO.args, (args_0 => (+mode_1 = Bq.pick_mode(args_0); (+apply_813 = {(mode_0 => \{True: Client.Bq.client_start; \{False: Bq.headless((mode_0 - 1 : U32)); \{}}}) : (@+mode_0: U32 -> (@+___1: Bool -> IO(Unit)))}; apply_813(mode_1, Support.Bq.Bool.from_u32(C.Bq.bit(U32.is_eq(mode_1, 0))))))))
