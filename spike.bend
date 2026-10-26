# Spike: proves the raylib wrapper end to end -- window, draw-list
# frame, text, input poll, clean shutdown. Runs ~180 frames then exits
# (or Esc / close button). Links raylib like build.sh:
#   bun ../bend2-core/bend2/main.ts spike.bend -o .build/spike.c
#   clang -std=c11 -w -O1 .build/spike.c -o .build/spike \
#     -I/opt/homebrew/include -L/opt/homebrew/lib -lraylib -lpthread -lm \
#     -framework Cocoa -framework IOKit -framework CoreVideo \
#     -framework CoreAudio -framework AudioToolbox

import Base
import gralha-raylib@0.1.0.0/raylib.bend as RL

def frame_cmds(+t: U32) -> List<U32>:
  List.append(&1, U32, RL.clear(1710638),
  List.append(&1, U32, RL.rect((40 + U32.mod(t, 400) : U32), 100, 60, 60, 16739229),
  List.append(&1, U32, RL.rect_lines(40, 200, 200, 80, 65450),
  List.append(&1, U32, RL.circle(400, 300, 30, 16765286),
  List.append(&1, U32, RL.sprite(0, 0, 0, 4, 4, 500, 100, 4096, 0, 16777215),
  List.append(&1, U32, RL.sprite(0, 0, 0, 4, 4, 600, 100, 4096, 1, 16777215),
  RL.text(40, 40, 30, 16777215, "BendQuest raylib spike")))))))

# A 4x4 RGBA test texture: magenta/teal checker with one red corner.
def checker_px(+i: U32) -> List<U32>:
  +even = U32.is_eq(U32.mod((U32.mod(i, 4) + U32.div(i, 4) : U32), 2), 0)
  Bool.pick(List<U32>, U32.is_eq(i, 0), [255, 0, 0, 255],
    Bool.pick(List<U32>, even, [255, 0, 255, 255], [0, 200, 180, 255]))

def checker_go(+k: Nat) -> List<U32>:
  match k:
    case 0n:
      []
    case 1n+j:
      List.append(&1, U32, checker_px((15 - U32.from_nat(j) : U32)), checker_go(j))

def esc_held(ws: List<U32>) -> Bool:
  RL.bit(RL.first(ws), 11n)

def maybe_shot(+shoot: Bool) -> IO(Unit):
  match shoot:
    case True{}:
      RL.screenshot("spike_frame.png")
    case False{}:
      IO.pure(Unit, Unit{})

def loop(+fuel: Nat, +stop: Bool, +t: U32) -> IO(Unit):
  match fuel:
    case 0n:
      IO.pure(Unit, Unit{})
    case 1n+f:
      match stop:
        case True{}:
          IO.pure(Unit, Unit{})
        case False{}:
          do IO<Unit>:
            RL.frame(frame_cmds(t))
            inp : List<U32> <- RL.input()
            maybe_shot(Nat.is_eq(f, 60n))
            closed : Bool <- RL.should_close()
            IO.sleep(16)
            loop(f, closed || esc_held(inp), (t + 4 : U32))

def main() -> IO(Unit):
  do IO<Unit>:
    RL.open("bendquest spike", 800, 600)
    tex : U32 <- RL.texture(4, 4, checker_go(16n))
    IO.print("tex id: " ++ U32.show(tex))
    loop(180n, False{}, 0)
    RL.close()
    IO.print("spike ok")
