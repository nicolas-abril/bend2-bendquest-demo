# Dev-only sprite gallery: draws every asset (with layer tints) once,
# screenshots, exits. bend gallery.bend -o gallery && ./gallery

import ../../bend3/bend-base/Base
import ./raylib
import ./sprites

def spr(tex: U32, fi: U32, fw: U32, fh: U32, x: U32, y: U32, sc: U32, tint: U32) -> List(U32):
  [6, tex, fi * fw, 0, fw, fh, x, y, sc * 256, 0, tint]

def player_cmds(a: Assets, x: U32, y: U32, f: U32, skin: U32, hairs: U32, hairc: U32, shirt: U32, hat: U32, cape: U32) -> List(U32):
  TexPlr.TexPlr{body, hair0, hair1, hair2, outfit, hat0, hat1, hat2, cape0, cape1} = a_plr(a)
  hairtex = pick3(hairs, hair0, hair1, hair2)
  hattex = pick3(hat, hat0, hat1, hat2)
  capetex = pick2(cape, cape0, cape1)
  capepart = spr(capetex, f, 16, 20, x, y, 3, 0xFFFFFF)
  hatpart = spr(hattex, 0, 16, 20, x, (y - (3 * 3)) + (f * 3), 3, 0xFFFFFF)
  List.flatten(U32, [
    capepart,
    spr(body, f, 16, 20, x, y, 3, skin_tint(skin)),
    spr(outfit, f, 16, 20, x, y, 3, shirt_tint(shirt)),
    spr(hairtex, f, 16, 20, x, y, 3, hair_tint(hairc)),
    hatpart])

def mob_row(a: Assets, f: U32) -> List(U32):
  TexMob.TexMob{slime, spore, bat, golem, wolf, wisp, mossback, stonewarden, rimehowl, maw} = a_mob(a)
  List.flatten(U32, [
    spr(slime, f, 16, 16, 20, 240, 3, 0xFFFFFF),
    spr(spore, f, 16, 16, 80, 240, 3, 0xFFFFFF),
    spr(bat, f, 16, 16, 140, 240, 3, 0xFFFFFF),
    spr(golem, f, 16, 16, 200, 240, 3, 0xFFFFFF),
    spr(wolf, f, 16, 16, 260, 240, 3, 0xFFFFFF),
    spr(wisp, f, 16, 16, 320, 240, 3, 0xFFFFFF),
    spr(slime, f, 16, 16, 380, 240, 3, 0xFFE8C468),
    spr(wolf, f, 16, 16, 440, 240, 3, 0xFFB08FF2),
    spr(mossback, f, 32, 32, 520, 210, 3, 0xFFFFFF),
    spr(stonewarden, f, 32, 32, 630, 210, 3, 0xFFFFFF),
    spr(rimehowl, f, 32, 32, 740, 210, 3, 0xFFFFFF),
    spr(maw, f, 32, 32, 850, 210, 3, 0xFFFFFF)])

# explicit countdown recursions (a field-capturing lambda under a wide
# destructure is the compiler's worst case)
def tile_cells(tiles: U32, n: U32) -> List(U32):
  match n:
    case 0:
      []
    case 1+n2:
      i = 16 - (1 + n2)
      spr(tiles, i, 16, 16, 20 + (i * 58), 360, 3, 0xFFFFFF) ++ tile_cells(tiles, n2)

def tile_row(a: Assets) -> List(U32):
  tile_cells(a_tiles(a), 16)

def icon_cells(icons: U32, n: U32) -> List(U32):
  match n:
    case 0:
      []
    case 1+n2:
      i = 6 - (1 + n2)
      spr(icons, i, 16, 16, 20 + (i * 58), 440, 3, 0xFFFFFF) ++ icon_cells(icons, n2)

def icon_row(a: Assets) -> List(U32):
  TexWld.TexWld{elder, keeper, tiles, icons, slash, spark} = a_wld(a)
  List.flatten(U32, [
    icon_cells(icons, 6),
    spr(icons, 1, 16, 16, 380, 440, 3, 0xFF9BE5FF),
    spr(icons, 1, 16, 16, 440, 440, 3, 0xFFFFD166),
    spr(elder, 0, 16, 20, 520, 430, 3, 0xFFFFFF),
    spr(keeper, 0, 16, 20, 580, 430, 3, 0xFFFFFF),
    spr(slash, 0, 16, 16, 660, 440, 3, 0xFFFFFF),
    spr(slash, 1, 16, 16, 720, 440, 3, 0xFFFFFF),
    spr(spark, 0, 16, 16, 780, 440, 3, 0xFFFFFF),
    spr(spark, 1, 16, 16, 840, 440, 3, 0xFFFFFF)])

def players_row(a: Assets, f: U32) -> List(U32):
  List.flatten(U32, [
    player_cmds(a, 20, 60, f, 0, 0, 0, 0, 0, 0),
    player_cmds(a, 90, 60, f, 1, 1, 1, 1, 1, 0),
    player_cmds(a, 160, 60, f, 2, 2, 2, 2, 2, 1),
    player_cmds(a, 230, 60, f, 3, 0, 3, 3, 0, 1),
    player_cmds(a, 300, 60, f, 0, 1, 4, 4, 1, 0),
    player_cmds(a, 370, 60, f, 1, 2, 5, 5, 2, 1)])

def frame(a: Assets, f: U32) -> List(U32):
  List.flatten(U32, [
    [0, 0x2A2438],
    players_row(a, f),
    mob_row(a, f),
    tile_row(a),
    icon_row(a)])

def wait_frames(n: U32, a: Assets, f: U32) -> IO(Unit):
  match n:
    case 0:
      IO.pure(Unit, Unit.U{})
    case 1+m:
      do IO(Unit):
        rl_frame(frame(a, f))
        IO.sleep(16)
        wait_frames(m, a, f)

def main() -> IO(Unit):
  do IO(Unit):
    rl_init("gallery", 960, 540)
    a <- load_assets()
    wait_frames(10, a, 0)
    rl_screenshot("gallery_f0.png")
    wait_frames(10, a, 1)
    rl_screenshot("gallery_f1.png")
    rl_shutdown()
    IO.print("gallery done")
