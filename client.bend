# Bendquest client. Current Bend syntax; see README.md for the port notes.
import Base
import ./compat.bend as C
import ./ior.bend as Ior
import ./support.bend as Support
import ./sprites.bend as Sprites
import ./world.bend as World
import ./proto.bend as Proto
import ./server.bend as Server
import ./raylib.bend as Raylib
import ./data.bend as Data
import ./game.bend as Game

law Bq.tri:
  (@+t_0: U32 -> U32)

law Bq.aurora_px:
  (@+x_0: U32 -> (@+y_1: U32 -> List<&1, U32>))

law Bq.aurora_row:
  (@+x_0: U32 -> (@+y_1: U32 -> List<&1, U32>))

law Bq.aurora_rows:
  (@+d_0: U32 -> (@+y_1: U32 -> List<&1, U32>))

law Bq.aurora_bytes:
  C.Bq.Bytes

law Bq.sq_sample:
  (@+i_0: U32 -> (@+period_1: U32 -> (@+amp_2: U32 -> U32)))

law Bq.synth_go:
  (@+n_0: U32 -> (@+len_1: U32 -> (@+p0_2: U32 -> (@+p1_3: U32 -> List<&1, U32>))))

law Bq.snd_hit_bytes:
  C.Bq.Bytes

law Bq.snd_lvl_bytes:
  C.Bq.Bytes

law Bq.auto_mode:
  IO(U32)

type Bq.Form is Type:
  Bq.Form.Form{focus_0: U32, f_ip_1: C.Bq.String, f_port_2: C.Bq.String, f_name_3: C.Bq.String, err_4: C.Bq.String}

type Bq.Net is Type:
  Bq.Net.Net{net_on_0: U32, sock_1: C.Bq.TCP, hosting_2: U32, hostaddr_3: C.Bq.String, hostlog_4: List<&1, C.Bq.String>, hoststat_5: C.Bq.String}

type Bq.FameP is Type:
  Bq.FameP.FameP{name_0: C.Bq.String, lv_1: U32, score_2: U32, skin_3: U32, hairs_4: U32, hairc_5: U32, shirt_6: U32, hat_7: U32, cape_8: U32, wea_9: U32, arm_10: U32, hel_11: U32, chm_12: U32}

type Bq.FameR is Type:
  Bq.FameR.FameR{no_0: U32, dur_1: U32, fps_2: List<&1, Bq.FameP>}

type Bq.OverE is Type:
  Bq.OverE.OverE{rank_0: U32, score_1: U32, coins_2: U32, name_3: C.Bq.String}

type Bq.Acct is Type:
  Bq.Acct.Acct{coins_0: U32, ownh_1: U32, ownc_2: U32, wno_3: U32, phase_4: U32, fame_5: List<&1, Bq.FameR>, over_6: List<&1, Bq.OverE>}

type Bq.Look is Type:
  Bq.Look.Look{skin_0: U32, hairs_1: U32, hairc_2: U32, shirt_3: U32, hat_4: U32, cape_5: U32}

type Bq.PVs is Type:
  Bq.PVs.PVs{lv_0: U32, hp_1: U32, mhp_2: U32, dead_3: U32}

type Bq.PV is Type:
  Bq.PV.PV{pid_0: U32, x_1: U32, y_2: U32, px_3: U32, py_4: U32, dir_5: U32, moving_6: U32, st_7: Bq.PVs, lk_8: Bq.Look}

type Bq.MV is Type:
  Bq.MV.MV{mid_0: U32, kind_1: U32, rare_2: U32, x_3: U32, y_4: U32, px_5: U32, py_6: U32, hp_7: U32, mhp_8: U32}

type Bq.NameE is Type:
  Bq.NameE.NameE{pid_0: U32, name_1: C.Bq.String}

type Bq.Bub is Type:
  Bq.Bub.Bub{pid_0: U32, text_1: C.Bq.String, ttl_2: U32}

type Bq.FXV is Type:
  Bq.FXV.FXV{kind_0: U32, x_1: U32, y_2: U32, ttl_3: U32}

type Bq.Wv is Type:
  Bq.Wv.Wv{mypid_0: U32, zid_1: U32, grid_2: List<&1, U32>, plist_3: List<&1, Bq.PV>, mlist_4: List<&1, Bq.MV>, names_5: List<&1, Bq.NameE>, me_6: List<&1, U32>, snapms_7: U32, evl_8: List<&1, C.Bq.String>, bubs_9: List<&1, Bq.Bub>, fxs_10: List<&1, Bq.FXV>}

type Bq.Ui is Type:
  Bq.Ui.Ui{inv_open_0: U32, quest_open_1: U32, shop_open_2: U32, dash_open_3: U32, fame_open_4: U32, chat_open_5: U32, chatbuf_6: C.Bq.String, move_sent_7: U32}

type Bq.CS is Type:
  Bq.CS.CS{scene_0: U32, quitting_1: U32, form_2: Bq.Form, net_3: Bq.Net, acct_4: Bq.Acct, look_5: Bq.Look, wv_6: Bq.Wv, ui_7: Bq.Ui}

law Bq.cs_set_name:
  (@+cs_0: Bq.CS -> (@+v_1: C.Bq.String -> Bq.CS))

law Bq.name_override:
  (@+cs_0: Bq.CS -> IO(Bq.CS))

law Bq.cs0:
  Bq.CS

law Bq.auto_press:
  (@+k_0: U32 -> List<&1, U32>)

law Bq.auto_click:
  (@+x_0: U32 -> (@+y_1: U32 -> List<&1, U32>))

law Bq.auto_hold:
  (@+mask_0: U32 -> List<&1, U32>)

law Bq.menu_key:
  (@+mode_0: U32 -> U32)

law Bq.rift_words:
  (@+fn_0: U32 -> List<&1, U32>)

law Bq.auto_words:
  (@+mode_0: U32 -> (@+fn_1: U32 -> List<&1, U32>))

law Bq.auto_pick:
  (@+mode_0: U32 -> (@+fn_1: U32 -> (@+real_2: List<&1, U32> -> List<&1, U32>)))

law Bq.send_line:
  (@+fd_0: U32 -> (@+line_1: C.Bq.String -> IO(Unit)))

law Bq.cs_net:
  (@+cs_0: Bq.CS -> Bq.Net)

law Bq.cs_netinfo:
  (@+cs_0: Bq.CS -> C.Bq.Pair.Pair(U32, (__1 => U32)))

law Bq.send_wire:
  (@+cs_0: Bq.CS -> (@+l_1: C.Bq.String -> IO(Bq.CS)))

law Bq.cs_scene:
  (@+cs_0: Bq.CS -> (@+v_1: U32 -> Bq.CS))

law Bq.cs_unhost:
  (@+cs_0: Bq.CS -> Bq.CS)

law Bq.cs_hostaddr:
  (@+cs_0: Bq.CS -> C.Bq.String)

law Bq.local_ip:
  IO(C.Bq.String)

law Bq.cs_set_hosting:
  (@+cs_0: Bq.CS -> (@+addr_1: C.Bq.String -> Bq.CS))

law Bq.cs_read:
  (@+cs_0: Bq.CS -> C.Bq.Pair.Pair(U32, (__1 => C.Bq.Pair.Pair(U32, (__2 => C.Bq.Pair.Pair(C.Bq.String, (__3 => C.Bq.Pair.Pair(C.Bq.String, (__4 => C.Bq.String)))))))))

law Bq.try_host:
  (@+cs_0: Bq.CS -> (@+lg_1: Chan<C.Bq.String> -> (@+ctl_2: Chan<U32> -> (@+stat_3: Chan<C.Bq.String> -> IO(Bq.CS)))))

law Bq.dial_verdict:
  (@+r_0: Result<&1, &1, C.Bq.Pair.Pair(U32, (__0 => C.Bq.String)), Result<&1, &1, C.Bq.Pair.Pair(U32, (__0 => C.Bq.String)), C.Bq.TCP>> -> Result<&1, &1, C.Bq.String, C.Bq.TCP>)

law Bq.dial:
  (@+host_0: C.Bq.String -> (@+port_1: U32 -> Ior.Bq.IOR(C.Bq.String, C.Bq.TCP)))

law Bq.push_all:
  (@+rx_0: Chan<C.Bq.String> -> (@+ls_1: List<&1, C.Bq.String> -> IO(Unit)))

law Bq.cl_reader:
  (@+fuel_0: U32 -> (@+sock_1: C.Bq.TCP -> (@+rx_2: Chan<C.Bq.String> -> (@+buf_3: C.Bq.String -> IO(Unit)))))

law Bq.start_net:
  (@+rx_0: Chan<C.Bq.String> -> (@+host_1: C.Bq.String -> (@+port_2: U32 -> (@+name_3: C.Bq.String -> Ior.Bq.IOR(C.Bq.String, C.Bq.TCP)))))

law Bq.cs_err:
  (@+cs_0: Bq.CS -> (@+msg_1: C.Bq.String -> Bq.CS))

law Bq.cs_set_net:
  (@+cs_0: Bq.CS -> (@+nsock_1: C.Bq.TCP -> Bq.CS))

law Bq.connect_verdict:
  (@+cs_0: Bq.CS -> (@+r_1: Result<&1, &1, C.Bq.String, C.Bq.TCP> -> Bq.CS))

law Bq.connect_now:
  (@+cs_0: Bq.CS -> (@+rx_1: Chan<C.Bq.String> -> (@+host_2: C.Bq.String -> (@+port_3: U32 -> (@+name_4: C.Bq.String -> IO(Bq.CS))))))

law Bq.try_connect:
  (@+cs_0: Bq.CS -> (@+rx_1: Chan<C.Bq.String> -> IO(Bq.CS)))

law Bq.do_action:
  (@+cs_0: Bq.CS -> (@+l_1: C.Bq.String -> (@+rx_2: Chan<C.Bq.String> -> (@+lg_3: Chan<C.Bq.String> -> (@+ctl_4: Chan<U32> -> (@+stat_5: Chan<C.Bq.String> -> IO(Bq.CS)))))))

law Bq.do_actions:
  (@+cs_0: Bq.CS -> (@+ls_1: List<&1, C.Bq.String> -> (@+rx_2: Chan<C.Bq.String> -> (@+lg_3: Chan<C.Bq.String> -> (@+ctl_4: Chan<U32> -> (@+stat_5: Chan<C.Bq.String> -> IO(Bq.CS)))))))

law Bq.fame_add_fp:
  (@+fs_0: List<&1, Bq.FameR> -> (@+f_1: Bq.FameP -> List<&1, Bq.FameR>))

law Bq.srv_fp:
  (@+cs_0: Bq.CS -> (@+ns_1: List<&1, U32> -> (@+text_2: C.Bq.String -> Bq.CS)))

law Bq.fame_add_run:
  (@+fs_0: List<&1, Bq.FameR> -> (@+no_1: U32 -> (@+dur_2: U32 -> List<&1, Bq.FameR>)))

law Bq.srv_frun:
  (@+cs_0: Bq.CS -> (@+ns_1: List<&1, U32> -> Bq.CS))

law Bq.srv_fameb:
  (@+cs_0: Bq.CS -> Bq.CS)

law Bq.push_ev:
  (@+evl_0: List<&1, C.Bq.String> -> (@+s_1: C.Bq.String -> List<&1, C.Bq.String>))

law Bq.srv_start:
  (@+cs_0: Bq.CS -> (@+ns_1: List<&1, U32> -> Bq.CS))

law Bq.srv_over:
  (@+cs_0: Bq.CS -> (@+ns_1: List<&1, U32> -> (@+text_2: C.Bq.String -> Bq.CS)))

law Bq.srv_fx:
  (@+cs_0: Bq.CS -> (@+ns_1: List<&1, U32> -> Bq.CS))

law Bq.srv_bubble:
  (@+cs_0: Bq.CS -> (@+ns_1: List<&1, U32> -> (@+text_2: C.Bq.String -> Bq.CS)))

law Bq.srv_ev:
  (@+cs_0: Bq.CS -> (@+text_1: C.Bq.String -> Bq.CS))

law Bq.name_put:
  (@+ns_0: List<&1, Bq.NameE> -> (@+pid_1: U32 -> (@+name_2: C.Bq.String -> List<&1, Bq.NameE>)))

law Bq.srv_plr:
  (@+cs_0: Bq.CS -> (@+ns_1: List<&1, U32> -> (@+text_2: C.Bq.String -> Bq.CS)))

law Bq.ME_PHASE:
  U32

law Bq.srv_me:
  (@+cs_0: Bq.CS -> (@+ns_1: List<&1, U32> -> Bq.CS))

law Bq.mv_find:
  (@+ms_0: List<&1, Bq.MV> -> (@+mid_1: U32 -> Support.Bq.Maybe(C.Bq.Pair.Pair(U32, (__2 => U32)))))

law Bq.prev_or:
  (@+m_0: Support.Bq.Maybe(C.Bq.Pair.Pair(U32, (__0 => U32))) -> (@+x_1: U32 -> (@+y_2: U32 -> C.Bq.Pair.Pair(U32, (__3 => U32)))))

law Bq.snap_mvs:
  (@+ns_0: List<&1, U32> -> (@+n_1: U32 -> (@+old_2: List<&1, Bq.MV> -> List<&1, Bq.MV>)))

law Bq.pv_find:
  (@+ps_0: List<&1, Bq.PV> -> (@+pid_1: U32 -> Support.Bq.Maybe(C.Bq.Pair.Pair(U32, (__2 => U32)))))

law Bq.snap_pvs:
  (@+ns_0: List<&1, U32> -> (@+n_1: U32 -> (@+old_2: List<&1, Bq.PV> -> C.Bq.Pair.Pair(List<&1, Bq.PV>, (__3 => List<&1, U32>)))))

law Bq.srv_snap:
  (@+cs_0: Bq.CS -> (@+ns_1: List<&1, U32> -> (@+now_2: U32 -> Bq.CS)))

law Bq.hexval:
  (@+c_0: U32 -> U32)

law Bq.grid_of:
  (@+s_0: C.Bq.String -> List<&1, U32>)

law Bq.srv_zone:
  (@+cs_0: Bq.CS -> (@+ns_1: List<&1, U32> -> (@+text_2: C.Bq.String -> Bq.CS)))

law Bq.srv_discon:
  (@+cs_0: Bq.CS -> Bq.CS)

law Bq.srv_err:
  (@+cs_0: Bq.CS -> (@+text_1: C.Bq.String -> Bq.CS))

law Bq.scene_after_welcome:
  (@+scene_0: U32 -> U32)

law Bq.srv_welcome:
  (@+cs_0: Bq.CS -> (@+ns_1: List<&1, U32> -> Bq.CS))

law Bq.apply_srv:
  (@+cs_0: Bq.CS -> (@+now_1: U32 -> (@+line_2: C.Bq.String -> Bq.CS)))

law Bq.drain_rx:
  (@+cs_0: Bq.CS -> (@+rx_1: Chan<C.Bq.String> -> (@+k_2: U32 -> (@+now_3: U32 -> IO(Bq.CS)))))

law Bq.cs_hostlog:
  (@+cs_0: Bq.CS -> (@+line_1: C.Bq.String -> Bq.CS))

law Bq.drain_hlog:
  (@+cs_0: Bq.CS -> (@+lg_1: Chan<C.Bq.String> -> (@+k_2: U32 -> IO(Bq.CS))))

law Bq.cs_hoststat:
  (@+cs_0: Bq.CS -> (@+v_1: C.Bq.String -> Bq.CS))

law Bq.drain_stat:
  (@+cs_0: Bq.CS -> (@+stat_1: Chan<C.Bq.String> -> (@+k_2: U32 -> IO(Bq.CS))))

law Bq.bub_decay:
  (@+bs_0: List<&1, Bq.Bub> -> List<&1, Bq.Bub>)

law Bq.fx_decay:
  (@+fs_0: List<&1, Bq.FXV> -> List<&1, Bq.FXV>)

law Bq.cs_decay:
  (@+cs_0: Bq.CS -> Bq.CS)

law Bq.spr:
  (@+tex_0: U32 -> (@+fi_1: U32 -> (@+fw_2: U32 -> (@+fh_3: U32 -> (@+x_4: U32 -> (@+y_5: U32 -> (@+sc_6: U32 -> (@+flip_7: U32 -> (@+tint_8: U32 -> List<&1, U32>)))))))))

law Bq.tile_row_cmds:
  (@+a_tiles_0: U32 -> (@+row_1: List<&1, U32> -> (@+y_2: U32 -> (@+x_3: U32 -> List<&1, U32>))))

law Bq.grid_row:
  (@+grid_0: List<&1, U32> -> (@+y_1: U32 -> List<&1, U32>))

law Bq.tile_band:
  (@+a_tiles_0: U32 -> (@+grid_1: List<&1, U32> -> (@+y0_2: U32 -> (@+n_3: U32 -> List<&1, U32>))))

law Bq.tiles_cmds:
  (@+a_tiles_0: U32 -> (@+grid_1: List<&1, U32> -> List<&1, U32>))

law Bq.text_cmd:
  (@+x_0: U32 -> (@+y_1: U32 -> (@+size_2: U32 -> (@+color_3: U32 -> (@+s_4: C.Bq.String -> List<&1, U32>)))))

law Bq.npc_cmds:
  (@+a_0: Sprites.Bq.Assets -> (@+zid_1: U32 -> List<&1, U32>))

law Bq.lerp_px:
  (@+prev_0: U32 -> (@+cur_1: U32 -> (@+a_2: U32 -> U32)))

law Bq.rare_tint:
  (@+rare_0: U32 -> U32)

law Bq.mob_tex:
  (@+a_0: Sprites.Bq.Assets -> (@+kind_1: U32 -> U32))

law Bq.mob_body:
  (@+a_0: Sprites.Bq.Assets -> (@+kind_1: U32 -> (@+big_2: U32 -> (@+sx_3: U32 -> (@+sy_4: U32 -> (@+f_5: U32 -> (@+tint_6: U32 -> List<&1, U32>)))))))

law Bq.rect:
  (@+x_0: U32 -> (@+y_1: U32 -> (@+w_2: U32 -> (@+h_3: U32 -> (@+c_4: U32 -> List<&1, U32>)))))

law Bq.bar:
  (@+x_0: U32 -> (@+y_1: U32 -> (@+w_2: U32 -> (@+h_3: U32 -> (@+val_4: U32 -> (@+max_5: U32 -> (@+fg_6: U32 -> (@+bg_7: U32 -> List<&1, U32>))))))))

law Bq.mob_cmds:
  (@+a_0: Sprites.Bq.Assets -> (@+ms_1: List<&1, Bq.MV> -> (@+alpha_2: U32 -> (@+f_3: U32 -> List<&1, U32>))))

law Bq.walk_frame:
  (@+moving_0: U32 -> (@+tms_1: U32 -> U32))

law Bq.name_of:
  (@+ns_0: List<&1, Bq.NameE> -> (@+pid_1: U32 -> C.Bq.String))

law Bq.cape_part:
  (@+a_0: Sprites.Bq.Assets -> (@+x_1: U32 -> (@+y_2: U32 -> (@+f_3: U32 -> (@+sc_4: U32 -> (@+flip_5: U32 -> (@+cape_6: U32 -> List<&1, U32>)))))))

law Bq.hat_part:
  (@+a_0: Sprites.Bq.Assets -> (@+x_1: U32 -> (@+y_2: U32 -> (@+f_3: U32 -> (@+sc_4: U32 -> (@+flip_5: U32 -> (@+hat_6: U32 -> List<&1, U32>)))))))

law Bq.char_cmds:
  (@+a_0: Sprites.Bq.Assets -> (@+x_1: U32 -> (@+y_2: U32 -> (@+f_3: U32 -> (@+sc_4: U32 -> (@+flip_5: U32 -> (@+skin_6: U32 -> (@+hairs_7: U32 -> (@+hairc_8: U32 -> (@+shirt_9: U32 -> (@+hat_10: U32 -> (@+cape_11: U32 -> List<&1, U32>))))))))))))

law Bq.name_col:
  (@+mine_0: U32 -> U32)

law Bq.dead_cmds:
  (@+dead_0: U32 -> (@+sx_1: U32 -> (@+sy_2: U32 -> List<&1, U32>)))

law Bq.plr_cmds:
  (@+a_0: Sprites.Bq.Assets -> (@+ps_1: List<&1, Bq.PV> -> (@+names_2: List<&1, Bq.NameE> -> (@+mypid_3: U32 -> (@+alpha_4: U32 -> (@+tms_5: U32 -> List<&1, U32>))))))

law Bq.fx_tex:
  (@+slash_0: U32 -> (@+spark_1: U32 -> (@+kind_2: U32 -> U32)))

law Bq.fx_tint:
  (@+kind_0: U32 -> U32)

law Bq.fx_cmds_go:
  (@+slash_0: U32 -> (@+spark_1: U32 -> (@+fs_2: List<&1, Bq.FXV> -> List<&1, U32>)))

law Bq.assets_fx:
  (@+a_0: Sprites.Bq.Assets -> C.Bq.Pair.Pair(U32, (__1 => U32)))

law Bq.fx_cmds:
  (@+a_0: Sprites.Bq.Assets -> (@+fs_1: List<&1, Bq.FXV> -> List<&1, U32>))

law Bq.snd_pick:
  (@+hit_0: U32 -> (@+lvl_1: U32 -> (@+kind_2: U32 -> U32)))

law Bq.fx_snd:
  (@+hit_0: U32 -> (@+lvl_1: U32 -> (@+fs_2: List<&1, Bq.FXV> -> List<&1, U32>)))

law Bq.bub_cmds:
  (@+bs_0: List<&1, Bq.Bub> -> (@+ps_1: List<&1, Bq.PV> -> (@+alpha_2: U32 -> List<&1, U32>)))

law Bq.world_cmds:
  (@+a_0: Sprites.Bq.Assets -> (@+wv_1: Bq.Wv -> (@+tms_2: U32 -> (@+snds_3: C.Bq.Pair.Pair(U32, (__3 => U32)) -> List<&1, U32>))))

law Bq.cs_wv:
  (@+cs_0: Bq.CS -> Bq.Wv)

law Bq.cs_me:
  (@+cs_0: Bq.CS -> List<&1, U32>)

law Bq.meg:
  (@+me_0: List<&1, U32> -> (@+i_1: U32 -> U32))

law Bq.ME_HP:
  U32

law Bq.ME_MHP:
  U32

law Bq.ME_XP:
  U32

law Bq.ME_XPN:
  U32

law Bq.ME_LV:
  U32

law Bq.ME_GOLD:
  U32

law Bq.pot_hud:
  (@+a_0: Sprites.Bq.Assets -> (@+n_1: U32 -> List<&1, U32>))

law Bq.ME_POTS:
  U32

law Bq.spin_hud:
  (@+cd_0: U32 -> List<&1, U32>)

law Bq.ME_SPINCD:
  U32

law Bq.ME_SCORE:
  U32

law Bq.sig_dot:
  (@+x_0: U32 -> (@+y_1: U32 -> (@+on_2: U32 -> List<&1, U32>)))

law Bq.sigil_hud:
  (@+s_0: U32 -> List<&1, U32>)

law Bq.ME_SIGILS:
  U32

law Bq.ME_WATK:
  U32

law Bq.ME_DF:
  U32

law Bq.ME_CRIT:
  U32

law Bq.ME_PTS:
  U32

law Bq.atkdef_str:
  (@+me_0: List<&1, U32> -> C.Bq.String)

law Bq.ME_MAINQ:
  U32

law Bq.quest_extra:
  (@+q_0: U32 -> (@+cull_1: U32 -> C.Bq.String))

law Bq.ME_CULL:
  U32

law Bq.quest_chip:
  (@+cs_0: Bq.CS -> List<&1, U32>)

law Bq.log_cmds_go:
  (@+ls_0: List<&1, C.Bq.String> -> (@+y_1: U32 -> List<&1, U32>))

law Bq.cs_evl:
  (@+cs_0: Bq.CS -> List<&1, C.Bq.String>)

law Bq.log_cmds:
  (@+cs_0: Bq.CS -> List<&1, U32>)

law Bq.hud_cmds:
  (@+cs_0: Bq.CS -> (@+a_1: Sprites.Bq.Assets -> (@+tms_2: U32 -> List<&1, U32>)))

law Bq.cs_chatbuf:
  (@+cs_0: Bq.CS -> C.Bq.String)

law Bq.cs_flags:
  (@+cs_0: Bq.CS -> C.Bq.Pair.Pair(U32, (__1 => C.Bq.Pair.Pair(U32, (__2 => C.Bq.Pair.Pair(U32, (__3 => C.Bq.Pair.Pair(U32, (__4 => C.Bq.Pair.Pair(U32, (__5 => C.Bq.Pair.Pair(U32, (__6 => U32)))))))))))))

law Bq.chat_cmds:
  (@+cs_0: Bq.CS -> List<&1, U32>)

law Bq.panel_if:
  (@+on_0: U32 -> (@+cmds_1: List<&1, U32> -> List<&1, U32>))

law Bq.INV_X:
  U32

law Bq.INV_Y:
  U32

law Bq.rect_l:
  (@+x_0: U32 -> (@+y_1: U32 -> (@+w_2: U32 -> (@+h_3: U32 -> (@+c_4: U32 -> List<&1, U32>)))))

law Bq.ME_INV0:
  U32

law Bq.inv_cell:
  (@+a_0: Sprites.Bq.Assets -> (@+k_1: U32 -> (@+cnt_2: U32 -> (@+cx_3: U32 -> (@+cy_4: U32 -> List<&1, U32>)))))

law Bq.inv_slots:
  (@+a_0: Sprites.Bq.Assets -> (@+me_1: List<&1, U32> -> (@+n_2: U32 -> List<&1, U32>)))

law Bq.gear_cell:
  (@+a_0: Sprites.Bq.Assets -> (@+k1_1: U32 -> (@+cx_2: U32 -> (@+cy_3: U32 -> List<&1, U32>))))

law Bq.ME_WEA:
  U32

law Bq.ME_ARM:
  U32

law Bq.ME_HEL:
  U32

law Bq.ME_CHM:
  U32

law Bq.gear_slots:
  (@+a_0: Sprites.Bq.Assets -> (@+me_1: List<&1, U32> -> List<&1, U32>))

law Bq.plus_btn:
  (@+x_0: U32 -> (@+y_1: U32 -> (@+pts_2: U32 -> List<&1, U32>)))

law Bq.stat_row:
  (@+x_0: U32 -> (@+y_1: U32 -> (@+nm_2: C.Bq.String -> (@+v_3: U32 -> (@+pts_4: U32 -> List<&1, U32>)))))

law Bq.ME_STR:
  U32

law Bq.ME_AGI:
  U32

law Bq.ME_VIT:
  U32

law Bq.stat_rows:
  (@+me_0: List<&1, U32> -> List<&1, U32>)

law Bq.inv_panel:
  (@+cs_0: Bq.CS -> (@+a_1: Sprites.Bq.Assets -> List<&1, U32>))

law Bq.side_row:
  (@+x_0: U32 -> (@+y_1: U32 -> (@+q_2: U32 -> (@+cnt_3: U32 -> (@+done_4: U32 -> List<&1, U32>)))))

law Bq.ME_SQ0:
  U32

law Bq.ME_SQD:
  U32

law Bq.ME_SQ1:
  U32

law Bq.ME_SQ2:
  U32

law Bq.quest_panel:
  (@+cs_0: Bq.CS -> List<&1, U32>)

law Bq.SHOP_ROW_COUNT:
  U32

law Bq.req_str:
  (@+k_0: U32 -> C.Bq.String)

law Bq.shop_row:
  (@+a_0: Sprites.Bq.Assets -> (@+k_1: U32 -> (@+y_2: U32 -> List<&1, U32>)))

law Bq.shop_kind:
  (@+i_0: U32 -> U32)

law Bq.shop_rows:
  (@+a_0: Sprites.Bq.Assets -> (@+n_1: U32 -> List<&1, U32>))

law Bq.shop_panel:
  (@+cs_0: Bq.CS -> (@+a_1: Sprites.Bq.Assets -> List<&1, U32>))

law Bq.dur_str:
  (@+d_0: U32 -> C.Bq.String)

law Bq.fame_icon:
  (@+a_0: Sprites.Bq.Assets -> (@+x_1: U32 -> (@+y_2: U32 -> (@+k1_3: U32 -> List<&1, U32>))))

law Bq.fame_gear:
  (@+a_0: Sprites.Bq.Assets -> (@+x_1: U32 -> (@+y_2: U32 -> (@+wea_3: U32 -> (@+arm_4: U32 -> (@+hel_5: U32 -> (@+chm_6: U32 -> List<&1, U32>)))))))

law Bq.fame_chars:
  (@+a_0: Sprites.Bq.Assets -> (@+fs_1: List<&1, Bq.FameP> -> (@+x_2: U32 -> (@+y_3: U32 -> List<&1, U32>))))

law Bq.fame_rows:
  (@+a_0: Sprites.Bq.Assets -> (@+fs_1: List<&1, Bq.FameR> -> (@+y_2: U32 -> List<&1, U32>)))

law Bq.cs_acct:
  (@+cs_0: Bq.CS -> Bq.Acct)

law Bq.fame_panel:
  (@+cs_0: Bq.CS -> (@+a_1: Sprites.Bq.Assets -> List<&1, U32>))

law Bq.over_rows:
  (@+os_0: List<&1, Bq.OverE> -> (@+y_1: U32 -> List<&1, U32>))

law Bq.over_panel:
  (@+cs_0: Bq.CS -> List<&1, U32>)

law Bq.cs_err_str:
  (@+cs_0: Bq.CS -> C.Bq.String)

law Bq.err_toast:
  (@+cs_0: Bq.CS -> List<&1, U32>)

law Bq.render_game:
  (@+cs_0: Bq.CS -> (@+a_1: Sprites.Bq.Assets -> (@+tms_2: U32 -> (@+snds_3: C.Bq.Pair.Pair(U32, (__3 => U32)) -> List<&1, U32>))))

law Bq.opt_row:
  (@+y_0: U32 -> (@+label_1: C.Bq.String -> (@+val_2: C.Bq.String -> List<&1, U32>)))

law Bq.hat_label:
  (@+h_0: U32 -> C.Bq.String)

law Bq.cape_label:
  (@+c_0: U32 -> C.Bq.String)

law Bq.afford_col:
  (@+ok_0: U32 -> U32)

law Bq.shop_btn:
  (@+x_0: U32 -> (@+y_1: U32 -> (@+owned_2: U32 -> (@+name_3: C.Bq.String -> (@+price_4: U32 -> (@+coins_5: U32 -> List<&1, U32>))))))

law Bq.btn:
  (@+x_0: U32 -> (@+y_1: U32 -> (@+w_2: U32 -> (@+h_3: U32 -> (@+c_4: U32 -> (@+tx_5: U32 -> (@+label_6: C.Bq.String -> List<&1, U32>)))))))

law Bq.fame_if:
  (@+cs_0: Bq.CS -> (@+a_1: Sprites.Bq.Assets -> List<&1, U32>))

law Bq.cs_creator_vals:
  (@+cs_0: Bq.CS -> C.Bq.Pair.Pair(U32, (__1 => C.Bq.Pair.Pair(U32, (__2 => C.Bq.Pair.Pair(U32, (__3 => C.Bq.Pair.Pair(U32, (__4 => C.Bq.Pair.Pair(U32, (__5 => C.Bq.Pair.Pair(U32, (__6 => C.Bq.Pair.Pair(U32, (__7 => C.Bq.Pair.Pair(U32, (__8 => U32)))))))))))))))))

law Bq.render_creator:
  (@+cs_0: Bq.CS -> (@+a_1: Sprites.Bq.Assets -> (@+tms_2: U32 -> List<&1, U32>)))

law Bq.dash_log:
  (@+ls_0: List<&1, C.Bq.String> -> (@+y_1: U32 -> List<&1, U32>))

law Bq.render_dash:
  (@+cs_0: Bq.CS -> List<&1, U32>)

law Bq.aurora_bg:
  (@+auro_0: U32 -> List<&1, U32>)

law Bq.field_col:
  (@+f_0: U32 -> U32)

law Bq.cursor_of:
  (@+f_0: U32 -> C.Bq.String)

law Bq.field_box:
  (@+label_0: C.Bq.String -> (@+val_1: C.Bq.String -> (@+x_2: U32 -> (@+y_3: U32 -> (@+focused_4: U32 -> List<&1, U32>)))))

law Bq.render_host:
  (@+cs_0: Bq.CS -> (@+a_1: Sprites.Bq.Assets -> (@+auro_2: U32 -> List<&1, U32>)))

law Bq.render_join:
  (@+cs_0: Bq.CS -> (@+a_1: Sprites.Bq.Assets -> (@+auro_2: U32 -> List<&1, U32>)))

law Bq.render_menu:
  (@+cs_0: Bq.CS -> (@+a_1: Sprites.Bq.Assets -> (@+auro_2: U32 -> (@+tms_3: U32 -> List<&1, U32>))))

law Bq.render:
  (@+cs_0: Bq.CS -> (@+a_1: Sprites.Bq.Assets -> (@+auro_2: U32 -> (@+tms_3: U32 -> (@+snds_4: C.Bq.Pair.Pair(U32, (__4 => U32)) -> List<&1, U32>)))))

law Bq.shot_name:
  (@+mode_0: U32 -> (@+fn_1: U32 -> C.Bq.String))

law Bq.auto_shot:
  (@+mode_0: U32 -> (@+fn_1: U32 -> IO(Unit)))

law Bq.auto_end:
  (@+mode_0: U32 -> U32)

law Bq.frame_pace:
  (@+last_0: U32 -> IO(U32))

law Bq.cs_hosting:
  (@+cs_0: Bq.CS -> U32)

law Bq.shutdown:
  (@+cs_0: Bq.CS -> (@+ctl_1: Chan<U32> -> IO(Unit)))

law Bq.cs_quitting:
  (@+cs_0: Bq.CS -> U32)

law Bq.presses:
  (@+ws_0: List<&1, U32> -> List<&1, U32>)

law Bq.typed:
  (@+ws_0: List<&1, U32> -> List<&1, U32>)

law Bq.held_of:
  (@+ws_0: List<&1, U32> -> U32)

law Bq.mouse_of:
  (@+ws_0: List<&1, U32> -> U32)

law Bq.dir_held:
  (@+h_0: U32 -> U32)

law Bq.move_lines:
  (@+d_0: U32 -> (@+msent_1: U32 -> List<&1, C.Bq.String>))

law Bq.cs_move_sent:
  (@+cs_0: Bq.CS -> (@+v_1: U32 -> Bq.CS))

law Bq.click_if:
  (@+on_0: U32 -> (@+ls_1: List<&1, C.Bq.String> -> List<&1, C.Bq.String>))

law Bq.hit:
  (@+m_0: U32 -> (@+x_1: U32 -> (@+y_2: U32 -> (@+w_3: U32 -> (@+h_4: U32 -> U32)))))

law Bq.inv_slot_hit:
  (@+m_0: U32 -> (@+n_1: U32 -> U32))

law Bq.gear_slot_hit:
  (@+m_0: U32 -> U32)

law Bq.stat_plus_hit:
  (@+m_0: U32 -> U32)

law Bq.inv_click:
  (@+m_0: U32 -> (@+me_1: List<&1, U32> -> List<&1, C.Bq.String>))

law Bq.shop_row_hit:
  (@+m_0: U32 -> (@+n_1: U32 -> U32))

law Bq.shop_click:
  (@+m_0: U32 -> List<&1, C.Bq.String>)

law Bq.game_clicks:
  (@+cs_0: Bq.CS -> (@+m_1: U32 -> (@+inv_2: U32 -> (@+shp_3: U32 -> List<&1, C.Bq.String>))))

law Bq.has_press:
  (@+ps_0: List<&1, U32> -> (@+k_1: U32 -> U32))

law Bq.press_line:
  (@+ps_0: List<&1, U32> -> (@+k_1: U32 -> (@+tag_2: C.Bq.String -> List<&1, C.Bq.String>)))

law Bq.cs_grid_at:
  (@+cs_0: Bq.CS -> (@+x_1: U32 -> (@+y_2: U32 -> U32)))

law Bq.cs_mypos:
  (@+cs_0: Bq.CS -> C.Bq.Pair.Pair(U32, (__1 => C.Bq.Pair.Pair(U32, (__2 => U32)))))

law Bq.context_line:
  (@+cs_0: Bq.CS -> List<&1, C.Bq.String>)

law Bq.press_ctx:
  (@+cs_0: Bq.CS -> (@+ps_1: List<&1, U32> -> List<&1, C.Bq.String>))

law Bq.act_lines:
  (@+cs_0: Bq.CS -> (@+ps_1: List<&1, U32> -> List<&1, C.Bq.String>))

law Bq.i_xor:
  (@+v_0: U32 -> (@+flip_1: U32 -> U32))

law Bq.cs_toggle:
  (@+cs_0: Bq.CS -> (@+which_1: U32 -> Bq.CS))

law Bq.cs_chat:
  (@+cs_0: Bq.CS -> (@+open_1: U32 -> (@+buf_2: C.Bq.String -> Bq.CS)))

law Bq.tog_if:
  (@+cs_0: Bq.CS -> (@+on_1: U32 -> (@+which_2: U32 -> Bq.CS)))

law Bq.near_the_mat:
  (@+cs_0: Bq.CS -> U32)

law Bq.shop_toggle:
  (@+cs_0: Bq.CS -> (@+on_1: U32 -> Bq.CS))

law Bq.close_panels:
  (@+cs_0: Bq.CS -> Bq.CS)

law Bq.toggles:
  (@+cs_0: Bq.CS -> (@+ps_1: List<&1, U32> -> Bq.CS))

law Bq.append_cps:
  (@+s_0: C.Bq.String -> (@+cps_1: List<&1, U32> -> (@+maxlen_2: U32 -> C.Bq.String)))

law Bq.str_tail:
  (@+s_0: C.Bq.String -> C.Bq.String)

law Bq.drop_last:
  (@+s_0: C.Bq.String -> (@+n_1: U32 -> C.Bq.String))

law Bq.edit_str:
  (@+s_0: C.Bq.String -> (@+cps_1: List<&1, U32> -> (@+bs_2: U32 -> (@+maxlen_3: U32 -> C.Bq.String))))

law Bq.say_lines:
  (@+buf_0: C.Bq.String -> List<&1, C.Bq.String>)

law Bq.input_game:
  (@+cs_0: Bq.CS -> (@+ps_1: List<&1, U32> -> (@+cps_2: List<&1, U32> -> (@+held_3: U32 -> (@+m_4: U32 -> C.Bq.Pair.Pair(Bq.CS, (__5 => List<&1, C.Bq.String>)))))))

law Bq.cyc_step:
  (@+cur_0: U32 -> (@+mask_1: U32 -> (@+maxid_2: U32 -> (@+fuel_3: U32 -> U32))))

law Bq.cyc_own:
  (@+cur_0: U32 -> (@+d_1: U32 -> (@+mask_2: U32 -> (@+maxid_3: U32 -> U32))))

law Bq.cs_creator:
  (@+cs_0: Bq.CS -> (@+dskin_1: U32 -> (@+dhairs_2: U32 -> (@+dhairc_3: U32 -> (@+dshirt_4: U32 -> (@+dhat_5: U32 -> (@+dcape_6: U32 -> Bq.CS)))))))

law Bq.creator_shop_click:
  (@+m_0: U32 -> List<&1, C.Bq.String>)

law Bq.input_creator:
  (@+cs_0: Bq.CS -> (@+ps_1: List<&1, U32> -> (@+m_2: U32 -> C.Bq.Pair.Pair(Bq.CS, (__3 => List<&1, C.Bq.String>)))))

law Bq.input_dash:
  (@+cs_0: Bq.CS -> (@+ps_1: List<&1, U32> -> (@+m_2: U32 -> C.Bq.Pair.Pair(Bq.CS, (__3 => List<&1, C.Bq.String>)))))

law Bq.edit_pick:
  (@+s_0: C.Bq.String -> (@+on_1: U32 -> (@+cps_2: List<&1, U32> -> (@+bs_3: U32 -> (@+ml_4: U32 -> C.Bq.String)))))

law Bq.cs_edit_field:
  (@+cs_0: Bq.CS -> (@+cps_1: List<&1, U32> -> (@+bs_2: U32 -> Bq.CS)))

law Bq.cs_focus:
  (@+cs_0: Bq.CS -> (@+v_1: U32 -> Bq.CS))

law Bq.input_host:
  (@+cs_0: Bq.CS -> (@+ps_1: List<&1, U32> -> (@+cps_2: List<&1, U32> -> (@+m_3: U32 -> C.Bq.Pair.Pair(Bq.CS, (__4 => List<&1, C.Bq.String>))))))

law Bq.field_hit:
  (@+m_0: U32 -> (@+base_y_1: U32 -> (@+n_2: U32 -> U32)))

law Bq.field_click:
  (@+cs_0: Bq.CS -> (@+m_1: U32 -> (@+base_y_2: U32 -> (@+nfields_3: U32 -> Bq.CS))))

law Bq.input_join:
  (@+cs_0: Bq.CS -> (@+ps_1: List<&1, U32> -> (@+cps_2: List<&1, U32> -> (@+m_3: U32 -> C.Bq.Pair.Pair(Bq.CS, (__4 => List<&1, C.Bq.String>))))))

law Bq.cs_quit:
  (@+cs_0: Bq.CS -> Bq.CS)

law Bq.input_menu:
  (@+cs_0: Bq.CS -> (@+ps_1: List<&1, U32> -> (@+m_2: U32 -> C.Bq.Pair.Pair(Bq.CS, (__3 => List<&1, C.Bq.String>)))))

law Bq.handle_input:
  (@+cs_0: Bq.CS -> (@+ws_1: List<&1, U32> -> C.Bq.Pair.Pair(Bq.CS, (__2 => List<&1, C.Bq.String>))))

law Bq.frame_loop:
  (@+fuel_0: U32 -> (@+cs_1: Bq.CS -> (@+a_2: Sprites.Bq.Assets -> (@+auro_3: U32 -> (@+rx_4: Chan<C.Bq.String> -> (@+lg_5: Chan<C.Bq.String> -> (@+ctl_6: Chan<U32> -> (@+stat_7: Chan<C.Bq.String> -> (@+last_8: U32 -> (@+auto_9: U32 -> (@+snds_10: C.Bq.Pair.Pair(U32, (__10 => U32)) -> IO(Unit))))))))))))

law Bq.client_start:
  IO(Unit)

@unsafe
def Bq.tri():
  (t_0 => (+m_1 = (t_0 % 128 : U32); (+apply_11 = {(m_0 => (word => C.Bq.word_case(U32, word, 0, (unit => m_0), (_2300_1 => (128 - m_0 : U32)), 0))) : (@+m_0: U32 -> (@+___1: U32 -> U32))}; apply_11(m_1, C.Bq.bit(U32.is_ge(m_1, 64))))))

@unsafe
def Bq.aurora_px():
  (x_0 => (y_1 => (+b1_2 = Bq.tri(((x_0 + (y_1 / 2 : U32) : U32) + 17 : U32)); (+b2_3 = Bq.tri((((x_0 / 2 : U32) + 89 : U32) + (y_1 * 2 : U32) : U32)); (+b3_4 = Bq.tri((((x_0 * 2 : U32) + 111 : U32) + y_1 : U32)); (+r_5 = ((18 + (b1_2 / 3 : U32) : U32) + (b3_4 / 8 : U32) : U32); (+g_6 = (14 + (b2_3 / 3 : U32) : U32); (+b_7 = ((40 + (b1_2 / 2 : U32) : U32) + (b2_3 / 6 : U32) : U32); (+star_8 = C.Bq.bit(U32.is_eq((World.Bq.hash2(x_0, y_1) % 251 : U32), 0)); (+apply_12 = {(r_0 => (g_1 => (b_2 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => [r_0, g_1, b_2, 255]), (_2310_3 => [235, 235, 255, 255]), 0))))) : (@+r_0: U32 -> (@+g_1: U32 -> (@+b_2: U32 -> (@+___3: U32 -> List<&1, U32>))))}; apply_12(r_5, g_6, b_7, star_8)))))))))))

@unsafe
def Bq.aurora_row():
  (word => C.Bq.word_case((@+y_1: U32 -> List<&1, U32>), word, 0, (unit => (y_0 => Nil{})), (x2_0 => (y_1 => Support.Bq.List.concat(U32, Bq.aurora_px((128 - (1 + x2_0 : U32) : U32), y_1), Bq.aurora_row(x2_0, y_1)))), 1))

@unsafe
def Bq.aurora_rows():
  (word => C.Bq.word_case((@+y_1: U32 -> List<&1, U32>), word, 0, (unit => (y_0 => Bq.aurora_row(128, y_0))), (e_0 => (y_1 => (fork_t_2 fork_b_3 = Bq.aurora_rows(e_0, y_1) Bq.aurora_rows(e_0, (y_1 + U32.shln(1, U32.to_nat(e_0)) : U32)); +t_2 = fork_t_2; +b_3 = fork_b_3; Support.Bq.List.concat(U32, t_2, b_3)))), 1))

@unsafe
def Bq.aurora_bytes():
  C.Bq.Bytes.pack(Bq.aurora_rows(7, 0))

@unsafe
def Bq.sq_sample():
  (i_0 => (period_1 => (amp_2 => (+half_3 = (period_1 / 2 : U32); (+apply_14 = {(amp_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (128 - amp_0 : U32)), (_1729_1 => (128 + amp_0 : U32)), 0))) : (@+amp_0: U32 -> (@+___1: U32 -> U32))}; apply_14(amp_2, C.Bq.bit(U32.is_lt((i_0 % Support.Bq.U32.max(period_1, 2) : U32), half_3))))))))

@unsafe
def Bq.synth_go():
  (word => C.Bq.word_case((@+len_1: U32 -> (@+p0_2: U32 -> (@+p1_3: U32 -> List<&1, U32>))), word, 0, (unit => (len_0 => (p0_1 => (p1_2 => Nil{})))), (m_0 => (len_1 => (p0_2 => (p1_3 => (+i_4 = (len_1 - (1 + m_0 : U32) : U32); (+period_5 = (p0_2 + (((p1_3 - p0_2 : U32) * i_4 : U32) / Support.Bq.U32.max(len_1, 1) : U32) : U32); (+amp_6 = ((28 * (len_1 - i_4 : U32) : U32) / Support.Bq.U32.max(len_1, 1) : U32); Con{Bq.sq_sample(i_4, period_5, amp_6), Bq.synth_go(m_0, len_1, p0_2, p1_3)}))))))), 1))

@unsafe
def Bq.snd_hit_bytes():
  C.Bq.Bytes.pack(Bq.synth_go(2200, 2200, 90, 130))

@unsafe
def Bq.snd_lvl_bytes():
  C.Bq.Bytes.pack(Bq.synth_go(5500, 5500, 100, 33))

@unsafe
def Bq.auto_mode():
  C.Bq.IO.bind(Result<&1, &1, C.Bq.Pair.Pair(U32, (__0 => C.Bq.String)), C.Bq.String>, U32, C.Bq.IO.get_env(C.Bq.text("BQ_AUTO")), \{Done: (v_0 => (+apply_15 = {(v_0 => \{False: (+apply_16 = {\{False: C.Bq.IO.pure(U32, 2); \{True: C.Bq.IO.pure(U32, 3); \{}}} : (@+___0: Bool -> IO(U32))}; apply_16(Support.Bq.String.eq(v_0, C.Bq.text("rift")))); \{True: C.Bq.IO.pure(U32, 1); \{}}}) : (@+v_0: C.Bq.String -> (@+___1: Bool -> IO(U32)))}; apply_15(v_0, Support.Bq.String.eq(v_0, C.Bq.text("host"))))); \{Fail: (e_0 => C.Bq.IO.pure(U32, 0)); \{}}})

@unsafe
def Bq.cs_set_name():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => \{Bq.Form.Form: (focus_2 => (f_ip_3 => (f_port_4 => (f_name_5 => (err_6 => (net_7 => (acct_8 => (look_9 => (wv_10 => (ui_11 => (v_12 => Bq.CS.CS{scene_0, quitting_1, Bq.Form.Form{focus_2, f_ip_3, f_port_4, v_12, err_6}, net_7, acct_8, look_9, wv_10, ui_11}))))))))))); \{}})); \{}}

@unsafe
def Bq.name_override():
  (cs_0 => C.Bq.IO.bind(Result<&1, &1, C.Bq.Pair.Pair(U32, (__1 => C.Bq.String)), C.Bq.String>, Bq.CS, C.Bq.IO.get_env(C.Bq.text("BQ_NAME")), \{Done: (v_1 => C.Bq.IO.pure(Bq.CS, Bq.cs_set_name(cs_0, v_1))); \{Fail: (e_1 => C.Bq.IO.pure(Bq.CS, cs_0)); \{}}}))

@unsafe
def Bq.cs0():
  Bq.CS.CS{0, 0, Bq.Form.Form{0, C.Bq.text("127.0.0.1"), C.Bq.text("4977"), C.Bq.text("hero"), Nil{}}, Bq.Net.Net{0, C.Bq.TCP.TCP{0}, 0, Nil{}, Nil{}, Nil{}}, Bq.Acct.Acct{0, 0, 0, 0, 1, Nil{}, Nil{}}, Bq.Look.Look{0, 0, 0, 0, 0, 0}, Bq.Wv.Wv{0, 0, Nil{}, Nil{}, Nil{}, Nil{}, Nil{}, 0, Nil{}, Nil{}, Nil{}}, Bq.Ui.Ui{0, 0, 0, 0, 0, 0, Nil{}, 5}}

@unsafe
def Bq.auto_press():
  (k_0 => [0, 0, (268435456 .|. k_0 : U32)])

@unsafe
def Bq.auto_click():
  (x_0 => (y_1 => [0, ((x_0 .|. U32.shln(y_1, U32.to_nat(12)) : U32) .|. U32.shln(1, U32.to_nat(26)) : U32)]))

@unsafe
def Bq.auto_hold():
  (mask_0 => [mask_0, 0])

@unsafe
def Bq.menu_key():
  (mode_0 => (+apply_17 = {(word => C.Bq.word_case(U32, word, 0, (unit => 80), (_2447_0 => 72), 0)) : (@+___0: U32 -> U32)}; apply_17(C.Bq.bit(U32.is_eq(mode_0, 1)))))

@unsafe
def Bq.rift_words():
  (fn_0 => (+apply_18 = {(fn_0 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => (+apply_19 = {(fn_0 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => (+apply_20 = {(word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => [0, 0]), (_2452_0 => [2, 0, (268435456 .|. 70 : U32)]), 0)) : (@+___0: U32 -> List<&1, U32>)}; apply_20(C.Bq.word_and(C.Bq.bit(U32.is_ge(fn_0, 300)), C.Bq.bit(U32.is_lt(fn_0, 980)))))), (_2454_1 => Bq.auto_press(257)), 0))) : (@+fn_0: U32 -> (@+___1: U32 -> List<&1, U32>))}; apply_19(fn_0, C.Bq.word_or(C.Bq.bit(U32.is_eq(fn_0, 90)), C.Bq.bit(U32.is_eq(fn_0, 260)))))), (_2456_1 => Bq.auto_press(80)), 0))) : (@+fn_0: U32 -> (@+___1: U32 -> List<&1, U32>))}; apply_18(fn_0, C.Bq.bit(U32.is_eq(fn_0, 30)))))

@unsafe
def Bq.auto_words():
  (mode_0 => (fn_1 => (+apply_21 = {(fn_0 => (mode_1 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => (+apply_22 = {(fn_0 => (mode_1 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => (+apply_23 = {(fn_0 => (mode_1 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => (+apply_24 = {(fn_0 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => (+apply_25 = {(fn_0 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => (+apply_26 = {(fn_0 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => (+apply_27 = {(fn_0 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => (+apply_28 = {(fn_0 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => (+apply_29 = {(fn_0 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => (+apply_30 = {(fn_0 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => (+apply_31 = {(fn_0 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => (+apply_32 = {(fn_0 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => (+apply_33 = {(word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => [0, 0]), (_2460_0 => Bq.auto_press(73)), 0)) : (@+___0: U32 -> List<&1, U32>)}; apply_33(C.Bq.bit(U32.is_eq(fn_0, 600))))), (_2462_1 => Bq.auto_press(73)), 0))) : (@+fn_0: U32 -> (@+___1: U32 -> List<&1, U32>))}; apply_32(fn_0, C.Bq.bit(U32.is_eq(fn_0, 545))))), (_2464_1 => Bq.auto_press(66)), 0))) : (@+fn_0: U32 -> (@+___1: U32 -> List<&1, U32>))}; apply_31(fn_0, C.Bq.bit(U32.is_eq(fn_0, 530))))), (_2466_1 => Bq.auto_click(400, 184)), 0))) : (@+fn_0: U32 -> (@+___1: U32 -> List<&1, U32>))}; apply_30(fn_0, C.Bq.bit(U32.is_eq(fn_0, 470))))), (_2468_1 => Bq.auto_click(400, 140)), 0))) : (@+fn_0: U32 -> (@+___1: U32 -> List<&1, U32>))}; apply_29(fn_0, C.Bq.bit(U32.is_eq(fn_0, 430))))), (_2470_1 => Bq.auto_press(66)), 0))) : (@+fn_0: U32 -> (@+___1: U32 -> List<&1, U32>))}; apply_28(fn_0, C.Bq.bit(U32.is_eq(fn_0, 410))))), (_2472_1 => Bq.auto_hold(4)), 0))) : (@+fn_0: U32 -> (@+___1: U32 -> List<&1, U32>))}; apply_27(fn_0, C.Bq.word_and(C.Bq.bit(U32.is_ge(fn_0, 366)), C.Bq.bit(U32.is_lt(fn_0, 400)))))), (_2474_1 => Bq.auto_hold(2)), 0))) : (@+fn_0: U32 -> (@+___1: U32 -> List<&1, U32>))}; apply_26(fn_0, C.Bq.word_and(C.Bq.bit(U32.is_ge(fn_0, 320)), C.Bq.bit(U32.is_lt(fn_0, 366)))))), (_2476_1 => Bq.auto_press(257)), 0))) : (@+fn_0: U32 -> (@+___1: U32 -> List<&1, U32>))}; apply_25(fn_0, C.Bq.bit(U32.is_eq(fn_0, 260))))), (_2478_1 => Bq.auto_press(257)), 0))) : (@+fn_0: U32 -> (@+___1: U32 -> List<&1, U32>))}; apply_24(fn_0, C.Bq.bit(U32.is_eq(fn_0, 90))))), (_2480_2 => Bq.auto_press(Bq.menu_key(mode_1))), 0)))) : (@+fn_0: U32 -> (@+mode_1: U32 -> (@+___2: U32 -> List<&1, U32>)))}; apply_23(fn_0, mode_1, C.Bq.bit(U32.is_eq(fn_0, 30))))), (_2482_2 => Bq.rift_words(fn_0)), 0)))) : (@+fn_0: U32 -> (@+mode_1: U32 -> (@+___2: U32 -> List<&1, U32>)))}; apply_22(fn_0, mode_1, C.Bq.bit(U32.is_eq(mode_1, 3))))), (_2484_2 => Nil{}), 0)))) : (@+fn_0: U32 -> (@+mode_1: U32 -> (@+___2: U32 -> List<&1, U32>)))}; apply_21(fn_1, mode_0, C.Bq.bit(U32.is_eq(mode_0, 0))))))

@unsafe
def Bq.auto_pick():
  (mode_0 => (fn_1 => (real_2 => (+apply_34 = {(mode_0 => (fn_1 => (real_2 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => Bq.auto_words(mode_0, fn_1)), (_2489_3 => real_2), 0))))) : (@+mode_0: U32 -> (@+fn_1: U32 -> (@+real_2: List<&1, U32> -> (@+___3: U32 -> List<&1, U32>))))}; apply_34(mode_0, fn_1, real_2, C.Bq.bit(U32.is_eq(mode_0, 0)))))))

@unsafe
def Bq.send_line():
  (fd_0 => (line_1 => C.Bq.IO.bind(Result<&1, &1, C.Bq.Pair.Pair(U32, (__2 => C.Bq.String)), Result<&1, &1, C.Bq.Pair.Pair(U32, (__2 => C.Bq.String)), Unit>>, Unit, C.Bq.IO.timeout(Result<&1, &1, C.Bq.Pair.Pair(U32, (__2 => C.Bq.String)), Unit>, 300, C.Bq.TCP.send(C.Bq.TCP.TCP{fd_0}, C.Bq.Bytes.from_string(line_1))), (r_2 => C.Bq.IO.pure(Unit, Unit{})))))

@unsafe
def Bq.cs_net():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => (form_2 => (net_3 => (acct_4 => (look_5 => (wv_6 => (ui_7 => net_3)))))))); \{}}

@unsafe
def Bq.cs_netinfo():
  (cs_0 => (+apply_35 = {\{Bq.Net.Net: (net_on_0 => (sock_1 => (hosting_2 => (hostaddr_3 => (hostlog_4 => (hoststat_5 => (+apply_36 = {(net_on_0 => \{C.Bq.TCP.TCP: (fd_1 => (hosting_2 => (hostaddr_3 => (hostlog_4 => (hoststat_5 => Tuple{net_on_0, fd_1}))))); \{}}) : (@+net_on_0: U32 -> (@+___1: C.Bq.TCP -> (@+__2: U32 -> (@+__3: List<&1, Char> -> (@+__4: List<&1, List<&1, Char>> -> (@+__5: List<&1, Char> -> Sigma<&1, &1, U32, (__6 => U32)>))))))}; apply_36(net_on_0, sock_1, hosting_2, hostaddr_3, hostlog_4, hoststat_5)))))))); \{}} : (@+___0: Bq.Net -> Sigma<&1, &1, U32, (__1 => U32)>)}; apply_35(Bq.cs_net(cs_0))))

@unsafe
def Bq.send_wire():
  (cs_0 => (l_1 => (+apply_37 = {(l_0 => (cs_1 => \{Tuple: (fst_2 => (snd_3 => (+apply_38 = {(fst_0 => (snd_1 => (l_2 => (cs_3 => (word => C.Bq.word_case(IO(Bq.CS), word, 0, (unit => C.Bq.IO.bind(Unit, Bq.CS, Bq.send_line(snd_1, l_2), (__4 => C.Bq.IO.pure(Bq.CS, cs_3)))), (_2416_4 => C.Bq.IO.pure(Bq.CS, cs_3)), 0)))))) : (@-fst_0: U32 -> (@+snd_1: (__1 => U32)(fst_0) -> (@+l_2: C.Bq.String -> (@+cs_3: Bq.CS -> (@+___4: U32 -> IO(Bq.CS))))))}; apply_38(fst_2, snd_3, l_0, cs_1, C.Bq.bit(U32.is_eq(fst_2, 0)))))); \{}})) : (@+l_0: C.Bq.String -> (@+cs_1: Bq.CS -> (@+___2: Sigma<&1, &1, U32, (__2 => U32)> -> IO(Bq.CS))))}; apply_37(l_1, cs_0, Bq.cs_netinfo(cs_0)))))

@unsafe
def Bq.cs_scene():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => (form_2 => (net_3 => (acct_4 => (look_5 => (wv_6 => (ui_7 => (v_8 => Bq.CS.CS{v_8, quitting_1, form_2, net_3, acct_4, look_5, wv_6, ui_7}))))))))); \{}}

@unsafe
def Bq.cs_unhost():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => (form_2 => \{Bq.Net.Net: (net_on_3 => (sock_4 => (hosting_5 => (hostaddr_6 => (hostlog_7 => (hoststat_8 => (acct_9 => (look_10 => (wv_11 => (ui_12 => Bq.CS.CS{scene_0, quitting_1, form_2, Bq.Net.Net{net_on_3, sock_4, 0, Nil{}, Nil{}, Nil{}}, acct_9, look_10, wv_11, ui_12})))))))))); \{}}))); \{}}

@unsafe
def Bq.cs_hostaddr():
  (cs_0 => (+apply_39 = {\{Bq.Net.Net: (net_on_0 => (sock_1 => (hosting_2 => (hostaddr_3 => (hostlog_4 => (hoststat_5 => hostaddr_3)))))); \{}} : (@+___0: Bq.Net -> List<&1, Char>)}; apply_39(Bq.cs_net(cs_0))))

@unsafe
def Bq.local_ip():
  C.Bq.IO.bind(Result<&1, &1, C.Bq.Pair.Pair(U32, (__0 => C.Bq.String)), C.Bq.Bytes>, C.Bq.String, C.Bq.IO.exec(C.Bq.text("ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo 127.0.0.1")), \{Done: (bs_0 => C.Bq.IO.pure(C.Bq.String, Support.Bq.String.trim(C.Bq.Bytes.to_string(bs_0)))); \{Fail: (e_0 => C.Bq.IO.pure(C.Bq.String, C.Bq.text("127.0.0.1"))); \{}}})

@unsafe
def Bq.cs_set_hosting():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => (form_2 => \{Bq.Net.Net: (net_on_3 => (sock_4 => (hosting_5 => (hostaddr_6 => (hostlog_7 => (hoststat_8 => (acct_9 => (look_10 => (wv_11 => (ui_12 => (addr_13 => Bq.CS.CS{scene_0, quitting_1, form_2, Bq.Net.Net{net_on_3, sock_4, 1, addr_13, hostlog_7, hoststat_8}, acct_9, look_10, wv_11, ui_12}))))))))))); \{}}))); \{}}

@unsafe
def Bq.cs_read():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => \{Bq.Form.Form: (focus_2 => (f_ip_3 => (f_port_4 => (f_name_5 => (err_6 => (net_7 => (acct_8 => (look_9 => (wv_10 => (ui_11 => Tuple{scene_0, Tuple{focus_2, Tuple{f_ip_3, Tuple{f_port_4, f_name_5}}}})))))))))); \{}})); \{}}

@unsafe
def Bq.try_host():
  (cs_0 => (lg_1 => (ctl_2 => (stat_3 => (+apply_537 = {(lg_0 => (ctl_1 => (stat_2 => (cs_3 => \{Tuple: (fst_4 => (snd_5 => (+apply_538 = {(lg_0 => (ctl_1 => (stat_2 => (cs_3 => \{Tuple: (fst_4 => (snd_5 => (+apply_539 = {(lg_0 => (ctl_1 => (stat_2 => (cs_3 => \{Tuple: (fst_4 => (snd_5 => (+apply_540 = {(lg_0 => (ctl_1 => (stat_2 => (cs_3 => \{Tuple: (fst_4 => (snd_5 => (+port_6 = Proto.Bq.read_u32(fst_4); C.Bq.IO.bind(Unit, Bq.CS, C.Bq.IO.spawn(Server.Bq.server_start(port_6, lg_0, ctl_1, stat_2)), (__7 => C.Bq.IO.bind(Unit, Bq.CS, C.Bq.IO.sleep(200), (__8 => C.Bq.IO.bind(C.Bq.String, Bq.CS, Bq.local_ip, (ip_9 => (+cs1_10 = Bq.cs_set_hosting(cs_3, Support.Bq.List.concat(Char, ip_9, Support.Bq.List.concat(Char, C.Bq.text(":"), fst_4))); C.Bq.IO.pure(Bq.CS, Bq.cs_scene(cs1_10, 5)))))))))))); \{}})))) : (@+lg_0: Chan<C.Bq.String> -> (@+ctl_1: Chan<U32> -> (@+stat_2: Chan<C.Bq.String> -> (@+cs_3: Bq.CS -> (@+___4: Sigma<&1, &1, List<&1, Char>, (__4 => List<&1, Char>)> -> IO(Bq.CS))))))}; apply_540(lg_0, ctl_1, stat_2, cs_3, snd_5)))); \{}})))) : (@+lg_0: Chan<C.Bq.String> -> (@+ctl_1: Chan<U32> -> (@+stat_2: Chan<C.Bq.String> -> (@+cs_3: Bq.CS -> (@+___4: Sigma<&1, &1, List<&1, Char>, (__4 => Sigma<&1, &1, List<&1, Char>, (__5 => List<&1, Char>)>)> -> IO(Bq.CS))))))}; apply_539(lg_0, ctl_1, stat_2, cs_3, snd_5)))); \{}})))) : (@+lg_0: Chan<C.Bq.String> -> (@+ctl_1: Chan<U32> -> (@+stat_2: Chan<C.Bq.String> -> (@+cs_3: Bq.CS -> (@+___4: Sigma<&1, &1, U32, (__4 => Sigma<&1, &1, List<&1, Char>, (__5 => Sigma<&1, &1, List<&1, Char>, (__6 => List<&1, Char>)>)>)> -> IO(Bq.CS))))))}; apply_538(lg_0, ctl_1, stat_2, cs_3, snd_5)))); \{}})))) : (@+lg_0: Chan<C.Bq.String> -> (@+ctl_1: Chan<U32> -> (@+stat_2: Chan<C.Bq.String> -> (@+cs_3: Bq.CS -> (@+___4: Sigma<&1, &1, U32, (__4 => Sigma<&1, &1, U32, (__5 => Sigma<&1, &1, List<&1, Char>, (__6 => Sigma<&1, &1, List<&1, Char>, (__7 => List<&1, Char>)>)>)>)> -> IO(Bq.CS))))))}; apply_537(lg_1, ctl_2, stat_3, cs_0, Bq.cs_read(cs_0)))))))

@unsafe
def Bq.dial_verdict():
  \{Fail: (e_0 => Fail{C.Bq.text("connection timed out")}); \{Done: \{Fail: \{Tuple: (ecode_0 => (emsg_1 => Fail{Support.Bq.List.concat(Char, C.Bq.text("connect failed: "), emsg_1)})); \{}}; \{Done: (sock_0 => Done{sock_0}); \{}}}; \{}}}

@unsafe
def Bq.dial():
  (host_0 => (port_1 => C.Bq.IO.bind(Result<&1, &1, C.Bq.Pair.Pair(U32, (__2 => C.Bq.String)), Result<&1, &1, C.Bq.Pair.Pair(U32, (__2 => C.Bq.String)), C.Bq.TCP>>, Result<&1, &1, C.Bq.String, C.Bq.TCP>, C.Bq.IO.timeout(Result<&1, &1, C.Bq.Pair.Pair(U32, (__2 => C.Bq.String)), C.Bq.TCP>, 3000, C.Bq.TCP.connect(host_0, port_1)), (r_2 => C.Bq.IO.pure(Result<&1, &1, C.Bq.String, C.Bq.TCP>, Bq.dial_verdict(r_2))))))

@unsafe
def Bq.push_all():
  (rx_0 => \{Nil: C.Bq.IO.pure(Unit, Unit{}); \{Con: (l_1 => (rest_2 => C.Bq.IO.bind(Result<&1, &1, C.Bq.Pair.Pair(U32, (__3 => C.Bq.String)), Unit>, Unit, C.Bq.Chan.send(C.Bq.String, rx_0, l_1), (__3 => Bq.push_all(rx_0, rest_2))))); \{}}})

@unsafe
def Bq.cl_reader():
  (word => C.Bq.word_case((@+sock_1: C.Bq.TCP -> (@+rx_2: Chan<C.Bq.String> -> (@+buf_3: C.Bq.String -> IO(Unit)))), word, 0, (unit => (sock_0 => (rx_1 => (buf_2 => C.Bq.IO.pure(Unit, Unit{}))))), (f_0 => (sock_1 => (rx_2 => (buf_3 => C.Bq.IO.bind(Result<&1, &1, C.Bq.Pair.Pair(U32, (__4 => C.Bq.String)), C.Bq.Bytes>, Unit, C.Bq.TCP.recv(sock_1, 8192), \{Done: \{C.Bq.Bytes.Bytes: (blen_4 => (bdata_5 => (+apply_541 = {(rx_0 => (f_1 => (sock_2 => (buf_3 => (blen_4 => (bdata_5 => (word => C.Bq.word_case(IO(Unit), word, 0, (unit => (+apply_542 = {(rx_0 => (f_1 => (sock_2 => \{Tuple: (fst_3 => (snd_4 => C.Bq.IO.bind(Unit, Unit, Bq.push_all(rx_0, snd_4), (__5 => Bq.cl_reader(f_1, sock_2, rx_0, fst_3))))); \{}}))) : (@+rx_0: Chan<C.Bq.String> -> (@+f_1: U32 -> (@+sock_2: C.Bq.TCP -> (@+___3: Sigma<&1, &1, List<&1, Char>, (__3 => List<&1, List<&1, Char>>)> -> IO(Unit)))))}; apply_542(rx_0, f_1, sock_2, Proto.Bq.feed(buf_3, C.Bq.Bytes.to_string(C.Bq.Bytes.Bytes{blen_4, bdata_5}))))), (_2339_6 => C.Bq.IO.bind(Result<&1, &1, C.Bq.Pair.Pair(U32, (__7 => C.Bq.String)), Unit>, Unit, C.Bq.Chan.send(C.Bq.String, rx_0, C.Bq.text("DISCON\n")), (__7 => C.Bq.IO.pure(Unit, Unit{})))), 0)))))))) : (@+rx_0: Chan<C.Bq.String> -> (@+f_1: U32 -> (@+sock_2: C.Bq.TCP -> (@+buf_3: C.Bq.String -> (@+blen_4: U32 -> (@+bdata_5: List<&1, U32> -> (@+___6: U32 -> IO(Unit))))))))}; apply_541(rx_2, f_0, sock_1, buf_3, blen_4, bdata_5, C.Bq.bit(U32.is_eq(blen_4, 0)))))); \{}}; \{Fail: (e_4 => C.Bq.IO.bind(Result<&1, &1, C.Bq.Pair.Pair(U32, (__5 => C.Bq.String)), Unit>, Unit, C.Bq.Chan.send(C.Bq.String, rx_2, C.Bq.text("DISCON\n")), (__5 => C.Bq.IO.pure(Unit, Unit{})))); \{}}}))))), 1))

@unsafe
def Bq.start_net():
  (rx_0 => (host_1 => (port_2 => (name_3 => Ior.Bq.IOR.bind(C.Bq.String, C.Bq.TCP, C.Bq.TCP, Bq.dial(host_1, port_2), \{C.Bq.TCP.TCP: (fd_4 => Ior.Bq.IOR.bind(C.Bq.String, Unit, C.Bq.TCP, Ior.Bq.IOR.lift(C.Bq.String, Unit, C.Bq.IO.spawn(Bq.cl_reader(Support.Bq.U32.MAX_VALUE, C.Bq.TCP.TCP{fd_4}, rx_0, Nil{}))), (__5 => Ior.Bq.IOR.bind(C.Bq.String, Unit, C.Bq.TCP, Ior.Bq.IOR.lift(C.Bq.String, Unit, Bq.send_line(fd_4, Proto.Bq.wire_enc(C.Bq.text("HELLO"), Nil{}, name_3))), (__6 => Ior.Bq.IOR.pure(C.Bq.String, C.Bq.TCP, C.Bq.TCP.TCP{fd_4})))))); \{}})))))

@unsafe
def Bq.cs_err():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => \{Bq.Form.Form: (focus_2 => (f_ip_3 => (f_port_4 => (f_name_5 => (err_6 => (net_7 => (acct_8 => (look_9 => (wv_10 => (ui_11 => (msg_12 => Bq.CS.CS{scene_0, quitting_1, Bq.Form.Form{focus_2, f_ip_3, f_port_4, f_name_5, msg_12}, net_7, acct_8, look_9, wv_10, ui_11}))))))))))); \{}})); \{}}

@unsafe
def Bq.cs_set_net():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => \{Bq.Form.Form: (focus_2 => (f_ip_3 => (f_port_4 => (f_name_5 => (err_6 => \{Bq.Net.Net: (net_on_7 => (sock_8 => (hosting_9 => (hostaddr_10 => (hostlog_11 => (hoststat_12 => (acct_13 => (look_14 => (wv_15 => (ui_16 => (nsock_17 => (+fm2_18 = {Bq.Form.Form{focus_2, f_ip_3, f_port_4, f_name_5, Nil{}} : Bq.Form}; (+nt2_19 = {Bq.Net.Net{1, nsock_17, hosting_9, hostaddr_10, hostlog_11, hoststat_12} : Bq.Net}; Bq.CS.CS{scene_0, quitting_1, fm2_18, nt2_19, acct_13, look_14, wv_15, ui_16}))))))))))))); \{}}))))); \{}})); \{}}

@unsafe
def Bq.connect_verdict():
  (cs_0 => \{Fail: (msg_1 => Bq.cs_err(cs_0, msg_1)); \{Done: (sock_1 => Bq.cs_set_net(cs_0, sock_1)); \{}}})

@unsafe
def Bq.connect_now():
  (cs_0 => (rx_1 => (host_2 => (port_3 => (name_4 => C.Bq.IO.bind(Result<&1, &1, C.Bq.String, C.Bq.TCP>, Bq.CS, Ior.Bq.IOR.run(C.Bq.String, C.Bq.TCP, Bq.start_net(rx_1, host_2, port_3, name_4)), (r_5 => C.Bq.IO.pure(Bq.CS, Bq.connect_verdict(cs_0, r_5)))))))))

@unsafe
def Bq.try_connect():
  (cs_0 => (rx_1 => (+apply_543 = {(cs_0 => (rx_1 => \{Tuple: (fst_2 => (snd_3 => (+apply_544 = {(cs_0 => (rx_1 => (word => C.Bq.word_case(IO(Bq.CS), word, 0, (unit => (+apply_545 = {(cs_0 => (rx_1 => \{Tuple: (fst_2 => (snd_3 => (+apply_546 = {(cs_0 => (rx_1 => \{Tuple: (fst_2 => (snd_3 => (+apply_547 = {(cs_0 => (rx_1 => \{Tuple: (fst_2 => (snd_3 => (+apply_548 = {(cs_0 => (rx_1 => (fst_2 => \{Tuple: (fst_3 => (snd_4 => Bq.connect_now(cs_0, rx_1, fst_2, Proto.Bq.read_u32(fst_3), snd_4))); \{}}))) : (@+cs_0: Bq.CS -> (@+rx_1: Chan<C.Bq.String> -> (@+fst_2: C.Bq.String -> (@+___3: Sigma<&1, &1, List<&1, Char>, (__3 => List<&1, Char>)> -> IO(Bq.CS)))))}; apply_548(cs_0, rx_1, fst_2, snd_3)))); \{}})) : (@+cs_0: Bq.CS -> (@+rx_1: Chan<C.Bq.String> -> (@+___2: Sigma<&1, &1, List<&1, Char>, (__2 => Sigma<&1, &1, List<&1, Char>, (__3 => List<&1, Char>)>)> -> IO(Bq.CS))))}; apply_547(cs_0, rx_1, snd_3)))); \{}})) : (@+cs_0: Bq.CS -> (@+rx_1: Chan<C.Bq.String> -> (@+___2: Sigma<&1, &1, U32, (__2 => Sigma<&1, &1, List<&1, Char>, (__3 => Sigma<&1, &1, List<&1, Char>, (__4 => List<&1, Char>)>)>)> -> IO(Bq.CS))))}; apply_546(cs_0, rx_1, snd_3)))); \{}})) : (@+cs_0: Bq.CS -> (@+rx_1: Chan<C.Bq.String> -> (@+___2: Sigma<&1, &1, U32, (__2 => Sigma<&1, &1, U32, (__3 => Sigma<&1, &1, List<&1, Char>, (__4 => Sigma<&1, &1, List<&1, Char>, (__5 => List<&1, Char>)>)>)>)> -> IO(Bq.CS))))}; apply_545(cs_0, rx_1, Bq.cs_read(cs_0)))), (_2393_2 => C.Bq.IO.pure(Bq.CS, cs_0)), 0)))) : (@+cs_0: Bq.CS -> (@+rx_1: Chan<C.Bq.String> -> (@+___2: U32 -> IO(Bq.CS))))}; apply_544(cs_0, rx_1, C.Bq.bit(U32.is_eq(fst_2, 1)))))); \{}})) : (@+cs_0: Bq.CS -> (@+rx_1: Chan<C.Bq.String> -> (@+___2: Sigma<&1, &1, U32, (__2 => U32)> -> IO(Bq.CS))))}; apply_543(cs_0, rx_1, Bq.cs_netinfo(cs_0)))))

@unsafe
def Bq.do_action():
  (cs_0 => (l_1 => (rx_2 => (lg_3 => (ctl_4 => (stat_5 => (+apply_549 = {(cs_0 => (l_1 => (ctl_2 => (lg_3 => (stat_4 => (rx_5 => \{False: (+apply_550 = {(cs_0 => (l_1 => (ctl_2 => (lg_3 => (stat_4 => \{False: (+apply_551 = {(cs_0 => (l_1 => (ctl_2 => \{False: (+apply_552 = {(cs_0 => (l_1 => (ctl_2 => \{False: (+apply_553 = {(cs_0 => (l_1 => (ctl_2 => \{False: Bq.send_wire(cs_0, l_1); \{True: C.Bq.IO.bind(Result<&1, &1, C.Bq.Pair.Pair(U32, (__3 => C.Bq.String)), Unit>, Bq.CS, C.Bq.Chan.send(U32, ctl_2, 2), (__3 => C.Bq.IO.pure(Bq.CS, Bq.cs_scene(Bq.cs_unhost(cs_0), 0)))); \{}}}))) : (@+cs_0: Bq.CS -> (@+l_1: C.Bq.String -> (@+ctl_2: Chan<U32> -> (@+___3: Bool -> IO(Bq.CS)))))}; apply_553(cs_0, l_1, ctl_2, Support.Bq.String.eq(l_1, C.Bq.text("!STOP")))); \{True: C.Bq.IO.bind(Result<&1, &1, C.Bq.Pair.Pair(U32, (__3 => C.Bq.String)), Unit>, Bq.CS, C.Bq.Chan.send(U32, ctl_2, 1), (__3 => C.Bq.IO.pure(Bq.CS, cs_0))); \{}}}))) : (@+cs_0: Bq.CS -> (@+l_1: C.Bq.String -> (@+ctl_2: Chan<U32> -> (@+___3: Bool -> IO(Bq.CS)))))}; apply_552(cs_0, l_1, ctl_2, Support.Bq.String.eq(l_1, C.Bq.text("!RESTART")))); \{True: C.Bq.IO.bind(Unit, Bq.CS, Raylib.Bq.rl_clipboard(Bq.cs_hostaddr(cs_0)), (__3 => C.Bq.IO.pure(Bq.CS, cs_0))); \{}}}))) : (@+cs_0: Bq.CS -> (@+l_1: C.Bq.String -> (@+ctl_2: Chan<U32> -> (@+___3: Bool -> IO(Bq.CS)))))}; apply_551(cs_0, l_1, ctl_2, Support.Bq.String.eq(l_1, C.Bq.text("!COPY")))); \{True: Bq.try_host(cs_0, lg_3, ctl_2, stat_4); \{}}}))))) : (@+cs_0: Bq.CS -> (@+l_1: C.Bq.String -> (@+ctl_2: Chan<U32> -> (@+lg_3: Chan<C.Bq.String> -> (@+stat_4: Chan<C.Bq.String> -> (@+___5: Bool -> IO(Bq.CS)))))))}; apply_550(cs_0, l_1, ctl_2, lg_3, stat_4, Support.Bq.String.eq(l_1, C.Bq.text("!HOST")))); \{True: Bq.try_connect(cs_0, rx_5); \{}}})))))) : (@+cs_0: Bq.CS -> (@+l_1: C.Bq.String -> (@+ctl_2: Chan<U32> -> (@+lg_3: Chan<C.Bq.String> -> (@+stat_4: Chan<C.Bq.String> -> (@+rx_5: Chan<C.Bq.String> -> (@+___6: Bool -> IO(Bq.CS))))))))}; apply_549(cs_0, l_1, ctl_4, lg_3, stat_5, rx_2, Support.Bq.String.eq(l_1, C.Bq.text("!CONNECT"))))))))))

@unsafe
def Bq.do_actions():
  (cs_0 => \{Nil: (rx_1 => (lg_2 => (ctl_3 => (stat_4 => C.Bq.IO.pure(Bq.CS, cs_0))))); \{Con: (l_1 => (rest_2 => (rx_3 => (lg_4 => (ctl_5 => (stat_6 => C.Bq.IO.bind(Bq.CS, Bq.CS, Bq.do_action(cs_0, l_1, rx_3, lg_4, ctl_5, stat_6), (cs2_7 => Bq.do_actions(cs2_7, rest_2, rx_3, lg_4, ctl_5, stat_6))))))))); \{}}})

@unsafe
def Bq.fame_add_fp():
  \{Nil: (f_0 => Nil{}); \{Con: \{Bq.FameR.FameR: (no_0 => (dur_1 => (fps_2 => (rest_3 => (f_4 => Con{Bq.FameR.FameR{no_0, dur_1, Support.Bq.List.concat(Bq.FameP, fps_2, [f_4])}, rest_3}))))); \{}}; \{}}}

@unsafe
def Bq.srv_fp():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => (form_2 => (net_3 => \{Bq.Acct.Acct: (coins_4 => (ownh_5 => (ownc_6 => (wno_7 => (phase_8 => (fame_9 => (over_10 => (look_11 => (wv_12 => (ui_13 => (ns_14 => (text_15 => (+f_16 = {Bq.FameP.FameP{text_15, Server.Bq.nth(ns_14, 0), Server.Bq.nth(ns_14, 1), Server.Bq.nth(ns_14, 2), Server.Bq.nth(ns_14, 3), Server.Bq.nth(ns_14, 4), Server.Bq.nth(ns_14, 5), Server.Bq.nth(ns_14, 6), Server.Bq.nth(ns_14, 7), Server.Bq.nth(ns_14, 8), Server.Bq.nth(ns_14, 9), Server.Bq.nth(ns_14, 10), Server.Bq.nth(ns_14, 11)} : Bq.FameP}; (+ac2_17 = {Bq.Acct.Acct{coins_4, ownh_5, ownc_6, wno_7, phase_8, Bq.fame_add_fp(fame_9, f_16), over_10} : Bq.Acct}; Bq.CS.CS{scene_0, quitting_1, form_2, net_3, ac2_17, look_11, wv_12, ui_13})))))))))))))); \{}})))); \{}}

@unsafe
def Bq.fame_add_run():
  (fs_0 => (no_1 => (dur_2 => Con{Bq.FameR.FameR{no_1, dur_2, Nil{}}, fs_0})))

@unsafe
def Bq.srv_frun():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => (form_2 => (net_3 => \{Bq.Acct.Acct: (coins_4 => (ownh_5 => (ownc_6 => (wno_7 => (phase_8 => (fame_9 => (over_10 => (look_11 => (wv_12 => (ui_13 => (ns_14 => (+ac2_15 = {Bq.Acct.Acct{coins_4, ownh_5, ownc_6, wno_7, phase_8, Bq.fame_add_run(fame_9, Server.Bq.nth(ns_14, 0), Server.Bq.nth(ns_14, 1)), over_10} : Bq.Acct}; Bq.CS.CS{scene_0, quitting_1, form_2, net_3, ac2_15, look_11, wv_12, ui_13})))))))))))); \{}})))); \{}}

@unsafe
def Bq.srv_fameb():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => (form_2 => (net_3 => \{Bq.Acct.Acct: (coins_4 => (ownh_5 => (ownc_6 => (wno_7 => (phase_8 => (fame_9 => (over_10 => (look_11 => (wv_12 => (ui_13 => Bq.CS.CS{scene_0, quitting_1, form_2, net_3, Bq.Acct.Acct{coins_4, ownh_5, ownc_6, wno_7, phase_8, Nil{}, over_10}, look_11, wv_12, ui_13})))))))))); \{}})))); \{}}

@unsafe
def Bq.push_ev():
  (evl_0 => (s_1 => Support.Bq.List.take(C.Bq.String, 7, Con{s_1, evl_0})))

@unsafe
def Bq.srv_start():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => (form_2 => (net_3 => \{Bq.Acct.Acct: (coins_4 => (ownh_5 => (ownc_6 => (wno_7 => (phase_8 => (fame_9 => (over_10 => (look_11 => \{Bq.Wv.Wv: (mypid_12 => (zid_13 => (grid_14 => (plist_15 => (mlist_16 => (names_17 => (me_18 => (snapms_19 => (evl_20 => (bubs_21 => (fxs_22 => \{Bq.Ui.Ui: (inv_open_23 => (quest_open_24 => (shop_open_25 => (dash_open_26 => (fame_open_27 => (chat_open_28 => (chatbuf_29 => (move_sent_30 => (ns_31 => (+ac2_32 = {Bq.Acct.Acct{coins_4, ownh_5, ownc_6, Server.Bq.nth(ns_31, 0), 1, fame_9, Nil{}} : Bq.Acct}; (+wv2_33 = {Bq.Wv.Wv{mypid_12, zid_13, grid_14, plist_15, mlist_16, names_17, me_18, snapms_19, Bq.push_ev(evl_20, C.Bq.text("A new world dawns!")), bubs_21, fxs_22} : Bq.Wv}; (+ui2_34 = {Bq.Ui.Ui{inv_open_23, quest_open_24, shop_open_25, dash_open_26, 0, chat_open_28, chatbuf_29, move_sent_30} : Bq.Ui}; Bq.CS.CS{scene_0, quitting_1, form_2, net_3, ac2_32, look_11, wv2_33, ui2_34})))))))))))); \{}}))))))))))); \{}})))))))); \{}})))); \{}}

@unsafe
def Bq.srv_over():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => (form_2 => (net_3 => \{Bq.Acct.Acct: (coins_4 => (ownh_5 => (ownc_6 => (wno_7 => (phase_8 => (fame_9 => (over_10 => (look_11 => (wv_12 => (ui_13 => (ns_14 => (text_15 => (+ac2_16 = {Bq.Acct.Acct{coins_4, ownh_5, ownc_6, wno_7, phase_8, fame_9, Support.Bq.List.concat(Bq.OverE, over_10, [Bq.OverE.OverE{Server.Bq.nth(ns_14, 0), Server.Bq.nth(ns_14, 1), Server.Bq.nth(ns_14, 2), text_15}])} : Bq.Acct}; Bq.CS.CS{scene_0, quitting_1, form_2, net_3, ac2_16, look_11, wv_12, ui_13}))))))))))))); \{}})))); \{}}

@unsafe
def Bq.srv_fx():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => (form_2 => (net_3 => (acct_4 => (look_5 => \{Bq.Wv.Wv: (mypid_6 => (zid_7 => (grid_8 => (plist_9 => (mlist_10 => (names_11 => (me_12 => (snapms_13 => (evl_14 => (bubs_15 => (fxs_16 => (ui_17 => (ns_18 => (+wv2_19 = {Bq.Wv.Wv{mypid_6, zid_7, grid_8, plist_9, mlist_10, names_11, me_12, snapms_13, evl_14, bubs_15, Con{Bq.FXV.FXV{Server.Bq.nth(ns_18, 0), Server.Bq.nth(ns_18, 1), Server.Bq.nth(ns_18, 2), 20}, fxs_16}} : Bq.Wv}; Bq.CS.CS{scene_0, quitting_1, form_2, net_3, acct_4, look_5, wv2_19, ui_17})))))))))))))); \{}})))))); \{}}

@unsafe
def Bq.srv_bubble():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => (form_2 => (net_3 => (acct_4 => (look_5 => \{Bq.Wv.Wv: (mypid_6 => (zid_7 => (grid_8 => (plist_9 => (mlist_10 => (names_11 => (me_12 => (snapms_13 => (evl_14 => (bubs_15 => (fxs_16 => (ui_17 => (ns_18 => (text_19 => (+wv2_20 = {Bq.Wv.Wv{mypid_6, zid_7, grid_8, plist_9, mlist_10, names_11, me_12, snapms_13, evl_14, Con{Bq.Bub.Bub{Server.Bq.nth(ns_18, 0), text_19, 240}, bubs_15}, fxs_16} : Bq.Wv}; Bq.CS.CS{scene_0, quitting_1, form_2, net_3, acct_4, look_5, wv2_20, ui_17}))))))))))))))); \{}})))))); \{}}

@unsafe
def Bq.srv_ev():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => (form_2 => (net_3 => (acct_4 => (look_5 => \{Bq.Wv.Wv: (mypid_6 => (zid_7 => (grid_8 => (plist_9 => (mlist_10 => (names_11 => (me_12 => (snapms_13 => (evl_14 => (bubs_15 => (fxs_16 => (ui_17 => (text_18 => (+wv2_19 = {Bq.Wv.Wv{mypid_6, zid_7, grid_8, plist_9, mlist_10, names_11, me_12, snapms_13, Bq.push_ev(evl_14, text_18), bubs_15, fxs_16} : Bq.Wv}; Bq.CS.CS{scene_0, quitting_1, form_2, net_3, acct_4, look_5, wv2_19, ui_17})))))))))))))); \{}})))))); \{}}

@unsafe
def Bq.name_put():
  \{Nil: (pid_0 => (name_1 => [Bq.NameE.NameE{pid_0, name_1}])); \{Con: \{Bq.NameE.NameE: (pid2_0 => (n2_1 => (rest_2 => (pid_3 => (name_4 => (+apply_554 = {(pid2_0 => (n2_1 => (rest_2 => (pid_3 => (name_4 => (word => C.Bq.word_case(List<&1, Bq.NameE>, word, 0, (unit => Con{Bq.NameE.NameE{pid2_0, n2_1}, Bq.name_put(rest_2, pid_3, name_4)}), (_183_5 => Con{Bq.NameE.NameE{pid_3, name_4}, rest_2}), 0))))))) : (@+pid2_0: U32 -> (@+n2_1: C.Bq.String -> (@+rest_2: List<&1, Bq.NameE> -> (@+pid_3: U32 -> (@+name_4: C.Bq.String -> (@+___5: U32 -> List<&1, Bq.NameE>))))))}; apply_554(pid2_0, n2_1, rest_2, pid_3, name_4, C.Bq.bit(U32.is_eq(pid2_0, pid_3))))))))); \{}}; \{}}}

@unsafe
def Bq.srv_plr():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => (form_2 => (net_3 => (acct_4 => (look_5 => \{Bq.Wv.Wv: (mypid_6 => (zid_7 => (grid_8 => (plist_9 => (mlist_10 => (names_11 => (me_12 => (snapms_13 => (evl_14 => (bubs_15 => (fxs_16 => (ui_17 => (ns_18 => (text_19 => (+wv2_20 = {Bq.Wv.Wv{mypid_6, zid_7, grid_8, plist_9, mlist_10, Bq.name_put(names_11, Server.Bq.nth(ns_18, 0), text_19), me_12, snapms_13, evl_14, bubs_15, fxs_16} : Bq.Wv}; Bq.CS.CS{scene_0, quitting_1, form_2, net_3, acct_4, look_5, wv2_20, ui_17}))))))))))))))); \{}})))))); \{}}

@unsafe
def Bq.ME_PHASE():
  28

@unsafe
def Bq.srv_me():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => (form_2 => (net_3 => \{Bq.Acct.Acct: (coins_4 => (ownh_5 => (ownc_6 => (wno_7 => (phase_8 => (fame_9 => (over_10 => (look_11 => \{Bq.Wv.Wv: (mypid_12 => (zid_13 => (grid_14 => (plist_15 => (mlist_16 => (names_17 => (me_18 => (snapms_19 => (evl_20 => (bubs_21 => (fxs_22 => (ui_23 => (ns_24 => (+ac2_25 = {Bq.Acct.Acct{coins_4, ownh_5, ownc_6, wno_7, Server.Bq.nth(ns_24, Bq.ME_PHASE), fame_9, over_10} : Bq.Acct}; (+wv2_26 = {Bq.Wv.Wv{Server.Bq.nth(ns_24, 0), zid_13, grid_14, plist_15, mlist_16, names_17, ns_24, snapms_19, evl_20, bubs_21, fxs_22} : Bq.Wv}; Bq.CS.CS{scene_0, quitting_1, form_2, net_3, ac2_25, look_11, wv2_26, ui_23}))))))))))))))); \{}})))))))); \{}})))); \{}}

@unsafe
def Bq.mv_find():
  \{Nil: (mid_0 => Support.Bq.Maybe.none(C.Bq.Pair.Pair(U32, (__1 => U32)))); \{Con: \{Bq.MV.MV: (mid2_0 => (kind_1 => (rare_2 => (x_3 => (y_4 => (px_5 => (py_6 => (hp_7 => (mhp_8 => (rest_9 => (mid_10 => (+apply_555 = {(rest_0 => (mid_1 => (x_2 => (y_3 => (word => C.Bq.word_case(Result<&1, &1, Unit, Sigma<&1, &1, U32, (__5 => U32)>>, word, 0, (unit => Bq.mv_find(rest_0, mid_1)), (_139_4 => Support.Bq.Maybe.some(C.Bq.Pair.Pair(U32, (__5 => U32)), Tuple{x_2, y_3})), 0)))))) : (@+rest_0: List<&1, Bq.MV> -> (@+mid_1: U32 -> (@+x_2: U32 -> (@+y_3: U32 -> (@+___4: U32 -> Result<&1, &1, Unit, Sigma<&1, &1, U32, (__5 => U32)>>)))))}; apply_555(rest_9, mid_10, x_3, y_4, C.Bq.bit(U32.is_eq(mid2_0, mid_10))))))))))))))); \{}}; \{}}}

@unsafe
def Bq.prev_or():
  \{Done: (p_0 => (x_1 => (y_2 => p_0))); \{Fail: (u_0 => (x_1 => (y_2 => Tuple{x_1, y_2}))); \{}}}

@unsafe
def Bq.snap_mvs():
  (ns_0 => (word => C.Bq.word_case((@+old_2: List<&1, Bq.MV> -> List<&1, Bq.MV>), word, 0, (unit => (old_1 => Nil{})), (n2_1 => (old_2 => (+mid_3 = World.Bq.lget(ns_0, 0, 0); (+x_4 = World.Bq.lget(ns_0, 3, 0); (+y_5 = World.Bq.lget(ns_0, 4, 0); (+prev_6 = Bq.mv_find(old_2, mid_3); (+apply_556 = {(mid_0 => (ns_1 => (x_2 => (y_3 => (n2_4 => (old_5 => \{Tuple: (fst_6 => (snd_7 => Con{Bq.MV.MV{mid_0, World.Bq.lget(ns_1, 1, 0), World.Bq.lget(ns_1, 2, 0), x_2, y_3, fst_6, snd_7, World.Bq.lget(ns_1, 5, 1), World.Bq.lget(ns_1, 6, 1)}, Bq.snap_mvs(Support.Bq.List.drop(U32, 7, ns_1), n2_4, old_5)})); \{}})))))) : (@+mid_0: U32 -> (@+ns_1: List<&1, U32> -> (@+x_2: U32 -> (@+y_3: U32 -> (@+n2_4: U32 -> (@+old_5: List<&1, Bq.MV> -> (@+___6: Sigma<&1, &1, U32, (__6 => U32)> -> List<&1, Bq.MV>)))))))}; apply_556(mid_3, ns_0, x_4, y_5, n2_1, old_2, Bq.prev_or(prev_6, x_4, y_5))))))))), 1)))

@unsafe
def Bq.pv_find():
  \{Nil: (pid_0 => Support.Bq.Maybe.none(C.Bq.Pair.Pair(U32, (__1 => U32)))); \{Con: \{Bq.PV.PV: (pid2_0 => (x_1 => (y_2 => (px_3 => (py_4 => (dir_5 => (moving_6 => (st_7 => (lk_8 => (rest_9 => (pid_10 => (+apply_557 = {(rest_0 => (pid_1 => (x_2 => (y_3 => (word => C.Bq.word_case(Result<&1, &1, Unit, Sigma<&1, &1, U32, (__5 => U32)>>, word, 0, (unit => Bq.pv_find(rest_0, pid_1)), (_124_4 => Support.Bq.Maybe.some(C.Bq.Pair.Pair(U32, (__5 => U32)), Tuple{x_2, y_3})), 0)))))) : (@+rest_0: List<&1, Bq.PV> -> (@+pid_1: U32 -> (@+x_2: U32 -> (@+y_3: U32 -> (@+___4: U32 -> Result<&1, &1, Unit, Sigma<&1, &1, U32, (__5 => U32)>>)))))}; apply_557(rest_9, pid_10, x_1, y_2, C.Bq.bit(U32.is_eq(pid2_0, pid_10))))))))))))))); \{}}; \{}}}

@unsafe
def Bq.snap_pvs():
  (ns_0 => (word => C.Bq.word_case((@+old_2: List<&1, Bq.PV> -> C.Bq.Pair.Pair(List<&1, Bq.PV>, (__3 => List<&1, U32>))), word, 0, (unit => (old_1 => Tuple{Nil{}, ns_0})), (n2_1 => (old_2 => (+pid_3 = World.Bq.lget(ns_0, 0, 0); (+x_4 = World.Bq.lget(ns_0, 1, 0); (+y_5 = World.Bq.lget(ns_0, 2, 0); (+prev_6 = Bq.pv_find(old_2, pid_3); (+apply_558 = {(ns_0 => (pid_1 => (x_2 => (y_3 => (n2_4 => (old_5 => \{Tuple: (fst_6 => (snd_7 => (+st_8 = {Bq.PVs.PVs{World.Bq.lget(ns_0, 5, 1), World.Bq.lget(ns_0, 6, 1), World.Bq.lget(ns_0, 7, 1), World.Bq.lget(ns_0, 14, 0)} : Bq.PVs}; (+lk_9 = {Bq.Look.Look{World.Bq.lget(ns_0, 8, 0), World.Bq.lget(ns_0, 9, 0), World.Bq.lget(ns_0, 10, 0), World.Bq.lget(ns_0, 11, 0), World.Bq.lget(ns_0, 12, 0), World.Bq.lget(ns_0, 13, 0)} : Bq.Look}; (+pv_10 = {Bq.PV.PV{pid_1, x_2, y_3, fst_6, snd_7, World.Bq.lget(ns_0, 3, 0), World.Bq.lget(ns_0, 4, 0), st_8, lk_9} : Bq.PV}; (+apply_559 = {(pv_0 => \{Tuple: (fst_1 => (snd_2 => Tuple{Con{pv_0, fst_1}, snd_2})); \{}}) : (@+pv_0: Bq.PV -> (@+___1: Sigma<&1, &1, List<&1, Bq.PV>, (__1 => List<&1, U32>)> -> Sigma<&1, &1, List<&1, Bq.PV>, (__2 => List<&1, U32>)>))}; apply_559(pv_10, Bq.snap_pvs(Support.Bq.List.drop(U32, 15, ns_0), n2_4, old_5)))))))); \{}})))))) : (@+ns_0: List<&1, U32> -> (@+pid_1: U32 -> (@+x_2: U32 -> (@+y_3: U32 -> (@+n2_4: U32 -> (@+old_5: List<&1, Bq.PV> -> (@+___6: Sigma<&1, &1, U32, (__6 => U32)> -> Sigma<&1, &1, List<&1, Bq.PV>, (__7 => List<&1, U32>)>)))))))}; apply_558(ns_0, pid_3, x_4, y_5, n2_1, old_2, Bq.prev_or(prev_6, x_4, y_5))))))))), 1)))

@unsafe
def Bq.srv_snap():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => (form_2 => (net_3 => (acct_4 => (look_5 => \{Bq.Wv.Wv: (mypid_6 => (zid_7 => (grid_8 => (plist_9 => (mlist_10 => (names_11 => (me_12 => (snapms_13 => (evl_14 => (bubs_15 => (fxs_16 => (ui_17 => (ns_18 => (now_19 => (+np_20 = Server.Bq.nth(ns_18, 2); (+body_21 = Support.Bq.List.drop(U32, 3, ns_18); (+apply_560 = {(mlist_0 => (mypid_1 => (zid_2 => (grid_3 => (names_4 => (me_5 => (now_6 => (evl_7 => (bubs_8 => (fxs_9 => (scene_10 => (quitting_11 => (form_12 => (net_13 => (acct_14 => (look_15 => (ui_16 => \{Tuple: (fst_17 => (snd_18 => (+nm_19 = World.Bq.lget(snd_18, 0, 0); (+mvs_20 = Bq.snap_mvs(Support.Bq.List.drop(U32, 1, snd_18), nm_19, mlist_0); (+wv2_21 = {Bq.Wv.Wv{mypid_1, zid_2, grid_3, fst_17, mvs_20, names_4, me_5, now_6, evl_7, bubs_8, fxs_9} : Bq.Wv}; Bq.CS.CS{scene_10, quitting_11, form_12, net_13, acct_14, look_15, wv2_21, ui_16}))))); \{}}))))))))))))))))) : (@+mlist_0: List<&1, Bq.MV> -> (@+mypid_1: U32 -> (@+zid_2: U32 -> (@+grid_3: List<&1, U32> -> (@+names_4: List<&1, Bq.NameE> -> (@+me_5: List<&1, U32> -> (@+now_6: U32 -> (@+evl_7: List<&1, C.Bq.String> -> (@+bubs_8: List<&1, Bq.Bub> -> (@+fxs_9: List<&1, Bq.FXV> -> (@+scene_10: U32 -> (@+quitting_11: U32 -> (@+form_12: Bq.Form -> (@+net_13: Bq.Net -> (@+acct_14: Bq.Acct -> (@+look_15: Bq.Look -> (@+ui_16: Bq.Ui -> (@+___17: Sigma<&1, &1, List<&1, Bq.PV>, (__17 => List<&1, U32>)> -> Bq.CS))))))))))))))))))}; apply_560(mlist_10, mypid_6, zid_7, grid_8, names_11, me_12, now_19, evl_14, bubs_15, fxs_16, scene_0, quitting_1, form_2, net_3, acct_4, look_5, ui_17, Bq.snap_pvs(body_21, np_20, plist_9))))))))))))))))))); \{}})))))); \{}}

@unsafe
def Bq.hexval():
  (c_0 => (+apply_561 = {(c_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (c_0 - 48 : U32)), (_106_1 => ((c_0 - 97 : U32) + 10 : U32)), 0))) : (@+c_0: U32 -> (@+___1: U32 -> U32))}; apply_561(c_0, C.Bq.bit(U32.is_ge(c_0, 97)))))

@unsafe
def Bq.grid_of():
  \{Nil: Nil{}; \{Con: (c_0 => (rest_1 => Con{Bq.hexval(Support.Bq.Char.code(c_0)), Bq.grid_of(rest_1)})); \{}}}

@unsafe
def Bq.srv_zone():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => (form_2 => (net_3 => (acct_4 => (look_5 => \{Bq.Wv.Wv: (mypid_6 => (zid_7 => (grid_8 => (plist_9 => (mlist_10 => (names_11 => (me_12 => (snapms_13 => (evl_14 => (bubs_15 => (fxs_16 => \{Bq.Ui.Ui: (inv_open_17 => (quest_open_18 => (shop_open_19 => (dash_open_20 => (fame_open_21 => (chat_open_22 => (chatbuf_23 => (move_sent_24 => (ns_25 => (text_26 => (+wv2_27 = {Bq.Wv.Wv{mypid_6, Server.Bq.nth(ns_25, 0), Bq.grid_of(text_26), Nil{}, Nil{}, names_11, me_12, snapms_13, evl_14, bubs_15, fxs_16} : Bq.Wv}; (+ui2_28 = {Bq.Ui.Ui{inv_open_17, quest_open_18, shop_open_19, dash_open_20, fame_open_21, chat_open_22, chatbuf_23, 9} : Bq.Ui}; Bq.CS.CS{3, quitting_1, form_2, net_3, acct_4, look_5, wv2_27, ui2_28})))))))))))); \{}}))))))))))); \{}})))))); \{}}

@unsafe
def Bq.srv_discon():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => \{Bq.Form.Form: (focus_2 => (f_ip_3 => (f_port_4 => (f_name_5 => (err_6 => \{Bq.Net.Net: (net_on_7 => (sock_8 => (hosting_9 => (hostaddr_10 => (hostlog_11 => (hoststat_12 => (acct_13 => (look_14 => \{Bq.Wv.Wv: (mypid_15 => (zid_16 => (grid_17 => (plist_18 => (mlist_19 => (names_20 => (me_21 => (snapms_22 => (evl_23 => (bubs_24 => (fxs_25 => (ui_26 => (+fm2_27 = {Bq.Form.Form{focus_2, f_ip_3, f_port_4, f_name_5, C.Bq.text("disconnected from server")} : Bq.Form}; (+nt2_28 = {Bq.Net.Net{0, C.Bq.TCP.TCP{0}, hosting_9, hostaddr_10, hostlog_11, hoststat_12} : Bq.Net}; (+wv2_29 = {Bq.Wv.Wv{mypid_15, zid_16, grid_17, Nil{}, Nil{}, names_20, me_21, snapms_22, evl_23, bubs_24, fxs_25} : Bq.Wv}; Bq.CS.CS{0, quitting_1, fm2_27, nt2_28, acct_13, look_14, wv2_29, ui_26}))))))))))))))); \{}})))))))); \{}}))))); \{}})); \{}}

@unsafe
def Bq.srv_err():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => \{Bq.Form.Form: (focus_2 => (f_ip_3 => (f_port_4 => (f_name_5 => (err_6 => (net_7 => (acct_8 => (look_9 => (wv_10 => (ui_11 => (text_12 => Bq.CS.CS{scene_0, quitting_1, Bq.Form.Form{focus_2, f_ip_3, f_port_4, f_name_5, text_12}, net_7, acct_8, look_9, wv_10, ui_11}))))))))))); \{}})); \{}}

@unsafe
def Bq.scene_after_welcome():
  (scene_0 => (+apply_562 = {(word => C.Bq.word_case(U32, word, 0, (unit => 2), (_204_0 => 3), 0)) : (@+___0: U32 -> U32)}; apply_562(C.Bq.bit(U32.is_eq(scene_0, 3)))))

@unsafe
def Bq.srv_welcome():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => (form_2 => (net_3 => \{Bq.Acct.Acct: (coins_4 => (ownh_5 => (ownc_6 => (wno_7 => (phase_8 => (fame_9 => (over_10 => (look_11 => (wv_12 => (ui_13 => (ns_14 => (+ac2_15 = {Bq.Acct.Acct{Server.Bq.nth(ns_14, 0), Server.Bq.nth(ns_14, 1), Server.Bq.nth(ns_14, 2), Server.Bq.nth(ns_14, 3), Server.Bq.nth(ns_14, 4), fame_9, over_10} : Bq.Acct}; Bq.CS.CS{Bq.scene_after_welcome(scene_0), quitting_1, form_2, net_3, ac2_15, look_11, wv_12, ui_13})))))))))))); \{}})))); \{}}

@unsafe
def Bq.apply_srv():
  (cs_0 => (now_1 => (line_2 => (+apply_563 = {(cs_0 => (now_1 => \{Proto.Bq.Msg.Msg: (tag_2 => (ns_3 => (text_4 => (+apply_564 = {(cs_0 => (ns_1 => (text_2 => (tag_3 => (now_4 => \{False: (+apply_565 = {(cs_0 => (ns_1 => (text_2 => (tag_3 => (now_4 => \{False: (+apply_566 = {(cs_0 => (ns_1 => (text_2 => (tag_3 => (now_4 => \{False: (+apply_567 = {(cs_0 => (ns_1 => (text_2 => (tag_3 => (now_4 => \{False: (+apply_568 = {(cs_0 => (ns_1 => (text_2 => (tag_3 => (now_4 => \{False: (+apply_569 = {(cs_0 => (ns_1 => (text_2 => (tag_3 => \{False: (+apply_570 = {(cs_0 => (ns_1 => (text_2 => (tag_3 => \{False: (+apply_571 = {(cs_0 => (ns_1 => (text_2 => (tag_3 => \{False: (+apply_572 = {(cs_0 => (ns_1 => (text_2 => (tag_3 => \{False: (+apply_573 = {(cs_0 => (ns_1 => (text_2 => (tag_3 => \{False: (+apply_574 = {(cs_0 => (ns_1 => (text_2 => (tag_3 => \{False: (+apply_575 = {(cs_0 => (ns_1 => (text_2 => (tag_3 => \{False: (+apply_576 = {(cs_0 => (ns_1 => (text_2 => (tag_3 => \{False: (+apply_577 = {(cs_0 => (ns_1 => (text_2 => (tag_3 => \{False: (+apply_578 = {(cs_0 => (ns_1 => (text_2 => \{False: cs_0; \{True: Bq.srv_fp(cs_0, ns_1, text_2); \{}}}))) : (@+cs_0: Bq.CS -> (@+ns_1: List<&1, U32> -> (@+text_2: C.Bq.String -> (@+___3: Bool -> Bq.CS))))}; apply_578(cs_0, ns_1, text_2, Proto.Bq.is(tag_3, C.Bq.text("FP")))); \{True: Bq.srv_frun(cs_0, ns_1); \{}}})))) : (@+cs_0: Bq.CS -> (@+ns_1: List<&1, U32> -> (@+text_2: C.Bq.String -> (@+tag_3: C.Bq.String -> (@+___4: Bool -> Bq.CS)))))}; apply_577(cs_0, ns_1, text_2, tag_3, Proto.Bq.is(tag_3, C.Bq.text("FRUN")))); \{True: Bq.srv_fameb(cs_0); \{}}})))) : (@+cs_0: Bq.CS -> (@+ns_1: List<&1, U32> -> (@+text_2: C.Bq.String -> (@+tag_3: C.Bq.String -> (@+___4: Bool -> Bq.CS)))))}; apply_576(cs_0, ns_1, text_2, tag_3, Proto.Bq.is(tag_3, C.Bq.text("FAMEB")))); \{True: Bq.srv_start(cs_0, ns_1); \{}}})))) : (@+cs_0: Bq.CS -> (@+ns_1: List<&1, U32> -> (@+text_2: C.Bq.String -> (@+tag_3: C.Bq.String -> (@+___4: Bool -> Bq.CS)))))}; apply_575(cs_0, ns_1, text_2, tag_3, Proto.Bq.is(tag_3, C.Bq.text("START")))); \{True: Bq.srv_over(cs_0, ns_1, text_2); \{}}})))) : (@+cs_0: Bq.CS -> (@+ns_1: List<&1, U32> -> (@+text_2: C.Bq.String -> (@+tag_3: C.Bq.String -> (@+___4: Bool -> Bq.CS)))))}; apply_574(cs_0, ns_1, text_2, tag_3, Proto.Bq.is(tag_3, C.Bq.text("OVER")))); \{True: Bq.srv_fx(cs_0, ns_1); \{}}})))) : (@+cs_0: Bq.CS -> (@+ns_1: List<&1, U32> -> (@+text_2: C.Bq.String -> (@+tag_3: C.Bq.String -> (@+___4: Bool -> Bq.CS)))))}; apply_573(cs_0, ns_1, text_2, tag_3, Proto.Bq.is(tag_3, C.Bq.text("FX")))); \{True: Bq.srv_bubble(cs_0, ns_1, text_2); \{}}})))) : (@+cs_0: Bq.CS -> (@+ns_1: List<&1, U32> -> (@+text_2: C.Bq.String -> (@+tag_3: C.Bq.String -> (@+___4: Bool -> Bq.CS)))))}; apply_572(cs_0, ns_1, text_2, tag_3, Proto.Bq.is(tag_3, C.Bq.text("BUBBLE")))); \{True: Bq.srv_ev(cs_0, text_2); \{}}})))) : (@+cs_0: Bq.CS -> (@+ns_1: List<&1, U32> -> (@+text_2: C.Bq.String -> (@+tag_3: C.Bq.String -> (@+___4: Bool -> Bq.CS)))))}; apply_571(cs_0, ns_1, text_2, tag_3, Proto.Bq.is(tag_3, C.Bq.text("EV")))); \{True: Bq.srv_plr(cs_0, ns_1, text_2); \{}}})))) : (@+cs_0: Bq.CS -> (@+ns_1: List<&1, U32> -> (@+text_2: C.Bq.String -> (@+tag_3: C.Bq.String -> (@+___4: Bool -> Bq.CS)))))}; apply_570(cs_0, ns_1, text_2, tag_3, Proto.Bq.is(tag_3, C.Bq.text("PLR")))); \{True: Bq.srv_me(cs_0, ns_1); \{}}})))) : (@+cs_0: Bq.CS -> (@+ns_1: List<&1, U32> -> (@+text_2: C.Bq.String -> (@+tag_3: C.Bq.String -> (@+___4: Bool -> Bq.CS)))))}; apply_569(cs_0, ns_1, text_2, tag_3, Proto.Bq.is(tag_3, C.Bq.text("ME")))); \{True: Bq.srv_snap(cs_0, ns_1, now_4); \{}}}))))) : (@+cs_0: Bq.CS -> (@+ns_1: List<&1, U32> -> (@+text_2: C.Bq.String -> (@+tag_3: C.Bq.String -> (@+now_4: U32 -> (@+___5: Bool -> Bq.CS))))))}; apply_568(cs_0, ns_1, text_2, tag_3, now_4, Proto.Bq.is(tag_3, C.Bq.text("SNAP")))); \{True: Bq.srv_zone(cs_0, ns_1, text_2); \{}}}))))) : (@+cs_0: Bq.CS -> (@+ns_1: List<&1, U32> -> (@+text_2: C.Bq.String -> (@+tag_3: C.Bq.String -> (@+now_4: U32 -> (@+___5: Bool -> Bq.CS))))))}; apply_567(cs_0, ns_1, text_2, tag_3, now_4, Proto.Bq.is(tag_3, C.Bq.text("ZONE")))); \{True: Bq.srv_discon(cs_0); \{}}}))))) : (@+cs_0: Bq.CS -> (@+ns_1: List<&1, U32> -> (@+text_2: C.Bq.String -> (@+tag_3: C.Bq.String -> (@+now_4: U32 -> (@+___5: Bool -> Bq.CS))))))}; apply_566(cs_0, ns_1, text_2, tag_3, now_4, Proto.Bq.is(tag_3, C.Bq.text("DISCON")))); \{True: Bq.srv_err(cs_0, text_2); \{}}}))))) : (@+cs_0: Bq.CS -> (@+ns_1: List<&1, U32> -> (@+text_2: C.Bq.String -> (@+tag_3: C.Bq.String -> (@+now_4: U32 -> (@+___5: Bool -> Bq.CS))))))}; apply_565(cs_0, ns_1, text_2, tag_3, now_4, Proto.Bq.is(tag_3, C.Bq.text("ERR")))); \{True: Bq.srv_welcome(cs_0, ns_1); \{}}}))))) : (@+cs_0: Bq.CS -> (@+ns_1: List<&1, U32> -> (@+text_2: C.Bq.String -> (@+tag_3: C.Bq.String -> (@+now_4: U32 -> (@+___5: Bool -> Bq.CS))))))}; apply_564(cs_0, ns_3, text_4, tag_2, now_1, Proto.Bq.is(tag_2, C.Bq.text("WELCOME"))))))); \{}})) : (@+cs_0: Bq.CS -> (@+now_1: U32 -> (@+___2: Proto.Bq.Msg -> Bq.CS)))}; apply_563(cs_0, now_1, Proto.Bq.wire_dec(line_2))))))

@unsafe
def Bq.drain_rx():
  (cs_0 => (rx_1 => (word => C.Bq.word_case((@+now_3: U32 -> IO(Bq.CS)), word, 0, (unit => (now_2 => C.Bq.IO.pure(Bq.CS, cs_0))), (k2_2 => (now_3 => C.Bq.IO.bind(Support.Bq.Maybe(C.Bq.String), Bq.CS, C.Bq.Chan.poll(C.Bq.String, rx_1), \{Fail: (u_4 => C.Bq.IO.pure(Bq.CS, cs_0)); \{Done: (line_4 => Bq.drain_rx(Bq.apply_srv(cs_0, now_3, line_4), rx_1, k2_2, now_3)); \{}}}))), 1))))

@unsafe
def Bq.cs_hostlog():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => (form_2 => \{Bq.Net.Net: (net_on_3 => (sock_4 => (hosting_5 => (hostaddr_6 => (hostlog_7 => (hoststat_8 => (acct_9 => (look_10 => (wv_11 => (ui_12 => (line_13 => Bq.CS.CS{scene_0, quitting_1, form_2, Bq.Net.Net{net_on_3, sock_4, hosting_5, hostaddr_6, Support.Bq.List.take(C.Bq.String, 18, Con{line_13, hostlog_7}), hoststat_8}, acct_9, look_10, wv_11, ui_12}))))))))))); \{}}))); \{}}

@unsafe
def Bq.drain_hlog():
  (cs_0 => (lg_1 => (word => C.Bq.word_case(IO(Bq.CS), word, 0, (unit => C.Bq.IO.pure(Bq.CS, cs_0)), (k2_2 => C.Bq.IO.bind(Support.Bq.Maybe(C.Bq.String), Bq.CS, C.Bq.Chan.poll(C.Bq.String, lg_1), \{Fail: (u_3 => C.Bq.IO.pure(Bq.CS, cs_0)); \{Done: (line_3 => Bq.drain_hlog(Bq.cs_hostlog(cs_0, line_3), lg_1, k2_2)); \{}}})), 1))))

@unsafe
def Bq.cs_hoststat():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => (form_2 => \{Bq.Net.Net: (net_on_3 => (sock_4 => (hosting_5 => (hostaddr_6 => (hostlog_7 => (hoststat_8 => (acct_9 => (look_10 => (wv_11 => (ui_12 => (v_13 => Bq.CS.CS{scene_0, quitting_1, form_2, Bq.Net.Net{net_on_3, sock_4, hosting_5, hostaddr_6, hostlog_7, v_13}, acct_9, look_10, wv_11, ui_12}))))))))))); \{}}))); \{}}

@unsafe
def Bq.drain_stat():
  (cs_0 => (stat_1 => (word => C.Bq.word_case(IO(Bq.CS), word, 0, (unit => C.Bq.IO.pure(Bq.CS, cs_0)), (k2_2 => C.Bq.IO.bind(Support.Bq.Maybe(C.Bq.String), Bq.CS, C.Bq.Chan.poll(C.Bq.String, stat_1), \{Fail: (u_3 => C.Bq.IO.pure(Bq.CS, cs_0)); \{Done: (line_3 => Bq.drain_stat(Bq.cs_hoststat(cs_0, line_3), stat_1, k2_2)); \{}}})), 1))))

@unsafe
def Bq.bub_decay():
  \{Nil: Nil{}; \{Con: \{Bq.Bub.Bub: (pid_0 => (text_1 => (ttl_2 => (rest_3 => (+apply_579 = {(pid_0 => (text_1 => (ttl_2 => (rest_3 => (word => C.Bq.word_case(List<&1, Bq.Bub>, word, 0, (unit => Con{Bq.Bub.Bub{pid_0, text_1, (ttl_2 - 1 : U32)}, Bq.bub_decay(rest_3)}), (_927_4 => Bq.bub_decay(rest_3)), 0)))))) : (@+pid_0: U32 -> (@+text_1: C.Bq.String -> (@+ttl_2: U32 -> (@+rest_3: List<&1, Bq.Bub> -> (@+___4: U32 -> List<&1, Bq.Bub>)))))}; apply_579(pid_0, text_1, ttl_2, rest_3, C.Bq.bit(U32.is_le(ttl_2, 1)))))))); \{}}; \{}}}

@unsafe
def Bq.fx_decay():
  \{Nil: Nil{}; \{Con: \{Bq.FXV.FXV: (kind_0 => (x_1 => (y_2 => (ttl_3 => (rest_4 => (+apply_580 = {(kind_0 => (x_1 => (y_2 => (ttl_3 => (rest_4 => (word => C.Bq.word_case(List<&1, Bq.FXV>, word, 0, (unit => Con{Bq.FXV.FXV{kind_0, x_1, y_2, (ttl_3 - 1 : U32)}, Bq.fx_decay(rest_4)}), (_936_5 => Bq.fx_decay(rest_4)), 0))))))) : (@+kind_0: U32 -> (@+x_1: U32 -> (@+y_2: U32 -> (@+ttl_3: U32 -> (@+rest_4: List<&1, Bq.FXV> -> (@+___5: U32 -> List<&1, Bq.FXV>))))))}; apply_580(kind_0, x_1, y_2, ttl_3, rest_4, C.Bq.bit(U32.is_le(ttl_3, 1))))))))); \{}}; \{}}}

@unsafe
def Bq.cs_decay():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => (form_2 => (net_3 => (acct_4 => (look_5 => \{Bq.Wv.Wv: (mypid_6 => (zid_7 => (grid_8 => (plist_9 => (mlist_10 => (names_11 => (me_12 => (snapms_13 => (evl_14 => (bubs_15 => (fxs_16 => (ui_17 => (+wv2_18 = {Bq.Wv.Wv{mypid_6, zid_7, grid_8, plist_9, mlist_10, names_11, me_12, snapms_13, evl_14, Bq.bub_decay(bubs_15), Bq.fx_decay(fxs_16)} : Bq.Wv}; Bq.CS.CS{scene_0, quitting_1, form_2, net_3, acct_4, look_5, wv2_18, ui_17}))))))))))))); \{}})))))); \{}}

@unsafe
def Bq.spr():
  (tex_0 => (fi_1 => (fw_2 => (fh_3 => (x_4 => (y_5 => (sc_6 => (flip_7 => (tint_8 => [6, tex_0, (fi_1 * fw_2 : U32), 0, fw_2, fh_3, x_4, y_5, (sc_6 * 256 : U32), flip_7, tint_8])))))))))

@unsafe
def Bq.tile_row_cmds():
  (a_tiles_0 => \{Nil: (y_1 => (x_2 => Nil{})); \{Con: (t_1 => (rest_2 => (y_3 => (x_4 => Support.Bq.List.concat(U32, Bq.spr(a_tiles_0, t_1, 16, 16, (x_4 * 32 : U32), (y_3 * 32 : U32), 2, 0, 16777215), Bq.tile_row_cmds(a_tiles_0, rest_2, y_3, (x_4 + 1 : U32))))))); \{}}})

@unsafe
def Bq.grid_row():
  (grid_0 => (y_1 => Support.Bq.List.take(U32, Data.Bq.ZONE_W, Support.Bq.List.drop(U32, (y_1 * Data.Bq.ZONE_W : U32), grid_0))))

@unsafe
def Bq.tile_band():
  (a_tiles_0 => (grid_1 => (y0_2 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => Nil{}), (n2_3 => Support.Bq.List.concat(U32, Bq.tile_row_cmds(a_tiles_0, Bq.grid_row(grid_1, y0_2), y0_2, 0), Bq.tile_band(a_tiles_0, grid_1, (y0_2 + 1 : U32), n2_3))), 1)))))

@unsafe
def Bq.tiles_cmds():
  (a_tiles_0 => (grid_1 => (fork_b0_2 fork_b1_3 fork_b2_4 fork_b3_5 = Bq.tile_band(a_tiles_0, grid_1, 0, 4) Bq.tile_band(a_tiles_0, grid_1, 4, 4) Bq.tile_band(a_tiles_0, grid_1, 8, 4) Bq.tile_band(a_tiles_0, grid_1, 12, 5); +b0_2 = fork_b0_2; +b1_3 = fork_b1_3; +b2_4 = fork_b2_4; +b3_5 = fork_b3_5; Support.Bq.List.concat(U32, b0_2, Support.Bq.List.concat(U32, b1_3, Support.Bq.List.concat(U32, b2_4, b3_5))))))

@unsafe
def Bq.text_cmd():
  (x_0 => (y_1 => (size_2 => (color_3 => (s_4 => (+cps_5 = Support.Bq.List.map_2(s_4); (+n_6 = Support.Bq.List.length(U32, cps_5); Support.Bq.List.concat(U32, [3, x_0, y_1, size_2, color_3, n_6], cps_5))))))))

@unsafe
def Bq.npc_cmds():
  (a_0 => (zid_1 => (+apply_582 = {(zid_0 => \{Sprites.Bq.TexWld.TexWld: (elder_1 => (keeper_2 => (tiles_3 => (icons_4 => (slash_5 => (spark_6 => (+apply_583 = {(elder_0 => (keeper_1 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => Nil{}), (_1806_2 => (+e_3 = Bq.spr(elder_0, 0, 16, 20, (Data.Bq.ELDER_X * 32 : U32), ((Data.Bq.ELDER_Y * 32 : U32) - 16 : U32), 2, 0, 16777215); (+k_4 = Bq.spr(keeper_1, 0, 16, 20, ((Data.Bq.SHOP_X * 32 : U32) + 16 : U32), ((Data.Bq.SHOP_Y * 32 : U32) - 24 : U32), 2, 0, 16777215); (+n1_5 = Bq.text_cmd(((Data.Bq.ELDER_X * 32 : U32) - 8 : U32), ((Data.Bq.ELDER_Y * 32 : U32) - 28 : U32), 10, 10216804, C.Bq.text("Elder Fern")); (+n2_6 = Bq.text_cmd(((Data.Bq.SHOP_X * 32 : U32) + 6 : U32), ((Data.Bq.SHOP_Y * 32 : U32) - 36 : U32), 10, 16765286, C.Bq.text("Keeper")); Support.Bq.List.concat(U32, e_3, Support.Bq.List.concat(U32, k_4, Support.Bq.List.concat(U32, n1_5, n2_6)))))))), 0)))) : (@+elder_0: U32 -> (@+keeper_1: U32 -> (@+___2: U32 -> List<&1, U32>)))}; apply_583(elder_1, keeper_2, C.Bq.bit(U32.is_eq(zid_0, 0)))))))))); \{}}) : (@+zid_0: U32 -> (@+___1: Sprites.Bq.TexWld -> List<&1, U32>))}; apply_582(zid_1, Sprites.Bq.a_wld(a_0)))))

@unsafe
def Bq.lerp_px():
  (prev_0 => (cur_1 => (a_2 => (+pp_3 = (prev_0 * 32 : U32); (+cc_4 = (cur_1 * 32 : U32); (+apply_584 = {(pp_0 => (cc_1 => (a_2 => (word => C.Bq.word_case(U32, word, 0, (unit => (pp_0 - U32.shrn(((pp_0 - cc_1 : U32) * a_2 : U32), U32.to_nat(8)) : U32)), (_1520_3 => (pp_0 + U32.shrn(((cc_1 - pp_0 : U32) * a_2 : U32), U32.to_nat(8)) : U32)), 0))))) : (@+pp_0: U32 -> (@+cc_1: U32 -> (@+a_2: U32 -> (@+___3: U32 -> U32))))}; apply_584(pp_3, cc_4, a_2, C.Bq.bit(U32.is_ge(cc_4, pp_3)))))))))

@unsafe
def Bq.rare_tint():
  (rare_0 => (+apply_585 = {(word => C.Bq.word_case(U32, word, 0, (unit => 16777215), (_1639_0 => 4293444712), 0)) : (@+___0: U32 -> U32)}; apply_585(C.Bq.bit(U32.is_eq(rare_0, 1)))))

@unsafe
def Bq.mob_tex():
  (a_0 => (kind_1 => (+apply_586 = {(kind_0 => \{Sprites.Bq.TexMob.TexMob: (slime_1 => (spore_2 => (bat_3 => (golem_4 => (wolf_5 => (wisp_6 => (mossback_7 => (stonewarden_8 => (rimehowl_9 => (maw_10 => (+apply_587 = {(maw_0 => (rimehowl_1 => (kind_2 => (stonewarden_3 => (mossback_4 => (wisp_5 => (wolf_6 => (golem_7 => (bat_8 => (spore_9 => (slime_10 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_588 = {(maw_0 => (rimehowl_1 => (kind_2 => (stonewarden_3 => (mossback_4 => (wisp_5 => (wolf_6 => (golem_7 => (bat_8 => (spore_9 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_589 = {(maw_0 => (rimehowl_1 => (kind_2 => (stonewarden_3 => (mossback_4 => (wisp_5 => (wolf_6 => (golem_7 => (bat_8 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_590 = {(maw_0 => (rimehowl_1 => (kind_2 => (stonewarden_3 => (mossback_4 => (wisp_5 => (wolf_6 => (golem_7 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_591 = {(maw_0 => (rimehowl_1 => (kind_2 => (stonewarden_3 => (mossback_4 => (wisp_5 => (wolf_6 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_592 = {(maw_0 => (rimehowl_1 => (kind_2 => (stonewarden_3 => (mossback_4 => (wisp_5 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_593 = {(maw_0 => (rimehowl_1 => (kind_2 => (stonewarden_3 => (mossback_4 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_594 = {(maw_0 => (rimehowl_1 => (kind_2 => (stonewarden_3 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_595 = {(maw_0 => (rimehowl_1 => (word => C.Bq.word_case(U32, word, 0, (unit => maw_0), (_1619_2 => rimehowl_1), 0)))) : (@+maw_0: U32 -> (@+rimehowl_1: U32 -> (@+___2: U32 -> U32)))}; apply_595(maw_0, rimehowl_1, C.Bq.bit(U32.is_eq(kind_2, 8))))), (_1621_4 => stonewarden_3), 0)))))) : (@+maw_0: U32 -> (@+rimehowl_1: U32 -> (@+kind_2: U32 -> (@+stonewarden_3: U32 -> (@+___4: U32 -> U32)))))}; apply_594(maw_0, rimehowl_1, kind_2, stonewarden_3, C.Bq.bit(U32.is_eq(kind_2, 7))))), (_1623_5 => mossback_4), 0))))))) : (@+maw_0: U32 -> (@+rimehowl_1: U32 -> (@+kind_2: U32 -> (@+stonewarden_3: U32 -> (@+mossback_4: U32 -> (@+___5: U32 -> U32))))))}; apply_593(maw_0, rimehowl_1, kind_2, stonewarden_3, mossback_4, C.Bq.bit(U32.is_eq(kind_2, 6))))), (_1625_6 => wisp_5), 0)))))))) : (@+maw_0: U32 -> (@+rimehowl_1: U32 -> (@+kind_2: U32 -> (@+stonewarden_3: U32 -> (@+mossback_4: U32 -> (@+wisp_5: U32 -> (@+___6: U32 -> U32)))))))}; apply_592(maw_0, rimehowl_1, kind_2, stonewarden_3, mossback_4, wisp_5, C.Bq.bit(U32.is_eq(kind_2, 5))))), (_1627_7 => wolf_6), 0))))))))) : (@+maw_0: U32 -> (@+rimehowl_1: U32 -> (@+kind_2: U32 -> (@+stonewarden_3: U32 -> (@+mossback_4: U32 -> (@+wisp_5: U32 -> (@+wolf_6: U32 -> (@+___7: U32 -> U32))))))))}; apply_591(maw_0, rimehowl_1, kind_2, stonewarden_3, mossback_4, wisp_5, wolf_6, C.Bq.bit(U32.is_eq(kind_2, 4))))), (_1629_8 => golem_7), 0)))))))))) : (@+maw_0: U32 -> (@+rimehowl_1: U32 -> (@+kind_2: U32 -> (@+stonewarden_3: U32 -> (@+mossback_4: U32 -> (@+wisp_5: U32 -> (@+wolf_6: U32 -> (@+golem_7: U32 -> (@+___8: U32 -> U32)))))))))}; apply_590(maw_0, rimehowl_1, kind_2, stonewarden_3, mossback_4, wisp_5, wolf_6, golem_7, C.Bq.bit(U32.is_eq(kind_2, 3))))), (_1631_9 => bat_8), 0))))))))))) : (@+maw_0: U32 -> (@+rimehowl_1: U32 -> (@+kind_2: U32 -> (@+stonewarden_3: U32 -> (@+mossback_4: U32 -> (@+wisp_5: U32 -> (@+wolf_6: U32 -> (@+golem_7: U32 -> (@+bat_8: U32 -> (@+___9: U32 -> U32))))))))))}; apply_589(maw_0, rimehowl_1, kind_2, stonewarden_3, mossback_4, wisp_5, wolf_6, golem_7, bat_8, C.Bq.bit(U32.is_eq(kind_2, 2))))), (_1633_10 => spore_9), 0)))))))))))) : (@+maw_0: U32 -> (@+rimehowl_1: U32 -> (@+kind_2: U32 -> (@+stonewarden_3: U32 -> (@+mossback_4: U32 -> (@+wisp_5: U32 -> (@+wolf_6: U32 -> (@+golem_7: U32 -> (@+bat_8: U32 -> (@+spore_9: U32 -> (@+___10: U32 -> U32)))))))))))}; apply_588(maw_0, rimehowl_1, kind_2, stonewarden_3, mossback_4, wisp_5, wolf_6, golem_7, bat_8, spore_9, C.Bq.bit(U32.is_eq(kind_2, 1))))), (_1635_11 => slime_10), 0))))))))))))) : (@+maw_0: U32 -> (@+rimehowl_1: U32 -> (@+kind_2: U32 -> (@+stonewarden_3: U32 -> (@+mossback_4: U32 -> (@+wisp_5: U32 -> (@+wolf_6: U32 -> (@+golem_7: U32 -> (@+bat_8: U32 -> (@+spore_9: U32 -> (@+slime_10: U32 -> (@+___11: U32 -> U32))))))))))))}; apply_587(maw_10, rimehowl_9, kind_0, stonewarden_8, mossback_7, wisp_6, wolf_5, golem_4, bat_3, spore_2, slime_1, C.Bq.bit(U32.is_eq(kind_0, 0)))))))))))))); \{}}) : (@+kind_0: U32 -> (@+___1: Sprites.Bq.TexMob -> U32))}; apply_586(kind_1, Sprites.Bq.a_mob(a_0)))))

@unsafe
def Bq.mob_body():
  (a_0 => (kind_1 => (word => C.Bq.word_case((@+sx_3: U32 -> (@+sy_4: U32 -> (@+f_5: U32 -> (@+tint_6: U32 -> List<&1, U32>)))), word, 0, (unit => (sx_2 => (sy_3 => (f_4 => (tint_5 => Bq.spr(Bq.mob_tex(a_0, kind_1), f_4, 16, 16, sx_2, sy_3, 2, 0, tint_5)))))), (_1647_2 => (sx_3 => (sy_4 => (f_5 => (tint_6 => Bq.spr(Bq.mob_tex(a_0, kind_1), f_5, 32, 32, (sx_3 - 16 : U32), (sy_4 - 32 : U32), 2, 0, tint_6)))))), 0))))

@unsafe
def Bq.rect():
  (x_0 => (y_1 => (w_2 => (h_3 => (c_4 => [1, x_0, y_1, w_2, h_3, c_4])))))

@unsafe
def Bq.bar():
  (x_0 => (y_1 => (w_2 => (h_3 => (val_4 => (max_5 => (fg_6 => (bg_7 => (+fw_8 = ((w_2 * Support.Bq.U32.min(val_4, max_5) : U32) / Support.Bq.U32.max(max_5, 1) : U32); Support.Bq.List.concat(U32, Bq.rect(x_0, y_1, w_2, h_3, bg_7), Bq.rect(x_0, y_1, fw_8, h_3, fg_6)))))))))))

@unsafe
def Bq.mob_cmds():
  (a_0 => \{Nil: (alpha_1 => (f_2 => Nil{})); \{Con: \{Bq.MV.MV: (mid_1 => (kind_2 => (rare_3 => (x_4 => (y_5 => (px_6 => (py_7 => (hp_8 => (mhp_9 => (rest_10 => (alpha_11 => (f_12 => (+sx_13 = Bq.lerp_px(px_6, x_4, alpha_11); (+sy_14 = Bq.lerp_px(py_7, y_5, alpha_11); (+tint_15 = Bq.rare_tint(rare_3); (+big_16 = C.Bq.bit(U32.is_ge(kind_2, 6)); (+body_17 = Bq.mob_body(a_0, kind_2, big_16, sx_13, sy_14, f_12, tint_15); (+hbar_18 = Bq.bar(sx_13, (sy_14 - 6 : U32), (32 + (32 * big_16 : U32) : U32), 4, hp_8, mhp_9, 16734810, 3224377392); Support.Bq.List.concat(U32, body_17, Support.Bq.List.concat(U32, hbar_18, Bq.mob_cmds(a_0, rest_10, alpha_11, f_12))))))))))))))))))))); \{}}; \{}}})

@unsafe
def Bq.walk_frame():
  (word => C.Bq.word_case((@+tms_1: U32 -> U32), word, 0, (unit => (tms_0 => 0)), (_1671_0 => (tms_1 => ((tms_1 / 150 : U32) % 2 : U32))), 0))

@unsafe
def Bq.name_of():
  \{Nil: (pid_0 => C.Bq.text("???")); \{Con: \{Bq.NameE.NameE: (pid2_0 => (n2_1 => (rest_2 => (pid_3 => (+apply_596 = {(rest_0 => (pid_1 => (n2_2 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => Bq.name_of(rest_0, pid_1)), (_191_3 => n2_2), 0))))) : (@+rest_0: List<&1, Bq.NameE> -> (@+pid_1: U32 -> (@+n2_2: C.Bq.String -> (@+___3: U32 -> List<&1, Char>))))}; apply_596(rest_2, pid_3, n2_1, C.Bq.bit(U32.is_eq(pid2_0, pid_3)))))))); \{}}; \{}}}

@unsafe
def Bq.cape_part():
  (a_0 => (x_1 => (y_2 => (f_3 => (sc_4 => (flip_5 => (cape_6 => (+apply_598 = {(cape_0 => (f_1 => (x_2 => (y_3 => (sc_4 => (flip_5 => \{Sprites.Bq.TexPlr.TexPlr: (body_6 => (hair0_7 => (hair1_8 => (hair2_9 => (outfit_10 => (hat0_11 => (hat1_12 => (hat2_13 => (cape0_14 => (cape1_15 => (+apply_599 = {(cape_0 => (cape0_1 => (cape1_2 => (f_3 => (x_4 => (y_5 => (sc_6 => (flip_7 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => Bq.spr(Sprites.Bq.pick2((cape_0 - 1 : U32), cape0_1, cape1_2), f_3, 16, 20, x_4, y_5, sc_6, flip_7, 16777215)), (_1539_8 => Nil{}), 0)))))))))) : (@+cape_0: U32 -> (@+cape0_1: U32 -> (@+cape1_2: U32 -> (@+f_3: U32 -> (@+x_4: U32 -> (@+y_5: U32 -> (@+sc_6: U32 -> (@+flip_7: U32 -> (@+___8: U32 -> List<&1, U32>)))))))))}; apply_599(cape_0, cape0_14, cape1_15, f_1, x_2, y_3, sc_4, flip_5, C.Bq.bit(U32.is_eq(cape_0, 0)))))))))))))); \{}})))))) : (@+cape_0: U32 -> (@+f_1: U32 -> (@+x_2: U32 -> (@+y_3: U32 -> (@+sc_4: U32 -> (@+flip_5: U32 -> (@+___6: Sprites.Bq.TexPlr -> List<&1, U32>)))))))}; apply_598(cape_6, f_3, x_1, y_2, sc_4, flip_5, Sprites.Bq.a_plr(a_0))))))))))

@unsafe
def Bq.hat_part():
  (a_0 => (x_1 => (y_2 => (f_3 => (sc_4 => (flip_5 => (hat_6 => (+apply_602 = {(hat_0 => (x_1 => (y_2 => (sc_3 => (f_4 => (flip_5 => \{Sprites.Bq.TexPlr.TexPlr: (body_6 => (hair0_7 => (hair1_8 => (hair2_9 => (outfit_10 => (hat0_11 => (hat1_12 => (hat2_13 => (cape0_14 => (cape1_15 => (+apply_603 = {(hat_0 => (hat0_1 => (hat1_2 => (hat2_3 => (x_4 => (y_5 => (sc_6 => (f_7 => (flip_8 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => Bq.spr(Sprites.Bq.pick3((hat_0 - 1 : U32), hat0_1, hat1_2, hat2_3), 0, 16, 20, x_4, ((y_5 - (3 * sc_6 : U32) : U32) + (f_7 * sc_6 : U32) : U32), sc_6, flip_8, 16777215)), (_1559_9 => Nil{}), 0))))))))))) : (@+hat_0: U32 -> (@+hat0_1: U32 -> (@+hat1_2: U32 -> (@+hat2_3: U32 -> (@+x_4: U32 -> (@+y_5: U32 -> (@+sc_6: U32 -> (@+f_7: U32 -> (@+flip_8: U32 -> (@+___9: U32 -> List<&1, U32>))))))))))}; apply_603(hat_0, hat0_11, hat1_12, hat2_13, x_1, y_2, sc_3, f_4, flip_5, C.Bq.bit(U32.is_eq(hat_0, 0)))))))))))))); \{}})))))) : (@+hat_0: U32 -> (@+x_1: U32 -> (@+y_2: U32 -> (@+sc_3: U32 -> (@+f_4: U32 -> (@+flip_5: U32 -> (@+___6: Sprites.Bq.TexPlr -> List<&1, U32>)))))))}; apply_602(hat_6, x_1, y_2, sc_4, f_3, flip_5, Sprites.Bq.a_plr(a_0))))))))))

@unsafe
def Bq.char_cmds():
  (a_0 => (x_1 => (y_2 => (f_3 => (sc_4 => (flip_5 => (skin_6 => (hairs_7 => (hairc_8 => (shirt_9 => (hat_10 => (cape_11 => (+capep_12 = Bq.cape_part(a_0, x_1, y_2, f_3, sc_4, flip_5, cape_11); (+hatp_13 = Bq.hat_part(a_0, x_1, y_2, f_3, sc_4, flip_5, hat_10); (+apply_607 = {(hairs_0 => (capep_1 => (f_2 => (x_3 => (y_4 => (sc_5 => (flip_6 => (skin_7 => (shirt_8 => (hairc_9 => (hatp_10 => \{Sprites.Bq.TexPlr.TexPlr: (body_11 => (hair0_12 => (hair1_13 => (hair2_14 => (outfit_15 => (hat0_16 => (hat1_17 => (hat2_18 => (cape0_19 => (cape1_20 => (+hairtex_21 = Sprites.Bq.pick3(hairs_0, hair0_12, hair1_13, hair2_14); Support.Bq.List.flatten(U32, [capep_1, Bq.spr(body_11, f_2, 16, 20, x_3, y_4, sc_5, flip_6, Sprites.Bq.skin_tint(skin_7)), Bq.spr(outfit_15, f_2, 16, 20, x_3, y_4, sc_5, flip_6, Sprites.Bq.shirt_tint(shirt_8)), Bq.spr(hairtex_21, f_2, 16, 20, x_3, y_4, sc_5, flip_6, Sprites.Bq.hair_tint(hairc_9)), hatp_10])))))))))))); \{}}))))))))))) : (@+hairs_0: U32 -> (@+capep_1: List<&1, U32> -> (@+f_2: U32 -> (@+x_3: U32 -> (@+y_4: U32 -> (@+sc_5: U32 -> (@+flip_6: U32 -> (@+skin_7: U32 -> (@+shirt_8: U32 -> (@+hairc_9: U32 -> (@+hatp_10: List<&1, U32> -> (@+___11: Sprites.Bq.TexPlr -> List<&1, U32>))))))))))))}; apply_607(hairs_7, capep_12, f_3, x_1, y_2, sc_4, flip_5, skin_6, shirt_9, hairc_8, hatp_13, Sprites.Bq.a_plr(a_0)))))))))))))))))

@unsafe
def Bq.name_col():
  (word => C.Bq.word_case(U32, word, 0, (unit => 16777215), (_1673_0 => 16765286), 0))

@unsafe
def Bq.dead_cmds():
  (word => C.Bq.word_case((@+sx_1: U32 -> (@+sy_2: U32 -> List<&1, U32>)), word, 0, (unit => (sx_0 => (sy_1 => Nil{}))), (_1677_0 => (sx_1 => (sy_2 => Bq.text_cmd((sx_1 - 6 : U32), (sy_2 - 42 : U32), 12, 16744576, C.Bq.text("R.I.P"))))), 0))

@unsafe
def Bq.plr_cmds():
  (a_0 => \{Nil: (names_1 => (mypid_2 => (alpha_3 => (tms_4 => Nil{})))); \{Con: \{Bq.PV.PV: (pid_1 => (x_2 => (y_3 => (px_4 => (py_5 => (dir_6 => (moving_7 => \{Bq.PVs.PVs: (lv_8 => (hp_9 => (mhp_10 => (dead_11 => \{Bq.Look.Look: (skin_12 => (hairs_13 => (hairc_14 => (shirt_15 => (hat_16 => (cape_17 => (rest_18 => (names_19 => (mypid_20 => (alpha_21 => (tms_22 => (+sx_23 = Bq.lerp_px(px_4, x_2, alpha_21); (+sy_24 = Bq.lerp_px(py_5, y_3, alpha_21); (+f_25 = Bq.walk_frame(moving_7, tms_22); (+flip_26 = C.Bq.bit(U32.is_eq(dir_6, 0)); (+nm_27 = Bq.name_of(names_19, pid_1); (+body_28 = Bq.char_cmds(a_0, sx_23, (sy_24 - 16 : U32), f_25, 2, flip_26, skin_12, hairs_13, hairc_14, shirt_15, hat_16, cape_17); (+tag_29 = Bq.text_cmd((sx_23 - 4 : U32), (sy_24 - 30 : U32), 10, Bq.name_col(C.Bq.bit(U32.is_eq(pid_1, mypid_20))), nm_27); (+hbar_30 = Bq.bar(sx_23, (sy_24 - 20 : U32), 32, 3, hp_9, mhp_10, 6539085, 3224383536); (+deadfx_31 = Bq.dead_cmds(dead_11, sx_23, sy_24); Support.Bq.List.concat(U32, body_28, Support.Bq.List.concat(U32, tag_29, Support.Bq.List.concat(U32, hbar_30, Support.Bq.List.concat(U32, deadfx_31, Bq.plr_cmds(a_0, rest_18, names_19, mypid_20, alpha_21, tms_22))))))))))))))))))))))))); \{}})))); \{}}))))))); \{}}; \{}}})

@unsafe
def Bq.fx_tex():
  (slash_0 => (spark_1 => (kind_2 => (+apply_608 = {(spark_0 => (slash_1 => (word => C.Bq.word_case(U32, word, 0, (unit => spark_0), (_1718_2 => slash_1), 0)))) : (@+spark_0: U32 -> (@+slash_1: U32 -> (@+___2: U32 -> U32)))}; apply_608(spark_1, slash_0, C.Bq.word_or(C.Bq.bit(U32.is_eq(kind_2, 0)), C.Bq.bit(U32.is_eq(kind_2, 4))))))))

@unsafe
def Bq.fx_tint():
  (kind_0 => (+apply_609 = {(kind_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_610 = {(word => C.Bq.word_case(U32, word, 0, (unit => 16777215), (_1721_0 => 4294955366), 0)) : (@+___0: U32 -> U32)}; apply_610(C.Bq.bit(U32.is_eq(kind_0, 2))))), (_1723_1 => 4294929259), 0))) : (@+kind_0: U32 -> (@+___1: U32 -> U32))}; apply_609(kind_0, C.Bq.bit(U32.is_eq(kind_0, 4)))))

@unsafe
def Bq.fx_cmds_go():
  (slash_0 => (spark_1 => \{Nil: Nil{}; \{Con: \{Bq.FXV.FXV: (kind_2 => (x_3 => (y_4 => (ttl_5 => (rest_6 => (+fi_7 = ((20 - ttl_5 : U32) / 10 : U32); (+tex_8 = Bq.fx_tex(slash_0, spark_1, kind_2); Support.Bq.List.concat(U32, Bq.spr(tex_8, (fi_7 .&. 1 : U32), 16, 16, (x_3 * 32 : U32), ((y_4 * 32 : U32) - 8 : U32), 2, 0, Bq.fx_tint(kind_2)), Bq.fx_cmds_go(slash_0, spark_1, rest_6))))))))); \{}}; \{}}}))

@unsafe
def Bq.assets_fx():
  (a_0 => (+apply_611 = {\{Sprites.Bq.TexWld.TexWld: (elder_0 => (keeper_1 => (tiles_2 => (icons_3 => (slash_4 => (spark_5 => Tuple{slash_4, spark_5})))))); \{}} : (@+___0: Sprites.Bq.TexWld -> Sigma<&1, &1, U32, (__1 => U32)>)}; apply_611(Sprites.Bq.a_wld(a_0))))

@unsafe
def Bq.fx_cmds():
  (a_0 => (fs_1 => (+apply_612 = {(fs_0 => \{Tuple: (fst_1 => (snd_2 => Bq.fx_cmds_go(fst_1, snd_2, fs_0))); \{}}) : (@+fs_0: List<&1, Bq.FXV> -> (@+___1: Sigma<&1, &1, U32, (__1 => U32)> -> List<&1, U32>))}; apply_612(fs_1, Bq.assets_fx(a_0)))))

@unsafe
def Bq.snd_pick():
  (hit_0 => (lvl_1 => (kind_2 => (+apply_613 = {(hit_0 => (lvl_1 => (word => C.Bq.word_case(U32, word, 0, (unit => hit_0), (_1742_2 => lvl_1), 0)))) : (@+hit_0: U32 -> (@+lvl_1: U32 -> (@+___2: U32 -> U32)))}; apply_613(hit_0, lvl_1, C.Bq.bit(U32.is_eq(kind_2, 2)))))))

@unsafe
def Bq.fx_snd():
  (hit_0 => (lvl_1 => \{Nil: Nil{}; \{Con: \{Bq.FXV.FXV: (kind_2 => (x_3 => (y_4 => (ttl_5 => (rest_6 => (+apply_614 = {(hit_0 => (lvl_1 => (rest_2 => (kind_3 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => Bq.fx_snd(hit_0, lvl_1, rest_2)), (_1753_4 => Support.Bq.List.concat(U32, [7, Bq.snd_pick(hit_0, lvl_1, kind_3)], Bq.fx_snd(hit_0, lvl_1, rest_2))), 0)))))) : (@+hit_0: U32 -> (@+lvl_1: U32 -> (@+rest_2: List<&1, Bq.FXV> -> (@+kind_3: U32 -> (@+___4: U32 -> List<&1, U32>)))))}; apply_614(hit_0, lvl_1, rest_6, kind_2, C.Bq.bit(U32.is_eq(ttl_5, 19))))))))); \{}}; \{}}}))

@unsafe
def Bq.bub_cmds():
  \{Nil: (ps_0 => (alpha_1 => Nil{})); \{Con: \{Bq.Bub.Bub: (pid_0 => (text_1 => (ttl_2 => (rest_3 => (ps_4 => (alpha_5 => (+apply_615 = {(rest_0 => (ps_1 => (alpha_2 => (text_3 => \{Fail: (error_4 => Bq.bub_cmds(rest_0, ps_1, alpha_2)); \{Done: (value_4 => (+apply_616 = {(text_0 => (rest_1 => (ps_2 => (alpha_3 => \{Tuple: (fst_4 => (snd_5 => (+w_6 = (((13 * Support.Bq.String.length(text_0) : U32) / 2 : U32) + 10 : U32); (+bx_7 = (fst_4 * 32 : U32); Support.Bq.List.concat(U32, Bq.rect(bx_7, ((snd_5 * 32 : U32) - 44 : U32), w_6, 16, 3774871792), Support.Bq.List.concat(U32, Bq.text_cmd((bx_7 + 4 : U32), ((snd_5 * 32 : U32) - 42 : U32), 10, 3158080, text_0), Bq.bub_cmds(rest_1, ps_2, alpha_3))))))); \{}})))) : (@+text_0: C.Bq.String -> (@+rest_1: List<&1, Bq.Bub> -> (@+ps_2: List<&1, Bq.PV> -> (@+alpha_3: U32 -> (@+___4: Sigma<&1, &1, U32, (__4 => U32)> -> List<&1, U32>)))))}; apply_616(text_3, rest_0, ps_1, alpha_2, value_4))); \{}}})))) : (@+rest_0: List<&1, Bq.Bub> -> (@+ps_1: List<&1, Bq.PV> -> (@+alpha_2: U32 -> (@+text_3: C.Bq.String -> (@+___4: Result<&1, &1, Unit, Sigma<&1, &1, U32, (__4 => U32)>> -> List<&1, U32>)))))}; apply_615(rest_3, ps_4, alpha_5, text_1, Bq.pv_find(ps_4, pid_0))))))))); \{}}; \{}}}

@unsafe
def Bq.world_cmds():
  (a_0 => \{Bq.Wv.Wv: (mypid_1 => (zid_2 => (grid_3 => (plist_4 => (mlist_5 => (names_6 => (me_7 => (snapms_8 => (evl_9 => (bubs_10 => (fxs_11 => (tms_12 => (snds_13 => (+alpha_14 = Support.Bq.U32.min(256, (((tms_12 - snapms_8 : U32) * 256 : U32) / Data.Bq.TICK_MS : U32)); (+mobf_15 = ((tms_12 / 300 : U32) % 2 : U32); (+tl_16 = Bq.tiles_cmds(Sprites.Bq.a_tiles(a_0), grid_3); (+np_17 = Bq.npc_cmds(a_0, zid_2); (+mb_18 = Bq.mob_cmds(a_0, mlist_5, alpha_14, mobf_15); (+pl_19 = Bq.plr_cmds(a_0, plist_4, names_6, mypid_1, alpha_14, tms_12); (+fx_20 = Bq.fx_cmds(a_0, fxs_11); (+apply_617 = {(fxs_0 => (bubs_1 => (plist_2 => (alpha_3 => (tl_4 => (np_5 => (mb_6 => (pl_7 => \{Tuple: (fst_8 => (snd_9 => (fx_10 => (+sn_11 = Bq.fx_snd(fst_8, snd_9, fxs_0); (+bb_12 = Bq.bub_cmds(bubs_1, plist_2, alpha_3); Support.Bq.List.concat(U32, tl_4, Support.Bq.List.concat(U32, np_5, Support.Bq.List.concat(U32, mb_6, Support.Bq.List.concat(U32, pl_7, Support.Bq.List.concat(U32, fx_10, Support.Bq.List.concat(U32, sn_11, bb_12))))))))))); \{}})))))))) : (@+fxs_0: List<&1, Bq.FXV> -> (@+bubs_1: List<&1, Bq.Bub> -> (@+plist_2: List<&1, Bq.PV> -> (@+alpha_3: U32 -> (@+tl_4: List<&1, U32> -> (@+np_5: List<&1, U32> -> (@+mb_6: List<&1, U32> -> (@+pl_7: List<&1, U32> -> (@+___8: Sigma<&1, &1, U32, (__8 => U32)> -> (@+__9: List<&1, U32> -> List<&1, U32>))))))))))}; apply_617(fxs_11, bubs_10, plist_4, alpha_14, tl_16, np_17, mb_18, pl_19, snds_13, fx_20)))))))))))))))))))))); \{}})

@unsafe
def Bq.cs_wv():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => (form_2 => (net_3 => (acct_4 => (look_5 => (wv_6 => (ui_7 => wv_6)))))))); \{}}

@unsafe
def Bq.cs_me():
  (cs_0 => (+apply_618 = {\{Bq.Wv.Wv: (mypid_0 => (zid_1 => (grid_2 => (plist_3 => (mlist_4 => (names_5 => (me_6 => (snapms_7 => (evl_8 => (bubs_9 => (fxs_10 => me_6))))))))))); \{}} : (@+___0: Bq.Wv -> List<&1, U32>)}; apply_618(Bq.cs_wv(cs_0))))

@unsafe
def Bq.meg():
  (me_0 => (i_1 => World.Bq.lget(me_0, i_1, 0)))

@unsafe
def Bq.ME_HP():
  1

@unsafe
def Bq.ME_MHP():
  2

@unsafe
def Bq.ME_XP():
  3

@unsafe
def Bq.ME_XPN():
  4

@unsafe
def Bq.ME_LV():
  6

@unsafe
def Bq.ME_GOLD():
  5

@unsafe
def Bq.pot_hud():
  (a_0 => (n_1 => Support.Bq.List.concat(U32, Bq.spr(Sprites.Bq.a_icons(a_0), 0, 16, 16, 250, 556, 2, 0, 16777215), Bq.text_cmd(284, 566, 14, 16777215, Support.Bq.List.concat(Char, C.Bq.text("x"), Support.Bq.U32.show(n_1))))))

@unsafe
def Bq.ME_POTS():
  15

@unsafe
def Bq.spin_hud():
  (cd_0 => (+apply_620 = {(cd_0 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => Bq.text_cmd(250, 594, 12, 8952234, Support.Bq.List.concat(Char, C.Bq.text("E spin "), Support.Bq.U32.show(cd_0)))), (_1813_1 => Bq.text_cmd(250, 594, 12, 10216804, C.Bq.text("E spin READY"))), 0))) : (@+cd_0: U32 -> (@+___1: U32 -> List<&1, U32>))}; apply_620(cd_0, C.Bq.bit(U32.is_eq(cd_0, 0)))))

@unsafe
def Bq.ME_SPINCD():
  24

@unsafe
def Bq.ME_SCORE():
  23

@unsafe
def Bq.sig_dot():
  (x_0 => (y_1 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => [2, (x_0 - 7 : U32), (y_1 - 7 : U32), 14, 14, 5596791]), (_1817_2 => [4, x_0, y_1, 7, 16765286]), 0))))

@unsafe
def Bq.sigil_hud():
  (s_0 => (+a_1 = Bq.sig_dot(700, 580, (s_0 .&. 1 : U32)); (+b_2 = Bq.sig_dot(720, 580, (U32.shrn(s_0, U32.to_nat(1)) .&. 1 : U32)); (+c_3 = Bq.sig_dot(740, 580, (U32.shrn(s_0, U32.to_nat(2)) .&. 1 : U32)); (+t_4 = Bq.text_cmd(760, 576, 12, 12110814, C.Bq.text("sigils")); Support.Bq.List.concat(U32, a_1, Support.Bq.List.concat(U32, b_2, Support.Bq.List.concat(U32, c_3, t_4))))))))

@unsafe
def Bq.ME_SIGILS():
  22

@unsafe
def Bq.ME_WATK():
  25

@unsafe
def Bq.ME_DF():
  26

@unsafe
def Bq.ME_CRIT():
  27

@unsafe
def Bq.ME_PTS():
  7

@unsafe
def Bq.atkdef_str():
  (me_0 => Support.Bq.String.flatten([C.Bq.text("atk "), Support.Bq.U32.show(Bq.meg(me_0, Bq.ME_WATK)), C.Bq.text("  def "), Support.Bq.U32.show(Bq.meg(me_0, Bq.ME_DF)), C.Bq.text("  crit "), Support.Bq.U32.show(Bq.meg(me_0, Bq.ME_CRIT)), C.Bq.text("%  pts "), Support.Bq.U32.show(Bq.meg(me_0, Bq.ME_PTS))]))

@unsafe
def Bq.ME_MAINQ():
  16

@unsafe
def Bq.quest_extra():
  (q_0 => (cull_1 => (+apply_621 = {(cull_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => Nil{}), (_1826_1 => Support.Bq.String.flatten([C.Bq.text(" ("), Support.Bq.U32.show(cull_0), C.Bq.text("/"), Support.Bq.U32.show(Data.Bq.MQ_CULL_N), C.Bq.text(")")])), 0))) : (@+cull_0: U32 -> (@+___1: U32 -> List<&1, Char>))}; apply_621(cull_1, C.Bq.bit(U32.is_eq(q_0, 1))))))

@unsafe
def Bq.ME_CULL():
  17

@unsafe
def Bq.quest_chip():
  (cs_0 => (+me_1 = Bq.cs_me(cs_0); (+q_2 = Bq.meg(me_1, Bq.ME_MAINQ); (+extra_3 = Bq.quest_extra(q_2, Bq.meg(me_1, Bq.ME_CULL)); Support.Bq.List.concat(U32, Bq.rect(8, 8, 420, 22, 3222936110), Bq.text_cmd(14, 12, 12, 16765286, Support.Bq.List.concat(Char, Data.Bq.mainq_text(q_2), extra_3)))))))

@unsafe
def Bq.log_cmds_go():
  \{Nil: (y_0 => Nil{}); \{Con: (l_0 => (rest_1 => (y_2 => Support.Bq.List.concat(U32, Support.Bq.List.concat(U32, Bq.rect(8, y_2, (((13 * Support.Bq.String.length(l_0) : U32) / 2 : U32) + 14 : U32), 16, 2416971808), Bq.text_cmd(12, (y_2 + 3 : U32), 10, 15263984, l_0)), Bq.log_cmds_go(rest_1, (y_2 - 18 : U32)))))); \{}}}

@unsafe
def Bq.cs_evl():
  (cs_0 => (+apply_628 = {\{Bq.Wv.Wv: (mypid_0 => (zid_1 => (grid_2 => (plist_3 => (mlist_4 => (names_5 => (me_6 => (snapms_7 => (evl_8 => (bubs_9 => (fxs_10 => evl_8))))))))))); \{}} : (@+___0: Bq.Wv -> List<&1, List<&1, Char>>)}; apply_628(Bq.cs_wv(cs_0))))

@unsafe
def Bq.log_cmds():
  (cs_0 => Bq.log_cmds_go(Bq.cs_evl(cs_0), 524))

@unsafe
def Bq.hud_cmds():
  (cs_0 => (a_1 => (tms_2 => (+me_3 = Bq.cs_me(cs_0); (+hp_4 = Bq.meg(me_3, Bq.ME_HP); (+mh_5 = Bq.meg(me_3, Bq.ME_MHP); (+xp_6 = Bq.meg(me_3, Bq.ME_XP); (+xn_7 = Bq.meg(me_3, Bq.ME_XPN); (+base_8 = Bq.rect(0, 544, 960, 96, 4028242478); (+hpb_9 = Bq.bar(16, 556, 220, 16, hp_4, mh_5, 15223391, 2150641728); (+hpt_10 = Bq.text_cmd(20, 558, 12, 16777215, Support.Bq.List.concat(Char, C.Bq.text("HP "), Support.Bq.List.concat(Char, Support.Bq.U32.show(hp_4), Support.Bq.List.concat(Char, C.Bq.text("/"), Support.Bq.U32.show(mh_5))))); (+xpb_11 = Bq.bar(16, 578, 220, 10, xp_6, xn_7, 6608882, 2150641728); (+lvt_12 = Bq.text_cmd(16, 594, 20, 16765286, Support.Bq.List.concat(Char, C.Bq.text("Lv "), Support.Bq.U32.show(Bq.meg(me_3, Bq.ME_LV)))); (+gold_13 = Bq.text_cmd(100, 594, 16, 16765286, Support.Bq.List.concat(Char, Support.Bq.U32.show(Bq.meg(me_3, Bq.ME_GOLD)), C.Bq.text("g"))); (+pots_14 = Bq.pot_hud(a_1, Bq.meg(me_3, Bq.ME_POTS)); (+spin_15 = Bq.spin_hud(Bq.meg(me_3, Bq.ME_SPINCD)); (+score_16 = Bq.text_cmd(700, 556, 16, 16777215, Support.Bq.List.concat(Char, C.Bq.text("score "), Support.Bq.U32.show(Bq.meg(me_3, Bq.ME_SCORE)))); (+sig_17 = Bq.sigil_hud(Bq.meg(me_3, Bq.ME_SIGILS)); (+stat_18 = Bq.text_cmd(360, 556, 12, 12110814, Bq.atkdef_str(me_3)); (+hint_19 = Bq.text_cmd(360, 616, 10, 8952234, C.Bq.text("WASD move  SPACE atk  E spin  Q potion  F talk/enter  I inv  B shop  TAB quests  T chat  H fame")); (+qst_20 = Bq.quest_chip(cs_0); (+logl_21 = Bq.log_cmds(cs_0); Support.Bq.List.concat(U32, base_8, Support.Bq.List.concat(U32, hpb_9, Support.Bq.List.concat(U32, hpt_10, Support.Bq.List.concat(U32, xpb_11, Support.Bq.List.concat(U32, lvt_12, Support.Bq.List.concat(U32, gold_13, Support.Bq.List.concat(U32, pots_14, Support.Bq.List.concat(U32, spin_15, Support.Bq.List.concat(U32, score_16, Support.Bq.List.concat(U32, sig_17, Support.Bq.List.concat(U32, stat_18, Support.Bq.List.concat(U32, hint_19, Support.Bq.List.concat(U32, qst_20, logl_21)))))))))))))))))))))))))))))))))))

@unsafe
def Bq.cs_chatbuf():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => (form_2 => (net_3 => (acct_4 => (look_5 => (wv_6 => \{Bq.Ui.Ui: (inv_open_7 => (quest_open_8 => (shop_open_9 => (dash_open_10 => (fame_open_11 => (chat_open_12 => (chatbuf_13 => (move_sent_14 => chatbuf_13)))))))); \{}}))))))); \{}}

@unsafe
def Bq.cs_flags():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => (form_2 => (net_3 => (acct_4 => (look_5 => (wv_6 => \{Bq.Ui.Ui: (inv_open_7 => (quest_open_8 => (shop_open_9 => (dash_open_10 => (fame_open_11 => (chat_open_12 => (chatbuf_13 => (move_sent_14 => Tuple{inv_open_7, Tuple{quest_open_8, Tuple{shop_open_9, Tuple{dash_open_10, Tuple{fame_open_11, Tuple{chat_open_12, move_sent_14}}}}}})))))))); \{}}))))))); \{}}

@unsafe
def Bq.chat_cmds():
  (cs_0 => (+apply_629 = {(cs_0 => \{Tuple: (fst_1 => (snd_2 => (+apply_630 = {(cs_0 => \{Tuple: (fst_1 => (snd_2 => (+apply_631 = {(cs_0 => \{Tuple: (fst_1 => (snd_2 => (+apply_632 = {(cs_0 => \{Tuple: (fst_1 => (snd_2 => (+apply_633 = {(cs_0 => \{Tuple: (fst_1 => (snd_2 => (+apply_634 = {(cs_0 => \{Tuple: (fst_1 => (snd_2 => (+apply_635 = {(cs_0 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => Nil{}), (_2001_1 => Support.Bq.List.concat(U32, Bq.rect(8, 500, 500, 24, 3760463928), Bq.text_cmd(14, 505, 13, 16777215, Support.Bq.List.concat(Char, C.Bq.text("say: "), Support.Bq.List.concat(Char, Bq.cs_chatbuf(cs_0), C.Bq.text("_")))))), 0))) : (@+cs_0: Bq.CS -> (@+___1: U32 -> List<&1, U32>))}; apply_635(cs_0, C.Bq.bit(U32.is_eq(fst_1, 1)))))); \{}}) : (@+cs_0: Bq.CS -> (@+___1: Sigma<&1, &1, U32, (__1 => U32)> -> List<&1, U32>))}; apply_634(cs_0, snd_2)))); \{}}) : (@+cs_0: Bq.CS -> (@+___1: Sigma<&1, &1, U32, (__1 => Sigma<&1, &1, U32, (__2 => U32)>)> -> List<&1, U32>))}; apply_633(cs_0, snd_2)))); \{}}) : (@+cs_0: Bq.CS -> (@+___1: Sigma<&1, &1, U32, (__1 => Sigma<&1, &1, U32, (__2 => Sigma<&1, &1, U32, (__3 => U32)>)>)> -> List<&1, U32>))}; apply_632(cs_0, snd_2)))); \{}}) : (@+cs_0: Bq.CS -> (@+___1: Sigma<&1, &1, U32, (__1 => Sigma<&1, &1, U32, (__2 => Sigma<&1, &1, U32, (__3 => Sigma<&1, &1, U32, (__4 => U32)>)>)>)> -> List<&1, U32>))}; apply_631(cs_0, snd_2)))); \{}}) : (@+cs_0: Bq.CS -> (@+___1: Sigma<&1, &1, U32, (__1 => Sigma<&1, &1, U32, (__2 => Sigma<&1, &1, U32, (__3 => Sigma<&1, &1, U32, (__4 => Sigma<&1, &1, U32, (__5 => U32)>)>)>)>)> -> List<&1, U32>))}; apply_630(cs_0, snd_2)))); \{}}) : (@+cs_0: Bq.CS -> (@+___1: Sigma<&1, &1, U32, (__1 => Sigma<&1, &1, U32, (__2 => Sigma<&1, &1, U32, (__3 => Sigma<&1, &1, U32, (__4 => Sigma<&1, &1, U32, (__5 => Sigma<&1, &1, U32, (__6 => U32)>)>)>)>)>)> -> List<&1, U32>))}; apply_629(cs_0, Bq.cs_flags(cs_0))))

@unsafe
def Bq.panel_if():
  (word => C.Bq.word_case((@+cmds_1: List<&1, U32> -> List<&1, U32>), word, 0, (unit => (cmds_0 => Nil{})), (_2227_0 => (cmds_1 => cmds_1)), 0))

@unsafe
def Bq.INV_X():
  640

@unsafe
def Bq.INV_Y():
  60

@unsafe
def Bq.rect_l():
  (x_0 => (y_1 => (w_2 => (h_3 => (c_4 => [2, x_0, y_1, w_2, h_3, c_4])))))

@unsafe
def Bq.ME_INV0():
  29

@unsafe
def Bq.inv_cell():
  (a_0 => (k_1 => (cnt_2 => (cx_3 => (cy_4 => (+bg_5 = Bq.rect(cx_3, cy_4, 40, 40, 2149061672); (+apply_643 = {(a_0 => (k_1 => (cx_2 => (cy_3 => (cnt_4 => (bg_5 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => (+icon_6 = Bq.spr(Sprites.Bq.a_icons(a_0), Data.Bq.item_icon(k_1), 16, 16, (cx_2 + 4 : U32), (cy_3 + 4 : U32), 2, 0, Data.Bq.rarity_tint(Data.Bq.item_rarity(k_1))); (+num_7 = Bq.text_cmd((cx_2 + 26 : U32), (cy_3 + 28 : U32), 10, 16777215, Support.Bq.U32.show(cnt_4)); Support.Bq.List.concat(U32, bg_5, Support.Bq.List.concat(U32, icon_6, num_7))))), (_1867_6 => bg_5), 0)))))))) : (@+a_0: Sprites.Bq.Assets -> (@+k_1: U32 -> (@+cx_2: U32 -> (@+cy_3: U32 -> (@+cnt_4: U32 -> (@+bg_5: List<&1, U32> -> (@+___6: U32 -> List<&1, U32>)))))))}; apply_643(a_0, k_1, cx_3, cy_4, cnt_2, bg_5, C.Bq.bit(U32.is_eq(cnt_2, 0))))))))))

@unsafe
def Bq.inv_slots():
  (a_0 => (me_1 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => Nil{}), (n2_2 => (+k_3 = (18 - (1 + n2_2 : U32) : U32); (+cnt_4 = World.Bq.lget(me_1, (Bq.ME_INV0 + k_3 : U32), 0); (+cx_5 = ((Bq.INV_X + 10 : U32) + ((k_3 % 6 : U32) * 46 : U32) : U32); (+cy_6 = ((Bq.INV_Y + 40 : U32) + ((k_3 / 6 : U32) * 46 : U32) : U32); Support.Bq.List.concat(U32, Bq.inv_cell(a_0, k_3, cnt_4, cx_5, cy_6), Bq.inv_slots(a_0, me_1, n2_2))))))), 1))))

@unsafe
def Bq.gear_cell():
  (a_0 => (k1_1 => (cx_2 => (cy_3 => (+bg_4 = Support.Bq.List.concat(U32, Bq.rect(cx_2, cy_3, 40, 40, 2149061672), Bq.rect_l(cx_2, cy_3, 40, 40, 5596791)); (+apply_644 = {(k1_0 => (bg_1 => (a_2 => (cx_3 => (cy_4 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => (+k_5 = (k1_0 - 1 : U32); Support.Bq.List.concat(U32, bg_1, Bq.spr(Sprites.Bq.a_icons(a_2), Data.Bq.item_icon(k_5), 16, 16, (cx_3 + 4 : U32), (cy_4 + 4 : U32), 2, 0, Data.Bq.rarity_tint(Data.Bq.item_rarity(k_5)))))), (_1883_5 => bg_1), 0))))))) : (@+k1_0: U32 -> (@+bg_1: List<&1, U32> -> (@+a_2: Sprites.Bq.Assets -> (@+cx_3: U32 -> (@+cy_4: U32 -> (@+___5: U32 -> List<&1, U32>))))))}; apply_644(k1_1, bg_4, a_0, cx_2, cy_3, C.Bq.bit(U32.is_eq(k1_1, 0)))))))))

@unsafe
def Bq.ME_WEA():
  11

@unsafe
def Bq.ME_ARM():
  12

@unsafe
def Bq.ME_HEL():
  13

@unsafe
def Bq.ME_CHM():
  14

@unsafe
def Bq.gear_slots():
  (a_0 => (me_1 => (+t_2 = Bq.text_cmd((Bq.INV_X + 10 : U32), (Bq.INV_Y + 180 : U32), 12, 12110814, C.Bq.text("Equipped (click to remove)")); (+g0_3 = Bq.gear_cell(a_0, Bq.meg(me_1, Bq.ME_WEA), (Bq.INV_X + 10 : U32), (Bq.INV_Y + 196 : U32)); (+g1_4 = Bq.gear_cell(a_0, Bq.meg(me_1, Bq.ME_ARM), (Bq.INV_X + 56 : U32), (Bq.INV_Y + 196 : U32)); (+g2_5 = Bq.gear_cell(a_0, Bq.meg(me_1, Bq.ME_HEL), (Bq.INV_X + 102 : U32), (Bq.INV_Y + 196 : U32)); (+g3_6 = Bq.gear_cell(a_0, Bq.meg(me_1, Bq.ME_CHM), (Bq.INV_X + 148 : U32), (Bq.INV_Y + 196 : U32)); Support.Bq.List.concat(U32, t_2, Support.Bq.List.concat(U32, g0_3, Support.Bq.List.concat(U32, g1_4, Support.Bq.List.concat(U32, g2_5, g3_6)))))))))))

@unsafe
def Bq.plus_btn():
  (x_0 => (y_1 => (pts_2 => (+apply_645 = {(x_0 => (y_1 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => Bq.rect(x_0, y_1, 24, 20, 1347774071)), (_1895_2 => Support.Bq.List.concat(U32, Bq.rect(x_0, y_1, 24, 20, 6539085), Bq.text_cmd((x_0 + 8 : U32), (y_1 + 3 : U32), 14, 1060892, C.Bq.text("+")))), 0)))) : (@+x_0: U32 -> (@+y_1: U32 -> (@+___2: U32 -> List<&1, U32>)))}; apply_645(x_0, y_1, C.Bq.bit(U32.is_gt(pts_2, 0)))))))

@unsafe
def Bq.stat_row():
  (x_0 => (y_1 => (nm_2 => (v_3 => (pts_4 => (+t_5 = Bq.text_cmd(x_0, (y_1 + 2 : U32), 12, 16777215, Support.Bq.List.concat(Char, nm_2, Support.Bq.List.concat(Char, C.Bq.text(" "), Support.Bq.U32.show(v_3)))); (+b_6 = Bq.plus_btn((x_0 + 110 : U32), y_1, pts_4); Support.Bq.List.concat(U32, t_5, b_6))))))))

@unsafe
def Bq.ME_STR():
  8

@unsafe
def Bq.ME_AGI():
  9

@unsafe
def Bq.ME_VIT():
  10

@unsafe
def Bq.stat_rows():
  (me_0 => (+pts_1 = Bq.meg(me_0, Bq.ME_PTS); (+t_2 = Bq.text_cmd((Bq.INV_X + 10 : U32), (Bq.INV_Y + 250 : U32), 12, 12110814, Support.Bq.List.concat(Char, C.Bq.text("Stats  (+"), Support.Bq.List.concat(Char, Support.Bq.U32.show(pts_1), C.Bq.text(" pts)")))); (+r0_3 = Bq.stat_row((Bq.INV_X + 150 : U32), (Bq.INV_Y + 250 : U32), C.Bq.text("STR"), Bq.meg(me_0, Bq.ME_STR), pts_1); (+r1_4 = Bq.stat_row((Bq.INV_X + 150 : U32), (Bq.INV_Y + 274 : U32), C.Bq.text("AGI"), Bq.meg(me_0, Bq.ME_AGI), pts_1); (+r2_5 = Bq.stat_row((Bq.INV_X + 150 : U32), (Bq.INV_Y + 298 : U32), C.Bq.text("VIT"), Bq.meg(me_0, Bq.ME_VIT), pts_1); Support.Bq.List.concat(U32, t_2, Support.Bq.List.concat(U32, r0_3, Support.Bq.List.concat(U32, r1_4, r2_5)))))))))

@unsafe
def Bq.inv_panel():
  (cs_0 => (a_1 => (+me_2 = Bq.cs_me(cs_0); (+box_3 = Support.Bq.List.concat(U32, Bq.rect(Bq.INV_X, Bq.INV_Y, 310, 340, 4028899384), Bq.rect_l(Bq.INV_X, Bq.INV_Y, 310, 340, 6608882)); (+title_4 = Bq.text_cmd((Bq.INV_X + 10 : U32), (Bq.INV_Y + 10 : U32), 16, 16765286, C.Bq.text("Inventory  (click to equip)")); (+slots_5 = Bq.inv_slots(a_1, me_2, 18); (+gear_6 = Bq.gear_slots(a_1, me_2); (+stats_7 = Bq.stat_rows(me_2); Support.Bq.List.concat(U32, box_3, Support.Bq.List.concat(U32, title_4, Support.Bq.List.concat(U32, slots_5, Support.Bq.List.concat(U32, gear_6, stats_7))))))))))))

@unsafe
def Bq.side_row():
  (x_0 => (y_1 => (q_2 => (cnt_3 => (done_4 => (+apply_646 = {(x_0 => (y_1 => (q_2 => (cnt_3 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => Bq.text_cmd(x_0, y_1, 12, 16777215, Support.Bq.String.flatten([Data.Bq.sideq_name(q_2), C.Bq.text("  "), Support.Bq.U32.show(Support.Bq.U32.min(cnt_3, Data.Bq.sideq_need(q_2))), C.Bq.text("/"), Support.Bq.U32.show(Data.Bq.sideq_need(q_2))]))), (_1923_4 => Bq.text_cmd(x_0, y_1, 12, 6539085, Support.Bq.List.concat(Char, Data.Bq.sideq_name(q_2), C.Bq.text(" - DONE")))), 0)))))) : (@+x_0: U32 -> (@+y_1: U32 -> (@+q_2: U32 -> (@+cnt_3: U32 -> (@+___4: U32 -> List<&1, U32>)))))}; apply_646(x_0, y_1, q_2, cnt_3, C.Bq.bit(U32.is_eq((U32.shrn(done_4, U32.to_nat(q_2)) .&. 1 : U32), 1)))))))))

@unsafe
def Bq.ME_SQ0():
  18

@unsafe
def Bq.ME_SQD():
  21

@unsafe
def Bq.ME_SQ1():
  19

@unsafe
def Bq.ME_SQ2():
  20

@unsafe
def Bq.quest_panel():
  (cs_0 => (+me_1 = Bq.cs_me(cs_0); (+box_2 = Support.Bq.List.concat(U32, Bq.rect(20, 60, 380, 240, 4028899384), Bq.rect_l(20, 60, 380, 240, 16765286)); (+t_3 = Bq.text_cmd(30, 70, 16, 16765286, C.Bq.text("Quests")); (+mq_4 = Bq.text_cmd(30, 100, 12, 16777215, Support.Bq.List.concat(Char, C.Bq.text("MAIN: "), Support.Bq.List.concat(Char, Data.Bq.mainq_text(Bq.meg(me_1, Bq.ME_MAINQ)), Bq.quest_extra(Bq.meg(me_1, Bq.ME_MAINQ), Bq.meg(me_1, Bq.ME_CULL))))); (+s0_5 = Bq.side_row(30, 130, 0, Bq.meg(me_1, Bq.ME_SQ0), Bq.meg(me_1, Bq.ME_SQD)); (+s1_6 = Bq.side_row(30, 155, 1, Bq.meg(me_1, Bq.ME_SQ1), Bq.meg(me_1, Bq.ME_SQD)); (+s2_7 = Bq.side_row(30, 180, 2, Bq.meg(me_1, Bq.ME_SQ2), Bq.meg(me_1, Bq.ME_SQD)); (+lore_8 = Bq.text_cmd(30, 215, 10, 8952234, C.Bq.text("Side quests reward potions and gear. The Rift opens at 3 sigils.")); (+sc_9 = Bq.text_cmd(30, 240, 12, 10216804, Support.Bq.List.concat(Char, C.Bq.text("Score: "), Support.Bq.List.concat(Char, Support.Bq.U32.show(Bq.meg(me_1, Bq.ME_SCORE)), C.Bq.text("   Kills feed the realm's memory.")))); Support.Bq.List.concat(U32, box_2, Support.Bq.List.concat(U32, t_3, Support.Bq.List.concat(U32, mq_4, Support.Bq.List.concat(U32, s0_5, Support.Bq.List.concat(U32, s1_6, Support.Bq.List.concat(U32, s2_7, Support.Bq.List.concat(U32, lore_8, sc_9)))))))))))))))))

@unsafe
def Bq.SHOP_ROW_COUNT():
  8

@unsafe
def Bq.req_str():
  (k_0 => Support.Bq.List.concat(Char, C.Bq.text("lv "), Support.Bq.U32.show(Support.Bq.Nat.to_u32(Game.Bq.ilvreq(Support.Bq.Nat.from_u32(k_0))))))

@unsafe
def Bq.shop_row():
  (a_0 => (k_1 => (y_2 => (+bg_3 = Bq.rect(340, y_2, 280, 40, 2149061672); (+ic_4 = Bq.spr(Sprites.Bq.a_icons(a_0), Data.Bq.item_icon(k_1), 16, 16, 344, (y_2 + 4 : U32), 2, 0, Data.Bq.rarity_tint(Data.Bq.item_rarity(k_1))); (+nm_5 = Bq.text_cmd(384, (y_2 + 6 : U32), 12, 16777215, Data.Bq.item_name(k_1)); (+pr_6 = Bq.text_cmd(384, (y_2 + 22 : U32), 11, 16765286, Support.Bq.List.concat(Char, Support.Bq.U32.show(Support.Bq.Nat.to_u32(Game.Bq.iprice(Support.Bq.Nat.from_u32(k_1)))), Support.Bq.List.concat(Char, C.Bq.text("g   "), Bq.req_str(k_1)))); Support.Bq.List.concat(U32, bg_3, Support.Bq.List.concat(U32, ic_4, Support.Bq.List.concat(U32, nm_5, pr_6))))))))))

@unsafe
def Bq.shop_kind():
  (i_0 => (+apply_647 = {(i_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_648 = {(i_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_649 = {(i_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_650 = {(i_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_651 = {(i_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_652 = {(i_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_653 = {(word => C.Bq.word_case(U32, word, 0, (unit => 15), (_1173_0 => 12), 0)) : (@+___0: U32 -> U32)}; apply_653(C.Bq.bit(U32.is_eq(i_0, 6))))), (_1175_1 => 9), 0))) : (@+i_0: U32 -> (@+___1: U32 -> U32))}; apply_652(i_0, C.Bq.bit(U32.is_eq(i_0, 5))))), (_1177_1 => 8), 0))) : (@+i_0: U32 -> (@+___1: U32 -> U32))}; apply_651(i_0, C.Bq.bit(U32.is_eq(i_0, 4))))), (_1179_1 => 7), 0))) : (@+i_0: U32 -> (@+___1: U32 -> U32))}; apply_650(i_0, C.Bq.bit(U32.is_eq(i_0, 3))))), (_1181_1 => 2), 0))) : (@+i_0: U32 -> (@+___1: U32 -> U32))}; apply_649(i_0, C.Bq.bit(U32.is_eq(i_0, 2))))), (_1183_1 => 1), 0))) : (@+i_0: U32 -> (@+___1: U32 -> U32))}; apply_648(i_0, C.Bq.bit(U32.is_eq(i_0, 1))))), (_1185_1 => 0), 0))) : (@+i_0: U32 -> (@+___1: U32 -> U32))}; apply_647(i_0, C.Bq.bit(U32.is_eq(i_0, 0)))))

@unsafe
def Bq.shop_rows():
  (a_0 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => Nil{}), (n2_1 => (+i_2 = (Bq.SHOP_ROW_COUNT - (1 + n2_1 : U32) : U32); Support.Bq.List.concat(U32, Bq.shop_row(a_0, Bq.shop_kind(i_2), (120 + (i_2 * 44 : U32) : U32)), Bq.shop_rows(a_0, n2_1)))), 1)))

@unsafe
def Bq.shop_panel():
  (cs_0 => (a_1 => (+me_2 = Bq.cs_me(cs_0); (+box_3 = Support.Bq.List.concat(U32, Bq.rect(330, 90, 300, 390, 4028899384), Bq.rect_l(330, 90, 300, 390, 6539085)); (+t_4 = Bq.text_cmd(340, 98, 16, 16765286, C.Bq.text("Keeper Bramble's Shop")); (+g_5 = Bq.text_cmd(500, 100, 12, 16777215, Support.Bq.List.concat(Char, Support.Bq.U32.show(Bq.meg(me_2, Bq.ME_GOLD)), C.Bq.text("g"))); (+rows_6 = Bq.shop_rows(a_1, Bq.SHOP_ROW_COUNT); Support.Bq.List.concat(U32, box_3, Support.Bq.List.concat(U32, t_4, Support.Bq.List.concat(U32, g_5, rows_6))))))))))

@unsafe
def Bq.dur_str():
  (d_0 => Support.Bq.String.flatten([Support.Bq.U32.show((d_0 / 60 : U32)), C.Bq.text("m"), Support.Bq.U32.show((d_0 % 60 : U32)), C.Bq.text("s")]))

@unsafe
def Bq.fame_icon():
  (a_0 => (x_1 => (y_2 => (k1_3 => (+apply_654 = {(a_0 => (k1_1 => (x_2 => (y_3 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => Bq.spr(Sprites.Bq.a_icons(a_0), Data.Bq.item_icon((k1_1 - 1 : U32)), 16, 16, x_2, y_3, 1, 0, Data.Bq.rarity_tint(Data.Bq.item_rarity((k1_1 - 1 : U32))))), (_2009_4 => Nil{}), 0)))))) : (@+a_0: Sprites.Bq.Assets -> (@+k1_1: U32 -> (@+x_2: U32 -> (@+y_3: U32 -> (@+___4: U32 -> List<&1, U32>)))))}; apply_654(a_0, k1_3, x_1, y_2, C.Bq.bit(U32.is_eq(k1_3, 0))))))))

@unsafe
def Bq.fame_gear():
  (a_0 => (x_1 => (y_2 => (wea_3 => (arm_4 => (hel_5 => (chm_6 => (+g0_7 = Bq.fame_icon(a_0, x_1, y_2, wea_3); (+g1_8 = Bq.fame_icon(a_0, x_1, (y_2 + 18 : U32), arm_4); (+g2_9 = Bq.fame_icon(a_0, (x_1 + 18 : U32), y_2, hel_5); (+g3_10 = Bq.fame_icon(a_0, (x_1 + 18 : U32), (y_2 + 18 : U32), chm_6); Support.Bq.List.concat(U32, g0_7, Support.Bq.List.concat(U32, g1_8, Support.Bq.List.concat(U32, g2_9, g3_10))))))))))))))

@unsafe
def Bq.fame_chars():
  (a_0 => \{Nil: (x_1 => (y_2 => Nil{})); \{Con: \{Bq.FameP.FameP: (name_1 => (lv_2 => (score_3 => (skin_4 => (hairs_5 => (hairc_6 => (shirt_7 => (hat_8 => (cape_9 => (wea_10 => (arm_11 => (hel_12 => (chm_13 => (rest_14 => (x_15 => (y_16 => (+apply_655 = {(a_0 => (x_1 => (y_2 => (skin_3 => (hairs_4 => (hairc_5 => (shirt_6 => (hat_7 => (cape_8 => (name_9 => (lv_10 => (score_11 => (wea_12 => (arm_13 => (hel_14 => (chm_15 => (rest_16 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => (+ch_17 = Bq.char_cmds(a_0, x_1, y_2, 0, 2, 0, skin_3, hairs_4, hairc_5, shirt_6, hat_7, cape_8); (+nm_18 = Bq.text_cmd((x_1 - 4 : U32), (y_2 + 44 : U32), 9, 16777215, name_9); (+st_19 = Bq.text_cmd((x_1 - 4 : U32), (y_2 + 55 : U32), 9, 12110814, Support.Bq.String.flatten([C.Bq.text("lv"), Support.Bq.U32.show(lv_10), C.Bq.text(" "), Support.Bq.U32.show(score_11), C.Bq.text("pt")])); (+gr_20 = Bq.fame_gear(a_0, (x_1 + 34 : U32), (y_2 + 4 : U32), wea_12, arm_13, hel_14, chm_15); Support.Bq.List.concat(U32, ch_17, Support.Bq.List.concat(U32, nm_18, Support.Bq.List.concat(U32, st_19, Support.Bq.List.concat(U32, gr_20, Bq.fame_chars(a_0, rest_16, (x_1 + 110 : U32), y_2)))))))))), (_2045_17 => Nil{}), 0))))))))))))))))))) : (@+a_0: Sprites.Bq.Assets -> (@+x_1: U32 -> (@+y_2: U32 -> (@+skin_3: U32 -> (@+hairs_4: U32 -> (@+hairc_5: U32 -> (@+shirt_6: U32 -> (@+hat_7: U32 -> (@+cape_8: U32 -> (@+name_9: C.Bq.String -> (@+lv_10: U32 -> (@+score_11: U32 -> (@+wea_12: U32 -> (@+arm_13: U32 -> (@+hel_14: U32 -> (@+chm_15: U32 -> (@+rest_16: List<&1, Bq.FameP> -> (@+___17: U32 -> List<&1, U32>))))))))))))))))))}; apply_655(a_0, x_15, y_16, skin_4, hairs_5, hairc_6, shirt_7, hat_8, cape_9, name_1, lv_2, score_3, wea_10, arm_11, hel_12, chm_13, rest_14, C.Bq.bit(U32.is_gt(x_15, 780)))))))))))))))))))); \{}}; \{}}})

@unsafe
def Bq.fame_rows():
  (a_0 => \{Nil: (y_1 => Nil{}); \{Con: \{Bq.FameR.FameR: (no_1 => (dur_2 => (fps_3 => (rest_4 => (y_5 => (+apply_656 = {(y_0 => (no_1 => (dur_2 => (a_3 => (fps_4 => (rest_5 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => (+hdr_6 = Bq.text_cmd(120, y_0, 14, 16765286, Support.Bq.String.flatten([C.Bq.text("world "), Support.Bq.U32.show(no_1), C.Bq.text("  sealed in "), Bq.dur_str(dur_2)])); (+ps_7 = Bq.fame_chars(a_3, fps_4, 130, (y_0 + 20 : U32)); Support.Bq.List.concat(U32, hdr_6, Support.Bq.List.concat(U32, ps_7, Bq.fame_rows(a_3, rest_5, (y_0 + 92 : U32))))))), (_2057_6 => Nil{}), 0)))))))) : (@+y_0: U32 -> (@+no_1: U32 -> (@+dur_2: U32 -> (@+a_3: Sprites.Bq.Assets -> (@+fps_4: List<&1, Bq.FameP> -> (@+rest_5: List<&1, Bq.FameR> -> (@+___6: U32 -> List<&1, U32>)))))))}; apply_656(y_5, no_1, dur_2, a_0, fps_3, rest_4, C.Bq.bit(U32.is_gt(y_5, 440))))))))); \{}}; \{}}})

@unsafe
def Bq.cs_acct():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => (form_2 => (net_3 => (acct_4 => (look_5 => (wv_6 => (ui_7 => acct_4)))))))); \{}}

@unsafe
def Bq.fame_panel():
  (cs_0 => (a_1 => (+apply_657 = {(a_0 => \{Bq.Acct.Acct: (coins_1 => (ownh_2 => (ownc_3 => (wno_4 => (phase_5 => (fame_6 => (over_7 => (+box_8 = Support.Bq.List.concat(U32, Bq.rect(100, 40, 760, 500, 4128905774), Bq.rect_l(100, 40, 760, 500, 10216959)); (+t_9 = Bq.text_cmd(120, 52, 20, 10216959, C.Bq.text("HALL OF FAME  (H to close)")); (+rows_10 = Bq.fame_rows(a_0, fame_6, 90); Support.Bq.List.concat(U32, box_8, Support.Bq.List.concat(U32, t_9, rows_10)))))))))))); \{}}) : (@+a_0: Sprites.Bq.Assets -> (@+___1: Bq.Acct -> List<&1, U32>))}; apply_657(a_1, Bq.cs_acct(cs_0)))))

@unsafe
def Bq.over_rows():
  \{Nil: (y_0 => Nil{}); \{Con: \{Bq.OverE.OverE: (rank_0 => (score_1 => (coins_2 => (name_3 => (rest_4 => (y_5 => (+apply_658 = {(y_0 => (rank_1 => (name_2 => (score_3 => (coins_4 => (rest_5 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => Support.Bq.List.concat(U32, Bq.text_cmd(300, y_0, 14, 16777215, Support.Bq.String.flatten([C.Bq.text("#"), Support.Bq.U32.show((rank_1 + 1 : U32)), C.Bq.text("  "), name_2, C.Bq.text("  "), Support.Bq.U32.show(score_3), C.Bq.text("pt  +"), Support.Bq.U32.show(coins_4), C.Bq.text(" coins")])), Bq.over_rows(rest_5, (y_0 + 24 : U32)))), (_2080_6 => Nil{}), 0)))))))) : (@+y_0: U32 -> (@+rank_1: U32 -> (@+name_2: C.Bq.String -> (@+score_3: U32 -> (@+coins_4: U32 -> (@+rest_5: List<&1, Bq.OverE> -> (@+___6: U32 -> List<&1, U32>)))))))}; apply_658(y_5, rank_0, name_3, score_1, coins_2, rest_4, C.Bq.bit(U32.is_gt(y_5, 400)))))))))); \{}}; \{}}}

@unsafe
def Bq.over_panel():
  (cs_0 => (+apply_659 = {\{Bq.Acct.Acct: (coins_0 => (ownh_1 => (ownc_2 => (wno_3 => (phase_4 => (fame_5 => (over_6 => (+apply_660 = {(over_0 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => (+box_1 = Support.Bq.List.concat(U32, Bq.rect(240, 100, 480, 360, 4128905774), Bq.rect_l(240, 100, 480, 360, 16765286)); (+t1_2 = Bq.text_cmd(300, 120, 26, 16765286, C.Bq.text("THE REALM IS SAVED!")); (+t2_3 = Bq.text_cmd(300, 156, 13, 12110814, C.Bq.text("final scores -- star coins paid by rank")); (+rows_4 = Bq.over_rows(over_0, 190); (+t3_5 = Bq.text_cmd(300, 420, 12, 10216959, C.Bq.text("a new world dawns shortly... (H: hall of fame)")); Support.Bq.List.concat(U32, box_1, Support.Bq.List.concat(U32, t1_2, Support.Bq.List.concat(U32, t2_3, Support.Bq.List.concat(U32, rows_4, t3_5)))))))))), (_2095_1 => Nil{}), 0))) : (@+over_0: List<&1, Bq.OverE> -> (@+___1: U32 -> List<&1, U32>))}; apply_660(over_6, C.Bq.bit(U32.is_ne(phase_4, 2))))))))))); \{}} : (@+___0: Bq.Acct -> List<&1, U32>)}; apply_659(Bq.cs_acct(cs_0))))

@unsafe
def Bq.cs_err_str():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => \{Bq.Form.Form: (focus_2 => (f_ip_3 => (f_port_4 => (f_name_5 => (err_6 => (net_7 => (acct_8 => (look_9 => (wv_10 => (ui_11 => err_6)))))))))); \{}})); \{}}

@unsafe
def Bq.err_toast():
  (cs_0 => (+err_1 = Bq.cs_err_str(cs_0); (+apply_661 = {(err_0 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => Support.Bq.List.concat(U32, Bq.rect(240, 8, 480, 26, 3769645650), Bq.text_cmd(250, 14, 13, 16777215, err_0))), (_2100_1 => Nil{}), 0))) : (@+err_0: C.Bq.String -> (@+___1: U32 -> List<&1, U32>))}; apply_661(err_1, C.Bq.bit(U32.is_eq(Support.Bq.String.length(err_1), 0))))))

@unsafe
def Bq.render_game():
  (cs_0 => (a_1 => (tms_2 => (snds_3 => (+apply_662 = {(a_0 => (cs_1 => (tms_2 => (snds_3 => \{Tuple: (fst_4 => (snd_5 => (+apply_663 = {(a_0 => (cs_1 => (tms_2 => (snds_3 => (fst_4 => \{Tuple: (fst_5 => (snd_6 => (+apply_664 = {(a_0 => (cs_1 => (tms_2 => (snds_3 => (fst_4 => (fst_5 => \{Tuple: (fst_6 => (snd_7 => (+apply_665 = {(a_0 => (cs_1 => (tms_2 => (snds_3 => (fst_4 => (fst_5 => (fst_6 => \{Tuple: (fst_7 => (snd_8 => (+apply_666 = {(a_0 => (cs_1 => (tms_2 => (snds_3 => (fst_4 => (fst_5 => (fst_6 => \{Tuple: (fst_7 => (snd_8 => (+apply_667 = {(a_0 => (cs_1 => (tms_2 => (snds_3 => (fst_4 => (fst_5 => (fst_6 => (fst_7 => \{Tuple: (fst_8 => (snd_9 => (+base_10 = {[0, 1052700] : List<&1, U32>}; (+wc_11 = Bq.world_cmds(a_0, Bq.cs_wv(cs_1), tms_2, snds_3); (+hud_12 = Bq.hud_cmds(cs_1, a_0, tms_2); (+ch_13 = Bq.chat_cmds(cs_1); (+p1_14 = Bq.panel_if(fst_4, Bq.inv_panel(cs_1, a_0)); (+p2_15 = Bq.panel_if(fst_5, Bq.quest_panel(cs_1)); (+p3_16 = Bq.panel_if(fst_6, Bq.shop_panel(cs_1, a_0)); (+p5_17 = Bq.panel_if(fst_7, Bq.fame_panel(cs_1, a_0)); (+ov_18 = Bq.over_panel(cs_1); (+et_19 = Bq.err_toast(cs_1); Support.Bq.List.concat(U32, base_10, Support.Bq.List.concat(U32, wc_11, Support.Bq.List.concat(U32, hud_12, Support.Bq.List.concat(U32, ch_13, Support.Bq.List.concat(U32, p1_14, Support.Bq.List.concat(U32, p2_15, Support.Bq.List.concat(U32, p3_16, Support.Bq.List.concat(U32, p5_17, Support.Bq.List.concat(U32, ov_18, et_19))))))))))))))))))))); \{}})))))))) : (@+a_0: Sprites.Bq.Assets -> (@+cs_1: Bq.CS -> (@+tms_2: U32 -> (@+snds_3: C.Bq.Pair.Pair(U32, (__3 => U32)) -> (@+fst_4: U32 -> (@+fst_5: U32 -> (@+fst_6: U32 -> (@+fst_7: U32 -> (@+___8: Sigma<&1, &1, U32, (__8 => U32)> -> List<&1, U32>)))))))))}; apply_667(a_0, cs_1, tms_2, snds_3, fst_4, fst_5, fst_6, fst_7, snd_8)))); \{}}))))))) : (@+a_0: Sprites.Bq.Assets -> (@+cs_1: Bq.CS -> (@+tms_2: U32 -> (@+snds_3: C.Bq.Pair.Pair(U32, (__3 => U32)) -> (@+fst_4: U32 -> (@+fst_5: U32 -> (@+fst_6: U32 -> (@+___7: Sigma<&1, &1, U32, (__7 => Sigma<&1, &1, U32, (__8 => U32)>)> -> List<&1, U32>))))))))}; apply_666(a_0, cs_1, tms_2, snds_3, fst_4, fst_5, fst_6, snd_8)))); \{}}))))))) : (@+a_0: Sprites.Bq.Assets -> (@+cs_1: Bq.CS -> (@+tms_2: U32 -> (@+snds_3: C.Bq.Pair.Pair(U32, (__3 => U32)) -> (@+fst_4: U32 -> (@+fst_5: U32 -> (@+fst_6: U32 -> (@+___7: Sigma<&1, &1, U32, (__7 => Sigma<&1, &1, U32, (__8 => Sigma<&1, &1, U32, (__9 => U32)>)>)> -> List<&1, U32>))))))))}; apply_665(a_0, cs_1, tms_2, snds_3, fst_4, fst_5, fst_6, snd_7)))); \{}})))))) : (@+a_0: Sprites.Bq.Assets -> (@+cs_1: Bq.CS -> (@+tms_2: U32 -> (@+snds_3: C.Bq.Pair.Pair(U32, (__3 => U32)) -> (@+fst_4: U32 -> (@+fst_5: U32 -> (@+___6: Sigma<&1, &1, U32, (__6 => Sigma<&1, &1, U32, (__7 => Sigma<&1, &1, U32, (__8 => Sigma<&1, &1, U32, (__9 => U32)>)>)>)> -> List<&1, U32>)))))))}; apply_664(a_0, cs_1, tms_2, snds_3, fst_4, fst_5, snd_6)))); \{}}))))) : (@+a_0: Sprites.Bq.Assets -> (@+cs_1: Bq.CS -> (@+tms_2: U32 -> (@+snds_3: C.Bq.Pair.Pair(U32, (__3 => U32)) -> (@+fst_4: U32 -> (@+___5: Sigma<&1, &1, U32, (__5 => Sigma<&1, &1, U32, (__6 => Sigma<&1, &1, U32, (__7 => Sigma<&1, &1, U32, (__8 => Sigma<&1, &1, U32, (__9 => U32)>)>)>)>)> -> List<&1, U32>))))))}; apply_663(a_0, cs_1, tms_2, snds_3, fst_4, snd_5)))); \{}})))) : (@+a_0: Sprites.Bq.Assets -> (@+cs_1: Bq.CS -> (@+tms_2: U32 -> (@+snds_3: C.Bq.Pair.Pair(U32, (__3 => U32)) -> (@+___4: Sigma<&1, &1, U32, (__4 => Sigma<&1, &1, U32, (__5 => Sigma<&1, &1, U32, (__6 => Sigma<&1, &1, U32, (__7 => Sigma<&1, &1, U32, (__8 => Sigma<&1, &1, U32, (__9 => U32)>)>)>)>)>)> -> List<&1, U32>)))))}; apply_662(a_1, cs_0, tms_2, snds_3, Bq.cs_flags(cs_0)))))))

@unsafe
def Bq.opt_row():
  (y_0 => (label_1 => (val_2 => (+l_3 = Bq.text_cmd(360, (y_0 + 6 : U32), 14, 12110814, label_1); (+v_4 = Bq.text_cmd(470, (y_0 + 6 : U32), 14, 16777215, val_2); (+b_5 = Support.Bq.List.concat(U32, Bq.rect(560, y_0, 30, 30, 4020894), Bq.text_cmd(569, (y_0 + 6 : U32), 16, 16777215, C.Bq.text(">"))); Support.Bq.List.concat(U32, l_3, Support.Bq.List.concat(U32, v_4, b_5))))))))

@unsafe
def Bq.hat_label():
  (h_0 => (+apply_670 = {(h_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => Data.Bq.hat_name((h_0 - 1 : U32))), (_2168_1 => C.Bq.text("none")), 0))) : (@+h_0: U32 -> (@+___1: U32 -> List<&1, Char>))}; apply_670(h_0, C.Bq.bit(U32.is_eq(h_0, 0)))))

@unsafe
def Bq.cape_label():
  (c_0 => (+apply_672 = {(c_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => Data.Bq.cape_name((c_0 - 1 : U32))), (_2171_1 => C.Bq.text("none")), 0))) : (@+c_0: U32 -> (@+___1: U32 -> List<&1, Char>))}; apply_672(c_0, C.Bq.bit(U32.is_eq(c_0, 0)))))

@unsafe
def Bq.afford_col():
  (word => C.Bq.word_case(U32, word, 0, (unit => 1345532740), (_2173_0 => 4020894), 0))

@unsafe
def Bq.shop_btn():
  (x_0 => (y_1 => (word => C.Bq.word_case((@+name_3: C.Bq.String -> (@+price_4: U32 -> (@+coins_5: U32 -> List<&1, U32>))), word, 0, (unit => (name_2 => (price_3 => (coins_4 => (+col_5 = Bq.afford_col(C.Bq.bit(U32.is_ge(coins_4, price_3))); Support.Bq.List.concat(U32, Bq.rect(x_0, y_1, 200, 34, col_5), Bq.text_cmd((x_0 + 8 : U32), (y_1 + 9 : U32), 12, 16775408, Support.Bq.String.flatten([name_2, C.Bq.text("  "), Support.Bq.U32.show(price_3), C.Bq.text("c")])))))))), (_2181_2 => (name_3 => (price_4 => (coins_5 => Support.Bq.List.concat(U32, Bq.rect(x_0, y_1, 200, 34, 1347774071), Bq.text_cmd((x_0 + 8 : U32), (y_1 + 9 : U32), 12, 10216804, Support.Bq.List.concat(Char, name_3, C.Bq.text(" (owned)")))))))), 0))))

@unsafe
def Bq.btn():
  (x_0 => (y_1 => (w_2 => (h_3 => (c_4 => (tx_5 => (label_6 => Support.Bq.List.concat(U32, Bq.rect(x_0, y_1, w_2, h_3, c_4), Support.Bq.List.concat(U32, Bq.rect_l(x_0, y_1, w_2, h_3, 1315860), Bq.text_cmd((x_0 + tx_5 : U32), (y_1 + 14 : U32), 20, 16775408, label_6))))))))))

@unsafe
def Bq.fame_if():
  (cs_0 => (a_1 => (+apply_673 = {(cs_0 => (a_1 => \{Tuple: (fst_2 => (snd_3 => (+apply_674 = {(cs_0 => (a_1 => \{Tuple: (fst_2 => (snd_3 => (+apply_675 = {(cs_0 => (a_1 => \{Tuple: (fst_2 => (snd_3 => (+apply_676 = {(cs_0 => (a_1 => \{Tuple: (fst_2 => (snd_3 => (+apply_677 = {(cs_0 => (a_1 => \{Tuple: (fst_2 => (snd_3 => (+apply_678 = {(cs_0 => (a_1 => (fst_2 => \{Tuple: (fst_3 => (snd_4 => (+apply_679 = {(cs_0 => (a_1 => (word => C.Bq.word_case((@+__3: U32 -> (@+__4: U32 -> List<&1, U32>)), word, 0, (unit => (cht_2 => (msent_3 => Nil{}))), (_2191_2 => (cht_3 => (msent_4 => Bq.fame_panel(cs_0, a_1)))), 0)))) : (@+cs_0: Bq.CS -> (@+a_1: Sprites.Bq.Assets -> (@+___2: U32 -> (@+__3: U32 -> (@+__4: U32 -> List<&1, U32>)))))}; apply_679(cs_0, a_1, fst_2, fst_3, snd_4)))); \{}}))) : (@+cs_0: Bq.CS -> (@+a_1: Sprites.Bq.Assets -> (@+fst_2: U32 -> (@+___3: Sigma<&1, &1, U32, (__3 => U32)> -> List<&1, U32>))))}; apply_678(cs_0, a_1, fst_2, snd_3)))); \{}})) : (@+cs_0: Bq.CS -> (@+a_1: Sprites.Bq.Assets -> (@+___2: Sigma<&1, &1, U32, (__2 => Sigma<&1, &1, U32, (__3 => U32)>)> -> List<&1, U32>)))}; apply_677(cs_0, a_1, snd_3)))); \{}})) : (@+cs_0: Bq.CS -> (@+a_1: Sprites.Bq.Assets -> (@+___2: Sigma<&1, &1, U32, (__2 => Sigma<&1, &1, U32, (__3 => Sigma<&1, &1, U32, (__4 => U32)>)>)> -> List<&1, U32>)))}; apply_676(cs_0, a_1, snd_3)))); \{}})) : (@+cs_0: Bq.CS -> (@+a_1: Sprites.Bq.Assets -> (@+___2: Sigma<&1, &1, U32, (__2 => Sigma<&1, &1, U32, (__3 => Sigma<&1, &1, U32, (__4 => Sigma<&1, &1, U32, (__5 => U32)>)>)>)> -> List<&1, U32>)))}; apply_675(cs_0, a_1, snd_3)))); \{}})) : (@+cs_0: Bq.CS -> (@+a_1: Sprites.Bq.Assets -> (@+___2: Sigma<&1, &1, U32, (__2 => Sigma<&1, &1, U32, (__3 => Sigma<&1, &1, U32, (__4 => Sigma<&1, &1, U32, (__5 => Sigma<&1, &1, U32, (__6 => U32)>)>)>)>)> -> List<&1, U32>)))}; apply_674(cs_0, a_1, snd_3)))); \{}})) : (@+cs_0: Bq.CS -> (@+a_1: Sprites.Bq.Assets -> (@+___2: Sigma<&1, &1, U32, (__2 => Sigma<&1, &1, U32, (__3 => Sigma<&1, &1, U32, (__4 => Sigma<&1, &1, U32, (__5 => Sigma<&1, &1, U32, (__6 => Sigma<&1, &1, U32, (__7 => U32)>)>)>)>)>)> -> List<&1, U32>)))}; apply_673(cs_0, a_1, Bq.cs_flags(cs_0)))))

@unsafe
def Bq.cs_creator_vals():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => (form_2 => (net_3 => \{Bq.Acct.Acct: (coins_4 => (ownh_5 => (ownc_6 => (wno_7 => (phase_8 => (fame_9 => (over_10 => \{Bq.Look.Look: (skin_11 => (hairs_12 => (hairc_13 => (shirt_14 => (hat_15 => (cape_16 => (wv_17 => (ui_18 => Tuple{skin_11, Tuple{hairs_12, Tuple{hairc_13, Tuple{shirt_14, Tuple{hat_15, Tuple{cape_16, Tuple{coins_4, Tuple{ownh_5, ownc_6}}}}}}}})))))))); \{}}))))))); \{}})))); \{}}

@unsafe
def Bq.render_creator():
  (cs_0 => (a_1 => (tms_2 => (+apply_680 = {(a_0 => (tms_1 => (cs_2 => \{Tuple: (fst_3 => (snd_4 => (+apply_681 = {(a_0 => (tms_1 => (fst_2 => (cs_3 => \{Tuple: (fst_4 => (snd_5 => (+apply_682 = {(a_0 => (tms_1 => (fst_2 => (fst_3 => (cs_4 => \{Tuple: (fst_5 => (snd_6 => (+apply_683 = {(a_0 => (tms_1 => (fst_2 => (fst_3 => (fst_4 => (cs_5 => \{Tuple: (fst_6 => (snd_7 => (+apply_684 = {(a_0 => (tms_1 => (fst_2 => (fst_3 => (fst_4 => (fst_5 => (cs_6 => \{Tuple: (fst_7 => (snd_8 => (+apply_685 = {(a_0 => (tms_1 => (fst_2 => (fst_3 => (fst_4 => (fst_5 => (fst_6 => (cs_7 => \{Tuple: (fst_8 => (snd_9 => (+apply_686 = {(a_0 => (tms_1 => (fst_2 => (fst_3 => (fst_4 => (fst_5 => (fst_6 => (fst_7 => (cs_8 => \{Tuple: (fst_9 => (snd_10 => (+apply_687 = {(a_0 => (tms_1 => (fst_2 => (fst_3 => (fst_4 => (fst_5 => (fst_6 => (fst_7 => (fst_8 => (cs_9 => \{Tuple: (fst_10 => (snd_11 => (+bg_12 = {[0, 2367544] : List<&1, U32>}; (+t_13 = Bq.text_cmd(330, 40, 26, 16765286, C.Bq.text("CREATE YOUR HERO")); (+prev_14 = Bq.char_cmds(a_0, 120, 150, ((tms_1 / 400 : U32) % 2 : U32), 8, 0, fst_2, fst_3, fst_4, fst_5, fst_6, fst_7); (+r0_15 = Bq.opt_row(150, C.Bq.text("skin"), Support.Bq.U32.show(fst_2)); (+r1_16 = Bq.opt_row(195, C.Bq.text("hair style"), Support.Bq.U32.show(fst_3)); (+r2_17 = Bq.opt_row(240, C.Bq.text("hair color"), Support.Bq.U32.show(fst_4)); (+r3_18 = Bq.opt_row(285, C.Bq.text("shirt"), Support.Bq.U32.show(fst_5)); (+r4_19 = Bq.opt_row(330, C.Bq.text("hat"), Bq.hat_label(fst_6)); (+r5_20 = Bq.opt_row(375, C.Bq.text("cape"), Bq.cape_label(fst_7)); (+ct_21 = Bq.text_cmd(60, 430, 15, 16765286, Support.Bq.List.concat(Char, C.Bq.text("star coins: "), Support.Bq.U32.show(fst_8))); (+s0_22 = Bq.shop_btn(60, 460, (fst_10 .&. 1 : U32), Data.Bq.hat_name(0), Data.Bq.hat_price(0), fst_8); (+s1_23 = Bq.shop_btn(60, 498, (U32.shrn(fst_10, U32.to_nat(1)) .&. 1 : U32), Data.Bq.hat_name(1), Data.Bq.hat_price(1), fst_8); (+s2_24 = Bq.shop_btn(60, 536, (U32.shrn(fst_10, U32.to_nat(2)) .&. 1 : U32), Data.Bq.hat_name(2), Data.Bq.hat_price(2), fst_8); (+s3_25 = Bq.shop_btn(290, 460, (snd_11 .&. 1 : U32), Data.Bq.cape_name(0), Data.Bq.cape_price(0), fst_8); (+s4_26 = Bq.shop_btn(290, 498, (U32.shrn(snd_11, U32.to_nat(1)) .&. 1 : U32), Data.Bq.cape_name(1), Data.Bq.cape_price(1), fst_8); (+b_27 = Bq.btn(640, 480, 240, 60, 6539085, 45, C.Bq.text("ENTER THE WORLD")); (+hint_28 = Bq.text_cmd(640, 560, 11, 8952234, C.Bq.text("H: hall of fame   ENTER: play")); (+base_29 = Support.Bq.List.concat(U32, bg_12, Support.Bq.List.concat(U32, t_13, Support.Bq.List.concat(U32, prev_14, Support.Bq.List.concat(U32, r0_15, Support.Bq.List.concat(U32, r1_16, Support.Bq.List.concat(U32, r2_17, Support.Bq.List.concat(U32, r3_18, Support.Bq.List.concat(U32, r4_19, Support.Bq.List.concat(U32, r5_20, Support.Bq.List.concat(U32, ct_21, Support.Bq.List.concat(U32, s0_22, Support.Bq.List.concat(U32, s1_23, Support.Bq.List.concat(U32, s2_24, Support.Bq.List.concat(U32, s3_25, Support.Bq.List.concat(U32, s4_26, Support.Bq.List.concat(U32, b_27, hint_28)))))))))))))))); (+fam_30 = Bq.fame_if(cs_9, a_0); Support.Bq.List.concat(U32, base_29, Support.Bq.List.concat(U32, fam_30, Bq.err_toast(cs_9)))))))))))))))))))))))); \{}})))))))))) : (@+a_0: Sprites.Bq.Assets -> (@+tms_1: U32 -> (@+fst_2: U32 -> (@+fst_3: U32 -> (@+fst_4: U32 -> (@+fst_5: U32 -> (@+fst_6: U32 -> (@+fst_7: U32 -> (@+fst_8: U32 -> (@+cs_9: Bq.CS -> (@+___10: Sigma<&1, &1, U32, (__10 => U32)> -> List<&1, U32>)))))))))))}; apply_687(a_0, tms_1, fst_2, fst_3, fst_4, fst_5, fst_6, fst_7, fst_9, cs_8, snd_10)))); \{}}))))))))) : (@+a_0: Sprites.Bq.Assets -> (@+tms_1: U32 -> (@+fst_2: U32 -> (@+fst_3: U32 -> (@+fst_4: U32 -> (@+fst_5: U32 -> (@+fst_6: U32 -> (@+fst_7: U32 -> (@+cs_8: Bq.CS -> (@+___9: Sigma<&1, &1, U32, (__9 => Sigma<&1, &1, U32, (__10 => U32)>)> -> List<&1, U32>))))))))))}; apply_686(a_0, tms_1, fst_2, fst_3, fst_4, fst_5, fst_6, fst_8, cs_7, snd_9)))); \{}})))))))) : (@+a_0: Sprites.Bq.Assets -> (@+tms_1: U32 -> (@+fst_2: U32 -> (@+fst_3: U32 -> (@+fst_4: U32 -> (@+fst_5: U32 -> (@+fst_6: U32 -> (@+cs_7: Bq.CS -> (@+___8: Sigma<&1, &1, U32, (__8 => Sigma<&1, &1, U32, (__9 => Sigma<&1, &1, U32, (__10 => U32)>)>)> -> List<&1, U32>)))))))))}; apply_685(a_0, tms_1, fst_2, fst_3, fst_4, fst_5, fst_7, cs_6, snd_8)))); \{}}))))))) : (@+a_0: Sprites.Bq.Assets -> (@+tms_1: U32 -> (@+fst_2: U32 -> (@+fst_3: U32 -> (@+fst_4: U32 -> (@+fst_5: U32 -> (@+cs_6: Bq.CS -> (@+___7: Sigma<&1, &1, U32, (__7 => Sigma<&1, &1, U32, (__8 => Sigma<&1, &1, U32, (__9 => Sigma<&1, &1, U32, (__10 => U32)>)>)>)> -> List<&1, U32>))))))))}; apply_684(a_0, tms_1, fst_2, fst_3, fst_4, fst_6, cs_5, snd_7)))); \{}})))))) : (@+a_0: Sprites.Bq.Assets -> (@+tms_1: U32 -> (@+fst_2: U32 -> (@+fst_3: U32 -> (@+fst_4: U32 -> (@+cs_5: Bq.CS -> (@+___6: Sigma<&1, &1, U32, (__6 => Sigma<&1, &1, U32, (__7 => Sigma<&1, &1, U32, (__8 => Sigma<&1, &1, U32, (__9 => Sigma<&1, &1, U32, (__10 => U32)>)>)>)>)> -> List<&1, U32>)))))))}; apply_683(a_0, tms_1, fst_2, fst_3, fst_5, cs_4, snd_6)))); \{}}))))) : (@+a_0: Sprites.Bq.Assets -> (@+tms_1: U32 -> (@+fst_2: U32 -> (@+fst_3: U32 -> (@+cs_4: Bq.CS -> (@+___5: Sigma<&1, &1, U32, (__5 => Sigma<&1, &1, U32, (__6 => Sigma<&1, &1, U32, (__7 => Sigma<&1, &1, U32, (__8 => Sigma<&1, &1, U32, (__9 => Sigma<&1, &1, U32, (__10 => U32)>)>)>)>)>)> -> List<&1, U32>))))))}; apply_682(a_0, tms_1, fst_2, fst_4, cs_3, snd_5)))); \{}})))) : (@+a_0: Sprites.Bq.Assets -> (@+tms_1: U32 -> (@+fst_2: U32 -> (@+cs_3: Bq.CS -> (@+___4: Sigma<&1, &1, U32, (__4 => Sigma<&1, &1, U32, (__5 => Sigma<&1, &1, U32, (__6 => Sigma<&1, &1, U32, (__7 => Sigma<&1, &1, U32, (__8 => Sigma<&1, &1, U32, (__9 => Sigma<&1, &1, U32, (__10 => U32)>)>)>)>)>)>)> -> List<&1, U32>)))))}; apply_681(a_0, tms_1, fst_3, cs_2, snd_4)))); \{}}))) : (@+a_0: Sprites.Bq.Assets -> (@+tms_1: U32 -> (@+cs_2: Bq.CS -> (@+___3: Sigma<&1, &1, U32, (__3 => Sigma<&1, &1, U32, (__4 => Sigma<&1, &1, U32, (__5 => Sigma<&1, &1, U32, (__6 => Sigma<&1, &1, U32, (__7 => Sigma<&1, &1, U32, (__8 => Sigma<&1, &1, U32, (__9 => Sigma<&1, &1, U32, (__10 => U32)>)>)>)>)>)>)>)> -> List<&1, U32>))))}; apply_680(a_1, tms_2, cs_0, Bq.cs_creator_vals(cs_0))))))

@unsafe
def Bq.dash_log():
  \{Nil: (y_0 => Nil{}); \{Con: (l_0 => (rest_1 => (y_2 => (+apply_688 = {(y_0 => (l_1 => (rest_2 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => Support.Bq.List.concat(U32, Bq.text_cmd(40, y_0, 15, 15263984, l_1), Bq.dash_log(rest_2, (y_0 + 21 : U32)))), (_1958_3 => Nil{}), 0))))) : (@+y_0: U32 -> (@+l_1: C.Bq.String -> (@+rest_2: List<&1, C.Bq.String> -> (@+___3: U32 -> List<&1, U32>))))}; apply_688(y_2, l_0, rest_1, C.Bq.bit(U32.is_gt(y_2, 596))))))); \{}}}

@unsafe
def Bq.render_dash():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => (form_2 => \{Bq.Net.Net: (net_on_3 => (sock_4 => (hosting_5 => (hostaddr_6 => (hostlog_7 => (hoststat_8 => (acct_9 => (look_10 => (wv_11 => (ui_12 => (+bg_13 = {[0, 1315871] : List<&1, U32>}; (+t_14 = Bq.text_cmd(40, 28, 30, 16765286, C.Bq.text("BENDQUEST SERVER")); (+ad_15 = Bq.text_cmd(40, 76, 22, 10216959, Support.Bq.List.concat(Char, C.Bq.text("address:  "), hostaddr_6)); (+st_16 = Bq.text_cmd(40, 112, 16, 10216804, hoststat_8); (+b1_17 = Bq.btn(640, 120, 220, 44, 4020894, 40, C.Bq.text("COPY ADDRESS")); (+b2_18 = Bq.btn(640, 180, 220, 44, 8081333, 34, C.Bq.text("RESTART WORLD")); (+b3_19 = Bq.btn(640, 240, 220, 44, 11549266, 46, C.Bq.text("SAVE + STOP")); (+lt_20 = Bq.text_cmd(40, 150, 15, 12110814, C.Bq.text("event log")); (+ln_21 = {[5, 40, 172, 600, 172, 5596791] : List<&1, U32>}; (+ll_22 = Bq.dash_log(hostlog_7, 182); (+hint_23 = Bq.text_cmd(40, 610, 14, 8952234, C.Bq.text("players join via PLAY with the address above; closing this window also saves")); Support.Bq.List.concat(U32, bg_13, Support.Bq.List.concat(U32, t_14, Support.Bq.List.concat(U32, ad_15, Support.Bq.List.concat(U32, st_16, Support.Bq.List.concat(U32, b1_17, Support.Bq.List.concat(U32, b2_18, Support.Bq.List.concat(U32, b3_19, Support.Bq.List.concat(U32, lt_20, Support.Bq.List.concat(U32, ln_21, Support.Bq.List.concat(U32, ll_22, hint_23))))))))))))))))))))))))))))))); \{}}))); \{}}

@unsafe
def Bq.aurora_bg():
  (auro_0 => Bq.spr(auro_0, 0, 128, 128, 0, 0, 8, 0, 16777215))

@unsafe
def Bq.field_col():
  (word => C.Bq.word_case(U32, word, 0, (unit => 5596791), (_2116_0 => 16765286), 0))

@unsafe
def Bq.cursor_of():
  (word => C.Bq.word_case(C.Bq.String, word, 0, (unit => Nil{}), (_2118_0 => C.Bq.text("_")), 0))

@unsafe
def Bq.field_box():
  (label_0 => (val_1 => (x_2 => (y_3 => (focused_4 => (+lab_5 = Bq.text_cmd(x_2, (y_3 - 18 : U32), 13, 12110814, label_0); (+bg_6 = Bq.rect(x_2, y_3, 300, 40, 4028899384); (+ol_7 = Bq.rect_l(x_2, y_3, 300, 40, Bq.field_col(focused_4)); (+tv_8 = Bq.text_cmd((x_2 + 10 : U32), (y_3 + 10 : U32), 16, 16777215, Support.Bq.List.concat(Char, val_1, Bq.cursor_of(focused_4))); Support.Bq.List.concat(U32, lab_5, Support.Bq.List.concat(U32, bg_6, Support.Bq.List.concat(U32, ol_7, tv_8))))))))))))

@unsafe
def Bq.render_host():
  (cs_0 => (a_1 => (auro_2 => (+apply_689 = {(auro_0 => (cs_1 => \{Tuple: (fst_2 => (snd_3 => (+apply_690 = {(auro_0 => (cs_1 => \{Tuple: (fst_2 => (snd_3 => (+apply_691 = {(auro_0 => (cs_1 => \{Tuple: (fst_2 => (snd_3 => (+apply_692 = {(auro_0 => (cs_1 => \{Tuple: (fst_2 => (snd_3 => (+bg_4 = Support.Bq.List.concat(U32, [0, 1710638], Bq.aurora_bg(auro_0)); (+t_5 = Bq.text_cmd(340, 120, 30, 10186725, C.Bq.text("HOST A REALM")); (+f1_6 = Bq.field_box(C.Bq.text("port"), fst_2, 330, 220, 1); (+note_7 = Bq.text_cmd(250, 300, 14, 12110814, C.Bq.text("starts a dedicated server in this window (no hero);")); (+note2_8 = Bq.text_cmd(250, 322, 14, 12110814, C.Bq.text("players join it from another BendQuest via PLAY")); (+b_9 = Bq.btn(380, 430, 200, 50, 8081333, 30, C.Bq.text("START SERVER")); (+hint_10 = Bq.text_cmd(330, 500, 14, 8952234, C.Bq.text("ENTER: start    ESC: back")); Support.Bq.List.concat(U32, bg_4, Support.Bq.List.concat(U32, t_5, Support.Bq.List.concat(U32, f1_6, Support.Bq.List.concat(U32, note_7, Support.Bq.List.concat(U32, note2_8, Support.Bq.List.concat(U32, b_9, Support.Bq.List.concat(U32, hint_10, Bq.err_toast(cs_1))))))))))))))))); \{}})) : (@+auro_0: U32 -> (@+cs_1: Bq.CS -> (@+___2: Sigma<&1, &1, List<&1, Char>, (__2 => List<&1, Char>)> -> List<&1, U32>)))}; apply_692(auro_0, cs_1, snd_3)))); \{}})) : (@+auro_0: U32 -> (@+cs_1: Bq.CS -> (@+___2: Sigma<&1, &1, List<&1, Char>, (__2 => Sigma<&1, &1, List<&1, Char>, (__3 => List<&1, Char>)>)> -> List<&1, U32>)))}; apply_691(auro_0, cs_1, snd_3)))); \{}})) : (@+auro_0: U32 -> (@+cs_1: Bq.CS -> (@+___2: Sigma<&1, &1, U32, (__2 => Sigma<&1, &1, List<&1, Char>, (__3 => Sigma<&1, &1, List<&1, Char>, (__4 => List<&1, Char>)>)>)> -> List<&1, U32>)))}; apply_690(auro_0, cs_1, snd_3)))); \{}})) : (@+auro_0: U32 -> (@+cs_1: Bq.CS -> (@+___2: Sigma<&1, &1, U32, (__2 => Sigma<&1, &1, U32, (__3 => Sigma<&1, &1, List<&1, Char>, (__4 => Sigma<&1, &1, List<&1, Char>, (__5 => List<&1, Char>)>)>)>)> -> List<&1, U32>)))}; apply_689(auro_2, cs_0, Bq.cs_read(cs_0))))))

@unsafe
def Bq.render_join():
  (cs_0 => (a_1 => (auro_2 => (+apply_693 = {(auro_0 => (cs_1 => \{Tuple: (fst_2 => (snd_3 => (+apply_694 = {(auro_0 => (cs_1 => \{Tuple: (fst_2 => (snd_3 => (+apply_695 = {(auro_0 => (fst_1 => (cs_2 => \{Tuple: (fst_3 => (snd_4 => (+apply_696 = {(auro_0 => (fst_1 => (fst_2 => (cs_3 => \{Tuple: (fst_4 => (snd_5 => (+bg_6 = Support.Bq.List.concat(U32, [0, 1710638], Bq.aurora_bg(auro_0)); (+t_7 = Bq.text_cmd(370, 120, 30, 10216959, C.Bq.text("JOIN A REALM")); (+f0_8 = Bq.field_box(C.Bq.text("server ip"), fst_1, 330, 220, C.Bq.bit(U32.is_eq(fst_2, 0))); (+f1_9 = Bq.field_box(C.Bq.text("port"), fst_4, 330, 280, C.Bq.bit(U32.is_eq(fst_2, 1))); (+f2_10 = Bq.field_box(C.Bq.text("hero name"), snd_5, 330, 340, C.Bq.bit(U32.is_eq(fst_2, 2))); (+b_11 = Bq.btn(380, 430, 200, 50, 6539085, 55, C.Bq.text("CONNECT")); (+hint_12 = Bq.text_cmd(330, 500, 12, 8952234, C.Bq.text("TAB: next field   ENTER: connect   ESC: back")); Support.Bq.List.concat(U32, bg_6, Support.Bq.List.concat(U32, t_7, Support.Bq.List.concat(U32, f0_8, Support.Bq.List.concat(U32, f1_9, Support.Bq.List.concat(U32, f2_10, Support.Bq.List.concat(U32, b_11, Support.Bq.List.concat(U32, hint_12, Bq.err_toast(cs_3))))))))))))))))); \{}})))) : (@+auro_0: U32 -> (@+fst_1: C.Bq.String -> (@+fst_2: U32 -> (@+cs_3: Bq.CS -> (@+___4: Sigma<&1, &1, List<&1, Char>, (__4 => List<&1, Char>)> -> List<&1, U32>)))))}; apply_696(auro_0, fst_3, fst_1, cs_2, snd_4)))); \{}}))) : (@+auro_0: U32 -> (@+fst_1: U32 -> (@+cs_2: Bq.CS -> (@+___3: Sigma<&1, &1, List<&1, Char>, (__3 => Sigma<&1, &1, List<&1, Char>, (__4 => List<&1, Char>)>)> -> List<&1, U32>))))}; apply_695(auro_0, fst_2, cs_1, snd_3)))); \{}})) : (@+auro_0: U32 -> (@+cs_1: Bq.CS -> (@+___2: Sigma<&1, &1, U32, (__2 => Sigma<&1, &1, List<&1, Char>, (__3 => Sigma<&1, &1, List<&1, Char>, (__4 => List<&1, Char>)>)>)> -> List<&1, U32>)))}; apply_694(auro_0, cs_1, snd_3)))); \{}})) : (@+auro_0: U32 -> (@+cs_1: Bq.CS -> (@+___2: Sigma<&1, &1, U32, (__2 => Sigma<&1, &1, U32, (__3 => Sigma<&1, &1, List<&1, Char>, (__4 => Sigma<&1, &1, List<&1, Char>, (__5 => List<&1, Char>)>)>)>)> -> List<&1, U32>)))}; apply_693(auro_2, cs_0, Bq.cs_read(cs_0))))))

@unsafe
def Bq.render_menu():
  (cs_0 => (a_1 => (auro_2 => (tms_3 => (+bg_4 = Support.Bq.List.concat(U32, [0, 1710638], Bq.aurora_bg(auro_2)); (+title_5 = Bq.text_cmd(310, 120, 60, 16765286, C.Bq.text("BENDQUEST")); (+sub_6 = Bq.text_cmd(285, 190, 16, 12110814, C.Bq.text("a tiny mmo, fully written and PROVEN in bend")); (+b1_7 = Bq.btn(380, 290, 200, 50, 6539085, 78, C.Bq.text("PLAY")); (+b2_8 = Bq.btn(380, 360, 200, 50, 8081333, 78, C.Bq.text("HOST")); (+b3_9 = Bq.btn(380, 430, 200, 50, 11549266, 78, C.Bq.text("QUIT")); (+c1_10 = Bq.char_cmds(a_1, 240, 300, ((tms_3 / 400 : U32) % 2 : U32), 4, 0, 0, 0, 1, 1, 0, 1); (+c2_11 = Bq.char_cmds(a_1, 660, 300, (((tms_3 + 200 : U32) / 400 : U32) % 2 : U32), 4, 1, 2, 2, 4, 0, 2, 0); (+hint_12 = Bq.text_cmd(360, 560, 14, 8952234, C.Bq.text("P: play    H: host    Q: quit")); Support.Bq.List.concat(U32, bg_4, Support.Bq.List.concat(U32, title_5, Support.Bq.List.concat(U32, sub_6, Support.Bq.List.concat(U32, b1_7, Support.Bq.List.concat(U32, b2_8, Support.Bq.List.concat(U32, b3_9, Support.Bq.List.concat(U32, c1_10, Support.Bq.List.concat(U32, c2_11, Support.Bq.List.concat(U32, hint_12, Bq.err_toast(cs_0)))))))))))))))))))))))

@unsafe
def Bq.render():
  (cs_0 => (a_1 => (auro_2 => (tms_3 => (snds_4 => (+apply_697 = {(cs_0 => (a_1 => (tms_2 => (snds_3 => (auro_4 => \{Tuple: (fst_5 => (snd_6 => (+apply_698 = {(cs_0 => (a_1 => (tms_2 => (snds_3 => (fst_4 => (auro_5 => \{Tuple: (fst_6 => (snd_7 => (+apply_699 = {(cs_0 => (a_1 => (tms_2 => (snds_3 => (fst_4 => (auro_5 => \{Tuple: (fst_6 => (snd_7 => (+apply_700 = {(cs_0 => (a_1 => (tms_2 => (snds_3 => (fst_4 => (auro_5 => \{Tuple: (fst_6 => (snd_7 => (+apply_701 = {(cs_0 => (a_1 => (tms_2 => (snds_3 => (fst_4 => (auro_5 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => (+apply_702 = {(cs_0 => (a_1 => (tms_2 => (snds_3 => (fst_4 => (auro_5 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => (+apply_703 = {(cs_0 => (a_1 => (tms_2 => (snds_3 => (fst_4 => (auro_5 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => (+apply_704 = {(cs_0 => (a_1 => (tms_2 => (snds_3 => (fst_4 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => (+apply_705 = {(cs_0 => (a_1 => (tms_2 => (snds_3 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => Bq.render_game(cs_0, a_1, tms_2, snds_3)), (_2287_4 => Bq.render_creator(cs_0, a_1, tms_2)), 0)))))) : (@+cs_0: Bq.CS -> (@+a_1: Sprites.Bq.Assets -> (@+tms_2: U32 -> (@+snds_3: C.Bq.Pair.Pair(U32, (__3 => U32)) -> (@+___4: U32 -> List<&1, U32>)))))}; apply_705(cs_0, a_1, tms_2, snds_3, C.Bq.bit(U32.is_eq(fst_4, 2))))), (_2289_5 => Bq.render_dash(cs_0)), 0))))))) : (@+cs_0: Bq.CS -> (@+a_1: Sprites.Bq.Assets -> (@+tms_2: U32 -> (@+snds_3: C.Bq.Pair.Pair(U32, (__3 => U32)) -> (@+fst_4: U32 -> (@+___5: U32 -> List<&1, U32>))))))}; apply_704(cs_0, a_1, tms_2, snds_3, fst_4, C.Bq.bit(U32.is_eq(fst_4, 5))))), (_2291_6 => Bq.render_host(cs_0, a_1, auro_5)), 0)))))))) : (@+cs_0: Bq.CS -> (@+a_1: Sprites.Bq.Assets -> (@+tms_2: U32 -> (@+snds_3: C.Bq.Pair.Pair(U32, (__3 => U32)) -> (@+fst_4: U32 -> (@+auro_5: U32 -> (@+___6: U32 -> List<&1, U32>)))))))}; apply_703(cs_0, a_1, tms_2, snds_3, fst_4, auro_5, C.Bq.bit(U32.is_eq(fst_4, 4))))), (_2293_6 => Bq.render_join(cs_0, a_1, auro_5)), 0)))))))) : (@+cs_0: Bq.CS -> (@+a_1: Sprites.Bq.Assets -> (@+tms_2: U32 -> (@+snds_3: C.Bq.Pair.Pair(U32, (__3 => U32)) -> (@+fst_4: U32 -> (@+auro_5: U32 -> (@+___6: U32 -> List<&1, U32>)))))))}; apply_702(cs_0, a_1, tms_2, snds_3, fst_4, auro_5, C.Bq.bit(U32.is_eq(fst_4, 1))))), (_2295_6 => Bq.render_menu(cs_0, a_1, auro_5, tms_2)), 0)))))))) : (@+cs_0: Bq.CS -> (@+a_1: Sprites.Bq.Assets -> (@+tms_2: U32 -> (@+snds_3: C.Bq.Pair.Pair(U32, (__3 => U32)) -> (@+fst_4: U32 -> (@+auro_5: U32 -> (@+___6: U32 -> List<&1, U32>)))))))}; apply_701(cs_0, a_1, tms_2, snds_3, fst_4, auro_5, C.Bq.bit(U32.is_eq(fst_4, 0)))))); \{}})))))) : (@+cs_0: Bq.CS -> (@+a_1: Sprites.Bq.Assets -> (@+tms_2: U32 -> (@+snds_3: C.Bq.Pair.Pair(U32, (__3 => U32)) -> (@+fst_4: U32 -> (@+auro_5: U32 -> (@+___6: Sigma<&1, &1, List<&1, Char>, (__6 => List<&1, Char>)> -> List<&1, U32>)))))))}; apply_700(cs_0, a_1, tms_2, snds_3, fst_4, auro_5, snd_7)))); \{}})))))) : (@+cs_0: Bq.CS -> (@+a_1: Sprites.Bq.Assets -> (@+tms_2: U32 -> (@+snds_3: C.Bq.Pair.Pair(U32, (__3 => U32)) -> (@+fst_4: U32 -> (@+auro_5: U32 -> (@+___6: Sigma<&1, &1, List<&1, Char>, (__6 => Sigma<&1, &1, List<&1, Char>, (__7 => List<&1, Char>)>)> -> List<&1, U32>)))))))}; apply_699(cs_0, a_1, tms_2, snds_3, fst_4, auro_5, snd_7)))); \{}})))))) : (@+cs_0: Bq.CS -> (@+a_1: Sprites.Bq.Assets -> (@+tms_2: U32 -> (@+snds_3: C.Bq.Pair.Pair(U32, (__3 => U32)) -> (@+fst_4: U32 -> (@+auro_5: U32 -> (@+___6: Sigma<&1, &1, U32, (__6 => Sigma<&1, &1, List<&1, Char>, (__7 => Sigma<&1, &1, List<&1, Char>, (__8 => List<&1, Char>)>)>)> -> List<&1, U32>)))))))}; apply_698(cs_0, a_1, tms_2, snds_3, fst_5, auro_4, snd_6)))); \{}}))))) : (@+cs_0: Bq.CS -> (@+a_1: Sprites.Bq.Assets -> (@+tms_2: U32 -> (@+snds_3: C.Bq.Pair.Pair(U32, (__3 => U32)) -> (@+auro_4: U32 -> (@+___5: Sigma<&1, &1, U32, (__5 => Sigma<&1, &1, U32, (__6 => Sigma<&1, &1, List<&1, Char>, (__7 => Sigma<&1, &1, List<&1, Char>, (__8 => List<&1, Char>)>)>)>)> -> List<&1, U32>))))))}; apply_697(cs_0, a_1, tms_3, snds_4, auro_2, Bq.cs_read(cs_0))))))))

@unsafe
def Bq.shot_name():
  (mode_0 => (fn_1 => Support.Bq.String.flatten([C.Bq.text("bq_"), Support.Bq.U32.show(mode_0), C.Bq.text("_"), Support.Bq.U32.show(fn_1), C.Bq.text(".png")])))

@unsafe
def Bq.auto_shot():
  (mode_0 => (fn_1 => (+apply_706 = {(mode_0 => (fn_1 => (word => C.Bq.word_case(IO(Unit), word, 0, (unit => (+apply_707 = {(mode_0 => (fn_1 => (word => C.Bq.word_case(IO(Unit), word, 0, (unit => (+apply_708 = {(mode_0 => (fn_1 => (word => C.Bq.word_case(IO(Unit), word, 0, (unit => C.Bq.IO.pure(Unit, Unit{})), (_2497_2 => Raylib.Bq.rl_screenshot(Bq.shot_name(mode_0, fn_1))), 0)))) : (@+mode_0: U32 -> (@+fn_1: U32 -> (@+___2: U32 -> IO(Unit))))}; apply_708(mode_0, fn_1, C.Bq.word_or(C.Bq.word_or(C.Bq.word_or(C.Bq.word_or(C.Bq.word_or(C.Bq.word_or(C.Bq.bit(U32.is_eq(fn_1, 25)), C.Bq.bit(U32.is_eq(fn_1, 85))), C.Bq.bit(U32.is_eq(fn_1, 250))), C.Bq.bit(U32.is_eq(fn_1, 310))), C.Bq.bit(U32.is_eq(fn_1, 515))), C.Bq.bit(U32.is_eq(fn_1, 580))), C.Bq.bit(U32.is_eq(fn_1, 620)))))), (_2499_2 => (+apply_709 = {(mode_0 => (fn_1 => (word => C.Bq.word_case(IO(Unit), word, 0, (unit => C.Bq.IO.pure(Unit, Unit{})), (_2495_2 => Raylib.Bq.rl_screenshot(Bq.shot_name(mode_0, fn_1))), 0)))) : (@+mode_0: U32 -> (@+fn_1: U32 -> (@+___2: U32 -> IO(Unit))))}; apply_709(mode_0, fn_1, C.Bq.word_or(C.Bq.word_or(C.Bq.bit(U32.is_eq(fn_1, 25)), C.Bq.bit(U32.is_eq(fn_1, 350))), C.Bq.word_and(C.Bq.bit(U32.is_eq((fn_1 % 900 : U32), 0)), C.Bq.bit(U32.is_ge(fn_1, 900))))))), 0)))) : (@+mode_0: U32 -> (@+fn_1: U32 -> (@+___2: U32 -> IO(Unit))))}; apply_707(mode_0, fn_1, C.Bq.bit(U32.is_eq(mode_0, 3))))), (_2501_2 => C.Bq.IO.pure(Unit, Unit{})), 0)))) : (@+mode_0: U32 -> (@+fn_1: U32 -> (@+___2: U32 -> IO(Unit))))}; apply_706(mode_0, fn_1, C.Bq.bit(U32.is_eq(mode_0, 0))))))

@unsafe
def Bq.auto_end():
  (mode_0 => (+apply_710 = {(word => C.Bq.word_case(U32, word, 0, (unit => 640), (_2548_0 => 30000), 0)) : (@+___0: U32 -> U32)}; apply_710(C.Bq.bit(U32.is_eq(mode_0, 3)))))

@unsafe
def Bq.frame_pace():
  (last_0 => C.Bq.IO.bind(U32, U32, C.Bq.IO.now_ms, (t_1 => (+apply_711 = {(t_0 => (last_1 => \{True: C.Bq.IO.bind(Unit, U32, C.Bq.IO.sleep((16 - (t_0 - last_1 : U32) : U32)), (__2 => C.Bq.IO.bind(U32, U32, C.Bq.IO.now_ms, (t2_3 => C.Bq.IO.pure(U32, t2_3))))); \{False: C.Bq.IO.pure(U32, t_0); \{}}})) : (@+t_0: U32 -> (@+last_1: U32 -> (@+___2: Bool -> IO(U32))))}; apply_711(t_1, last_0, Support.Bq.Bool.from_u32(C.Bq.bit(U32.is_lt((t_1 - last_0 : U32), 16))))))))

@unsafe
def Bq.cs_hosting():
  (cs_0 => (+apply_712 = {\{Bq.Net.Net: (net_on_0 => (sock_1 => (hosting_2 => (hostaddr_3 => (hostlog_4 => (hoststat_5 => hosting_2)))))); \{}} : (@+___0: Bq.Net -> U32)}; apply_712(Bq.cs_net(cs_0))))

@unsafe
def Bq.shutdown():
  (cs_0 => (ctl_1 => (+apply_713 = {(ctl_0 => (word => C.Bq.word_case(IO(Unit), word, 0, (unit => C.Bq.IO.bind(Unit, Unit, Raylib.Bq.rl_shutdown, (__1 => C.Bq.IO.print(C.Bq.text("bendquest: bye!"))))), (_2509_1 => C.Bq.IO.bind(Result<&1, &1, C.Bq.Pair.Pair(U32, (__2 => C.Bq.String)), Unit>, Unit, C.Bq.Chan.send(U32, ctl_0, 2), (__2 => C.Bq.IO.bind(Unit, Unit, C.Bq.IO.sleep(400), (__3 => C.Bq.IO.bind(Unit, Unit, Raylib.Bq.rl_shutdown, (__4 => C.Bq.IO.print(C.Bq.text("bendquest: world saved. bye!"))))))))), 0))) : (@+ctl_0: Chan<U32> -> (@+___1: U32 -> IO(Unit)))}; apply_713(ctl_1, Bq.cs_hosting(cs_0)))))

@unsafe
def Bq.cs_quitting():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => (form_2 => (net_3 => (acct_4 => (look_5 => (wv_6 => (ui_7 => quitting_1)))))))); \{}}

@unsafe
def Bq.presses():
  \{Nil: Nil{}; \{Con: (w_0 => (rest_1 => (+apply_714 = {(rest_0 => (w_1 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => Bq.presses(rest_0)), (_612_2 => Con{(w_1 .&. 65535 : U32), Bq.presses(rest_0)}), 0)))) : (@+rest_0: List<&1, U32> -> (@+w_1: U32 -> (@+___2: U32 -> List<&1, U32>)))}; apply_714(rest_1, w_0, C.Bq.bit(U32.is_eq(U32.shrn(w_0, U32.to_nat(28)), 1)))))); \{}}}

@unsafe
def Bq.typed():
  \{Nil: Nil{}; \{Con: (w_0 => (rest_1 => (+apply_715 = {(rest_0 => (w_1 => (word => C.Bq.word_case(List<&1, U32>, word, 0, (unit => Bq.typed(rest_0)), (_617_2 => Con{(w_1 .&. 1048575 : U32), Bq.typed(rest_0)}), 0)))) : (@+rest_0: List<&1, U32> -> (@+w_1: U32 -> (@+___2: U32 -> List<&1, U32>)))}; apply_715(rest_1, w_0, C.Bq.bit(U32.is_eq(U32.shrn(w_0, U32.to_nat(28)), 2)))))); \{}}}

@unsafe
def Bq.held_of():
  (ws_0 => World.Bq.lget(ws_0, 0, 0))

@unsafe
def Bq.mouse_of():
  (ws_0 => World.Bq.lget(ws_0, 1, 0))

@unsafe
def Bq.dir_held():
  (h_0 => (+l_1 = C.Bq.word_or((U32.shrn(h_0, U32.to_nat(0)) .&. 1 : U32), (U32.shrn(h_0, U32.to_nat(5)) .&. 1 : U32)); (+r_2 = C.Bq.word_or((U32.shrn(h_0, U32.to_nat(1)) .&. 1 : U32), (U32.shrn(h_0, U32.to_nat(7)) .&. 1 : U32)); (+u_3 = C.Bq.word_or((U32.shrn(h_0, U32.to_nat(2)) .&. 1 : U32), (U32.shrn(h_0, U32.to_nat(4)) .&. 1 : U32)); (+d_4 = C.Bq.word_or((U32.shrn(h_0, U32.to_nat(3)) .&. 1 : U32), (U32.shrn(h_0, U32.to_nat(6)) .&. 1 : U32)); (+apply_716 = {(u_0 => (r_1 => (word => C.Bq.word_case((@+__3: U32 -> U32), word, 0, (unit => (+apply_717 = {(u_0 => (word => C.Bq.word_case((@+__2: U32 -> U32), word, 0, (unit => (+apply_718 = {(word => C.Bq.word_case((@+__1: U32 -> U32), word, 0, (unit => (word => C.Bq.word_case(U32, word, 0, (unit => 5), (_1191_0 => 3), 0))), (_1192_0 => (d_1 => 2)), 0)) : (@+___0: U32 -> (@+__1: U32 -> U32))}; apply_718(u_0))), (_1193_1 => (d_2 => 1)), 0))) : (@+u_0: U32 -> (@+___1: U32 -> (@+__2: U32 -> U32)))}; apply_717(u_0, r_1))), (_1194_2 => (d_3 => 0)), 0)))) : (@+u_0: U32 -> (@+r_1: U32 -> (@+___2: U32 -> (@+__3: U32 -> U32))))}; apply_716(u_3, r_2, l_1, d_4)))))))

@unsafe
def Bq.move_lines():
  (d_0 => (msent_1 => (+apply_719 = {(d_0 => (word => C.Bq.word_case(List<&1, List<&1, Char>>, word, 0, (unit => (+apply_720 = {(d_0 => (word => C.Bq.word_case(List<&1, List<&1, Char>>, word, 0, (unit => [Proto.Bq.wire_enc(C.Bq.text("MOVE"), [d_0], Nil{})]), (_1357_1 => [Proto.Bq.wire_enc(C.Bq.text("HALT"), Nil{}, Nil{})]), 0))) : (@+d_0: U32 -> (@+___1: U32 -> List<&1, List<&1, Char>>))}; apply_720(d_0, C.Bq.bit(U32.is_eq(d_0, 5))))), (_1359_1 => Nil{}), 0))) : (@+d_0: U32 -> (@+___1: U32 -> List<&1, List<&1, Char>>))}; apply_719(d_0, C.Bq.bit(U32.is_eq(d_0, msent_1))))))

@unsafe
def Bq.cs_move_sent():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => (form_2 => (net_3 => (acct_4 => (look_5 => (wv_6 => \{Bq.Ui.Ui: (inv_open_7 => (quest_open_8 => (shop_open_9 => (dash_open_10 => (fame_open_11 => (chat_open_12 => (chatbuf_13 => (move_sent_14 => (v_15 => Bq.CS.CS{scene_0, quitting_1, form_2, net_3, acct_4, look_5, wv_6, Bq.Ui.Ui{inv_open_7, quest_open_8, shop_open_9, dash_open_10, fame_open_11, chat_open_12, chatbuf_13, v_15}}))))))))); \{}}))))))); \{}}

@unsafe
def Bq.click_if():
  (word => C.Bq.word_case((@+ls_1: List<&1, C.Bq.String> -> List<&1, C.Bq.String>), word, 0, (unit => (ls_0 => Nil{})), (_1362_0 => (ls_1 => ls_1)), 0))

@unsafe
def Bq.hit():
  (m_0 => (x_1 => (y_2 => (w_3 => (h_4 => (+mx_5 = (m_0 .&. 4095 : U32); (+my_6 = (U32.shrn(m_0, U32.to_nat(12)) .&. 4095 : U32); (+clicked_7 = (U32.shrn(m_0, U32.to_nat(26)) .&. 1 : U32); C.Bq.word_and(C.Bq.word_and(C.Bq.word_and(C.Bq.word_and(clicked_7, C.Bq.bit(U32.is_ge(mx_5, x_1))), C.Bq.bit(U32.is_lt(mx_5, (x_1 + w_3 : U32)))), C.Bq.bit(U32.is_ge(my_6, y_2))), C.Bq.bit(U32.is_lt(my_6, (y_2 + h_4 : U32))))))))))))

@unsafe
def Bq.inv_slot_hit():
  (m_0 => (word => C.Bq.word_case(U32, word, 0, (unit => 4294967295), (n2_1 => (+k_2 = (18 - (1 + n2_1 : U32) : U32); (+cx_3 = ((Bq.INV_X + 10 : U32) + ((k_2 % 6 : U32) * 46 : U32) : U32); (+cy_4 = ((Bq.INV_Y + 40 : U32) + ((k_2 / 6 : U32) * 46 : U32) : U32); (+apply_721 = {(m_0 => (n2_1 => (k_2 => (word => C.Bq.word_case(U32, word, 0, (unit => Bq.inv_slot_hit(m_0, n2_1)), (_1214_3 => k_2), 0))))) : (@+m_0: U32 -> (@+n2_1: U32 -> (@+k_2: U32 -> (@+___3: U32 -> U32))))}; apply_721(m_0, n2_1, k_2, Bq.hit(m_0, cx_3, cy_4, 40, 40))))))), 1)))

@unsafe
def Bq.gear_slot_hit():
  (m_0 => (+apply_722 = {(m_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_723 = {(m_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_724 = {(m_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_725 = {(word => C.Bq.word_case(U32, word, 0, (unit => 4294967295), (_1217_0 => 3), 0)) : (@+___0: U32 -> U32)}; apply_725(Bq.hit(m_0, (Bq.INV_X + 148 : U32), (Bq.INV_Y + 196 : U32), 40, 40)))), (_1219_1 => 2), 0))) : (@+m_0: U32 -> (@+___1: U32 -> U32))}; apply_724(m_0, Bq.hit(m_0, (Bq.INV_X + 102 : U32), (Bq.INV_Y + 196 : U32), 40, 40)))), (_1221_1 => 1), 0))) : (@+m_0: U32 -> (@+___1: U32 -> U32))}; apply_723(m_0, Bq.hit(m_0, (Bq.INV_X + 56 : U32), (Bq.INV_Y + 196 : U32), 40, 40)))), (_1223_1 => 0), 0))) : (@+m_0: U32 -> (@+___1: U32 -> U32))}; apply_722(m_0, Bq.hit(m_0, (Bq.INV_X + 10 : U32), (Bq.INV_Y + 196 : U32), 40, 40))))

@unsafe
def Bq.stat_plus_hit():
  (m_0 => (+apply_726 = {(m_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_727 = {(m_0 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_728 = {(word => C.Bq.word_case(U32, word, 0, (unit => 4294967295), (_1226_0 => 2), 0)) : (@+___0: U32 -> U32)}; apply_728(Bq.hit(m_0, (Bq.INV_X + 260 : U32), (Bq.INV_Y + 298 : U32), 24, 20)))), (_1228_1 => 1), 0))) : (@+m_0: U32 -> (@+___1: U32 -> U32))}; apply_727(m_0, Bq.hit(m_0, (Bq.INV_X + 260 : U32), (Bq.INV_Y + 274 : U32), 24, 20)))), (_1230_1 => 0), 0))) : (@+m_0: U32 -> (@+___1: U32 -> U32))}; apply_726(m_0, Bq.hit(m_0, (Bq.INV_X + 260 : U32), (Bq.INV_Y + 250 : U32), 24, 20))))

@unsafe
def Bq.inv_click():
  (m_0 => (me_1 => (+k_2 = Bq.inv_slot_hit(m_0, 18); (+apply_729 = {(m_0 => (me_1 => (k_2 => (word => C.Bq.word_case(List<&1, List<&1, Char>>, word, 0, (unit => (+s_3 = Bq.gear_slot_hit(m_0); (+apply_730 = {(m_0 => (me_1 => (s_2 => (word => C.Bq.word_case(List<&1, List<&1, Char>>, word, 0, (unit => (+a_3 = Bq.stat_plus_hit(m_0); (+apply_731 = {(a_0 => (me_1 => (word => C.Bq.word_case(List<&1, List<&1, Char>>, word, 0, (unit => Nil{}), (_1241_2 => (+apply_732 = {(a_0 => (word => C.Bq.word_case(List<&1, List<&1, Char>>, word, 0, (unit => Nil{}), (_1239_1 => [Proto.Bq.wire_enc(C.Bq.text("ALLOC"), [a_0], Nil{})]), 0))) : (@+a_0: U32 -> (@+___1: U32 -> List<&1, List<&1, Char>>))}; apply_732(a_0, C.Bq.bit(U32.is_gt(World.Bq.lget(me_1, Bq.ME_PTS, 0), 0))))), 0)))) : (@+a_0: U32 -> (@+me_1: List<&1, U32> -> (@+___2: U32 -> List<&1, List<&1, Char>>)))}; apply_731(a_3, me_1, C.Bq.bit(U32.is_ne(a_3, 4294967295)))))), (_1243_3 => [Proto.Bq.wire_enc(C.Bq.text("UNEQ"), [s_2], Nil{})]), 0))))) : (@+m_0: U32 -> (@+me_1: List<&1, U32> -> (@+s_2: U32 -> (@+___3: U32 -> List<&1, List<&1, Char>>))))}; apply_730(m_0, me_1, s_3, C.Bq.bit(U32.is_ne(s_3, 4294967295)))))), (_1245_3 => (+apply_733 = {(k_0 => (word => C.Bq.word_case(List<&1, List<&1, Char>>, word, 0, (unit => Nil{}), (_1235_1 => [Proto.Bq.wire_enc(C.Bq.text("EQUIP"), [k_0], Nil{})]), 0))) : (@+k_0: U32 -> (@+___1: U32 -> List<&1, List<&1, Char>>))}; apply_733(k_2, C.Bq.bit(U32.is_gt(World.Bq.lget(me_1, (Bq.ME_INV0 + k_2 : U32), 0), 0))))), 0))))) : (@+m_0: U32 -> (@+me_1: List<&1, U32> -> (@+k_2: U32 -> (@+___3: U32 -> List<&1, List<&1, Char>>))))}; apply_729(m_0, me_1, k_2, C.Bq.bit(U32.is_ne(k_2, 4294967295)))))))

@unsafe
def Bq.shop_row_hit():
  (m_0 => (word => C.Bq.word_case(U32, word, 0, (unit => 4294967295), (n2_1 => (+i_2 = (Bq.SHOP_ROW_COUNT - (1 + n2_1 : U32) : U32); (+apply_734 = {(m_0 => (n2_1 => (i_2 => (word => C.Bq.word_case(U32, word, 0, (unit => Bq.shop_row_hit(m_0, n2_1)), (_1251_3 => i_2), 0))))) : (@+m_0: U32 -> (@+n2_1: U32 -> (@+i_2: U32 -> (@+___3: U32 -> U32))))}; apply_734(m_0, n2_1, i_2, Bq.hit(m_0, 340, (120 + (i_2 * 44 : U32) : U32), 280, 40))))), 1)))

@unsafe
def Bq.shop_click():
  (m_0 => (+i_1 = Bq.shop_row_hit(m_0, Bq.SHOP_ROW_COUNT); (+apply_735 = {(i_0 => (word => C.Bq.word_case(List<&1, List<&1, Char>>, word, 0, (unit => [Proto.Bq.wire_enc(C.Bq.text("BUY"), [Bq.shop_kind(i_0)], Nil{})]), (_1255_1 => Nil{}), 0))) : (@+i_0: U32 -> (@+___1: U32 -> List<&1, List<&1, Char>>))}; apply_735(i_1, C.Bq.bit(U32.is_eq(i_1, 4294967295))))))

@unsafe
def Bq.game_clicks():
  (cs_0 => (m_1 => (inv_2 => (shp_3 => (+a_4 = Bq.click_if(inv_2, Bq.inv_click(m_1, Bq.cs_me(cs_0))); (+b_5 = Bq.click_if(shp_3, Bq.shop_click(m_1)); Support.Bq.List.concat(C.Bq.String, a_4, b_5)))))))

@unsafe
def Bq.has_press():
  \{Nil: (k_0 => 0); \{Con: (p_0 => (rest_1 => (k_2 => (+apply_736 = {(rest_0 => (k_1 => (word => C.Bq.word_case(U32, word, 0, (unit => Bq.has_press(rest_0, k_1)), (_625_2 => 1), 0)))) : (@+rest_0: List<&1, U32> -> (@+k_1: U32 -> (@+___2: U32 -> U32)))}; apply_736(rest_1, k_2, C.Bq.bit(U32.is_eq(p_0, k_2))))))); \{}}}

@unsafe
def Bq.press_line():
  (ps_0 => (k_1 => (tag_2 => (+apply_737 = {(tag_0 => (word => C.Bq.word_case(List<&1, List<&1, Char>>, word, 0, (unit => Nil{}), (_1373_1 => [Proto.Bq.wire_enc(tag_0, Nil{}, Nil{})]), 0))) : (@+tag_0: C.Bq.String -> (@+___1: U32 -> List<&1, List<&1, Char>>))}; apply_737(tag_2, Bq.has_press(ps_0, k_1))))))

@unsafe
def Bq.cs_grid_at():
  (cs_0 => (x_1 => (y_2 => (+apply_738 = {(y_0 => (x_1 => \{Bq.Wv.Wv: (mypid_2 => (zid_3 => (grid_4 => (plist_5 => (mlist_6 => (names_7 => (me_8 => (snapms_9 => (evl_10 => (bubs_11 => (fxs_12 => World.Bq.lget(grid_4, ((y_0 * Data.Bq.ZONE_W : U32) + x_1 : U32), 0)))))))))))); \{}})) : (@+y_0: U32 -> (@+x_1: U32 -> (@+___2: Bq.Wv -> U32)))}; apply_738(y_2, x_1, Bq.cs_wv(cs_0))))))

@unsafe
def Bq.cs_mypos():
  (cs_0 => (+apply_739 = {\{Bq.Wv.Wv: (mypid_0 => (zid_1 => (grid_2 => (plist_3 => (mlist_4 => (names_5 => (me_6 => (snapms_7 => (evl_8 => (bubs_9 => (fxs_10 => (+apply_740 = {(zid_0 => \{Done: (value_1 => (+apply_741 = {(zid_0 => \{Tuple: (fst_1 => (snd_2 => Tuple{zid_0, Tuple{fst_1, snd_2}})); \{}}) : (@+zid_0: U32 -> (@+___1: Sigma<&1, &1, U32, (__1 => U32)> -> Sigma<&1, &1, U32, (__2 => Sigma<&1, &1, U32, (__3 => U32)>)>))}; apply_741(zid_0, value_1))); \{Fail: (error_1 => Tuple{zid_0, Tuple{0, 0}}); \{}}}) : (@+zid_0: U32 -> (@+___1: Result<&1, &1, Unit, Sigma<&1, &1, U32, (__1 => U32)>> -> Sigma<&1, &1, U32, (__2 => Sigma<&1, &1, U32, (__3 => U32)>)>))}; apply_740(zid_1, Bq.pv_find(plist_3, mypid_0)))))))))))))); \{}} : (@+___0: Bq.Wv -> Sigma<&1, &1, U32, (__1 => Sigma<&1, &1, U32, (__2 => U32)>)>)}; apply_739(Bq.cs_wv(cs_0))))

@unsafe
def Bq.context_line():
  (cs_0 => (+apply_742 = {(cs_0 => \{Tuple: (fst_1 => (snd_2 => (+apply_743 = {(cs_0 => (fst_1 => \{Tuple: (fst_2 => (snd_3 => (+t_4 = Bq.cs_grid_at(cs_0, fst_2, snd_3); (+apply_744 = {(fst_0 => (fst_1 => (snd_2 => (word => C.Bq.word_case(List<&1, List<&1, Char>>, word, 0, (unit => (+apply_745 = {(fst_0 => (fst_1 => (snd_2 => (word => C.Bq.word_case(List<&1, List<&1, Char>>, word, 0, (unit => (+apply_746 = {(word => C.Bq.word_case(List<&1, List<&1, Char>>, word, 0, (unit => Nil{}), (_1201_0 => [Proto.Bq.wire_enc(C.Bq.text("TALK"), [1], Nil{})]), 0)) : (@+___0: U32 -> List<&1, List<&1, Char>>)}; apply_746(C.Bq.word_and(C.Bq.bit(U32.is_eq(fst_0, 0)), C.Bq.bit(U32.is_le(World.Bq.chdist(fst_1, snd_2, Data.Bq.SHOP_X, Data.Bq.SHOP_Y), 2)))))), (_1203_3 => [Proto.Bq.wire_enc(C.Bq.text("TALK"), [0], Nil{})]), 0))))) : (@+fst_0: U32 -> (@+fst_1: U32 -> (@+snd_2: (__2 => U32)(fst_1) -> (@+___3: U32 -> List<&1, List<&1, Char>>))))}; apply_745(fst_0, fst_1, snd_2, C.Bq.word_and(C.Bq.bit(U32.is_eq(fst_0, 0)), C.Bq.bit(U32.is_le(World.Bq.chdist(fst_1, snd_2, Data.Bq.ELDER_X, Data.Bq.ELDER_Y), 2)))))), (_1205_3 => [Proto.Bq.wire_enc(C.Bq.text("ENTER"), Nil{}, Nil{})]), 0))))) : (@+fst_0: U32 -> (@+fst_1: U32 -> (@+snd_2: (__2 => U32)(fst_1) -> (@+___3: U32 -> List<&1, List<&1, Char>>))))}; apply_744(fst_1, fst_2, snd_3, C.Bq.word_or(C.Bq.bit(U32.is_eq(t_4, Data.Bq.T_PORTAL)), C.Bq.bit(U32.is_eq(t_4, Data.Bq.T_RIFTPORTAL)))))))); \{}})) : (@+cs_0: Bq.CS -> (@+fst_1: U32 -> (@+___2: Sigma<&1, &1, U32, (__2 => U32)> -> List<&1, List<&1, Char>>)))}; apply_743(cs_0, fst_1, snd_2)))); \{}}) : (@+cs_0: Bq.CS -> (@+___1: Sigma<&1, &1, U32, (__1 => Sigma<&1, &1, U32, (__2 => U32)>)> -> List<&1, List<&1, Char>>))}; apply_742(cs_0, Bq.cs_mypos(cs_0))))

@unsafe
def Bq.press_ctx():
  (cs_0 => (ps_1 => (+apply_747 = {(cs_0 => (word => C.Bq.word_case(List<&1, List<&1, Char>>, word, 0, (unit => Nil{}), (_1377_1 => Bq.context_line(cs_0)), 0))) : (@+cs_0: Bq.CS -> (@+___1: U32 -> List<&1, List<&1, Char>>))}; apply_747(cs_0, Bq.has_press(ps_1, 70)))))

@unsafe
def Bq.act_lines():
  (cs_0 => (ps_1 => (+a_2 = Bq.press_line(ps_1, 32, C.Bq.text("ATK")); (+b_3 = Bq.press_line(ps_1, 69, C.Bq.text("SPIN")); (+c_4 = Bq.press_line(ps_1, 81, C.Bq.text("QUAFF")); (+f_5 = Bq.press_ctx(cs_0, ps_1); (+h_6 = Bq.press_line(ps_1, 72, C.Bq.text("FAME")); Support.Bq.List.concat(C.Bq.String, a_2, Support.Bq.List.concat(C.Bq.String, b_3, Support.Bq.List.concat(C.Bq.String, c_4, Support.Bq.List.concat(C.Bq.String, f_5, h_6)))))))))))

@unsafe
def Bq.i_xor():
  (v_0 => (flip_1 => (v_0 .^. flip_1 : U32)))

@unsafe
def Bq.cs_toggle():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => (form_2 => (net_3 => (acct_4 => (look_5 => (wv_6 => \{Bq.Ui.Ui: (inv_open_7 => (quest_open_8 => (shop_open_9 => (dash_open_10 => (fame_open_11 => (chat_open_12 => (chatbuf_13 => (move_sent_14 => (which_15 => (+i2_16 = Bq.i_xor(inv_open_7, C.Bq.bit(U32.is_eq(which_15, 0))); (+q2_17 = Bq.i_xor(quest_open_8, C.Bq.bit(U32.is_eq(which_15, 1))); (+s2_18 = Bq.i_xor(shop_open_9, C.Bq.bit(U32.is_eq(which_15, 2))); (+d2_19 = Bq.i_xor(dash_open_10, C.Bq.bit(U32.is_eq(which_15, 3))); (+f2_20 = Bq.i_xor(fame_open_11, C.Bq.bit(U32.is_eq(which_15, 4))); Bq.CS.CS{scene_0, quitting_1, form_2, net_3, acct_4, look_5, wv_6, Bq.Ui.Ui{i2_16, q2_17, s2_18, d2_19, f2_20, chat_open_12, chatbuf_13, move_sent_14}})))))))))))))); \{}}))))))); \{}}

@unsafe
def Bq.cs_chat():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => (form_2 => (net_3 => (acct_4 => (look_5 => (wv_6 => \{Bq.Ui.Ui: (inv_open_7 => (quest_open_8 => (shop_open_9 => (dash_open_10 => (fame_open_11 => (chat_open_12 => (chatbuf_13 => (move_sent_14 => (open_15 => (buf_16 => Bq.CS.CS{scene_0, quitting_1, form_2, net_3, acct_4, look_5, wv_6, Bq.Ui.Ui{inv_open_7, quest_open_8, shop_open_9, dash_open_10, fame_open_11, open_15, buf_16, move_sent_14}})))))))))); \{}}))))))); \{}}

@unsafe
def Bq.tog_if():
  (cs_0 => (on_1 => (which_2 => (+apply_748 = {(cs_0 => (which_1 => (word => C.Bq.word_case(Bq.CS, word, 0, (unit => (+apply_749 = {(cs_0 => (which_1 => (word => C.Bq.word_case(Bq.CS, word, 0, (unit => Bq.cs_toggle(cs_0, which_1)), (_1389_2 => Bq.cs_chat(cs_0, 1, Nil{})), 0)))) : (@+cs_0: Bq.CS -> (@+which_1: U32 -> (@+___2: U32 -> Bq.CS)))}; apply_749(cs_0, which_1, C.Bq.bit(U32.is_eq(which_1, 5))))), (_1391_2 => cs_0), 0)))) : (@+cs_0: Bq.CS -> (@+which_1: U32 -> (@+___2: U32 -> Bq.CS)))}; apply_748(cs_0, which_2, C.Bq.bit(U32.is_eq(on_1, 0)))))))

@unsafe
def Bq.near_the_mat():
  (cs_0 => (+apply_750 = {\{Tuple: (fst_0 => (snd_1 => (+apply_751 = {(fst_0 => \{Tuple: (fst_1 => (snd_2 => C.Bq.word_and(C.Bq.bit(U32.is_eq(fst_0, 0)), C.Bq.bit(U32.is_le(World.Bq.chdist(fst_1, snd_2, Data.Bq.SHOP_X, Data.Bq.SHOP_Y), 2))))); \{}}) : (@+fst_0: U32 -> (@+___1: Sigma<&1, &1, U32, (__1 => U32)> -> U32))}; apply_751(fst_0, snd_1)))); \{}} : (@+___0: Sigma<&1, &1, U32, (__0 => Sigma<&1, &1, U32, (__1 => U32)>)> -> U32)}; apply_750(Bq.cs_mypos(cs_0))))

@unsafe
def Bq.shop_toggle():
  (cs_0 => (on_1 => (+apply_752 = {(cs_0 => (word => C.Bq.word_case(Bq.CS, word, 0, (unit => (+apply_753 = {(cs_0 => (word => C.Bq.word_case(Bq.CS, word, 0, (unit => Bq.cs_err(cs_0, C.Bq.text("the shop opens on Keeper Bramble's mat (zone 1 village)"))), (_1417_1 => Bq.cs_toggle(cs_0, 2)), 0))) : (@+cs_0: Bq.CS -> (@+___1: U32 -> Bq.CS))}; apply_753(cs_0, Bq.near_the_mat(cs_0)))), (_1419_1 => cs_0), 0))) : (@+cs_0: Bq.CS -> (@+___1: U32 -> Bq.CS))}; apply_752(cs_0, C.Bq.bit(U32.is_eq(on_1, 0))))))

@unsafe
def Bq.close_panels():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => (form_2 => (net_3 => (acct_4 => (look_5 => (wv_6 => \{Bq.Ui.Ui: (inv_open_7 => (quest_open_8 => (shop_open_9 => (dash_open_10 => (fame_open_11 => (chat_open_12 => (chatbuf_13 => (move_sent_14 => Bq.CS.CS{scene_0, quitting_1, form_2, net_3, acct_4, look_5, wv_6, Bq.Ui.Ui{0, 0, 0, 0, 0, chat_open_12, chatbuf_13, move_sent_14}})))))))); \{}}))))))); \{}}

@unsafe
def Bq.toggles():
  (cs_0 => (ps_1 => (+cs1_2 = Bq.tog_if(cs_0, Bq.has_press(ps_1, 73), 0); (+cs2_3 = Bq.tog_if(cs1_2, Bq.has_press(ps_1, 258), 1); (+cs3_4 = Bq.shop_toggle(cs2_3, Bq.has_press(ps_1, 66)); (+cs5_5 = Bq.tog_if(cs3_4, Bq.has_press(ps_1, 72), 4); (+cs6_6 = Bq.tog_if(cs5_5, C.Bq.word_or(Bq.has_press(ps_1, 257), Bq.has_press(ps_1, 84)), 5); (+apply_754 = {(cs6_0 => (word => C.Bq.word_case(Bq.CS, word, 0, (unit => cs6_0), (_1428_1 => Bq.close_panels(cs6_0)), 0))) : (@+cs6_0: Bq.CS -> (@+___1: U32 -> Bq.CS))}; apply_754(cs6_6, Bq.has_press(ps_1, 256))))))))))

@unsafe
def Bq.append_cps():
  (s_0 => \{Nil: (maxlen_1 => s_0); \{Con: (c_1 => (rest_2 => (maxlen_3 => (+apply_755 = {(s_0 => (c_1 => (rest_2 => (maxlen_3 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => Bq.append_cps(Support.Bq.List.concat(Char, s_0, [Chr{c_1}]), rest_2, maxlen_3)), (_647_4 => Bq.append_cps(s_0, rest_2, maxlen_3)), 0)))))) : (@+s_0: C.Bq.String -> (@+c_1: U32 -> (@+rest_2: List<&1, U32> -> (@+maxlen_3: U32 -> (@+___4: U32 -> List<&1, Char>)))))}; apply_755(s_0, c_1, rest_2, maxlen_3, C.Bq.word_or(C.Bq.word_or(C.Bq.bit(U32.is_ge(Support.Bq.String.length(s_0), maxlen_3)), C.Bq.bit(U32.is_lt(c_1, 32))), C.Bq.bit(U32.is_gt(c_1, 126)))))))); \{}}})

@unsafe
def Bq.str_tail():
  \{Nil: Nil{}; \{Con: (c_0 => (rest_1 => rest_1)); \{}}}

@unsafe
def Bq.drop_last():
  (s_0 => (n_1 => (+apply_756 = {(s_0 => (word => C.Bq.word_case(List<&1, Char>, word, 0, (unit => Support.Bq.String.reverse(Bq.str_tail(Support.Bq.String.reverse(s_0)))), (_640_1 => s_0), 0))) : (@+s_0: C.Bq.String -> (@+___1: U32 -> List<&1, Char>))}; apply_756(s_0, C.Bq.bit(U32.is_eq(n_1, 0))))))

@unsafe
def Bq.edit_str():
  (s_0 => (cps_1 => (bs_2 => (maxlen_3 => Bq.append_cps(Bq.drop_last(s_0, bs_2), cps_1, maxlen_3)))))

@unsafe
def Bq.say_lines():
  (buf_0 => (+apply_757 = {(buf_0 => (word => C.Bq.word_case(List<&1, List<&1, Char>>, word, 0, (unit => [Proto.Bq.wire_enc(C.Bq.text("SAY"), Nil{}, buf_0)]), (_1353_1 => Nil{}), 0))) : (@+buf_0: C.Bq.String -> (@+___1: U32 -> List<&1, List<&1, Char>>))}; apply_757(buf_0, C.Bq.bit(U32.is_eq(Support.Bq.String.length(buf_0), 0)))))

@unsafe
def Bq.input_game():
  (cs_0 => (ps_1 => (cps_2 => (held_3 => (m_4 => (+apply_758 = {(held_0 => (cs_1 => (m_2 => (ps_3 => (cps_4 => \{Tuple: (fst_5 => (snd_6 => (+apply_759 = {(held_0 => (cs_1 => (m_2 => (fst_3 => (ps_4 => (cps_5 => \{Tuple: (fst_6 => (snd_7 => (+apply_760 = {(held_0 => (cs_1 => (m_2 => (fst_3 => (ps_4 => (cps_5 => \{Tuple: (fst_6 => (snd_7 => (+apply_761 = {(held_0 => (cs_1 => (m_2 => (fst_3 => (fst_4 => (ps_5 => (cps_6 => \{Tuple: (fst_7 => (snd_8 => (+apply_762 = {(held_0 => (cs_1 => (m_2 => (fst_3 => (fst_4 => (ps_5 => (cps_6 => \{Tuple: (fst_7 => (snd_8 => (+apply_763 = {(held_0 => (cs_1 => (m_2 => (fst_3 => (fst_4 => (ps_5 => (cps_6 => \{Tuple: (fst_7 => (snd_8 => (+apply_764 = {(held_0 => (fst_1 => (snd_2 => (cs_3 => (m_4 => (fst_5 => (fst_6 => (ps_7 => (cps_8 => (word => C.Bq.word_case(Sigma<&1, &1, Bq.CS, (__10 => List<&1, List<&1, Char>>)>, word, 0, (unit => (+d_9 = Bq.dir_held(held_0); (+mv_10 = Bq.move_lines(d_9, snd_2); (+cs1_11 = Bq.cs_move_sent(cs_3, d_9); (+clicks_12 = Bq.game_clicks(cs1_11, m_4, fst_5, fst_6); (+acts_13 = Bq.act_lines(cs1_11, ps_7); (+cs2_14 = Bq.toggles(cs1_11, ps_7); Tuple{cs2_14, Support.Bq.List.concat(C.Bq.String, mv_10, Support.Bq.List.concat(C.Bq.String, clicks_12, acts_13))}))))))), (_1454_9 => (+buf_10 = Bq.edit_str(Bq.cs_chatbuf(cs_3), cps_8, Bq.has_press(ps_7, 259), 60); (+apply_765 = {(cs_0 => (buf_1 => (ps_2 => (word => C.Bq.word_case(Sigma<&1, &1, Bq.CS, (__4 => List<&1, List<&1, Char>>)>, word, 0, (unit => (+apply_766 = {(cs_0 => (buf_1 => (word => C.Bq.word_case(Sigma<&1, &1, Bq.CS, (__3 => List<&1, List<&1, Char>>)>, word, 0, (unit => Tuple{Bq.cs_chat(cs_0, 1, buf_1), Nil{}}), (_1444_2 => Tuple{Bq.cs_chat(cs_0, 0, Nil{}), Nil{}}), 0)))) : (@+cs_0: Bq.CS -> (@+buf_1: C.Bq.String -> (@+___2: U32 -> Sigma<&1, &1, Bq.CS, (__3 => List<&1, List<&1, Char>>)>)))}; apply_766(cs_0, buf_1, Bq.has_press(ps_2, 256)))), (_1446_3 => (+out_4 = Bq.say_lines(buf_1); Tuple{Bq.cs_chat(cs_0, 0, Nil{}), out_4})), 0))))) : (@+cs_0: Bq.CS -> (@+buf_1: C.Bq.String -> (@+ps_2: List<&1, U32> -> (@+___3: U32 -> Sigma<&1, &1, Bq.CS, (__4 => List<&1, List<&1, Char>>)>))))}; apply_765(cs_3, buf_10, ps_7, Bq.has_press(ps_7, 257))))), 0))))))))))) : (@+held_0: U32 -> (@-fst_1: U32 -> (@+snd_2: (__2 => U32)(fst_1) -> (@+cs_3: Bq.CS -> (@+m_4: U32 -> (@+fst_5: U32 -> (@+fst_6: U32 -> (@+ps_7: List<&1, U32> -> (@+cps_8: List<&1, U32> -> (@+___9: U32 -> Sigma<&1, &1, Bq.CS, (__10 => List<&1, List<&1, Char>>)>))))))))))}; apply_764(held_0, fst_7, snd_8, cs_1, m_2, fst_3, fst_4, ps_5, cps_6, C.Bq.bit(U32.is_eq(fst_7, 1)))))); \{}}))))))) : (@+held_0: U32 -> (@+cs_1: Bq.CS -> (@+m_2: U32 -> (@+fst_3: U32 -> (@+fst_4: U32 -> (@+ps_5: List<&1, U32> -> (@+cps_6: List<&1, U32> -> (@+___7: Sigma<&1, &1, U32, (__7 => U32)> -> Sigma<&1, &1, Bq.CS, (__8 => List<&1, List<&1, Char>>)>))))))))}; apply_763(held_0, cs_1, m_2, fst_3, fst_4, ps_5, cps_6, snd_8)))); \{}}))))))) : (@+held_0: U32 -> (@+cs_1: Bq.CS -> (@+m_2: U32 -> (@+fst_3: U32 -> (@+fst_4: U32 -> (@+ps_5: List<&1, U32> -> (@+cps_6: List<&1, U32> -> (@+___7: Sigma<&1, &1, U32, (__7 => Sigma<&1, &1, U32, (__8 => U32)>)> -> Sigma<&1, &1, Bq.CS, (__8 => List<&1, List<&1, Char>>)>))))))))}; apply_762(held_0, cs_1, m_2, fst_3, fst_4, ps_5, cps_6, snd_8)))); \{}}))))))) : (@+held_0: U32 -> (@+cs_1: Bq.CS -> (@+m_2: U32 -> (@+fst_3: U32 -> (@+fst_4: U32 -> (@+ps_5: List<&1, U32> -> (@+cps_6: List<&1, U32> -> (@+___7: Sigma<&1, &1, U32, (__7 => Sigma<&1, &1, U32, (__8 => Sigma<&1, &1, U32, (__9 => U32)>)>)> -> Sigma<&1, &1, Bq.CS, (__8 => List<&1, List<&1, Char>>)>))))))))}; apply_761(held_0, cs_1, m_2, fst_3, fst_6, ps_4, cps_5, snd_7)))); \{}})))))) : (@+held_0: U32 -> (@+cs_1: Bq.CS -> (@+m_2: U32 -> (@+fst_3: U32 -> (@+ps_4: List<&1, U32> -> (@+cps_5: List<&1, U32> -> (@+___6: Sigma<&1, &1, U32, (__6 => Sigma<&1, &1, U32, (__7 => Sigma<&1, &1, U32, (__8 => Sigma<&1, &1, U32, (__9 => U32)>)>)>)> -> Sigma<&1, &1, Bq.CS, (__7 => List<&1, List<&1, Char>>)>)))))))}; apply_760(held_0, cs_1, m_2, fst_3, ps_4, cps_5, snd_7)))); \{}})))))) : (@+held_0: U32 -> (@+cs_1: Bq.CS -> (@+m_2: U32 -> (@+fst_3: U32 -> (@+ps_4: List<&1, U32> -> (@+cps_5: List<&1, U32> -> (@+___6: Sigma<&1, &1, U32, (__6 => Sigma<&1, &1, U32, (__7 => Sigma<&1, &1, U32, (__8 => Sigma<&1, &1, U32, (__9 => Sigma<&1, &1, U32, (__10 => U32)>)>)>)>)> -> Sigma<&1, &1, Bq.CS, (__7 => List<&1, List<&1, Char>>)>)))))))}; apply_759(held_0, cs_1, m_2, fst_5, ps_3, cps_4, snd_6)))); \{}}))))) : (@+held_0: U32 -> (@+cs_1: Bq.CS -> (@+m_2: U32 -> (@+ps_3: List<&1, U32> -> (@+cps_4: List<&1, U32> -> (@+___5: Sigma<&1, &1, U32, (__5 => Sigma<&1, &1, U32, (__6 => Sigma<&1, &1, U32, (__7 => Sigma<&1, &1, U32, (__8 => Sigma<&1, &1, U32, (__9 => Sigma<&1, &1, U32, (__10 => U32)>)>)>)>)>)> -> Sigma<&1, &1, Bq.CS, (__6 => List<&1, List<&1, Char>>)>))))))}; apply_758(held_3, cs_0, m_4, ps_1, cps_2, Bq.cs_flags(cs_0))))))))

@unsafe
def Bq.cyc_step():
  (cur_0 => (mask_1 => (maxid_2 => (word => C.Bq.word_case(U32, word, 0, (unit => 0), (f_3 => (+nxt_4 = ((cur_0 + 1 : U32) % (maxid_2 + 1 : U32) : U32); (+apply_767 = {(nxt_0 => (mask_1 => (maxid_2 => (f_3 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_768 = {(nxt_0 => (mask_1 => (maxid_2 => (f_3 => (word => C.Bq.word_case(U32, word, 0, (unit => Bq.cyc_step(nxt_0, mask_1, maxid_2, f_3)), (_718_4 => nxt_0), 0)))))) : (@+nxt_0: U32 -> (@+mask_1: U32 -> (@+maxid_2: U32 -> (@+f_3: U32 -> (@+___4: U32 -> U32)))))}; apply_768(nxt_0, mask_1, maxid_2, f_3, C.Bq.bit(U32.is_eq((U32.shrn(mask_1, U32.to_nat((nxt_0 - 1 : U32))) .&. 1 : U32), 1))))), (_720_4 => 0), 0)))))) : (@+nxt_0: U32 -> (@+mask_1: U32 -> (@+maxid_2: U32 -> (@+f_3: U32 -> (@+___4: U32 -> U32)))))}; apply_767(nxt_4, mask_1, maxid_2, f_3, C.Bq.bit(U32.is_eq(nxt_4, 0)))))), 1)))))

@unsafe
def Bq.cyc_own():
  (cur_0 => (d_1 => (mask_2 => (maxid_3 => (+apply_769 = {(cur_0 => (mask_1 => (maxid_2 => (word => C.Bq.word_case(U32, word, 0, (unit => Bq.cyc_step(cur_0, mask_1, maxid_2, (maxid_2 + 1 : U32))), (_726_3 => cur_0), 0))))) : (@+cur_0: U32 -> (@+mask_1: U32 -> (@+maxid_2: U32 -> (@+___3: U32 -> U32))))}; apply_769(cur_0, mask_2, maxid_3, C.Bq.bit(U32.is_eq(d_1, 0))))))))

@unsafe
def Bq.cs_creator():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => (form_2 => (net_3 => \{Bq.Acct.Acct: (coins_4 => (ownh_5 => (ownc_6 => (wno_7 => (phase_8 => (fame_9 => (over_10 => \{Bq.Look.Look: (skin_11 => (hairs_12 => (hairc_13 => (shirt_14 => (hat_15 => (cape_16 => (wv_17 => (ui_18 => (dskin_19 => (dhairs_20 => (dhairc_21 => (dshirt_22 => (dhat_23 => (dcape_24 => (+lk2_25 = {Bq.Look.Look{((skin_11 + dskin_19 : U32) % 4 : U32), ((hairs_12 + dhairs_20 : U32) % 3 : U32), ((hairc_13 + dhairc_21 : U32) % 6 : U32), ((shirt_14 + dshirt_22 : U32) % 6 : U32), Bq.cyc_own(hat_15, dhat_23, ownh_5, 3), Bq.cyc_own(cape_16, dcape_24, ownc_6, 2)} : Bq.Look}; (+ac2_26 = {Bq.Acct.Acct{coins_4, ownh_5, ownc_6, wno_7, phase_8, fame_9, over_10} : Bq.Acct}; Bq.CS.CS{scene_0, quitting_1, form_2, net_3, ac2_26, lk2_25, wv_17, ui_18})))))))))))))))); \{}}))))))); \{}})))); \{}}

@unsafe
def Bq.creator_shop_click():
  (m_0 => (+apply_770 = {(m_0 => (word => C.Bq.word_case(List<&1, List<&1, Char>>, word, 0, (unit => (+apply_771 = {(m_0 => (word => C.Bq.word_case(List<&1, List<&1, Char>>, word, 0, (unit => (+apply_772 = {(m_0 => (word => C.Bq.word_case(List<&1, List<&1, Char>>, word, 0, (unit => (+apply_773 = {(m_0 => (word => C.Bq.word_case(List<&1, List<&1, Char>>, word, 0, (unit => (+apply_774 = {(word => C.Bq.word_case(List<&1, List<&1, Char>>, word, 0, (unit => Nil{}), (_1317_0 => [Proto.Bq.wire_enc(C.Bq.text("SHOP"), [1, 2], Nil{})]), 0)) : (@+___0: U32 -> List<&1, List<&1, Char>>)}; apply_774(Bq.hit(m_0, 290, 498, 200, 34)))), (_1319_1 => [Proto.Bq.wire_enc(C.Bq.text("SHOP"), [1, 1], Nil{})]), 0))) : (@+m_0: U32 -> (@+___1: U32 -> List<&1, List<&1, Char>>))}; apply_773(m_0, Bq.hit(m_0, 290, 460, 200, 34)))), (_1321_1 => [Proto.Bq.wire_enc(C.Bq.text("SHOP"), [0, 3], Nil{})]), 0))) : (@+m_0: U32 -> (@+___1: U32 -> List<&1, List<&1, Char>>))}; apply_772(m_0, Bq.hit(m_0, 60, 536, 200, 34)))), (_1323_1 => [Proto.Bq.wire_enc(C.Bq.text("SHOP"), [0, 2], Nil{})]), 0))) : (@+m_0: U32 -> (@+___1: U32 -> List<&1, List<&1, Char>>))}; apply_771(m_0, Bq.hit(m_0, 60, 498, 200, 34)))), (_1325_1 => [Proto.Bq.wire_enc(C.Bq.text("SHOP"), [0, 1], Nil{})]), 0))) : (@+m_0: U32 -> (@+___1: U32 -> List<&1, List<&1, Char>>))}; apply_770(m_0, Bq.hit(m_0, 60, 460, 200, 34))))

@unsafe
def Bq.input_creator():
  (cs_0 => (ps_1 => (m_2 => (+d0_3 = Bq.hit(m_2, 560, 150, 30, 30); (+d1_4 = Bq.hit(m_2, 560, 195, 30, 30); (+d2_5 = Bq.hit(m_2, 560, 240, 30, 30); (+d3_6 = Bq.hit(m_2, 560, 285, 30, 30); (+d4_7 = Bq.hit(m_2, 560, 330, 30, 30); (+d5_8 = Bq.hit(m_2, 560, 375, 30, 30); (+cs1_9 = Bq.cs_creator(cs_0, d0_3, d1_4, d2_5, d3_6, d4_7, d5_8); (+sh_10 = Bq.creator_shop_click(m_2); (+apply_775 = {(cs1_0 => (sh_1 => (ps_2 => (m_3 => (word => C.Bq.word_case(Sigma<&1, &1, Bq.CS, (__5 => List<&1, List<&1, Char>>)>, word, 0, (unit => (+apply_776 = {(cs1_0 => (sh_1 => (word => C.Bq.word_case(Sigma<&1, &1, Bq.CS, (__3 => List<&1, List<&1, Char>>)>, word, 0, (unit => Tuple{cs1_0, sh_1}), (_1348_2 => (+apply_777 = {(cs1_0 => \{Tuple: (fst_1 => (snd_2 => (+apply_778 = {(cs1_0 => (fst_1 => \{Tuple: (fst_2 => (snd_3 => (+apply_779 = {(cs1_0 => (fst_1 => (fst_2 => \{Tuple: (fst_3 => (snd_4 => (+apply_780 = {(cs1_0 => (fst_1 => (fst_2 => (fst_3 => \{Tuple: (fst_4 => (snd_5 => (+apply_781 = {(cs1_0 => (fst_1 => (fst_2 => (fst_3 => (fst_4 => \{Tuple: (fst_5 => (snd_6 => (+apply_782 = {(cs1_0 => (fst_1 => (fst_2 => (fst_3 => (fst_4 => (fst_5 => \{Tuple: (fst_6 => (snd_7 => (+apply_783 = {(cs1_0 => (fst_1 => (fst_2 => (fst_3 => (fst_4 => (fst_5 => (fst_6 => \{Tuple: (fst_7 => (snd_8 => (+apply_784 = {(cs1_0 => (fst_1 => (fst_2 => (fst_3 => (fst_4 => (fst_5 => (fst_6 => \{Tuple: (fst_7 => (snd_8 => Tuple{cs1_0, [Proto.Bq.wire_enc(C.Bq.text("CREATE"), [fst_1, fst_2, fst_3, fst_4, fst_5, fst_6], Nil{})]})); \{}}))))))) : (@+cs1_0: Bq.CS -> (@+fst_1: U32 -> (@+fst_2: U32 -> (@+fst_3: U32 -> (@+fst_4: U32 -> (@+fst_5: U32 -> (@+fst_6: U32 -> (@+___7: Sigma<&1, &1, U32, (__7 => U32)> -> Sigma<&1, &1, Bq.CS, (__8 => List<&1, List<&1, Char>>)>))))))))}; apply_784(cs1_0, fst_1, fst_2, fst_3, fst_4, fst_5, fst_6, snd_8)))); \{}}))))))) : (@+cs1_0: Bq.CS -> (@+fst_1: U32 -> (@+fst_2: U32 -> (@+fst_3: U32 -> (@+fst_4: U32 -> (@+fst_5: U32 -> (@+fst_6: U32 -> (@+___7: Sigma<&1, &1, U32, (__7 => Sigma<&1, &1, U32, (__8 => U32)>)> -> Sigma<&1, &1, Bq.CS, (__8 => List<&1, List<&1, Char>>)>))))))))}; apply_783(cs1_0, fst_1, fst_2, fst_3, fst_4, fst_5, fst_6, snd_7)))); \{}})))))) : (@+cs1_0: Bq.CS -> (@+fst_1: U32 -> (@+fst_2: U32 -> (@+fst_3: U32 -> (@+fst_4: U32 -> (@+fst_5: U32 -> (@+___6: Sigma<&1, &1, U32, (__6 => Sigma<&1, &1, U32, (__7 => Sigma<&1, &1, U32, (__8 => U32)>)>)> -> Sigma<&1, &1, Bq.CS, (__7 => List<&1, List<&1, Char>>)>)))))))}; apply_782(cs1_0, fst_1, fst_2, fst_3, fst_4, fst_5, snd_6)))); \{}}))))) : (@+cs1_0: Bq.CS -> (@+fst_1: U32 -> (@+fst_2: U32 -> (@+fst_3: U32 -> (@+fst_4: U32 -> (@+___5: Sigma<&1, &1, U32, (__5 => Sigma<&1, &1, U32, (__6 => Sigma<&1, &1, U32, (__7 => Sigma<&1, &1, U32, (__8 => U32)>)>)>)> -> Sigma<&1, &1, Bq.CS, (__6 => List<&1, List<&1, Char>>)>))))))}; apply_781(cs1_0, fst_1, fst_2, fst_3, fst_4, snd_5)))); \{}})))) : (@+cs1_0: Bq.CS -> (@+fst_1: U32 -> (@+fst_2: U32 -> (@+fst_3: U32 -> (@+___4: Sigma<&1, &1, U32, (__4 => Sigma<&1, &1, U32, (__5 => Sigma<&1, &1, U32, (__6 => Sigma<&1, &1, U32, (__7 => Sigma<&1, &1, U32, (__8 => U32)>)>)>)>)> -> Sigma<&1, &1, Bq.CS, (__5 => List<&1, List<&1, Char>>)>)))))}; apply_780(cs1_0, fst_1, fst_2, fst_3, snd_4)))); \{}}))) : (@+cs1_0: Bq.CS -> (@+fst_1: U32 -> (@+fst_2: U32 -> (@+___3: Sigma<&1, &1, U32, (__3 => Sigma<&1, &1, U32, (__4 => Sigma<&1, &1, U32, (__5 => Sigma<&1, &1, U32, (__6 => Sigma<&1, &1, U32, (__7 => Sigma<&1, &1, U32, (__8 => U32)>)>)>)>)>)> -> Sigma<&1, &1, Bq.CS, (__4 => List<&1, List<&1, Char>>)>))))}; apply_779(cs1_0, fst_1, fst_2, snd_3)))); \{}})) : (@+cs1_0: Bq.CS -> (@+fst_1: U32 -> (@+___2: Sigma<&1, &1, U32, (__2 => Sigma<&1, &1, U32, (__3 => Sigma<&1, &1, U32, (__4 => Sigma<&1, &1, U32, (__5 => Sigma<&1, &1, U32, (__6 => Sigma<&1, &1, U32, (__7 => Sigma<&1, &1, U32, (__8 => U32)>)>)>)>)>)>)> -> Sigma<&1, &1, Bq.CS, (__3 => List<&1, List<&1, Char>>)>)))}; apply_778(cs1_0, fst_1, snd_2)))); \{}}) : (@+cs1_0: Bq.CS -> (@+___1: Sigma<&1, &1, U32, (__1 => Sigma<&1, &1, U32, (__2 => Sigma<&1, &1, U32, (__3 => Sigma<&1, &1, U32, (__4 => Sigma<&1, &1, U32, (__5 => Sigma<&1, &1, U32, (__6 => Sigma<&1, &1, U32, (__7 => Sigma<&1, &1, U32, (__8 => U32)>)>)>)>)>)>)>)> -> Sigma<&1, &1, Bq.CS, (__2 => List<&1, List<&1, Char>>)>))}; apply_777(cs1_0, Bq.cs_creator_vals(cs1_0)))), 0)))) : (@+cs1_0: Bq.CS -> (@+sh_1: List<&1, C.Bq.String> -> (@+___2: U32 -> Sigma<&1, &1, Bq.CS, (__3 => List<&1, List<&1, Char>>)>)))}; apply_776(cs1_0, sh_1, C.Bq.word_or(Bq.has_press(ps_2, 257), Bq.hit(m_3, 640, 480, 240, 60))))), (_1350_4 => Tuple{Bq.cs_toggle(cs1_0, 4), [C.Bq.text("FAME")]}), 0)))))) : (@+cs1_0: Bq.CS -> (@+sh_1: List<&1, C.Bq.String> -> (@+ps_2: List<&1, U32> -> (@+m_3: U32 -> (@+___4: U32 -> Sigma<&1, &1, Bq.CS, (__5 => List<&1, List<&1, Char>>)>)))))}; apply_775(cs1_9, sh_10, ps_1, m_2, Bq.has_press(ps_1, 72))))))))))))))

@unsafe
def Bq.input_dash():
  (cs_0 => (ps_1 => (m_2 => (+apply_785 = {(cs_0 => (m_1 => (word => C.Bq.word_case(Sigma<&1, &1, Bq.CS, (__3 => List<&1, List<&1, Char>>)>, word, 0, (unit => (+apply_786 = {(cs_0 => (m_1 => (word => C.Bq.word_case(Sigma<&1, &1, Bq.CS, (__3 => List<&1, List<&1, Char>>)>, word, 0, (unit => (+apply_787 = {(cs_0 => (word => C.Bq.word_case(Sigma<&1, &1, Bq.CS, (__2 => List<&1, List<&1, Char>>)>, word, 0, (unit => Tuple{cs_0, Nil{}}), (_1260_1 => Tuple{cs_0, [C.Bq.text("!STOP")]}), 0))) : (@+cs_0: Bq.CS -> (@+___1: U32 -> Sigma<&1, &1, Bq.CS, (__2 => List<&1, List<&1, Char>>)>))}; apply_787(cs_0, Bq.hit(m_1, 640, 240, 220, 44)))), (_1262_2 => Tuple{cs_0, [C.Bq.text("!RESTART")]}), 0)))) : (@+cs_0: Bq.CS -> (@+m_1: U32 -> (@+___2: U32 -> Sigma<&1, &1, Bq.CS, (__3 => List<&1, List<&1, Char>>)>)))}; apply_786(cs_0, m_1, Bq.hit(m_1, 640, 180, 220, 44)))), (_1264_2 => Tuple{cs_0, [C.Bq.text("!COPY")]}), 0)))) : (@+cs_0: Bq.CS -> (@+m_1: U32 -> (@+___2: U32 -> Sigma<&1, &1, Bq.CS, (__3 => List<&1, List<&1, Char>>)>)))}; apply_785(cs_0, m_2, Bq.hit(m_2, 640, 120, 220, 44))))))

@unsafe
def Bq.edit_pick():
  (s_0 => (word => C.Bq.word_case((@+cps_2: List<&1, U32> -> (@+bs_3: U32 -> (@+ml_4: U32 -> C.Bq.String))), word, 0, (unit => (cps_1 => (bs_2 => (ml_3 => s_0)))), (_691_1 => (cps_2 => (bs_3 => (ml_4 => Bq.edit_str(s_0, cps_2, bs_3, ml_4))))), 0)))

@unsafe
def Bq.cs_edit_field():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => \{Bq.Form.Form: (focus_2 => (f_ip_3 => (f_port_4 => (f_name_5 => (err_6 => (net_7 => (acct_8 => (look_9 => (wv_10 => (ui_11 => (cps_12 => (bs_13 => (+ip2_14 = Bq.edit_pick(f_ip_3, C.Bq.bit(U32.is_eq(focus_2, 0)), cps_12, bs_13, 15); (+po2_15 = Bq.edit_pick(f_port_4, C.Bq.bit(U32.is_eq(focus_2, 1)), cps_12, bs_13, 5); (+na2_16 = Bq.edit_pick(f_name_5, C.Bq.bit(U32.is_eq(focus_2, 2)), cps_12, bs_13, 12); Bq.CS.CS{scene_0, quitting_1, Bq.Form.Form{focus_2, ip2_14, po2_15, na2_16, err_6}, net_7, acct_8, look_9, wv_10, ui_11}))))))))))))))); \{}})); \{}}

@unsafe
def Bq.cs_focus():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => \{Bq.Form.Form: (focus_2 => (f_ip_3 => (f_port_4 => (f_name_5 => (err_6 => (net_7 => (acct_8 => (look_9 => (wv_10 => (ui_11 => (v_12 => Bq.CS.CS{scene_0, quitting_1, Bq.Form.Form{v_12, f_ip_3, f_port_4, f_name_5, err_6}, net_7, acct_8, look_9, wv_10, ui_11}))))))))))); \{}})); \{}}

@unsafe
def Bq.input_host():
  (cs_0 => (ps_1 => (cps_2 => (m_3 => (+cs2_4 = Bq.cs_edit_field(Bq.cs_focus(cs_0, 1), cps_2, Bq.has_press(ps_1, 259)); (+apply_788 = {(cs2_0 => (ps_1 => (word => C.Bq.word_case(Sigma<&1, &1, Bq.CS, (__3 => List<&1, List<&1, Char>>)>, word, 0, (unit => (+apply_789 = {(cs2_0 => (word => C.Bq.word_case(Sigma<&1, &1, Bq.CS, (__2 => List<&1, List<&1, Char>>)>, word, 0, (unit => Tuple{cs2_0, Nil{}}), (_1312_1 => Tuple{Bq.cs_scene(cs2_0, 0), Nil{}}), 0))) : (@+cs2_0: Bq.CS -> (@+___1: U32 -> Sigma<&1, &1, Bq.CS, (__2 => List<&1, List<&1, Char>>)>))}; apply_789(cs2_0, Bq.has_press(ps_1, 256)))), (_1314_2 => Tuple{cs2_0, [C.Bq.text("!HOST")]}), 0)))) : (@+cs2_0: Bq.CS -> (@+ps_1: List<&1, U32> -> (@+___2: U32 -> Sigma<&1, &1, Bq.CS, (__3 => List<&1, List<&1, Char>>)>)))}; apply_788(cs2_4, ps_1, C.Bq.word_and(C.Bq.word_or(Bq.has_press(ps_1, 257), Bq.hit(m_3, 380, 430, 200, 50)), (1 - Bq.cs_hosting(cs2_4) : U32)))))))))

@unsafe
def Bq.field_hit():
  (m_0 => (base_y_1 => (word => C.Bq.word_case(U32, word, 0, (unit => 4294967295), (n2_2 => (+i_3 = (2 - n2_2 : U32); (+apply_790 = {(m_0 => (base_y_1 => (n2_2 => (i_3 => (word => C.Bq.word_case(U32, word, 0, (unit => Bq.field_hit(m_0, base_y_1, n2_2)), (_1280_4 => i_3), 0)))))) : (@+m_0: U32 -> (@+base_y_1: U32 -> (@+n2_2: U32 -> (@+i_3: U32 -> (@+___4: U32 -> U32)))))}; apply_790(m_0, base_y_1, n2_2, i_3, Bq.hit(m_0, 330, (base_y_1 + (i_3 * 60 : U32) : U32), 300, 40))))), 1))))

@unsafe
def Bq.field_click():
  (cs_0 => (m_1 => (base_y_2 => (nfields_3 => (+f_4 = Bq.field_hit(m_1, base_y_2, nfields_3); (+apply_791 = {(cs_0 => (f_1 => (word => C.Bq.word_case(Bq.CS, word, 0, (unit => Bq.cs_focus(cs_0, f_1)), (_1287_2 => cs_0), 0)))) : (@+cs_0: Bq.CS -> (@+f_1: U32 -> (@+___2: U32 -> Bq.CS)))}; apply_791(cs_0, f_4, C.Bq.bit(U32.is_eq(f_4, 4294967295)))))))))

@unsafe
def Bq.input_join():
  (cs_0 => (ps_1 => (cps_2 => (m_3 => (+cs1_4 = Bq.field_click(cs_0, m_3, 220, 3); (+cs2_5 = Bq.cs_edit_field(cs1_4, cps_2, Bq.has_press(ps_1, 259)); (+apply_792 = {(cs2_0 => (ps_1 => (m_2 => (word => C.Bq.word_case(Sigma<&1, &1, Bq.CS, (__4 => List<&1, List<&1, Char>>)>, word, 0, (unit => (+apply_793 = {(cs2_0 => (ps_1 => (word => C.Bq.word_case(Sigma<&1, &1, Bq.CS, (__3 => List<&1, List<&1, Char>>)>, word, 0, (unit => (+apply_794 = {(cs2_0 => (word => C.Bq.word_case(Sigma<&1, &1, Bq.CS, (__2 => List<&1, List<&1, Char>>)>, word, 0, (unit => Tuple{cs2_0, Nil{}}), (_1301_1 => Tuple{Bq.cs_scene(cs2_0, 0), Nil{}}), 0))) : (@+cs2_0: Bq.CS -> (@+___1: U32 -> Sigma<&1, &1, Bq.CS, (__2 => List<&1, List<&1, Char>>)>))}; apply_794(cs2_0, Bq.has_press(ps_1, 256)))), (_1303_2 => Tuple{cs2_0, [C.Bq.text("!CONNECT")]}), 0)))) : (@+cs2_0: Bq.CS -> (@+ps_1: List<&1, U32> -> (@+___2: U32 -> Sigma<&1, &1, Bq.CS, (__3 => List<&1, List<&1, Char>>)>)))}; apply_793(cs2_0, ps_1, C.Bq.word_or(Bq.has_press(ps_1, 257), Bq.hit(m_2, 380, 430, 200, 50))))), (_1305_3 => (+apply_795 = {(cs2_0 => \{Tuple: (fst_1 => (snd_2 => (+apply_796 = {(cs2_0 => \{Tuple: (fst_1 => (snd_2 => (+apply_797 = {(cs2_0 => (fst_1 => \{Tuple: (fst_2 => (snd_3 => (+apply_798 = {(cs2_0 => (fst_1 => \{Tuple: (fst_2 => (snd_3 => Tuple{Bq.cs_focus(cs2_0, ((fst_1 + 1 : U32) % 3 : U32)), Nil{}})); \{}})) : (@+cs2_0: Bq.CS -> (@+fst_1: U32 -> (@+___2: Sigma<&1, &1, List<&1, Char>, (__2 => List<&1, Char>)> -> Sigma<&1, &1, Bq.CS, (__3 => List<&1, List<&1, Char>>)>)))}; apply_798(cs2_0, fst_1, snd_3)))); \{}})) : (@+cs2_0: Bq.CS -> (@+fst_1: U32 -> (@+___2: Sigma<&1, &1, List<&1, Char>, (__2 => Sigma<&1, &1, List<&1, Char>, (__3 => List<&1, Char>)>)> -> Sigma<&1, &1, Bq.CS, (__3 => List<&1, List<&1, Char>>)>)))}; apply_797(cs2_0, fst_1, snd_2)))); \{}}) : (@+cs2_0: Bq.CS -> (@+___1: Sigma<&1, &1, U32, (__1 => Sigma<&1, &1, List<&1, Char>, (__2 => Sigma<&1, &1, List<&1, Char>, (__3 => List<&1, Char>)>)>)> -> Sigma<&1, &1, Bq.CS, (__2 => List<&1, List<&1, Char>>)>))}; apply_796(cs2_0, snd_2)))); \{}}) : (@+cs2_0: Bq.CS -> (@+___1: Sigma<&1, &1, U32, (__1 => Sigma<&1, &1, U32, (__2 => Sigma<&1, &1, List<&1, Char>, (__3 => Sigma<&1, &1, List<&1, Char>, (__4 => List<&1, Char>)>)>)>)> -> Sigma<&1, &1, Bq.CS, (__2 => List<&1, List<&1, Char>>)>))}; apply_795(cs2_0, Bq.cs_read(cs2_0)))), 0))))) : (@+cs2_0: Bq.CS -> (@+ps_1: List<&1, U32> -> (@+m_2: U32 -> (@+___3: U32 -> Sigma<&1, &1, Bq.CS, (__4 => List<&1, List<&1, Char>>)>))))}; apply_792(cs2_5, ps_1, m_3, Bq.has_press(ps_1, 258)))))))))

@unsafe
def Bq.cs_quit():
  \{Bq.CS.CS: (scene_0 => (quitting_1 => (form_2 => (net_3 => (acct_4 => (look_5 => (wv_6 => (ui_7 => Bq.CS.CS{scene_0, 1, form_2, net_3, acct_4, look_5, wv_6, ui_7})))))))); \{}}

@unsafe
def Bq.input_menu():
  (cs_0 => (ps_1 => (m_2 => (+apply_799 = {(cs_0 => (ps_1 => (m_2 => (word => C.Bq.word_case(Sigma<&1, &1, Bq.CS, (__4 => List<&1, List<&1, Char>>)>, word, 0, (unit => (+apply_800 = {(cs_0 => (ps_1 => (m_2 => (word => C.Bq.word_case(Sigma<&1, &1, Bq.CS, (__4 => List<&1, List<&1, Char>>)>, word, 0, (unit => (+apply_801 = {(cs_0 => (word => C.Bq.word_case(Sigma<&1, &1, Bq.CS, (__2 => List<&1, List<&1, Char>>)>, word, 0, (unit => Tuple{cs_0, Nil{}}), (_1269_1 => Tuple{Bq.cs_quit(cs_0), Nil{}}), 0))) : (@+cs_0: Bq.CS -> (@+___1: U32 -> Sigma<&1, &1, Bq.CS, (__2 => List<&1, List<&1, Char>>)>))}; apply_801(cs_0, C.Bq.word_or(Bq.has_press(ps_1, 81), Bq.hit(m_2, 380, 430, 200, 50))))), (_1271_3 => Tuple{Bq.cs_focus(Bq.cs_scene(cs_0, 4), 1), Nil{}}), 0))))) : (@+cs_0: Bq.CS -> (@+ps_1: List<&1, U32> -> (@+m_2: U32 -> (@+___3: U32 -> Sigma<&1, &1, Bq.CS, (__4 => List<&1, List<&1, Char>>)>))))}; apply_800(cs_0, ps_1, m_2, C.Bq.word_or(Bq.has_press(ps_1, 72), Bq.hit(m_2, 380, 360, 200, 50))))), (_1273_3 => Tuple{Bq.cs_scene(cs_0, 1), Nil{}}), 0))))) : (@+cs_0: Bq.CS -> (@+ps_1: List<&1, U32> -> (@+m_2: U32 -> (@+___3: U32 -> Sigma<&1, &1, Bq.CS, (__4 => List<&1, List<&1, Char>>)>))))}; apply_799(cs_0, ps_1, m_2, C.Bq.word_or(Bq.has_press(ps_1, 80), Bq.hit(m_2, 380, 290, 200, 50)))))))

@unsafe
def Bq.handle_input():
  (cs_0 => (ws_1 => (+ps_2 = Bq.presses(ws_1); (+cps_3 = Bq.typed(ws_1); (+held_4 = Bq.held_of(ws_1); (+m_5 = Bq.mouse_of(ws_1); (+apply_802 = {(cs_0 => (ps_1 => (cps_2 => (held_3 => (m_4 => \{Tuple: (fst_5 => (snd_6 => (+apply_803 = {(cs_0 => (ps_1 => (cps_2 => (held_3 => (m_4 => (fst_5 => \{Tuple: (fst_6 => (snd_7 => (+apply_804 = {(cs_0 => (ps_1 => (cps_2 => (held_3 => (m_4 => (fst_5 => \{Tuple: (fst_6 => (snd_7 => (+apply_805 = {(cs_0 => (ps_1 => (cps_2 => (held_3 => (m_4 => (fst_5 => \{Tuple: (fst_6 => (snd_7 => (+apply_806 = {(cs_0 => (ps_1 => (cps_2 => (held_3 => (m_4 => (fst_5 => (word => C.Bq.word_case(Sigma<&1, &1, Bq.CS, (__7 => List<&1, List<&1, Char>>)>, word, 0, (unit => (+apply_807 = {(cs_0 => (ps_1 => (cps_2 => (held_3 => (m_4 => (fst_5 => (word => C.Bq.word_case(Sigma<&1, &1, Bq.CS, (__7 => List<&1, List<&1, Char>>)>, word, 0, (unit => (+apply_808 = {(cs_0 => (ps_1 => (cps_2 => (held_3 => (m_4 => (fst_5 => (word => C.Bq.word_case(Sigma<&1, &1, Bq.CS, (__7 => List<&1, List<&1, Char>>)>, word, 0, (unit => (+apply_809 = {(cs_0 => (ps_1 => (cps_2 => (held_3 => (m_4 => (fst_5 => (word => C.Bq.word_case(Sigma<&1, &1, Bq.CS, (__7 => List<&1, List<&1, Char>>)>, word, 0, (unit => (+apply_810 = {(cs_0 => (ps_1 => (cps_2 => (held_3 => (m_4 => (word => C.Bq.word_case(Sigma<&1, &1, Bq.CS, (__6 => List<&1, List<&1, Char>>)>, word, 0, (unit => Bq.input_game(cs_0, ps_1, cps_2, held_3, m_4)), (_1468_5 => Bq.input_creator(cs_0, ps_1, m_4)), 0))))))) : (@+cs_0: Bq.CS -> (@+ps_1: List<&1, U32> -> (@+cps_2: List<&1, U32> -> (@+held_3: U32 -> (@+m_4: U32 -> (@+___5: U32 -> Sigma<&1, &1, Bq.CS, (__6 => List<&1, List<&1, Char>>)>))))))}; apply_810(cs_0, ps_1, cps_2, held_3, m_4, C.Bq.bit(U32.is_eq(fst_5, 2))))), (_1470_6 => Bq.input_dash(cs_0, ps_1, m_4)), 0)))))))) : (@+cs_0: Bq.CS -> (@+ps_1: List<&1, U32> -> (@+cps_2: List<&1, U32> -> (@+held_3: U32 -> (@+m_4: U32 -> (@+fst_5: U32 -> (@+___6: U32 -> Sigma<&1, &1, Bq.CS, (__7 => List<&1, List<&1, Char>>)>)))))))}; apply_809(cs_0, ps_1, cps_2, held_3, m_4, fst_5, C.Bq.bit(U32.is_eq(fst_5, 5))))), (_1472_6 => Bq.input_host(cs_0, ps_1, cps_2, m_4)), 0)))))))) : (@+cs_0: Bq.CS -> (@+ps_1: List<&1, U32> -> (@+cps_2: List<&1, U32> -> (@+held_3: U32 -> (@+m_4: U32 -> (@+fst_5: U32 -> (@+___6: U32 -> Sigma<&1, &1, Bq.CS, (__7 => List<&1, List<&1, Char>>)>)))))))}; apply_808(cs_0, ps_1, cps_2, held_3, m_4, fst_5, C.Bq.bit(U32.is_eq(fst_5, 4))))), (_1474_6 => Bq.input_join(cs_0, ps_1, cps_2, m_4)), 0)))))))) : (@+cs_0: Bq.CS -> (@+ps_1: List<&1, U32> -> (@+cps_2: List<&1, U32> -> (@+held_3: U32 -> (@+m_4: U32 -> (@+fst_5: U32 -> (@+___6: U32 -> Sigma<&1, &1, Bq.CS, (__7 => List<&1, List<&1, Char>>)>)))))))}; apply_807(cs_0, ps_1, cps_2, held_3, m_4, fst_5, C.Bq.bit(U32.is_eq(fst_5, 1))))), (_1476_6 => Bq.input_menu(cs_0, ps_1, m_4)), 0)))))))) : (@+cs_0: Bq.CS -> (@+ps_1: List<&1, U32> -> (@+cps_2: List<&1, U32> -> (@+held_3: U32 -> (@+m_4: U32 -> (@+fst_5: U32 -> (@+___6: U32 -> Sigma<&1, &1, Bq.CS, (__7 => List<&1, List<&1, Char>>)>)))))))}; apply_806(cs_0, ps_1, cps_2, held_3, m_4, fst_5, C.Bq.bit(U32.is_eq(fst_5, 0)))))); \{}})))))) : (@+cs_0: Bq.CS -> (@+ps_1: List<&1, U32> -> (@+cps_2: List<&1, U32> -> (@+held_3: U32 -> (@+m_4: U32 -> (@+fst_5: U32 -> (@+___6: Sigma<&1, &1, List<&1, Char>, (__6 => List<&1, Char>)> -> Sigma<&1, &1, Bq.CS, (__7 => List<&1, List<&1, Char>>)>)))))))}; apply_805(cs_0, ps_1, cps_2, held_3, m_4, fst_5, snd_7)))); \{}})))))) : (@+cs_0: Bq.CS -> (@+ps_1: List<&1, U32> -> (@+cps_2: List<&1, U32> -> (@+held_3: U32 -> (@+m_4: U32 -> (@+fst_5: U32 -> (@+___6: Sigma<&1, &1, List<&1, Char>, (__6 => Sigma<&1, &1, List<&1, Char>, (__7 => List<&1, Char>)>)> -> Sigma<&1, &1, Bq.CS, (__7 => List<&1, List<&1, Char>>)>)))))))}; apply_804(cs_0, ps_1, cps_2, held_3, m_4, fst_5, snd_7)))); \{}})))))) : (@+cs_0: Bq.CS -> (@+ps_1: List<&1, U32> -> (@+cps_2: List<&1, U32> -> (@+held_3: U32 -> (@+m_4: U32 -> (@+fst_5: U32 -> (@+___6: Sigma<&1, &1, U32, (__6 => Sigma<&1, &1, List<&1, Char>, (__7 => Sigma<&1, &1, List<&1, Char>, (__8 => List<&1, Char>)>)>)> -> Sigma<&1, &1, Bq.CS, (__7 => List<&1, List<&1, Char>>)>)))))))}; apply_803(cs_0, ps_1, cps_2, held_3, m_4, fst_5, snd_6)))); \{}}))))) : (@+cs_0: Bq.CS -> (@+ps_1: List<&1, U32> -> (@+cps_2: List<&1, U32> -> (@+held_3: U32 -> (@+m_4: U32 -> (@+___5: Sigma<&1, &1, U32, (__5 => Sigma<&1, &1, U32, (__6 => Sigma<&1, &1, List<&1, Char>, (__7 => Sigma<&1, &1, List<&1, Char>, (__8 => List<&1, Char>)>)>)>)> -> Sigma<&1, &1, Bq.CS, (__6 => List<&1, List<&1, Char>>)>))))))}; apply_802(cs_0, ps_2, cps_3, held_4, m_5, Bq.cs_read(cs_0)))))))))

@unsafe
def Bq.frame_loop():
  (word => C.Bq.word_case((@+cs_1: Bq.CS -> (@+a_2: Sprites.Bq.Assets -> (@+auro_3: U32 -> (@+rx_4: Chan<C.Bq.String> -> (@+lg_5: Chan<C.Bq.String> -> (@+ctl_6: Chan<U32> -> (@+stat_7: Chan<C.Bq.String> -> (@+last_8: U32 -> (@+auto_9: U32 -> (@+snds_10: C.Bq.Pair.Pair(U32, (__10 => U32)) -> IO(Unit))))))))))), word, 0, (unit => (cs_0 => (a_1 => (auro_2 => (rx_3 => (lg_4 => (ctl_5 => (stat_6 => (last_7 => (auto_8 => (snds_9 => C.Bq.IO.pure(Unit, Unit{})))))))))))), (f_0 => (cs_1 => (a_2 => (auro_3 => (rx_4 => (lg_5 => (ctl_6 => (stat_7 => (last_8 => (auto_9 => (snds_10 => (+fn_11 = (4294967295 - (1 + f_0 : U32) : U32); C.Bq.IO.bind(List<&1, U32>, Unit, Raylib.Bq.rl_input, (ws0_12 => (+ws_13 = Bq.auto_pick(auto_9, fn_11, ws0_12); (+apply_811 = {(rx_0 => (lg_1 => (ctl_2 => (stat_3 => (a_4 => (auro_5 => (snds_6 => (auto_7 => (fn_8 => (last_9 => (f_10 => \{Tuple: (fst_11 => (snd_12 => C.Bq.IO.bind(Bq.CS, Unit, Bq.do_actions(fst_11, snd_12, rx_0, lg_1, ctl_2, stat_3), (cs2_13 => C.Bq.IO.bind(U32, Unit, C.Bq.IO.now_ms, (now_14 => C.Bq.IO.bind(Bq.CS, Unit, Bq.drain_rx(cs2_13, rx_0, 96, now_14), (cs3_15 => C.Bq.IO.bind(Bq.CS, Unit, Bq.drain_hlog(cs3_15, lg_1, 16), (cs4a_16 => C.Bq.IO.bind(Bq.CS, Unit, Bq.drain_stat(cs4a_16, stat_3, 4), (cs4_17 => (+cs5_18 = Bq.cs_decay(cs4_17); C.Bq.IO.bind(Unit, Unit, Raylib.Bq.rl_frame(Bq.render(cs5_18, a_4, auro_5, now_14, snds_6)), (__19 => C.Bq.IO.bind(Unit, Unit, Bq.auto_shot(auto_7, fn_8), (__20 => C.Bq.IO.bind(Bool, Unit, Raylib.Bq.rl_should_close, (wclose_21 => (+autodone_22 = C.Bq.word_and(C.Bq.bit(U32.is_gt(auto_7, 0)), C.Bq.bit(U32.is_ge(fn_8, Bq.auto_end(auto_7)))); (+apply_812 = {(last_0 => (f_1 => (cs5_2 => (a_3 => (auro_4 => (rx_5 => (lg_6 => (ctl_7 => (stat_8 => (auto_9 => (snds_10 => \{False: C.Bq.IO.bind(U32, Unit, Bq.frame_pace(last_0), (t2_11 => Bq.frame_loop(f_1, cs5_2, a_3, auro_4, rx_5, lg_6, ctl_7, stat_8, t2_11, auto_9, snds_10))); \{True: Bq.shutdown(cs5_2, ctl_7); \{}}}))))))))))) : (@+last_0: U32 -> (@+f_1: U32 -> (@+cs5_2: Bq.CS -> (@+a_3: Sprites.Bq.Assets -> (@+auro_4: U32 -> (@+rx_5: Chan<C.Bq.String> -> (@+lg_6: Chan<C.Bq.String> -> (@+ctl_7: Chan<U32> -> (@+stat_8: Chan<C.Bq.String> -> (@+auto_9: U32 -> (@+snds_10: C.Bq.Pair.Pair(U32, (__10 => U32)) -> (@+___11: Bool -> IO(Unit)))))))))))))}; apply_812(last_9, f_10, cs5_18, a_4, auro_5, rx_0, lg_1, ctl_2, stat_3, auto_7, snds_6, Support.Bq.Bool.or(wclose_21, Support.Bq.Bool.from_u32(C.Bq.word_or(Bq.cs_quitting(cs5_18), autodone_22))))))))))))))))))))))))); \{}}))))))))))) : (@+rx_0: Chan<C.Bq.String> -> (@+lg_1: Chan<C.Bq.String> -> (@+ctl_2: Chan<U32> -> (@+stat_3: Chan<C.Bq.String> -> (@+a_4: Sprites.Bq.Assets -> (@+auro_5: U32 -> (@+snds_6: C.Bq.Pair.Pair(U32, (__6 => U32)) -> (@+auto_7: U32 -> (@+fn_8: U32 -> (@+last_9: U32 -> (@+f_10: U32 -> (@+___11: Sigma<&1, &1, Bq.CS, (__11 => List<&1, List<&1, Char>>)> -> IO(Unit)))))))))))))}; apply_811(rx_4, lg_5, ctl_6, stat_7, a_2, auro_3, snds_10, auto_9, fn_11, last_8, f_0, Bq.handle_input(cs_1, ws_13)))))))))))))))))), 1))

@unsafe
def Bq.client_start():
  C.Bq.IO.bind(Unit, Unit, Raylib.Bq.rl_init(C.Bq.text("BendQuest"), 960, 640), (__0 => C.Bq.IO.bind(Sprites.Bq.Assets, Unit, Sprites.Bq.load_assets, (a_1 => C.Bq.IO.bind(U32, Unit, Raylib.Bq.rl_tex_load(128, 128, Bq.aurora_bytes), (auro_2 => C.Bq.IO.bind(Bool, Unit, Raylib.Bq.rl_font(C.Bq.text("font.ttf")), (fontok_3 => C.Bq.IO.bind(Chan<C.Bq.String>, Unit, C.Bq.Chan.new(C.Bq.String, 1024), (rx_4 => C.Bq.IO.bind(Chan<C.Bq.String>, Unit, C.Bq.Chan.new(C.Bq.String, 256), (lg_5 => C.Bq.IO.bind(Chan<U32>, Unit, C.Bq.Chan.new(U32, 8), (ctl_6 => C.Bq.IO.bind(Chan<C.Bq.String>, Unit, C.Bq.Chan.new(C.Bq.String, 64), (stat_7 => C.Bq.IO.bind(U32, Unit, Raylib.Bq.rl_sound_load(Bq.snd_hit_bytes), (s_hit_8 => C.Bq.IO.bind(U32, Unit, Raylib.Bq.rl_sound_load(Bq.snd_lvl_bytes), (s_lvl_9 => C.Bq.IO.bind(U32, Unit, Bq.auto_mode, (am_10 => C.Bq.IO.bind(Bq.CS, Unit, Bq.name_override(Bq.cs0), (cs1_11 => C.Bq.IO.bind(U32, Unit, C.Bq.IO.now_ms, (t_12 => Bq.frame_loop(Support.Bq.U32.MAX_VALUE, cs1_11, a_1, auro_2, rx_4, lg_5, ctl_6, stat_7, t_12, am_10, Tuple{s_hit_8, s_lvl_9})))))))))))))))))))))))))))
