# Bendquest raylib: the game's names for gralha-raylib, over the compat
# layer's text (List<Char>) and byte (Bq.Bytes) types.
import Base
import ./compat.bend as C
import gralha-raylib@0.1.0.0/raylib.bend as RL

law Bq.rl_init:
  (@title_0: C.Bq.String -> (@+w_1: U32 -> (@+h_2: U32 -> IO(Unit))))

law Bq.rl_tex_load:
  (@+w_0: U32 -> (@+h_1: U32 -> (@pixels_2: C.Bq.Bytes -> IO(U32))))

law Bq.rl_font:
  (@path_0: C.Bq.String -> IO(Bool))

law Bq.rl_sound_load:
  (@samples_0: C.Bq.Bytes -> IO(U32))

law Bq.rl_input:
  IO(List<&1, U32>)

law Bq.rl_clipboard:
  (@text_0: C.Bq.String -> IO(Unit))

law Bq.rl_frame:
  (@cmds_0: List<&1, U32> -> IO(Unit))

law Bq.rl_screenshot:
  (@path_0: C.Bq.String -> IO(Unit))

law Bq.rl_should_close:
  IO(Bool)

law Bq.rl_shutdown:
  IO(Unit)

def Bq.rl_init(title_0, w_1, h_2):
  RL.open(C.Bq.untext(title_0), w_1, h_2)

def Bq.rl_tex_load(w_0, h_1, pixels_2):
  RL.texture(w_0, h_1, C.Bq.Bytes.to_list(pixels_2))

def Bq.rl_font(path_0):
  RL.font(C.Bq.untext(path_0))

def Bq.rl_sound_load(samples_0):
  RL.sound(C.Bq.Bytes.to_list(samples_0))

def Bq.rl_input():
  RL.input()

def Bq.rl_clipboard(text_0):
  RL.clipboard(C.Bq.untext(text_0))

def Bq.rl_frame(cmds_0):
  RL.frame(cmds_0)

def Bq.rl_screenshot(path_0):
  RL.screenshot(C.Bq.untext(path_0))

def Bq.rl_should_close():
  RL.should_close()

def Bq.rl_shutdown():
  RL.close()
