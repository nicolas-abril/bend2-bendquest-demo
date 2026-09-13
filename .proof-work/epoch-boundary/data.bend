# Bendquest data. Current Bend syntax; see README.md for the port notes.
import Base
import ./monster_damage.bend as MD
import ./population.bend as Pop
import ./landscape.bend as Landscape
import ./terrain.bend as Terrain
import ./combat.bend as Combat
import ./navigation.bend as Nav
import ./interactions.bend as Interact
import ./compat.bend as C

law Bq.TICK_MS:
  U32

law Bq.PORTAL_X:
  U32

law Bq.PORTAL_Y:
  U32

law Bq.BACK_X:
  U32

law Bq.BACK_Y:
  U32

law Bq.ZONE_W:
  U32

law Bq.ZONE_H:
  U32

law Bq.zone_name:
  (@+z_0: U32 -> C.Bq.String)

law Bq.SHOP_X:
  U32

law Bq.SHOP_Y:
  U32

law Bq.ELDER_X:
  U32

law Bq.ELDER_Y:
  U32

law Bq.MQ_SCORE_TALK:
  U32

law Bq.POTION_HEAL:
  U32

law Bq.charm_hp:
  (@+k_0: U32 -> U32)

law Bq.SPIN_CD_TICKS:
  U32

law Bq.mob_df:
  (@+k_0: U32 -> U32)

law Bq.MQ_SCORE_SIGIL:
  U32

law Bq.rank_coins:
  (@+rank_0: U32 -> U32)

law Bq.mob_gold:
  (@+k_0: U32 -> U32)

law Bq.mob_score:
  (@+k_0: U32 -> U32)

law Bq.MQ_CULL_N:
  U32

law Bq.MQ_SCORE_CULL:
  U32

law Bq.mob_drop_item:
  (@+k_0: U32 -> U32)

law Bq.mob_drop_pct:
  (@+k_0: U32 -> U32)

law Bq.zone_rare_item:
  (@+z_0: U32 -> U32)

law Bq.mob_name:
  (@+k_0: U32 -> C.Bq.String)

law Bq.boss_time_bonus:
  (@+k_0: U32 -> (@+elapsed_1: U32 -> U32))

law Bq.find_score:
  (@+r_0: U32 -> U32)

law Bq.item_rarity:
  (@+k_0: U32 -> U32)

law Bq.item_name:
  (@+k_0: U32 -> C.Bq.String)

law Bq.sideq_name:
  (@+q_0: U32 -> C.Bq.String)

law Bq.sideq_lore:
  (@+q_0: U32 -> C.Bq.String)

law Bq.sideq_score:
  (@+q_0: U32 -> U32)

law Bq.sideq_need:
  (@+q_0: U32 -> U32)

law Bq.xp_next:
  (@+lv_0: U32 -> U32)

law Bq.LV_CAP:
  U32

law Bq.mob_xp:
  (@+k_0: U32 -> U32)

law Bq.charm_agi_pct:
  (@+k_0: U32 -> U32)

law Bq.ATTACK_CD_TICKS:
  U32

law Bq.SPAWN_X:
  U32

law Bq.SPAWN_Y:
  U32

law Bq.cape_price:
  (@+i_0: U32 -> U32)

law Bq.hat_price:
  (@+i_0: U32 -> U32)

law Bq.RESTART_SECS:
  U32

law Bq.T_RIFTFLOOR:
  U32

law Bq.T_CRYSTAL:
  U32

law Bq.T_CAVEWALL:
  U32

law Bq.T_SNOW:
  U32

law Bq.T_ROCK:
  U32

law Bq.T_ICE:
  U32

law Bq.T_SNOWTREE:
  U32

law Bq.T_CAVEFLOOR:
  U32

law Bq.T_GRASS:
  U32

law Bq.T_FLOWER:
  U32

law Bq.T_WATER:
  U32

law Bq.T_TREE:
  U32

law Bq.T_PATH:
  U32

law Bq.T_PORTAL:
  U32

law Bq.T_RIFTPORTAL:
  U32

law Bq.T_SHOPMAT:
  U32

law Bq.RARE_SPAWN_PCT:
  U32

law Bq.mob_hp:
  (@+k_0: U32 -> U32)

law Bq.tile_walkable:
  (@+t_0: U32 -> U32)

law Bq.MOB_CAP_PER_ZONE:
  U32

law Bq.BOSS_X:
  U32

law Bq.MAW_X:
  U32

law Bq.BOSS_Y:
  U32

law Bq.MAW_Y:
  U32

law Bq.charm_atk:
  (@+k_0: U32 -> U32)

law Bq.RESPAWN_TICKS:
  U32

law Bq.mob_atk:
  (@+k_0: U32 -> U32)

law Bq.mainq_text:
  (@+st_0: U32 -> C.Bq.String)

law Bq.item_icon:
  (@+k_0: U32 -> U32)

law Bq.rarity_tint:
  (@+r_0: U32 -> U32)

law Bq.hat_name:
  (@+i_0: U32 -> C.Bq.String)

law Bq.cape_name:
  (@+i_0: U32 -> C.Bq.String)

@unsafe
def Bq.TICK_MS():
  120

@unsafe
def Bq.PORTAL_X():
  Nav.Navigation.forward_x(Nav.Navigation.rules)

@unsafe
def Bq.PORTAL_Y():
  Nav.Navigation.forward_y(Nav.Navigation.rules)

@unsafe
def Bq.BACK_X():
  Nav.Navigation.back_x(Nav.Navigation.rules)

@unsafe
def Bq.BACK_Y():
  Nav.Navigation.back_y(Nav.Navigation.rules)

@unsafe
def Bq.ZONE_W():
  Nav.Navigation.width

@unsafe
def Bq.ZONE_H():
  Nav.Navigation.height

@unsafe
def Bq.zone_name():
  (z_0 => (+apply_64 = {(z_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => (+apply_65 = {(z_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => (+apply_66 = {(word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => C.Bq.text("The Rift")), (_2_0 => C.Bq.text("Frostpeak")), 0)) : (@+___0: U32 -> List<&1, Char>)}; apply_66(C.Bq.bit(U32.is_eq(z_0, 2))))), (_4_1 => C.Bq.text("Gloomdepth Cavern")), 0))) : (@+z_0: U32 -> (@+___1: U32 -> List<&1, Char>))}; apply_65(z_0, C.Bq.bit(U32.is_eq(z_0, 1))))), (_6_1 => C.Bq.text("Verdant Hollow")), 0))) : (@+z_0: U32 -> (@+___1: U32 -> List<&1, Char>))}; apply_64(z_0, C.Bq.bit(U32.is_eq(z_0, 0)))))

@unsafe
def Bq.SHOP_X():
  Interact.Interaction.shop_x

@unsafe
def Bq.SHOP_Y():
  Interact.Interaction.shop_y

@unsafe
def Bq.ELDER_X():
  Interact.Interaction.elder_x

@unsafe
def Bq.ELDER_Y():
  Interact.Interaction.elder_y

@unsafe
def Bq.MQ_SCORE_TALK():
  Interact.Interaction.talk_score

@unsafe
def Bq.POTION_HEAL():
  40

@unsafe
def Bq.charm_hp():
  (k_0 => (+apply_118 = {(word => C.Bq.word_case(U32, word, 0, (unit => 0), (_269_0 => 30), 0)) : (@+___0: U32 -> U32)}; apply_118(C.Bq.bit(U32.is_eq(k_0, 17)))))

@unsafe
def Bq.SPIN_CD_TICKS():
  Combat.Combat.spin_ticks

@unsafe
def Bq.mob_df():
  (k_0 => (+apply_132 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_133 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_134 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_135 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_136 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_137 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_138 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_139 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_140 = {(word => C.Bq.word_case(U32, word, 0, (unit => 12), (_86_0 => 10), 0)) : (@+___0: U32 -> U32)}; apply_140(C.Bq.bit(U32.is_eq(k_0, 8))))), (_88_1 => 8), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_139(k_0, C.Bq.bit(U32.is_eq(k_0, 7))))), (_90_1 => 3), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_138(k_0, C.Bq.bit(U32.is_eq(k_0, 6))))), (_92_1 => 8), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_137(k_0, C.Bq.bit(U32.is_eq(k_0, 5))))), (_94_1 => 6), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_136(k_0, C.Bq.bit(U32.is_eq(k_0, 4))))), (_96_1 => 5), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_135(k_0, C.Bq.bit(U32.is_eq(k_0, 3))))), (_98_1 => 2), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_134(k_0, C.Bq.bit(U32.is_eq(k_0, 2))))), (_100_1 => 1), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_133(k_0, C.Bq.bit(U32.is_eq(k_0, 1))))), (_102_1 => 0), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_132(k_0, C.Bq.bit(U32.is_eq(k_0, 0)))))

@unsafe
def Bq.MQ_SCORE_SIGIL():
  200

@unsafe
def Bq.rank_coins():
  (rank_0 => (+apply_154 = {(rank_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_155 = {(rank_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_156 = {(word => C.Bq.word_case(U32, word, 0, (unit => 40), (_318_0 => 60), 0)) : (@+___0: U32 -> U32)}; apply_156(C.Bq.bit(U32.is_eq(rank_0, 2))))), (_320_1 => 80), 0))) : (@+rank_0: U32 -> (@+___1: U32 -> U32))}; apply_155(rank_0, C.Bq.bit(U32.is_eq(rank_0, 1))))), (_322_1 => 120), 0))) : (@+rank_0: U32 -> (@+___1: U32 -> U32))}; apply_154(rank_0, C.Bq.bit(U32.is_eq(rank_0, 0)))))

@unsafe
def Bq.mob_gold():
  (k_0 => (+apply_161 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_162 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_163 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_164 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_165 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_166 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_167 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_168 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_169 = {(word => C.Bq.word_case(U32, word, 0, (unit => 500), (_124_0 => 280), 0)) : (@+___0: U32 -> U32)}; apply_169(C.Bq.bit(U32.is_eq(k_0, 8))))), (_126_1 => 160), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_168(k_0, C.Bq.bit(U32.is_eq(k_0, 7))))), (_128_1 => 80), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_167(k_0, C.Bq.bit(U32.is_eq(k_0, 6))))), (_130_1 => 25), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_166(k_0, C.Bq.bit(U32.is_eq(k_0, 5))))), (_132_1 => 19), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_165(k_0, C.Bq.bit(U32.is_eq(k_0, 4))))), (_134_1 => 14), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_164(k_0, C.Bq.bit(U32.is_eq(k_0, 3))))), (_136_1 => 9), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_163(k_0, C.Bq.bit(U32.is_eq(k_0, 2))))), (_138_1 => 5), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_162(k_0, C.Bq.bit(U32.is_eq(k_0, 1))))), (_140_1 => 3), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_161(k_0, C.Bq.bit(U32.is_eq(k_0, 0)))))

@unsafe
def Bq.mob_score():
  (k_0 => (+apply_170 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_171 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_172 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_173 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_174 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_175 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_176 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_177 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_178 = {(word => C.Bq.word_case(U32, word, 0, (unit => 1500), (_143_0 => 500), 0)) : (@+___0: U32 -> U32)}; apply_178(C.Bq.bit(U32.is_eq(k_0, 8))))), (_145_1 => 300), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_177(k_0, C.Bq.bit(U32.is_eq(k_0, 7))))), (_147_1 => 150), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_176(k_0, C.Bq.bit(U32.is_eq(k_0, 6))))), (_149_1 => 18), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_175(k_0, C.Bq.bit(U32.is_eq(k_0, 5))))), (_151_1 => 14), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_174(k_0, C.Bq.bit(U32.is_eq(k_0, 4))))), (_153_1 => 10), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_173(k_0, C.Bq.bit(U32.is_eq(k_0, 3))))), (_155_1 => 6), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_172(k_0, C.Bq.bit(U32.is_eq(k_0, 2))))), (_157_1 => 3), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_171(k_0, C.Bq.bit(U32.is_eq(k_0, 1))))), (_159_1 => 2), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_170(k_0, C.Bq.bit(U32.is_eq(k_0, 0)))))

@unsafe
def Bq.MQ_CULL_N():
  8

@unsafe
def Bq.MQ_SCORE_CULL():
  60

@unsafe
def Bq.mob_drop_item():
  (k_0 => (+apply_182 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_183 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_184 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_185 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_186 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_187 = {(word => C.Bq.word_case(U32, word, 0, (unit => 0), (_169_0 => 17), 0)) : (@+___0: U32 -> U32)}; apply_187(C.Bq.bit(U32.is_eq(k_0, 5))))), (_171_1 => 10), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_186(k_0, C.Bq.bit(U32.is_eq(k_0, 4))))), (_173_1 => 4), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_185(k_0, C.Bq.bit(U32.is_eq(k_0, 3))))), (_175_1 => 8), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_184(k_0, C.Bq.bit(U32.is_eq(k_0, 2))))), (_177_1 => 12), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_183(k_0, C.Bq.bit(U32.is_eq(k_0, 1))))), (_179_1 => 7), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_182(k_0, C.Bq.bit(U32.is_eq(k_0, 0)))))

@unsafe
def Bq.mob_drop_pct():
  (k_0 => (+apply_188 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_189 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_190 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_191 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_192 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_193 = {(word => C.Bq.word_case(U32, word, 0, (unit => 0), (_182_0 => 8), 0)) : (@+___0: U32 -> U32)}; apply_193(C.Bq.bit(U32.is_eq(k_0, 5))))), (_184_1 => 8), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_192(k_0, C.Bq.bit(U32.is_eq(k_0, 4))))), (_186_1 => 10), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_191(k_0, C.Bq.bit(U32.is_eq(k_0, 3))))), (_188_1 => 8), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_190(k_0, C.Bq.bit(U32.is_eq(k_0, 2))))), (_190_1 => 10), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_189(k_0, C.Bq.bit(U32.is_eq(k_0, 1))))), (_192_1 => 8), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_188(k_0, C.Bq.bit(U32.is_eq(k_0, 0)))))

@unsafe
def Bq.zone_rare_item():
  (z_0 => (+apply_195 = {(z_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_196 = {(z_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_197 = {(word => C.Bq.word_case(U32, word, 0, (unit => 6), (_195_0 => 5), 0)) : (@+___0: U32 -> U32)}; apply_197(C.Bq.bit(U32.is_eq(z_0, 2))))), (_197_1 => 13), 0))) : (@+z_0: U32 -> (@+___1: U32 -> U32))}; apply_196(z_0, C.Bq.bit(U32.is_eq(z_0, 1))))), (_199_1 => 3), 0))) : (@+z_0: U32 -> (@+___1: U32 -> U32))}; apply_195(z_0, C.Bq.bit(U32.is_eq(z_0, 0)))))

@unsafe
def Bq.mob_name():
  (k_0 => (+apply_200 = {(k_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => (+apply_201 = {(k_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => (+apply_202 = {(k_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => (+apply_203 = {(k_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => (+apply_204 = {(k_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => (+apply_205 = {(k_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => (+apply_206 = {(k_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => (+apply_207 = {(k_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => (+apply_208 = {(word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => C.Bq.text("The Nulltide Maw")), (_10_0 => C.Bq.text("Rimehowl")), 0)) : (@+___0: U32 -> List<&1, Char>)}; apply_208(C.Bq.bit(U32.is_eq(k_0, 8))))), (_12_1 => C.Bq.text("The Stonewarden")), 0))) : (@+k_0: U32 -> (@+___1: U32 -> List<&1, Char>))}; apply_207(k_0, C.Bq.bit(U32.is_eq(k_0, 7))))), (_14_1 => C.Bq.text("Mossback the Elder")), 0))) : (@+k_0: U32 -> (@+___1: U32 -> List<&1, Char>))}; apply_206(k_0, C.Bq.bit(U32.is_eq(k_0, 6))))), (_16_1 => C.Bq.text("Ice Wisp")), 0))) : (@+k_0: U32 -> (@+___1: U32 -> List<&1, Char>))}; apply_205(k_0, C.Bq.bit(U32.is_eq(k_0, 5))))), (_18_1 => C.Bq.text("Frost Wolf")), 0))) : (@+k_0: U32 -> (@+___1: U32 -> List<&1, Char>))}; apply_204(k_0, C.Bq.bit(U32.is_eq(k_0, 4))))), (_20_1 => C.Bq.text("Rock Golem")), 0))) : (@+k_0: U32 -> (@+___1: U32 -> List<&1, Char>))}; apply_203(k_0, C.Bq.bit(U32.is_eq(k_0, 3))))), (_22_1 => C.Bq.text("Cave Bat")), 0))) : (@+k_0: U32 -> (@+___1: U32 -> List<&1, Char>))}; apply_202(k_0, C.Bq.bit(U32.is_eq(k_0, 2))))), (_24_1 => C.Bq.text("Spore Cap")), 0))) : (@+k_0: U32 -> (@+___1: U32 -> List<&1, Char>))}; apply_201(k_0, C.Bq.bit(U32.is_eq(k_0, 1))))), (_26_1 => C.Bq.text("Slime")), 0))) : (@+k_0: U32 -> (@+___1: U32 -> List<&1, Char>))}; apply_200(k_0, C.Bq.bit(U32.is_eq(k_0, 0)))))

@unsafe
def Bq.boss_time_bonus():
  (k_0 => (elapsed_1 => (+base_2 = {1800 : U32}; (+apply_211 = {(base_0 => (elapsed_1 => (k_2 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_212 = {(base_0 => (elapsed_1 => (word => C.Bq.word_case(U32, word, 0, (unit => ((base_0 - elapsed_1 : U32) / 6 : U32)), (_313_2 => ((base_0 - elapsed_1 : U32) / 2 : U32)), 0)))) : (@+base_0: U32 -> (@+elapsed_1: U32 -> (@+___2: U32 -> U32)))}; apply_212(base_0, elapsed_1, C.Bq.bit(U32.is_eq(k_2, 9))))), (_315_3 => 0), 0))))) : (@+base_0: U32 -> (@+elapsed_1: U32 -> (@+k_2: U32 -> (@+___3: U32 -> U32))))}; apply_211(base_2, elapsed_1, k_0, C.Bq.bit(U32.is_ge(elapsed_1, base_2)))))))

@unsafe
def Bq.find_score():
  (r_0 => (+apply_215 = {(r_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_216 = {(word => C.Bq.word_case(U32, word, 0, (unit => 0), (_258_0 => 250), 0)) : (@+___0: U32 -> U32)}; apply_216(C.Bq.bit(U32.is_eq(r_0, 2))))), (_260_1 => 60), 0))) : (@+r_0: U32 -> (@+___1: U32 -> U32))}; apply_215(r_0, C.Bq.bit(U32.is_eq(r_0, 1)))))

@unsafe
def Bq.item_rarity():
  (k_0 => (+apply_217 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_218 = {(word => C.Bq.word_case(U32, word, 0, (unit => 0), (_248_0 => 2), 0)) : (@+___0: U32 -> U32)}; apply_218(C.Bq.word_or(C.Bq.bit(U32.is_eq(k_0, 6)), C.Bq.bit(U32.is_eq(k_0, 11)))))), (_250_1 => 1), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_217(k_0, C.Bq.word_or(C.Bq.word_or(C.Bq.word_or(C.Bq.word_or(C.Bq.word_or(C.Bq.bit(U32.is_eq(k_0, 3)), C.Bq.bit(U32.is_eq(k_0, 5))), C.Bq.bit(U32.is_eq(k_0, 13))), C.Bq.bit(U32.is_eq(k_0, 10))), C.Bq.bit(U32.is_eq(k_0, 16))), C.Bq.bit(U32.is_eq(k_0, 14))))))

@unsafe
def Bq.item_name():
  (k_0 => (+apply_220 = {(k_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => (+apply_221 = {(k_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => (+apply_222 = {(k_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => (+apply_223 = {(k_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => (+apply_224 = {(k_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => (+apply_225 = {(k_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => (+apply_226 = {(k_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => (+apply_227 = {(k_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => (+apply_228 = {(k_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => (+apply_229 = {(k_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => (+apply_230 = {(k_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => (+apply_231 = {(k_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => (+apply_232 = {(k_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => (+apply_233 = {(k_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => (+apply_234 = {(k_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => (+apply_235 = {(k_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => (+apply_236 = {(word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => C.Bq.text("Heart Amulet")), (_202_0 => C.Bq.text("Ember Ring")), 0)) : (@+___0: U32 -> List<&1, Char>)}; apply_236(C.Bq.bit(U32.is_eq(k_0, 16))))), (_204_1 => C.Bq.text("Lucky Clover")), 0))) : (@+k_0: U32 -> (@+___1: U32 -> List<&1, Char>))}; apply_235(k_0, C.Bq.bit(U32.is_eq(k_0, 15))))), (_206_1 => C.Bq.text("Ice Crown")), 0))) : (@+k_0: U32 -> (@+___1: U32 -> List<&1, Char>))}; apply_234(k_0, C.Bq.bit(U32.is_eq(k_0, 14))))), (_208_1 => C.Bq.text("Miner Helm")), 0))) : (@+k_0: U32 -> (@+___1: U32 -> List<&1, Char>))}; apply_233(k_0, C.Bq.bit(U32.is_eq(k_0, 13))))), (_210_1 => C.Bq.text("Leaf Cap")), 0))) : (@+k_0: U32 -> (@+___1: U32 -> List<&1, Char>))}; apply_232(k_0, C.Bq.bit(U32.is_eq(k_0, 12))))), (_212_1 => C.Bq.text("Rift Guard")), 0))) : (@+k_0: U32 -> (@+___1: U32 -> List<&1, Char>))}; apply_231(k_0, C.Bq.bit(U32.is_eq(k_0, 11))))), (_214_1 => C.Bq.text("Frost Mail")), 0))) : (@+k_0: U32 -> (@+___1: U32 -> List<&1, Char>))}; apply_230(k_0, C.Bq.bit(U32.is_eq(k_0, 10))))), (_216_1 => C.Bq.text("Stone Plate")), 0))) : (@+k_0: U32 -> (@+___1: U32 -> List<&1, Char>))}; apply_229(k_0, C.Bq.bit(U32.is_eq(k_0, 9))))), (_218_1 => C.Bq.text("Leather Vest")), 0))) : (@+k_0: U32 -> (@+___1: U32 -> List<&1, Char>))}; apply_228(k_0, C.Bq.bit(U32.is_eq(k_0, 8))))), (_220_1 => C.Bq.text("Cloth Tunic")), 0))) : (@+k_0: U32 -> (@+___1: U32 -> List<&1, Char>))}; apply_227(k_0, C.Bq.bit(U32.is_eq(k_0, 7))))), (_222_1 => C.Bq.text("Rift Edge")), 0))) : (@+k_0: U32 -> (@+___1: U32 -> List<&1, Char>))}; apply_226(k_0, C.Bq.bit(U32.is_eq(k_0, 6))))), (_224_1 => C.Bq.text("Frost Axe")), 0))) : (@+k_0: U32 -> (@+___1: U32 -> List<&1, Char>))}; apply_225(k_0, C.Bq.bit(U32.is_eq(k_0, 5))))), (_226_1 => C.Bq.text("Cave Pick")), 0))) : (@+k_0: U32 -> (@+___1: U32 -> List<&1, Char>))}; apply_224(k_0, C.Bq.bit(U32.is_eq(k_0, 4))))), (_228_1 => C.Bq.text("Moss Blade")), 0))) : (@+k_0: U32 -> (@+___1: U32 -> List<&1, Char>))}; apply_223(k_0, C.Bq.bit(U32.is_eq(k_0, 3))))), (_230_1 => C.Bq.text("Iron Sword")), 0))) : (@+k_0: U32 -> (@+___1: U32 -> List<&1, Char>))}; apply_222(k_0, C.Bq.bit(U32.is_eq(k_0, 2))))), (_232_1 => C.Bq.text("Wooden Sword")), 0))) : (@+k_0: U32 -> (@+___1: U32 -> List<&1, Char>))}; apply_221(k_0, C.Bq.bit(U32.is_eq(k_0, 1))))), (_234_1 => C.Bq.text("Potion")), 0))) : (@+k_0: U32 -> (@+___1: U32 -> List<&1, Char>))}; apply_220(k_0, C.Bq.bit(U32.is_eq(k_0, 0)))))

@unsafe
def Bq.sideq_name():
  (q_0 => (+apply_240 = {(q_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => (+apply_241 = {(word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => C.Bq.text("The Lost Cub")), (_286_0 => C.Bq.text("Echoes in the Dark")), 0)) : (@+___0: U32 -> List<&1, Char>)}; apply_241(C.Bq.bit(U32.is_eq(q_0, 1))))), (_288_1 => C.Bq.text("Mushroom Soup")), 0))) : (@+q_0: U32 -> (@+___1: U32 -> List<&1, Char>))}; apply_240(q_0, C.Bq.bit(U32.is_eq(q_0, 0)))))

@unsafe
def Bq.sideq_lore():
  (q_0 => (+apply_242 = {(q_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => (+apply_243 = {(word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => C.Bq.text("The cub is safe. Rimehowl only rages because the Rift gnaws its den.")), (_306_0 => C.Bq.text("The shards hum an old song. The Stonewarden was a guardian, once.")), 0)) : (@+___0: U32 -> List<&1, Char>)}; apply_243(C.Bq.bit(U32.is_eq(q_0, 1))))), (_308_1 => C.Bq.text("Elder Fern: 'Before the Rift, these caps seasoned the harvest feast.'")), 0))) : (@+q_0: U32 -> (@+___1: U32 -> List<&1, Char>))}; apply_242(q_0, C.Bq.bit(U32.is_eq(q_0, 0)))))

@unsafe
def Bq.sideq_score():
  (q_0 => (+apply_244 = {(q_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_245 = {(word => C.Bq.word_case(U32, word, 0, (unit => 120), (_301_0 => 90), 0)) : (@+___0: U32 -> U32)}; apply_245(C.Bq.bit(U32.is_eq(q_0, 1))))), (_303_1 => 50), 0))) : (@+q_0: U32 -> (@+___1: U32 -> U32))}; apply_244(q_0, C.Bq.bit(U32.is_eq(q_0, 0)))))

@unsafe
def Bq.sideq_need():
  (q_0 => (+apply_246 = {(q_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_247 = {(word => C.Bq.word_case(U32, word, 0, (unit => 6), (_291_0 => 4), 0)) : (@+___0: U32 -> U32)}; apply_247(C.Bq.bit(U32.is_eq(q_0, 1))))), (_293_1 => 5), 0))) : (@+q_0: U32 -> (@+___1: U32 -> U32))}; apply_246(q_0, C.Bq.bit(U32.is_eq(q_0, 0)))))

@unsafe
def Bq.xp_next():
  (lv_0 => ((25 * lv_0 : U32) * lv_0 : U32))

@unsafe
def Bq.LV_CAP():
  20

@unsafe
def Bq.mob_xp():
  (k_0 => (+apply_266 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_267 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_268 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_269 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_270 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_271 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_272 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_273 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_274 = {(word => C.Bq.word_case(U32, word, 0, (unit => 3000), (_105_0 => 1300), 0)) : (@+___0: U32 -> U32)}; apply_274(C.Bq.bit(U32.is_eq(k_0, 8))))), (_107_1 => 700), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_273(k_0, C.Bq.bit(U32.is_eq(k_0, 7))))), (_109_1 => 300), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_272(k_0, C.Bq.bit(U32.is_eq(k_0, 6))))), (_111_1 => 95), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_271(k_0, C.Bq.bit(U32.is_eq(k_0, 5))))), (_113_1 => 70), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_270(k_0, C.Bq.bit(U32.is_eq(k_0, 4))))), (_115_1 => 48), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_269(k_0, C.Bq.bit(U32.is_eq(k_0, 3))))), (_117_1 => 30), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_268(k_0, C.Bq.bit(U32.is_eq(k_0, 2))))), (_119_1 => 13), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_267(k_0, C.Bq.bit(U32.is_eq(k_0, 1))))), (_121_1 => 8), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_266(k_0, C.Bq.bit(U32.is_eq(k_0, 0)))))

@unsafe
def Bq.charm_agi_pct():
  (k_0 => (+apply_312 = {(word => C.Bq.word_case(U32, word, 0, (unit => 0), (_266_0 => 10), 0)) : (@+___0: U32 -> U32)}; apply_312(C.Bq.bit(U32.is_eq(k_0, 15)))))

@unsafe
def Bq.ATTACK_CD_TICKS():
  Combat.Combat.attack_ticks

@unsafe
def Bq.SPAWN_X():
  Landscape.Landscape.spawn_x

@unsafe
def Bq.SPAWN_Y():
  Landscape.Landscape.spawn_y

@unsafe
def Bq.cape_price():
  (i_0 => (+apply_352 = {(word => C.Bq.word_case(U32, word, 0, (unit => 200), (_338_0 => 80), 0)) : (@+___0: U32 -> U32)}; apply_352(C.Bq.bit(U32.is_eq(i_0, 0)))))

@unsafe
def Bq.hat_price():
  (i_0 => (+apply_353 = {(i_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_354 = {(word => C.Bq.word_case(U32, word, 0, (unit => 300), (_330_0 => 120), 0)) : (@+___0: U32 -> U32)}; apply_354(C.Bq.bit(U32.is_eq(i_0, 1))))), (_332_1 => 40), 0))) : (@+i_0: U32 -> (@+___1: U32 -> U32))}; apply_353(i_0, C.Bq.bit(U32.is_eq(i_0, 0)))))

@unsafe
def Bq.RESTART_SECS():
  300

@unsafe
def Bq.T_RIFTFLOOR():
  13

@unsafe
def Bq.T_CRYSTAL():
  8

@unsafe
def Bq.T_CAVEWALL():
  7

@unsafe
def Bq.T_SNOW():
  9

@unsafe
def Bq.T_ROCK():
  5

@unsafe
def Bq.T_ICE():
  10

@unsafe
def Bq.T_SNOWTREE():
  11

@unsafe
def Bq.T_CAVEFLOOR():
  6

@unsafe
def Bq.T_GRASS():
  0

@unsafe
def Bq.T_FLOWER():
  1

@unsafe
def Bq.T_WATER():
  3

@unsafe
def Bq.T_TREE():
  2

@unsafe
def Bq.T_PATH():
  4

@unsafe
def Bq.T_PORTAL():
  12

@unsafe
def Bq.T_RIFTPORTAL():
  14

@unsafe
def Bq.T_SHOPMAT():
  15

@unsafe
def Bq.RARE_SPAWN_PCT(): Pop.Population.rare_pct

@unsafe
def Bq.mob_hp(kind): Pop.Population.maximum(kind)

@unsafe
def Bq.tile_walkable(tile): C.Bq.bit(Terrain.Terrain.walkable(tile))

@unsafe
def Bq.MOB_CAP_PER_ZONE(): Pop.Population.cap

@unsafe
def Bq.BOSS_X(): Pop.Population.boss_x

@unsafe
def Bq.MAW_X(): Pop.Population.maw_x

@unsafe
def Bq.BOSS_Y(): Pop.Population.boss_y

@unsafe
def Bq.MAW_Y(): Pop.Population.maw_y

@unsafe
def Bq.charm_atk():
  (k_0 => (+apply_457 = {(word => C.Bq.word_case(U32, word, 0, (unit => 0), (_263_0 => 4), 0)) : (@+___0: U32 -> U32)}; apply_457(C.Bq.bit(U32.is_eq(k_0, 16)))))

@unsafe
def Bq.RESPAWN_TICKS():
  40

def Bq.mob_atk(kind): MD.MonsterDamage.catalog(kind)

@unsafe
def Bq.mainq_text():
  (st_0 => (+apply_622 = {(st_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => (+apply_623 = {(st_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => (+apply_624 = {(st_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => (+apply_625 = {(st_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => (+apply_626 = {(st_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => (+apply_627 = {(word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => C.Bq.text("Legend of the realm")), (_273_0 => C.Bq.text("SEAL THE RIFT - together!")), 0)) : (@+___0: U32 -> List<&1, Char>)}; apply_627(C.Bq.bit(U32.is_eq(st_0, 5))))), (_275_1 => C.Bq.text("Claim Rimehowl's sigil (zone 3)")), 0))) : (@+st_0: U32 -> (@+___1: U32 -> List<&1, Char>))}; apply_626(st_0, C.Bq.bit(U32.is_eq(st_0, 4))))), (_277_1 => C.Bq.text("Claim the Stonewarden's sigil (zone 2)")), 0))) : (@+st_0: U32 -> (@+___1: U32 -> List<&1, Char>))}; apply_625(st_0, C.Bq.bit(U32.is_eq(st_0, 3))))), (_279_1 => C.Bq.text("Claim Mossback's sigil (zone 1 boss)")), 0))) : (@+st_0: U32 -> (@+___1: U32 -> List<&1, Char>))}; apply_624(st_0, C.Bq.bit(U32.is_eq(st_0, 2))))), (_281_1 => C.Bq.text("Cull 8 slimes for the village")), 0))) : (@+st_0: U32 -> (@+___1: U32 -> List<&1, Char>))}; apply_623(st_0, C.Bq.bit(U32.is_eq(st_0, 1))))), (_283_1 => C.Bq.text("Speak with Elder Fern (E near her)")), 0))) : (@+st_0: U32 -> (@+___1: U32 -> List<&1, Char>))}; apply_622(st_0, C.Bq.bit(U32.is_eq(st_0, 0)))))

@unsafe
def Bq.item_icon():
  (k_0 => (+apply_636 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_637 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_638 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_639 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_640 = {(word => C.Bq.word_case(U32, word, 0, (unit => 5), (_237_0 => 4), 0)) : (@+___0: U32 -> U32)}; apply_640(C.Bq.word_and(C.Bq.bit(U32.is_ge(k_0, 12)), C.Bq.bit(U32.is_le(k_0, 14)))))), (_239_1 => 3), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_639(k_0, C.Bq.word_and(C.Bq.bit(U32.is_ge(k_0, 7)), C.Bq.bit(U32.is_le(k_0, 11)))))), (_241_1 => 1), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_638(k_0, C.Bq.word_and(C.Bq.bit(U32.is_ge(k_0, 1)), C.Bq.bit(U32.is_le(k_0, 6)))))), (_243_1 => 2), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_637(k_0, C.Bq.word_or(C.Bq.bit(U32.is_eq(k_0, 4)), C.Bq.bit(U32.is_eq(k_0, 5)))))), (_245_1 => 0), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_636(k_0, C.Bq.bit(U32.is_eq(k_0, 0)))))

@unsafe
def Bq.rarity_tint():
  (r_0 => (+apply_641 = {(r_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_642 = {(word => C.Bq.word_case(U32, word, 0, (unit => 4294967295), (_253_0 => 4294955366), 0)) : (@+___0: U32 -> U32)}; apply_642(C.Bq.bit(U32.is_eq(r_0, 2))))), (_255_1 => 4288407039), 0))) : (@+r_0: U32 -> (@+___1: U32 -> U32))}; apply_641(r_0, C.Bq.bit(U32.is_eq(r_0, 1)))))

@unsafe
def Bq.hat_name():
  (i_0 => (+apply_668 = {(i_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => (+apply_669 = {(word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => C.Bq.text("Champion's Crown")), (_325_0 => C.Bq.text("Star Wizard Hat")), 0)) : (@+___0: U32 -> List<&1, Char>)}; apply_669(C.Bq.bit(U32.is_eq(i_0, 1))))), (_327_1 => C.Bq.text("Leaf Cap (cosmetic)")), 0))) : (@+i_0: U32 -> (@+___1: U32 -> List<&1, Char>))}; apply_668(i_0, C.Bq.bit(U32.is_eq(i_0, 0)))))

@unsafe
def Bq.cape_name():
  (i_0 => (+apply_671 = {(word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => C.Bq.text("Night-Sky Cape")), (_335_0 => C.Bq.text("Scarlet Cape")), 0)) : (@+___0: U32 -> List<&1, Char>)}; apply_671(C.Bq.bit(U32.is_eq(i_0, 0)))))
