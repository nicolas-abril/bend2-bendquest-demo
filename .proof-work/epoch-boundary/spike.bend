# Spike: proves the raylib wrapper end to end -- window, draw-list
# frame, text, input poll, clean shutdown. Runs ~180 frames then exits
# (or Esc / close button).
#   bend spike.bend -o spike && ./spike

import ../../bend3/bend-base/Base
import ./raylib

def text_cmd(x: U32, y: U32, size: U32, color: U32, s: String) -> List(U32):
  cps = List.map(Char, U32, c => Char.code(c), s)
  n = List.length(U32, cps)
  [3, x, y, size, color, n] ++ cps

def frame_cmds(t: U32) -> List(U32):
  List.flatten(U32, [
    [0, 0x1A1A2E],
    [1, 40 + (t % 400), 100, 60, 60, 0xFF6B9D],
    [2, 40, 200, 200, 80, 0x00FFAA],
    [4, 400, 300, 30, 0xFFD166],
    [6, 0, 0, 0, 4, 4, 500, 100, 16 * 256, 0, 0xFFFFFF],
    [6, 0, 0, 0, 4, 4, 600, 100, 16 * 256, 1, 0xFFFFFF],
    text_cmd(40, 40, 30, 0xFFFFFF, "BendQuest raylib spike")])

# a 4x4 RGBA test texture: magenta/teal checker with one red corner
def checker_px(i: U32) -> List(U32):
  x = (i % 4)
  y = (i / 4)
  match i == 0:
    case Bool.T{}:
      [255, 0, 0, 255]
    case Bool.F{}:
      match ((x + y) % 2) == 0:
        case Bool.T{}:
          [255, 0, 255, 255]
        case Bool.F{}:
          [0, 200, 180, 255]

def checker_go(k: U32) -> List(U32):
  match k:
    case 0:
      []
    case 1+j:
      checker_px(15 - j) ++ checker_go(j)

def checker() -> Bytes:
  Bytes.pack(checker_go(16))

def esc_held(ws: List(U32)) -> Bool:
  match ws:
    case List.Nil{}:
      Bool.F{}
    case List.Cons{held, rest}:
      Bool.from_u32((held >> 11) .&. 1)

def maybe_shot(f: U32) -> IO(Unit):
  match f == 60:
    case Bool.T{}:
      rl_screenshot("spike_frame.png")
    case Bool.F{}:
      IO.pure(Unit, Unit.U{})

def loop(fuel: U32, t: U32) -> IO(Unit):
  match fuel:
    case 0:
      IO.pure(Unit, Unit.U{})
    case 1+f:
      do IO(Unit):
        rl_frame(frame_cmds(t))
        inp <- rl_input()
        maybe_shot(f)
        stop1 <- rl_should_close()
        match Bool.or(stop1, esc_held(inp)):
          case Bool.T{}:
            IO.pure(Unit, Unit.U{})
          case Bool.F{}:
            do IO(Unit):
              IO.sleep(16)
              loop(f, t + 4)

def main() -> IO(Unit):
  do IO(Unit):
    rl_init("bendquest spike", 800, 600)
    tex <- rl_tex_load(4, 4, checker())
    IO.print("tex id: " ++ U32.show(tex))
    loop(180, 0)
    rl_shutdown()
    IO.print("spike ok")
