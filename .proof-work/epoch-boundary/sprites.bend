# Bendquest sprites. Current Bend syntax; see README.md for the port notes.
import Base
import ./compat.bend as C
import ./support.bend as Support
import ./raylib.bend as Raylib

type Bq.TexPlr is Type:
  Bq.TexPlr.TexPlr{body_0: U32, hair0_1: U32, hair1_2: U32, hair2_3: U32, outfit_4: U32, hat0_5: U32, hat1_6: U32, hat2_7: U32, cape0_8: U32, cape1_9: U32}

type Bq.TexMob is Type:
  Bq.TexMob.TexMob{slime_0: U32, spore_1: U32, bat_2: U32, golem_3: U32, wolf_4: U32, wisp_5: U32, mossback_6: U32, stonewarden_7: U32, rimehowl_8: U32, maw_9: U32}

type Bq.TexWld is Type:
  Bq.TexWld.TexWld{elder_0: U32, keeper_1: U32, tiles_2: U32, icons_3: U32, slash_4: U32, spark_5: U32}

type Bq.Assets is Type:
  Bq.Assets.Assets{plr_0: Bq.TexPlr, mob_1: Bq.TexMob, wld_2: Bq.TexWld}

law Bq.pal_get:
  (@+pal_0: List<&1, C.Bq.Pair.Pair(U32, (__0 => U32))> -> (@+c_1: U32 -> U32))

law Bq.row_px:
  (@+row_0: C.Bq.String -> (@+pal_1: List<&1, C.Bq.Pair.Pair(U32, (__1 => U32))> -> List<&1, U32>))

law Bq.rows_px:
  (@+rows_0: List<&1, C.Bq.String> -> (@+pal_1: List<&1, C.Bq.Pair.Pair(U32, (__1 => U32))> -> List<&1, U32>))

law Bq.hcat_rows:
  (@+a_0: List<&1, C.Bq.String> -> (@+b_1: List<&1, C.Bq.String> -> List<&1, C.Bq.String>))

law Bq.hcat_all:
  (@+fs_0: List<&1, List<&1, C.Bq.String>> -> List<&1, C.Bq.String>)

law Bq.load_strip:
  (@+fw_0: U32 -> (@+fh_1: U32 -> (@+fs_2: List<&1, List<&1, C.Bq.String>> -> (@+pal_3: List<&1, C.Bq.Pair.Pair(U32, (__3 => U32))> -> IO(U32)))))

law Bq.body_f0:
  List<&1, C.Bq.String>

law Bq.body_f1:
  List<&1, C.Bq.String>

law Bq.ramp:
  List<&1, C.Bq.Pair.Pair(U32, (__0 => U32))>

law Bq.hair0_f0:
  List<&1, C.Bq.String>

law Bq.shift_down:
  (@+rows_0: List<&1, C.Bq.String> -> List<&1, C.Bq.String>)

law Bq.hair0_f1:
  List<&1, C.Bq.String>

law Bq.hair1_f0:
  List<&1, C.Bq.String>

law Bq.hair1_f1:
  List<&1, C.Bq.String>

law Bq.hair2_f0:
  List<&1, C.Bq.String>

law Bq.hair2_f1:
  List<&1, C.Bq.String>

law Bq.outfit_f0:
  List<&1, C.Bq.String>

law Bq.outfit_f1:
  List<&1, C.Bq.String>

law Bq.outfit_pal:
  List<&1, C.Bq.Pair.Pair(U32, (__0 => U32))>

law Bq.hat0_f0:
  List<&1, C.Bq.String>

law Bq.hat0_pal:
  List<&1, C.Bq.Pair.Pair(U32, (__0 => U32))>

law Bq.hat1_f0:
  List<&1, C.Bq.String>

law Bq.hat1_pal:
  List<&1, C.Bq.Pair.Pair(U32, (__0 => U32))>

law Bq.hat2_f0:
  List<&1, C.Bq.String>

law Bq.hat2_pal:
  List<&1, C.Bq.Pair.Pair(U32, (__0 => U32))>

law Bq.cape0_f0:
  List<&1, C.Bq.String>

law Bq.cape0_f1:
  List<&1, C.Bq.String>

law Bq.cape0_pal:
  List<&1, C.Bq.Pair.Pair(U32, (__0 => U32))>

law Bq.cape1_f0:
  List<&1, C.Bq.String>

law Bq.cape1_f1:
  List<&1, C.Bq.String>

law Bq.cape1_pal:
  List<&1, C.Bq.Pair.Pair(U32, (__0 => U32))>

law Bq.slime_f0:
  List<&1, C.Bq.String>

law Bq.slime_f1:
  List<&1, C.Bq.String>

law Bq.slime_pal:
  List<&1, C.Bq.Pair.Pair(U32, (__0 => U32))>

law Bq.spore_f0:
  List<&1, C.Bq.String>

law Bq.spore_f1:
  List<&1, C.Bq.String>

law Bq.spore_pal:
  List<&1, C.Bq.Pair.Pair(U32, (__0 => U32))>

law Bq.bat_f0:
  List<&1, C.Bq.String>

law Bq.bat_f1:
  List<&1, C.Bq.String>

law Bq.bat_pal:
  List<&1, C.Bq.Pair.Pair(U32, (__0 => U32))>

law Bq.golem_f0:
  List<&1, C.Bq.String>

law Bq.golem_f1:
  List<&1, C.Bq.String>

law Bq.golem_pal:
  List<&1, C.Bq.Pair.Pair(U32, (__0 => U32))>

law Bq.wolf_f0:
  List<&1, C.Bq.String>

law Bq.wolf_f1:
  List<&1, C.Bq.String>

law Bq.wolf_pal:
  List<&1, C.Bq.Pair.Pair(U32, (__0 => U32))>

law Bq.wisp_f0:
  List<&1, C.Bq.String>

law Bq.wisp_f1:
  List<&1, C.Bq.String>

law Bq.wisp_pal:
  List<&1, C.Bq.Pair.Pair(U32, (__0 => U32))>

law Bq.mossback_f0:
  List<&1, C.Bq.String>

law Bq.mossback_f1:
  List<&1, C.Bq.String>

law Bq.mossback_pal:
  List<&1, C.Bq.Pair.Pair(U32, (__0 => U32))>

law Bq.stonewarden_f0:
  List<&1, C.Bq.String>

law Bq.stonewarden_f1:
  List<&1, C.Bq.String>

law Bq.stonewarden_pal:
  List<&1, C.Bq.Pair.Pair(U32, (__0 => U32))>

law Bq.rimehowl_f0:
  List<&1, C.Bq.String>

law Bq.rimehowl_f1:
  List<&1, C.Bq.String>

law Bq.rimehowl_pal:
  List<&1, C.Bq.Pair.Pair(U32, (__0 => U32))>

law Bq.maw_f0:
  List<&1, C.Bq.String>

law Bq.maw_f1:
  List<&1, C.Bq.String>

law Bq.maw_pal:
  List<&1, C.Bq.Pair.Pair(U32, (__0 => U32))>

law Bq.elder_f0:
  List<&1, C.Bq.String>

law Bq.elder_pal:
  List<&1, C.Bq.Pair.Pair(U32, (__0 => U32))>

law Bq.keeper_f0:
  List<&1, C.Bq.String>

law Bq.keeper_pal:
  List<&1, C.Bq.Pair.Pair(U32, (__0 => U32))>

law Bq.tile_grass:
  List<&1, C.Bq.String>

law Bq.tile_flowers:
  List<&1, C.Bq.String>

law Bq.tile_tree:
  List<&1, C.Bq.String>

law Bq.tile_water:
  List<&1, C.Bq.String>

law Bq.tile_path:
  List<&1, C.Bq.String>

law Bq.tile_rock:
  List<&1, C.Bq.String>

law Bq.tile_cavefloor:
  List<&1, C.Bq.String>

law Bq.tile_cavewall:
  List<&1, C.Bq.String>

law Bq.tile_crystal:
  List<&1, C.Bq.String>

law Bq.tile_snow:
  List<&1, C.Bq.String>

law Bq.tile_ice:
  List<&1, C.Bq.String>

law Bq.tile_snowtree:
  List<&1, C.Bq.String>

law Bq.tile_portal:
  List<&1, C.Bq.String>

law Bq.tile_riftfloor:
  List<&1, C.Bq.String>

law Bq.tile_riftportal:
  List<&1, C.Bq.String>

law Bq.tile_shopmat:
  List<&1, C.Bq.String>

law Bq.tiles_pal:
  List<&1, C.Bq.Pair.Pair(U32, (__0 => U32))>

law Bq.icon_potion:
  List<&1, C.Bq.String>

law Bq.icon_sword:
  List<&1, C.Bq.String>

law Bq.icon_axe:
  List<&1, C.Bq.String>

law Bq.icon_armor:
  List<&1, C.Bq.String>

law Bq.icon_helm:
  List<&1, C.Bq.String>

law Bq.icon_charm:
  List<&1, C.Bq.String>

law Bq.icon_pal:
  List<&1, C.Bq.Pair.Pair(U32, (__0 => U32))>

law Bq.slash_f0:
  List<&1, C.Bq.String>

law Bq.slash_f1:
  List<&1, C.Bq.String>

law Bq.fx_pal:
  List<&1, C.Bq.Pair.Pair(U32, (__0 => U32))>

law Bq.spark_f0:
  List<&1, C.Bq.String>

law Bq.spark_f1:
  List<&1, C.Bq.String>

law Bq.load_assets:
  IO(Bq.Assets)

law Bq.a_wld:
  (@+a_0: Bq.Assets -> Bq.TexWld)

law Bq.a_tiles:
  (@+a_0: Bq.Assets -> U32)

law Bq.a_mob:
  (@+a_0: Bq.Assets -> Bq.TexMob)

law Bq.pick2:
  (@+i_0: U32 -> (@+a_1: U32 -> (@+b_2: U32 -> U32)))

law Bq.a_plr:
  (@+a_0: Bq.Assets -> Bq.TexPlr)

law Bq.pick3:
  (@+i_0: U32 -> (@+a_1: U32 -> (@+b_2: U32 -> (@+c_3: U32 -> U32))))

law Bq.skin_tint:
  (@+i_0: U32 -> U32)

law Bq.shirt_tint:
  (@+i_0: U32 -> U32)

law Bq.hair_tint:
  (@+i_0: U32 -> U32)

law Bq.a_icons:
  (@+a_0: Bq.Assets -> U32)

@unsafe
def Bq.pal_get():
  \{Nil: (c_0 => 0); \{Con: \{Tuple: (k_0 => (col_1 => (rest_2 => (c_3 => (+apply_9 = {(rest_0 => (c_1 => (k_2 => (col_3 => (word => C.Bq.word_case(U32, word, 0, (unit => Bq.pal_get(rest_0, c_1)), (_7_4 => col_3), 0)))))) : (@+rest_0: List<&1, C.Bq.Pair.Pair(U32, (__0 => U32))> -> (@+c_1: U32 -> (@-k_2: U32 -> (@+col_3: (__3 => U32)(k_2) -> (@+___4: U32 -> U32)))))}; apply_9(rest_2, c_3, k_0, col_1, C.Bq.bit(U32.is_eq(k_0, c_3)))))))); \{}}; \{}}}

@unsafe
def Bq.row_px():
  \{Nil: (pal_0 => Nil{}); \{Con: (ch_0 => (rest_1 => (pal_2 => (+c_3 = Support.Bq.Char.code(ch_0); (+apply_10 = {(pal_0 => (c_1 => (rest_2 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => (+col_3 = Bq.pal_get(pal_0, c_1); Support.Bq.List.concat(U32, [(U32.shrn(col_3, U32.to_nat(16)) .&. 255 : U32), (U32.shrn(col_3, U32.to_nat(8)) .&. 255 : U32), (col_3 .&. 255 : U32), (U32.shrn(col_3, U32.to_nat(24)) .&. 255 : U32)], Bq.row_px(rest_2, pal_0)))), (_15_3 => Support.Bq.List.concat(U32, [0, 0, 0, 0], Bq.row_px(rest_2, pal_0))), 0))))) : (@+pal_0: List<&1, C.Bq.Pair.Pair(U32, (__0 => U32))> -> (@+c_1: U32 -> (@+rest_2: List<&1, Char> -> (@+___3: U32 -> List<&1, U32>))))}; apply_10(pal_2, c_3, rest_1, C.Bq.bit(U32.is_eq(c_3, 46)))))))); \{}}}

@unsafe
def Bq.rows_px():
  \{Nil: (pal_0 => Nil{}); \{Con: (r_0 => (rest_1 => (pal_2 => Support.Bq.List.concat(U32, Bq.row_px(r_0, pal_2), Bq.rows_px(rest_1, pal_2))))); \{}}}

@unsafe
def Bq.hcat_rows():
  \{Nil: (b_0 => b_0); \{Con: (ra_0 => (resta_1 => \{Nil: Con{ra_0, resta_1}; \{Con: (rb_2 => (restb_3 => Con{Support.Bq.List.concat(Char, ra_0, rb_2), Bq.hcat_rows(resta_1, restb_3)})); \{}}})); \{}}}

@unsafe
def Bq.hcat_all():
  \{Nil: Nil{}; \{Con: (f_0 => (rest_1 => Bq.hcat_rows(f_0, Bq.hcat_all(rest_1)))); \{}}}

@unsafe
def Bq.load_strip():
  (fw_0 => (fh_1 => (fs_2 => (pal_3 => (+n_4 = Support.Bq.List.length(List<&1, C.Bq.String>, fs_2); Raylib.Bq.rl_tex_load((fw_0 * n_4 : U32), fh_1, C.Bq.Bytes.pack(Bq.rows_px(Bq.hcat_all(fs_2), pal_3))))))))

@unsafe
def Bq.body_f0():
  [C.Bq.text("....oooooooo...."), C.Bq.text("...o55555555o..."), C.Bq.text("..o5555555555o.."), C.Bq.text(".o555555555555o."), C.Bq.text(".o555555555555o."), C.Bq.text(".o555555555555o."), C.Bq.text(".o5e5555555e55o."), C.Bq.text(".o5e5555555e55o."), C.Bq.text(".o555555555555o."), C.Bq.text("..o55555555554o."), C.Bq.text("...oo555555oo..."), C.Bq.text("....o444444o...."), C.Bq.text("...o55555555o..."), C.Bq.text("...o55555555o..."), C.Bq.text("...o55o55o55o..."), C.Bq.text("....o44o444o...."), C.Bq.text("....o44o444o...."), C.Bq.text("....o44o444o...."), C.Bq.text("...oo44oo44oo..."), C.Bq.text("...oooo..oooo...")]

@unsafe
def Bq.body_f1():
  [C.Bq.text("................"), C.Bq.text("....oooooooo...."), C.Bq.text("...o55555555o..."), C.Bq.text("..o5555555555o.."), C.Bq.text(".o555555555555o."), C.Bq.text(".o555555555555o."), C.Bq.text(".o5e5555555e55o."), C.Bq.text(".o5e5555555e55o."), C.Bq.text(".o555555555555o."), C.Bq.text("..o55555555554o."), C.Bq.text("...oo555555oo..."), C.Bq.text("....o444444o...."), C.Bq.text("...o55555555o..."), C.Bq.text("...o55555555o..."), C.Bq.text("...o55o55o55o..."), C.Bq.text("....o44o44o....."), C.Bq.text("...o44oo444o...."), C.Bq.text("...o44o..o44o..."), C.Bq.text("..oo44o..o44oo.."), C.Bq.text("..oooo....oooo..")]

@unsafe
def Bq.ramp():
  [Tuple{53, 4294967295}, Tuple{52, 4291809231}, Tuple{51, 4289243304}, Tuple{111, 4279505940}, Tuple{101, 4279505940}, Tuple{119, 4294967295}]

@unsafe
def Bq.hair0_f0():
  [C.Bq.text("..5.o55o.5o....."), C.Bq.text("..o55555555o...."), C.Bq.text(".o5545554555o..."), C.Bq.text("o55455545554o..."), C.Bq.text("o45555555555o5.."), C.Bq.text(".o44o55554o44o.."), C.Bq.text("....o4444o......"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................")]

@unsafe
def Bq.shift_down():
  (rows_0 => Con{C.Bq.text("................"), Support.Bq.List.take(C.Bq.String, 19, rows_0)})

@unsafe
def Bq.hair0_f1():
  Bq.shift_down(Bq.hair0_f0)

@unsafe
def Bq.hair1_f0():
  [C.Bq.text("....o55555o....."), C.Bq.text("..o555555555o..."), C.Bq.text(".o55555555555o.."), C.Bq.text(".o55455555455o.."), C.Bq.text("o5545555555455o."), C.Bq.text("o5455555555545o."), C.Bq.text("o54o5555555o45o."), C.Bq.text("o44o.......o44o."), C.Bq.text(".oo.........oo.."), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................")]

@unsafe
def Bq.hair1_f1():
  Bq.shift_down(Bq.hair1_f0)

@unsafe
def Bq.hair2_f0():
  [C.Bq.text("....o55555o....."), C.Bq.text("..o555555555o..."), C.Bq.text(".o55555555555o.."), C.Bq.text(".o55545554555o.."), C.Bq.text("o5545555555555o."), C.Bq.text("o54555555555545o"), C.Bq.text("o5455555555554o."), C.Bq.text("o545o55555o545o."), C.Bq.text("o44o.....o544o.."), C.Bq.text("o44o.....o44o..."), C.Bq.text("o44o.....o44o..."), C.Bq.text(".oo|......oo...."), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................")]

@unsafe
def Bq.hair2_f1():
  Bq.shift_down(Bq.hair2_f0)

@unsafe
def Bq.outfit_f0():
  [C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("...oo555555oo..."), C.Bq.text("..o5544444455o.."), C.Bq.text("..o5555555555o.."), C.Bq.text("...o55o55o55o..."), C.Bq.text("....o..o...o...."), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("...obbboobbbo..."), C.Bq.text("...oooo..oooo...")]

@unsafe
def Bq.outfit_f1():
  [C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("...oo555555oo..."), C.Bq.text("..o5544444455o.."), C.Bq.text("..o5555555555o.."), C.Bq.text("....o..o..o....."), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("..obbbo..obbbo.."), C.Bq.text("..oooo....oooo..")]

@unsafe
def Bq.outfit_pal():
  Support.Bq.List.concat(C.Bq.Pair.Pair(U32, (__0 => U32)), Bq.ramp, [Tuple{98, 4283054936}])

@unsafe
def Bq.hat0_f0():
  [C.Bq.text("......ood......."), C.Bq.text("..oogggggdoo...."), C.Bq.text(".ogggggggggdo..."), C.Bq.text("ogggggggggggdo.."), C.Bq.text(".oodddddddddoo.."), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................")]

@unsafe
def Bq.hat0_pal():
  [Tuple{103, 4284729165}, Tuple{100, 4282288456}, Tuple{111, 4279505940}]

@unsafe
def Bq.hat1_f0():
  [C.Bq.text(".......oo......."), C.Bq.text("......opdo......"), C.Bq.text(".....oppddo....."), C.Bq.text("....opppdddo...."), C.Bq.text("...oppypdddo...."), C.Bq.text("..opppppddddo..."), C.Bq.text(".oppppppdddddo.."), C.Bq.text("oooooooooooooo.."), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................")]

@unsafe
def Bq.hat1_pal():
  [Tuple{112, 4286271413}, Tuple{100, 4283839879}, Tuple{121, 4294955366}, Tuple{111, 4279505940}]

@unsafe
def Bq.hat2_f0():
  [C.Bq.text("..oy..oyo..yo..."), C.Bq.text("..oyoyoryoyyo..."), C.Bq.text("..oyyyyyyyyyo..."), C.Bq.text("..odddddddddo..."), C.Bq.text("...ooooooooo...."), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................")]

@unsafe
def Bq.hat2_pal():
  [Tuple{121, 4294955366}, Tuple{100, 4293436221}, Tuple{114, 4293413471}, Tuple{111, 4279505940}]

@unsafe
def Bq.cape0_f0():
  [C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("..orrrrrrrrro..."), C.Bq.text("..orrrrrrrrro..."), C.Bq.text("..orrrrrrrrro..."), C.Bq.text("..orrrrrrrdro..."), C.Bq.text("..ordrrrrrrro..."), C.Bq.text("..orrrrrdrrro..."), C.Bq.text("..orrdrrrrdro..."), C.Bq.text("...orrrdrrro...."), C.Bq.text("....ooooooo....."), C.Bq.text("................"), C.Bq.text("................")]

@unsafe
def Bq.cape0_f1():
  Bq.shift_down(Bq.cape0_f0)

@unsafe
def Bq.cape0_pal():
  [Tuple{114, 4293413471}, Tuple{100, 4289739346}, Tuple{111, 4279505940}]

@unsafe
def Bq.cape1_f0():
  [C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("..orrrrrrrrro..."), C.Bq.text("..orrryrrrrro..."), C.Bq.text("..orrrrrrrrro..."), C.Bq.text("..orrrrrryrro..."), C.Bq.text("..oryrrrrrrro..."), C.Bq.text("..orrrrrrrrro..."), C.Bq.text("..orrrryrrrro..."), C.Bq.text("...orrrrrryo...."), C.Bq.text("....ooooooo....."), C.Bq.text("................"), C.Bq.text("................")]

@unsafe
def Bq.cape1_f1():
  Bq.shift_down(Bq.cape1_f0)

@unsafe
def Bq.cape1_pal():
  [Tuple{114, 4282210974}, Tuple{100, 4281024880}, Tuple{121, 4294955366}, Tuple{111, 4279505940}]

@unsafe
def Bq.slime_f0():
  [C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("......oooo......"), C.Bq.text("....oogglloo...."), C.Bq.text("...ogglllggggo.."), C.Bq.text("..ogglwlgggggo.."), C.Bq.text(".ogggllggggggdo."), C.Bq.text(".oggeggggggeggo."), C.Bq.text(".oggeggggggeggo."), C.Bq.text(".ogggggggggggdo."), C.Bq.text(".ogggggoogggddo."), C.Bq.text("..oggddddddddo.."), C.Bq.text("...oodddddoo...."), C.Bq.text(".....ooooo......")]

@unsafe
def Bq.slime_f1():
  [C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("......oooo......"), C.Bq.text("...oooggllooo..."), C.Bq.text("..oggglllggggo.."), C.Bq.text(".ogglwlggggggdo."), C.Bq.text("oggglldggggggddo"), C.Bq.text("ogeggggggggeggdo"), C.Bq.text("ogeggggggggeggdo"), C.Bq.text("oggggggoogggdddo"), C.Bq.text(".oggddddddddddo."), C.Bq.text("..oooooooooooo..")]

@unsafe
def Bq.slime_pal():
  [Tuple{103, 4284729165}, Tuple{108, 4288406884}, Tuple{100, 4282288456}, Tuple{101, 4279505940}, Tuple{111, 4279505940}, Tuple{119, 4294967295}]

@unsafe
def Bq.spore_f0():
  [C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("......oooo......"), C.Bq.text("....oorrrroo...."), C.Bq.text("...orrwrrrrro..."), C.Bq.text("..orrrrrwrrrro.."), C.Bq.text(".orrwrrrrrrwrro."), C.Bq.text(".orrrrrrrrrrrro."), C.Bq.text(".oooooooooooooo."), C.Bq.text("...osssssssso..."), C.Bq.text("...osesssseso..."), C.Bq.text("...osssssssso..."), C.Bq.text("...ossssossso..."), C.Bq.text("....osso.osso..."), C.Bq.text("....oo.....oo..."), C.Bq.text("................")]

@unsafe
def Bq.spore_f1():
  [C.Bq.text("................"), C.Bq.text("......oooo......"), C.Bq.text("....oorrrroo...."), C.Bq.text("...orrwrrrrro..."), C.Bq.text("..orrrrrwrrrro.."), C.Bq.text(".orrwrrrrrrwrro."), C.Bq.text(".orrrrrrrrrrrro."), C.Bq.text(".oooooooooooooo."), C.Bq.text("...osssssssso..."), C.Bq.text("...osesssseso..."), C.Bq.text("...osssssssso..."), C.Bq.text("...ossssossso..."), C.Bq.text("...osso..osso..."), C.Bq.text("...oo......oo..."), C.Bq.text("................"), C.Bq.text("................")]

@unsafe
def Bq.spore_pal():
  [Tuple{114, 4293421663}, Tuple{100, 4289743430}, Tuple{119, 4294963688}, Tuple{115, 4293574809}, Tuple{101, 4279505940}, Tuple{111, 4279505940}]

@unsafe
def Bq.bat_f0():
  [C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("oo............oo"), C.Bq.text("oddo........oddo"), C.Bq.text("odddo..oo..odddo"), C.Bq.text(".odddoopdoodddo."), C.Bq.text(".odddppppppdddo."), C.Bq.text("..odpppppppppo.."), C.Bq.text("..opppeppepppo.."), C.Bq.text("...oppppppppo..."), C.Bq.text("...opwpppwppo..."), C.Bq.text("....oppppppo...."), C.Bq.text(".....opoopo....."), C.Bq.text("......o..o......"), C.Bq.text("................"), C.Bq.text("................")]

@unsafe
def Bq.bat_f1():
  [C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("......oo........"), C.Bq.text(".....opdo......."), C.Bq.text("oooopppppppoooo."), C.Bq.text("oddddpppppdddddo"), C.Bq.text(".oodpppppppdoo.."), C.Bq.text("...opepppepo...."), C.Bq.text("...opppppppo...."), C.Bq.text("...opwpppwpo...."), C.Bq.text("....oppppppo...."), C.Bq.text(".....opoopo....."), C.Bq.text("................"), C.Bq.text("................")]

@unsafe
def Bq.bat_pal():
  [Tuple{112, 4286271413}, Tuple{100, 4283839879}, Tuple{101, 4294955366}, Tuple{111, 4279505940}, Tuple{119, 4294967295}]

@unsafe
def Bq.golem_f0():
  [C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("....oooooo......"), C.Bq.text("...ossssssdo...."), C.Bq.text("...osesseso....."), C.Bq.text("...ossssssdo...."), C.Bq.text("..oossssssdoo..."), C.Bq.text(".ossosssssdssdo."), C.Bq.text(".osdossmssdosdo."), C.Bq.text(".osdosssssdosdo."), C.Bq.text(".oodosssssdodo.."), C.Bq.text("...ossdssddo...."), C.Bq.text("...ossdossdo...."), C.Bq.text("..oossd.ossdo..."), C.Bq.text("..odddo.odddo..."), C.Bq.text("...ooo...ooo....")]

@unsafe
def Bq.golem_f1():
  [C.Bq.text("................"), C.Bq.text("....oooooo......"), C.Bq.text("...ossssssdo...."), C.Bq.text("...osesseso....."), C.Bq.text("...ossssssdo...."), C.Bq.text("..oossssssdoo..."), C.Bq.text(".ossosssssdssdo."), C.Bq.text(".osdossmssdosdo."), C.Bq.text(".osdosssssdosdo."), C.Bq.text(".oodosssssdodo.."), C.Bq.text("...ossdssddo...."), C.Bq.text("...ossdossdo...."), C.Bq.text("..oossd.ossdo..."), C.Bq.text("..oossd.ossdo..."), C.Bq.text("..odddo.odddo..."), C.Bq.text("...ooo...ooo....")]

@unsafe
def Bq.golem_pal():
  [Tuple{115, 4287339444}, Tuple{100, 4284312452}, Tuple{109, 4284729165}, Tuple{101, 4294955366}, Tuple{111, 4279505940}]

@unsafe
def Bq.wolf_f0():
  [C.Bq.text("................"), C.Bq.text(".o.o............"), C.Bq.text("osoco..........."), C.Bq.text("osssso......oo.."), C.Bq.text("oswsso.....osdo."), C.Bq.text("ossssooooooossdo"), C.Bq.text("osssssssssssssdo"), C.Bq.text("owssssssssssssso"), C.Bq.text("owsssssssssssso."), C.Bq.text(".ossssssssssso.."), C.Bq.text(".oso..oso..oso.."), C.Bq.text(".oso..oso..oso.."), C.Bq.text(".odo..odo..odo.."), C.Bq.text("..o....o....o..."), C.Bq.text("................"), C.Bq.text("................")]

@unsafe
def Bq.wolf_f1():
  [C.Bq.text("................"), C.Bq.text(".o.o............"), C.Bq.text("osoco..........."), C.Bq.text("osssso......oo.."), C.Bq.text("oswsso.....osdo."), C.Bq.text("ossssooooooossdo"), C.Bq.text("osssssssssssssdo"), C.Bq.text("owssssssssssssso"), C.Bq.text("owsssssssssssso."), C.Bq.text(".ossssssssssso.."), C.Bq.text(".oso...oso.oso.."), C.Bq.text("..oso.oso...oso."), C.Bq.text("..odo.odo...odo."), C.Bq.text("...o...o.....o.."), C.Bq.text("................"), C.Bq.text("................")]

@unsafe
def Bq.wolf_pal():
  [Tuple{115, 4290300894}, Tuple{100, 4286618036}, Tuple{119, 4294967295}, Tuple{101, 4284798962}, Tuple{111, 4279505940}]

@unsafe
def Bq.wisp_f0():
  [C.Bq.text("................"), C.Bq.text("................"), C.Bq.text(".......o........"), C.Bq.text("......oco......."), C.Bq.text(".....occco.o...."), C.Bq.text("..o.occlcco....."), C.Bq.text("...occllllco...."), C.Bq.text("..occlwwllcco..."), C.Bq.text("..oclwllllllo..."), C.Bq.text("..oclelllelco..."), C.Bq.text("..occlllllcco..."), C.Bq.text("...occllllco...."), C.Bq.text("....occcco......"), C.Bq.text(".....oooo......."), C.Bq.text("................"), C.Bq.text("................")]

@unsafe
def Bq.wisp_f1():
  [C.Bq.text("................"), C.Bq.text(".......o........"), C.Bq.text("......oco......."), C.Bq.text(".....occco......"), C.Bq.text("..o.occlcco.o..."), C.Bq.text("...occllllco...."), C.Bq.text("..occlwwllcco..."), C.Bq.text("..oclwllllllo..."), C.Bq.text("..oclelllelco..."), C.Bq.text("..occlllllcco..."), C.Bq.text("..occcllllcco..."), C.Bq.text("...occllllco...."), C.Bq.text("...occcccco....."), C.Bq.text("....oooooo......"), C.Bq.text("................"), C.Bq.text("................")]

@unsafe
def Bq.wisp_pal():
  [Tuple{99, 4284798962}, Tuple{108, 4290310911}, Tuple{119, 4294967295}, Tuple{101, 4279505940}, Tuple{111, 4281036162}]

@unsafe
def Bq.mossback_f0():
  [C.Bq.text("................................"), C.Bq.text("................................"), C.Bq.text("................................"), C.Bq.text("..........oo..oo..oo............"), C.Bq.text(".........oydooydooydo..........."), C.Bq.text("..........oooooooooo............"), C.Bq.text("..........ommmmmmmmo............"), C.Bq.text(".......oooommmmmmmmoooo........."), C.Bq.text(".....oogggggglllggggggoo........"), C.Bq.text("....oggggglllllllgggggggo......."), C.Bq.text("...ogggglllwwlllllgggggggo......"), C.Bq.text("..oggggllwwwlllllllgggggggo....."), C.Bq.text(".oggggllwwlllllllllllggggggo...."), C.Bq.text(".ogggglllllllllllllllggggggo...."), C.Bq.text("ogggggllllllllllllllllggggggo..."), C.Bq.text("ogggeeggglllllllllggggeeggggo..."), C.Bq.text("ogggeegggglllllllgggggeegggggo.."), C.Bq.text("oggggggggggglllggggggggggggggo.."), C.Bq.text("oggggggggggggggggggggggggggggo.."), C.Bq.text("oggggggggwwooowwgggggggggggggo.."), C.Bq.text(".ogggggggowwwwwoggggggggggggo..."), C.Bq.text(".oggggggggooooogggggggggdgggo..."), C.Bq.text(".ogggggggggggggggggggggddgggo..."), C.Bq.text("..ogggggggggggggggggggdddggo...."), C.Bq.text("..oggddgggggggggggggdddddgo....."), C.Bq.text("...ogddddgggggggggdddddddo......"), C.Bq.text("....oddddddddddddddddddgo......."), C.Bq.text(".....odddddddddddddddoo........."), C.Bq.text("......ooddddddddddoo............"), C.Bq.text("........oooooooooo.............."), C.Bq.text("................................"), C.Bq.text("................................")]

@unsafe
def Bq.mossback_f1():
  [C.Bq.text("................................"), C.Bq.text("................................"), C.Bq.text("................................"), C.Bq.text("................................"), C.Bq.text("................................"), C.Bq.text("..........oo..oo..oo............"), C.Bq.text(".........oydooydooydo..........."), C.Bq.text("..........oooooooooo............"), C.Bq.text("..........ommmmmmmmo............"), C.Bq.text(".......oooommmmmmmmoooo........."), C.Bq.text(".....oogggggglllggggggoo........"), C.Bq.text("....oggggglllllllgggggggo......."), C.Bq.text("...ogggglllwwlllllgggggggo......"), C.Bq.text("..oggggllwwwlllllllgggggggo....."), C.Bq.text(".oggggllwwlllllllllllggggggo...."), C.Bq.text(".ogggglllllllllllllllggggggo...."), C.Bq.text("ogggggllllllllllllllllggggggo..."), C.Bq.text("ogggeeggglllllllllggggeeggggo..."), C.Bq.text("ogggeegggglllllllgggggeegggggo.."), C.Bq.text("oggggggggggglllggggggggggggggo.."), C.Bq.text("oggggggggggggggggggggggggggggo.."), C.Bq.text("oggggggggwwooowwgggggggggggggo.."), C.Bq.text(".ogggggggowwwwwoggggggggggggo..."), C.Bq.text(".oggggggggooooogggggggggdgggo..."), C.Bq.text(".ogggggggggggggggggggggddgggo..."), C.Bq.text("..ogggggggggggggggggggdddggo...."), C.Bq.text("..oggddgggggggggggggdddddgo....."), C.Bq.text("...ogddddgggggggggdddddddo......"), C.Bq.text("...oddddddddddddddddddddgo......"), C.Bq.text("...odddddddddddddddddddoo......."), C.Bq.text("....oooooooooooooooooo.........."), C.Bq.text("................................")]

@unsafe
def Bq.mossback_pal():
  [Tuple{103, 4284729165}, Tuple{108, 4288406884}, Tuple{100, 4282288456}, Tuple{109, 4280704066}, Tuple{101, 4279505940}, Tuple{111, 4279505940}, Tuple{119, 4294967295}, Tuple{121, 4294955366}]

@unsafe
def Bq.stonewarden_f0():
  [C.Bq.text("................................"), C.Bq.text("................................"), C.Bq.text("..........oooooooo.............."), C.Bq.text(".........ossssssssdo............"), C.Bq.text(".........osessssesdo............"), C.Bq.text(".........ossssssssdo............"), C.Bq.text(".........osscsscssdo............"), C.Bq.text("..........ossssssdo............."), C.Bq.text("......ooooossssssdoooo.........."), C.Bq.text("....oossssossssssdosssdo........"), C.Bq.text("...ossssssossssssdosssssdo......"), C.Bq.text("..ossdsssssossssdossssssdo......"), C.Bq.text("..ossdosssssccsssssssossdo......"), C.Bq.text(".ossdo.ossssccsssssdo.ossdo....."), C.Bq.text(".ossdo.osssssssssssdo.ossdo....."), C.Bq.text(".osdo..ossscssssssdo...osdo....."), C.Bq.text(".osdo..osssscsssssdo...osdo....."), C.Bq.text(".odo...ossssssssssdo....odo....."), C.Bq.text("..o....ossssssssssdo.....o......"), C.Bq.text(".......osssdsssdssdo............"), C.Bq.text(".......osssdosssdsdo............"), C.Bq.text("......oosssdossssdoo............"), C.Bq.text("......ossssd.ossssdo............"), C.Bq.text("......ossssd.osssssdo..........."), C.Bq.text(".....osssssd..ossssdo..........."), C.Bq.text(".....osssdd...osssddo..........."), C.Bq.text(".....osddd.....osdddo..........."), C.Bq.text("....oddddo.....odddddo.........."), C.Bq.text("....oooooo.....oooooo..........."), C.Bq.text("................................"), C.Bq.text("................................"), C.Bq.text("................................")]

@unsafe
def Bq.stonewarden_f1():
  [C.Bq.text("................................"), C.Bq.text("................................"), C.Bq.text("................................"), C.Bq.text("..........oooooooo.............."), C.Bq.text(".........ossssssssdo............"), C.Bq.text(".........osessssesdo............"), C.Bq.text(".........ossssssssdo............"), C.Bq.text(".........osscsscssdo............"), C.Bq.text("..........ossssssdo............."), C.Bq.text("......ooooossssssdoooo.........."), C.Bq.text("....oossssossssssdosssdo........"), C.Bq.text("...ossssssossssssdosssssdo......"), C.Bq.text("..ossdsssssossssdossssssdo......"), C.Bq.text("..ossdosssssccsssssssossdo......"), C.Bq.text(".ossdo.ossssccsssssdo.ossdo....."), C.Bq.text(".ossdo.osssssssssssdo.ossdo....."), C.Bq.text(".osdo..ossscssssssdo...osdo....."), C.Bq.text(".osdo..osssscsssssdo...osdo....."), C.Bq.text(".odo...ossssssssssdo....odo....."), C.Bq.text("..o....ossssssssssdo.....o......"), C.Bq.text(".......osssdsssdssdo............"), C.Bq.text(".......osssdosssdsdo............"), C.Bq.text("......oosssdossssdoo............"), C.Bq.text("......ossssd.ossssdo............"), C.Bq.text("......ossssd.osssssdo..........."), C.Bq.text(".....osssssd..ossssdo..........."), C.Bq.text(".....osssdd...osssddo..........."), C.Bq.text(".....osddd.....osdddo..........."), C.Bq.text("....oddddo.....odddddo.........."), C.Bq.text("....oooooo.....oooooo..........."), C.Bq.text("................................"), C.Bq.text("................................")]

@unsafe
def Bq.stonewarden_pal():
  [Tuple{115, 4287339444}, Tuple{100, 4284312452}, Tuple{109, 4282272355}, Tuple{99, 4284798962}, Tuple{101, 4284798962}, Tuple{111, 4279505940}]

@unsafe
def Bq.rimehowl_f0():
  [C.Bq.text("................................"), C.Bq.text("...oo.oo........................"), C.Bq.text("..ossooss......................."), C.Bq.text("..osssssso...............ooo...."), C.Bq.text("..osswsssso.............ossdo..."), C.Bq.text("..osswcssso............osssdo..."), C.Bq.text("..ossssssso...........ossssdo..."), C.Bq.text("..osssssssoooooooooooosssssdo..."), C.Bq.text("..owsssssssssssssssssssssssdo..."), C.Bq.text("..owssssssssssssssssssssssdo...."), C.Bq.text("..owwssssssssssssssssssssso....."), C.Bq.text("...owwssssssssssssssssssso......"), C.Bq.text("...owwssssssssssssssssssso......"), C.Bq.text("....osssssssssssssssssssso......"), C.Bq.text("....ossssssssssssssssssso......."), C.Bq.text("....ossssossssssssosssso........"), C.Bq.text("....osso..osssso..osso.........."), C.Bq.text("....osso..osssso..osso.........."), C.Bq.text("....osso..osso.o..osso.........."), C.Bq.text("....odso..odso....odso.........."), C.Bq.text("....odo....odo....odo..........."), C.Bq.text(".....o......o......o............"), C.Bq.text("................................"), C.Bq.text("................................"), C.Bq.text("................................"), C.Bq.text("................................"), C.Bq.text("................................"), C.Bq.text("................................"), C.Bq.text("................................"), C.Bq.text("................................"), C.Bq.text("................................"), C.Bq.text("................................")]

@unsafe
def Bq.rimehowl_f1():
  [C.Bq.text("................................"), C.Bq.text("...oo.oo........................"), C.Bq.text("..ossooss......................."), C.Bq.text("..osssssso...............ooo...."), C.Bq.text("..osswsssso.............ossdo..."), C.Bq.text("..osswcssso............osssdo..."), C.Bq.text("..ossssssso...........ossssdo..."), C.Bq.text("..osssssssoooooooooooosssssdo..."), C.Bq.text("..owsssssssssssssssssssssssdo..."), C.Bq.text("..owssssssssssssssssssssssdo...."), C.Bq.text("..owwssssssssssssssssssssso....."), C.Bq.text("...owwssssssssssssssssssso......"), C.Bq.text("...owwssssssssssssssssssso......"), C.Bq.text("....osssssssssssssssssssso......"), C.Bq.text("....ossssssssssssssssssso......."), C.Bq.text("....ossssossssssssosssso........"), C.Bq.text("....osso...osssso..osso........."), C.Bq.text("...osso...osssso....osso........"), C.Bq.text("...osso...osso.o....osso........"), C.Bq.text("...odso...odso......odso........"), C.Bq.text("...odo.....odo......odo........."), C.Bq.text(".....o......o......o............"), C.Bq.text("................................"), C.Bq.text("................................"), C.Bq.text("................................"), C.Bq.text("................................"), C.Bq.text("................................"), C.Bq.text("................................"), C.Bq.text("................................"), C.Bq.text("................................"), C.Bq.text("................................"), C.Bq.text("................................")]

@unsafe
def Bq.rimehowl_pal():
  [Tuple{115, 4290300894}, Tuple{100, 4286618036}, Tuple{119, 4294967295}, Tuple{99, 4284798962}, Tuple{101, 4284798962}, Tuple{111, 4279505940}]

@unsafe
def Bq.maw_f0():
  [C.Bq.text("................................"), C.Bq.text("..........c..........c.........."), C.Bq.text("......c.......oooo.......c......"), C.Bq.text("...........ookkkkoo............."), C.Bq.text(".........ookkkkkkkkoo..........."), C.Bq.text("....c...okkkvvvvvvkkko....c....."), C.Bq.text(".......okkvvvvvvvvvvkko........."), C.Bq.text("......okkvvvpppppvvvvkko........"), C.Bq.text(".....okkvvpppppppppvvvkko......."), C.Bq.text("....okkvvpppwwpppppppvvkko......"), C.Bq.text("....okvvppwwwppppppppvvkko......"), C.Bq.text("...okkvvpwwpppppppppppvvko......"), C.Bq.text("...okvvpppppppppppppppvvko......"), C.Bq.text("...okvveeppppppppppeeppvko......"), C.Bq.text("...okvveeppppppppppeeppvko......"), C.Bq.text("...okvvppppppppppppppppvko......"), C.Bq.text("...okvvppppppppppppppppvko......"), C.Bq.text("...okkvpppowwowwowwoppvkko......"), C.Bq.text("....okvppowwwwwwwwwwopvkko......"), C.Bq.text("....okkvpowowwwwwwowopvko......."), C.Bq.text(".....okvvowwwwwwwwwwovvko......."), C.Bq.text(".....okkvvooooooooooovkko......."), C.Bq.text("......okkvvvvvvvvvvvvkko........"), C.Bq.text(".......okkvvvvvvvvvvkko........."), C.Bq.text("........ookkvvvvvvkkoo.........."), C.Bq.text("..........ookkkkkkoo............"), C.Bq.text("....c.......oooooo.......c......"), C.Bq.text("................................"), C.Bq.text("........c..........c............"), C.Bq.text("................................"), C.Bq.text("................................"), C.Bq.text("................................")]

@unsafe
def Bq.maw_f1():
  [C.Bq.text("................................"), C.Bq.text("................................"), C.Bq.text(".....c.........c.........c......"), C.Bq.text("..........oooooo................"), C.Bq.text("........ookkkkkkoo.............."), C.Bq.text("......ookkvvvvvvkkoo............"), C.Bq.text(".....okkvvvvvvvvvvkko..........."), C.Bq.text("....okkvvvpppppppvvkko.........."), C.Bq.text("....okvvpppppppppppvvko........."), C.Bq.text("...okkvpppwwppppppppvkko........"), C.Bq.text("...okvvpwwwpppppppppvvko........"), C.Bq.text("...okvvpwwppppppppppvvko........"), C.Bq.text("..okvvpppppppppppppppvvko......."), C.Bq.text("..okvveeeppppppppeeeppvko......."), C.Bq.text("..okvveeeppppppppeeeppvko......."), C.Bq.text("..okvvppppppppppppppppvko......."), C.Bq.text("..okvvppppppppppppppppvko......."), C.Bq.text("..okvvpppppppppppppppvvko......."), C.Bq.text("..okkvppoowwowwowwooppvko......."), C.Bq.text("...okvpowwwwwwwwwwwwopvko......."), C.Bq.text("...okvpowwwowwwwowwwopvko......."), C.Bq.text("...okvvowwwwwwwwwwwwovvko......."), C.Bq.text("...okkvvooooooooooooovkko......."), C.Bq.text("....okkvvvvvvvvvvvvvvkko........"), C.Bq.text(".....okkkvvvvvvvvvvkkko........."), C.Bq.text(".......ookkkvvvvkkkoo..........."), C.Bq.text(".........ookkkkkkoo............."), C.Bq.text("...........oooooo..............."), C.Bq.text(".....c...........c......c......."), C.Bq.text("................................"), C.Bq.text("................................"), C.Bq.text("................................")]

@unsafe
def Bq.maw_pal():
  [Tuple{118, 4283839879}, Tuple{112, 4286271413}, Tuple{107, 4281015111}, Tuple{119, 4294967295}, Tuple{101, 4293413471}, Tuple{99, 4284798962}, Tuple{111, 4279505940}]

@unsafe
def Bq.elder_f0():
  [C.Bq.text("....ooooooo....."), C.Bq.text("...owwwwwwwo...."), C.Bq.text("..owwwwwwwwwo..."), C.Bq.text("..owssssssswo..."), C.Bq.text("..owsessseswo..."), C.Bq.text("..owssssssswo..."), C.Bq.text("..owwssssswwo..."), C.Bq.text("..owwwssswwwo..."), C.Bq.text("...owwwwwwwo...."), C.Bq.text("..ogggggggggo..."), C.Bq.text(".oggggyggggggo.."), C.Bq.text(".ogggggggggggo.."), C.Bq.text(".odggggggggddo.."), C.Bq.text(".odggggggggddo.."), C.Bq.text(".odgggggggdddo.."), C.Bq.text(".oddggggggdddo.."), C.Bq.text(".oddddddddddo..."), C.Bq.text("..oddddddddo...."), C.Bq.text("...oo....oo....."), C.Bq.text("................")]

@unsafe
def Bq.elder_pal():
  [Tuple{115, 4293574809}, Tuple{119, 4294110692}, Tuple{103, 4284729165}, Tuple{100, 4282288456}, Tuple{101, 4279505940}, Tuple{111, 4279505940}, Tuple{121, 4294955366}]

@unsafe
def Bq.keeper_f0():
  [C.Bq.text("....ooooooo....."), C.Bq.text("...ohhhhhhho...."), C.Bq.text("..ohhhhhhhhho..."), C.Bq.text("..ohsssssssho..."), C.Bq.text("..ohsesssesho..."), C.Bq.text("..ohsssssssho..."), C.Bq.text("..ohssswsssho..."), C.Bq.text("...ossssssso...."), C.Bq.text("....ooooooo....."), C.Bq.text("...orrrrrrro...."), C.Bq.text("..orrrrrrrrro..."), C.Bq.text(".orrdrrrrrdrro.."), C.Bq.text(".orrdrrrrrdrro.."), C.Bq.text(".orrrrrrrrrrro.."), C.Bq.text("..odrrrrrrrdo..."), C.Bq.text("..odddddddddo..."), C.Bq.text("...oddo.oddo...."), C.Bq.text("...oddo.oddo...."), C.Bq.text("....oo...oo....."), C.Bq.text("................")]

@unsafe
def Bq.keeper_pal():
  [Tuple{115, 4291200578}, Tuple{104, 4283054936}, Tuple{114, 4293436221}, Tuple{100, 4289755694}, Tuple{101, 4279505940}, Tuple{111, 4279505940}, Tuple{119, 4294967295}]

@unsafe
def Bq.tile_grass():
  [C.Bq.text("gggggggggggggggg"), C.Bq.text("gggggGgggggggggg"), C.Bq.text("gggggggggggGgggg"), C.Bq.text("gGgggggggggggggg"), C.Bq.text("ggggggggGggggggg"), C.Bq.text("gggggggggggggggg"), C.Bq.text("ggGggggggggggGgg"), C.Bq.text("gggggggggggggggg"), C.Bq.text("gggggggGgggggggg"), C.Bq.text("gGgggggggggggggg"), C.Bq.text("ggggggggggGggggg"), C.Bq.text("gggGgggggggggggg"), C.Bq.text("gggggggggggggggg"), C.Bq.text("ggggggGggggggGgg"), C.Bq.text("gGgggggggggggggg"), C.Bq.text("gggggggggggggggg")]

@unsafe
def Bq.tile_flowers():
  [C.Bq.text("gggggggggggggggg"), C.Bq.text("ggfggggggggggggg"), C.Bq.text("gfyfgggggGgggggg"), C.Bq.text("ggfggggggggggggg"), C.Bq.text("gggggggggggfgggg"), C.Bq.text("gggggGgggggfyfgg"), C.Bq.text("ggggggggggggfggg"), C.Bq.text("gggggggggggggggg"), C.Bq.text("gggfgggggggggggg"), C.Bq.text("ggfyfggggggggggg"), C.Bq.text("gggfgggggggGgggg"), C.Bq.text("gggggggggggggggg"), C.Bq.text("gggggggggfgggggg"), C.Bq.text("gGgggggggfyfgggg"), C.Bq.text("ggggggggggfggggg"), C.Bq.text("gggggggggggggggg")]

@unsafe
def Bq.tile_tree():
  [C.Bq.text("gggggottoogggggg"), C.Bq.text("gggottttttoggggg"), C.Bq.text("ggottttttttogggg"), C.Bq.text("gottttTtttttoggg"), C.Bq.text("gotttttttTttoggg"), C.Bq.text("otttTttttttttogg"), C.Bq.text("otttttttTttttogg"), C.Bq.text("ottttttttttttogg"), C.Bq.text("gotTttttttTtoggg"), C.Bq.text("ggottttttttogggg"), C.Bq.text("gggoottttoogggg."), C.Bq.text("ggggggobbogggggg"), C.Bq.text("ggggggobbogggggg"), C.Bq.text("ggggggobbogggggg"), C.Bq.text("gggggobbbboggggg"), C.Bq.text("gggggggggggggggg")]

@unsafe
def Bq.tile_water():
  [C.Bq.text("wwwwwwwwwwwwwwww"), C.Bq.text("wwwWWwwwwwwwwwww"), C.Bq.text("wwwwwwwwwwWWwwww"), C.Bq.text("wwwwwwwwwwwwwwww"), C.Bq.text("wWWwwwwwwwwwwwww"), C.Bq.text("wwwwwwwWWwwwwwww"), C.Bq.text("wwwwwwwwwwwwwwww"), C.Bq.text("wwwwwwwwwwwwWWww"), C.Bq.text("wwWWwwwwwwwwwwww"), C.Bq.text("wwwwwwwwwwwwwwww"), C.Bq.text("wwwwwwWWwwwwwwww"), C.Bq.text("wwwwwwwwwwwwwwww"), C.Bq.text("wwwwwwwwwwWWwwww"), C.Bq.text("wWWwwwwwwwwwwwww"), C.Bq.text("wwwwwwwwwwwwwwww"), C.Bq.text("wwwwwwwWWwwwwwww")]

@unsafe
def Bq.tile_path():
  [C.Bq.text("pppppppppppppppp"), C.Bq.text("ppppPppppppppppp"), C.Bq.text("pppppppppppPpppp"), C.Bq.text("pPpppppppppppppp"), C.Bq.text("ppppppppPppppppp"), C.Bq.text("pppppppppppppppp"), C.Bq.text("ppPpppppppppppPp"), C.Bq.text("pppppppppppppppp"), C.Bq.text("pppppppPpppppppp"), C.Bq.text("pPpppppppppppppp"), C.Bq.text("ppppppppppPppppp"), C.Bq.text("pppPpppppppppppp"), C.Bq.text("pppppppppppppppp"), C.Bq.text("ppppppPppppppPpp"), C.Bq.text("pPpppppppppppppp"), C.Bq.text("pppppppppppppppp")]

@unsafe
def Bq.tile_rock():
  [C.Bq.text("gggggggggggggggg"), C.Bq.text("ggggoooooggggggg"), C.Bq.text("gggorrrrrogggggg"), C.Bq.text("ggorrrrRrrrogggg"), C.Bq.text("gorrrrrrrrRroggg"), C.Bq.text("gorrRrrrrrrroggg"), C.Bq.text("gorrrrrrRrrroggg"), C.Bq.text("gorrrrrrrrrroggg"), C.Bq.text("ggorRrrrrRrogggg"), C.Bq.text("gggorrrrrroggggg"), C.Bq.text("ggggoooooggggggg"), C.Bq.text("gggggggggggggggg"), C.Bq.text("gggggggggggggggg"), C.Bq.text("gggggggggggggggg"), C.Bq.text("gggggggggggggggg"), C.Bq.text("gggggggggggggggg")]

@unsafe
def Bq.tile_cavefloor():
  [C.Bq.text("cccccccccccccccc"), C.Bq.text("ccccCccccccccccc"), C.Bq.text("cccccccccccCcccc"), C.Bq.text("cCcccccccccccccc"), C.Bq.text("ccccccccCccccccc"), C.Bq.text("cccccccccccccccc"), C.Bq.text("ccCccccccccccCcc"), C.Bq.text("cccccccccccccccc"), C.Bq.text("cccccccCcccccccc"), C.Bq.text("cCcccccccccccccc"), C.Bq.text("ccccccccccCccccc"), C.Bq.text("cccCcccccccccccc"), C.Bq.text("cccccccccccccccc"), C.Bq.text("ccccccCccccccCcc"), C.Bq.text("cCcccccccccccccc"), C.Bq.text("cccccccccccccccc")]

@unsafe
def Bq.tile_cavewall():
  [C.Bq.text("kkkkkkkkkkkkkkkk"), C.Bq.text("kCCCCkkkCCCCCkkk"), C.Bq.text("kCCCCkkkCCCCCkkk"), C.Bq.text("kkkkkkkkkkkkkkkk"), C.Bq.text("kkCCCCCkkkCCCkkk"), C.Bq.text("kkCCCCCkkkCCCkkk"), C.Bq.text("kkkkkkkkkkkkkkkk"), C.Bq.text("kCCCkkkCCCCCCkkk"), C.Bq.text("kCCCkkkCCCCCCkkk"), C.Bq.text("kkkkkkkkkkkkkkkk"), C.Bq.text("kkCCCCCCkkCCCCkk"), C.Bq.text("kkCCCCCCkkCCCCkk"), C.Bq.text("kkkkkkkkkkkkkkkk"), C.Bq.text("kCCCCkkkCCCCCkkk"), C.Bq.text("kCCCCkkkCCCCCkkk"), C.Bq.text("kkkkkkkkkkkkkkkk")]

@unsafe
def Bq.tile_crystal():
  [C.Bq.text("cccccccccccccccc"), C.Bq.text("ccccccXocccccccc"), C.Bq.text("cccccoXxoccccccc"), C.Bq.text("cccccoxxocccccc."), C.Bq.text("ccccoxxXxocccccc"), C.Bq.text("ccccoxXxxocccccc"), C.Bq.text("cccoxxxxxxoccccc"), C.Bq.text("cccoxXxxxXoccccc"), C.Bq.text("cccoxxxXxxoccccc"), C.Bq.text("ccccoxxxxocccccc"), C.Bq.text("cccccooooccccccc"), C.Bq.text("cccccccccccccccc"), C.Bq.text("ccCcccccccccCccc"), C.Bq.text("cccccccccccccccc"), C.Bq.text("ccccccCccccccccc"), C.Bq.text("cccccccccccccccc")]

@unsafe
def Bq.tile_snow():
  [C.Bq.text("ssssssssssssssss"), C.Bq.text("ssssSsssssssssss"), C.Bq.text("ssssssssssssSsss"), C.Bq.text("sSssssssssssssss"), C.Bq.text("ssssssssSsssssss"), C.Bq.text("ssssssssssssssss"), C.Bq.text("ssSssssssssssSss"), C.Bq.text("ssssssssssssssss"), C.Bq.text("sssssssSssssssss"), C.Bq.text("sSssssssssssssss"), C.Bq.text("ssssssssssSsssss"), C.Bq.text("sssSssssssssssss"), C.Bq.text("ssssssssssssssss"), C.Bq.text("ssssssSssssssSss"), C.Bq.text("sSssssssssssssss"), C.Bq.text("ssssssssssssssss")]

@unsafe
def Bq.tile_ice():
  [C.Bq.text("iiiiiiiiiiiiiiii"), C.Bq.text("iiiIIiiiiiiiiiii"), C.Bq.text("iiiiiIIiiiiiiiii"), C.Bq.text("iiiiiiiiiiiIIiii"), C.Bq.text("iIIiiiiiiiiiiiii"), C.Bq.text("iiiiiiiIIiiiiiii"), C.Bq.text("iiiiiiiiIIiiiiii"), C.Bq.text("iiiiiiiiiiiiIIii"), C.Bq.text("iiIIiiiiiiiiiiii"), C.Bq.text("iiiIIiiiiiiiiiii"), C.Bq.text("iiiiiiIIiiiiiiii"), C.Bq.text("iiiiiiiIIiiiiiii"), C.Bq.text("iiiiiiiiiiIIiiii"), C.Bq.text("iIIiiiiiiiiIIiii"), C.Bq.text("iiiiiiiiiiiiiiii"), C.Bq.text("iiiiiiiIIiiiiiii")]

@unsafe
def Bq.tile_snowtree():
  [C.Bq.text("sssssossoossssss"), C.Bq.text("ssssosssssosssss"), C.Bq.text("sssosswssssossss"), C.Bq.text("ssossssssssgosss"), C.Bq.text("ssosswssssssosss"), C.Bq.text("sossssssswsssoss"), C.Bq.text("sossswsssssssoss"), C.Bq.text("sossssssswsssoss"), C.Bq.text("ssostsssssstosss"), C.Bq.text("sssossssssossss."), C.Bq.text("ssssoossoossssss"), C.Bq.text("ssssssobbossssss"), C.Bq.text("ssssssobbossssss"), C.Bq.text("ssssssobbossssss"), C.Bq.text("sssssobbbbosssss"), C.Bq.text("ssssssssssssssss")]

@unsafe
def Bq.tile_portal():
  [C.Bq.text("gggggggggggggggg"), C.Bq.text("ggggovvvvoggggg."), C.Bq.text("gggovmmmmvoggggg"), C.Bq.text("ggovmVVVVmvogggg"), C.Bq.text("ggovmVxxVmvogggg"), C.Bq.text("ggovmVxxVmvogggg"), C.Bq.text("ggovmVxxVmvogggg"), C.Bq.text("ggovmVxxVmvogggg"), C.Bq.text("ggovmVxxVmvogggg"), C.Bq.text("ggovmVVVVmvogggg"), C.Bq.text("gggovmmmmvoggggg"), C.Bq.text("ggggovvvvogggggg"), C.Bq.text("gggggggggggggggg"), C.Bq.text("gggggggggggggggg"), C.Bq.text("gggggggggggggggg"), C.Bq.text("gggggggggggggggg")]

@unsafe
def Bq.tile_riftfloor():
  [C.Bq.text("DDDDDDDDDDDDDDDD"), C.Bq.text("DDDDdDDDDDDDDDDD"), C.Bq.text("DDDDDDDDDDDdDDDD"), C.Bq.text("DdDDDDDDDDDDDDDD"), C.Bq.text("DDDDDDDDdDDDDDDD"), C.Bq.text("DDDDDDDDDDDDDvDD"), C.Bq.text("DDdDDDDDDDDDDDDD"), C.Bq.text("DDDDDDDDDDDDDDDD"), C.Bq.text("DDDDDDDdDDDDDDDD"), C.Bq.text("DdDDDDDDDDDDDDDD"), C.Bq.text("DDDDDvDDDDdDDDDD"), C.Bq.text("DDDdDDDDDDDDDDDD"), C.Bq.text("DDDDDDDDDDDDDDDD"), C.Bq.text("DDDDDDdDDDDDDdDD"), C.Bq.text("DdDDDDDDDDDDDDDD"), C.Bq.text("DDDDDDDDDDDDDDDD")]

@unsafe
def Bq.tile_riftportal():
  [C.Bq.text("DDDDDDDDDDDDDDDD"), C.Bq.text("DDDDovvvvoDDDDDD"), C.Bq.text("DDDovmmmmvoDDDDD"), C.Bq.text("DDovmVVVVmvoDDDD"), C.Bq.text("DDovmVeeVmvoDDDD"), C.Bq.text("DDovmVeeVmvoDDDD"), C.Bq.text("DDovmVeeVmvoDDDD"), C.Bq.text("DDovmVeeVmvoDDDD"), C.Bq.text("DDovmVeeVmvoDDDD"), C.Bq.text("DDovmVVVVmvoDDDD"), C.Bq.text("DDDovmmmmvoDDDDD"), C.Bq.text("DDDDovvvvoDDDDDD"), C.Bq.text("DDDDDDDDDDDDDDDD"), C.Bq.text("DDDDDDDDDDDDDDDD"), C.Bq.text("DDDDDDDDDDDDDDDD"), C.Bq.text("DDDDDDDDDDDDDDDD")]

@unsafe
def Bq.tile_shopmat():
  [C.Bq.text("gggggggggggggggg"), C.Bq.text("ggoooooooooooogg"), C.Bq.text("goeyeyeyeyeyeyog"), C.Bq.text("goyeyeyeyeyeyeog"), C.Bq.text("goeyeyeyeyeyeyog"), C.Bq.text("goyeyeyeyeyeyeog"), C.Bq.text("goeyeyeyeyeyeyog"), C.Bq.text("ggoooooooooooogg"), C.Bq.text("gggggggggggggggg"), C.Bq.text("gggggggggggggggg"), C.Bq.text("gggggggggggggggg"), C.Bq.text("gggggggggggggggg"), C.Bq.text("gggggggggggggggg"), C.Bq.text("gggggggggggggggg"), C.Bq.text("gggggggggggggggg"), C.Bq.text("gggggggggggggggg")]

@unsafe
def Bq.tiles_pal():
  [Tuple{103, 4284721485}, Tuple{71, 4283931203}, Tuple{102, 4293413471}, Tuple{121, 4294955366}, Tuple{116, 4282288456}, Tuple{84, 4280704066}, Tuple{98, 4285221426}, Tuple{119, 4282216401}, Tuple{87, 4284125160}, Tuple{112, 4291405942}, Tuple{80, 4290287200}, Tuple{114, 4287339444}, Tuple{82, 4284312452}, Tuple{99, 4283057240}, Tuple{67, 4282004808}, Tuple{107, 4281018424}, Tuple{120, 4284798962}, Tuple{88, 4288407039}, Tuple{115, 4293456120}, Tuple{83, 4292207344}, Tuple{105, 4290307570}, Tuple{73, 4292211450}, Tuple{118, 4283839879}, Tuple{86, 4286271413}, Tuple{109, 4288376805}, Tuple{100, 4282004808}, Tuple{68, 4281015111}, Tuple{111, 4279505940}, Tuple{101, 4293436221}]

@unsafe
def Bq.icon_potion():
  [C.Bq.text("................"), C.Bq.text("......oooo......"), C.Bq.text("......obbo......"), C.Bq.text("......obbo......"), C.Bq.text(".....oossoo....."), C.Bq.text("....osssssso...."), C.Bq.text("...ossrrrrsso..."), C.Bq.text("...osrrrrrrso..."), C.Bq.text("...osrrrrrrso..."), C.Bq.text("...osrrwrrrso..."), C.Bq.text("...osrrrrrrso..."), C.Bq.text("...ossrrrrsso..."), C.Bq.text("....osssssso...."), C.Bq.text(".....oooooo....."), C.Bq.text("................"), C.Bq.text("................")]

@unsafe
def Bq.icon_sword():
  [C.Bq.text("................"), C.Bq.text("...........oo..."), C.Bq.text("..........oswo.."), C.Bq.text(".........oswso.."), C.Bq.text("........oswso..."), C.Bq.text(".......oswso...."), C.Bq.text("......oswso....."), C.Bq.text(".....oswso......"), C.Bq.text("..o.oswso......."), C.Bq.text("..ooswso........"), C.Bq.text("..oyyso........."), C.Bq.text(".oyyyo.........."), C.Bq.text("oyyoyyo........."), C.Bq.text("oyo..oo........."), C.Bq.text(".o.............."), C.Bq.text("................")]

@unsafe
def Bq.icon_axe():
  [C.Bq.text("................"), C.Bq.text("......ooooo....."), C.Bq.text(".....ossssso...."), C.Bq.text("....ossssssso..."), C.Bq.text("....ossoobbo...."), C.Bq.text("....osso.obbo..."), C.Bq.text("....osso.obbo..."), C.Bq.text(".....oo..obbo..."), C.Bq.text(".........obbo..."), C.Bq.text(".........obbo..."), C.Bq.text(".........obbo..."), C.Bq.text(".........obbo..."), C.Bq.text(".........obbo..."), C.Bq.text("..........oo...."), C.Bq.text("................"), C.Bq.text("................")]

@unsafe
def Bq.icon_armor():
  [C.Bq.text("................"), C.Bq.text("...oo......oo..."), C.Bq.text("..osso....osso.."), C.Bq.text("..ossoooooosso.."), C.Bq.text("..osssssssssso.."), C.Bq.text("..osssssssssso.."), C.Bq.text("...osssssssso..."), C.Bq.text("...osssssssso..."), C.Bq.text("...osdssssdso..."), C.Bq.text("...osdssssdso..."), C.Bq.text("...osssssssso..."), C.Bq.text("....osssssso...."), C.Bq.text("....osssssso...."), C.Bq.text(".....oooooo....."), C.Bq.text("................"), C.Bq.text("................")]

@unsafe
def Bq.icon_helm():
  [C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("......oooo......"), C.Bq.text("....oossssoo...."), C.Bq.text("...osssssssso..."), C.Bq.text("..osssssssssso.."), C.Bq.text("..osssssssssso.."), C.Bq.text("..osssssssssso.."), C.Bq.text("..ossosssssoso.."), C.Bq.text("..ossosssssoso.."), C.Bq.text("..oosossssosoo.."), C.Bq.text("...o.osssso.o..."), C.Bq.text(".....oooooo....."), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................")]

@unsafe
def Bq.icon_charm():
  [C.Bq.text("................"), C.Bq.text("......oooo......"), C.Bq.text(".....oyyyyo....."), C.Bq.text("....oyo..oyo...."), C.Bq.text("....oyo..oyo...."), C.Bq.text("....oyo..oyo...."), C.Bq.text(".....oyooyo....."), C.Bq.text("......oyyo......"), C.Bq.text(".....oyyyyo....."), C.Bq.text("....oyyyyyyo...."), C.Bq.text("....oyyryyyo...."), C.Bq.text("....oyrrryyo...."), C.Bq.text("....oyyryyyo...."), C.Bq.text(".....oyyyyo....."), C.Bq.text("......oooo......"), C.Bq.text("................")]

@unsafe
def Bq.icon_pal():
  [Tuple{114, 4293413471}, Tuple{119, 4294967295}, Tuple{115, 4290300894}, Tuple{100, 4286618036}, Tuple{98, 4285221426}, Tuple{121, 4294955366}, Tuple{111, 4279505940}]

@unsafe
def Bq.slash_f0():
  [C.Bq.text("..........ww...."), C.Bq.text(".........wwy...."), C.Bq.text("........wwyy...."), C.Bq.text(".......wwyy....."), C.Bq.text("......wwyy......"), C.Bq.text(".....wwyy......."), C.Bq.text("....wwyy........"), C.Bq.text("...wwyy........."), C.Bq.text("...wyy.........."), C.Bq.text("..wwy..........."), C.Bq.text("..wy............"), C.Bq.text("..wy............"), C.Bq.text("..w............."), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................")]

@unsafe
def Bq.slash_f1():
  [C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("....w..........."), C.Bq.text("....ww.........."), C.Bq.text(".....wwy........"), C.Bq.text("......wwyy......"), C.Bq.text(".......wwyyy...."), C.Bq.text("........wwyyy..."), C.Bq.text(".........wwyy..."), C.Bq.text("..........wyy..."), C.Bq.text("...........yy..."), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................")]

@unsafe
def Bq.fx_pal():
  [Tuple{119, 4294967295}, Tuple{121, 4294955366}, Tuple{99, 4284798962}, Tuple{111, 4279505940}]

@unsafe
def Bq.spark_f0():
  [C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text(".......y........"), C.Bq.text("......yyy......."), C.Bq.text(".......y........"), C.Bq.text("...........c...."), C.Bq.text("..........ccc..."), C.Bq.text("...........c...."), C.Bq.text("....c..........."), C.Bq.text("...ccc.........."), C.Bq.text("....c..........."), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("................")]

@unsafe
def Bq.spark_f1():
  [C.Bq.text("................"), C.Bq.text("................"), C.Bq.text("....y..........."), C.Bq.text("...yyy.........."), C.Bq.text("....y..........."), C.Bq.text("..........y....."), C.Bq.text(".........yyy...."), C.Bq.text("..........y....."), C.Bq.text("................"), C.Bq.text("......c........."), C.Bq.text(".....ccc........"), C.Bq.text("......c........."), C.Bq.text("..........c....."), C.Bq.text(".........ccc...."), C.Bq.text("..........c....."), C.Bq.text("................")]

@unsafe
def Bq.load_assets():
  C.Bq.IO.bind(U32, Bq.Assets, Bq.load_strip(16, 20, [Bq.body_f0, Bq.body_f1], Bq.ramp), (body_0 => C.Bq.IO.bind(U32, Bq.Assets, Bq.load_strip(16, 20, [Bq.hair0_f0, Bq.hair0_f1], Bq.ramp), (hair0_1 => C.Bq.IO.bind(U32, Bq.Assets, Bq.load_strip(16, 20, [Bq.hair1_f0, Bq.hair1_f1], Bq.ramp), (hair1_2 => C.Bq.IO.bind(U32, Bq.Assets, Bq.load_strip(16, 20, [Bq.hair2_f0, Bq.hair2_f1], Bq.ramp), (hair2_3 => C.Bq.IO.bind(U32, Bq.Assets, Bq.load_strip(16, 20, [Bq.outfit_f0, Bq.outfit_f1], Bq.outfit_pal), (outfit_4 => C.Bq.IO.bind(U32, Bq.Assets, Bq.load_strip(16, 20, [Bq.hat0_f0], Bq.hat0_pal), (hat0_5 => C.Bq.IO.bind(U32, Bq.Assets, Bq.load_strip(16, 20, [Bq.hat1_f0], Bq.hat1_pal), (hat1_6 => C.Bq.IO.bind(U32, Bq.Assets, Bq.load_strip(16, 20, [Bq.hat2_f0], Bq.hat2_pal), (hat2_7 => C.Bq.IO.bind(U32, Bq.Assets, Bq.load_strip(16, 20, [Bq.cape0_f0, Bq.cape0_f1], Bq.cape0_pal), (cape0_8 => C.Bq.IO.bind(U32, Bq.Assets, Bq.load_strip(16, 20, [Bq.cape1_f0, Bq.cape1_f1], Bq.cape1_pal), (cape1_9 => C.Bq.IO.bind(U32, Bq.Assets, Bq.load_strip(16, 16, [Bq.slime_f0, Bq.slime_f1], Bq.slime_pal), (slime_10 => C.Bq.IO.bind(U32, Bq.Assets, Bq.load_strip(16, 16, [Bq.spore_f0, Bq.spore_f1], Bq.spore_pal), (spore_11 => C.Bq.IO.bind(U32, Bq.Assets, Bq.load_strip(16, 16, [Bq.bat_f0, Bq.bat_f1], Bq.bat_pal), (bat_12 => C.Bq.IO.bind(U32, Bq.Assets, Bq.load_strip(16, 16, [Bq.golem_f0, Bq.golem_f1], Bq.golem_pal), (golem_13 => C.Bq.IO.bind(U32, Bq.Assets, Bq.load_strip(16, 16, [Bq.wolf_f0, Bq.wolf_f1], Bq.wolf_pal), (wolf_14 => C.Bq.IO.bind(U32, Bq.Assets, Bq.load_strip(16, 16, [Bq.wisp_f0, Bq.wisp_f1], Bq.wisp_pal), (wisp_15 => C.Bq.IO.bind(U32, Bq.Assets, Bq.load_strip(32, 32, [Bq.mossback_f0, Bq.mossback_f1], Bq.mossback_pal), (mossback_16 => C.Bq.IO.bind(U32, Bq.Assets, Bq.load_strip(32, 32, [Bq.stonewarden_f0, Bq.stonewarden_f1], Bq.stonewarden_pal), (stonewarden_17 => C.Bq.IO.bind(U32, Bq.Assets, Bq.load_strip(32, 32, [Bq.rimehowl_f0, Bq.rimehowl_f1], Bq.rimehowl_pal), (rimehowl_18 => C.Bq.IO.bind(U32, Bq.Assets, Bq.load_strip(32, 32, [Bq.maw_f0, Bq.maw_f1], Bq.maw_pal), (maw_19 => C.Bq.IO.bind(U32, Bq.Assets, Bq.load_strip(16, 20, [Bq.elder_f0], Bq.elder_pal), (elder_20 => C.Bq.IO.bind(U32, Bq.Assets, Bq.load_strip(16, 20, [Bq.keeper_f0], Bq.keeper_pal), (keeper_21 => C.Bq.IO.bind(U32, Bq.Assets, Bq.load_strip(16, 16, [Bq.tile_grass, Bq.tile_flowers, Bq.tile_tree, Bq.tile_water, Bq.tile_path, Bq.tile_rock, Bq.tile_cavefloor, Bq.tile_cavewall, Bq.tile_crystal, Bq.tile_snow, Bq.tile_ice, Bq.tile_snowtree, Bq.tile_portal, Bq.tile_riftfloor, Bq.tile_riftportal, Bq.tile_shopmat], Bq.tiles_pal), (tiles_22 => C.Bq.IO.bind(U32, Bq.Assets, Bq.load_strip(16, 16, [Bq.icon_potion, Bq.icon_sword, Bq.icon_axe, Bq.icon_armor, Bq.icon_helm, Bq.icon_charm], Bq.icon_pal), (icons_23 => C.Bq.IO.bind(U32, Bq.Assets, Bq.load_strip(16, 16, [Bq.slash_f0, Bq.slash_f1], Bq.fx_pal), (slash_24 => C.Bq.IO.bind(U32, Bq.Assets, Bq.load_strip(16, 16, [Bq.spark_f0, Bq.spark_f1], Bq.fx_pal), (spark_25 => (+plr_26 = {Bq.TexPlr.TexPlr{body_0, hair0_1, hair1_2, hair2_3, outfit_4, hat0_5, hat1_6, hat2_7, cape0_8, cape1_9} : Bq.TexPlr}; (+mob_27 = {Bq.TexMob.TexMob{slime_10, spore_11, bat_12, golem_13, wolf_14, wisp_15, mossback_16, stonewarden_17, rimehowl_18, maw_19} : Bq.TexMob}; (+wld_28 = {Bq.TexWld.TexWld{elder_20, keeper_21, tiles_22, icons_23, slash_24, spark_25} : Bq.TexWld}; C.Bq.IO.pure(Bq.Assets, Bq.Assets.Assets{plr_26, mob_27, wld_28}))))))))))))))))))))))))))))))))))))))))))))))))))))))))

@unsafe
def Bq.a_wld():
  \{Bq.Assets.Assets: (plr_0 => (mob_1 => (wld_2 => wld_2))); \{}}

@unsafe
def Bq.a_tiles():
  (a_0 => (+apply_581 = {\{Bq.TexWld.TexWld: (elder_0 => (keeper_1 => (tiles_2 => (icons_3 => (slash_4 => (spark_5 => tiles_2)))))); \{}} : (@+___0: Bq.TexWld -> U32)}; apply_581(Bq.a_wld(a_0))))

@unsafe
def Bq.a_mob():
  \{Bq.Assets.Assets: (plr_0 => (mob_1 => (wld_2 => mob_1))); \{}}

@unsafe
def Bq.pick2():
  (i_0 => (a_1 => (b_2 => (+apply_597 = {(b_0 => (a_1 => (word => C.Bq.word_case(U32, word, 0, (unit => b_0), (_125_2 => a_1), 0)))) : (@+b_0: U32 -> (@+a_1: U32 -> (@+___2: U32 -> U32)))}; apply_597(b_2, a_1, C.Bq.bit(U32.is_eq(i_0, 0)))))))

@unsafe
def Bq.a_plr():
  \{Bq.Assets.Assets: (plr_0 => (mob_1 => (wld_2 => plr_0))); \{}}

@unsafe
def Bq.pick3():
  (i_0 => (a_1 => (b_2 => (c_3 => (+apply_600 = {(c_0 => (b_1 => (i_2 => (a_3 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_601 = {(c_0 => (b_1 => (word => C.Bq.word_case(U32, word, 0, (unit => c_0), (_131_2 => b_1), 0)))) : (@+c_0: U32 -> (@+b_1: U32 -> (@+___2: U32 -> U32)))}; apply_601(c_0, b_1, C.Bq.bit(U32.is_eq(i_2, 1))))), (_133_4 => a_3), 0)))))) : (@+c_0: U32 -> (@+b_1: U32 -> (@+i_2: U32 -> (@+a_3: U32 -> (@+___4: U32 -> U32)))))}; apply_600(c_3, b_2, i_0, a_1, C.Bq.bit(U32.is_eq(i_0, 0))))))))

@unsafe
def Bq.skin_tint():
  (i_0 => (+apply_604 = {(word => C.Bq.word_case(U32, word, 0, (unit => 4294367152), (word => C.Bq.word_case(U32, word, 1, (unit => 4293574809), (word => C.Bq.word_case(U32, word, 2, (unit => 4291200578), (__0 => 4287452452), 0)), 0)), 0)) : (@+___0: U32 -> U32)}; apply_604((i_0 % 4 : U32))))

@unsafe
def Bq.shirt_tint():
  (i_0 => (+apply_605 = {(word => C.Bq.word_case(U32, word, 0, (unit => 4282210974), (word => C.Bq.word_case(U32, word, 1, (unit => 4293413471), (word => C.Bq.word_case(U32, word, 2, (unit => 4284729165), (word => C.Bq.word_case(U32, word, 3, (unit => 4294955366), (word => C.Bq.word_case(U32, word, 4, (unit => 4286271413), (__0 => 4294938545), 0)), 0)), 0)), 0)), 0)) : (@+___0: U32 -> U32)}; apply_605((i_0 % 6 : U32))))

@unsafe
def Bq.hair_tint():
  (i_0 => (+apply_606 = {(word => C.Bq.word_case(U32, word, 0, (unit => 4283054936), (word => C.Bq.word_case(U32, word, 1, (unit => 4293436221), (word => C.Bq.word_case(U32, word, 2, (unit => 4289739346), (word => C.Bq.word_case(U32, word, 3, (unit => 4284729165), (word => C.Bq.word_case(U32, word, 4, (unit => 4284798962), (__0 => 4294110692), 0)), 0)), 0)), 0)), 0)) : (@+___0: U32 -> U32)}; apply_606((i_0 % 6 : U32))))

@unsafe
def Bq.a_icons():
  (a_0 => (+apply_619 = {\{Bq.TexWld.TexWld: (elder_0 => (keeper_1 => (tiles_2 => (icons_3 => (slash_4 => (spark_5 => icons_3)))))); \{}} : (@+___0: Bq.TexWld -> U32)}; apply_619(Bq.a_wld(a_0))))
