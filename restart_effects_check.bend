import Base
import ./main.bend as Application
import ./server.bend as Live
import ./connection.bend as Net
import ./channel_restart.bend as CR
import ./restart.bend as R
import ./restart_check.bend as Check
import ./disconnect_server_check.bend as Fixtures
import ./sessions.bend as Sess
import ./sessions_check.bend as Names
import ./players.bend as P
import ./players_check.bend as Test
import ./creation_check.bend as F
import ./simulation.bend as S
import ./terrain.bend as Terrain
import ./world.bend as World
import ./compat.bend as C
import ./proto.bend as Proto
import ./support.bend as Support

law previous_restart:
  (@+w_0: World.Bq.World -> (@+cs_1: List<&1, Live.Bq.Conn> -> (@+db_2: Live.Bq.Db -> (@+lg_3: Chan<C.Bq.String> -> IO(C.Bq.Pair.Pair(World.Bq.World, (__4 => C.Bq.Pair.Pair(List<&1, Live.Bq.Conn>, (__5 => Live.Bq.Db)))))))))

@unsafe
def previous_restart():
  \{Terrain.Terrain.World: \{S.Simulation.Meta: (phase_0 => (wno_1 => (seed_2 => (tick_3 => (t0_4 => (now_5 => (sigils_6 => (fame_t_7 => (nextpid_8 => (nextmid_9 => (plrs_10 => (mobs_11 => (maps_12 => (cs_13 => (db_14 => (lg_15 => (+nseed_16 = World.Bq.hash2(seed_2, now_5); (+w1_17 = World.Bq.fresh_world((wno_1 + 1 : U32), nseed_16, now_5); (+w2_18 = Live.Bq.readd_plrs(w1_17, plrs_10); (+cs2_19 = Live.Bq.rebind_conns(cs_13, Live.Bq.plrs_of_w(w2_18)); (+apply_448 = {(wno_0 => (w2_1 => (lg_2 => \{Live.Bq.Db.Db: (wno_3 => (profs_4 => (runs_5 => (cs2_6 => (+db2_7 = {Live.Bq.Db.Db{(wno_0 + 1 : U32), profs_4, runs_5} : Live.Bq.Db}; C.Bq.IO.bind(Unit, C.Bq.Pair.Pair(World.Bq.World, (__8 => C.Bq.Pair.Pair(List<&1, Live.Bq.Conn>, (__9 => Live.Bq.Db)))), Live.Bq.db_save(db2_7), (__8 => C.Bq.IO.bind(Unit, C.Bq.Pair.Pair(World.Bq.World, (__9 => C.Bq.Pair.Pair(List<&1, Live.Bq.Conn>, (__10 => Live.Bq.Db)))), Live.Bq.send_all(cs2_6, Proto.Bq.wire_enc(C.Bq.text("START"), [(wno_0 + 1 : U32)], Nil{})), (__9 => C.Bq.IO.bind(Unit, C.Bq.Pair.Pair(World.Bq.World, (__10 => C.Bq.Pair.Pair(List<&1, Live.Bq.Conn>, (__11 => Live.Bq.Db)))), Live.Bq.send_all_lines(cs2_6, Con{World.Bq.zone_line(Live.Bq.maps_of_w(w2_1), 0), Live.Bq.plr_name_lines(Live.Bq.plrs_of_w(w2_1))}), (__10 => C.Bq.IO.bind(Unit, C.Bq.Pair.Pair(World.Bq.World, (__11 => C.Bq.Pair.Pair(List<&1, Live.Bq.Conn>, (__12 => Live.Bq.Db)))), Live.Bq.send_all(cs2_6, Proto.Bq.wire_enc(C.Bq.text("EV"), Nil{}, Support.Bq.List.concat(Char, C.Bq.text("A NEW WORLD DAWNS (world "), Support.Bq.List.concat(Char, Support.Bq.U32.show((wno_0 + 1 : U32)), C.Bq.text(")"))))), (__11 => C.Bq.IO.bind(Unit, C.Bq.Pair.Pair(World.Bq.World, (__12 => C.Bq.Pair.Pair(List<&1, Live.Bq.Conn>, (__13 => Live.Bq.Db)))), Live.Bq.chan_push(lg_2, Support.Bq.List.concat(Char, C.Bq.text("world "), Support.Bq.List.concat(Char, Support.Bq.U32.show((wno_0 + 1 : U32)), C.Bq.text(" started")))), (__12 => C.Bq.IO.pure(C.Bq.Pair.Pair(World.Bq.World, (__13 => C.Bq.Pair.Pair(List<&1, Live.Bq.Conn>, (__14 => Live.Bq.Db)))), Tuple{w2_1, Tuple{cs2_6, db2_7}})))))))))))))))); \{}}))) : (@+wno_0: U32 -> (@+w2_1: World.Bq.World -> (@+lg_2: Chan<C.Bq.String> -> (@+___3: Live.Bq.Db -> (@+__4: List<&1, Live.Bq.Conn> -> IO(Sigma<&1, &1, World.Bq.World, (__5 => Sigma<&1, &1, List<&1, Live.Bq.Conn>, (__6 => Live.Bq.Db)>)>))))))}; apply_448(wno_1, w2_18, lg_15, db_14, cs2_19)))))))))))))))))))))); \{}}; \{}}


type ChannelData is Data:
  ChannelData{lines: List<&2,List<&2,Char>>,open: Bool}

type Disk is Data:
  Disk{contents: List<&2,Char>,ok: Bool}

type Snapshot is Data:
  Snapshot{game: R.Restart.Result,database: List<&2,Char>,disk: Disk,outputs: List<&2,ChannelData>,log: List<&2,List<&2,Char>>}

@unsafe
def drain(fuel: Nat,+out: Chan<C.Bq.String>) -> IO(List<&2,List<&2,Char>>):
  match fuel:
    case Zero{}: IO.pure(List<&2,List<&2,Char>>,Nil{})
    case Succ{left}:
      C.Bq.IO.bind(Result<&1,&1,Unit,C.Bq.String>,List<&2,List<&2,Char>>,C.Bq.Chan.poll(C.Bq.String,out),\{Fail: (unit => IO.pure(List<&2,List<&2,Char>>,Nil{})); \{Done: (line => C.Bq.IO.bind(List<&2,List<&2,Char>>,List<&2,List<&2,Char>>,drain(left,out),(rest => IO.pure(List<&2,List<&2,Char>>,Con{P.Players.share_name(line),rest})))); \{}}})

@unsafe
def channel_data(connection: Net.Connection.Record) -> IO(ChannelData):
  match connection:
    case Net.Connection.Record{cid,phase,pid,out,name}:
      +out = out
      do IO<ChannelData>:
        lines : List<&2,List<&2,Char>> <- drain(64n,out)
        accepted : Bool <- Chan.send(C.Bq.String,out,Nil{})
        Unit <- Chan.close(C.Bq.String,out)
        IO.pure(ChannelData,ChannelData{lines,accepted})

@unsafe
def channels_data(connections: List<&1,Net.Connection.Record>) -> IO(List<&2,ChannelData>):
  match connections:
    case Nil{}: IO.pure(List<&2,ChannelData>,Nil{})
    case Con{head,rest}:
      do IO<List<&2,ChannelData>>:
        first : ChannelData <- channel_data(head)
        later : List<&2,ChannelData> <- channels_data(rest)
        IO.pure(List<&2,ChannelData>,Con{first,later})

@unsafe
def disk_data(result: Result<&1,&1,U32 & C.Bq.String,C.Bq.String>) -> Disk:
  match result:
    case Fail{error}: Disk{Nil{},False{}}
    case Done{text}: Disk{P.Players.share_name(text),True{}}

@unsafe
def snapshot(result: World.Bq.World & (List<&1,Live.Bq.Conn> & Live.Bq.Db),+log: Chan<C.Bq.String>) -> IO(Snapshot):
  match result:
    case Tuple{world,rest}:
      match rest:
        case Tuple{connections,db}:
          +connections = connections
          do IO<Snapshot>:
            outputs : List<&2,ChannelData> <- channels_data(connections)
            logs : List<&2,List<&2,Char>> <- drain(64n,log)
            saved : Result<&1,&1,U32 & C.Bq.String,C.Bq.String> <- C.Bq.IO.read_text(Live.Bq.DB_PATH)
            Unit <- Chan.close(C.Bq.String,log)
            IO.pure(Snapshot,Snapshot{R.Restart.Result{world,Net.Connection.descriptors(connections)},P.Players.share_name(Live.Bq.db_enc(db)),disk_data(saved),outputs,logs})

@unsafe
def execute(previous: Bool,world: World.Bq.World,connections: List<&1,Live.Bq.Conn>,db: Live.Bq.Db,log: Chan<C.Bq.String>) -> IO(World.Bq.World & (List<&1,Live.Bq.Conn> & Live.Bq.Db)):
  match previous:
    case True{}: previous_restart(world,connections,db,log)
    case False{}: Live.Bq.restart_world(world,connections,db,log)

@unsafe
def capture_ready(previous: Bool,world: World.Bq.World,connections: List<&1,Live.Bq.Conn>,db: Live.Bq.Db,+log: Chan<C.Bq.String>) -> IO(Snapshot):
  do IO<Snapshot>:
    result : World.Bq.World & (List<&1,Live.Bq.Conn> & Live.Bq.Db) <- execute(previous,world,connections,db,log)
    snapshot(result,log)

@unsafe
def capture(previous: Bool,world: World.Bq.World,states: List<&2,Sess.Sessions.State>,db: Live.Bq.Db) -> IO(Snapshot):
  do IO<Snapshot>:
    connections : List<&1,Live.Bq.Conn> <- Fixtures.make_connections(states)
    log : Chan<C.Bq.String> <- Chan.new(C.Bq.String,128)
    capture_ready(previous,world,connections,db,log)

def same_lines(left: List<&2,List<&2,Char>>,right: List<&2,List<&2,Char>>) -> Bool:
  match left:
    case Nil{}:
      match right:
        case Nil{}: True{}
        case Con{head,rest}: False{}
    case Con{head,rest}:
      match right:
        case Nil{}: False{}
        case Con{other,later}: Bool.and(Sess.Sessions.name_eq(head,other),same_lines(rest,later))

def same_channel(left: ChannelData,right: ChannelData) -> Bool:
  match left:
    case ChannelData{lines,open}:
      match right:
        case ChannelData{other,other_open}: Bool.and(open,Bool.and(other_open,same_lines(lines,other)))

def same_channels(left: List<&2,ChannelData>,right: List<&2,ChannelData>) -> Bool:
  match left:
    case Nil{}:
      match right:
        case Nil{}: True{}
        case Con{head,rest}: False{}
    case Con{head,rest}:
      match right:
        case Nil{}: False{}
        case Con{other,later}: Bool.and(same_channel(head,other),same_channels(rest,later))

def disk_matches(disk: Disk,expected: List<&2,Char>) -> Bool:
  match disk:
    case Disk{contents,ok}: Bool.and(ok,Sess.Sessions.name_eq(contents,expected))

def same_snapshot(left: Snapshot,right: Snapshot) -> Bool:
  match left:
    case Snapshot{game,database,disk,outputs,log}:
      match right:
        case Snapshot{other,other_database,other_disk,other_outputs,other_log}:
          +database = database
          +other_database = other_database
          Bool.and(Check.same(game,other),Bool.and(Sess.Sessions.name_eq(database,other_database),Bool.and(disk_matches(disk,database),Bool.and(disk_matches(other_disk,other_database),Bool.and(same_channels(outputs,other_outputs),same_lines(log,other_log))))))

@unsafe
def database() -> Live.Bq.Db:
  Live.Bq.Db.Db{77,[Live.Bq.Prof.Prof{C.Bq.text("Étoile"),123,5,9},Live.Bq.Prof.Prof{C.Bq.text("Bob"),41,2,4}],[Live.Bq.Run.Run{4,95,[Live.Bq.FP.FP{C.Bq.text("Ada"),3,456,1,2,3,4,5,6,7,8,9,10}]}]}

def world(number: U32,seed: U32,now: U32,players: List<&2,P.Players.State>) -> World.Bq.World:
  Terrain.Terrain.world([[9,8],[7,6]],S.Simulation.State{S.Simulation.Meta{2,number,seed,33,44,now,7,66,4294967295,88},players,Nil{}})

@unsafe
def checked(label: String,+before: World.Bq.World,+states: List<&2,Sess.Sessions.State>) -> IO(Unit):
  do IO<Unit>:
    old : Snapshot <- capture(True{},before,states,database)
    next : Snapshot <- capture(False{},before,states,database)
    Test.verdict(label,same_snapshot(old,next))

@unsafe
def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- checked("restart effects empty",world(7,12,200,Nil{}),Nil{})
    Unit <- checked("restart effects waiting",world(7,12,200,Nil{}),[Names.state(1,0,0,""),Names.state(2,1,0,"Bob")])
    Unit <- checked("restart effects one player",world(7,12,200,[F.player(7,1,"Ada")]),[Names.state(1,2,7,"Ada")])
    Unit <- checked("restart effects opposite orders",world(7,12,200,[F.player(8,2,"Bob"),F.player(7,1,"Ada")]),[Names.state(1,2,7,"Ada"),Names.state(2,2,8,"Bob")])
    Unit <- checked("restart effects mixed waiting and playing",world(7,12,200,[F.player(7,1,"Ada"),F.player(8,2,"Bob")]),[Names.state(3,1,0,"Cy"),Names.state(2,2,8,"Bob"),Names.state(4,0,0,""),Names.state(1,2,7,"Ada")])
    Unit <- checked("restart effects world number wraps",world(4294967295,12,200,[F.player(7,1,"Ada")]),[Names.state(1,2,7,"Ada")])
    Unit <- checked("restart effects MAX seed and time",world(7,4294967295,4294967295,[F.player(7,1,"Ada")]),[Names.state(1,2,7,"Ada")])
    Unit <- checked("restart effects zero seed and time",world(7,0,0,[F.player(7,1,"Ada")]),[Names.state(1,2,7,"Ada")])
    Unit <- checked("restart effects MAX identity",world(7,12,200,[F.player(4294967295,4294967295,"Max")]),[Names.state(4294967295,2,4294967295,"Max")])
    checked("restart effects Unicode identity",world(7,12,200,[F.player(7,1,"Étoile猫")]),[Names.state(1,2,7,"Étoile猫")])

#| PASS restart effects empty
#| PASS restart effects waiting
#| PASS restart effects one player
#| PASS restart effects opposite orders
#| PASS restart effects mixed waiting and playing
#| PASS restart effects world number wraps
#| PASS restart effects MAX seed and time
#| PASS restart effects zero seed and time
#| PASS restart effects MAX identity
#| PASS restart effects Unicode identity
