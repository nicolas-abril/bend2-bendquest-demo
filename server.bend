# Bendquest server. Current Bend syntax; see README.md for the port notes.
import Base
import ./world_clock.bend as Clock
import ./connection.bend as Net
import ./channel_restart.bend as ChannelRestart
import ./rebinding.bend as Rebinding
import ./rebuild.bend as Rebuild
import ./sessions.bend as Sess
import ./allocation.bend as Alloc
import ./terrain.bend as Terrain
import ./simulation.bend as S
import ./players.bend as P
import ./compat.bend as C
import ./proto.bend as Proto
import ./world.bend as World
import ./support.bend as Support
import ./data.bend as Data
import ./game.bend as Game

type Bq.Prof is Type:
  Bq.Prof.Prof{name_0: C.Bq.String, coins_1: U32, hats_2: U32, capes_3: U32}

type Bq.FP is Type:
  Bq.FP.FP{name_0: C.Bq.String, lv_1: U32, score_2: U32, skin_3: U32, hairs_4: U32, hairc_5: U32, shirt_6: U32, hat_7: U32, cape_8: U32, wea_9: U32, arm_10: U32, hel_11: U32, chm_12: U32}

type Bq.Run is Type:
  Bq.Run.Run{no_0: U32, dur_1: U32, fps_2: List<&1, Bq.FP>}

type Bq.Db is Type:
  Bq.Db.Db{wno_0: U32, profs_1: List<&1, Bq.Prof>, runs_2: List<&1, Bq.Run>}

law Bq.DB_PATH:
  C.Bq.String

law Bq.nth:
  (@+ns_0: List<&1, U32> -> (@+i_1: U32 -> U32))

law Bq.db_line:
  (@+db_0: Bq.Db -> (@+m_1: Proto.Bq.Msg -> Bq.Db))

law Bq.db_lines:
  (@+db_0: Bq.Db -> (@+ls_1: List<&1, C.Bq.String> -> Bq.Db))

law Bq.db_dec:
  (@+s_0: C.Bq.String -> Bq.Db)

law Bq.db_load:
  IO(Bq.Db)

law Bq.chan_push:
  (@+out_0: Chan<C.Bq.String> -> (@+line_1: C.Bq.String -> IO(Unit)))

type Bq.InM is Type:
  Bq.InM.InJoin{sock_0: C.Bq.TCP}
  Bq.InM.InLine{cid_0: U32, line_1: C.Bq.String}
  Bq.InM.InGone{cid_0: U32}
  Bq.InM.InCtl{code_0: U32}

law Bq.acceptor:
  (@+fuel_0: U32 -> (@+srv_1: C.Bq.TCP -> (@+inbox_2: Chan<Bq.InM> -> IO(Unit))))

law Bq.ctl_pump:
  (@+fuel_0: U32 -> (@+ctl_1: Chan<U32> -> (@+inbox_2: Chan<Bq.InM> -> IO(Unit))))

def Bq.Conn() -> Type: Net.Connection.Record

law Bq.phase_of_w:
  (@+w_0: World.Bq.World -> U32)

law Bq.writer_drain:
  (@+fuel_0: U32 -> (@+sock_1: C.Bq.TCP -> (@+out_2: Chan<C.Bq.String> -> IO(Unit))))

law Bq.writer:
  (@+fuel_0: U32 -> (@+sock_1: C.Bq.TCP -> (@+out_2: Chan<C.Bq.String> -> IO(Unit))))

law Bq.send_lines:
  (@+cid_0: U32 -> (@+inbox_1: Chan<Bq.InM> -> (@+ls_2: List<&1, C.Bq.String> -> IO(Unit))))

law Bq.reader:
  (@+fuel_0: U32 -> (@+cid_1: U32 -> (@+sock_2: C.Bq.TCP -> (@+inbox_3: Chan<Bq.InM> -> (@+buf_4: C.Bq.String -> IO(Unit))))))

law Bq.on_join:
  (@+cs_0: List<&1, Bq.Conn> -> (@+ncid_1: U32 -> (@+sock_2: C.Bq.TCP -> (@+inbox_3: Chan<Bq.InM> -> (@+lg_4: Chan<C.Bq.String> -> IO(C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__5 => U32))))))))

law Bq.send_all:
  (@+cs_0: List<&1, Bq.Conn> -> (@+line_1: C.Bq.String -> IO(Unit)))

law Bq.send_to:
  (@+cs_0: List<&1, Bq.Conn> -> (@+cid_1: U32 -> (@+line_2: C.Bq.String -> IO(Unit))))

law Bq.zone_of_cid:
  (@+zs_0: List<&1, C.Bq.Pair.Pair(U32, (__0 => U32))> -> (@+cid_1: U32 -> U32))

law Bq.send_zone:
  (@+cs_0: List<&1, Bq.Conn> -> (@+zs_1: List<&1, C.Bq.Pair.Pair(U32, (__1 => U32))> -> (@+z_2: U32 -> (@+line_3: C.Bq.String -> IO(Unit)))))

law Bq.route_outs:
  (@+outs_0: List<&1, World.Bq.OutL> -> (@+cs_1: List<&1, Bq.Conn> -> (@+zs_2: List<&1, C.Bq.Pair.Pair(U32, (__2 => U32))> -> (@+lg_3: Chan<C.Bq.String> -> IO(Unit)))))

law Bq.cid_zones:
  (@+ps_0: List<&2, World.Bq.Plr> -> List<&1, C.Bq.Pair.Pair(U32, (__1 => U32))>)

law Bq.plrs_of_w:
  (@+w_0: World.Bq.World -> List<&2, World.Bq.Plr>)

law Bq.game_cmd:
  (@+w_0: World.Bq.World -> (@+pid_1: U32 -> (@+m_2: Proto.Bq.Msg -> C.Bq.Pair.Pair(World.Bq.World, (__3 => List<&1, World.Bq.OutL>)))))

law Bq.plr_zone_of:
  (@+ps_0: List<&2, World.Bq.Plr> -> (@+pid_1: U32 -> U32))

law Bq.take_conn:
  (@+cid_0: U32 -> (@+cs_1: List<&1, Bq.Conn> -> C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__2 => Support.Bq.Maybe(Bq.Conn)))))

law Bq.send_many:
  (@+cs_0: List<&1, Bq.Conn> -> (@+cid_1: U32 -> (@+ls_2: List<&1, C.Bq.String> -> IO(Unit))))

law Bq.fp_enc:
  (@+f_0: Bq.FP -> C.Bq.String)

law Bq.fame_fp_lines:
  (@+fs_0: List<&1, Bq.FP> -> List<&1, C.Bq.String>)

law Bq.fame_run_lines:
  (@+rs_0: List<&1, Bq.Run> -> List<&1, C.Bq.String>)

law Bq.fame_lines:
  (@+db_0: Bq.Db -> List<&1, C.Bq.String>)

law Bq.maps_of_w:
  (@+w_0: World.Bq.World -> List<&2,List<&2,U32>>)

law Bq.plr_name_lines:
  (@+ps_0: List<&2, World.Bq.Plr> -> List<&1, C.Bq.String>)

law Bq.own_ok:
  (@+mask_0: U32 -> (@+id1_1: U32 -> U32))

law Bq.prof_get:
  (@+ps_0: List<&1, Bq.Prof> -> (@+name_1: C.Bq.String -> Bq.Prof))

law Bq.db_prof:
  (@+db_0: Bq.Db -> (@+name_1: C.Bq.String -> Bq.Prof))

law Bq.on_create:
  (@+w_0: World.Bq.World -> (@+cs_1: List<&1, Bq.Conn> -> (@+db_2: Bq.Db -> (@+cid_3: U32 -> (@+ns_4: List<&1, U32> -> (@+lg_5: Chan<C.Bq.String> -> IO(C.Bq.Pair.Pair(World.Bq.World, (__6 => List<&1, Bq.Conn>)))))))))

law Bq.shop_price:
  (@+t_0: U32 -> (@+id_1: U32 -> U32))

law Bq.shop_owned:
  (@+t_0: U32 -> (@+id_1: U32 -> (@+hats_2: U32 -> (@+capes_3: U32 -> U32))))

law Bq.prof_put:
  (@+ps_0: List<&1, Bq.Prof> -> (@+np_1: Bq.Prof -> List<&1, Bq.Prof>))

law Bq.db_put_prof:
  (@+db_0: Bq.Db -> (@+p_1: Bq.Prof -> Bq.Db))

law Bq.shop_apply:
  (@+t_0: U32 -> (@+id_1: U32 -> (@+name_2: C.Bq.String -> (@+coins_3: U32 -> (@+hats_4: U32 -> (@+capes_5: U32 -> Bq.Prof))))))

law Bq.prof_enc:
  (@+p_0: Bq.Prof -> C.Bq.String)

law Bq.profs_enc:
  (@+ps_0: List<&1, Bq.Prof> -> C.Bq.String)

law Bq.fps_enc:
  (@+fs_0: List<&1, Bq.FP> -> C.Bq.String)

law Bq.run_enc:
  (@+r_0: Bq.Run -> C.Bq.String)

law Bq.runs_enc:
  (@+rs_0: List<&1, Bq.Run> -> C.Bq.String)

law Bq.db_enc:
  (@+db_0: Bq.Db -> C.Bq.String)

law Bq.db_save:
  (@+db_0: Bq.Db -> IO(Unit))

law Bq.welcome_line:
  (@+db_0: Bq.Db -> (@+name_1: C.Bq.String -> (@+wno_2: U32 -> (@+phase_3: U32 -> C.Bq.String))))

law Bq.on_shop:
  (@+cs_0: List<&1, Bq.Conn> -> (@+db_1: Bq.Db -> (@+cid_2: U32 -> (@+t_3: U32 -> (@+id_4: U32 -> IO(C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__5 => Bq.Db))))))))

law Bq.valid_name:
  (@+n_0: C.Bq.String -> Bool)

law Bq.name_online:
  (@+cs_0: List<&1, Bq.Conn> -> (@+name_1: C.Bq.String -> Bool))

law Bq.on_hello:
  (@+w_0: World.Bq.World -> (@+cs_1: List<&1, Bq.Conn> -> (@+db_2: Bq.Db -> (@+cid_3: U32 -> (@+name_4: C.Bq.String -> (@+lg_5: Chan<C.Bq.String> -> IO(List<&1, Bq.Conn>)))))))

law Bq.on_line:
  (@+w_0: World.Bq.World -> (@+cs_1: List<&1, Bq.Conn> -> (@+db_2: Bq.Db -> (@+cid_3: U32 -> (@+line_4: C.Bq.String -> (@+lg_5: Chan<C.Bq.String> -> IO(C.Bq.Pair.Pair(World.Bq.World, (__6 => C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__7 => Bq.Db)))))))))))

law Bq.on_gone:
  (@+w_0: World.Bq.World -> (@+cs_1: List<&1, Bq.Conn> -> (@+cid_2: U32 -> (@+lg_3: Chan<C.Bq.String> -> IO(C.Bq.Pair.Pair(World.Bq.World, (__4 => List<&1, Bq.Conn>)))))))

law Bq.drain:
  (@+k_0: U32 -> (@+w_1: World.Bq.World -> (@+cs_2: List<&1, Bq.Conn> -> (@+ncid_3: U32 -> (@+db_4: Bq.Db -> (@+inbox_5: Chan<Bq.InM> -> (@+lg_6: Chan<C.Bq.String> -> (@+flag_7: U32 -> IO(C.Bq.Pair.Pair(World.Bq.World, (__8 => C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__9 => C.Bq.Pair.Pair(U32, (__10 => C.Bq.Pair.Pair(Bq.Db, (__11 => U32)))))))))))))))))

law Bq.set_now:
  (@+w_0: World.Bq.World -> (@+n_1: U32 -> World.Bq.World))

law Bq.status_names:
  (@+ps_0: List<&2, World.Bq.Plr> -> C.Bq.String)

law Bq.status_of:
  (@+w_0: World.Bq.World -> C.Bq.String)

law Bq.maybe_status:
  (@+w_0: World.Bq.World -> (@+stat_1: Chan<C.Bq.String> -> IO(Unit)))

law Bq.award_coins:
  (@+db_0: Bq.Db -> (@+rs_1: List<&1, C.Bq.Pair.Pair(U32, (__1 => C.Bq.String))> -> (@+rank_2: U32 -> Bq.Db)))

law Bq.fp_of_plr:
  (@+p_0: World.Bq.Plr -> Bq.FP)

law Bq.fps_of:
  (@+ps_0: List<&2, World.Bq.Plr> -> List<&1, Bq.FP>)

law Bq.send_all_lines:
  (@+cs_0: List<&1, Bq.Conn> -> (@+ls_1: List<&1, C.Bq.String> -> IO(Unit)))

law Bq.run_end:
  (@+w_0: World.Bq.World -> (@+cs_1: List<&1, Bq.Conn> -> (@+db_2: Bq.Db -> (@+lg_3: Chan<C.Bq.String> -> IO(Bq.Db)))))

law Bq.maybe_run_end:
  (@+oldphase_0: U32 -> (@+w_1: World.Bq.World -> (@+cs_2: List<&1, Bq.Conn> -> (@+db_3: Bq.Db -> (@+lg_4: Chan<C.Bq.String> -> IO(Bq.Db))))))

law Bq.readd_plrs:
  (@+w_0: World.Bq.World -> (@+ps_1: List<&2, World.Bq.Plr> -> World.Bq.World))

law Bq.pid_of_cid:
  (@+ps_0: List<&2, World.Bq.Plr> -> (@+cid_1: U32 -> (@+d_2: U32 -> U32)))

law Bq.rebind_conns:
  (@+cs_0: List<&1, Bq.Conn> -> (@+ps_1: List<&2, World.Bq.Plr> -> List<&1, Bq.Conn>))

law Bq.restart_world:
  (@+w_0: World.Bq.World -> (@+cs_1: List<&1, Bq.Conn> -> (@+db_2: Bq.Db -> (@+lg_3: Chan<C.Bq.String> -> IO(C.Bq.Pair.Pair(World.Bq.World, (__4 => C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__5 => Bq.Db)))))))))

law Bq.fame_t_of_w:
  (@+w_0: World.Bq.World -> U32)

law Bq.loop_stop:
  (@+db1_0: Bq.Db -> (@+lg_1: Chan<C.Bq.String> -> IO(Unit)))

law Bq.game_loop:
  (@+fuel_0: U32 -> (@+w_1: World.Bq.World -> (@+cs_2: List<&1, Bq.Conn> -> (@+ncid_3: U32 -> (@+db_4: Bq.Db -> (@+inbox_5: Chan<Bq.InM> -> (@+lg_6: Chan<C.Bq.String> -> (@+stat_7: Chan<C.Bq.String> -> IO(Unit)))))))))

law Bq.server_start:
  (@+port_0: U32 -> (@+lg_1: Chan<C.Bq.String> -> (@+ctl_2: Chan<U32> -> (@+stat_3: Chan<C.Bq.String> -> IO(Unit)))))

@unsafe
def Bq.DB_PATH():
  C.Bq.text("bendquest_db.txt")

@unsafe
def Bq.nth():
  (ns_0 => (i_1 => World.Bq.lget(ns_0, i_1, 0)))

@unsafe
def Bq.db_line():
  \{Bq.Db.Db: (wno_0 => (profs_1 => (runs_2 => \{Proto.Bq.Msg.Msg: (tag_3 => (ns_4 => (text_5 => (+apply_40 = {(wno_0 => (profs_1 => (runs_2 => (text_3 => (ns_4 => (tag_5 => \{False: (+apply_41 = {(wno_0 => (profs_1 => (runs_2 => (text_3 => (ns_4 => (tag_5 => \{False: (+apply_42 = {(wno_0 => (profs_1 => (runs_2 => (text_3 => (ns_4 => (tag_5 => \{False: (+apply_43 = {(wno_0 => (profs_1 => (runs_2 => (text_3 => (ns_4 => \{False: Bq.Db.Db{wno_0, profs_1, runs_2}; \{True: (+f_5 = {Bq.FP.FP{text_3, Bq.nth(ns_4, 0), Bq.nth(ns_4, 1), Bq.nth(ns_4, 2), Bq.nth(ns_4, 3), Bq.nth(ns_4, 4), Bq.nth(ns_4, 5), Bq.nth(ns_4, 6), Bq.nth(ns_4, 7), Bq.nth(ns_4, 8), Bq.nth(ns_4, 9), Bq.nth(ns_4, 10), Bq.nth(ns_4, 11)} : Bq.FP}; (+apply_44 = {(wno_0 => (profs_1 => \{Nil: (f_2 => Bq.Db.Db{wno_0, profs_1, Nil{}}); \{Con: (head_2 => (tail_3 => (+apply_45 = {(wno_0 => (profs_1 => \{Bq.Run.Run: (no_2 => (dur_3 => (fps_4 => (rest_5 => (f_6 => Bq.Db.Db{wno_0, profs_1, Con{Bq.Run.Run{no_2, dur_3, Con{f_6, fps_4}}, rest_5}}))))); \{}})) : (@+wno_0: U32 -> (@+profs_1: List<&1, Bq.Prof> -> (@+___2: Bq.Run -> (@+__3: List<&1, Bq.Run> -> (@+__4: Bq.FP -> Bq.Db)))))}; apply_45(wno_0, profs_1, head_2, tail_3)))); \{}}})) : (@+wno_0: U32 -> (@+profs_1: List<&1, Bq.Prof> -> (@+___2: List<&1, Bq.Run> -> (@+__3: Bq.FP -> Bq.Db))))}; apply_44(wno_0, profs_1, runs_2, f_5))); \{}}}))))) : (@+wno_0: U32 -> (@+profs_1: List<&1, Bq.Prof> -> (@+runs_2: List<&1, Bq.Run> -> (@+text_3: C.Bq.String -> (@+ns_4: List<&1, U32> -> (@+___5: Bool -> Bq.Db))))))}; apply_43(wno_0, profs_1, runs_2, text_3, ns_4, Proto.Bq.is(tag_5, C.Bq.text("FP")))); \{True: Bq.Db.Db{wno_0, profs_1, Con{Bq.Run.Run{Bq.nth(ns_4, 0), Bq.nth(ns_4, 1), Nil{}}, runs_2}}; \{}}})))))) : (@+wno_0: U32 -> (@+profs_1: List<&1, Bq.Prof> -> (@+runs_2: List<&1, Bq.Run> -> (@+text_3: C.Bq.String -> (@+ns_4: List<&1, U32> -> (@+tag_5: C.Bq.String -> (@+___6: Bool -> Bq.Db)))))))}; apply_42(wno_0, profs_1, runs_2, text_3, ns_4, tag_5, Proto.Bq.is(tag_5, C.Bq.text("RUN")))); \{True: Bq.Db.Db{wno_0, Con{Bq.Prof.Prof{text_3, Bq.nth(ns_4, 0), Bq.nth(ns_4, 1), Bq.nth(ns_4, 2)}, profs_1}, runs_2}; \{}}})))))) : (@+wno_0: U32 -> (@+profs_1: List<&1, Bq.Prof> -> (@+runs_2: List<&1, Bq.Run> -> (@+text_3: C.Bq.String -> (@+ns_4: List<&1, U32> -> (@+tag_5: C.Bq.String -> (@+___6: Bool -> Bq.Db)))))))}; apply_41(wno_0, profs_1, runs_2, text_3, ns_4, tag_5, Proto.Bq.is(tag_5, C.Bq.text("PROF")))); \{True: Bq.Db.Db{Bq.nth(ns_4, 0), profs_1, runs_2}; \{}}})))))) : (@+wno_0: U32 -> (@+profs_1: List<&1, Bq.Prof> -> (@+runs_2: List<&1, Bq.Run> -> (@+text_3: C.Bq.String -> (@+ns_4: List<&1, U32> -> (@+tag_5: C.Bq.String -> (@+___6: Bool -> Bq.Db)))))))}; apply_40(wno_0, profs_1, runs_2, text_5, ns_4, tag_3, Proto.Bq.is(tag_3, C.Bq.text("DB"))))))); \{}}))); \{}}

@unsafe
def Bq.db_lines():
  (db_0 => \{Nil: db_0; \{Con: (l_1 => (rest_2 => Bq.db_lines(Bq.db_line(db_0, Proto.Bq.wire_dec(l_1)), rest_2))); \{}}})

@unsafe
def Bq.db_dec():
  (s_0 => (+apply_56 = {\{Tuple: (fst_0 => (snd_1 => Bq.db_lines(Bq.Db.Db{1, Nil{}, Nil{}}, snd_1))); \{}} : (@+___0: Sigma<&1, &1, List<&1, Char>, (__0 => List<&1, List<&1, Char>>)> -> Bq.Db)}; apply_56(Proto.Bq.feed(Nil{}, s_0))))

@unsafe
def Bq.db_load():
  C.Bq.IO.bind(Result<&1, &1, C.Bq.Pair.Pair(U32, (__0 => C.Bq.String)), C.Bq.String>, Bq.Db, C.Bq.IO.read_text(Bq.DB_PATH), \{Done: (s_0 => C.Bq.IO.pure(Bq.Db, Bq.db_dec(s_0))); \{Fail: (e_0 => C.Bq.IO.pure(Bq.Db, Bq.Db.Db{1, Nil{}, Nil{}})); \{}}})

@unsafe
def Bq.chan_push():
  (out_0 => (line_1 => C.Bq.IO.bind(Result<&1, &1, C.Bq.Pair.Pair(U32, (__2 => C.Bq.String)), Result<&1, &1, C.Bq.Pair.Pair(U32, (__2 => C.Bq.String)), Unit>>, Unit, C.Bq.IO.timeout(Result<&1, &1, C.Bq.Pair.Pair(U32, (__2 => C.Bq.String)), Unit>, 50, C.Bq.Chan.send(C.Bq.String, out_0, line_1)), (r_2 => C.Bq.IO.pure(Unit, Unit{})))))

@unsafe
def Bq.acceptor():
  (word => C.Bq.word_case((@+srv_1: C.Bq.TCP -> (@+inbox_2: Chan<Bq.InM> -> IO(Unit))), word, 0, (unit => (srv_0 => (inbox_1 => C.Bq.IO.pure(Unit, Unit{})))), (f_0 => (srv_1 => (inbox_2 => C.Bq.IO.bind(Result<&1, &1, C.Bq.Pair.Pair(U32, (__3 => C.Bq.String)), C.Bq.TCP>, Unit, C.Bq.TCP.accept(srv_1), \{Done: (sock_3 => C.Bq.IO.bind(Result<&1, &1, C.Bq.Pair.Pair(U32, (__4 => C.Bq.String)), Unit>, Unit, C.Bq.Chan.send(Bq.InM, inbox_2, Bq.InM.InJoin{sock_3}), (__4 => Bq.acceptor(f_0, srv_1, inbox_2)))); \{Fail: (e_3 => Bq.acceptor(f_0, srv_1, inbox_2)); \{}}})))), 1))

@unsafe
def Bq.ctl_pump():
  (word => C.Bq.word_case((@+ctl_1: Chan<U32> -> (@+inbox_2: Chan<Bq.InM> -> IO(Unit))), word, 0, (unit => (ctl_0 => (inbox_1 => C.Bq.IO.pure(Unit, Unit{})))), (f_0 => (ctl_1 => (inbox_2 => C.Bq.IO.bind(Result<&1, &1, C.Bq.Pair.Pair(U32, (__3 => C.Bq.String)), U32>, Unit, C.Bq.Chan.recv(U32, ctl_1), \{Done: (code_3 => C.Bq.IO.bind(Result<&1, &1, C.Bq.Pair.Pair(U32, (__4 => C.Bq.String)), Unit>, Unit, C.Bq.Chan.send(Bq.InM, inbox_2, Bq.InM.InCtl{code_3}), (__4 => Bq.ctl_pump(f_0, ctl_1, inbox_2)))); \{Fail: (e_3 => C.Bq.IO.pure(Unit, Unit{})); \{}}})))), 1))

@unsafe
def Bq.phase_of_w():
  \{Terrain.Terrain.World: (wm_0 => (plrs_1 => (mobs_2 => (maps_3 => World.Bq.wm_phase(wm_0))))); \{}}

@unsafe
def Bq.writer_drain():
  (word => C.Bq.word_case((@+sock_1: C.Bq.TCP -> (@+out_2: Chan<C.Bq.String> -> IO(Unit))), word, 0, (unit => (sock_0 => (out_1 => C.Bq.TCP.close(sock_0)))), (f_0 => (sock_1 => (out_2 => C.Bq.IO.bind(Result<&1, &1, C.Bq.Pair.Pair(U32, (__3 => C.Bq.String)), C.Bq.String>, Unit, C.Bq.Chan.recv(C.Bq.String, out_2), \{Done: (line_3 => Bq.writer_drain(f_0, sock_1, out_2)); \{Fail: (e_3 => C.Bq.TCP.close(sock_1)); \{}}})))), 1))

@unsafe
def Bq.writer():
  (word => C.Bq.word_case((@+sock_1: C.Bq.TCP -> (@+out_2: Chan<C.Bq.String> -> IO(Unit))), word, 0, (unit => (sock_0 => (out_1 => C.Bq.TCP.close(sock_0)))), (f_0 => (sock_1 => (out_2 => C.Bq.IO.bind(Result<&1, &1, C.Bq.Pair.Pair(U32, (__3 => C.Bq.String)), C.Bq.String>, Unit, C.Bq.Chan.recv(C.Bq.String, out_2), \{Done: (line_3 => C.Bq.IO.bind(Result<&1, &1, C.Bq.Pair.Pair(U32, (__4 => C.Bq.String)), Unit>, Unit, C.Bq.TCP.send(sock_1, C.Bq.Bytes.from_string(line_3)), \{Done: (u_4 => Bq.writer(f_0, sock_1, out_2)); \{Fail: (e_4 => Bq.writer_drain(f_0, sock_1, out_2)); \{}}})); \{Fail: (e_3 => C.Bq.TCP.close(sock_1)); \{}}})))), 1))

@unsafe
def Bq.send_lines():
  (cid_0 => (inbox_1 => \{Nil: C.Bq.IO.pure(Unit, Unit{}); \{Con: (l_2 => (rest_3 => C.Bq.IO.bind(Result<&1, &1, C.Bq.Pair.Pair(U32, (__4 => C.Bq.String)), Unit>, Unit, C.Bq.Chan.send(Bq.InM, inbox_1, Bq.InM.InLine{cid_0, l_2}), (__4 => Bq.send_lines(cid_0, inbox_1, rest_3))))); \{}}}))

@unsafe
def Bq.reader():
  (word => C.Bq.word_case((@+cid_1: U32 -> (@+sock_2: C.Bq.TCP -> (@+inbox_3: Chan<Bq.InM> -> (@+buf_4: C.Bq.String -> IO(Unit))))), word, 0, (unit => (cid_0 => (sock_1 => (inbox_2 => (buf_3 => C.Bq.IO.pure(Unit, Unit{})))))), (f_0 => (cid_1 => (sock_2 => (inbox_3 => (buf_4 => C.Bq.IO.bind(Result<&1, &1, C.Bq.Pair.Pair(U32, (__5 => C.Bq.String)), C.Bq.Bytes>, Unit, C.Bq.TCP.recv(sock_2, 4096), \{Done: \{C.Bq.Bytes.Bytes: (blen_5 => (bdata_6 => (+apply_57 = {(cid_0 => (inbox_1 => (f_2 => (sock_3 => (buf_4 => (blen_5 => (bdata_6 => (word => C.Bq.word_case(IO(Unit), word, 0, (unit => (+apply_58 = {(cid_0 => (inbox_1 => (f_2 => (sock_3 => \{Tuple: (fst_4 => (snd_5 => C.Bq.IO.bind(Unit, Unit, Bq.send_lines(cid_0, inbox_1, snd_5), (__6 => Bq.reader(f_2, cid_0, sock_3, inbox_1, fst_4))))); \{}})))) : (@+cid_0: U32 -> (@+inbox_1: Chan<Bq.InM> -> (@+f_2: U32 -> (@+sock_3: C.Bq.TCP -> (@+___4: Sigma<&1, &1, List<&1, Char>, (__4 => List<&1, List<&1, Char>>)> -> IO(Unit))))))}; apply_58(cid_0, inbox_1, f_2, sock_3, Proto.Bq.feed(buf_4, C.Bq.Bytes.to_string(C.Bq.Bytes.Bytes{blen_5, bdata_6}))))), (_292_7 => C.Bq.IO.bind(Result<&1, &1, C.Bq.Pair.Pair(U32, (__8 => C.Bq.String)), Unit>, Unit, C.Bq.Chan.send(Bq.InM, inbox_1, Bq.InM.InGone{cid_0}), (__8 => C.Bq.IO.pure(Unit, Unit{})))), 0))))))))) : (@+cid_0: U32 -> (@+inbox_1: Chan<Bq.InM> -> (@+f_2: U32 -> (@+sock_3: C.Bq.TCP -> (@+buf_4: C.Bq.String -> (@+blen_5: U32 -> (@+bdata_6: List<&1, U32> -> (@+___7: U32 -> IO(Unit)))))))))}; apply_57(cid_1, inbox_3, f_0, sock_2, buf_4, blen_5, bdata_6, C.Bq.bit(U32.is_eq(blen_5, 0)))))); \{}}; \{Fail: (e_5 => C.Bq.IO.bind(Result<&1, &1, C.Bq.Pair.Pair(U32, (__6 => C.Bq.String)), Unit>, Unit, C.Bq.Chan.send(Bq.InM, inbox_3, Bq.InM.InGone{cid_1}), (__6 => C.Bq.IO.pure(Unit, Unit{})))); \{}}})))))), 1))

def Bq.session_descriptor(connection: Bq.Conn) -> Sess.Sessions.State: Net.Connection.descriptor(connection)

def Bq.session_descriptors(connections: List<&1,Bq.Conn>) -> List<&2,Sess.Sessions.State>: Net.Connection.descriptors(connections)

def Bq.connection_from_descriptor(state: Sess.Sessions.State,out: Chan<C.Bq.String>) -> Bq.Conn: Net.Connection.from_descriptor(state,out)

@unsafe
def Bq.JoinResult() -> Type: List<&1,Bq.Conn> & U32

@unsafe
def Bq.connection_ids(connections: List<&1,Bq.Conn>) -> Alloc.Allocation.Ids:
  match connections:
    case Nil{}: Nil{}
    case Con{head,rest}:
      match head:
        case Net.Connection.Record{cid,state,pid,out,name}: Con{cid,Bq.connection_ids(rest)}

@unsafe
def Bq.on_join_allocated(+connections: List<&1,Bq.Conn>,+cid: U32,+next: U32,+sock: C.Bq.TCP,+inbox: Chan<Bq.InM>,+log: Chan<C.Bq.String>) -> IO(Bq.JoinResult):
  C.Bq.IO.bind(Chan<C.Bq.String>,Bq.JoinResult,C.Bq.Chan.new(C.Bq.String,256),(out =>
    C.Bq.IO.bind(Unit,Bq.JoinResult,C.Bq.IO.spawn(Bq.writer(Support.Bq.U32.MAX_VALUE,sock,out)),(_ =>
      C.Bq.IO.bind(Unit,Bq.JoinResult,C.Bq.IO.spawn(Bq.reader(Support.Bq.U32.MAX_VALUE,cid,sock,inbox,Nil{})),(_ =>
        C.Bq.IO.bind(Unit,Bq.JoinResult,Bq.chan_push(log,Support.Bq.List.concat(Char,C.Bq.text("connection #"),Support.Bq.U32.show(cid))),(_ =>
          C.Bq.IO.pure(Bq.JoinResult,Tuple{Con{Bq.connection_from_descriptor(Sess.Sessions.fresh(cid),out),connections},next})))))))))


@unsafe
def Bq.on_join_choice(result: Maybe<&2,Alloc.Allocation.Choice>,+connections: List<&1,Bq.Conn>,+hint: U32,sock: C.Bq.TCP,inbox: Chan<Bq.InM>,log: Chan<C.Bq.String>) -> IO(Bq.JoinResult):
  match result:
    case None{}: C.Bq.IO.bind(Unit,Bq.JoinResult,C.Bq.TCP.close(sock),(_ => C.Bq.IO.pure(Bq.JoinResult,Tuple{connections,hint})))
    case Some{choice}:
      match choice:
        case Alloc.Allocation.Choice{cid,next}: Bq.on_join_allocated(connections,cid,next,sock,inbox,log)

@unsafe
def Bq.on_join(connections,hint,sock,inbox,log):
  Bq.on_join_choice(Alloc.Allocation.find(Bq.connection_ids(connections),hint),connections,hint,sock,inbox,log)

@unsafe
def Bq.send_all():
  \{Nil: (line_0 => C.Bq.IO.pure(Unit, Unit{})); \{Con: \{Net.Connection.Record: (cid_0 => (st_1 => (pid_2 => (out_3 => (name_4 => (rest_5 => (line_6 => C.Bq.IO.bind(Unit, Unit, Bq.chan_push(out_3, line_6), (__7 => Bq.send_all(rest_5, line_6)))))))))); \{}}; \{}}}

@unsafe
def Bq.send_to():
  \{Nil: (cid_0 => (line_1 => C.Bq.IO.pure(Unit, Unit{}))); \{Con: \{Net.Connection.Record: (cid2_0 => (st_1 => (pid_2 => (out_3 => (name_4 => (rest_5 => (cid_6 => (line_7 => (+apply_59 = {(rest_0 => (cid_1 => (line_2 => (out_3 => (word => C.Bq.word_case(IO(Unit), word, 0, (unit => Bq.send_to(rest_0, cid_1, line_2)), (_324_4 => Bq.chan_push(out_3, line_2)), 0)))))) : (@+rest_0: List<&1, Bq.Conn> -> (@+cid_1: U32 -> (@+line_2: C.Bq.String -> (@+out_3: Chan<C.Bq.String> -> (@+___4: U32 -> IO(Unit))))))}; apply_59(rest_5, cid_6, line_7, out_3, C.Bq.bit(U32.is_eq(cid2_0, cid_6)))))))))))); \{}}; \{}}}

@unsafe
def Bq.zone_of_cid():
  \{Nil: (cid_0 => 99); \{Con: \{Tuple: (cid2_0 => (zone_1 => (rest_2 => (cid_3 => (+apply_60 = {(rest_0 => (cid_1 => (cid2_2 => (zone_3 => (word => C.Bq.word_case(U32, word, 0, (unit => Bq.zone_of_cid(rest_0, cid_1)), (_255_4 => zone_3), 0)))))) : (@+rest_0: List<&1, C.Bq.Pair.Pair(U32, (__0 => U32))> -> (@+cid_1: U32 -> (@-cid2_2: U32 -> (@+zone_3: (__3 => U32)(cid2_2) -> (@+___4: U32 -> U32)))))}; apply_60(rest_2, cid_3, cid2_0, zone_1, C.Bq.bit(U32.is_eq(cid2_0, cid_3)))))))); \{}}; \{}}}

@unsafe
def Bq.send_zone():
  \{Nil: (zs_0 => (z_1 => (line_2 => C.Bq.IO.pure(Unit, Unit{})))); \{Con: \{Net.Connection.Record: (cid_0 => (st_1 => (pid_2 => (out_3 => (name_4 => (rest_5 => (zs_6 => (z_7 => (line_8 => (+apply_61 = {(rest_0 => (zs_1 => (z_2 => (line_3 => (out_4 => (word => C.Bq.word_case(IO(Unit), word, 0, (unit => Bq.send_zone(rest_0, zs_1, z_2, line_3)), (_337_5 => C.Bq.IO.bind(Unit, Unit, Bq.chan_push(out_4, line_3), (__6 => Bq.send_zone(rest_0, zs_1, z_2, line_3)))), 0))))))) : (@+rest_0: List<&1, Bq.Conn> -> (@+zs_1: List<&1, C.Bq.Pair.Pair(U32, (__1 => U32))> -> (@+z_2: U32 -> (@+line_3: C.Bq.String -> (@+out_4: Chan<C.Bq.String> -> (@+___5: U32 -> IO(Unit)))))))}; apply_61(rest_5, zs_6, z_7, line_8, out_3, C.Bq.word_and(C.Bq.bit(U32.is_eq(st_1, 2)), C.Bq.bit(U32.is_eq(Bq.zone_of_cid(zs_6, cid_0), z_7)))))))))))))); \{}}; \{}}}

@unsafe
def Bq.route_outs():
  \{Nil: (cs_0 => (zs_1 => (lg_2 => C.Bq.IO.pure(Unit, Unit{})))); \{Con: \{World.Bq.OutL.All: (line_0 => (rest_1 => (cs_2 => (zs_3 => (lg_4 => C.Bq.IO.bind(Unit, Unit, Bq.send_all(cs_2, line_0), (__5 => Bq.route_outs(rest_1, cs_2, zs_3, lg_4)))))))); \{World.Bq.OutL.To: (cid_0 => (line_1 => (rest_2 => (cs_3 => (zs_4 => (lg_5 => C.Bq.IO.bind(Unit, Unit, Bq.send_to(cs_3, cid_0, line_1), (__6 => Bq.route_outs(rest_2, cs_3, zs_4, lg_5))))))))); \{World.Bq.OutL.ZoneL: (zone_0 => (line_1 => (rest_2 => (cs_3 => (zs_4 => (lg_5 => C.Bq.IO.bind(Unit, Unit, Bq.send_zone(cs_3, zs_4, zone_0, line_1), (__6 => Bq.route_outs(rest_2, cs_3, zs_4, lg_5))))))))); \{World.Bq.OutL.Log: (line_0 => (rest_1 => (cs_2 => (zs_3 => (lg_4 => C.Bq.IO.bind(Unit, Unit, Bq.chan_push(lg_4, line_0), (__5 => Bq.route_outs(rest_1, cs_2, zs_3, lg_4)))))))); \{}}}}}; \{}}}

@unsafe
def Bq.cid_zones():
  \{Nil: Nil{}; \{Con: \{P.Players.State: (pid_0 => (cid_1 => (hero_2 => (pos_3 => (vit_4 => (style_5 => (qst_6 => (meta_7 => (rest_8 => Con{Tuple{cid_1, World.Bq.pos_zone(pos_3)}, Bq.cid_zones(rest_8)}))))))))); \{}}; \{}}}

@unsafe
def Bq.plrs_of_w():
  \{Terrain.Terrain.World: (wm_0 => (plrs_1 => (mobs_2 => (maps_3 => plrs_1)))); \{}}

@unsafe
def Bq.game_cmd():
  (w_0 => (pid_1 => \{Proto.Bq.Msg.Msg: (tag_2 => (ns_3 => (text_4 => (+apply_329 = {(w_0 => (pid_1 => (tag_2 => (ns_3 => \{False: (+apply_330 = {(w_0 => (pid_1 => (tag_2 => (ns_3 => \{False: (+apply_331 = {(w_0 => (pid_1 => (tag_2 => (ns_3 => \{False: (+apply_332 = {(w_0 => (pid_1 => (tag_2 => (ns_3 => \{False: (+apply_333 = {(w_0 => (pid_1 => (tag_2 => (ns_3 => \{False: (+apply_334 = {(w_0 => (pid_1 => (tag_2 => (ns_3 => \{False: (+apply_335 = {(w_0 => (pid_1 => (tag_2 => (ns_3 => \{False: (+apply_336 = {(w_0 => (pid_1 => (tag_2 => (ns_3 => \{False: (+apply_337 = {(w_0 => (pid_1 => (tag_2 => (ns_3 => \{False: (+apply_338 = {(w_0 => (pid_1 => (tag_2 => (ns_3 => \{False: (+apply_339 = {(w_0 => (pid_1 => \{False: Tuple{w_0, Nil{}}; \{True: World.Bq.cmd_enter(w_0, pid_1); \{}}})) : (@+w_0: World.Bq.World -> (@+pid_1: U32 -> (@+___2: Bool -> Sigma<&1, &1, World.Bq.World, (__3 => List<&1, World.Bq.OutL>)>)))}; apply_339(w_0, pid_1, Proto.Bq.is(tag_2, C.Bq.text("ENTER")))); \{True: World.Bq.cmd_talk(w_0, pid_1, Bq.nth(ns_3, 0)); \{}}})))) : (@+w_0: World.Bq.World -> (@+pid_1: U32 -> (@+tag_2: C.Bq.String -> (@+ns_3: List<&1, U32> -> (@+___4: Bool -> Sigma<&1, &1, World.Bq.World, (__5 => List<&1, World.Bq.OutL>)>)))))}; apply_338(w_0, pid_1, tag_2, ns_3, Proto.Bq.is(tag_2, C.Bq.text("TALK")))); \{True: World.Bq.cmd_buy(w_0, pid_1, Bq.nth(ns_3, 0)); \{}}})))) : (@+w_0: World.Bq.World -> (@+pid_1: U32 -> (@+tag_2: C.Bq.String -> (@+ns_3: List<&1, U32> -> (@+___4: Bool -> Sigma<&1, &1, World.Bq.World, (__5 => List<&1, World.Bq.OutL>)>)))))}; apply_337(w_0, pid_1, tag_2, ns_3, Proto.Bq.is(tag_2, C.Bq.text("BUY")))); \{True: World.Bq.cmd_alloc(w_0, pid_1, Bq.nth(ns_3, 0)); \{}}})))) : (@+w_0: World.Bq.World -> (@+pid_1: U32 -> (@+tag_2: C.Bq.String -> (@+ns_3: List<&1, U32> -> (@+___4: Bool -> Sigma<&1, &1, World.Bq.World, (__5 => List<&1, World.Bq.OutL>)>)))))}; apply_336(w_0, pid_1, tag_2, ns_3, Proto.Bq.is(tag_2, C.Bq.text("ALLOC")))); \{True: World.Bq.cmd_uneq(w_0, pid_1, Bq.nth(ns_3, 0)); \{}}})))) : (@+w_0: World.Bq.World -> (@+pid_1: U32 -> (@+tag_2: C.Bq.String -> (@+ns_3: List<&1, U32> -> (@+___4: Bool -> Sigma<&1, &1, World.Bq.World, (__5 => List<&1, World.Bq.OutL>)>)))))}; apply_335(w_0, pid_1, tag_2, ns_3, Proto.Bq.is(tag_2, C.Bq.text("UNEQ")))); \{True: World.Bq.cmd_equip(w_0, pid_1, Bq.nth(ns_3, 0)); \{}}})))) : (@+w_0: World.Bq.World -> (@+pid_1: U32 -> (@+tag_2: C.Bq.String -> (@+ns_3: List<&1, U32> -> (@+___4: Bool -> Sigma<&1, &1, World.Bq.World, (__5 => List<&1, World.Bq.OutL>)>)))))}; apply_334(w_0, pid_1, tag_2, ns_3, Proto.Bq.is(tag_2, C.Bq.text("EQUIP")))); \{True: World.Bq.cmd_quaff(w_0, pid_1); \{}}})))) : (@+w_0: World.Bq.World -> (@+pid_1: U32 -> (@+tag_2: C.Bq.String -> (@+ns_3: List<&1, U32> -> (@+___4: Bool -> Sigma<&1, &1, World.Bq.World, (__5 => List<&1, World.Bq.OutL>)>)))))}; apply_333(w_0, pid_1, tag_2, ns_3, Proto.Bq.is(tag_2, C.Bq.text("QUAFF")))); \{True: World.Bq.cmd_spin(w_0, pid_1); \{}}})))) : (@+w_0: World.Bq.World -> (@+pid_1: U32 -> (@+tag_2: C.Bq.String -> (@+ns_3: List<&1, U32> -> (@+___4: Bool -> Sigma<&1, &1, World.Bq.World, (__5 => List<&1, World.Bq.OutL>)>)))))}; apply_332(w_0, pid_1, tag_2, ns_3, Proto.Bq.is(tag_2, C.Bq.text("SPIN")))); \{True: World.Bq.cmd_atk(w_0, pid_1); \{}}})))) : (@+w_0: World.Bq.World -> (@+pid_1: U32 -> (@+tag_2: C.Bq.String -> (@+ns_3: List<&1, U32> -> (@+___4: Bool -> Sigma<&1, &1, World.Bq.World, (__5 => List<&1, World.Bq.OutL>)>)))))}; apply_331(w_0, pid_1, tag_2, ns_3, Proto.Bq.is(tag_2, C.Bq.text("ATK")))); \{True: World.Bq.cmd_halt(w_0, pid_1); \{}}})))) : (@+w_0: World.Bq.World -> (@+pid_1: U32 -> (@+tag_2: C.Bq.String -> (@+ns_3: List<&1, U32> -> (@+___4: Bool -> Sigma<&1, &1, World.Bq.World, (__5 => List<&1, World.Bq.OutL>)>)))))}; apply_330(w_0, pid_1, tag_2, ns_3, Proto.Bq.is(tag_2, C.Bq.text("HALT")))); \{True: World.Bq.cmd_move(w_0, pid_1, Bq.nth(ns_3, 0)); \{}}})))) : (@+w_0: World.Bq.World -> (@+pid_1: U32 -> (@+tag_2: C.Bq.String -> (@+ns_3: List<&1, U32> -> (@+___4: Bool -> Sigma<&1, &1, World.Bq.World, (__5 => List<&1, World.Bq.OutL>)>)))))}; apply_329(w_0, pid_1, tag_2, ns_3, Proto.Bq.is(tag_2, C.Bq.text("MOVE"))))))); \{}}))

@unsafe
def Bq.plr_zone_of():
  \{Nil: (pid_0 => 0); \{Con: \{P.Players.State: (pid2_0 => (cid_1 => (hero_2 => (pos_3 => (vit_4 => (style_5 => (qst_6 => (meta_7 => (rest_8 => (pid_9 => (+apply_340 = {(rest_0 => (pid_1 => (pos_2 => (word => C.Bq.word_case(U32, word, 0, (unit => Bq.plr_zone_of(rest_0, pid_1)), (_579_3 => World.Bq.pos_zone(pos_2)), 0))))) : (@+rest_0: List<&2, World.Bq.Plr> -> (@+pid_1: U32 -> (@+pos_2: World.Bq.Pos -> (@+___3: U32 -> U32))))}; apply_340(rest_8, pid_9, pos_3, C.Bq.bit(U32.is_eq(pid2_0, pid_9)))))))))))))); \{}}; \{}}}

@unsafe
def Bq.take_conn():
  (cid_0 => \{Nil: Tuple{Nil{}, Support.Bq.Maybe.none(Bq.Conn)}; \{Con: \{Net.Connection.Record: (cid2_1 => (st_2 => (pid_3 => (out_4 => (name_5 => (rest_6 => (+apply_341 = {(cid2_0 => (st_1 => (pid_2 => (out_3 => (name_4 => (cid_5 => (rest_6 => (word => C.Bq.word_case(Sigma<&1, &1, List<&1, Bq.Conn>, (__8 => Result<&1, &1, Unit, Bq.Conn>)>, word, 0, (unit => (+apply_342 = {(cid2_0 => (st_1 => (pid_2 => (out_3 => (name_4 => \{Tuple: (fst_5 => (snd_6 => Tuple{Con{Net.Connection.Record{cid2_0, st_1, pid_2, out_3, name_4}, fst_5}, snd_6})); \{}}))))) : (@+cid2_0: U32 -> (@+st_1: U32 -> (@+pid_2: U32 -> (@+out_3: Chan<C.Bq.String> -> (@+name_4: C.Bq.String -> (@+___5: Sigma<&1, &1, List<&1, Bq.Conn>, (__5 => Result<&1, &1, Unit, Bq.Conn>)> -> Sigma<&1, &1, List<&1, Bq.Conn>, (__6 => Result<&1, &1, Unit, Bq.Conn>)>))))))}; apply_342(cid2_0, st_1, pid_2, out_3, name_4, Bq.take_conn(cid_5, rest_6)))), (_214_7 => Tuple{rest_6, Support.Bq.Maybe.some(Bq.Conn, Net.Connection.Record{cid2_0, st_1, pid_2, out_3, name_4})}), 0))))))))) : (@+cid2_0: U32 -> (@+st_1: U32 -> (@+pid_2: U32 -> (@+out_3: Chan<C.Bq.String> -> (@+name_4: C.Bq.String -> (@+cid_5: U32 -> (@+rest_6: List<&1, Bq.Conn> -> (@+___7: U32 -> Sigma<&1, &1, List<&1, Bq.Conn>, (__8 => Result<&1, &1, Unit, Bq.Conn>)>))))))))}; apply_341(cid2_1, st_2, pid_3, out_4, name_5, cid_0, rest_6, C.Bq.bit(U32.is_eq(cid2_1, cid_0)))))))))); \{}}; \{}}})

@unsafe
def Bq.send_many():
  (cs_0 => (cid_1 => \{Nil: C.Bq.IO.pure(Unit, Unit{}); \{Con: (l_2 => (rest_3 => C.Bq.IO.bind(Unit, Unit, Bq.send_to(cs_0, cid_1, l_2), (__4 => Bq.send_many(cs_0, cid_1, rest_3))))); \{}}}))

@unsafe
def Bq.fp_enc():
  \{Bq.FP.FP: (name_0 => (lv_1 => (score_2 => (skin_3 => (hairs_4 => (hairc_5 => (shirt_6 => (hat_7 => (cape_8 => (wea_9 => (arm_10 => (hel_11 => (chm_12 => Proto.Bq.wire_enc(C.Bq.text("FP"), [lv_1, score_2, skin_3, hairs_4, hairc_5, shirt_6, hat_7, cape_8, wea_9, arm_10, hel_11, chm_12], name_0)))))))))))))); \{}}

@unsafe
def Bq.fame_fp_lines():
  \{Nil: Nil{}; \{Con: (f_0 => (rest_1 => Con{Bq.fp_enc(f_0), Bq.fame_fp_lines(rest_1)})); \{}}}

@unsafe
def Bq.fame_run_lines():
  \{Nil: Nil{}; \{Con: \{Bq.Run.Run: (no_0 => (dur_1 => (fps_2 => (rest_3 => Support.Bq.List.concat(C.Bq.String, Con{Proto.Bq.wire_enc(C.Bq.text("FRUN"), [no_0, dur_1, Support.Bq.List.length(Bq.FP, fps_2)], Nil{}), Bq.fame_fp_lines(fps_2)}, Bq.fame_run_lines(rest_3)))))); \{}}; \{}}}

@unsafe
def Bq.fame_lines():
  \{Bq.Db.Db: (wno_0 => (profs_1 => (runs_2 => Support.Bq.List.concat(C.Bq.String, Con{Proto.Bq.wire_enc(C.Bq.text("FAMEB"), [Support.Bq.List.length(Bq.Run, runs_2)], Nil{}), Bq.fame_run_lines(Support.Bq.List.take(Bq.Run, 8, runs_2))}, [Proto.Bq.wire_enc(C.Bq.text("FAMEE"), Nil{}, Nil{})])))); \{}}

@unsafe
def Bq.maps_of_w():
  \{Terrain.Terrain.World: (wm_0 => (plrs_1 => (mobs_2 => (maps_3 => maps_3)))); \{}}

@unsafe
def Bq.plr_name_lines():
  \{Nil: Nil{}; \{Con: \{P.Players.State: (pid_0 => (cid_1 => (hero_2 => (pos_3 => (vit_4 => (style_5 => (qst_6 => (meta_7 => (rest_8 => Con{Proto.Bq.wire_enc(C.Bq.text("PLR"), [pid_0], World.Bq.pm_name(meta_7)), Bq.plr_name_lines(rest_8)}))))))))); \{}}; \{}}}

@unsafe
def Bq.own_ok():
  (mask_0 => (id1_1 => (+apply_343 = {(mask_0 => (id1_1 => (word => C.Bq.word_case(U32, word, 0, (unit => (U32.shrn(mask_0, U32.to_nat((id1_1 - 1 : U32))) .&. 1 : U32)), (_389_2 => 1), 0)))) : (@+mask_0: U32 -> (@+id1_1: U32 -> (@+___2: U32 -> U32)))}; apply_343(mask_0, id1_1, C.Bq.bit(U32.is_eq(id1_1, 0))))))

@unsafe
def Bq.prof_get():
  \{Nil: (name_0 => Bq.Prof.Prof{name_0, 0, 0, 0}); \{Con: \{Bq.Prof.Prof: (n2_0 => (coins_1 => (hats_2 => (capes_3 => (rest_4 => (name_5 => (+apply_344 = {(rest_0 => (name_1 => (n2_2 => (coins_3 => (hats_4 => (capes_5 => \{False: Bq.prof_get(rest_0, name_1); \{True: Bq.Prof.Prof{n2_2, coins_3, hats_4, capes_5}; \{}}})))))) : (@+rest_0: List<&1, Bq.Prof> -> (@+name_1: C.Bq.String -> (@+n2_2: C.Bq.String -> (@+coins_3: U32 -> (@+hats_4: U32 -> (@+capes_5: U32 -> (@+___6: Bool -> Bq.Prof)))))))}; apply_344(rest_4, name_5, n2_0, coins_1, hats_2, capes_3, Support.Bq.String.eq(n2_0, name_5))))))))); \{}}; \{}}}

@unsafe
def Bq.db_prof():
  \{Bq.Db.Db: (wno_0 => (profs_1 => (runs_2 => (name_3 => Bq.prof_get(profs_1, name_3))))); \{}}

@unsafe
def Bq.CreateResult() -> Type: World.Bq.World & List<&1,Bq.Conn>

@unsafe
def Bq.create_rejected(+world: World.Bq.World,+connection: Bq.Conn,+others: List<&1,Bq.Conn>) -> IO(Bq.CreateResult):
  match connection:
    case Net.Connection.Record{cid,state,pid,out,name}:
      +cid = cid
      +state = state
      +pid = pid
      +out = out
      +name = name
      C.Bq.IO.bind(Unit,Bq.CreateResult,Bq.chan_push(out,Proto.Bq.wire_enc(C.Bq.text("ERR"),Nil{},C.Bq.text("create rejected"))),(_ => C.Bq.IO.pure(Bq.CreateResult,Tuple{world,Con{Net.Connection.Record{cid,state,pid,out,name},others}})))

@unsafe
def Bq.create_announced(+world: World.Bq.World,+pid: U32,connection: Bq.Conn,+others: List<&1,Bq.Conn>,+log: Chan<C.Bq.String>) -> IO(Bq.CreateResult):
  match connection:
    case Net.Connection.Record{cid,state,old_pid,out,name}:
      +cid = cid
      +state = state
      +old_pid = old_pid
      +out = out
      +name = name
      +descriptor = Sess.Sessions.bind(Sess.Sessions.State{cid,state,old_pid,P.Players.share_name(name)},pid)
      +connections = {Con{Bq.connection_from_descriptor(descriptor,out),others} : List<&1,Bq.Conn>}
      C.Bq.IO.bind(Unit,Bq.CreateResult,Bq.chan_push(out,World.Bq.zone_line(Bq.maps_of_w(world),0)),(_ =>
        C.Bq.IO.bind(Unit,Bq.CreateResult,Bq.send_many(connections,cid,Bq.plr_name_lines(Bq.plrs_of_w(world))),(_ =>
          C.Bq.IO.bind(Unit,Bq.CreateResult,Bq.send_all(connections,Proto.Bq.wire_enc(C.Bq.text("PLR"),[pid],name)),(_ =>
            C.Bq.IO.bind(Unit,Bq.CreateResult,Bq.send_all(connections,Proto.Bq.wire_enc(C.Bq.text("EV"),Nil{},Support.Bq.List.concat(Char,name,C.Bq.text(" has entered the realm!")))),(_ =>
              C.Bq.IO.bind(Unit,Bq.CreateResult,Bq.chan_push(log,Support.Bq.List.concat(Char,name,Support.Bq.List.concat(Char,C.Bq.text(" joined as pid "),Support.Bq.U32.show(pid)))),(_ =>
                C.Bq.IO.pure(Bq.CreateResult,Tuple{world,connections})))))))))))


@unsafe
def Bq.create_committed(failed: Bool,world: World.Bq.World,pid: U32,previous: World.Bq.World,connection: Bq.Conn,others: List<&1,Bq.Conn>,log: Chan<C.Bq.String>) -> IO(Bq.CreateResult):
  match failed:
    case True{}: Bq.create_rejected(previous,connection,others)
    case False{}: Bq.create_announced(world,pid,connection,others,log)

@unsafe
def Bq.create_result(result: World.Bq.World & U32,previous: World.Bq.World,connection: Bq.Conn,others: List<&1,Bq.Conn>,log: Chan<C.Bq.String>) -> IO(Bq.CreateResult):
  match result:
    case Tuple{world,pid}:
      +id = pid
      Bq.create_committed(U32.is_eq(id,0),world,id,previous,connection,others,log)

@unsafe
def Bq.create_gate(rejected: Bool,+world: World.Bq.World,+connection: Bq.Conn,+others: List<&1,Bq.Conn>,+numbers: List<&1,U32>,hat: U32,cape: U32,log: Chan<C.Bq.String>) -> IO(Bq.CreateResult):
  match rejected:
    case True{}: Bq.create_rejected(world,connection,others)
    case False{}:
      match connection:
        case Net.Connection.Record{cid,state,pid,out,name}:
          +cid = cid
          +state = state
          +pid = pid
          +out = out
          +name = name
          Bq.create_result(World.Bq.add_plr(world,cid,U32.mod(Bq.nth(numbers,0),4),U32.mod(Bq.nth(numbers,1),3),U32.mod(Bq.nth(numbers,2),6),U32.mod(Bq.nth(numbers,3),6),hat,cape,name),world,Net.Connection.Record{cid,state,pid,out,name},others,log)

@unsafe
def Bq.create_profile(profile: Bq.Prof,world: World.Bq.World,connection: Bq.Conn,others: List<&1,Bq.Conn>,+numbers: List<&1,U32>,log: Chan<C.Bq.String>) -> IO(Bq.CreateResult):
  match profile:
    case Bq.Prof.Prof{profile_name,coins,hats,capes}:
      match connection:
        case Net.Connection.Record{cid,state,pid,out,name}:
          +cid = cid
          +state = state
          +pid = pid
          +out = out
          +name = name
          +hat = Bq.nth(numbers,4)
          +cape = Bq.nth(numbers,5)
          Bq.create_gate(Bool.or(U32.is_ne(state,1),Bool.or(U32.is_eq(Bq.own_ok(hats,hat),0),U32.is_eq(Bq.own_ok(capes,cape),0))),world,Net.Connection.Record{cid,state,pid,out,name},others,numbers,hat,cape,log)

@unsafe
def Bq.create_found(found: Result<&1,&1,Unit,Bq.Conn>,world: World.Bq.World,others: List<&1,Bq.Conn>,db: Bq.Db,numbers: List<&1,U32>,log: Chan<C.Bq.String>) -> IO(Bq.CreateResult):
  match found:
    case Fail{error}: C.Bq.IO.pure(Bq.CreateResult,Tuple{world,others})
    case Done{connection}:
      match connection:
        case Net.Connection.Record{cid,state,pid,out,name}:
          +cid = cid
          +state = state
          +pid = pid
          +out = out
          +name = name
          Bq.create_profile(Bq.db_prof(db,name),world,Net.Connection.Record{cid,state,pid,out,name},others,numbers,log)

@unsafe
def Bq.create_taken(taken: List<&1,Bq.Conn> & Result<&1,&1,Unit,Bq.Conn>,world: World.Bq.World,db: Bq.Db,numbers: List<&1,U32>,log: Chan<C.Bq.String>) -> IO(Bq.CreateResult):
  match taken:
    case Tuple{others,found}: Bq.create_found(found,world,others,db,numbers,log)

@unsafe
def Bq.on_create(world,connections,db,cid,numbers,log):
  Bq.create_taken(Bq.take_conn(cid,connections),world,db,numbers,log)

@unsafe
def Bq.shop_price():
  (t_0 => (id_1 => (+apply_355 = {(id_0 => (t_1 => (word => C.Bq.word_case(U32, word, 0, (unit => (+apply_356 = {(id_0 => (word => C.Bq.word_case(U32, word, 0, (unit => 0), (_415_1 => Data.Bq.cape_price((id_0 - 1 : U32))), 0))) : (@+id_0: U32 -> (@+___1: U32 -> U32))}; apply_356(id_0, C.Bq.word_and(C.Bq.word_and(C.Bq.bit(U32.is_eq(t_1, 1)), C.Bq.bit(U32.is_ge(id_0, 1))), C.Bq.bit(U32.is_le(id_0, 2)))))), (_417_2 => Data.Bq.hat_price((id_0 - 1 : U32))), 0)))) : (@+id_0: U32 -> (@+t_1: U32 -> (@+___2: U32 -> U32)))}; apply_355(id_1, t_0, C.Bq.word_and(C.Bq.word_and(C.Bq.bit(U32.is_eq(t_0, 0)), C.Bq.bit(U32.is_ge(id_1, 1))), C.Bq.bit(U32.is_le(id_1, 3)))))))

@unsafe
def Bq.shop_owned():
  (t_0 => (id_1 => (hats_2 => (capes_3 => (+apply_357 = {(capes_0 => (id_1 => (hats_2 => (word => C.Bq.word_case(U32, word, 0, (unit => (U32.shrn(capes_0, U32.to_nat((id_1 - 1 : U32))) .&. 1 : U32)), (_423_3 => (U32.shrn(hats_2, U32.to_nat((id_1 - 1 : U32))) .&. 1 : U32)), 0))))) : (@+capes_0: U32 -> (@+id_1: U32 -> (@+hats_2: U32 -> (@+___3: U32 -> U32))))}; apply_357(capes_3, id_1, hats_2, C.Bq.bit(U32.is_eq(t_0, 0))))))))

@unsafe
def Bq.prof_put():
  (ps_0 => \{Bq.Prof.Prof: (field_358 => field_359 => field_360 => field_361 => (+apply_362 = {\{Nil: (name_0 => (coins_1 => (hats_2 => (capes_3 => [Bq.Prof.Prof{name_0, coins_1, hats_2, capes_3}])))); \{Con: (head_0 => (tail_1 => (+apply_363 = {\{Bq.Prof.Prof: (name_0 => (coins_1 => (hats_2 => (capes_3 => (rest_4 => (name_5 => (coins_6 => (hats_7 => (capes_8 => (+apply_364 = {(name_0 => (coins_1 => (hats_2 => (capes_3 => (rest_4 => (name_5 => (coins_6 => (hats_7 => (capes_8 => \{False: Con{Bq.Prof.Prof{name_0, coins_1, hats_2, capes_3}, Bq.prof_put(rest_4, Bq.Prof.Prof{name_5, coins_6, hats_7, capes_8})}; \{True: Con{Bq.Prof.Prof{name_5, coins_6, hats_7, capes_8}, rest_4}; \{}}}))))))))) : (@+name_0: C.Bq.String -> (@+coins_1: U32 -> (@+hats_2: U32 -> (@+capes_3: U32 -> (@+rest_4: List<&1, Bq.Prof> -> (@+name_5: C.Bq.String -> (@+coins_6: U32 -> (@+hats_7: U32 -> (@+capes_8: U32 -> (@+___9: Bool -> List<&1, Bq.Prof>))))))))))}; apply_364(name_0, coins_1, hats_2, capes_3, rest_4, name_5, coins_6, hats_7, capes_8, Support.Bq.String.eq(name_0, name_5)))))))))))); \{}} : (@+___0: Bq.Prof -> (@+__1: List<&1, Bq.Prof> -> (@+__2: List<&1, Char> -> (@+__3: U32 -> (@+__4: U32 -> (@+__5: U32 -> List<&1, Bq.Prof>))))))}; apply_363(head_0, tail_1)))); \{}}} : (@+___0: List<&1, Bq.Prof> -> (@+__1: List<&1, Char> -> (@+__2: U32 -> (@+__3: U32 -> (@+__4: U32 -> List<&1, Bq.Prof>)))))}; apply_362(ps_0, field_358, field_359, field_360, field_361))); \{}})

@unsafe
def Bq.db_put_prof():
  \{Bq.Db.Db: (wno_0 => (profs_1 => (runs_2 => (p_3 => Bq.Db.Db{wno_0, Bq.prof_put(profs_1, p_3), runs_2})))); \{}}

@unsafe
def Bq.shop_apply():
  (t_0 => (id_1 => (name_2 => (coins_3 => (hats_4 => (capes_5 => (+apply_365 = {(name_0 => (coins_1 => (hats_2 => (capes_3 => (id_4 => (word => C.Bq.word_case(Bq.Prof, word, 0, (unit => Bq.Prof.Prof{name_0, coins_1, hats_2, (capes_3 .|. U32.shln(1, U32.to_nat((id_4 - 1 : U32))) : U32)}), (_431_5 => Bq.Prof.Prof{name_0, coins_1, (hats_2 .|. U32.shln(1, U32.to_nat((id_4 - 1 : U32))) : U32), capes_3}), 0))))))) : (@+name_0: C.Bq.String -> (@+coins_1: U32 -> (@+hats_2: U32 -> (@+capes_3: U32 -> (@+id_4: U32 -> (@+___5: U32 -> Bq.Prof))))))}; apply_365(name_2, coins_3, hats_4, capes_5, id_1, C.Bq.bit(U32.is_eq(t_0, 0))))))))))

@unsafe
def Bq.prof_enc():
  \{Bq.Prof.Prof: (name_0 => (coins_1 => (hats_2 => (capes_3 => Proto.Bq.wire_enc(C.Bq.text("PROF"), [coins_1, hats_2, capes_3], name_0))))); \{}}

@unsafe
def Bq.profs_enc():
  \{Nil: Nil{}; \{Con: (p_0 => (rest_1 => Support.Bq.List.concat(Char, Bq.prof_enc(p_0), Bq.profs_enc(rest_1)))); \{}}}

@unsafe
def Bq.fps_enc():
  \{Nil: Nil{}; \{Con: (f_0 => (rest_1 => Support.Bq.List.concat(Char, Bq.fp_enc(f_0), Bq.fps_enc(rest_1)))); \{}}}

@unsafe
def Bq.run_enc():
  \{Bq.Run.Run: (no_0 => (dur_1 => (fps_2 => Support.Bq.List.concat(Char, Proto.Bq.wire_enc(C.Bq.text("RUN"), [no_0, dur_1, Support.Bq.List.length(Bq.FP, fps_2)], Nil{}), Bq.fps_enc(fps_2))))); \{}}

@unsafe
def Bq.runs_enc():
  \{Nil: Nil{}; \{Con: (r_0 => (rest_1 => Support.Bq.List.concat(Char, Bq.run_enc(r_0), Bq.runs_enc(rest_1)))); \{}}}

@unsafe
def Bq.db_enc():
  \{Bq.Db.Db: (wno_0 => (profs_1 => (runs_2 => Support.Bq.List.concat(Char, Proto.Bq.wire_enc(C.Bq.text("DB"), [wno_0], Nil{}), Support.Bq.List.concat(Char, Bq.profs_enc(profs_1), Bq.runs_enc(runs_2)))))); \{}}

@unsafe
def Bq.db_save():
  (db_0 => C.Bq.IO.bind(Result<&1, &1, C.Bq.Pair.Pair(U32, (__1 => C.Bq.String)), Unit>, Unit, C.Bq.IO.write_text(Bq.DB_PATH, Bq.db_enc(db_0)), \{Done: (u_1 => C.Bq.IO.pure(Unit, Unit{})); \{Fail: (e_1 => C.Bq.IO.print_err(C.Bq.text("db save failed"))); \{}}}))

@unsafe
def Bq.welcome_line():
  (db_0 => (name_1 => (wno_2 => (phase_3 => (+apply_366 = {(wno_0 => (phase_1 => \{Bq.Prof.Prof: (name_2 => (coins_3 => (hats_4 => (capes_5 => Proto.Bq.wire_enc(C.Bq.text("WELCOME"), [coins_3, hats_4, capes_5, wno_0, phase_1], name_2))))); \{}})) : (@+wno_0: U32 -> (@+phase_1: U32 -> (@+___2: Bq.Prof -> List<&1, Char>)))}; apply_366(wno_2, phase_3, Bq.db_prof(db_0, name_1)))))))

@unsafe
def Bq.on_shop():
  (cs_0 => (db_1 => (cid_2 => (t_3 => (id_4 => (+apply_367 = {(db_0 => (t_1 => (id_2 => \{Tuple: (fst_3 => (snd_4 => (+apply_368 = {(fst_0 => (db_1 => (t_2 => (id_3 => \{Fail: (error_4 => C.Bq.IO.pure(C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__5 => Bq.Db)), Tuple{fst_0, db_1})); \{Done: (value_4 => (+apply_369 = {(t_0 => (id_1 => (db_2 => (fst_3 => \{Net.Connection.Record: (cid_4 => (st_5 => (pid_6 => (out_7 => (name_8 => (+apply_370 = {(t_0 => (id_1 => (db_2 => (out_3 => (name_4 => (cid_5 => (st_6 => (pid_7 => (fst_8 => \{Bq.Prof.Prof: (name_9 => (coins_10 => (hats_11 => (capes_12 => (+price_13 = Bq.shop_price(t_0, id_1); (+owned_14 = Bq.shop_owned(t_0, id_1, hats_11, capes_12); (+apply_371 = {(db_0 => (t_1 => (id_2 => (name_3 => (coins_4 => (price_5 => (hats_6 => (capes_7 => (out_8 => (name_9 => (cid_10 => (st_11 => (pid_12 => (fst_13 => (word => C.Bq.word_case(IO(Sigma<&1, &1, List<&1, Bq.Conn>, (__15 => Bq.Db)>), word, 0, (unit => (+db2_14 = Bq.db_put_prof(db_0, Bq.shop_apply(t_1, id_2, name_3, (coins_4 - price_5 : U32), hats_6, capes_7)); C.Bq.IO.bind(Unit, C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__15 => Bq.Db)), Bq.db_save(db2_14), (__15 => C.Bq.IO.bind(Unit, C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__16 => Bq.Db)), Bq.chan_push(out_8, Bq.welcome_line(db2_14, name_9, 0, 0)), (__16 => C.Bq.IO.pure(C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__17 => Bq.Db)), Tuple{Con{Net.Connection.Record{cid_10, st_11, pid_12, out_8, name_9}, fst_13}, db2_14}))))))), (_454_14 => C.Bq.IO.bind(Unit, C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__15 => Bq.Db)), Bq.chan_push(out_8, Proto.Bq.wire_enc(C.Bq.text("ERR"), Nil{}, C.Bq.text("cannot buy that"))), (__15 => C.Bq.IO.pure(C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__16 => Bq.Db)), Tuple{Con{Net.Connection.Record{cid_10, st_11, pid_12, out_8, name_9}, fst_13}, db_0})))), 0)))))))))))))))) : (@+db_0: Bq.Db -> (@+t_1: U32 -> (@+id_2: U32 -> (@+name_3: C.Bq.String -> (@+coins_4: U32 -> (@+price_5: U32 -> (@+hats_6: U32 -> (@+capes_7: U32 -> (@+out_8: Chan<C.Bq.String> -> (@+name_9: C.Bq.String -> (@+cid_10: U32 -> (@+st_11: U32 -> (@+pid_12: U32 -> (@+fst_13: List<&1, Bq.Conn> -> (@+___14: U32 -> IO(Sigma<&1, &1, List<&1, Bq.Conn>, (__15 => Bq.Db)>))))))))))))))))}; apply_371(db_2, t_0, id_1, name_9, coins_10, price_13, hats_11, capes_12, out_3, name_4, cid_5, st_6, pid_7, fst_8, C.Bq.word_or(C.Bq.word_or(C.Bq.word_or(C.Bq.bit(U32.is_eq(st_6, 0)), C.Bq.bit(U32.is_eq(price_13, 0))), owned_14), C.Bq.bit(U32.is_lt(coins_10, price_13))))))))))); \{}}))))))))) : (@+t_0: U32 -> (@+id_1: U32 -> (@+db_2: Bq.Db -> (@+out_3: Chan<C.Bq.String> -> (@+name_4: C.Bq.String -> (@+cid_5: U32 -> (@+st_6: U32 -> (@+pid_7: U32 -> (@+fst_8: List<&1, Bq.Conn> -> (@+___9: Bq.Prof -> IO(Sigma<&1, &1, List<&1, Bq.Conn>, (__10 => Bq.Db)>)))))))))))}; apply_370(t_0, id_1, db_2, out_7, name_8, cid_4, st_5, pid_6, fst_3, Bq.db_prof(db_2, name_8)))))))); \{}})))) : (@+t_0: U32 -> (@+id_1: U32 -> (@+db_2: Bq.Db -> (@+fst_3: List<&1, Bq.Conn> -> (@+___4: Bq.Conn -> IO(Sigma<&1, &1, List<&1, Bq.Conn>, (__5 => Bq.Db)>))))))}; apply_369(t_2, id_3, db_1, fst_0, value_4))); \{}}})))) : (@+fst_0: List<&1, Bq.Conn> -> (@+db_1: Bq.Db -> (@+t_2: U32 -> (@+id_3: U32 -> (@+___4: Result<&1, &1, Unit, Bq.Conn> -> IO(Sigma<&1, &1, List<&1, Bq.Conn>, (__5 => Bq.Db)>))))))}; apply_368(fst_3, db_0, t_1, id_2, snd_4)))); \{}}))) : (@+db_0: Bq.Db -> (@+t_1: U32 -> (@+id_2: U32 -> (@+___3: Sigma<&1, &1, List<&1, Bq.Conn>, (__3 => Result<&1, &1, Unit, Bq.Conn>)> -> IO(Sigma<&1, &1, List<&1, Bq.Conn>, (__4 => Bq.Db)>)))))}; apply_367(db_1, t_3, id_4, Bq.take_conn(cid_2, cs_0))))))))

@unsafe
def Bq.valid_name(name): Sess.Sessions.valid_name(P.Players.share_name(name))

@unsafe
def Bq.name_online(connections,name): Sess.Sessions.online(Bq.session_descriptors(connections),P.Players.share_name(name))

@unsafe
def Bq.hello_rejected(connection: Bq.Conn,+others: List<&1,Bq.Conn>,message: C.Bq.String) -> IO(List<&1,Bq.Conn>):
  match connection:
    case Net.Connection.Record{cid,phase,pid,out,name}:
      +out = out
      C.Bq.IO.bind(Unit,List<&1,Bq.Conn>,Bq.chan_push(out,Proto.Bq.wire_enc(C.Bq.text("ERR"),Nil{},message)),(_ => C.Bq.IO.pure(List<&1,Bq.Conn>,Con{Net.Connection.Record{cid,phase,pid,out,name},others})))

@unsafe
def Bq.hello_accepted(state: Sess.Sessions.State,connection: Bq.Conn,+others: List<&1,Bq.Conn>,+world: World.Bq.World,db: Bq.Db,+log: Chan<C.Bq.String>) -> IO(List<&1,Bq.Conn>):
  match state:
    case Sess.Sessions.State{cid,phase,pid,name}:
      match connection:
        case Net.Connection.Record{old_cid,old_phase,old_pid,out,old_name}:
          +out = out
          +name = P.Players.text_name(name)
          +connections = {Con{Net.Connection.Record{cid,phase,pid,out,name},others} : List<&1,Bq.Conn>}
          +meta = S.Simulation.meta(Terrain.Terrain.simulation(world))
          C.Bq.IO.bind(Unit,List<&1,Bq.Conn>,Bq.chan_push(out,Bq.welcome_line(db,name,World.Bq.wm_wno(meta),World.Bq.wm_phase(meta))),(_ =>
            C.Bq.IO.bind(Unit,List<&1,Bq.Conn>,Bq.chan_push(log,Support.Bq.List.concat(Char,C.Bq.text("hello: "),name)),(_ =>
              C.Bq.IO.pure(List<&1,Bq.Conn>,connections)))))

@unsafe
def Bq.hello_result(result: Sess.Sessions.Result,connection: Bq.Conn,others: List<&1,Bq.Conn>,world: World.Bq.World,db: Bq.Db,log: Chan<C.Bq.String>) -> IO(List<&1,Bq.Conn>):
  match result:
    case Sess.Sessions.Result{state,reply}:
      match reply:
        case Sess.Sessions.Locked{}: Bq.hello_rejected(connection,others,C.Bq.text("already playing"))
        case Sess.Sessions.BadName{}: Bq.hello_rejected(connection,others,C.Bq.text("that name is empty or too long"))
        case Sess.Sessions.Taken{}: Bq.hello_rejected(connection,others,C.Bq.text("that name is already online"))
        case Sess.Sessions.Welcome{}: Bq.hello_accepted(state,connection,others,world,db,log)

@unsafe
def Bq.hello_found(found: Result<&1,&1,Unit,Bq.Conn>,+others: List<&1,Bq.Conn>,world: World.Bq.World,db: Bq.Db,name: C.Bq.String,log: Chan<C.Bq.String>) -> IO(List<&1,Bq.Conn>):
  match found:
    case Fail{error}: C.Bq.IO.pure(List<&1,Bq.Conn>,others)
    case Done{connection}:
      +connection = connection
      Bq.hello_result(Sess.Sessions.hello(Bq.session_descriptor(connection),P.Players.share_name(name),Bq.session_descriptors(others)),connection,others,world,db,log)

@unsafe
def Bq.hello_taken(taken: List<&1,Bq.Conn> & Result<&1,&1,Unit,Bq.Conn>,world: World.Bq.World,db: Bq.Db,name: C.Bq.String,log: Chan<C.Bq.String>) -> IO(List<&1,Bq.Conn>):
  match taken:
    case Tuple{others,found}: Bq.hello_found(found,others,world,db,name,log)

@unsafe
def Bq.on_hello(world,connections,db,cid,name,log): Bq.hello_taken(Bq.take_conn(cid,connections),world,db,name,log)

@unsafe
def Bq.on_line():
  (w_0 => (cs_1 => (db_2 => (cid_3 => (line_4 => (lg_5 => (+m_6 = Proto.Bq.wire_dec(line_4); (+apply_378 = {(w_0 => (db_1 => (lg_2 => (cid_3 => (cs_4 => \{Proto.Bq.Msg.Msg: (tag_5 => (ns_6 => (text_7 => (+apply_379 = {(w_0 => (db_1 => (lg_2 => (tag_3 => (ns_4 => (text_5 => (cid_6 => (cs_7 => \{False: (+apply_380 = {(w_0 => (db_1 => (lg_2 => (tag_3 => (ns_4 => (text_5 => (cid_6 => (cs_7 => \{False: (+apply_381 = {(w_0 => (db_1 => (lg_2 => (tag_3 => (ns_4 => (text_5 => (cid_6 => (cs_7 => \{False: (+apply_382 = {(w_0 => (db_1 => (lg_2 => (tag_3 => (ns_4 => (text_5 => (cid_6 => (cs_7 => \{False: (+apply_383 = {(w_0 => (db_1 => (lg_2 => (tag_3 => (ns_4 => (text_5 => (cid_6 => (cs_7 => \{False: (+apply_384 = {(w_0 => (db_1 => (lg_2 => (tag_3 => (ns_4 => (text_5 => \{Tuple: (fst_6 => (snd_7 => (+apply_385 = {(w_0 => (fst_1 => (db_2 => (lg_3 => (tag_4 => (ns_5 => (text_6 => \{Fail: (error_7 => C.Bq.IO.pure(C.Bq.Pair.Pair(World.Bq.World, (__8 => C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__9 => Bq.Db)))), Tuple{w_0, Tuple{fst_1, db_2}})); \{Done: (value_7 => (+apply_386 = {(fst_0 => (lg_1 => (db_2 => (w_3 => (tag_4 => (ns_5 => (text_6 => \{Net.Connection.Record: (cid_7 => (st_8 => (pid_9 => (out_10 => (name_11 => (+cs5_12 = {Con{Net.Connection.Record{cid_7, st_8, pid_9, out_10, name_11}, fst_0} : List<&1, Bq.Conn>}; (+apply_387 = {(cs5_0 => (lg_1 => (db_2 => (w_3 => (pid_4 => (tag_5 => (ns_6 => (text_7 => (name_8 => (word => C.Bq.word_case(IO(Sigma<&1, &1, World.Bq.World, (__10 => Sigma<&1, &1, List<&1, Bq.Conn>, (__11 => Bq.Db)>)>), word, 0, (unit => (+apply_388 = {(cs5_0 => (lg_1 => (db_2 => (w_3 => (pid_4 => (tag_5 => (ns_6 => (text_7 => (name_8 => \{False: (+apply_389 = {(cs5_0 => (lg_1 => (db_2 => \{Tuple: (fst_3 => (snd_4 => C.Bq.IO.bind(Unit, C.Bq.Pair.Pair(World.Bq.World, (__5 => C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__6 => Bq.Db)))), Bq.route_outs(snd_4, cs5_0, Bq.cid_zones(Bq.plrs_of_w(fst_3)), lg_1), (__5 => C.Bq.IO.pure(C.Bq.Pair.Pair(World.Bq.World, (__6 => C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__7 => Bq.Db)))), Tuple{fst_3, Tuple{cs5_0, db_2}}))))); \{}}))) : (@+cs5_0: List<&1, Bq.Conn> -> (@+lg_1: Chan<C.Bq.String> -> (@+db_2: Bq.Db -> (@+___3: Sigma<&1, &1, World.Bq.World, (__3 => List<&1, World.Bq.OutL>)> -> IO(Sigma<&1, &1, World.Bq.World, (__4 => Sigma<&1, &1, List<&1, Bq.Conn>, (__5 => Bq.Db)>)>)))))}; apply_389(cs5_0, lg_1, db_2, Bq.game_cmd(w_3, pid_4, Proto.Bq.Msg.Msg{tag_5, ns_6, text_7}))); \{True: (+z_9 = Bq.plr_zone_of(Bq.plrs_of_w(w_3), pid_4); C.Bq.IO.bind(Unit, C.Bq.Pair.Pair(World.Bq.World, (__10 => C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__11 => Bq.Db)))), Bq.send_all(cs5_0, Proto.Bq.wire_enc(C.Bq.text("EV"), Nil{}, Support.Bq.List.concat(Char, name_8, Support.Bq.List.concat(Char, C.Bq.text(": "), text_7)))), (__10 => C.Bq.IO.bind(Unit, C.Bq.Pair.Pair(World.Bq.World, (__11 => C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__12 => Bq.Db)))), Bq.send_zone(cs5_0, Bq.cid_zones(Bq.plrs_of_w(w_3)), z_9, Proto.Bq.wire_enc(C.Bq.text("BUBBLE"), [pid_4], text_7)), (__11 => C.Bq.IO.pure(C.Bq.Pair.Pair(World.Bq.World, (__12 => C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__13 => Bq.Db)))), Tuple{w_3, Tuple{cs5_0, db_2}})))))); \{}}}))))))))) : (@+cs5_0: List<&1, Bq.Conn> -> (@+lg_1: Chan<C.Bq.String> -> (@+db_2: Bq.Db -> (@+w_3: World.Bq.World -> (@+pid_4: U32 -> (@+tag_5: C.Bq.String -> (@+ns_6: List<&1, U32> -> (@+text_7: C.Bq.String -> (@+name_8: C.Bq.String -> (@+___9: Bool -> IO(Sigma<&1, &1, World.Bq.World, (__10 => Sigma<&1, &1, List<&1, Bq.Conn>, (__11 => Bq.Db)>)>)))))))))))}; apply_388(cs5_0, lg_1, db_2, w_3, pid_4, tag_5, ns_6, text_7, name_8, Proto.Bq.is(tag_5, C.Bq.text("SAY"))))), (_614_9 => C.Bq.IO.pure(C.Bq.Pair.Pair(World.Bq.World, (__10 => C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__11 => Bq.Db)))), Tuple{w_3, Tuple{cs5_0, db_2}})), 0))))))))))) : (@+cs5_0: List<&1, Bq.Conn> -> (@+lg_1: Chan<C.Bq.String> -> (@+db_2: Bq.Db -> (@+w_3: World.Bq.World -> (@+pid_4: U32 -> (@+tag_5: C.Bq.String -> (@+ns_6: List<&1, U32> -> (@+text_7: C.Bq.String -> (@+name_8: C.Bq.String -> (@+___9: U32 -> IO(Sigma<&1, &1, World.Bq.World, (__10 => Sigma<&1, &1, List<&1, Bq.Conn>, (__11 => Bq.Db)>)>)))))))))))}; apply_387(cs5_12, lg_1, db_2, w_3, pid_9, tag_4, ns_5, text_6, name_11, C.Bq.bit(U32.is_ne(st_8, 2)))))))))); \{}}))))))) : (@+fst_0: List<&1, Bq.Conn> -> (@+lg_1: Chan<C.Bq.String> -> (@+db_2: Bq.Db -> (@+w_3: World.Bq.World -> (@+tag_4: C.Bq.String -> (@+ns_5: List<&1, U32> -> (@+text_6: C.Bq.String -> (@+___7: Bq.Conn -> IO(Sigma<&1, &1, World.Bq.World, (__8 => Sigma<&1, &1, List<&1, Bq.Conn>, (__9 => Bq.Db)>)>)))))))))}; apply_386(fst_1, lg_3, db_2, w_0, tag_4, ns_5, text_6, value_7))); \{}}}))))))) : (@+w_0: World.Bq.World -> (@+fst_1: List<&1, Bq.Conn> -> (@+db_2: Bq.Db -> (@+lg_3: Chan<C.Bq.String> -> (@+tag_4: C.Bq.String -> (@+ns_5: List<&1, U32> -> (@+text_6: C.Bq.String -> (@+___7: Result<&1, &1, Unit, Bq.Conn> -> IO(Sigma<&1, &1, World.Bq.World, (__8 => Sigma<&1, &1, List<&1, Bq.Conn>, (__9 => Bq.Db)>)>)))))))))}; apply_385(w_0, fst_6, db_1, lg_2, tag_3, ns_4, text_5, snd_7)))); \{}})))))) : (@+w_0: World.Bq.World -> (@+db_1: Bq.Db -> (@+lg_2: Chan<C.Bq.String> -> (@+tag_3: C.Bq.String -> (@+ns_4: List<&1, U32> -> (@+text_5: C.Bq.String -> (@+___6: Sigma<&1, &1, List<&1, Bq.Conn>, (__6 => Result<&1, &1, Unit, Bq.Conn>)> -> IO(Sigma<&1, &1, World.Bq.World, (__7 => Sigma<&1, &1, List<&1, Bq.Conn>, (__8 => Bq.Db)>)>))))))))}; apply_384(w_0, db_1, lg_2, tag_3, ns_4, text_5, Bq.take_conn(cid_6, cs_7))); \{True: C.Bq.IO.bind(Unit, C.Bq.Pair.Pair(World.Bq.World, (__8 => C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__9 => Bq.Db)))), Bq.send_to(cs_7, cid_6, Proto.Bq.wire_enc(C.Bq.text("PONG"), ns_4, Nil{})), (__8 => C.Bq.IO.pure(C.Bq.Pair.Pair(World.Bq.World, (__9 => C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__10 => Bq.Db)))), Tuple{w_0, Tuple{cs_7, db_1}}))); \{}}})))))))) : (@+w_0: World.Bq.World -> (@+db_1: Bq.Db -> (@+lg_2: Chan<C.Bq.String> -> (@+tag_3: C.Bq.String -> (@+ns_4: List<&1, U32> -> (@+text_5: C.Bq.String -> (@+cid_6: U32 -> (@+cs_7: List<&1, Bq.Conn> -> (@+___8: Bool -> IO(Sigma<&1, &1, World.Bq.World, (__9 => Sigma<&1, &1, List<&1, Bq.Conn>, (__10 => Bq.Db)>)>))))))))))}; apply_383(w_0, db_1, lg_2, tag_3, ns_4, text_5, cid_6, cs_7, Proto.Bq.is(tag_3, C.Bq.text("PING")))); \{True: C.Bq.IO.bind(Unit, C.Bq.Pair.Pair(World.Bq.World, (__8 => C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__9 => Bq.Db)))), Bq.send_many(cs_7, cid_6, Bq.fame_lines(db_1)), (__8 => C.Bq.IO.pure(C.Bq.Pair.Pair(World.Bq.World, (__9 => C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__10 => Bq.Db)))), Tuple{w_0, Tuple{cs_7, db_1}}))); \{}}})))))))) : (@+w_0: World.Bq.World -> (@+db_1: Bq.Db -> (@+lg_2: Chan<C.Bq.String> -> (@+tag_3: C.Bq.String -> (@+ns_4: List<&1, U32> -> (@+text_5: C.Bq.String -> (@+cid_6: U32 -> (@+cs_7: List<&1, Bq.Conn> -> (@+___8: Bool -> IO(Sigma<&1, &1, World.Bq.World, (__9 => Sigma<&1, &1, List<&1, Bq.Conn>, (__10 => Bq.Db)>)>))))))))))}; apply_382(w_0, db_1, lg_2, tag_3, ns_4, text_5, cid_6, cs_7, Proto.Bq.is(tag_3, C.Bq.text("FAME")))); \{True: C.Bq.IO.bind(C.Bq.Pair.Pair(World.Bq.World, (__8 => List<&1, Bq.Conn>)), C.Bq.Pair.Pair(World.Bq.World, (__8 => C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__9 => Bq.Db)))), Bq.on_create(w_0, cs_7, db_1, cid_6, ns_4, lg_2), \{Tuple: (w4_8 => (cs4_9 => C.Bq.IO.pure(C.Bq.Pair.Pair(World.Bq.World, (__10 => C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__11 => Bq.Db)))), Tuple{w4_8, Tuple{cs4_9, db_1}}))); \{}}); \{}}})))))))) : (@+w_0: World.Bq.World -> (@+db_1: Bq.Db -> (@+lg_2: Chan<C.Bq.String> -> (@+tag_3: C.Bq.String -> (@+ns_4: List<&1, U32> -> (@+text_5: C.Bq.String -> (@+cid_6: U32 -> (@+cs_7: List<&1, Bq.Conn> -> (@+___8: Bool -> IO(Sigma<&1, &1, World.Bq.World, (__9 => Sigma<&1, &1, List<&1, Bq.Conn>, (__10 => Bq.Db)>)>))))))))))}; apply_381(w_0, db_1, lg_2, tag_3, ns_4, text_5, cid_6, cs_7, Proto.Bq.is(tag_3, C.Bq.text("CREATE")))); \{True: C.Bq.IO.bind(C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__8 => Bq.Db)), C.Bq.Pair.Pair(World.Bq.World, (__8 => C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__9 => Bq.Db)))), Bq.on_shop(cs_7, db_1, cid_6, Bq.nth(ns_4, 0), Bq.nth(ns_4, 1)), \{Tuple: (cs3_8 => (db3_9 => C.Bq.IO.pure(C.Bq.Pair.Pair(World.Bq.World, (__10 => C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__11 => Bq.Db)))), Tuple{w_0, Tuple{cs3_8, db3_9}}))); \{}}); \{}}})))))))) : (@+w_0: World.Bq.World -> (@+db_1: Bq.Db -> (@+lg_2: Chan<C.Bq.String> -> (@+tag_3: C.Bq.String -> (@+ns_4: List<&1, U32> -> (@+text_5: C.Bq.String -> (@+cid_6: U32 -> (@+cs_7: List<&1, Bq.Conn> -> (@+___8: Bool -> IO(Sigma<&1, &1, World.Bq.World, (__9 => Sigma<&1, &1, List<&1, Bq.Conn>, (__10 => Bq.Db)>)>))))))))))}; apply_380(w_0, db_1, lg_2, tag_3, ns_4, text_5, cid_6, cs_7, Proto.Bq.is(tag_3, C.Bq.text("SHOP")))); \{True: C.Bq.IO.bind(List<&1, Bq.Conn>, C.Bq.Pair.Pair(World.Bq.World, (__8 => C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__9 => Bq.Db)))), Bq.on_hello(w_0, cs_7, db_1, cid_6, text_5, lg_2), (cs2_8 => C.Bq.IO.pure(C.Bq.Pair.Pair(World.Bq.World, (__9 => C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__10 => Bq.Db)))), Tuple{w_0, Tuple{cs2_8, db_1}}))); \{}}})))))))) : (@+w_0: World.Bq.World -> (@+db_1: Bq.Db -> (@+lg_2: Chan<C.Bq.String> -> (@+tag_3: C.Bq.String -> (@+ns_4: List<&1, U32> -> (@+text_5: C.Bq.String -> (@+cid_6: U32 -> (@+cs_7: List<&1, Bq.Conn> -> (@+___8: Bool -> IO(Sigma<&1, &1, World.Bq.World, (__9 => Sigma<&1, &1, List<&1, Bq.Conn>, (__10 => Bq.Db)>)>))))))))))}; apply_379(w_0, db_1, lg_2, tag_5, ns_6, text_7, cid_3, cs_4, Proto.Bq.is(tag_5, C.Bq.text("HELLO"))))))); \{}}))))) : (@+w_0: World.Bq.World -> (@+db_1: Bq.Db -> (@+lg_2: Chan<C.Bq.String> -> (@+cid_3: U32 -> (@+cs_4: List<&1, Bq.Conn> -> (@+___5: Proto.Bq.Msg -> IO(Sigma<&1, &1, World.Bq.World, (__6 => Sigma<&1, &1, List<&1, Bq.Conn>, (__7 => Bq.Db)>)>)))))))}; apply_378(w_0, db_2, lg_5, cid_3, cs_1, m_6)))))))))

@unsafe
def Bq.on_gone():
  (w_0 => (cs_1 => (cid_2 => (lg_3 => (+apply_392 = {(w_0 => (lg_1 => \{Tuple: (fst_2 => (snd_3 => (+apply_393 = {(w_0 => (fst_1 => (lg_2 => \{Fail: (error_3 => C.Bq.IO.pure(C.Bq.Pair.Pair(World.Bq.World, (__4 => List<&1, Bq.Conn>)), Tuple{w_0, fst_1})); \{Done: (value_3 => (+apply_394 = {(w_0 => (fst_1 => (lg_2 => \{Net.Connection.Record: (cid_3 => (st_4 => (pid_5 => (out_6 => (name_7 => C.Bq.IO.bind(Bool, C.Bq.Pair.Pair(World.Bq.World, (__8 => List<&1, Bq.Conn>)), C.Bq.Chan.close(C.Bq.String, out_6), (b_8 => (+w2_9 = World.Bq.del_plr(w_0, pid_5); C.Bq.IO.bind(Unit, C.Bq.Pair.Pair(World.Bq.World, (__10 => List<&1, Bq.Conn>)), Bq.send_all(fst_1, Proto.Bq.wire_enc(C.Bq.text("EV"), Nil{}, Support.Bq.List.concat(Char, name_7, C.Bq.text(" left.")))), (__10 => C.Bq.IO.bind(Unit, C.Bq.Pair.Pair(World.Bq.World, (__11 => List<&1, Bq.Conn>)), Bq.chan_push(lg_2, Support.Bq.List.concat(Char, C.Bq.text("gone: #"), Support.Bq.List.concat(Char, Support.Bq.U32.show(cid_3), Support.Bq.List.concat(Char, C.Bq.text(" "), name_7)))), (__11 => C.Bq.IO.pure(C.Bq.Pair.Pair(World.Bq.World, (__12 => List<&1, Bq.Conn>)), Tuple{w2_9, fst_1}))))))))))))); \{}}))) : (@+w_0: World.Bq.World -> (@+fst_1: List<&1, Bq.Conn> -> (@+lg_2: Chan<C.Bq.String> -> (@+___3: Bq.Conn -> IO(Sigma<&1, &1, World.Bq.World, (__4 => List<&1, Bq.Conn>)>)))))}; apply_394(w_0, fst_1, lg_2, value_3))); \{}}}))) : (@+w_0: World.Bq.World -> (@+fst_1: List<&1, Bq.Conn> -> (@+lg_2: Chan<C.Bq.String> -> (@+___3: Result<&1, &1, Unit, Bq.Conn> -> IO(Sigma<&1, &1, World.Bq.World, (__4 => List<&1, Bq.Conn>)>)))))}; apply_393(w_0, fst_2, lg_1, snd_3)))); \{}})) : (@+w_0: World.Bq.World -> (@+lg_1: Chan<C.Bq.String> -> (@+___2: Sigma<&1, &1, List<&1, Bq.Conn>, (__2 => Result<&1, &1, Unit, Bq.Conn>)> -> IO(Sigma<&1, &1, World.Bq.World, (__3 => List<&1, Bq.Conn>)>))))}; apply_392(w_0, lg_3, Bq.take_conn(cid_2, cs_1)))))))

@unsafe
def Bq.drain():
  (word => C.Bq.word_case((@+w_1: World.Bq.World -> (@+cs_2: List<&1, Bq.Conn> -> (@+ncid_3: U32 -> (@+db_4: Bq.Db -> (@+inbox_5: Chan<Bq.InM> -> (@+lg_6: Chan<C.Bq.String> -> (@+flag_7: U32 -> IO(C.Bq.Pair.Pair(World.Bq.World, (__8 => C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__9 => C.Bq.Pair.Pair(U32, (__10 => C.Bq.Pair.Pair(Bq.Db, (__11 => U32)))))))))))))))), word, 0, (unit => (w_0 => (cs_1 => (ncid_2 => (db_3 => (inbox_4 => (lg_5 => (flag_6 => C.Bq.IO.pure(C.Bq.Pair.Pair(World.Bq.World, (__7 => C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__8 => C.Bq.Pair.Pair(U32, (__9 => C.Bq.Pair.Pair(Bq.Db, (__10 => U32)))))))), Tuple{w_0, Tuple{cs_1, Tuple{ncid_2, Tuple{db_3, flag_6}}}}))))))))), (k2_0 => (w_1 => (cs_2 => (ncid_3 => (db_4 => (inbox_5 => (lg_6 => (flag_7 => C.Bq.IO.bind(Support.Bq.Maybe(Bq.InM), C.Bq.Pair.Pair(World.Bq.World, (__8 => C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__9 => C.Bq.Pair.Pair(U32, (__10 => C.Bq.Pair.Pair(Bq.Db, (__11 => U32)))))))), C.Bq.Chan.poll(Bq.InM, inbox_5), \{Fail: (u_8 => C.Bq.IO.pure(C.Bq.Pair.Pair(World.Bq.World, (__9 => C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__10 => C.Bq.Pair.Pair(U32, (__11 => C.Bq.Pair.Pair(Bq.Db, (__12 => U32)))))))), Tuple{w_1, Tuple{cs_2, Tuple{ncid_3, Tuple{db_4, flag_7}}}})); \{Done: \{Bq.InM.InJoin: (sock_8 => C.Bq.IO.bind(C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__9 => U32)), C.Bq.Pair.Pair(World.Bq.World, (__9 => C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__10 => C.Bq.Pair.Pair(U32, (__11 => C.Bq.Pair.Pair(Bq.Db, (__12 => U32)))))))), Bq.on_join(cs_2, ncid_3, sock_8, inbox_5, lg_6), \{Tuple: (cs2_9 => (ncid2_10 => Bq.drain(k2_0, w_1, cs2_9, ncid2_10, db_4, inbox_5, lg_6, flag_7))); \{}})); \{Bq.InM.InLine: (cid_8 => (line_9 => C.Bq.IO.bind(C.Bq.Pair.Pair(World.Bq.World, (__10 => C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__11 => Bq.Db)))), C.Bq.Pair.Pair(World.Bq.World, (__10 => C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__11 => C.Bq.Pair.Pair(U32, (__12 => C.Bq.Pair.Pair(Bq.Db, (__13 => U32)))))))), Bq.on_line(w_1, cs_2, db_4, cid_8, line_9, lg_6), \{Tuple: (w3_10 => \{Tuple: (cs3_11 => (db3_12 => Bq.drain(k2_0, w3_10, cs3_11, ncid_3, db3_12, inbox_5, lg_6, flag_7))); \{}}); \{}}))); \{Bq.InM.InGone: (cid_8 => C.Bq.IO.bind(C.Bq.Pair.Pair(World.Bq.World, (__9 => List<&1, Bq.Conn>)), C.Bq.Pair.Pair(World.Bq.World, (__9 => C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__10 => C.Bq.Pair.Pair(U32, (__11 => C.Bq.Pair.Pair(Bq.Db, (__12 => U32)))))))), Bq.on_gone(w_1, cs_2, cid_8, lg_6), \{Tuple: (w4_9 => (cs4_10 => Bq.drain(k2_0, w4_9, cs4_10, ncid_3, db_4, inbox_5, lg_6, flag_7))); \{}})); \{Bq.InM.InCtl: (code_8 => (+apply_395 = {(k2_0 => (w_1 => (cs_2 => (ncid_3 => (db_4 => (inbox_5 => (lg_6 => (word => C.Bq.word_case(IO(Sigma<&1, &1, World.Bq.World, (__8 => Sigma<&1, &1, List<&1, Bq.Conn>, (__9 => Sigma<&1, &1, U32, (__10 => Sigma<&1, &1, Bq.Db, (__11 => U32)>)>)>)>), word, 0, (unit => Bq.drain(k2_0, w_1, cs_2, ncid_3, db_4, inbox_5, lg_6, 1)), (_670_7 => Bq.drain(k2_0, w_1, cs_2, ncid_3, db_4, inbox_5, lg_6, 2)), 0))))))))) : (@+k2_0: U32 -> (@+w_1: World.Bq.World -> (@+cs_2: List<&1, Bq.Conn> -> (@+ncid_3: U32 -> (@+db_4: Bq.Db -> (@+inbox_5: Chan<Bq.InM> -> (@+lg_6: Chan<C.Bq.String> -> (@+___7: U32 -> IO(Sigma<&1, &1, World.Bq.World, (__8 => Sigma<&1, &1, List<&1, Bq.Conn>, (__9 => Sigma<&1, &1, U32, (__10 => Sigma<&1, &1, Bq.Db, (__11 => U32)>)>)>)>)))))))))}; apply_395(k2_0, w_1, cs_2, ncid_3, db_4, inbox_5, lg_6, C.Bq.bit(U32.is_eq(code_8, 1))))); \{}}}}}; \{}}}))))))))), 1))

def Bq.set_now(world,now): Clock.WorldClock.set(world,now)

@unsafe
def Bq.status_names():
  \{Nil: Nil{}; \{Con: \{P.Players.State: (pid_0 => (cid_1 => (hero_2 => (pos_3 => (vit_4 => (style_5 => (qst_6 => (meta_7 => (rest_8 => Support.Bq.List.concat(Char, Support.Bq.String.flatten([C.Bq.text("  "), World.Bq.pm_name(meta_7), C.Bq.text(" Lv."), Support.Bq.U32.show(World.Bq.hero_lv(hero_2)), C.Bq.text(" @"), Data.Bq.zone_name(World.Bq.pos_zone(pos_3))]), Bq.status_names(rest_8))))))))))); \{}}; \{}}}

@unsafe
def Bq.status_of():
  (w_0 => (+ps_1 = Bq.plrs_of_w(w_0); Support.Bq.List.concat(Char, Support.Bq.U32.show(U32.from_nat(P.Players.length(ps_1))), Support.Bq.List.concat(Char, C.Bq.text(" online"), Bq.status_names(ps_1)))))

@unsafe
def Bq.maybe_status():
  \{Terrain.Terrain.World: (wm_0 => (plrs_1 => (mobs_2 => (maps_3 => (stat_4 => (+apply_396 = {(stat_0 => (wm_1 => (plrs_2 => (mobs_3 => (maps_4 => (word => C.Bq.word_case(IO(Unit), word, 0, (unit => C.Bq.IO.pure(Unit, Unit{})), (_691_5 => Bq.chan_push(stat_0, Bq.status_of(Terrain.Terrain.World{wm_1, plrs_2, mobs_3, maps_4}))), 0))))))) : (@+stat_0: Chan<C.Bq.String> -> (@+wm_1: World.Bq.WMeta -> (@+plrs_2: List<&2, World.Bq.Plr> -> (@+mobs_3: List<&2, World.Bq.Mob> -> (@+maps_4: List<&2,List<&2,U32>> -> (@+___5: U32 -> IO(Unit)))))))}; apply_396(stat_4, wm_0, plrs_1, mobs_2, maps_3, C.Bq.bit(U32.is_eq((World.Bq.wm_tick(wm_0) % 25 : U32), 0))))))))); \{}}

@unsafe
def Bq.award_coins():
  (db_0 => \{Nil: (rank_1 => db_0); \{Con: \{Tuple: (sc_1 => (nm_2 => (rest_3 => (rank_4 => (+apply_397 = {(db_0 => (rank_1 => (sc_2 => (rest_3 => \{Bq.Prof.Prof: (name_4 => (coins_5 => (hats_6 => (capes_7 => (+db2_8 = Bq.db_put_prof(db_0, Bq.Prof.Prof{name_4, ((coins_5 + Data.Bq.rank_coins(rank_1) : U32) + (sc_2 / 12 : U32) : U32), hats_6, capes_7}); Bq.award_coins(db2_8, rest_3, (rank_1 + 1 : U32))))))); \{}})))) : (@+db_0: Bq.Db -> (@+rank_1: U32 -> (@+sc_2: U32 -> (@+rest_3: List<&1, C.Bq.Pair.Pair(U32, (__3 => C.Bq.String))> -> (@+___4: Bq.Prof -> Bq.Db)))))}; apply_397(db_0, rank_4, sc_1, rest_3, Bq.db_prof(db_0, nm_2))))))); \{}}; \{}}})

@unsafe
def Bq.fp_of_plr():
  \{P.Players.State: (pid_0 => (cid_1 => (hero_2 => (pos_3 => (vit_4 => \{P.Players.Style: (skin_5 => (hairs_6 => (hairc_7 => (shirt_8 => (hat_9 => (cape_10 => (qst_11 => \{P.Players.Meta: (field_398 => field_399 => field_400 => stored_field_401 => (+field_401 = P.Players.text_name(stored_field_401); (+apply_402 = {(skin_0 => (hairs_1 => (hairc_2 => (shirt_3 => (hat_4 => (cape_5 => \{Game.Bq.Hero.Hero: (inv_6 => (wea_7 => (arm_8 => (hel_9 => (chm_10 => (gold_11 => (lv_12 => (str_13 => (agi_14 => (vit_15 => (pts_16 => (score_17 => (kills_18 => (found_19 => (name_20 => Bq.FP.FP{name_20, Support.Bq.Nat.to_u32(lv_12), score_17, skin_0, hairs_1, hairc_2, shirt_3, hat_4, cape_5, World.Bq.slot_kind(wea_7), World.Bq.slot_kind(arm_8), World.Bq.slot_kind(hel_9), World.Bq.slot_kind(chm_10)}))))))))))))))); \{}})))))) : (@+skin_0: U32 -> (@+hairs_1: U32 -> (@+hairc_2: U32 -> (@+shirt_3: U32 -> (@+hat_4: U32 -> (@+cape_5: U32 -> (@+___6: Game.Bq.Hero -> (@+__7: U32 -> (@+__8: U32 -> (@+__9: U32 -> (@+__10: List<&1, Char> -> Bq.FP)))))))))))}; apply_402(skin_5, hairs_6, hairc_7, shirt_8, hat_9, cape_10, hero_2, field_398, field_399, field_400, field_401)))); \{}}))))))); \{}}))))); \{}}

@unsafe
def Bq.fps_of():
  \{Nil: Nil{}; \{Con: (p_0 => (rest_1 => Con{Bq.fp_of_plr(p_0), Bq.fps_of(rest_1)})); \{}}}

@unsafe
def Bq.send_all_lines():
  (cs_0 => \{Nil: C.Bq.IO.pure(Unit, Unit{}); \{Con: (l_1 => (rest_2 => C.Bq.IO.bind(Unit, Unit, Bq.send_all(cs_0, l_1), (__3 => Bq.send_all_lines(cs_0, rest_2))))); \{}}})

@unsafe
def Bq.run_end():
  \{Terrain.Terrain.World: \{S.Simulation.Meta: (phase_0 => (wno_1 => (seed_2 => (tick_3 => (t0_4 => (now_5 => (sigils_6 => (fame_t_7 => (nextpid_8 => (nextmid_9 => (plrs_10 => (mobs_11 => (maps_12 => (cs_13 => (db_14 => (lg_15 => (+dur_16 = (now_5 - t0_4 : U32); (+rb_17 = World.Bq.ranked(World.Bq.score_names(plrs_10)); (+db1_18 = Bq.award_coins(db_14, rb_17, 0); (+apply_403 = {(wno_0 => (dur_1 => (plrs_2 => (cs_3 => (lg_4 => \{Bq.Db.Db: (wno_5 => (profs_6 => (runs_7 => (+db2_8 = {Bq.Db.Db{(wno_0 + 1 : U32), profs_6, Con{Bq.Run.Run{wno_0, dur_1, Bq.fps_of(plrs_2)}, runs_7}} : Bq.Db}; C.Bq.IO.bind(Unit, Bq.Db, Bq.db_save(db2_8), (__9 => C.Bq.IO.bind(Unit, Bq.Db, Bq.send_all_lines(cs_3, Bq.fame_lines(db2_8)), (__10 => C.Bq.IO.bind(Unit, Bq.Db, Bq.chan_push(lg_4, Support.Bq.List.concat(Char, C.Bq.text("RUN "), Support.Bq.List.concat(Char, Support.Bq.U32.show(wno_0), Support.Bq.List.concat(Char, C.Bq.text(" COMPLETE in "), Support.Bq.List.concat(Char, Support.Bq.U32.show(dur_1), Support.Bq.List.concat(Char, C.Bq.text("s -- hall of fame open, restart in "), Support.Bq.List.concat(Char, Support.Bq.U32.show(Data.Bq.RESTART_SECS), C.Bq.text("s")))))))), (__11 => C.Bq.IO.pure(Bq.Db, db2_8))))))))))); \{}}))))) : (@+wno_0: U32 -> (@+dur_1: U32 -> (@+plrs_2: List<&2, World.Bq.Plr> -> (@+cs_3: List<&1, Bq.Conn> -> (@+lg_4: Chan<C.Bq.String> -> (@+___5: Bq.Db -> IO(Bq.Db)))))))}; apply_403(wno_1, dur_16, plrs_10, cs_13, lg_15, db1_18))))))))))))))))))))); \{}}; \{}}

@unsafe
def Bq.maybe_run_end():
  (oldphase_0 => (w_1 => (cs_2 => (db_3 => (lg_4 => (+apply_404 = {(db_0 => (w_1 => (cs_2 => (lg_3 => (word => C.Bq.word_case(IO(Bq.Db), word, 0, (unit => C.Bq.IO.pure(Bq.Db, db_0)), (_795_4 => Bq.run_end(w_1, cs_2, db_0, lg_3)), 0)))))) : (@+db_0: Bq.Db -> (@+w_1: World.Bq.World -> (@+cs_2: List<&1, Bq.Conn> -> (@+lg_3: Chan<C.Bq.String> -> (@+___4: U32 -> IO(Bq.Db))))))}; apply_404(db_3, w_1, cs_2, lg_4, C.Bq.word_and(C.Bq.bit(U32.is_eq(oldphase_0, 1)), C.Bq.bit(U32.is_eq(Bq.phase_of_w(w_1), 2))))))))))

@unsafe
def Bq.readd_plrs(world,players): Rebuild.Rebuild.world(players,world)

@unsafe
def Bq.pid_of_cid(players,cid,fallback): Rebinding.Rebinding.lookup(players,cid,fallback)

@unsafe
def Bq.rebind_conns(connections,players): Net.Connection.rebind(connections,players)

@unsafe
def Bq.restart_ready(result: ChannelRestart.ChannelRestart.Result,+number: U32,db: Bq.Db,log: Chan<C.Bq.String>) -> IO(World.Bq.World & (List<&1,Bq.Conn> & Bq.Db)):
  match result:
    case ChannelRestart.ChannelRestart.Result{world,connections}:
      match db:
        case Bq.Db.Db{old_number,profiles,runs}:
          +world = world
          +connections = connections
          +updated = {Bq.Db.Db{number,profiles,runs} : Bq.Db}
          do IO<World.Bq.World & (List<&1,Bq.Conn> & Bq.Db)>:
            Unit <- Bq.db_save(updated)
            Unit <- Bq.send_all(connections,Proto.Bq.wire_enc(C.Bq.text("START"),[number],Nil{}))
            Unit <- Bq.send_all_lines(connections,Con{World.Bq.zone_line(Bq.maps_of_w(world),0),Bq.plr_name_lines(Bq.plrs_of_w(world))})
            Unit <- Bq.send_all(connections,Proto.Bq.wire_enc(C.Bq.text("EV"),Nil{},Support.Bq.List.concat(Char,C.Bq.text("A NEW WORLD DAWNS (world "),Support.Bq.List.concat(Char,Support.Bq.U32.show(number),C.Bq.text(")")))))
            Unit <- Bq.chan_push(log,Support.Bq.List.concat(Char,C.Bq.text("world "),Support.Bq.List.concat(Char,Support.Bq.U32.show(number),C.Bq.text(" started"))))
            IO.pure(World.Bq.World & (List<&1,Bq.Conn> & Bq.Db),Tuple{world,Tuple{connections,updated}})

@unsafe
def Bq.restart_world(world,connections,db,log):
  +before = Terrain.Terrain.simulation(world)
  Bq.restart_ready(ChannelRestart.ChannelRestart.restart(before,connections),U32.add(ChannelRestart.ChannelRestart.number(S.Simulation.meta(before)),1),db,log)

@unsafe
def Bq.fame_t_of_w():
  \{Terrain.Terrain.World: \{S.Simulation.Meta: (phase_0 => (wno_1 => (seed_2 => (tick_3 => (t0_4 => (now_5 => (sigils_6 => (fame_t_7 => (nextpid_8 => (nextmid_9 => (plrs_10 => (mobs_11 => (maps_12 => fame_t_7))))))))))))); \{}}; \{}}

@unsafe
def Bq.loop_stop():
  (db1_0 => (lg_1 => C.Bq.IO.bind(Unit, Unit, Bq.db_save(db1_0), (__2 => C.Bq.IO.bind(Unit, Unit, Bq.chan_push(lg_1, C.Bq.text("server stopped")), (__3 => C.Bq.IO.pure(Unit, Unit{})))))))

@unsafe
def Bq.game_loop():
  (word => C.Bq.word_case((@+w_1: World.Bq.World -> (@+cs_2: List<&1, Bq.Conn> -> (@+ncid_3: U32 -> (@+db_4: Bq.Db -> (@+inbox_5: Chan<Bq.InM> -> (@+lg_6: Chan<C.Bq.String> -> (@+stat_7: Chan<C.Bq.String> -> IO(Unit)))))))), word, 0, (unit => (w_0 => (cs_1 => (ncid_2 => (db_3 => (inbox_4 => (lg_5 => (stat_6 => C.Bq.IO.pure(Unit, Unit{}))))))))), (f_0 => (w_1 => (cs_2 => (ncid_3 => (db_4 => (inbox_5 => (lg_6 => (stat_7 => C.Bq.IO.bind(Unit, Unit, C.Bq.IO.sleep(Data.Bq.TICK_MS), (__8 => C.Bq.IO.bind(U32, Unit, C.Bq.IO.now, (now_9 => (+oldphase_10 = Bq.phase_of_w(w_1); C.Bq.IO.bind(C.Bq.Pair.Pair(World.Bq.World, (__11 => C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__12 => C.Bq.Pair.Pair(U32, (__13 => C.Bq.Pair.Pair(Bq.Db, (__14 => U32)))))))), Unit, Bq.drain(64, Bq.set_now(w_1, now_9), cs_2, ncid_3, db_4, inbox_5, lg_6, 0), \{Tuple: (w1_11 => \{Tuple: (cs1_12 => \{Tuple: (ncid1_13 => \{Tuple: (db1_14 => (flag_15 => (+apply_532 = {(cs1_0 => (lg_1 => (stat_2 => (oldphase_3 => (db1_4 => (f_5 => (ncid1_6 => (inbox_7 => (flag_8 => (now_9 => (w1_10 => (word => C.Bq.word_case(IO(Unit), word, 0, (unit => (+apply_533 = {(cs1_0 => (lg_1 => (stat_2 => (oldphase_3 => (db1_4 => (f_5 => (ncid1_6 => (inbox_7 => (flag_8 => (now_9 => \{Tuple: (fst_10 => (snd_11 => C.Bq.IO.bind(Unit, Unit, Bq.route_outs(snd_11, cs1_0, Bq.cid_zones(Bq.plrs_of_w(fst_10)), lg_1), (__12 => C.Bq.IO.bind(Unit, Unit, Bq.maybe_status(fst_10, stat_2), (__13 => C.Bq.IO.bind(Bq.Db, Unit, Bq.maybe_run_end(oldphase_3, fst_10, cs1_0, db1_4, lg_1), (db2_14 => (+apply_534 = {(f_0 => (fst_1 => (cs1_2 => (ncid1_3 => (db2_4 => (inbox_5 => (lg_6 => (stat_7 => (word => C.Bq.word_case(IO(Unit), word, 0, (unit => Bq.game_loop(f_0, fst_1, cs1_2, ncid1_3, db2_4, inbox_5, lg_6, stat_7)), (_823_8 => C.Bq.IO.bind(C.Bq.Pair.Pair(World.Bq.World, (__9 => C.Bq.Pair.Pair(List<&1, Bq.Conn>, (__10 => Bq.Db)))), Unit, Bq.restart_world(fst_1, cs1_2, db2_4, lg_6), \{Tuple: (w3_9 => \{Tuple: (cs3_10 => (db3_11 => Bq.game_loop(f_0, w3_9, cs3_10, ncid1_3, db3_11, inbox_5, lg_6, stat_7))); \{}}); \{}})), 0)))))))))) : (@+f_0: U32 -> (@+fst_1: World.Bq.World -> (@+cs1_2: List<&1, Bq.Conn> -> (@+ncid1_3: U32 -> (@+db2_4: Bq.Db -> (@+inbox_5: Chan<Bq.InM> -> (@+lg_6: Chan<C.Bq.String> -> (@+stat_7: Chan<C.Bq.String> -> (@+___8: U32 -> IO(Unit))))))))))}; apply_534(f_5, fst_10, cs1_0, ncid1_6, db2_14, inbox_7, lg_1, stat_2, C.Bq.word_or(C.Bq.bit(U32.is_eq(flag_8, 2)), C.Bq.word_and(C.Bq.bit(U32.is_eq(Bq.phase_of_w(fst_10), 2)), C.Bq.bit(U32.is_ge((now_9 - Bq.fame_t_of_w(fst_10) : U32), Data.Bq.RESTART_SECS)))))))))))))); \{}})))))))))) : (@+cs1_0: List<&1, Bq.Conn> -> (@+lg_1: Chan<C.Bq.String> -> (@+stat_2: Chan<C.Bq.String> -> (@+oldphase_3: U32 -> (@+db1_4: Bq.Db -> (@+f_5: U32 -> (@+ncid1_6: U32 -> (@+inbox_7: Chan<Bq.InM> -> (@+flag_8: (__8 => U32)(db1_4) -> (@+now_9: U32 -> (@+___10: Sigma<&1, &1, World.Bq.World, (__10 => List<&1, World.Bq.OutL>)> -> IO(Unit))))))))))))}; apply_533(cs1_0, lg_1, stat_2, oldphase_3, db1_4, f_5, ncid1_6, inbox_7, flag_8, now_9, World.Bq.tick_world(w1_10)))), (_826_11 => Bq.loop_stop(db1_4, lg_1)), 0))))))))))))) : (@+cs1_0: List<&1, Bq.Conn> -> (@+lg_1: Chan<C.Bq.String> -> (@+stat_2: Chan<C.Bq.String> -> (@+oldphase_3: U32 -> (@+db1_4: Bq.Db -> (@+f_5: U32 -> (@+ncid1_6: U32 -> (@+inbox_7: Chan<Bq.InM> -> (@+flag_8: (__8 => U32)(db1_4) -> (@+now_9: U32 -> (@+w1_10: World.Bq.World -> (@+___11: U32 -> IO(Unit)))))))))))))}; apply_532(cs1_12, lg_6, stat_7, oldphase_10, db1_14, f_0, ncid1_13, inbox_5, flag_15, now_9, w1_11, C.Bq.bit(U32.is_eq(flag_15, 1)))))); \{}}); \{}}); \{}}); \{}})))))))))))))), 1))

@unsafe
def Bq.server_start():
  (port_0 => (lg_1 => (ctl_2 => (stat_3 => C.Bq.IO.bind(Bq.Db, Unit, Bq.db_load, (db_4 => C.Bq.IO.bind(U32, Unit, C.Bq.IO.now, (now_5 => C.Bq.IO.bind(Result<&1, &1, C.Bq.Pair.Pair(U32, (__6 => C.Bq.String)), C.Bq.TCP>, Unit, C.Bq.TCP.listen(port_0), \{Fail: \{Tuple: (code_6 => (emsg_7 => C.Bq.IO.bind(Unit, Unit, Bq.chan_push(lg_1, Support.Bq.List.concat(Char, C.Bq.text("LISTEN FAILED: "), emsg_7)), (__8 => C.Bq.IO.pure(Unit, Unit{}))))); \{}}; \{Done: (srv_6 => C.Bq.IO.bind(Chan<Bq.InM>, Unit, C.Bq.Chan.new(Bq.InM, 512), (inbox_7 => C.Bq.IO.bind(Unit, Unit, C.Bq.IO.spawn(Bq.acceptor(Support.Bq.U32.MAX_VALUE, srv_6, inbox_7)), (__8 => C.Bq.IO.bind(Unit, Unit, C.Bq.IO.spawn(Bq.ctl_pump(Support.Bq.U32.MAX_VALUE, ctl_2, inbox_7)), (__9 => (+apply_535 = {(lg_0 => (port_1 => (now_2 => (inbox_3 => (stat_4 => \{Bq.Db.Db: (wno_5 => (profs_6 => (runs_7 => C.Bq.IO.bind(U32, Unit, C.Bq.IO.rand_word, (seed_8 => C.Bq.IO.bind(Unit, Unit, Bq.chan_push(lg_0, Support.Bq.List.concat(Char, C.Bq.text("server listening on port "), Support.Bq.List.concat(Char, Support.Bq.U32.show(port_1), Support.Bq.List.concat(Char, C.Bq.text(" (world "), Support.Bq.List.concat(Char, Support.Bq.U32.show(wno_5), C.Bq.text(")")))))), (__9 => Bq.game_loop(Support.Bq.U32.MAX_VALUE, World.Bq.fresh_world(wno_5, seed_8, now_2), Nil{}, 1, Bq.Db.Db{wno_5, profs_6, runs_7}, inbox_3, lg_0, stat_4)))))))); \{}}))))) : (@+lg_0: Chan<C.Bq.String> -> (@+port_1: U32 -> (@+now_2: U32 -> (@+inbox_3: Chan<Bq.InM> -> (@+stat_4: Chan<C.Bq.String> -> (@+___5: Bq.Db -> IO(Unit)))))))}; apply_535(lg_1, port_0, now_5, inbox_7, stat_3, db_4))))))))); \{}}})))))))))
