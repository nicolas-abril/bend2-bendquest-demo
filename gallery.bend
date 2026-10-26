# Dev-only sprite gallery: draws every asset (with layer tints) for a few
# frames, screenshots gallery_f0.png and gallery_f1.png, exits. Links
# raylib like build.sh:
#   bun ../bend2-core/bend2/main.ts gallery.bend -o .build/gallery.c
#   clang -std=c11 -w -O1 .build/gallery.c -o .build/gallery \
#     -I/opt/homebrew/include -L/opt/homebrew/lib -lraylib -lpthread -lm \
#     -framework Cocoa -framework IOKit -framework CoreVideo \
#     -framework CoreAudio -framework AudioToolbox
import Base
import ./sprites.bend as Sprites
import gralha-raylib@0.1.0.0/raylib.bend as RL

def white() -> U32:
  16777215

def spr(+tex: U32, +fi: U32, +fw: U32, +fh: U32, +x: U32, +y: U32, +sc: U32, +tint: U32) -> List<U32>:
  RL.sprite(tex, (fi * fw : U32), 0, fw, fh, x, y, (sc * 256 : U32), 0, tint)

def cat(xs: List<List<U32>>) -> List<U32>:
  match xs:
    case Nil{}:
      []
    case Con{x, rest}:
      List.append(&1, U32, x, cat(rest))

# The game's textures, copied out of its linear records so every row can
# read them.
type Tex is Data:
  Tex{body: U32, hair0: U32, hair1: U32, hair2: U32, outfit: U32, hat0: U32, hat1: U32, hat2: U32, cape0: U32, cape1: U32, slime: U32, spore: U32, bat: U32, golem: U32, wolf: U32, wisp: U32, mossback: U32, stonewarden: U32, rimehowl: U32, maw: U32, elder: U32, keeper: U32, tiles: U32, icons: U32, slash: U32, spark: U32}

def tex_of_parts(p: Sprites.Bq.TexPlr, m: Sprites.Bq.TexMob, w: Sprites.Bq.TexWld) -> Tex:
  Sprites.Bq.TexPlr.TexPlr{body, hair0, hair1, hair2, outfit, hat0, hat1, hat2, cape0, cape1} = p
  Sprites.Bq.TexMob.TexMob{slime, spore, bat, golem, wolf, wisp, mossback, stonewarden, rimehowl, maw} = m
  Sprites.Bq.TexWld.TexWld{elder, keeper, tiles, icons, slash, spark} = w
  Tex{body, hair0, hair1, hair2, outfit, hat0, hat1, hat2, cape0, cape1, slime, spore, bat, golem, wolf, wisp, mossback, stonewarden, rimehowl, maw, elder, keeper, tiles, icons, slash, spark}

def tex_of(a: Sprites.Bq.Assets) -> Tex:
  Sprites.Bq.Assets.Assets{p, m, w} = a
  tex_of_parts(p, m, w)

def player_cmds(+t: Tex, +x: U32, +y: U32, +f: U32, +skin: U32, +hairs: U32, +hairc: U32, +shirt: U32, +hat: U32, +cape: U32) -> List<U32>:
  Tex{body, hair0, hair1, hair2, outfit, hat0, hat1, hat2, cape0, cape1, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _} = t
  cat([
    spr(Sprites.Bq.pick2(cape, cape0, cape1), f, 16, 20, x, y, 3, white()),
    spr(body, f, 16, 20, x, y, 3, Sprites.Bq.skin_tint(skin)),
    spr(outfit, f, 16, 20, x, y, 3, Sprites.Bq.shirt_tint(shirt)),
    spr(Sprites.Bq.pick3(hairs, hair0, hair1, hair2), f, 16, 20, x, y, 3, Sprites.Bq.hair_tint(hairc)),
    spr(Sprites.Bq.pick3(hat, hat0, hat1, hat2), 0, 16, 20, x, ((y - 9 : U32) + (f * 3 : U32) : U32), 3, white())])

def mob_row(+t: Tex, +f: U32) -> List<U32>:
  Tex{_, _, _, _, _, _, _, _, _, _, slime, spore, bat, golem, wolf, wisp, mossback, stonewarden, rimehowl, maw, _, _, _, _, _, _} = t
  cat([
    spr(slime, f, 16, 16, 20, 240, 3, white()),
    spr(spore, f, 16, 16, 80, 240, 3, white()),
    spr(bat, f, 16, 16, 140, 240, 3, white()),
    spr(golem, f, 16, 16, 200, 240, 3, white()),
    spr(wolf, f, 16, 16, 260, 240, 3, white()),
    spr(wisp, f, 16, 16, 320, 240, 3, white()),
    spr(slime, f, 16, 16, 380, 240, 3, 4293444712),
    spr(wolf, f, 16, 16, 440, 240, 3, 4289761266),
    spr(mossback, f, 32, 32, 520, 210, 3, white()),
    spr(stonewarden, f, 32, 32, 630, 210, 3, white()),
    spr(rimehowl, f, 32, 32, 740, 210, 3, white()),
    spr(maw, f, 32, 32, 850, 210, 3, white())])

# Cells i = total-n .. total-1 of a 16-wide strip, laid out left to right.
def cells(+tex: U32, +total: U32, +y: U32, +n: Nat) -> List<U32>:
  match n:
    case 0n:
      []
    case 1n+m:
      +i = (total - (1 + U32.from_nat(m) : U32) : U32)
      List.append(&1, U32, spr(tex, i, 16, 16, (20 + (i * 58 : U32) : U32), y, 3, white()), cells(tex, total, y, m))

def icon_row(+t: Tex) -> List<U32>:
  Tex{_, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, elder, keeper, tiles, icons, slash, spark} = t
  cat([
    cells(tiles, 16, 360, 16n),
    cells(icons, 6, 440, 6n),
    spr(icons, 1, 16, 16, 380, 440, 3, 4288407039),
    spr(icons, 1, 16, 16, 440, 440, 3, 4294955366),
    spr(elder, 0, 16, 20, 520, 430, 3, white()),
    spr(keeper, 0, 16, 20, 580, 430, 3, white()),
    spr(slash, 0, 16, 16, 660, 440, 3, white()),
    spr(slash, 1, 16, 16, 720, 440, 3, white()),
    spr(spark, 0, 16, 16, 780, 440, 3, white()),
    spr(spark, 1, 16, 16, 840, 440, 3, white())])

def players_row(+t: Tex, +f: U32) -> List<U32>:
  cat([
    player_cmds(t, 20, 60, f, 0, 0, 0, 0, 0, 0),
    player_cmds(t, 90, 60, f, 1, 1, 1, 1, 1, 0),
    player_cmds(t, 160, 60, f, 2, 2, 2, 2, 2, 1),
    player_cmds(t, 230, 60, f, 3, 0, 3, 3, 0, 1),
    player_cmds(t, 300, 60, f, 0, 1, 4, 4, 1, 0),
    player_cmds(t, 370, 60, f, 1, 2, 5, 5, 2, 1)])

def frame(+t: Tex, +f: U32) -> List<U32>:
  cat([RL.clear(2761784), players_row(t, f), mob_row(t, f), icon_row(t)])

def wait_frames(+n: Nat, +t: Tex, +f: U32) -> IO(Unit):
  match n:
    case 0n:
      IO.pure(Unit, Unit{})
    case 1n+m:
      do IO<Unit>:
        RL.frame(frame(t, f))
        IO.sleep(16)
        wait_frames(m, t, f)

def main() -> IO(Unit):
  do IO<Unit>:
    RL.open("gallery", 960, 540)
    a : Sprites.Bq.Assets <- Sprites.Bq.load_assets
    +t : Tex = tex_of(a)
    wait_frames(10n, t, 0)
    RL.screenshot("gallery_f0.png")
    wait_frames(10n, t, 1)
    RL.screenshot("gallery_f1.png")
    RL.close()
    IO.print("gallery done")
