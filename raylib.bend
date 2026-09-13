# Bendquest raylib. Current Bend syntax; see README.md for the port notes.
import Base
import ./compat.bend as C
import ./support.bend as Support

law Bq.window:
  (@+title_0: C.Bq.String -> (@+w_1: U32 -> (@+h_2: U32 -> IO(Unit))))

law Bq.rl_init:
  (@+title_0: C.Bq.String -> (@+w_1: U32 -> (@+h_2: U32 -> IO(Unit))))

law Bq.blit:
  (@+cmds_0: List<&1, U32> -> IO(Unit))

law Bq.gfx_events:
  IO(List<&1, U32>)

law Bq.reply1:
  (@+ws_0: List<&1, U32> -> U32)

law Bq.rl_query:
  (@+cmds_0: List<&1, U32> -> IO(U32))

law Bq.rl_tex_load:
  (@+w_0: U32 -> (@+h_1: U32 -> (@+pixels_2: C.Bq.Bytes -> IO(U32))))

law Bq.str_words:
  (@+s_0: C.Bq.String -> List<&1, U32>)

law Bq.rl_font:
  (@+path_0: C.Bq.String -> IO(Bool))

law Bq.rl_sound_load:
  (@+samples_0: C.Bq.Bytes -> IO(U32))

law Bq.rl_input:
  IO(List<&1, U32>)

law Bq.rl_clipboard:
  (@+text_0: C.Bq.String -> IO(Unit))

law Bq.rl_frame:
  (@+cmds_0: List<&1, U32> -> IO(Unit))

law Bq.rl_screenshot:
  (@+path_0: C.Bq.String -> IO(Unit))

law Bq.rl_should_close:
  IO(Bool)

law Bq.rl_shutdown:
  IO(Unit)

@unsafe
def Bq.window(title_0, w_1, h_2):
  import "./effs/raylib.c"

@unsafe
def Bq.rl_init():
  (title_0 => (w_1 => (h_2 => Bq.window(title_0, w_1, h_2))))

@unsafe
def Bq.blit(cmds_0):
  import "./effs/raylib.c"

@unsafe
def Bq.gfx_events():
  import "./effs/raylib.c"

@unsafe
def Bq.reply1():
  \{Nil: 0; \{Con: (w_0 => (rest_1 => w_0)); \{}}}

@unsafe
def Bq.rl_query():
  (cmds_0 => C.Bq.IO.bind(Unit, U32, Bq.blit(cmds_0), (__1 => C.Bq.IO.bind(List<&1, U32>, U32, Bq.gfx_events, (r_2 => C.Bq.IO.pure(U32, Bq.reply1(r_2)))))))

@unsafe
def Bq.rl_tex_load():
  (w_0 => (h_1 => (pixels_2 => (+bs_3 = C.Bq.Bytes.to_list(pixels_2); Bq.rl_query(Support.Bq.List.concat(U32, [20, w_0, h_1, Support.Bq.List.length(U32, bs_3)], bs_3))))))

@unsafe
def Bq.str_words():
  (s_0 => Support.Bq.List.map_0(s_0))

@unsafe
def Bq.rl_font():
  (path_0 => (+cs_1 = Bq.str_words(path_0); C.Bq.IO.bind(U32, Bool, Bq.rl_query(Support.Bq.List.concat(U32, [22, Support.Bq.List.length(U32, cs_1)], cs_1)), (r_2 => C.Bq.IO.pure(Bool, Support.Bq.Bool.from_u32(r_2))))))

@unsafe
def Bq.rl_sound_load():
  (samples_0 => (+bs_1 = C.Bq.Bytes.to_list(samples_0); Bq.rl_query(Support.Bq.List.concat(U32, [21, Support.Bq.List.length(U32, bs_1)], bs_1))))

@unsafe
def Bq.rl_input():
  Bq.gfx_events

@unsafe
def Bq.rl_clipboard():
  (text_0 => (+cs_1 = Bq.str_words(text_0); Bq.blit(Support.Bq.List.concat(U32, [23, Support.Bq.List.length(U32, cs_1)], cs_1))))

@unsafe
def Bq.rl_frame():
  (cmds_0 => Bq.blit(cmds_0))

@unsafe
def Bq.rl_screenshot():
  (path_0 => (+cs_1 = Bq.str_words(path_0); Bq.blit(Support.Bq.List.concat(U32, [24, Support.Bq.List.length(U32, cs_1)], cs_1))))

@unsafe
def Bq.rl_should_close():
  C.Bq.IO.bind(U32, Bool, Bq.rl_query([26]), (r_0 => C.Bq.IO.pure(Bool, Support.Bq.Bool.from_u32(r_0))))

@unsafe
def Bq.rl_shutdown():
  Bq.blit([25])
