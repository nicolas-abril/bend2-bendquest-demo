import Base
import ./main.bend as Application
import ./world_clock.bend as Clock
import ./server.bend as Live
import ./terrain.bend as T
import ./simulation.bend as S
import ./rebuild_check.bend as Old
import ./creation_check.bend as F
import ./simulation_check.bend as ST
import ./players_check.bend as Test
import ./sessions.bend as Sess
import ./sessions_check.bend as SS
import ./channel_restart.bend as CR
import ./restart_trace.bend as Trace
import ./restart_check.bend as RT
import ./creation.bend as K

# Preserved original server clock body, independent of the new implementation.
law previous: (@+world: T.Terrain.World -> (@+now: U32 -> T.Terrain.World))

@unsafe
def previous():
  \{T.Terrain.World: \{S.Simulation.Meta: (phase_0 => (wno_1 => (seed_2 => (tick_3 => (t0_4 => (now_5 => (sigils_6 => (fame_t_7 => (nextpid_8 => (nextmid_9 => (plrs_10 => (mobs_11 => (maps_12 => (n_13 => T.Terrain.World{S.Simulation.Meta{phase_0, wno_1, seed_2, tick_3, t0_4, n_13, sigils_6, fame_t_7, nextpid_8, nextmid_9}, plrs_10, mobs_11, maps_12})))))))))))))); \{}}; \{}}

# Distinct metadata, nontrivial rosters, Unicode and arbitrary map payloads.
def fixture(phase: U32,seed: U32,now: U32) -> T.Terrain.World:
  T.Terrain.World{S.Simulation.Meta{phase,4294967295,seed,4294967295,123,now,7,4294967294,99,500},[Old.styled(7,1,"Étoile猫"),Old.styled(8,2,"Bob")],[ST.monster(42,0,0,0)],[[0,1,2,4294967295],Nil{},[72]]}

@unsafe
def checked(label: String,+world: T.Terrain.World,+now: U32) -> IO(Unit): Test.verdict(label,Bool.and(Old.same(Clock.WorldClock.set(world,now),previous(world,now)),Old.same(Live.Bq.set_now(world,now),previous(world,now))))

def traced(label: String,inputs: List<&2,Trace.RestartTrace.Input>,world: U32,+seed: U32,now: U32,tick: U32,states: List<&2,Sess.Sessions.State>) -> IO(Unit):
  +after = Trace.RestartTrace.trace(inputs,RT.initial)
  +meta = S.Simulation.meta(K.Creation.world(Trace.RestartTrace.result(after)))
  Test.verdict(label,Bool.and(U32.is_eq(CR.ChannelRestart.number(meta),world),Bool.and(U32.is_eq(CR.ChannelRestart.seed(meta),seed),Bool.and(U32.is_eq(Trace.RestartTrace.seed(after),seed),Bool.and(U32.is_eq(CR.ChannelRestart.now(meta),now),Bool.and(U32.is_eq(S.Simulation.clock(meta),tick),F.same_states(K.Creation.states(Trace.RestartTrace.result(after)),states)))))))

@unsafe
def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- checked("clock waiting zero",fixture(0,0,0),0)
    Unit <- checked("clock waiting backwards",fixture(0,123,200),91)
    Unit <- checked("clock waiting wrap",fixture(0,4294967295,4294967295),0)
    Unit <- checked("clock playing zero",fixture(1,0,0),0)
    Unit <- checked("clock playing backwards",fixture(1,123,200),91)
    Unit <- checked("clock playing wrap",fixture(1,4294967295,4294967295),0)
    Unit <- checked("clock ended zero",fixture(2,0,0),0)
    Unit <- checked("clock ended backwards",fixture(2,123,200),91)
    Unit <- checked("clock ended wrap",fixture(2,4294967295,4294967295),0)
    Unit <- checked("clock arbitrary phase zero",fixture(7,0,0),0)
    Unit <- checked("clock arbitrary phase backwards",fixture(7,123,200),91)
    Unit <- checked("clock arbitrary phase wrap",fixture(7,4294967295,4294967295),0)
    Unit <- traced("clock trace time only",[Trace.RestartTrace.Time{0}],7,0,0,99,[SS.state(1,2,7,"Ada"),SS.state(2,2,8,"Bob")])
    Unit <- traced("clock trace last time wins",[Trace.RestartTrace.Time{4294967295},Trace.RestartTrace.Time{1}],7,0,1,99,[SS.state(1,2,7,"Ada"),SS.state(2,2,8,"Bob")])
    Unit <- traced("clock trace time then tick",[Trace.RestartTrace.Time{0},RT.tick],7,0,0,100,[SS.state(1,2,7,"Ada"),SS.state(2,2,8,"Bob")])
    Unit <- traced("clock trace time then restart",[Trace.RestartTrace.Time{4294967295},Trace.RestartTrace.Replace{8,123,77}],8,123,77,0,[SS.state(1,2,1,"Ada"),SS.state(2,2,2,"Bob")])
    Unit <- traced("clock trace restart then time",[Trace.RestartTrace.Replace{8,123,77},Trace.RestartTrace.Time{4294967295}],8,123,4294967295,0,[SS.state(1,2,1,"Ada"),SS.state(2,2,2,"Bob")])
    Unit <- traced("clock trace time disconnect time",[Trace.RestartTrace.Time{9},RT.gone(1),Trace.RestartTrace.Time{10}],7,0,10,99,[SS.state(2,2,8,"Bob")])
    Unit <- traced("clock trace restart time tick wrap",[Trace.RestartTrace.Replace{8,123,77},Trace.RestartTrace.Time{4294967295},RT.tick,Trace.RestartTrace.Time{0}],8,123,0,1,[SS.state(1,2,1,"Ada"),SS.state(2,2,2,"Bob")])
    traced("clock trace time create time",[Trace.RestartTrace.Time{4294967295},RT.connection(K.Creation.Connect{3}),RT.connection(K.Creation.Hello{3,SS.name("Cy")}),RT.connection(K.Creation.Create{3,F.style,True{}}),Trace.RestartTrace.Time{0}],7,0,0,99,[SS.state(3,2,99,"Cy"),SS.state(1,2,7,"Ada"),SS.state(2,2,8,"Bob")])

#| PASS clock waiting zero
#| PASS clock waiting backwards
#| PASS clock waiting wrap
#| PASS clock playing zero
#| PASS clock playing backwards
#| PASS clock playing wrap
#| PASS clock ended zero
#| PASS clock ended backwards
#| PASS clock ended wrap
#| PASS clock arbitrary phase zero
#| PASS clock arbitrary phase backwards
#| PASS clock arbitrary phase wrap
#| PASS clock trace time only
#| PASS clock trace last time wins
#| PASS clock trace time then tick
#| PASS clock trace time then restart
#| PASS clock trace restart then time
#| PASS clock trace time disconnect time
#| PASS clock trace restart time tick wrap
#| PASS clock trace time create time
