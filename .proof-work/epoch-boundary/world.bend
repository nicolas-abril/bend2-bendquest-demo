# Bendquest world. Current Bend syntax; see README.md for the port notes.
import Base
import ./live_attack.bend as LiveAttack
import ./live_spin.bend as LiveSpin
import ./spin_plans.bend as Spin
import ./combat_targets.bend as Targets
import ./target_plans.bend as TP
import ./live_combat.bend as Fight
import ./live_commands.bend as LC
import ./live_tick.bend as Tick
import ./monster_damage.bend as MD
import ./ai_refs.bend as AIRefs
import ./targeting.bend as Targeting
import ./references.bend as Ref
import ./admission.bend as Join
import ./population.bend as Pop
import ./placement.bend as Place
import ./planning.bend as Plan
import ./pursuit.bend as Pursuit
import ./landscape.bend as Landscape
import ./locomotion.bend as L
import ./terrain.bend as Terrain
import ./battle.bend as Battle
import ./combat.bend as Combat
import ./interactions.bend as Interact
import ./payouts.bend as Pay
import ./inventory.bend as I
import ./simulation.bend as S
import ./players.bend as P
import ./health.bend as Health
import ./vitals.bend as V
import ./monsters.bend as M
import ./roster.bend as R
import ./ai.bend as A
import ./rewards.bend as Rewards
import ./compat.bend as C
import ./game.bend as Game
import ./support.bend as Support
import ./proto.bend as Proto
import ./data.bend as Data

law Bq.hash2:
  (@+a_0: U32 -> (@+b_1: U32 -> U32))

law Bq.lget:
  (@+xs_0: List<&1, U32> -> (@+i_1: U32 -> (@+d_2: U32 -> U32)))

def Bq.WMeta() -> Data:
  S.Simulation.Meta

def Bq.Pos() -> Data:
  P.Players.Pos

def Bq.Vit() -> Data:
  V.Vitals.State

def Bq.PStyle() -> Data:
  P.Players.Style

def Bq.Qst() -> Data:
  P.Players.Quest

def Bq.PMeta() -> Data:
  P.Players.Meta

def Bq.Plr() -> Data:
  P.Players.State

def Bq.make_meta(score: U32, kills: U32, found: U32, name: C.Bq.String) -> Bq.PMeta:
  P.Players.Meta{score, kills, found, P.Players.share_name(name)}

def Bq.Mob() -> Data:
  M.Monsters.State

def Bq.World() -> Data:
  Terrain.Terrain.World

law Bq.wm_phase:
  (@+m_0: Bq.WMeta -> U32)

type Bq.OutL is Type:
  Bq.OutL.All{line_0: C.Bq.String}
  Bq.OutL.To{cid_0: U32, line_1: C.Bq.String}
  Bq.OutL.ZoneL{zone_0: U32, line_1: C.Bq.String}
  Bq.OutL.Log{line_0: C.Bq.String}

law Bq.render_live_command:
  LC.LiveCommands.Result -> List<&1,Bq.OutL>

law Bq.pos_zone:
  (@+p_0: Bq.Pos -> U32)

law Bq.put_plr:
  (@+wm_0: Bq.WMeta -> (@+p_1: Bq.Plr -> (@+others_2: List<&2, Bq.Plr> -> (@+mobs_3: List<&2, Bq.Mob> -> (@+maps_4: List<&2,List<&2,U32>> -> Bq.World)))))

law Bq.tile_hex:
  (@+t_0: U32 -> Char)

law Bq.map_hex:
  (@+m_0: List<&2, U32> -> C.Bq.String)

law Bq.map_of:
  (@+maps_0: List<&2,List<&2,U32>> -> (@+z_1: U32 -> List<&2, U32>))

law Bq.zone_line:
  (@+maps_0: List<&2,List<&2,U32>> -> (@+z_1: U32 -> C.Bq.String))

law Bq.wm_sigils:
  (@+m_0: Bq.WMeta -> U32)

law Bq.take_plr:
  (@+pid_0: U32 -> (@+ps_1: List<&2, Bq.Plr> -> C.Bq.Pair.Pair(List<&2, Bq.Plr>, (__2 => Support.Bq.Maybe(Bq.Plr)))))

law Bq.cmd_enter:
  (@+w_0: Bq.World -> (@+pid_1: U32 -> C.Bq.Pair.Pair(Bq.World, (__2 => List<&1, Bq.OutL>))))

law Bq.chdist:
  (@+ax_0: U32 -> (@+ay_1: U32 -> (@+bx_2: U32 -> (@+by_3: U32 -> U32))))

law Bq.near_shop:
  (@+z_0: U32 -> (@+x_1: U32 -> (@+y_2: U32 -> U32)))

law Bq.elder_line:
  (@+mainq_0: U32 -> (@+sigils_1: U32 -> C.Bq.String))

law Bq.near_elder:
  (@+z_0: U32 -> (@+x_1: U32 -> (@+y_2: U32 -> U32)))

law Bq.cmd_talk:
  (@+w_0: Bq.World -> (@+pid_1: U32 -> (@+npc_2: U32 -> C.Bq.Pair.Pair(Bq.World, (__3 => List<&1, Bq.OutL>)))))

law Bq.hero_gold_u:
  (@+h_0: Game.Bq.Hero -> U32)

law Bq.slot_kind:
  (@+m_0: Game.Bq.Maybe(Nat) -> U32)

law Bq.hero_maxhp:
  (@+h_0: Game.Bq.Hero -> U32)

law Bq.bag_count:
  (@+b_0: Game.Bq.Bag -> (@+k_1: U32 -> U32))

law Bq.hero_pots:
  (@+h_0: Game.Bq.Hero -> U32)

law Bq.too_far_out:
  (@+cid_0: U32 -> (@+fb_1: U32 -> List<&1, Bq.OutL>))

law Bq.cmd_buy:
  (@+w_0: Bq.World -> (@+pid_1: U32 -> (@+k_2: U32 -> C.Bq.Pair.Pair(Bq.World, (__3 => List<&1, Bq.OutL>)))))

law Bq.cmd_alloc:
  (@+w_0: Bq.World -> (@+pid_1: U32 -> (@+s_2: U32 -> C.Bq.Pair.Pair(Bq.World, (__3 => List<&1, Bq.OutL>)))))

law Bq.wire_slot:
  (@+s_0: U32 -> Game.Bq.ISlot)

law Bq.cmd_uneq:
  (@+w_0: Bq.World -> (@+pid_1: U32 -> (@+s_2: U32 -> C.Bq.Pair.Pair(Bq.World, (__3 => List<&1, Bq.OutL>)))))

law Bq.cmd_equip:
  (@+w_0: Bq.World -> (@+pid_1: U32 -> (@+k_2: U32 -> C.Bq.Pair.Pair(Bq.World, (__3 => List<&1, Bq.OutL>)))))

law Bq.cmd_quaff:
  (@+w_0: Bq.World -> (@+pid_1: U32 -> C.Bq.Pair.Pair(Bq.World, (__2 => List<&1, Bq.OutL>))))

law Bq.mids_in_reach:
  (@+ms_0: List<&2, Bq.Mob> -> (@+z_1: U32 -> (@+x_2: U32 -> (@+y_3: U32 -> List<&1, U32>))))

law Bq.plr_hero_of:
  (@+p_0: Bq.Plr -> Game.Bq.Hero)

law Bq.wm_tick:
  (@+m_0: Bq.WMeta -> U32)

law Bq.fx:
  (@+z_0: U32 -> (@+kind_1: U32 -> (@+x_2: U32 -> (@+y_3: U32 -> Bq.OutL))))

law Bq.hero_wea_n:
  (@+h_0: Game.Bq.Hero -> Nat)

law Bq.hero_str_n:
  (@+h_0: Game.Bq.Hero -> Nat)

law Bq.plr_hit:
  (@+h_0: Game.Bq.Hero -> (@+mdf_1: U32 -> (@+crit_2: U32 -> U32)))

law Bq.take_mob:
  (@+mid_0: U32 -> (@+ms_1: List<&2, Bq.Mob> -> C.Bq.Pair.Pair(List<&2, Bq.Mob>, (__2 => Support.Bq.Maybe(Bq.Mob)))))

law Bq.mob_df_at:
  (@+ms_0: List<&2, Bq.Mob> -> (@+mid_1: U32 -> U32))

law Bq.mainq_for_boss:
  (@+kind_0: U32 -> U32)

law Bq.sigil_advance:
  (@+ps_0: List<&2, Bq.Plr> -> (@+stage_1: U32 -> List<&2, Bq.Plr>))

law Bq.advance_if_boss:
  (@+ps_0: List<&2, Bq.Plr> -> (@+kind_1: U32 -> List<&2, Bq.Plr>))

law Bq.sigil_bit:
  (@+kind_0: U32 -> U32)

law Bq.evlog:
  (@+text_0: C.Bq.String -> List<&1, Bq.OutL>)

law Bq.over_lines_go:
  (@+rank_0: U32 -> (@+rs_1: List<&1, C.Bq.Pair.Pair(U32, (__1 => C.Bq.String))> -> List<&1, Bq.OutL>))

law Bq.ins_desc:
  (@+x_0: C.Bq.Pair.Pair(U32, (__0 => C.Bq.String)) -> (@+xs_1: List<&1, C.Bq.Pair.Pair(U32, (__1 => C.Bq.String))> -> List<&1, C.Bq.Pair.Pair(U32, (__2 => C.Bq.String))>))

law Bq.ranked:
  (@+ps_0: List<&1, C.Bq.Pair.Pair(U32, (__0 => C.Bq.String))> -> List<&1, C.Bq.Pair.Pair(U32, (__1 => C.Bq.String))>)

law Bq.score_names:
  (@+ps_0: List<&2, Bq.Plr> -> List<&1, C.Bq.Pair.Pair(U32, (__1 => C.Bq.String))>)

law Bq.over_lines:
  (@+ps_0: List<&2, Bq.Plr> -> List<&1, Bq.OutL>)

law Bq.hero_add_gold:
  (@+h_0: Game.Bq.Hero -> (@+g_1: U32 -> Game.Bq.Hero))

law Bq.sideq_idx:
  (@+kind_0: U32 -> U32)

law Bq.drop_roll:
  (@+kind_0: U32 -> (@+tick_1: U32 -> (@+mid_2: U32 -> U32)))

law Bq.rare_drop_of:
  (@+zone_0: U32 -> U32)

law Bq.drop_pick:
  (@+kind_0: U32 -> (@+rare_1: U32 -> (@+mzone_2: U32 -> (@+tick_3: U32 -> (@+mid_4: U32 -> U32)))))

law Bq.boss_outs:
  (@+kind_0: U32 -> (@+rare_1: U32 -> (@+elapsed_2: U32 -> (@+name_3: C.Bq.String -> List<&1, Bq.OutL>))))

law Bq.boss_bonus_score:
  (@+kind_0: U32 -> (@+elapsed_1: U32 -> U32))

law Bq.up_outs:
  (@+ups_0: U32 -> (@+z_1: U32 -> (@+x_2: U32 -> (@+y_3: U32 -> (@+name_4: C.Bq.String -> List<&1, Bq.OutL>)))))

law Bq.find_bonus:
  (@+found_0: U32 -> (@+k_1: U32 -> U32))

law Bq.hero_add_item:
  (@+h_0: Game.Bq.Hero -> (@+k_1: U32 -> Game.Bq.Hero))

law Bq.found_bit:
  (@+k_0: U32 -> U32)

law Bq.maybe_drop:
  (@+h_0: Game.Bq.Hero -> (@+k_1: U32 -> (@+found_2: U32 -> C.Bq.Pair.Pair(Game.Bq.Hero, (__3 => C.Bq.Pair.Pair(U32, (__4 => C.Bq.Pair.Pair(U32, (__5 => List<&1, Bq.OutL>)))))))))

law Bq.sideq_reward:
  (@+h_0: Game.Bq.Hero -> (@+q_1: U32 -> Game.Bq.Hero))

law Bq.ev:
  (@+text_0: C.Bq.String -> Bq.OutL)

law Bq.apply_sideq:
  (@+p_hero_0: Game.Bq.Hero -> (@+q_1: U32 -> (@+cnt_2: U32 -> (@+done_3: U32 -> C.Bq.Pair.Pair(Game.Bq.Hero, (__4 => C.Bq.Pair.Pair(U32, (__5 => C.Bq.Pair.Pair(U32, (__6 => C.Bq.Pair.Pair(U32, (__7 => List<&1, Bq.OutL>))))))))))))

law Bq.apply_sideq_at:
  (@+h_0: Game.Bq.Hero -> (@+q_1: U32 -> (@+sq0_2: U32 -> (@+sq1_3: U32 -> (@+sq2_4: U32 -> (@+sqdone_5: U32 -> C.Bq.Pair.Pair(Game.Bq.Hero, (__6 => C.Bq.Pair.Pair(C.Bq.Pair.Pair(U32, (__7 => C.Bq.Pair.Pair(U32, (__8 => C.Bq.Pair.Pair(U32, (__9 => U32)))))), (__7 => C.Bq.Pair.Pair(U32, (__8 => C.Bq.Pair.Pair(U32, (__9 => List<&1, Bq.OutL>))))))))))))))

law Bq.hero_lv:
  (@+h_0: Game.Bq.Hero -> U32)

law Bq.gain_xp_go:
  (@+fuel_0: U32 -> (@+h_1: Game.Bq.Hero -> (@+xp_2: U32 -> (@+ups_3: U32 -> C.Bq.Pair.Pair(Game.Bq.Hero, (__4 => C.Bq.Pair.Pair(U32, (__5 => U32))))))))

law Bq.gain_xp:
  (@+h_0: Game.Bq.Hero -> (@+xp_1: U32 -> (@+gained_2: U32 -> C.Bq.Pair.Pair(Game.Bq.Hero, (__3 => C.Bq.Pair.Pair(U32, (__4 => U32)))))))

law Bq.kill_reward:
  (@+p_0: Bq.Plr -> (@+kind_1: U32 -> (@+rare_2: U32 -> (@+mzone_3: U32 -> (@+tick_4: U32 -> (@+elapsed_5: U32 -> (@+mid_6: U32 -> C.Bq.Pair.Pair(Bq.Plr, (__7 => List<&1, Bq.OutL>)))))))))

law Bq.on_mob_kill:
  (@+w_0: Bq.World -> (@+pid_1: U32 -> (@+kind_2: U32 -> (@+rare_3: U32 -> (@+mzone_4: U32 -> (@+mid_5: U32 -> C.Bq.Pair.Pair(Bq.World, (__6 => List<&1, Bq.OutL>))))))))

law Bq.after_strike:
  (@+w_0: Bq.World -> (@+pid_1: U32 -> (@+z_2: U32 -> (@+kr_3: Support.Bq.Maybe(C.Bq.Pair.Pair(U32, (__3 => C.Bq.Pair.Pair(U32, (__4 => C.Bq.Pair.Pair(U32, (__5 => U32))))))) -> C.Bq.Pair.Pair(Bq.World, (__4 => List<&1, Bq.OutL>))))))

law Bq.respawn_of:
  (@+kind_0: U32 -> U32)

law Bq.strike_mob:
  (@+ms_0: List<&2, Bq.Mob> -> (@+mid_1: U32 -> (@+dmg_2: U32 -> C.Bq.Pair.Pair(List<&2, Bq.Mob>, (__3 => C.Bq.Pair.Pair(Support.Bq.Maybe(C.Bq.Pair.Pair(U32, (__4 => C.Bq.Pair.Pair(U32, (__5 => C.Bq.Pair.Pair(U32, (__6 => U32))))))), (__4 => U32)))))))

law Bq.spin_strikes:
  (@+w_0: Bq.World -> (@+pid_1: U32 -> (@+mids_2: List<&1, U32> -> (@+hero_snapshot_3: Game.Bq.Hero -> (@+tick_4: U32 -> C.Bq.Pair.Pair(Bq.World, (__5 => List<&1, Bq.OutL>)))))))

law Bq.cmd_spin:
  (@+w_0: Bq.World -> (@+pid_1: U32 -> C.Bq.Pair.Pair(Bq.World, (__2 => List<&1, Bq.OutL>))))

law Bq.mob_in_reach:
  (@+ms_0: List<&2, Bq.Mob> -> (@+z_1: U32 -> (@+x_2: U32 -> (@+y_3: U32 -> U32))))

law Bq.hero_crit:
  (@+h_0: Game.Bq.Hero -> U32)

law Bq.atk_fx:
  (@+z_0: U32 -> (@+x_1: U32 -> (@+y_2: U32 -> (@+dir_3: U32 -> (@+mid_4: U32 -> (@+crit_5: U32 -> List<&1, Bq.OutL>))))))

law Bq.cmd_atk:
  (@+w_0: Bq.World -> (@+pid_1: U32 -> C.Bq.Pair.Pair(Bq.World, (__2 => List<&1, Bq.OutL>))))

law Bq.pos_halt:
  (@+p_0: Bq.Pos -> Bq.Pos)

law Bq.cmd_halt:
  (@+w_0: Bq.World -> (@+pid_1: U32 -> C.Bq.Pair.Pair(Bq.World, (__2 => List<&1, Bq.OutL>))))

law Bq.cmd_move:
  (@+w_0: Bq.World -> (@+pid_1: U32 -> (@+d_2: U32 -> C.Bq.Pair.Pair(Bq.World, (__3 => List<&1, Bq.OutL>)))))

law Bq.pm_name:
  (@+m_0: Bq.PMeta -> C.Bq.String)

law Bq.mk_plr:
  (@+pid_0: U32 -> (@+cid_1: U32 -> (@+skin_2: U32 -> (@+hairs_3: U32 -> (@+hairc_4: U32 -> (@+shirt_5: U32 -> (@+hat_6: U32 -> (@+cape_7: U32 -> (@+name_8: C.Bq.String -> Bq.Plr)))))))))

law Bq.add_plr:
  (@+w_0: Bq.World -> (@+cid_1: U32 -> (@+skin_2: U32 -> (@+hairs_3: U32 -> (@+hairc_4: U32 -> (@+shirt_5: U32 -> (@+hat_6: U32 -> (@+cape_7: U32 -> (@+name_8: C.Bq.String -> C.Bq.Pair.Pair(Bq.World, (__9 => U32)))))))))))

law Bq.wm_wno:
  (@+m_0: Bq.WMeta -> U32)

law Bq.del_plr:
  (@+w_0: Bq.World -> (@+pid_1: U32 -> Bq.World))

law Bq.gen_tile:
  (@+z_0: U32 -> (@+seed_1: U32 -> (@+i_2: U32 -> U32)))

law Bq.gen_tree:
  (@+z_0: U32 -> (@+seed_1: U32 -> (@+d_2: U32 -> (@+i_3: U32 -> List<&1, U32>))))

law Bq.floor_of:
  (@+z_0: U32 -> U32)

law Bq.lset:
  (@+xs_0: List<&1, U32> -> (@+i_1: U32 -> (@+v_2: U32 -> List<&1, U32>)))

law Bq.stamp_row:
  (@+m_0: List<&1, U32> -> (@+x_1: U32 -> (@+n_2: U32 -> (@+y_3: U32 -> (@+t_4: U32 -> List<&1, U32>)))))

law Bq.stamp_col:
  (@+m_0: List<&1, U32> -> (@+x_1: U32 -> (@+y_2: U32 -> (@+n_3: U32 -> (@+t_4: U32 -> List<&1, U32>)))))

law Bq.stamp_box:
  (@+m_0: List<&1, U32> -> (@+x0_1: U32 -> (@+y0_2: U32 -> (@+w_3: U32 -> (@+h_4: U32 -> (@+t_5: U32 -> List<&1, U32>))))))

law Bq.portal_tile:
  (@+z_0: U32 -> U32)

law Bq.back_portal:
  (@+m_0: List<&1, U32> -> (@+z_1: U32 -> List<&1, U32>))

law Bq.village:
  (@+m_0: List<&1, U32> -> (@+z_1: U32 -> List<&1, U32>))

law Bq.gen_zone:
  (@+z_0: U32 -> (@+seed_1: U32 -> List<&1, U32>))

law Bq.gen_maps:
  (@+seed_0: U32 -> List<&2,List<&2,U32>>)

law Bq.zone_kinds:
  (@+z_0: U32 -> (@+salt_1: U32 -> U32))

law Bq.tile_at:
  (@+maps_0: List<&2,List<&2,U32>> -> (@+z_1: U32 -> (@+x_2: U32 -> (@+y_3: U32 -> U32))))

law Bq.walk_ok:
  (@+maps_0: List<&2,List<&2,U32>> -> (@+z_1: U32 -> (@+x_2: U32 -> (@+y_3: U32 -> U32))))

law Bq.in_village:
  (@+z_0: U32 -> (@+x_1: U32 -> (@+y_2: U32 -> U32)))

law Bq.spawn_spot:
  (@+maps_0: List<&2,List<&2,U32>> -> (@+z_1: U32 -> (@+salt_2: U32 -> C.Bq.Pair.Pair(U32, (__3 => U32)))))

law Bq.mk_mob:
  (@+maps_0: List<&2,List<&2,U32>> -> (@+mid_1: U32 -> (@+z_2: U32 -> (@+salt_3: U32 -> (@+rare_4: U32 -> Bq.Mob)))))

law Bq.populate_zone:
  (@+maps_0: List<&2,List<&2,U32>> -> (@+z_1: U32 -> (@+n_2: U32 -> (@+mid0_3: U32 -> List<&2, Bq.Mob>))))

law Bq.pick_boss_x:
  (@+z_0: U32 -> U32)

law Bq.pick_boss_y:
  (@+z_0: U32 -> U32)

law Bq.mk_boss:
  (@+mid_0: U32 -> (@+z_1: U32 -> Bq.Mob))

law Bq.initial_mobs:
  (@+maps_0: List<&2,List<&2,U32>> -> List<&2, Bq.Mob>)

law Bq.fresh_world:
  (@+wno_0: U32 -> (@+seed_1: U32 -> (@+now_2: U32 -> Bq.World)))

law Bq.snap_mobs:
  (@+ms_0: List<&2, Bq.Mob> -> (@+z_1: U32 -> C.Bq.Pair.Pair(U32, (__2 => List<&1, U32>))))

law Bq.snap_plrs:
  (@+ps_0: List<&2, Bq.Plr> -> (@+z_1: U32 -> C.Bq.Pair.Pair(U32, (__2 => List<&1, U32>))))

law Bq.snap_line:
  (@+plrs_0: List<&2, Bq.Plr> -> (@+mobs_1: List<&2, Bq.Mob> -> (@+tick_2: U32 -> (@+z_3: U32 -> C.Bq.String))))

law Bq.hero_pts_of:
  (@+h_0: Game.Bq.Hero -> Nat)

law Bq.hero_str_u:
  (@+h_0: Game.Bq.Hero -> U32)

law Bq.hero_agi_u:
  (@+h_0: Game.Bq.Hero -> U32)

law Bq.hero_vit_u:
  (@+h_0: Game.Bq.Hero -> U32)

law Bq.hero_wea_of:
  (@+h_0: Game.Bq.Hero -> Game.Bq.Maybe(Nat))

law Bq.hero_arm_of:
  (@+h_0: Game.Bq.Hero -> Game.Bq.Maybe(Nat))

law Bq.hero_hel_of:
  (@+h_0: Game.Bq.Hero -> Game.Bq.Maybe(Nat))

law Bq.hero_chm_of:
  (@+h_0: Game.Bq.Hero -> Game.Bq.Maybe(Nat))

law Bq.watk_of:
  (@+m_0: Game.Bq.Maybe(Nat) -> U32)

law Bq.hero_watk:
  (@+h_0: Game.Bq.Hero -> U32)

law Bq.df_of:
  (@+m_0: Game.Bq.Maybe(Nat) -> U32)

law Bq.hero_df:
  (@+h_0: Game.Bq.Hero -> U32)

law Bq.bag_counts:
  (@+b_0: Game.Bq.Bag -> (@+k_1: U32 -> List<&1, U32>))

law Bq.hero_inv_counts:
  (@+h_0: Game.Bq.Hero -> List<&1, U32>)

law Bq.me_line:
  (@+p_0: Bq.Plr -> (@+sigils_1: U32 -> (@+phase_2: U32 -> Bq.OutL)))

law Bq.me_lines:
  (@+ps_0: List<&2, Bq.Plr> -> (@+sigils_1: U32 -> (@+phase_2: U32 -> List<&1, Bq.OutL>)))

law Bq.snap_outs:
  (@+plrs_0: List<&2, Bq.Plr> -> (@+mobs_1: List<&2, Bq.Mob> -> (@+tick_2: U32 -> (@+sigils_3: U32 -> (@+phase_4: U32 -> List<&1, Bq.OutL>)))))

law Bq.mob_hit:
  (@+matk_0: U32 -> (@+h_1: Game.Bq.Hero -> U32))

law Bq.apply_hits:
  (@+plrs_0: List<&2, Bq.Plr> -> (@+hits_1: List<&1, C.Bq.Pair.Pair(U32, (__1 => U32))> -> C.Bq.Pair.Pair(List<&2, Bq.Plr>, (__2 => List<&1, Bq.OutL>))))

law Bq.maw_upkeep:
  (@+kind_0: U32 -> (@+hp_1: U32 -> (@+mhp_2: U32 -> U32)))

law Bq.tgt_pos:
  (@+ts_0: List<&1, C.Bq.Pair.Pair(U32, (__0 => C.Bq.Pair.Pair(U32, (__1 => U32))))> -> (@+pid_1: U32 -> Support.Bq.Maybe(C.Bq.Pair.Pair(U32, (__2 => U32)))))

law Bq.nearest_tgt:
  (@+ts_0: List<&1, C.Bq.Pair.Pair(U32, (__0 => C.Bq.Pair.Pair(U32, (__1 => U32))))> -> (@+x_1: U32 -> (@+y_2: U32 -> (@+best_3: U32 -> (@+bestd_4: U32 -> C.Bq.Pair.Pair(U32, (__5 => U32)))))))

law Bq.tgt_acquire:
  (@+ts_0: List<&1, C.Bq.Pair.Pair(U32, (__0 => C.Bq.Pair.Pair(U32, (__1 => U32))))> -> (@+x_1: U32 -> (@+y_2: U32 -> C.Bq.Pair.Pair(U32, (__3 => C.Bq.Pair.Pair(U32, (__4 => C.Bq.Pair.Pair(U32, (__5 => U32)))))))))

law Bq.tgt_keep:
  (@+ts_0: List<&1, C.Bq.Pair.Pair(U32, (__0 => C.Bq.Pair.Pair(U32, (__1 => U32))))> -> (@+tgt_1: U32 -> (@+x_2: U32 -> (@+y_3: U32 -> C.Bq.Pair.Pair(U32, (__4 => C.Bq.Pair.Pair(U32, (__5 => C.Bq.Pair.Pair(U32, (__6 => U32))))))))))

law Bq.walk_dir:
  (@+d_0: U32 -> Game.Bq.Dir)

law Bq.move_plr_xy:
  (@+maps_0: List<&2,List<&2,U32>> -> (@+z_1: U32 -> (@+x_2: U32 -> (@+y_3: U32 -> (@+d_4: U32 -> C.Bq.Pair.Pair(U32, (__5 => U32)))))))

law Bq.mob_move_xy:
  (@+maps_0: List<&2,List<&2,U32>> -> (@+z_1: U32 -> (@+x_2: U32 -> (@+y_3: U32 -> (@+d_4: U32 -> C.Bq.Pair.Pair(U32, (__5 => U32)))))))

law Bq.step_toward:
  (@+maps_0: List<&2,List<&2,U32>> -> (@+z_1: U32 -> (@+x_2: U32 -> (@+y_3: U32 -> (@+tx_4: U32 -> (@+ty_5: U32 -> C.Bq.Pair.Pair(U32, (__6 => U32))))))))

law Bq.mob_atk_now:
  (@+kind_0: U32 -> (@+hp_1: U32 -> (@+mhp_2: U32 -> U32)))

law Bq.ai_mob:
  (@+m_0: Bq.Mob -> (@+ts_1: List<&1, C.Bq.Pair.Pair(U32, (__1 => C.Bq.Pair.Pair(U32, (__2 => U32))))> -> (@+maps_2: List<&2,List<&2,U32>> -> (@+tick_3: U32 -> C.Bq.Pair.Pair(Bq.Mob, (__4 => Support.Bq.Maybe(C.Bq.Pair.Pair(U32, (__5 => U32)))))))))

law Bq.ai_zone:
  (@+ms_0: List<&2, Bq.Mob> -> (@+ts_1: List<&1, C.Bq.Pair.Pair(U32, (__1 => C.Bq.Pair.Pair(U32, (__2 => U32))))> -> (@+maps_2: List<&2,List<&2,U32>> -> (@+tick_3: U32 -> C.Bq.Pair.Pair(List<&2, Bq.Mob>, (__4 => List<&1, C.Bq.Pair.Pair(U32, (__5 => U32))>))))))

law Bq.mobs_of_zone:
  (@+ms_0: List<&2, Bq.Mob> -> (@+z_1: U32 -> List<&2, Bq.Mob>))

law Bq.plr_targets:
  (@+ps_0: List<&2, Bq.Plr> -> (@+z_1: U32 -> List<&1, C.Bq.Pair.Pair(U32, (__2 => C.Bq.Pair.Pair(U32, (__3 => U32))))>))

law Bq.tick_mobs:
  (@+mobs_0: List<&2, Bq.Mob> -> (@+plrs_1: List<&2, Bq.Plr> -> (@+maps_2: List<&2,List<&2,U32>> -> (@+tick_3: U32 -> C.Bq.Pair.Pair(List<&2, Bq.Mob>, (__4 => List<&1, C.Bq.Pair.Pair(U32, (__5 => U32))>))))))

law Bq.walk_if:
  (@+maps_0: List<&2,List<&2,U32>> -> (@+z_1: U32 -> (@+x_2: U32 -> (@+y_3: U32 -> (@+d_4: U32 -> (@+moving_5: U32 -> C.Bq.Pair.Pair(U32, (__6 => U32))))))))

law Bq.upkeep_plr:
  (@+p_0: Bq.Plr -> (@+maps_1: List<&2,List<&2,U32>> -> (@+tick_2: U32 -> C.Bq.Pair.Pair(Bq.Plr, (__3 => List<&1, Bq.OutL>)))))

law Bq.upkeep_all:
  (@+ps_0: List<&2, Bq.Plr> -> (@+maps_1: List<&2,List<&2,U32>> -> (@+tick_2: U32 -> C.Bq.Pair.Pair(List<&2, Bq.Plr>, (__3 => List<&1, Bq.OutL>)))))

law Bq.tick_world:
  (@+w_0: Bq.World -> C.Bq.Pair.Pair(Bq.World, (__1 => List<&1, Bq.OutL>)))

@unsafe
def Bq.hash2(a,b):
  Landscape.Landscape.hash(a,b)

@unsafe
def Bq.lget():
  \{Nil: (i_0 => (d_1 => d_1)); \{Con: (h_0 => (t_1 => (word => C.Bq.word_case((@+d_2: U32 -> U32), word, 0, (unit => (d_2 => h_0)), (j_2 => (d_3 => Bq.lget(t_1, j_2, d_3))), 1)))); \{}}}

@unsafe
def Bq.wm_phase():
  \{S.Simulation.Meta: (phase_0 => (wno_1 => (seed_2 => (tick_3 => (t0_4 => (now_5 => (sigils_6 => (fame_t_7 => (nextpid_8 => (nextmid_9 => phase_0)))))))))); \{}}

@unsafe
def Bq.pos_zone():
  \{P.Players.Pos: (zone_0 => (x_1 => (y_2 => (dir_3 => (moving_4 => zone_0))))); \{}}

@unsafe
def Bq.put_plr():
  (wm_0 => (p_1 => (others_2 => (mobs_3 => (maps_4 => (+ps_5 = {Con{p_1, others_2} : List<&2, Bq.Plr>}; Terrain.Terrain.World{wm_0, ps_5, mobs_3, maps_4}))))))

@unsafe
def Bq.tile_hex():
  (t_0 => (+apply_63 = {(t_0 => (word => C.Bq.word_case(Char, word, 0, (unit => Chr{(97 + (t_0 - 10 : U32) : U32)}), (_616_1 => Chr{(48 + t_0 : U32)}), 0))) : (@+t_0: U32 -> (@+___1: U32 -> Char))}; apply_63(t_0, C.Bq.bit(U32.is_lt(t_0, 10)))))

@unsafe
def Bq.map_hex():
  \{Nil: Nil{}; \{Con: (t_0 => (rest_1 => Con{Bq.tile_hex(t_0), Bq.map_hex(rest_1)})); \{}}}

@unsafe
def Bq.map_of(maps,z): Terrain.Terrain.map_of(maps,z)

@unsafe
def Bq.zone_line():
  (maps_0 => (z_1 => Proto.Bq.wire_enc(C.Bq.text("ZONE"), [z_1, Data.Bq.ZONE_W, Data.Bq.ZONE_H], Bq.map_hex(Bq.map_of(maps_0, z_1)))))

def Bq.wm_sigils(meta): LC.LiveCommands.sigils(meta)

@unsafe
def Bq.player_taken(taken: P.Players.Take) -> C.Bq.Pair.Pair(List<&2, Bq.Plr>, (ps => Support.Bq.Maybe(Bq.Plr))):
  match taken:
    case P.Players.Take{others, found}:
      match found:
        case None{}:
          Tuple{others, Fail{Unit{}}}
        case Some{player}:
          Tuple{others, Done{player}}

@unsafe
def Bq.take_plr(pid, players):
  Bq.player_taken(P.Players.take(players, pid))

@unsafe
def Bq.elder_line():
  (mainq_0 => (sigils_1 => (+apply_77 = {(mainq_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => (+apply_78 = {(mainq_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => (+apply_79 = {(word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => C.Bq.text("Elder Fern: 'The meadow remembers you kindly, hero.'")), (_1243_0 => C.Bq.text("Elder Fern: 'The Rift is open. Go -- and go TOGETHER. No one seals it alone.'")), 0)) : (@+___0: U32 -> List<&1, Char>)}; apply_79(C.Bq.bit(U32.is_eq(mainq_0, 5))))), (_1245_1 => C.Bq.text("Elder Fern: 'Three sigils open the Rift. The wardens hold them.'")), 0))) : (@+mainq_0: U32 -> (@+___1: U32 -> List<&1, Char>))}; apply_78(mainq_0, C.Bq.word_and(C.Bq.bit(U32.is_ge(mainq_0, 2)), C.Bq.bit(U32.is_le(mainq_0, 4)))))), (_1247_1 => C.Bq.text("Elder Fern: 'The slimes overrun the meadow. Cull them!'")), 0))) : (@+mainq_0: U32 -> (@+___1: U32 -> List<&1, Char>))}; apply_77(mainq_0, C.Bq.bit(U32.is_eq(mainq_0, 1))))))

@unsafe
def Bq.interaction_reply(+reply: Maybe<&2,Interact.Interaction.Reply>, +maps: List<&2,List<&2,U32>>, sigils: U32) -> List<&1,Bq.OutL>:
  match reply:
    case None{}: Nil{}
    case Some{message}:
      match message:
        case Interact.Interaction.Reply{cid,event}:
          match event:
            case Interact.Interaction.Quiet{}: Nil{}
            case Interact.Interaction.ElderStart{}:
              [Bq.OutL.To{cid,Proto.Bq.wire_enc(C.Bq.text("EV"),Nil{},C.Bq.text("Elder Fern: 'The Rift gnaws at our world. Prove yourself: cull 8 slimes.'"))}]
            case Interact.Interaction.Elder{main}:
              [Bq.OutL.To{cid,Proto.Bq.wire_enc(C.Bq.text("EV"),Nil{},Bq.elder_line(main,sigils))}]
            case Interact.Interaction.Shop{}:
              [Bq.OutL.To{cid,Proto.Bq.wire_enc(C.Bq.text("EV"),Nil{},C.Bq.text("Keeper Bramble: 'Potions, blades, plate -- press B on my mat to browse!'"))}]
            case Interact.Interaction.Sealed{}:
              [Bq.OutL.To{cid,Proto.Bq.wire_enc(C.Bq.text("EV"),Nil{},C.Bq.text("The Rift gate is SEALED. Three sigils are needed."))}]
            case Interact.Interaction.Entered{zone}:
              +destination = zone
              [Bq.OutL.To{cid,Bq.zone_line(maps,destination)},Bq.OutL.To{cid,Proto.Bq.wire_enc(C.Bq.text("EV"),Nil{},Support.Bq.List.concat(Char,C.Bq.text("You enter "),Data.Bq.zone_name(destination)))}]
            case Interact.Interaction.Returned{zone}:
              +destination = zone
              [Bq.OutL.To{cid,Bq.zone_line(maps,destination)},Bq.OutL.To{cid,Proto.Bq.wire_enc(C.Bq.text("EV"),Nil{},Support.Bq.List.concat(Char,C.Bq.text("You return to "),Data.Bq.zone_name(destination)))}]

@unsafe
def Bq.too_far_out():
  (cid_0 => (fb_1 => (+apply_121 = {(cid_0 => (word => C.Bq.word_case(List<&1, Bq.OutL>, word, 0, (unit => Nil{}), (_1177_1 => [Bq.OutL.To{cid_0, Proto.Bq.wire_enc(C.Bq.text("EV"), Nil{}, C.Bq.text("Keeper Bramble: 'Step onto my mat first, friend!'"))}]), 0))) : (@+cid_0: U32 -> (@+___1: U32 -> List<&1, Bq.OutL>))}; apply_121(cid_0, C.Bq.bit(U32.is_eq(fb_1, 1))))))

@unsafe
def Bq.inventory_reply(reply: Maybe<&2, I.Inventory.Reply>) -> List<&1, Bq.OutL>:
  match reply:
    case None{}: Nil{}
    case Some{value}:
      match value:
        case I.Inventory.Reply{cid, notice}:
          match notice:
            case I.Inventory.Quiet{}: Nil{}
            case I.Inventory.TooFar{}: Bq.too_far_out(cid, 1)
            case I.Inventory.NoGold{}:
              [Bq.OutL.To{cid, Proto.Bq.wire_enc(C.Bq.text("EV"), Nil{}, C.Bq.text("Keeper Bramble: 'Not enough gold for that one.'"))}]

@unsafe
def Bq.render_live_command(result):
  match result:
    case LC.LiveCommands.Result{world,notice}:
      match world:
        case Terrain.Terrain.World{meta,players,monsters,maps}:
          match notice:
            case LC.LiveCommands.Inventory{reply}: Bq.inventory_reply(reply)
            case LC.LiveCommands.Interaction{reply}: Bq.interaction_reply(reply,maps,LC.LiveCommands.sigils(meta))


@unsafe
def Bq.interaction_result(wm: Bq.WMeta,mobs: List<&2,Bq.Mob>,maps: Terrain.Terrain.Maps,result: Interact.Interaction.Result) -> Bq.World & List<&1,Bq.OutL>:
  LC.LiveCommands.emit(Bq.OutL,LC.LiveCommands.interaction_result(wm,mobs,maps,result),Bq.render_live_command)

@unsafe
def Bq.interaction_command(world: Bq.World,pid: U32,command: Interact.Interaction.Command) -> Bq.World & List<&1,Bq.OutL>:
  LC.LiveCommands.emit(Bq.OutL,LC.LiveCommands.run(LC.LiveCommands.Act{pid,command},world),Bq.render_live_command)

@unsafe
def Bq.cmd_enter(world,pid): LC.LiveCommands.emit(Bq.OutL,LC.LiveCommands.run(LC.LiveCommands.Enter{pid},world),Bq.render_live_command)

def Bq.chdist(ax,ay,bx,by): Targets.Targets.distance(ax,ay,bx,by)

@unsafe
def Bq.near_shop(zone,x,y):
  C.Bq.bit(Interact.Interaction.near(P.Players.Pos{zone,x,y,0,0},Interact.Interaction.shop_x,Interact.Interaction.shop_y))


@unsafe
def Bq.near_elder(zone,x,y):
  C.Bq.bit(Interact.Interaction.near(P.Players.Pos{zone,x,y,0,0},Interact.Interaction.elder_x,Interact.Interaction.elder_y))

@unsafe
def Bq.cmd_talk(world,pid,npc):
  Bq.interaction_command(world,pid,Interact.Interaction.Talk{npc})

@unsafe
def Bq.hero_gold_u():
  (h_0 => Support.Bq.Nat.to_u32(Game.Bq.hero_gold(h_0)))

@unsafe
def Bq.slot_kind():
  \{Done: (k_0 => (Support.Bq.Nat.to_u32(k_0) + 1 : U32)); \{Fail: (u_0 => 0); \{}}}

@unsafe
def Bq.hero_maxhp(h):
  Rewards.Rewards.maximum(h, 4294967295)

@unsafe
def Bq.bag_count():
  \{Nil: (k_0 => 0); \{Con: (n_0 => (rest_1 => (word => C.Bq.word_case(U32, word, 0, (unit => Support.Bq.Nat.to_u32(n_0)), (kp_2 => Bq.bag_count(rest_1, kp_2)), 1)))); \{}}}

@unsafe
def Bq.hero_pots():
  \{Game.Bq.Hero.Hero: (inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => Bq.bag_count(inv_0, 0)))))))))))); \{}}



# The map predicate supplies a shop-proximity fact; inventory.bend owns the
# actual lookup result, hero/vital transition, and complete roster rebuild.
def Bq.inventory_near(found: Maybe<&2,P.Players.State>) -> Bool: LC.LiveCommands.near(found)



@unsafe
def Bq.inventory_result(wm: Bq.WMeta,mobs: List<&2,Bq.Mob>,maps: Terrain.Terrain.Maps,result: I.Inventory.Result) -> Bq.World & List<&1,Bq.OutL>:
  LC.LiveCommands.emit(Bq.OutL,LC.LiveCommands.inventory_result(wm,mobs,maps,result),Bq.render_live_command)

@unsafe
def Bq.cmd_hop(world: Bq.World,pid: U32,op: Game.Bq.HOp) -> Bq.World & List<&1,Bq.OutL>:
  LC.LiveCommands.emit(Bq.OutL,LC.LiveCommands.run(LC.LiveCommands.Hero{pid,op,Data.Bq.POTION_HEAL},world),Bq.render_live_command)

@unsafe
def Bq.cmd_buy():
  (w_0 => (pid_1 => (k_2 => Bq.cmd_hop(w_0, pid_1, Game.Bq.HOp.Buy{Support.Bq.Nat.from_u32(Support.Bq.U32.min(k_2, 17))}))))

@unsafe
def Bq.cmd_alloc():
  (w_0 => (pid_1 => (s_2 => Bq.cmd_hop(w_0, pid_1, Game.Bq.HOp.Alloc{Support.Bq.Nat.from_u32(Support.Bq.U32.min(s_2, 2))}))))

@unsafe
def Bq.wire_slot():
  (s_0 => (+apply_127 = {(s_0 => (word => C.Bq.word_case(Game.Bq.ISlot, word, 0, (unit => (+apply_128 = {(s_0 => (word => C.Bq.word_case(Game.Bq.ISlot, word, 0, (unit => (+apply_129 = {(word => C.Bq.word_case(Game.Bq.ISlot, word, 0, (unit => Game.Bq.ISlot.SlotC{}), (_1153_0 => Game.Bq.ISlot.SlotH{}), 0)) : (@+___0: U32 -> Game.Bq.ISlot)}; apply_129(C.Bq.bit(U32.is_eq(s_0, 2))))), (_1155_1 => Game.Bq.ISlot.SlotA{}), 0))) : (@+s_0: U32 -> (@+___1: U32 -> Game.Bq.ISlot))}; apply_128(s_0, C.Bq.bit(U32.is_eq(s_0, 1))))), (_1157_1 => Game.Bq.ISlot.SlotW{}), 0))) : (@+s_0: U32 -> (@+___1: U32 -> Game.Bq.ISlot))}; apply_127(s_0, C.Bq.bit(U32.is_eq(s_0, 0)))))

@unsafe
def Bq.cmd_uneq():
  (w_0 => (pid_1 => (s_2 => Bq.cmd_hop(w_0, pid_1, Game.Bq.HOp.Unequip{Bq.wire_slot(s_2)}))))

@unsafe
def Bq.cmd_equip():
  (w_0 => (pid_1 => (k_2 => Bq.cmd_hop(w_0, pid_1, Game.Bq.HOp.Equip{Support.Bq.Nat.from_u32(Support.Bq.U32.min(k_2, 17))}))))

@unsafe
def Bq.cmd_quaff():
  (w_0 => (pid_1 => Bq.cmd_hop(w_0, pid_1, Game.Bq.HOp.Quaff{})))

def Bq.mids_in_reach(monsters,zone,x,y): Targets.Targets.all_ids(monsters,Targets.Targets.Point{zone,x,y})

@unsafe
def Bq.plr_hero_of():
  \{P.Players.State: (pid_0 => (cid_1 => (hero_2 => (pos_3 => (vit_4 => (style_5 => (qst_6 => (meta_7 => hero_2)))))))); \{}}

@unsafe
def Bq.wm_tick():
  \{S.Simulation.Meta: (phase_0 => (wno_1 => (seed_2 => (tick_3 => (t0_4 => (now_5 => (sigils_6 => (fame_t_7 => (nextpid_8 => (nextmid_9 => tick_3)))))))))); \{}}

@unsafe
def Bq.fx():
  (z_0 => (kind_1 => (x_2 => (y_3 => Bq.OutL.ZoneL{z_0, Proto.Bq.wire_enc(C.Bq.text("FX"), [kind_1, x_2, y_3], Nil{})}))))

@unsafe
def Bq.hero_wea_n():
  \{Game.Bq.Hero.Hero: (inv_0 => \{Done: (k_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => Game.Bq.iatk(k_1))))))))))); \{Fail: (u_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => 1n)))))))))); \{}}}); \{}}

@unsafe
def Bq.hero_str_n():
  \{Game.Bq.Hero.Hero: (inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => str_7))))))))))); \{}}

@unsafe
def Bq.plr_hit():
  (h_0 => (mdf_1 => (crit_2 => (+d_3 = Game.Bq.damage(Bq.hero_wea_n(h_0), Bq.hero_str_n(h_0), Support.Bq.Nat.from_u32(mdf_1), Support.Bq.Bool.from_u32(crit_2)); Support.Bq.Nat.to_u32(d_3)))))

@unsafe
def Bq.take_mob_result(result: R.Roster.Take) -> C.Bq.Pair.Pair(List<&2, Bq.Mob>, (ms => Support.Bq.Maybe(Bq.Mob))):
  match result:
    case R.Roster.Take{others, found}:
      match found:
        case None{}:
          Tuple{others, Fail{Unit{}}}
        case Some{monster}:
          Tuple{others, Done{monster}}

@unsafe
def Bq.take_mob(mid, ms):
  Bq.take_mob_result(R.Roster.take(ms, mid))

@unsafe
def Bq.mob_df_at():
  (ms_0 => (mid_1 => (+apply_143 = {\{Tuple: (fst_0 => (snd_1 => (+apply_144 = {\{Fail: (error_0 => 0); \{Done: (value_0 => (+apply_145 = {\{M.Monsters.State: (mid_0 => (kind_1 => (rare_2 => (zone_3 => (x_4 => (y_5 => (hp_6 => (mhp_7 => (tgt_8 => (atkcd_9 => (dead_10 => (resp_11 => Data.Bq.mob_df(kind_1))))))))))))); \{}} : (@+___0: Bq.Mob -> U32)}; apply_145(value_0))); \{}}} : (@+___0: Result<&1, &1, Unit, Bq.Mob> -> U32)}; apply_144(snd_1)))); \{}} : (@+___0: Sigma<&1, &1, List<&2, Bq.Mob>, (__0 => Result<&1, &1, Unit, Bq.Mob>)> -> U32)}; apply_143(Bq.take_mob(mid_1, ms_0)))))

@unsafe
def Bq.mainq_for_boss():
  (kind_0 => (+apply_146 = {(kind_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_147 = {(kind_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_148 = {(word => C.Bq.word_case(U32, word, 0, (unit => 9), (_680_0 => 4), 0)) : (@+___0: U32 -> U32)}; apply_148(C.Bq.bit(U32.is_eq(kind_0, 8))))), (_682_1 => 3), 0))) : (@+kind_0: U32 -> (@+___1: U32 -> U32))}; apply_147(kind_0, C.Bq.bit(U32.is_eq(kind_0, 7))))), (_684_1 => 2), 0))) : (@+kind_0: U32 -> (@+___1: U32 -> U32))}; apply_146(kind_0, C.Bq.bit(U32.is_eq(kind_0, 6)))))

@unsafe
def Bq.sigil_advance(players,stage):
  Pay.Payout.sigil_all(players,stage,Data.Bq.MQ_SCORE_SIGIL)

@unsafe
def Bq.advance_if_boss(players,kind):
  Pay.Payout.advance(players,kind,Data.Bq.MQ_SCORE_SIGIL)

@unsafe
def Bq.sigil_bit(kind): Battle.Battle.sigil(kind)

@unsafe
def Bq.evlog():
  (text_0 => [Bq.OutL.All{Proto.Bq.wire_enc(C.Bq.text("EV"), Nil{}, text_0)}, Bq.OutL.Log{text_0}])

@unsafe
def Bq.over_lines_go():
  (rank_0 => \{Nil: Nil{}; \{Con: \{Tuple: (sc_1 => (nm_2 => (rest_3 => Con{Bq.OutL.All{Proto.Bq.wire_enc(C.Bq.text("OVER"), [rank_0, sc_1, Data.Bq.rank_coins(rank_0)], nm_2)}, Bq.over_lines_go((rank_0 + 1 : U32), rest_3)}))); \{}}; \{}}})

@unsafe
def Bq.ins_desc():
  (x_0 => \{Nil: [x_0]; \{Con: (field_157 => field_158 => (+apply_159 = {\{Tuple: (fst_0 => (snd_1 => \{Tuple: (ys2_2 => (yn_3 => (rest_4 => (+apply_160 = {(ys2_0 => (yn_1 => (fst_2 => (snd_3 => (rest_4 => (word => C.Bq.word_case(List<&1, Sigma<&1, &1, U32, (__6 => List<&1, Char>)>>, word, 0, (unit => Con{Tuple{ys2_0, yn_1}, Bq.ins_desc(Tuple{fst_2, snd_3}, rest_4)}), (_718_5 => Con{Tuple{fst_2, snd_3}, Con{Tuple{ys2_0, yn_1}, rest_4}}), 0))))))) : (@+ys2_0: U32 -> (@+yn_1: (__1 => C.Bq.String)(ys2_0) -> (@+fst_2: U32 -> (@+snd_3: (__3 => C.Bq.String)(fst_2) -> (@+rest_4: List<&1, C.Bq.Pair.Pair(U32, (__4 => C.Bq.String))> -> (@+___5: U32 -> List<&1, Sigma<&1, &1, U32, (__6 => List<&1, Char>)>>))))))}; apply_160(ys2_2, yn_3, fst_0, snd_1, rest_4, C.Bq.bit(U32.is_ge(fst_0, ys2_2))))))); \{}})); \{}} : (@+___0: Sigma<&1, &1, U32, (__0 => List<&1, Char>)> -> (@+__1: Sigma<&1, &1, U32, (__1 => List<&1, Char>)> -> (@+__2: List<&1, Sigma<&1, &1, U32, (__2 => List<&1, Char>)>> -> List<&1, Sigma<&1, &1, U32, (__3 => List<&1, Char>)>>)))}; apply_159(x_0, field_157, field_158))); \{}}})

@unsafe
def Bq.ranked():
  \{Nil: Nil{}; \{Con: (p_0 => (rest_1 => Bq.ins_desc(p_0, Bq.ranked(rest_1)))); \{}}}

@unsafe
def Bq.score_names():
  \{Nil: Nil{}; \{Con: \{P.Players.State: (pid_0 => (cid_1 => (hero_2 => (pos_3 => (vit_4 => (style_5 => (qst_6 => \{P.Players.Meta: (score_7 => (kills_8 => (found_9 => (stored_name_10 => (rest_11 => (+name_10 = P.Players.text_name(stored_name_10); Con{Tuple{score_7, name_10}, Bq.score_names(rest_11)})))))); \{}}))))))); \{}}; \{}}}

@unsafe
def Bq.over_lines():
  (ps_0 => Bq.over_lines_go(0, Bq.ranked(Bq.score_names(ps_0))))

@unsafe
def Bq.hero_add_gold(h, amount):
  Rewards.Rewards.add_gold(h, amount)

@unsafe
def Bq.sideq_idx():
  (kind_0 => (+apply_179 = {(kind_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_180 = {(kind_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_181 = {(word => C.Bq.word_case(U32, word, 0, (unit => 9), (_630_0 => 2), 0)) : (@+___0: U32 -> U32)}; apply_181(C.Bq.bit(U32.is_eq(kind_0, 4))))), (_632_1 => 1), 0))) : (@+kind_0: U32 -> (@+___1: U32 -> U32))}; apply_180(kind_0, C.Bq.bit(U32.is_eq(kind_0, 3))))), (_634_1 => 0), 0))) : (@+kind_0: U32 -> (@+___1: U32 -> U32))}; apply_179(kind_0, C.Bq.bit(U32.is_eq(kind_0, 1)))))

@unsafe
def Bq.drop_roll():
  (kind_0 => (tick_1 => (mid_2 => (+r_3 = (Bq.hash2(((tick_1 * 31 : U32) + mid_2 : U32), (kind_0 + 917 : U32)) % 100 : U32); (+apply_194 = {(kind_0 => (word => C.Bq.word_case(U32, word, 0, (unit => 4294967295), (_658_1 => Data.Bq.mob_drop_item(kind_0)), 0))) : (@+kind_0: U32 -> (@+___1: U32 -> U32))}; apply_194(kind_0, C.Bq.bit(U32.is_lt(r_3, Data.Bq.mob_drop_pct(kind_0)))))))))

@unsafe
def Bq.rare_drop_of():
  (zone_0 => Data.Bq.zone_rare_item(zone_0))

@unsafe
def Bq.drop_pick():
  (kind_0 => (rare_1 => (mzone_2 => (tick_3 => (mid_4 => (+apply_198 = {(kind_0 => (tick_1 => (mid_2 => (mzone_3 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_199 = {(kind_0 => (tick_1 => (mid_2 => (mzone_3 => (word => C.Bq.word_case(U32, word, 0, (unit => Bq.drop_roll(kind_0, tick_1, mid_2)), (_780_4 => Bq.rare_drop_of(mzone_3)), 0)))))) : (@+kind_0: U32 -> (@+tick_1: U32 -> (@+mid_2: U32 -> (@+mzone_3: U32 -> (@+___4: U32 -> U32)))))}; apply_199(kind_0, tick_1, mid_2, mzone_3, C.Bq.bit(U32.is_ge(kind_0, 6))))), (_782_4 => Bq.rare_drop_of(mzone_3)), 0)))))) : (@+kind_0: U32 -> (@+tick_1: U32 -> (@+mid_2: U32 -> (@+mzone_3: U32 -> (@+___4: U32 -> U32)))))}; apply_198(kind_0, tick_3, mid_4, mzone_2, C.Bq.bit(U32.is_eq(rare_1, 1)))))))))

@unsafe
def Bq.boss_outs():
  (kind_0 => (rare_1 => (elapsed_2 => (name_3 => (+apply_209 = {(kind_0 => (name_1 => (rare_2 => (elapsed_3 => (word => C.Bq.word_case(List<&1, Bq.OutL>, word, 0, (unit => (+apply_210 = {(kind_0 => (name_1 => (word => C.Bq.word_case(List<&1, Bq.OutL>, word, 0, (unit => Nil{}), (_788_2 => Bq.evlog(Support.Bq.String.flatten([C.Bq.text("A rare "), Data.Bq.mob_name(kind_0), C.Bq.text(" was slain by "), name_1, C.Bq.text("!")]))), 0)))) : (@+kind_0: U32 -> (@+name_1: C.Bq.String -> (@+___2: U32 -> List<&1, Bq.OutL>)))}; apply_210(kind_0, name_1, C.Bq.bit(U32.is_eq(rare_2, 1))))), (_790_4 => Bq.evlog(Support.Bq.String.flatten([Data.Bq.mob_name(kind_0), C.Bq.text(" falls to "), name_1, C.Bq.text("! ("), Support.Bq.U32.show(elapsed_3), C.Bq.text("s)")]))), 0)))))) : (@+kind_0: U32 -> (@+name_1: C.Bq.String -> (@+rare_2: U32 -> (@+elapsed_3: U32 -> (@+___4: U32 -> List<&1, Bq.OutL>)))))}; apply_209(kind_0, name_3, rare_1, elapsed_2, C.Bq.bit(U32.is_ge(kind_0, 6))))))))

@unsafe
def Bq.boss_bonus_score():
  (kind_0 => (elapsed_1 => (+apply_213 = {(kind_0 => (elapsed_1 => (word => C.Bq.word_case(U32, word, 0, (unit => 0), (_794_2 => Data.Bq.boss_time_bonus(kind_0, elapsed_1)), 0)))) : (@+kind_0: U32 -> (@+elapsed_1: U32 -> (@+___2: U32 -> U32)))}; apply_213(kind_0, elapsed_1, C.Bq.bit(U32.is_ge(kind_0, 6))))))

@unsafe
def Bq.up_outs():
  (ups_0 => (z_1 => (x_2 => (y_3 => (name_4 => (+apply_214 = {(name_0 => (z_1 => (x_2 => (y_3 => (word => C.Bq.word_case(List<&1, Bq.OutL>, word, 0, (unit => Nil{}), (_801_4 => Support.Bq.List.concat(Bq.OutL, Bq.evlog(Support.Bq.List.concat(Char, name_0, C.Bq.text(" leveled up!"))), [Bq.fx(z_1, 2, x_2, y_3)])), 0)))))) : (@+name_0: C.Bq.String -> (@+z_1: U32 -> (@+x_2: U32 -> (@+y_3: U32 -> (@+___4: U32 -> List<&1, Bq.OutL>)))))}; apply_214(name_4, z_1, x_2, y_3, C.Bq.bit(U32.is_gt(ups_0, 0)))))))))

@unsafe
def Bq.find_bonus():
  (found_0 => (k_1 => (+apply_219 = {(k_0 => (word => C.Bq.word_case(U32, word, 0, (unit => Data.Bq.find_score(Data.Bq.item_rarity(k_0))), (_663_1 => 0), 0))) : (@+k_0: U32 -> (@+___1: U32 -> U32))}; apply_219(k_1, C.Bq.bit(U32.is_eq((U32.shrn(found_0, U32.to_nat((k_1 .&. 31 : U32))) .&. 1 : U32), 1))))))

@unsafe
def Bq.hero_add_item(h, kind):
  Rewards.Rewards.add_item(h, kind)

@unsafe
def Bq.found_bit():
  (k_0 => U32.shln(1, U32.to_nat((k_0 .&. 31 : U32))))

@unsafe
def Bq.maybe_drop():
  (h_0 => (k_1 => (found_2 => (+apply_237 = {(found_0 => (k_1 => (h_2 => (word => C.Bq.word_case(Sigma<&1, &1, Game.Bq.Hero, (__4 => Sigma<&1, &1, U32, (__5 => Sigma<&1, &1, U32, (__6 => List<&1, Bq.OutL>)>)>)>, word, 0, (unit => (+bonus_3 = Bq.find_bonus(found_0, k_1); (+outs_4 = Bq.evlog(Support.Bq.List.concat(Char, C.Bq.text("Loot! "), Data.Bq.item_name(k_1))); Tuple{Bq.hero_add_item(h_2, k_1), Tuple{(found_0 .|. Bq.found_bit(k_1) : U32), Tuple{bonus_3, outs_4}}}))), (_670_3 => Tuple{h_2, Tuple{found_0, Tuple{0, Nil{}}}}), 0))))) : (@+found_0: U32 -> (@+k_1: U32 -> (@+h_2: Game.Bq.Hero -> (@+___3: U32 -> Sigma<&1, &1, Game.Bq.Hero, (__4 => Sigma<&1, &1, U32, (__5 => Sigma<&1, &1, U32, (__6 => List<&1, Bq.OutL>)>)>)>))))}; apply_237(found_2, k_1, h_0, C.Bq.bit(U32.is_eq(k_1, 4294967295)))))))

@unsafe
def Bq.sideq_reward(h, quest):
  Rewards.Rewards.sidequest(h, quest)

@unsafe
def Bq.ev():
  (text_0 => Bq.OutL.All{Proto.Bq.wire_enc(C.Bq.text("EV"), Nil{}, text_0)})

@unsafe
def Bq.apply_sideq():
  (p_hero_0 => (q_1 => (cnt_2 => (done_3 => (+apply_248 = {(cnt_0 => (p_hero_1 => (done_2 => (q_3 => (word => C.Bq.word_case(Sigma<&1, &1, Game.Bq.Hero, (__5 => Sigma<&1, &1, U32, (__6 => Sigma<&1, &1, U32, (__7 => Sigma<&1, &1, U32, (__8 => List<&1, Bq.OutL>)>)>)>)>, word, 0, (unit => (+c2_4 = (cnt_0 + 1 : U32); (+apply_249 = {(p_hero_0 => (c2_1 => (done_2 => (q_3 => (word => C.Bq.word_case(Sigma<&1, &1, Game.Bq.Hero, (__5 => Sigma<&1, &1, U32, (__6 => Sigma<&1, &1, U32, (__7 => Sigma<&1, &1, U32, (__8 => List<&1, Bq.OutL>)>)>)>)>, word, 0, (unit => Tuple{p_hero_0, Tuple{c2_1, Tuple{done_2, Tuple{0, Nil{}}}}}), (_649_4 => (+h2_5 = Bq.sideq_reward(p_hero_0, q_3); (+outs_6 = Support.Bq.List.concat(Bq.OutL, Bq.evlog(Support.Bq.List.concat(Char, C.Bq.text("Side quest complete: "), Data.Bq.sideq_name(q_3))), [Bq.ev(Data.Bq.sideq_lore(q_3))]); Tuple{h2_5, Tuple{c2_1, Tuple{(done_2 .|. U32.shln(1, U32.to_nat(q_3)) : U32), Tuple{Data.Bq.sideq_score(q_3), outs_6}}}}))), 0)))))) : (@+p_hero_0: Game.Bq.Hero -> (@+c2_1: U32 -> (@+done_2: U32 -> (@+q_3: U32 -> (@+___4: U32 -> Sigma<&1, &1, Game.Bq.Hero, (__5 => Sigma<&1, &1, U32, (__6 => Sigma<&1, &1, U32, (__7 => Sigma<&1, &1, U32, (__8 => List<&1, Bq.OutL>)>)>)>)>)))))}; apply_249(p_hero_1, c2_4, done_2, q_3, C.Bq.bit(U32.is_ge(c2_4, Data.Bq.sideq_need(q_3))))))), (_651_4 => Tuple{p_hero_1, Tuple{cnt_0, Tuple{done_2, Tuple{0, Nil{}}}}}), 0)))))) : (@+cnt_0: U32 -> (@+p_hero_1: Game.Bq.Hero -> (@+done_2: U32 -> (@+q_3: U32 -> (@+___4: U32 -> Sigma<&1, &1, Game.Bq.Hero, (__5 => Sigma<&1, &1, U32, (__6 => Sigma<&1, &1, U32, (__7 => Sigma<&1, &1, U32, (__8 => List<&1, Bq.OutL>)>)>)>)>)))))}; apply_248(cnt_2, p_hero_0, done_3, q_1, C.Bq.word_or(C.Bq.bit(U32.is_gt(q_1, 2)), C.Bq.bit(U32.is_eq((U32.shrn(done_3, U32.to_nat(q_1)) .&. 1 : U32), 1)))))))))

@unsafe
def Bq.apply_sideq_at():
  (h_0 => (q_1 => (sq0_2 => (sq1_3 => (sq2_4 => (sqdone_5 => (+apply_250 = {(h_0 => (sq0_1 => (sq1_2 => (sq2_3 => (sqdone_4 => (q_5 => (word => C.Bq.word_case(Sigma<&1, &1, Game.Bq.Hero, (__7 => Sigma<&1, &1, Sigma<&1, &1, U32, (__8 => Sigma<&1, &1, U32, (__9 => Sigma<&1, &1, U32, (__10 => U32)>)>)>, (__8 => Sigma<&1, &1, U32, (__9 => Sigma<&1, &1, U32, (__10 => List<&1, Bq.OutL>)>)>)>)>, word, 0, (unit => (+apply_251 = {(h_0 => (sq0_1 => (sq1_2 => (sq2_3 => (sqdone_4 => (q_5 => (word => C.Bq.word_case(Sigma<&1, &1, Game.Bq.Hero, (__7 => Sigma<&1, &1, Sigma<&1, &1, U32, (__8 => Sigma<&1, &1, U32, (__9 => Sigma<&1, &1, U32, (__10 => U32)>)>)>, (__8 => Sigma<&1, &1, U32, (__9 => Sigma<&1, &1, U32, (__10 => List<&1, Bq.OutL>)>)>)>)>, word, 0, (unit => (+apply_252 = {(h_0 => (sq0_1 => (sq1_2 => (sq2_3 => (sqdone_4 => (word => C.Bq.word_case(Sigma<&1, &1, Game.Bq.Hero, (__6 => Sigma<&1, &1, Sigma<&1, &1, U32, (__7 => Sigma<&1, &1, U32, (__8 => Sigma<&1, &1, U32, (__9 => U32)>)>)>, (__7 => Sigma<&1, &1, U32, (__8 => Sigma<&1, &1, U32, (__9 => List<&1, Bq.OutL>)>)>)>)>, word, 0, (unit => Tuple{h_0, Tuple{Tuple{sq0_1, Tuple{sq1_2, Tuple{sq2_3, sqdone_4}}}, Tuple{0, Tuple{0, Nil{}}}}}), (_769_5 => (+apply_253 = {(sq0_0 => (sq1_1 => \{Tuple: (fst_2 => (snd_3 => (+apply_254 = {(fst_0 => (sq0_1 => (sq1_2 => \{Tuple: (fst_3 => (snd_4 => (+apply_255 = {(fst_0 => (sq0_1 => (sq1_2 => (fst_3 => \{Tuple: (fst_4 => (snd_5 => (+apply_256 = {(fst_0 => (sq0_1 => (sq1_2 => (fst_3 => (fst_4 => \{Tuple: (fst_5 => (snd_6 => Tuple{fst_0, Tuple{Tuple{sq0_1, Tuple{sq1_2, Tuple{fst_3, fst_4}}}, Tuple{0, Tuple{fst_5, snd_6}}}})); \{}}))))) : (@+fst_0: Game.Bq.Hero -> (@+sq0_1: U32 -> (@+sq1_2: U32 -> (@+fst_3: U32 -> (@+fst_4: U32 -> (@+___5: Sigma<&1, &1, U32, (__5 => List<&1, Bq.OutL>)> -> Sigma<&1, &1, Game.Bq.Hero, (__6 => Sigma<&1, &1, Sigma<&1, &1, U32, (__7 => Sigma<&1, &1, U32, (__8 => Sigma<&1, &1, U32, (__9 => U32)>)>)>, (__7 => Sigma<&1, &1, U32, (__8 => Sigma<&1, &1, U32, (__9 => List<&1, Bq.OutL>)>)>)>)>))))))}; apply_256(fst_0, sq0_1, sq1_2, fst_3, fst_4, snd_5)))); \{}})))) : (@+fst_0: Game.Bq.Hero -> (@+sq0_1: U32 -> (@+sq1_2: U32 -> (@+fst_3: U32 -> (@+___4: Sigma<&1, &1, U32, (__4 => Sigma<&1, &1, U32, (__5 => List<&1, Bq.OutL>)>)> -> Sigma<&1, &1, Game.Bq.Hero, (__5 => Sigma<&1, &1, Sigma<&1, &1, U32, (__6 => Sigma<&1, &1, U32, (__7 => Sigma<&1, &1, U32, (__8 => U32)>)>)>, (__6 => Sigma<&1, &1, U32, (__7 => Sigma<&1, &1, U32, (__8 => List<&1, Bq.OutL>)>)>)>)>)))))}; apply_255(fst_0, sq0_1, sq1_2, fst_3, snd_4)))); \{}}))) : (@+fst_0: Game.Bq.Hero -> (@+sq0_1: U32 -> (@+sq1_2: U32 -> (@+___3: Sigma<&1, &1, U32, (__3 => Sigma<&1, &1, U32, (__4 => Sigma<&1, &1, U32, (__5 => List<&1, Bq.OutL>)>)>)> -> Sigma<&1, &1, Game.Bq.Hero, (__4 => Sigma<&1, &1, Sigma<&1, &1, U32, (__5 => Sigma<&1, &1, U32, (__6 => Sigma<&1, &1, U32, (__7 => U32)>)>)>, (__5 => Sigma<&1, &1, U32, (__6 => Sigma<&1, &1, U32, (__7 => List<&1, Bq.OutL>)>)>)>)>))))}; apply_254(fst_2, sq0_0, sq1_1, snd_3)))); \{}})) : (@+sq0_0: U32 -> (@+sq1_1: U32 -> (@+___2: Sigma<&1, &1, Game.Bq.Hero, (__2 => Sigma<&1, &1, U32, (__3 => Sigma<&1, &1, U32, (__4 => Sigma<&1, &1, U32, (__5 => List<&1, Bq.OutL>)>)>)>)> -> Sigma<&1, &1, Game.Bq.Hero, (__3 => Sigma<&1, &1, Sigma<&1, &1, U32, (__4 => Sigma<&1, &1, U32, (__5 => Sigma<&1, &1, U32, (__6 => U32)>)>)>, (__4 => Sigma<&1, &1, U32, (__5 => Sigma<&1, &1, U32, (__6 => List<&1, Bq.OutL>)>)>)>)>)))}; apply_253(sq0_1, sq1_2, Bq.apply_sideq(h_0, 2, sq2_3, sqdone_4)))), 0))))))) : (@+h_0: Game.Bq.Hero -> (@+sq0_1: U32 -> (@+sq1_2: U32 -> (@+sq2_3: U32 -> (@+sqdone_4: U32 -> (@+___5: U32 -> Sigma<&1, &1, Game.Bq.Hero, (__6 => Sigma<&1, &1, Sigma<&1, &1, U32, (__7 => Sigma<&1, &1, U32, (__8 => Sigma<&1, &1, U32, (__9 => U32)>)>)>, (__7 => Sigma<&1, &1, U32, (__8 => Sigma<&1, &1, U32, (__9 => List<&1, Bq.OutL>)>)>)>)>))))))}; apply_252(h_0, sq0_1, sq1_2, sq2_3, sqdone_4, C.Bq.bit(U32.is_eq(q_5, 2))))), (_771_6 => (+apply_257 = {(sq0_0 => (sq2_1 => \{Tuple: (fst_2 => (snd_3 => (+apply_258 = {(fst_0 => (sq0_1 => (sq2_2 => \{Tuple: (fst_3 => (snd_4 => (+apply_259 = {(fst_0 => (sq0_1 => (fst_2 => (sq2_3 => \{Tuple: (fst_4 => (snd_5 => (+apply_260 = {(fst_0 => (sq0_1 => (fst_2 => (sq2_3 => (fst_4 => \{Tuple: (fst_5 => (snd_6 => Tuple{fst_0, Tuple{Tuple{sq0_1, Tuple{fst_2, Tuple{sq2_3, fst_4}}}, Tuple{0, Tuple{fst_5, snd_6}}}})); \{}}))))) : (@+fst_0: Game.Bq.Hero -> (@+sq0_1: U32 -> (@+fst_2: U32 -> (@+sq2_3: U32 -> (@+fst_4: U32 -> (@+___5: Sigma<&1, &1, U32, (__5 => List<&1, Bq.OutL>)> -> Sigma<&1, &1, Game.Bq.Hero, (__6 => Sigma<&1, &1, Sigma<&1, &1, U32, (__7 => Sigma<&1, &1, U32, (__8 => Sigma<&1, &1, U32, (__9 => U32)>)>)>, (__7 => Sigma<&1, &1, U32, (__8 => Sigma<&1, &1, U32, (__9 => List<&1, Bq.OutL>)>)>)>)>))))))}; apply_260(fst_0, sq0_1, fst_2, sq2_3, fst_4, snd_5)))); \{}})))) : (@+fst_0: Game.Bq.Hero -> (@+sq0_1: U32 -> (@+fst_2: U32 -> (@+sq2_3: U32 -> (@+___4: Sigma<&1, &1, U32, (__4 => Sigma<&1, &1, U32, (__5 => List<&1, Bq.OutL>)>)> -> Sigma<&1, &1, Game.Bq.Hero, (__5 => Sigma<&1, &1, Sigma<&1, &1, U32, (__6 => Sigma<&1, &1, U32, (__7 => Sigma<&1, &1, U32, (__8 => U32)>)>)>, (__6 => Sigma<&1, &1, U32, (__7 => Sigma<&1, &1, U32, (__8 => List<&1, Bq.OutL>)>)>)>)>)))))}; apply_259(fst_0, sq0_1, fst_3, sq2_2, snd_4)))); \{}}))) : (@+fst_0: Game.Bq.Hero -> (@+sq0_1: U32 -> (@+sq2_2: U32 -> (@+___3: Sigma<&1, &1, U32, (__3 => Sigma<&1, &1, U32, (__4 => Sigma<&1, &1, U32, (__5 => List<&1, Bq.OutL>)>)>)> -> Sigma<&1, &1, Game.Bq.Hero, (__4 => Sigma<&1, &1, Sigma<&1, &1, U32, (__5 => Sigma<&1, &1, U32, (__6 => Sigma<&1, &1, U32, (__7 => U32)>)>)>, (__5 => Sigma<&1, &1, U32, (__6 => Sigma<&1, &1, U32, (__7 => List<&1, Bq.OutL>)>)>)>)>))))}; apply_258(fst_2, sq0_0, sq2_1, snd_3)))); \{}})) : (@+sq0_0: U32 -> (@+sq2_1: U32 -> (@+___2: Sigma<&1, &1, Game.Bq.Hero, (__2 => Sigma<&1, &1, U32, (__3 => Sigma<&1, &1, U32, (__4 => Sigma<&1, &1, U32, (__5 => List<&1, Bq.OutL>)>)>)>)> -> Sigma<&1, &1, Game.Bq.Hero, (__3 => Sigma<&1, &1, Sigma<&1, &1, U32, (__4 => Sigma<&1, &1, U32, (__5 => Sigma<&1, &1, U32, (__6 => U32)>)>)>, (__4 => Sigma<&1, &1, U32, (__5 => Sigma<&1, &1, U32, (__6 => List<&1, Bq.OutL>)>)>)>)>)))}; apply_257(sq0_1, sq2_3, Bq.apply_sideq(h_0, 1, sq1_2, sqdone_4)))), 0)))))))) : (@+h_0: Game.Bq.Hero -> (@+sq0_1: U32 -> (@+sq1_2: U32 -> (@+sq2_3: U32 -> (@+sqdone_4: U32 -> (@+q_5: U32 -> (@+___6: U32 -> Sigma<&1, &1, Game.Bq.Hero, (__7 => Sigma<&1, &1, Sigma<&1, &1, U32, (__8 => Sigma<&1, &1, U32, (__9 => Sigma<&1, &1, U32, (__10 => U32)>)>)>, (__8 => Sigma<&1, &1, U32, (__9 => Sigma<&1, &1, U32, (__10 => List<&1, Bq.OutL>)>)>)>)>)))))))}; apply_251(h_0, sq0_1, sq1_2, sq2_3, sqdone_4, q_5, C.Bq.bit(U32.is_eq(q_5, 1))))), (_773_6 => (+apply_261 = {(sq1_0 => (sq2_1 => \{Tuple: (fst_2 => (snd_3 => (+apply_262 = {(fst_0 => (sq1_1 => (sq2_2 => \{Tuple: (fst_3 => (snd_4 => (+apply_263 = {(fst_0 => (fst_1 => (sq1_2 => (sq2_3 => \{Tuple: (fst_4 => (snd_5 => (+apply_264 = {(fst_0 => (fst_1 => (sq1_2 => (sq2_3 => (fst_4 => \{Tuple: (fst_5 => (snd_6 => Tuple{fst_0, Tuple{Tuple{fst_1, Tuple{sq1_2, Tuple{sq2_3, fst_4}}}, Tuple{0, Tuple{fst_5, snd_6}}}})); \{}}))))) : (@+fst_0: Game.Bq.Hero -> (@+fst_1: U32 -> (@+sq1_2: U32 -> (@+sq2_3: U32 -> (@+fst_4: U32 -> (@+___5: Sigma<&1, &1, U32, (__5 => List<&1, Bq.OutL>)> -> Sigma<&1, &1, Game.Bq.Hero, (__6 => Sigma<&1, &1, Sigma<&1, &1, U32, (__7 => Sigma<&1, &1, U32, (__8 => Sigma<&1, &1, U32, (__9 => U32)>)>)>, (__7 => Sigma<&1, &1, U32, (__8 => Sigma<&1, &1, U32, (__9 => List<&1, Bq.OutL>)>)>)>)>))))))}; apply_264(fst_0, fst_1, sq1_2, sq2_3, fst_4, snd_5)))); \{}})))) : (@+fst_0: Game.Bq.Hero -> (@+fst_1: U32 -> (@+sq1_2: U32 -> (@+sq2_3: U32 -> (@+___4: Sigma<&1, &1, U32, (__4 => Sigma<&1, &1, U32, (__5 => List<&1, Bq.OutL>)>)> -> Sigma<&1, &1, Game.Bq.Hero, (__5 => Sigma<&1, &1, Sigma<&1, &1, U32, (__6 => Sigma<&1, &1, U32, (__7 => Sigma<&1, &1, U32, (__8 => U32)>)>)>, (__6 => Sigma<&1, &1, U32, (__7 => Sigma<&1, &1, U32, (__8 => List<&1, Bq.OutL>)>)>)>)>)))))}; apply_263(fst_0, fst_3, sq1_1, sq2_2, snd_4)))); \{}}))) : (@+fst_0: Game.Bq.Hero -> (@+sq1_1: U32 -> (@+sq2_2: U32 -> (@+___3: Sigma<&1, &1, U32, (__3 => Sigma<&1, &1, U32, (__4 => Sigma<&1, &1, U32, (__5 => List<&1, Bq.OutL>)>)>)> -> Sigma<&1, &1, Game.Bq.Hero, (__4 => Sigma<&1, &1, Sigma<&1, &1, U32, (__5 => Sigma<&1, &1, U32, (__6 => Sigma<&1, &1, U32, (__7 => U32)>)>)>, (__5 => Sigma<&1, &1, U32, (__6 => Sigma<&1, &1, U32, (__7 => List<&1, Bq.OutL>)>)>)>)>))))}; apply_262(fst_2, sq1_0, sq2_1, snd_3)))); \{}})) : (@+sq1_0: U32 -> (@+sq2_1: U32 -> (@+___2: Sigma<&1, &1, Game.Bq.Hero, (__2 => Sigma<&1, &1, U32, (__3 => Sigma<&1, &1, U32, (__4 => Sigma<&1, &1, U32, (__5 => List<&1, Bq.OutL>)>)>)>)> -> Sigma<&1, &1, Game.Bq.Hero, (__3 => Sigma<&1, &1, Sigma<&1, &1, U32, (__4 => Sigma<&1, &1, U32, (__5 => Sigma<&1, &1, U32, (__6 => U32)>)>)>, (__4 => Sigma<&1, &1, U32, (__5 => Sigma<&1, &1, U32, (__6 => List<&1, Bq.OutL>)>)>)>)>)))}; apply_261(sq1_2, sq2_3, Bq.apply_sideq(h_0, 0, sq0_1, sqdone_4)))), 0)))))))) : (@+h_0: Game.Bq.Hero -> (@+sq0_1: U32 -> (@+sq1_2: U32 -> (@+sq2_3: U32 -> (@+sqdone_4: U32 -> (@+q_5: U32 -> (@+___6: U32 -> Sigma<&1, &1, Game.Bq.Hero, (__7 => Sigma<&1, &1, Sigma<&1, &1, U32, (__8 => Sigma<&1, &1, U32, (__9 => Sigma<&1, &1, U32, (__10 => U32)>)>)>, (__8 => Sigma<&1, &1, U32, (__9 => Sigma<&1, &1, U32, (__10 => List<&1, Bq.OutL>)>)>)>)>)))))))}; apply_250(h_0, sq0_2, sq1_3, sq2_4, sqdone_5, q_1, C.Bq.bit(U32.is_eq(q_1, 0))))))))))

@unsafe
def Bq.hero_lv():
  \{Game.Bq.Hero.Hero: (inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => Support.Bq.Nat.to_u32(lv_6)))))))))))); \{}}

@unsafe
def Bq.xp_result(result: Rewards.Rewards.Result) -> C.Bq.Pair.Pair(Game.Bq.Hero, (h => C.Bq.Pair.Pair(U32, (xp => U32)))):
  match result:
    case Rewards.Rewards.Result{hero, xp, levels}:
      Tuple{hero, Tuple{xp, levels}}

@unsafe
def Bq.gain_xp_go(fuel, h, xp, ups):
  Bq.xp_result(Rewards.Rewards.go(U32.to_nat(fuel), h, xp, ups))

@unsafe
def Bq.gain_xp(h, xp, gained):
  Bq.xp_result(Rewards.Rewards.gain(h, xp, gained))

@unsafe
def Bq.payout_plan(+kind: U32, +rare: U32, mzone: U32, tick: U32, elapsed: U32, mid: U32) -> Pay.Payout.Plan:
  +mult = U32.add(1,U32.mul(7,rare))
  +q = Pay.Payout.side_index(kind)
  +drop = Bq.drop_pick(kind,rare,mzone,tick,mid)
  Pay.Payout.Plan{kind,U32.mul(Data.Bq.mob_xp(kind),mult),U32.mul(Data.Bq.mob_gold(kind),mult),U32.mul(Data.Bq.mob_score(kind),U32.add(1,U32.mul(9,rare))),Data.Bq.sideq_need(q),Data.Bq.sideq_score(q),drop,Data.Bq.find_score(Data.Bq.item_rarity(drop)),Bq.boss_bonus_score(kind,elapsed),Data.Bq.MQ_CULL_N,Data.Bq.MQ_SCORE_CULL}

@unsafe
def Bq.payout_side_out(done: Maybe<&2,U32>) -> List<&1,Bq.OutL>:
  match done:
    case None{}: Nil{}
    case Some{q}:
      +quest = q
      Support.Bq.List.concat(Bq.OutL,Bq.evlog(Support.Bq.List.concat(Char,C.Bq.text("Side quest complete: "),Data.Bq.sideq_name(quest))),[Bq.ev(Data.Bq.sideq_lore(quest))])

@unsafe
def Bq.payout_drop_out(drop: Maybe<&2,U32>) -> List<&1,Bq.OutL>:
  match drop:
    case None{}: Nil{}
    case Some{kind}: Bq.evlog(Support.Bq.List.concat(Char,C.Bq.text("Loot! "),Data.Bq.item_name(kind)))

@unsafe
def Bq.payout_player_out(player: P.Players.State, side: Maybe<&2,U32>, drop: Maybe<&2,U32>, levels: U32, kind: U32, rare: U32, elapsed: U32) -> List<&1,Bq.OutL>:
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
      match pos:
        case P.Players.Pos{zone,x,y,dir,moving}:
          match meta:
            case P.Players.Meta{score,kills,found,name}:
              +text_name = P.Players.text_name(name)
              Support.Bq.List.concat(Bq.OutL,Bq.payout_side_out(side),Support.Bq.List.concat(Bq.OutL,Bq.payout_drop_out(drop),Support.Bq.List.concat(Bq.OutL,Bq.boss_outs(kind,rare,elapsed,text_name),Bq.up_outs(levels,zone,x,y,text_name))))

@unsafe
def Bq.payout_outs(paid: Pay.Payout.Kill, kind: U32, rare: U32, elapsed: U32) -> List<&1,Bq.OutL>:
  match paid:
    case Pay.Payout.Kill{player,side,drop,levels}: Bq.payout_player_out(player,side,drop,levels,kind,rare,elapsed)

@unsafe
def Bq.payout_player_result(+paid: Pay.Payout.Kill, kind: U32, rare: U32, elapsed: U32) -> C.Bq.Pair.Pair(Bq.Plr,(player => List<&1,Bq.OutL>)):
  Tuple{Pay.Payout.killer(paid),Bq.payout_outs(paid,kind,rare,elapsed)}

@unsafe
def Bq.kill_reward(p,kind,rare,mzone,tick,elapsed,mid):
  Bq.payout_player_result(Pay.Payout.kill(p,Bq.payout_plan(kind,rare,mzone,tick,elapsed,mid)),kind,rare,elapsed)



@unsafe
def Bq.battle_end_out(ended: Bool,players: List<&2,P.Players.State>,outs: List<&1,Bq.OutL>) -> List<&1,Bq.OutL>:
  match ended:
    case False{}: outs
    case True{}: Support.Bq.List.concat(Bq.OutL,outs,Support.Bq.List.concat(Bq.OutL,Bq.evlog(C.Bq.text("THE NULLTIDE MAW IS SEALED! The realm is saved!")),Bq.over_lines(players)))

@unsafe
def Bq.battle_notice_out(notice: Battle.Battle.Notice) -> List<&1,Bq.OutL>:
  match notice:
    case Battle.Battle.Notice{kill,award,elapsed,ended,players}:
      match kill:
        case R.Roster.Kill{kind,rare,zone,mid}:
          Bq.battle_end_out(ended,players,Bq.payout_outs(award,kind,rare,elapsed))

@unsafe
def Bq.battle_notices(notices: List<&2,Battle.Battle.Notice>) -> List<&1,Bq.OutL>:
  match notices:
    case Nil{}: Nil{}
    case Con{head,rest}: Support.Bq.List.concat(Bq.OutL,Bq.battle_notice_out(head),Bq.battle_notices(rest))

@unsafe
def Bq.atk_fx():
  (z_0 => (x_1 => (y_2 => (dir_3 => (mid_4 => (crit_5 => (+apply_313 = {(z_0 => (crit_1 => (x_2 => (y_3 => (word => C.Bq.word_case(List<&1, Bq.OutL>, word, 0, (unit => [Bq.fx(z_0, (0 + (crit_1 * 4 : U32) : U32), x_2, y_3)]), (_1031_4 => Nil{}), 0)))))) : (@+z_0: U32 -> (@+crit_1: U32 -> (@+x_2: U32 -> (@+y_3: U32 -> (@+___4: U32 -> List<&1, Bq.OutL>)))))}; apply_313(z_0, crit_5, x_1, y_2, C.Bq.bit(U32.is_eq(mid_4, 0))))))))))

@unsafe
def Bq.render_combat(result: Fight.LiveCombat.Result) -> List<&1,Bq.OutL>:
  match result:
    case Fight.LiveCombat.Result{world,notices,visual}:
      match visual:
        case Fight.LiveCombat.Quiet{}: Bq.battle_notices(notices)
        case Fight.LiveCombat.Attack{zone,x,y,dir,mid,crit}: Support.Bq.List.concat(Bq.OutL,Bq.atk_fx(zone,x,y,dir,mid,crit),Bq.battle_notices(notices))
        case Fight.LiveCombat.Spin{zone,x,y}: Con{Bq.fx(zone,1,x,y),Bq.battle_notices(notices)}

@unsafe
def Bq.battle_world(maps: List<&2,List<&2,U32>>,result: Battle.Battle.Result) -> C.Bq.Pair.Pair(Bq.World,(world => List<&1,Bq.OutL>)):
  Fight.LiveCombat.emit(Bq.OutL,Fight.LiveCombat.pack(result,maps,Fight.LiveCombat.Quiet{}),Bq.render_combat)


@unsafe
def Bq.battle_input_taken(+mid: U32,damage: U32,+wm: S.Simulation.Meta,taken: R.Roster.Take) -> Battle.Battle.Input:
  match taken:
    case R.Roster.Take{others,found}:
      match found:
        case None{}: Battle.Battle.Input{mid,damage,Pay.Payout.Plan{0,0,0,0,0,0,4294967295,0,0,0,0}}
        case Some{monster}:
          match monster:
            case M.Monsters.State{actual,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}:
              Battle.Battle.Input{mid,damage,Bq.payout_plan(kind,rare,zone,Bq.wm_tick(wm),Battle.Battle.elapsed(wm),actual)}

@unsafe
def Bq.battle_input(monsters: List<&2,M.Monsters.State>,+mid: U32,damage: U32,wm: S.Simulation.Meta) -> Battle.Battle.Input:
  Bq.battle_input_taken(mid,damage,wm,R.Roster.take(monsters,mid))

@unsafe
def Bq.on_mob_kill(world,pid,kind,rare,mzone,mid):
  match world:
    case Terrain.Terrain.World{wm,players,mobs,maps}:
      Bq.battle_world(maps,Battle.Battle.reward(S.Simulation.State{wm,players,mobs},pid,R.Roster.Kill{kind,rare,mzone,mid},Bq.payout_plan(kind,rare,mzone,Bq.wm_tick(wm),Battle.Battle.elapsed(wm),mid),Data.Bq.MQ_SCORE_SIGIL))

@unsafe
def Bq.after_strike():
  (w_0 => (pid_1 => (z_2 => \{Fail: (u_3 => Tuple{w_0, Nil{}}); \{Done: \{Tuple: (kind_3 => \{Tuple: (rare_4 => \{Tuple: (mz_5 => (mid_6 => Bq.on_mob_kill(w_0, pid_1, kind_3, rare_4, mz_5, mid_6))); \{}}); \{}}); \{}}; \{}}})))

@unsafe
def Bq.respawn_of(kind):
  R.Roster.respawn_time(kind)

@unsafe
def Bq.strike_roster(result: R.Roster.Strike) -> C.Bq.Pair.Pair(List<&2, Bq.Mob>, (ms => C.Bq.Pair.Pair(Support.Bq.Maybe(C.Bq.Pair.Pair(U32, (k => C.Bq.Pair.Pair(U32, (r => C.Bq.Pair.Pair(U32, (z => U32))))))), (kill => U32)))):
  match result:
    case R.Roster.Strike{monsters, kill, dealt}:
      match kill:
        case None{}:
          Tuple{monsters, Tuple{Fail{Unit{}}, dealt}}
        case Some{info}:
          match info:
            case R.Roster.Kill{kind, rare, zone, mid}:
              Tuple{monsters, Tuple{Done{Tuple{kind, Tuple{rare, Tuple{zone, mid}}}}, dealt}}

@unsafe
def Bq.strike_mob(ms, mid, dmg):
  Bq.strike_roster(R.Roster.strike(ms, mid, dmg))

@unsafe
def Bq.battle_spin_inputs(mids: List<&1,U32>,+monsters: List<&2,M.Monsters.State>,+hero: Game.Bq.Hero,+wm: S.Simulation.Meta) -> List<&2,Battle.Battle.Input>:
  match mids:
    case Nil{}: Nil{}
    case Con{mid,rest}:
      +target = mid
      +damage = Support.Bq.U32.max(U32.div(U32.mul(Bq.plr_hit(hero,Bq.mob_df_at(monsters,target),0),3),5),1)
      Con{Bq.battle_input(monsters,target,damage,wm),Bq.battle_spin_inputs(rest,monsters,hero,wm)}

@unsafe
def Bq.spin_strikes(world,pid,mids,hero_snapshot,tick):
  match world:
    case Terrain.Terrain.World{wm,players,monsters,maps}:
      Bq.battle_world(maps,Battle.Battle.run(Bq.battle_spin_inputs(mids,monsters,hero_snapshot,wm),S.Simulation.State{wm,players,monsters},pid,Data.Bq.MQ_SCORE_SIGIL))

@unsafe
def Bq.spin_finished(zone: U32,x: U32,y: U32,result: Sigma<&1,&1,Bq.World,(world => List<&1,Bq.OutL>)>) -> Sigma<&1,&1,Bq.World,(world => List<&1,Bq.OutL>)>:
  match result:
    case Tuple{updated,outs}: Tuple{updated,Con{Bq.fx(zone,1,x,y),outs}}

@unsafe
def Bq.spin_powers(+monsters: List<&2,M.Monsters.State>,+hero: Game.Bq.Hero,+wm: S.Simulation.Meta,+selected: List<&2,M.Monsters.State>) -> Spin.SpinPlans.Powers(selected):
  match selected:
    case Nil{}: Unit{}
    case Con{monster,rest}:
      +target = R.Roster.id(monster)
      +damage = Support.Bq.U32.max(U32.div(U32.mul(Bq.plr_hit(hero,Bq.mob_df_at(monsters,target),0),3),5),1)
      Tuple{TP.TargetPlans.power(Bq.battle_input(monsters,target,damage,wm)),Bq.spin_powers(monsters,hero,wm,rest)}

@unsafe
def Bq.live_spin_powers(+monsters: List<&2,M.Monsters.State>,+player: P.Players.State,+wm: S.Simulation.Meta,+selected: List<&2,M.Monsters.State>) -> Spin.SpinPlans.Powers(selected):
  Bq.spin_powers(monsters,P.Players.hero(player),wm,selected)

@unsafe
def Bq.plan_spin(ready: Fight.LiveCombat.Ready) -> Fight.LiveCombat.Plan:
  LiveSpin.LiveSpin.plan(ready,Bq.live_spin_powers)

@unsafe
def Bq.spin_admitted(wm: Bq.WMeta,mobs: List<&2,Bq.Mob>,maps: List<&2,List<&2,U32>>,pid: U32,result: Combat.Combat.Result) -> Sigma<&1,&1,Bq.World,(world => List<&1,Bq.OutL>)>:
  +ready = {Fight.LiveCombat.Ready{wm,mobs,maps,result,pid,Data.Bq.MQ_SCORE_SIGIL} : Fight.LiveCombat.Ready}
  Fight.LiveCombat.emit(Bq.OutL,Fight.LiveCombat.finish(ready,Bq.plan_spin(ready)),Bq.render_combat)


@unsafe
def Bq.cmd_spin(world,pid):
  Fight.LiveCombat.emit(Bq.OutL,Fight.LiveCombat.run(world,Combat.Combat.Spin{},pid,Data.Bq.MQ_SCORE_SIGIL,Bq.plan_spin),Bq.render_combat)


def Bq.mob_in_reach(monsters,zone,x,y): Targets.Targets.first_id(monsters,Targets.Targets.Point{zone,x,y})

@unsafe
def Bq.hero_crit():
  \{Game.Bq.Hero.Hero: (inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => Support.Bq.U32.min(60, ((Support.Bq.Nat.to_u32(agi_8) * 2 : U32) + Data.Bq.charm_agi_pct((Bq.slot_kind(chm_4) - 1 : U32)) : U32))))))))))))); \{}}


@unsafe
def Bq.attack_finished(zone: U32,x: U32,y: U32,dir: U32,mid: U32,crit: U32,result: Sigma<&1,&1,Bq.World,(world => List<&1,Bq.OutL>)>) -> Sigma<&1,&1,Bq.World,(world => List<&1,Bq.OutL>)>:
  match result:
    case Tuple{final,outs}: Tuple{final,Support.Bq.List.concat(Bq.OutL,Bq.atk_fx(zone,x,y,dir,mid,crit),outs)}


@unsafe
def Bq.attack_power(+monsters: List<&2,M.Monsters.State>,hero: Game.Bq.Hero,+wm: S.Simulation.Meta,crit: U32,monster: M.Monsters.State) -> TP.TargetPlans.Power:
  +mid = R.Roster.id(monster)
  TP.TargetPlans.power(Bq.battle_input(monsters,mid,Bq.plr_hit(hero,Bq.mob_df_at(monsters,mid),crit),wm))

@unsafe
def Bq.live_attack_power(+monsters: List<&2,M.Monsters.State>,+player: P.Players.State,+wm: S.Simulation.Meta,+pid: U32) -> LiveAttack.LiveAttack.Tuning:
  +hero = P.Players.hero(player)
  +crit = C.Bq.bit(U32.is_lt(U32.mod(Bq.hash2(Bq.wm_tick(wm),U32.add(U32.mul(pid,7),3)),100),Bq.hero_crit(hero)))
  LiveAttack.LiveAttack.Tuning{crit,Bq.attack_power(monsters,hero,wm,crit)}

@unsafe
def Bq.plan_attack(ready: Fight.LiveCombat.Ready) -> Fight.LiveCombat.Plan:
  LiveAttack.LiveAttack.plan(ready,Bq.live_attack_power)

@unsafe
def Bq.attack_admitted(wm: Bq.WMeta,mobs: List<&2,Bq.Mob>,maps: List<&2,List<&2,U32>>,pid: U32,result: Combat.Combat.Result) -> Sigma<&1,&1,Bq.World,(world => List<&1,Bq.OutL>)>:
  +ready = {Fight.LiveCombat.Ready{wm,mobs,maps,result,pid,Data.Bq.MQ_SCORE_SIGIL} : Fight.LiveCombat.Ready}
  Fight.LiveCombat.emit(Bq.OutL,Fight.LiveCombat.finish(ready,Bq.plan_attack(ready)),Bq.render_combat)


@unsafe
def Bq.cmd_atk(world,pid):
  Fight.LiveCombat.emit(Bq.OutL,Fight.LiveCombat.run(world,Combat.Combat.Attack{},pid,Data.Bq.MQ_SCORE_SIGIL,Bq.plan_attack),Bq.render_combat)


@unsafe
def Bq.pos_halt():
  \{P.Players.Pos: (zone_0 => (x_1 => (y_2 => (dir_3 => (moving_4 => P.Players.Pos{zone_0, x_1, y_2, dir_3, 0}))))); \{}}

@unsafe
def Bq.cmd_halt(world,pid):
  Bq.interaction_command(world,pid,Interact.Interaction.Halt{})

@unsafe
def Bq.cmd_move(world,pid,direction):
  Bq.interaction_command(world,pid,Interact.Interaction.Move{direction})

@unsafe
def Bq.pm_name():
  \{P.Players.Meta: (score_0 => (kills_1 => (found_2 => (stored_name_3 => (+name_3 = P.Players.text_name(stored_name_3); name_3))))); \{}}

@unsafe
def Bq.mk_plr(pid, cid, skin, hairs, hairc, shirt, hat, cape, name):
  P.Players.spawn(pid, cid, P.Players.Style{skin, hairs, hairc, shirt, hat, cape}, P.Players.share_name(name), Data.Bq.SPAWN_X, Data.Bq.SPAWN_Y)

@unsafe
def Bq.add_plr_result(result: Join.Admission.Result,maps: Terrain.Terrain.Maps) -> C.Bq.Pair.Pair(Bq.World,(world => U32)):
  match result:
    case Join.Admission.Result{state,pid}:
      match state:
        case S.Simulation.State{meta,players,monsters}: Tuple{Terrain.Terrain.World{meta,players,monsters,maps},pid}

@unsafe
def Bq.add_plr(world,cid,skin,hairs,hairc,shirt,hat,cape,name):
  match world:
    case Terrain.Terrain.World{meta,players,monsters,maps}:
      Bq.add_plr_result(Join.Admission.add(S.Simulation.State{meta,players,monsters},cid,P.Players.Style{skin,hairs,hairc,shirt,hat,cape},P.Players.share_name(name)),maps)

@unsafe
def Bq.wm_wno():
  \{S.Simulation.Meta: (phase_0 => (wno_1 => (seed_2 => (tick_3 => (t0_4 => (now_5 => (sigils_6 => (fame_t_7 => (nextpid_8 => (nextmid_9 => wno_1)))))))))); \{}}

@unsafe
def Bq.del_plr(world,pid): Ref.References.remove(world,pid)

@unsafe
def Bq.gen_tile(zone,seed,index):
  Landscape.Landscape.random_tile(zone,seed,index)

@unsafe
def Bq.gen_tree(zone,seed,depth,index):
  Terrain.Terrain.linear(Landscape.Landscape.raw(U32.to_nat(depth),zone,seed,index))

@unsafe
def Bq.floor_of(zone):
  Landscape.Landscape.floor(zone)

@unsafe
def Bq.lset():
  \{Nil: (i_0 => (v_1 => Nil{})); \{Con: (h_0 => (t_1 => (word => C.Bq.word_case((@+v_2: U32 -> List<&1, U32>), word, 0, (unit => (v_2 => Con{v_2, t_1})), (j_2 => (v_3 => Con{h_0, Bq.lset(t_1, j_2, v_3)})), 1)))); \{}}}

@unsafe
def Bq.stamp_row():
  (m_0 => (x_1 => (word => C.Bq.word_case((@+y_3: U32 -> (@+t_4: U32 -> List<&1, U32>)), word, 0, (unit => (y_2 => (t_3 => m_0))), (p_2 => (y_3 => (t_4 => Bq.stamp_row(Bq.lset(m_0, ((y_3 * Data.Bq.ZONE_W : U32) + x_1 : U32), t_4), (x_1 + 1 : U32), p_2, y_3, t_4)))), 1))))

@unsafe
def Bq.stamp_col():
  (m_0 => (x_1 => (y_2 => (word => C.Bq.word_case((@+t_4: U32 -> List<&1, U32>), word, 0, (unit => (t_3 => m_0)), (p_3 => (t_4 => Bq.stamp_col(Bq.lset(m_0, ((y_2 * Data.Bq.ZONE_W : U32) + x_1 : U32), t_4), x_1, (y_2 + 1 : U32), p_3, t_4))), 1)))))

@unsafe
def Bq.stamp_box():
  (m_0 => (x0_1 => (y0_2 => (w_3 => (word => C.Bq.word_case((@+t_5: U32 -> List<&1, U32>), word, 0, (unit => (t_4 => m_0)), (hp_4 => (t_5 => Bq.stamp_box(Bq.stamp_row(m_0, x0_1, w_3, y0_2, t_5), x0_1, (y0_2 + 1 : U32), w_3, hp_4, t_5))), 1))))))

@unsafe
def Bq.portal_tile():
  (z_0 => (+apply_426 = {(z_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_427 = {(word => C.Bq.word_case(U32, word, 0, (unit => Data.Bq.T_PORTAL), (_281_0 => Data.Bq.T_RIFTFLOOR), 0)) : (@+___0: U32 -> U32)}; apply_427(C.Bq.bit(U32.is_eq(z_0, 3))))), (_283_1 => Data.Bq.T_RIFTPORTAL), 0))) : (@+z_0: U32 -> (@+___1: U32 -> U32))}; apply_426(z_0, C.Bq.bit(U32.is_eq(z_0, 2)))))

@unsafe
def Bq.back_portal():
  (m_0 => (z_1 => (+apply_428 = {(m_0 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => Bq.lset(m_0, ((Data.Bq.BACK_Y * Data.Bq.ZONE_W : U32) + Data.Bq.BACK_X : U32), Data.Bq.T_PORTAL)), (_287_1 => m_0), 0))) : (@+m_0: List<&1, U32> -> (@+___1: U32 -> List<&1, U32>))}; apply_428(m_0, C.Bq.bit(U32.is_eq(z_1, 0))))))

@unsafe
def Bq.village():
  (m_0 => (z_1 => (+apply_429 = {(m_0 => (z_1 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => (+apply_430 = {(m_0 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => m_0), (_292_1 => Bq.stamp_box(m_0, 10, 3, 12, 11, Data.Bq.T_RIFTFLOOR)), 0))) : (@+m_0: List<&1, U32> -> (@+___1: U32 -> List<&1, U32>))}; apply_430(m_0, C.Bq.bit(U32.is_eq(z_1, 3))))), (_294_2 => (+m1_3 = Bq.stamp_box(m_0, 3, 3, 9, 4, Data.Bq.T_GRASS); Bq.lset(m1_3, ((Data.Bq.SHOP_Y * Data.Bq.ZONE_W : U32) + Data.Bq.SHOP_X : U32), Data.Bq.T_SHOPMAT))), 0)))) : (@+m_0: List<&1, U32> -> (@+z_1: U32 -> (@+___2: U32 -> List<&1, U32>)))}; apply_429(m_0, z_1, C.Bq.bit(U32.is_eq(z_1, 0))))))

@unsafe
def Bq.gen_zone(zone,seed):
  Terrain.Terrain.linear(Landscape.Landscape.zone(zone,seed))

@unsafe
def Bq.gen_maps(seed):
  Landscape.Landscape.maps(seed)

@unsafe
def Bq.zone_kinds(zone,salt): Pop.Population.kind(zone,salt)

@unsafe
def Bq.tile_at(maps,z,x,y): Terrain.Terrain.tile_at(maps,z,x,y)

@unsafe
def Bq.walk_ok(maps,z,x,y): C.Bq.bit(Terrain.Terrain.can_walk(maps,P.Players.Pos{z,x,y,0,0}))

@unsafe
def Bq.in_village(z,x,y): C.Bq.bit(Terrain.Terrain.in_village(P.Players.Pos{z,x,y,0,0}))

@unsafe
def Bq.spawn_spot(maps,zone,salt): Place.Placement.xy(Place.Placement.spot(maps,zone,salt))

@unsafe
def Bq.mk_mob(maps,mid,zone,salt,rare): Pop.Population.monster(maps,mid,zone,salt,rare)

@unsafe
def Bq.populate_zone(maps,zone,count,base): Pop.Population.populate(U32.to_nat(count),maps,zone,base)

@unsafe
def Bq.pick_boss_x():
  (z_0 => (+apply_444 = {(word => C.Bq.word_case(U32, word, 0, (unit => Data.Bq.BOSS_X), (_340_0 => Data.Bq.MAW_X), 0)) : (@+___0: U32 -> U32)}; apply_444(C.Bq.bit(U32.is_eq(z_0, 3)))))

@unsafe
def Bq.pick_boss_y():
  (z_0 => (+apply_445 = {(word => C.Bq.word_case(U32, word, 0, (unit => Data.Bq.BOSS_Y), (_343_0 => Data.Bq.MAW_Y), 0)) : (@+___0: U32 -> U32)}; apply_445(C.Bq.bit(U32.is_eq(z_0, 3)))))

@unsafe
def Bq.mk_boss(mid,zone): Pop.Population.boss(mid,zone)

@unsafe
def Bq.initial_mobs(maps): Pop.Population.initial(maps)

@unsafe
def Bq.fresh_world(world,seed,now): Pop.Population.fresh(world,seed,now)

@unsafe
def Bq.snap_mobs():
  \{Nil: (z_0 => Tuple{0, Nil{}}); \{Con: \{M.Monsters.State: (mid_0 => (kind_1 => (rare_2 => (zone_3 => (x_4 => (y_5 => (hp_6 => (mhp_7 => (tgt_8 => (atkcd_9 => (dead_10 => (resp_11 => (rest_12 => (z_13 => (+apply_449 = {(mid_0 => (kind_1 => (rare_2 => (x_3 => (y_4 => (hp_5 => (mhp_6 => (zone_7 => (z_8 => (dead_9 => \{Tuple: (fst_10 => (snd_11 => (+apply_450 = {(fst_0 => (snd_1 => (mid_2 => (kind_3 => (rare_4 => (x_5 => (y_6 => (hp_7 => (mhp_8 => (word => C.Bq.word_case(Sigma<&1, &1, U32, (__10 => List<&1, U32>)>, word, 0, (unit => Tuple{fst_0, snd_1}), (_1701_9 => Tuple{(fst_0 + 1 : U32), Support.Bq.List.concat(U32, [mid_2, kind_3, rare_4, x_5, y_6, hp_7, mhp_8], snd_1)}), 0))))))))))) : (@+fst_0: U32 -> (@+snd_1: (__1 => List<&1, U32>)(fst_0) -> (@+mid_2: U32 -> (@+kind_3: U32 -> (@+rare_4: U32 -> (@+x_5: U32 -> (@+y_6: U32 -> (@+hp_7: U32 -> (@+mhp_8: U32 -> (@+___9: U32 -> Sigma<&1, &1, U32, (__10 => List<&1, U32>)>))))))))))}; apply_450(fst_10, snd_11, mid_0, kind_1, rare_2, x_3, y_4, hp_5, mhp_6, C.Bq.word_and(C.Bq.bit(U32.is_eq(zone_7, z_8)), C.Bq.bit(U32.is_eq(dead_9, 0))))))); \{}})))))))))) : (@+mid_0: U32 -> (@+kind_1: U32 -> (@+rare_2: U32 -> (@+x_3: U32 -> (@+y_4: U32 -> (@+hp_5: U32 -> (@+mhp_6: U32 -> (@+zone_7: U32 -> (@+z_8: U32 -> (@+dead_9: U32 -> (@+___10: Sigma<&1, &1, U32, (__10 => List<&1, U32>)> -> Sigma<&1, &1, U32, (__11 => List<&1, U32>)>)))))))))))}; apply_449(mid_0, kind_1, rare_2, x_4, y_5, hp_6, mhp_7, zone_3, z_13, dead_10, Bq.snap_mobs(rest_12, z_13))))))))))))))))); \{}}; \{}}}

@unsafe
def Bq.snap_plrs():
  \{Nil: (z_0 => Tuple{0, Nil{}}); \{Con: \{P.Players.State: (pid_0 => (cid_1 => (hero_2 => \{P.Players.Pos: (zone_3 => (x_4 => (y_5 => (dir_6 => (moving_7 => (vit_8 => (style_9 => (qst_10 => (meta_11 => (rest_12 => (z_13 => (+apply_451 = {(hero_0 => (pid_1 => (x_2 => (y_3 => (dir_4 => (moving_5 => (style_6 => (vit_7 => (zone_8 => (z_9 => \{Tuple: (fst_10 => (snd_11 => (+apply_452 = {(fst_0 => (snd_1 => (hero_2 => (pid_3 => (x_4 => (y_5 => (dir_6 => (moving_7 => (style_8 => (vit_9 => (word => C.Bq.word_case(Sigma<&1, &1, U32, (__11 => List<&1, U32>)>, word, 0, (unit => Tuple{fst_0, snd_1}), (__10 => (+apply_453 = {(hero_0 => (fst_1 => (pid_2 => (x_3 => (y_4 => (dir_5 => (moving_6 => (snd_7 => (style_8 => \{V.Vitals.State: (hp_9 => (xp_10 => (dead_11 => (resp_12 => (atkcd_13 => (spincd_14 => (+apply_454 = {(hero_0 => (fst_1 => (pid_2 => (x_3 => (y_4 => (dir_5 => (moving_6 => (snd_7 => \{P.Players.Style: (skin_8 => (hairs_9 => (hairc_10 => (shirt_11 => (hat_12 => (cape_13 => (hp_14 => (xp_15 => (dead_16 => (resp_17 => (atkcd_18 => (spincd_19 => (_1680_20 => (+mh_21 = Bq.hero_maxhp(hero_0); (+lv_22 = Bq.hero_lv(hero_0); Tuple{(fst_1 + 1 : U32), Support.Bq.List.concat(U32, [pid_2, x_3, y_4, dir_5, moving_6, lv_22, hp_14, mh_21, skin_8, hairs_9, hairc_10, shirt_11, hat_12, cape_13, dead_16], snd_7)}))))))))))))))); \{}})))))))) : (@+hero_0: Game.Bq.Hero -> (@+fst_1: U32 -> (@+pid_2: U32 -> (@+x_3: U32 -> (@+y_4: U32 -> (@+dir_5: U32 -> (@+moving_6: U32 -> (@+snd_7: (__7 => List<&1, U32>)(fst_1) -> (@+___8: Bq.PStyle -> (@+__9: U32 -> (@+__10: U32 -> (@+__11: U32 -> (@+__12: U32 -> (@+__13: U32 -> (@+__14: U32 -> (@+__15: U32 -> Sigma<&1, &1, U32, (__16 => List<&1, U32>)>))))))))))))))))}; apply_454(hero_0, fst_1, pid_2, x_3, y_4, dir_5, moving_6, snd_7, style_8, hp_9, xp_10, dead_11, resp_12, atkcd_13, spincd_14)))))))); \{}}))))))))) : (@+hero_0: Game.Bq.Hero -> (@+fst_1: U32 -> (@+pid_2: U32 -> (@+x_3: U32 -> (@+y_4: U32 -> (@+dir_5: U32 -> (@+moving_6: U32 -> (@+snd_7: (__7 => List<&1, U32>)(fst_1) -> (@+style_8: Bq.PStyle -> (@+___9: Bq.Vit -> (@+__10: U32 -> Sigma<&1, &1, U32, (__11 => List<&1, U32>)>)))))))))))}; apply_453(hero_2, fst_0, pid_3, x_4, y_5, dir_6, moving_7, snd_1, style_8, vit_9, __10))), 0)))))))))))) : (@+fst_0: U32 -> (@+snd_1: (__1 => List<&1, U32>)(fst_0) -> (@+hero_2: Game.Bq.Hero -> (@+pid_3: U32 -> (@+x_4: U32 -> (@+y_5: U32 -> (@+dir_6: U32 -> (@+moving_7: U32 -> (@+style_8: Bq.PStyle -> (@+vit_9: Bq.Vit -> (@+___10: U32 -> Sigma<&1, &1, U32, (__11 => List<&1, U32>)>)))))))))))}; apply_452(fst_10, snd_11, hero_0, pid_1, x_2, y_3, dir_4, moving_5, style_6, vit_7, C.Bq.bit(U32.is_eq(zone_8, z_9)))))); \{}})))))))))) : (@+hero_0: Game.Bq.Hero -> (@+pid_1: U32 -> (@+x_2: U32 -> (@+y_3: U32 -> (@+dir_4: U32 -> (@+moving_5: U32 -> (@+style_6: Bq.PStyle -> (@+vit_7: Bq.Vit -> (@+zone_8: U32 -> (@+z_9: U32 -> (@+___10: Sigma<&1, &1, U32, (__10 => List<&1, U32>)> -> Sigma<&1, &1, U32, (__11 => List<&1, U32>)>)))))))))))}; apply_451(hero_2, pid_0, x_4, y_5, dir_6, moving_7, style_9, vit_8, zone_3, z_13, Bq.snap_plrs(rest_12, z_13)))))))))))))); \{}}))); \{}}; \{}}}

@unsafe
def Bq.snap_line():
  (plrs_0 => (mobs_1 => (tick_2 => (z_3 => (+apply_455 = {(tick_0 => (z_1 => (mobs_2 => \{Tuple: (fst_3 => (snd_4 => (+apply_456 = {(tick_0 => (z_1 => (fst_2 => (snd_3 => \{Tuple: (fst_4 => (snd_5 => Proto.Bq.wire_enc(C.Bq.text("SNAP"), Support.Bq.List.concat(U32, Support.Bq.List.concat(U32, [tick_0, z_1, fst_2], snd_3), Con{fst_4, snd_5}), Nil{}))); \{}})))) : (@+tick_0: U32 -> (@+z_1: U32 -> (@+fst_2: U32 -> (@+snd_3: (__3 => List<&1, U32>)(fst_2) -> (@+___4: Sigma<&1, &1, U32, (__4 => List<&1, U32>)> -> List<&1, Char>)))))}; apply_456(tick_0, z_1, fst_3, snd_4, Bq.snap_mobs(mobs_2, z_1))))); \{}}))) : (@+tick_0: U32 -> (@+z_1: U32 -> (@+mobs_2: List<&2, Bq.Mob> -> (@+___3: Sigma<&1, &1, U32, (__3 => List<&1, U32>)> -> List<&1, Char>))))}; apply_455(tick_2, z_3, mobs_1, Bq.snap_plrs(plrs_0, z_3)))))))

@unsafe
def Bq.hero_pts_of():
  \{Game.Bq.Hero.Hero: (inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => pts_10))))))))))); \{}}

@unsafe
def Bq.hero_str_u():
  \{Game.Bq.Hero.Hero: (inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => Support.Bq.Nat.to_u32(str_7)))))))))))); \{}}

@unsafe
def Bq.hero_agi_u():
  \{Game.Bq.Hero.Hero: (inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => Support.Bq.Nat.to_u32(agi_8)))))))))))); \{}}

@unsafe
def Bq.hero_vit_u():
  \{Game.Bq.Hero.Hero: (inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => Support.Bq.Nat.to_u32(vit_9)))))))))))); \{}}

@unsafe
def Bq.hero_wea_of():
  \{Game.Bq.Hero.Hero: (inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => wea_1))))))))))); \{}}

@unsafe
def Bq.hero_arm_of():
  \{Game.Bq.Hero.Hero: (inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => arm_2))))))))))); \{}}

@unsafe
def Bq.hero_hel_of():
  \{Game.Bq.Hero.Hero: (inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => hel_3))))))))))); \{}}

@unsafe
def Bq.hero_chm_of():
  \{Game.Bq.Hero.Hero: (inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => chm_4))))))))))); \{}}

@unsafe
def Bq.watk_of():
  \{Done: (k_0 => Support.Bq.Nat.to_u32(Game.Bq.iatk(k_0))); \{Fail: (u_0 => 1); \{}}}

@unsafe
def Bq.hero_watk():
  \{Game.Bq.Hero.Hero: (inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => (+base_11 = Bq.watk_of(wea_1); (base_11 + Data.Bq.charm_atk((Bq.slot_kind(chm_4) - 1 : U32)) : U32))))))))))))); \{}}

@unsafe
def Bq.df_of():
  \{Done: (k_0 => Support.Bq.Nat.to_u32(Game.Bq.idf(k_0))); \{Fail: (u_0 => 0); \{}}}

@unsafe
def Bq.hero_df():
  \{Game.Bq.Hero.Hero: (inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => ((Bq.df_of(arm_2) + Bq.df_of(hel_3) : U32) + Bq.df_of(chm_4) : U32)))))))))))); \{}}

@unsafe
def Bq.bag_counts():
  (b_0 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => Nil{}), (k2_1 => Con{Bq.bag_count(b_0, (18 - (1 + k2_1 : U32) : U32)), Bq.bag_counts(b_0, k2_1)}), 1)))

@unsafe
def Bq.hero_inv_counts():
  \{Game.Bq.Hero.Hero: (inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => Bq.bag_counts(inv_0, 18)))))))))))); \{}}

@unsafe
def Bq.me_line():
  \{P.Players.State: (pid_0 => (cid_1 => (hero_2 => (pos_3 => \{V.Vitals.State: (hp_4 => (xp_5 => (dead_6 => (resp_7 => (atkcd_8 => (spincd_9 => (style_10 => \{P.Players.Quest: (mainq_11 => (cull_12 => (sq0_13 => (sq1_14 => (sq2_15 => (sqdone_16 => \{P.Players.Meta: (score_17 => (kills_18 => (found_19 => (stored_name_20 => (sigils_21 => (phase_22 => (+name_20 = P.Players.text_name(stored_name_20); (+ns_23 = {[pid_0, hp_4, Bq.hero_maxhp(hero_2), xp_5, Data.Bq.xp_next(Bq.hero_lv(hero_2)), Bq.hero_gold_u(hero_2), Bq.hero_lv(hero_2), Support.Bq.Nat.to_u32(Bq.hero_pts_of(hero_2)), Bq.hero_str_u(hero_2), Bq.hero_agi_u(hero_2), Bq.hero_vit_u(hero_2), Bq.slot_kind(Bq.hero_wea_of(hero_2)), Bq.slot_kind(Bq.hero_arm_of(hero_2)), Bq.slot_kind(Bq.hero_hel_of(hero_2)), Bq.slot_kind(Bq.hero_chm_of(hero_2)), Bq.hero_pots(hero_2), mainq_11, cull_12, sq0_13, sq1_14, sq2_15, sqdone_16, sigils_21, score_17, spincd_9, Bq.hero_watk(hero_2), Bq.hero_df(hero_2), Bq.hero_crit(hero_2), phase_22] : List<&1, U32>}; Bq.OutL.To{cid_1, Proto.Bq.wire_enc(C.Bq.text("ME"), Support.Bq.List.concat(U32, ns_23, Bq.hero_inv_counts(hero_2)), Nil{})})))))))); \{}})))))); \{}}))))))); \{}})))); \{}}

@unsafe
def Bq.me_lines():
  \{Nil: (sigils_0 => (phase_1 => Nil{})); \{Con: (p_0 => (rest_1 => (sigils_2 => (phase_3 => Con{Bq.me_line(p_0, sigils_2, phase_3), Bq.me_lines(rest_1, sigils_2, phase_3)})))); \{}}}

@unsafe
def Bq.snap_outs():
  (plrs_0 => (mobs_1 => (tick_2 => (sigils_3 => (phase_4 => (+s0_5 = {[Bq.OutL.ZoneL{0, Bq.snap_line(plrs_0, mobs_1, tick_2, 0)}, Bq.OutL.ZoneL{1, Bq.snap_line(plrs_0, mobs_1, tick_2, 1)}, Bq.OutL.ZoneL{2, Bq.snap_line(plrs_0, mobs_1, tick_2, 2)}, Bq.OutL.ZoneL{3, Bq.snap_line(plrs_0, mobs_1, tick_2, 3)}] : List<&1, Bq.OutL>}; Support.Bq.List.concat(Bq.OutL, s0_5, Bq.me_lines(plrs_0, sigils_3, phase_4))))))))

@unsafe
def Bq.mob_hit(attack, hero):
  P.Players.mob_hit(attack, hero)

@unsafe
def Bq.player_event(+event: P.Players.Event, maps: List<&2,List<&2,U32>>) -> List<&1, Bq.OutL>:
  match event:
    case P.Players.Died{pid, cid, name}:
      Bq.evlog(Support.Bq.List.concat(Char, P.Players.text_name(name), C.Bq.text(" has fallen...")))
    case P.Players.Revived{pid, cid}:
      [Bq.OutL.To{cid, Bq.zone_line(maps, 0)}, Bq.OutL.To{cid, Proto.Bq.wire_enc(C.Bq.text("EV"), Nil{}, C.Bq.text("You awaken at the village..."))}]

@unsafe
def Bq.player_events(events: List<&2, P.Players.Event>, +maps: List<&2,List<&2,U32>>) -> List<&1, Bq.OutL>:
  match events:
    case Nil{}:
      Nil{}
    case Con{head, rest}:
      Support.Bq.List.concat(Bq.OutL, Bq.player_event(head, maps), Bq.player_events(rest, maps))

@unsafe
def Bq.player_step_result(step: P.Players.Step, maps: List<&2,List<&2,U32>>) -> C.Bq.Pair.Pair(Bq.Plr, (p => List<&1, Bq.OutL>)):
  match step:
    case P.Players.Step{player, event}:
      match event:
        case None{}:
          Tuple{player, Nil{}}
        case Some{event}:
          Tuple{player, Bq.player_event(event, maps)}

@unsafe
def Bq.player_result(result: P.Players.Result, maps: List<&2,List<&2,U32>>) -> C.Bq.Pair.Pair(List<&2, Bq.Plr>, (ps => List<&1, Bq.OutL>)):
  match result:
    case P.Players.Result{players, events}:
      Tuple{players, Bq.player_events(events, maps)}

@unsafe
def Bq.apply_one_hit(p: Bq.Plr, attack: U32) -> C.Bq.Pair.Pair(Bq.Plr, (p => List<&1, Bq.OutL>)):
  Bq.player_step_result(P.Players.hurt(p, attack, Data.Bq.RESPAWN_TICKS), Nil{})

@unsafe
def Bq.player_hits(hits: List<&1, C.Bq.Pair.Pair(U32, (pid => U32))>) -> List<&2, P.Players.Attack>:
  match hits:
    case Nil{}:
      Nil{}
    case Con{hit, rest}:
      match hit:
        case Tuple{pid, attack}:
          Con{P.Players.Attack{pid, attack}, Bq.player_hits(rest)}

@unsafe
def Bq.apply_hits(players, hits):
  Bq.player_result(P.Players.apply_hits(Bq.player_hits(hits), players, Data.Bq.RESPAWN_TICKS), Nil{})

@unsafe
def Bq.maw_upkeep():
  (kind_0 => (hp_1 => (mhp_2 => (+apply_468 = {(hp_0 => (mhp_1 => (word => C.Bq.word_case(U32, word, 0, (unit => hp_0), (_1421_2 => Health.Health.heal_word(hp_0, 30, mhp_1)), 0)))) : (@+hp_0: U32 -> (@+mhp_1: U32 -> (@+___2: U32 -> U32)))}; apply_468(hp_1, mhp_2, C.Bq.bit(U32.is_eq(kind_0, 9)))))))

@unsafe
def Bq.target_candidates(targets: List<&1,C.Bq.Pair.Pair(U32,(pid => C.Bq.Pair.Pair(U32,(x => U32))))>) -> Targeting.Targeting.Candidates:
  match targets:
    case Nil{}: Nil{}
    case Con{head,rest}:
      match head:
        case Tuple{pid,coords}:
          match coords:
            case Tuple{x,y}: Con{Targeting.Targeting.Candidate{pid,x,y},Bq.target_candidates(rest)}

@unsafe
def Bq.target_wire(candidates: Targeting.Targeting.Candidates) -> List<&1,C.Bq.Pair.Pair(U32,(pid => C.Bq.Pair.Pair(U32,(x => U32))))>:
  match candidates:
    case Nil{}: Nil{}
    case Con{head,rest}:
      match head:
        case Targeting.Targeting.Candidate{pid,x,y}: Con{Tuple{pid,Tuple{x,y}},Bq.target_wire(rest)}

@unsafe
def Bq.target_result(target: Pursuit.Pursuit.Target) -> C.Bq.Pair.Pair(U32,(pid => C.Bq.Pair.Pair(U32,(x => C.Bq.Pair.Pair(U32,(y => U32)))))):
  match target:
    case Pursuit.Pursuit.Target{pid,x,y,present}: Tuple{pid,Tuple{x,Tuple{y,C.Bq.bit(present)}}}

@unsafe
def Bq.target_position(found: Maybe<&2,Targeting.Targeting.Candidate>) -> Support.Bq.Maybe(C.Bq.Pair.Pair(U32,(x => U32))):
  match found:
    case None{}: Fail{Unit{}}
    case Some{candidate}:
      match candidate:
        case Targeting.Targeting.Candidate{pid,x,y}: Done{Tuple{x,y}}

@unsafe
def Bq.target_best(best: Targeting.Targeting.Best) -> C.Bq.Pair.Pair(U32,(pid => U32)):
  match best:
    case Targeting.Targeting.Best{pid,distance}: Tuple{pid,distance}

@unsafe
def Bq.tgt_pos(targets,pid): Bq.target_position(Targeting.Targeting.find(Bq.target_candidates(targets),pid))

@unsafe
def Bq.nearest_tgt(targets,x,y,best,distance): Bq.target_best(Targeting.Targeting.nearest(Bq.target_candidates(targets),x,y,Targeting.Targeting.Best{best,distance}))

@unsafe
def Bq.tgt_acquire(targets,x,y): Bq.target_result(Targeting.Targeting.acquire(Bq.target_candidates(targets),x,y))

@unsafe
def Bq.tgt_keep(targets,pid,x,y): Bq.target_result(Targeting.Targeting.keep(Bq.target_candidates(targets),pid,x,y))

@unsafe
def Bq.walk_dir(d): Terrain.Terrain.direction(d)

@unsafe
def Bq.terrain_xy(pos: P.Players.Pos) -> C.Bq.Pair.Pair(U32,(x => U32)):
  match pos:
    case P.Players.Pos{zone,x,y,heading,moving}: Tuple{x,y}

@unsafe
def Bq.move_plr_xy(maps,z,x,y,d):
  Bq.terrain_xy(Terrain.Terrain.move(maps,P.Players.Pos{z,x,y,d,1}))

@unsafe
def Bq.mob_move_xy(maps,z,x,y,d):
  Bq.terrain_xy(Terrain.Terrain.mob_move(maps,P.Players.Pos{z,x,y,d,1}))

@unsafe
def Bq.step_toward(maps,z,x,y,tx,ty):
  Bq.terrain_xy(Pursuit.Pursuit.toward(maps,P.Players.Pos{z,x,y,0,0},tx,ty))

def Bq.mob_atk_now(kind,hp,maximum): MD.MonsterDamage.current(kind,hp,maximum)

@unsafe
def Bq.ai_position(+monster: Bq.Mob, xy: C.Bq.Pair.Pair(U32, (x => U32))) -> C.Bq.Pair.Pair(Bq.Mob, (m => Support.Bq.Maybe(C.Bq.Pair.Pair(U32, (pid => U32))))) :
  match monster:
    case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      match xy:
        case Tuple{nx, ny}:
          Tuple{M.Monsters.aim(M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}, nx, ny, target, attack), Fail{Unit{}}}

@unsafe
def Bq.ai_wander(go: Bool, +monster: Bq.Mob, maps: List<&2,List<&2,U32>>, +tick: U32) -> C.Bq.Pair.Pair(Bq.Mob, (m => Support.Bq.Maybe(C.Bq.Pair.Pair(U32, (pid => U32))))) :
  match go:
    case False{}:
      Tuple{monster, Fail{Unit{}}}
    case True{}:
      match monster:
        case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
          Bq.ai_position(M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}, Bq.mob_move_xy(maps, zone, x, y, (Bq.hash2(tick, (mid * 5 : U32)) .&. 3 : U32)))

@unsafe
def Bq.ai_chase(go: Bool, +monster: Bq.Mob, +tx: U32, +ty: U32, maps: List<&2,List<&2,U32>>) -> C.Bq.Pair.Pair(Bq.Mob, (m => Support.Bq.Maybe(C.Bq.Pair.Pair(U32, (pid => U32))))) :
  match go:
    case False{}:
      Tuple{monster, Fail{Unit{}}}
    case True{}:
      match monster:
        case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
          Bq.ai_position(M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}, Bq.step_toward(maps, zone, x, y, tx, ty))

@unsafe
def Bq.ai_attack(ready: Bool, +monster: Bq.Mob) -> C.Bq.Pair.Pair(Bq.Mob, (m => Support.Bq.Maybe(C.Bq.Pair.Pair(U32, (pid => U32))))) :
  match ready:
    case False{}:
      Tuple{monster, Fail{Unit{}}}
    case True{}:
      match monster:
        case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
          Tuple{M.Monsters.aim(M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}, x, y, target, 9), Done{Tuple{target, (Bq.mob_atk_now(kind, hp, maximum) * (1 + rare : U32) : U32)}}}

@unsafe
def Bq.ai_adjacent(+monster: Bq.Mob, near: Bool, +tx: U32, +ty: U32, maps: List<&2,List<&2,U32>>, +tick: U32) -> C.Bq.Pair.Pair(Bq.Mob, (m => Support.Bq.Maybe(C.Bq.Pair.Pair(U32, (pid => U32))))) :
  match monster:
    case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      match near:
        case True{}:
          Bq.ai_attack(U32.is_eq(attack, 0), M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn})
        case False{}:
          Bq.ai_chase(U32.is_eq(((tick + mid : U32) .&. 1 : U32), 0), M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}, tx, ty, maps)

@unsafe
def Bq.ai_target_gate(+monster: Bq.Mob, has: Bool, +tx: U32, +ty: U32, maps: List<&2,List<&2,U32>>, +tick: U32) -> C.Bq.Pair.Pair(Bq.Mob, (m => Support.Bq.Maybe(C.Bq.Pair.Pair(U32, (pid => U32))))) :
  match monster:
    case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      match has:
        case False{}:
          Bq.ai_wander(U32.is_eq(((tick + mid : U32) .&. 7 : U32), 0), M.Monsters.aim(M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}, x, y, 0, attack), maps, tick)
        case True{}:
          Bq.ai_adjacent(M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}, U32.is_le(Bq.chdist(x, y, tx, ty), 1), tx, ty, maps, tick)

@unsafe
def Bq.ai_target(+monster: Bq.Mob, current: C.Bq.Pair.Pair(U32, (pid => C.Bq.Pair.Pair(U32, (x => C.Bq.Pair.Pair(U32, (y => U32)))))), maps: List<&2,List<&2,U32>>, +tick: U32) -> C.Bq.Pair.Pair(Bq.Mob, (m => Support.Bq.Maybe(C.Bq.Pair.Pair(U32, (pid => U32))))) :
  match monster:
    case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
      match current:
        case Tuple{next_target, rest}:
          match rest:
            case Tuple{tx, tail}:
              match tail:
                case Tuple{ty, has}:
                  Bq.ai_target_gate(M.Monsters.aim(M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}, x, y, next_target, attack), U32.is_ne(has, 0), tx, ty, maps, tick)

@unsafe
def Bq.ai_active_plan(result: C.Bq.Pair.Pair(Bq.Mob, (m => Support.Bq.Maybe(C.Bq.Pair.Pair(U32, (pid => U32)))))) -> A.AI.Plan:
  match result:
    case Tuple{monster, hit}:
      match monster:
        case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, respawn}:
          match hit:
            case Fail{unit}:
              A.AI.Move{x, y, target}
            case Done{pair}:
              match pair:
                case Tuple{pid, damage}:
                  A.AI.Attack{pid, damage}

@unsafe
def Bq.ai_spawn_plan(monster: Bq.Mob) -> A.AI.Plan: Pop.Population.spawn_plan(monster)

@unsafe
def Bq.pursuit_target(current: C.Bq.Pair.Pair(U32,(pid => C.Bq.Pair.Pair(U32,(x => C.Bq.Pair.Pair(U32,(y => U32))))))) -> Pursuit.Pursuit.Target:
  match current:
    case Tuple{pid,rest}:
      match rest:
        case Tuple{x,tail}:
          match tail:
            case Tuple{y,has}: Pursuit.Pursuit.Target{pid,x,y,U32.is_ne(has,0)}

def Bq.ai_damage(monster: M.Monsters.State) -> U32: MD.MonsterDamage.amount(monster)

def Bq.ai_damages(monsters: List<&2,M.Monsters.State>) -> List<&2,U32>: MD.MonsterDamage.list(monsters)

@unsafe
def Bq.ai_context_data(+result: M.Monsters.Tick,candidates: Targeting.Targeting.Candidates) -> Plan.Planning.Context:
  Targeting.Targeting.context(result,candidates,Bq.ai_damage(M.Monsters.tick_state(result)))

@unsafe
def Bq.ai_contexts_data(+monsters: List<&2,Bq.Mob>,candidates: Targeting.Targeting.Candidates) -> List<&2,Plan.Planning.Context>:
  Targeting.Targeting.contexts(monsters,candidates,Bq.ai_damages(monsters))

@unsafe
def Bq.ai_context_tick(result: M.Monsters.Tick,targets: List<&1,C.Bq.Pair.Pair(U32,(pid => C.Bq.Pair.Pair(U32,(x => U32))))>) -> Plan.Planning.Context:
  Bq.ai_context_data(result,Bq.target_candidates(targets))

@unsafe
def Bq.ai_contexts(monsters: List<&2,Bq.Mob>,targets: List<&1,C.Bq.Pair.Pair(U32,(pid => C.Bq.Pair.Pair(U32,(x => U32))))>) -> List<&2,Plan.Planning.Context>:
  Bq.ai_contexts_data(monsters,Bq.target_candidates(targets))

@unsafe
def Bq.ai_plan_tick(+result: M.Monsters.Tick, targets: List<&1, C.Bq.Pair.Pair(U32, (pid => C.Bq.Pair.Pair(U32, (x => U32))))>, maps: List<&2,List<&2,U32>>, tick: U32) -> A.AI.Plan:
  Plan.Planning.tick_plan(result,maps,Bq.ai_context_tick(result,targets),tick)

@unsafe
def Bq.ai_plan(m: Bq.Mob, ts: List<&1, C.Bq.Pair.Pair(U32, (pid => C.Bq.Pair.Pair(U32, (x => U32))))>, maps: List<&2,List<&2,U32>>, tick: U32) -> A.AI.Plan:
  Bq.ai_plan_tick(M.Monsters.tick(m), ts, maps, tick)

@unsafe
def Bq.ai_plans(+ms: List<&2, Bq.Mob>, ts: List<&1, C.Bq.Pair.Pair(U32, (pid => C.Bq.Pair.Pair(U32, (x => U32))))>, maps: List<&2,List<&2,U32>>, tick: U32) -> List<&2, A.AI.Plan>:
  Plan.Planning.plans(ms,Bq.ai_contexts(ms,ts),maps,tick)

@unsafe
def Bq.ai_single_result(result: A.AI.Step) -> C.Bq.Pair.Pair(Bq.Mob, (m => Support.Bq.Maybe(C.Bq.Pair.Pair(U32, (pid => U32))))) :
  match result:
    case A.AI.Step{monster, hit}:
      match hit:
        case None{}:
          Tuple{monster, Fail{Unit{}}}
        case Some{hit}:
          match hit:
            case A.AI.Hit{pid, damage}:
              Tuple{monster, Done{Tuple{pid, damage}}}

@unsafe
def Bq.ai_hits(hits: List<&2, A.AI.Hit>) -> List<&1, C.Bq.Pair.Pair(U32, (pid => U32))>:
  match hits:
    case Nil{}:
      Nil{}
    case Con{hit, rest}:
      match hit:
        case A.AI.Hit{pid, damage}:
          Con{Tuple{pid, damage}, Bq.ai_hits(rest)}

@unsafe
def Bq.ai_list_result(result: A.AI.Result) -> C.Bq.Pair.Pair(List<&2, Bq.Mob>, (ms => List<&1, C.Bq.Pair.Pair(U32, (pid => U32))>)):
  match result:
    case A.AI.Result{monsters, hits}:
      Tuple{monsters, Bq.ai_hits(hits)}

@unsafe
def Bq.ai_mob(m, ts, maps, tick):
  Bq.ai_single_result(A.AI.step(m, Bq.ai_plan(m, ts, maps, tick)))

@unsafe
def Bq.ai_zone(ms, ts, maps, tick):
  Bq.ai_list_result(A.AI.run(ms, Bq.ai_plans(ms, ts, maps, tick)))

@unsafe
def Bq.mobs_of_zone(ms, zone):
  R.Roster.zone(ms, zone)

@unsafe
def Bq.plr_targets(players,zone): Bq.target_wire(Targeting.Targeting.filter(players,zone))

@unsafe
def Bq.tick_mobs(mobs, plrs, maps, tick):
  p0 p1 p2 p3 = Bq.ai_plans(R.Roster.zone(mobs, 0), Bq.plr_targets(plrs, 0), maps, tick) Bq.ai_plans(R.Roster.zone(mobs, 1), Bq.plr_targets(plrs, 1), maps, tick) Bq.ai_plans(R.Roster.zone(mobs, 2), Bq.plr_targets(plrs, 2), maps, tick) Bq.ai_plans(R.Roster.zone(mobs, 3), Bq.plr_targets(plrs, 3), maps, tick)
  Bq.ai_list_result(A.AI.run_zones(mobs, p0, p1, p2, p3))

@unsafe
def Bq.walk_if(maps,z,x,y,d,moving):
  Bq.terrain_xy(Terrain.Terrain.walk_if(maps,P.Players.Pos{z,x,y,d,moving}))

@unsafe
def Bq.player_xy_plan(xy: C.Bq.Pair.Pair(U32, (x => U32))) -> P.Players.Plan:
  match xy:
    case Tuple{nx, ny}:
      P.Players.Walk{nx, ny}

@unsafe
def Bq.upkeep_plan(player: Bq.Plr, maps: List<&2,List<&2,U32>>) -> P.Players.Plan:
  L.Locomotion.plan(maps,player)

@unsafe
def Bq.upkeep_plans(players: List<&2, Bq.Plr>, +maps: List<&2,List<&2,U32>>) -> List<&2, P.Players.Plan>:
  L.Locomotion.plans(players,maps)

@unsafe
def Bq.upkeep_plr(p, maps, tick):
  Bq.player_step_result(P.Players.upkeep(p, Bq.upkeep_plan(p, maps), tick, Data.Bq.SPAWN_X, Data.Bq.SPAWN_Y), maps)

@unsafe
def Bq.upkeep_all(players, maps, tick):
  Bq.player_result(P.Players.upkeep_all(players, Bq.upkeep_plans(players, maps), tick, Data.Bq.SPAWN_X, Data.Bq.SPAWN_Y), maps)

@unsafe
def Bq.simulation_rules() -> S.Simulation.Rules:
  Plan.Planning.rules(Data.Bq.RESPAWN_TICKS)

# The formatter returns only messages; LiveTick.emit retains the checked world.
@unsafe
def Bq.render_tick(result: Tick.LiveTick.Result) -> List<&1,Bq.OutL>:
  match result:
    case Tick.LiveTick.Result{world,events,clock}:
      match world:
        case Terrain.Terrain.World{meta,players,monsters,maps}:
          +meta = meta
          Support.Bq.List.concat(Bq.OutL,Bq.player_events(events,maps),Bq.snap_outs(players,monsters,clock,Bq.wm_sigils(meta),S.Simulation.phase(meta)))

@unsafe
def Bq.tick_result(result: S.Simulation.Result,maps: Terrain.Terrain.Maps,tick: U32) -> C.Bq.Pair.Pair(Bq.World,(world => List<&1,Bq.OutL>)):
  Tick.LiveTick.emit(Bq.OutL,Tick.LiveTick.pack(result,maps,tick),Bq.render_tick)

@unsafe
def Bq.tick_finish(prepared: S.Simulation.Prepared,maps: Terrain.Terrain.Maps,rules: S.Simulation.Rules) -> C.Bq.Pair.Pair(Bq.World,(world => List<&1,Bq.OutL>)):
  Tick.LiveTick.emit(Bq.OutL,Tick.LiveTick.finish(prepared,maps,rules),Bq.render_tick)

@unsafe
def Bq.tick_player_plans(running: Bool, players: List<&2, Bq.Plr>, maps: List<&2,List<&2,U32>>) -> List<&2, P.Players.Plan>:
  L.Locomotion.tick_plans(running,players,maps)

@unsafe
def Bq.tick_world(world): Tick.LiveTick.emit(Bq.OutL,Tick.LiveTick.run(world,Data.Bq.RESPAWN_TICKS),Bq.render_tick)


# Legacy formatting returns only lines; the safe adapter retains the world.
