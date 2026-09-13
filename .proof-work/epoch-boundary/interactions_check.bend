import Base
import ./terrain.bend as Terrain
import ./interactions.bend as I
import ./navigation.bend as N
import ./players.bend as P
import ./vitals.bend as V
import ./game.bend as G
import ./world.bend as W
import ./compat.bend as C
import ./simulation.bend as S
import ./players_check.bend as T
import ./simulation_check.bend as ST
import ./payouts_check.bend as PT
import ./ai_check.bend as MT

def fixture_player(+pid: U32,zone: U32,x: U32,y: U32,dir: U32,moving: U32,main: U32,score: U32) -> P.Players.State:
  P.Players.State{pid,U32.add(pid,10),G.Bq.fresh_hero,P.Players.Pos{zone,x,y,dir,moving},V.Vitals.State{35,42,0,7,3,9},P.Players.Style{1,2,3,4,5,6},P.Players.Quest{main,7,2,3,4,5},P.Players.Meta{score,8,9,T.name()}}

def elder_ready() -> P.Players.State: fixture_player(2,0,6,4,2,1,0,40)
def elder_started() -> P.Players.State: fixture_player(2,0,6,4,2,1,1,50)
def portal(zone: U32) -> P.Players.State: fixture_player(2,zone,28,8,3,1,2,50)
def back_portal(zone: U32) -> P.Players.State: fixture_player(2,zone,1,8,2,1,2,50)

def same_event(a: I.Interaction.Event,b: I.Interaction.Event) -> Bool:
  match a:
    case I.Interaction.Quiet{}:
      match b:
        case I.Interaction.Quiet{}: True{}
        case I.Interaction.ElderStart{}: False{}
        case I.Interaction.Elder{m}: False{}
        case I.Interaction.Shop{}: False{}
        case I.Interaction.Sealed{}: False{}
        case I.Interaction.Entered{z}: False{}
        case I.Interaction.Returned{z}: False{}
    case I.Interaction.ElderStart{}:
      match b:
        case I.Interaction.Quiet{}: False{}
        case I.Interaction.ElderStart{}: True{}
        case I.Interaction.Elder{m}: False{}
        case I.Interaction.Shop{}: False{}
        case I.Interaction.Sealed{}: False{}
        case I.Interaction.Entered{z}: False{}
        case I.Interaction.Returned{z}: False{}
    case I.Interaction.Elder{m}:
      match b:
        case I.Interaction.Quiet{}: False{}
        case I.Interaction.ElderStart{}: False{}
        case I.Interaction.Elder{n}: U32.is_eq(m,n)
        case I.Interaction.Shop{}: False{}
        case I.Interaction.Sealed{}: False{}
        case I.Interaction.Entered{z}: False{}
        case I.Interaction.Returned{z}: False{}
    case I.Interaction.Shop{}:
      match b:
        case I.Interaction.Quiet{}: False{}
        case I.Interaction.ElderStart{}: False{}
        case I.Interaction.Elder{m}: False{}
        case I.Interaction.Shop{}: True{}
        case I.Interaction.Sealed{}: False{}
        case I.Interaction.Entered{z}: False{}
        case I.Interaction.Returned{z}: False{}
    case I.Interaction.Sealed{}:
      match b:
        case I.Interaction.Quiet{}: False{}
        case I.Interaction.ElderStart{}: False{}
        case I.Interaction.Elder{m}: False{}
        case I.Interaction.Shop{}: False{}
        case I.Interaction.Sealed{}: True{}
        case I.Interaction.Entered{z}: False{}
        case I.Interaction.Returned{z}: False{}
    case I.Interaction.Entered{z}:
      match b:
        case I.Interaction.Quiet{}: False{}
        case I.Interaction.ElderStart{}: False{}
        case I.Interaction.Elder{m}: False{}
        case I.Interaction.Shop{}: False{}
        case I.Interaction.Sealed{}: False{}
        case I.Interaction.Entered{w}: U32.is_eq(z,w)
        case I.Interaction.Returned{w}: False{}
    case I.Interaction.Returned{z}:
      match b:
        case I.Interaction.Quiet{}: False{}
        case I.Interaction.ElderStart{}: False{}
        case I.Interaction.Elder{m}: False{}
        case I.Interaction.Shop{}: False{}
        case I.Interaction.Sealed{}: False{}
        case I.Interaction.Entered{w}: False{}
        case I.Interaction.Returned{w}: U32.is_eq(z,w)

def check_step(label: String,actual: I.Interaction.Step,expected: P.Players.State,event: I.Interaction.Event) -> IO(Unit):
  match actual:
    case I.Interaction.Step{player,actual_event}: T.verdict(label,Bool.and(T.same_player(player,expected),same_event(actual_event,event)))

def fixture_meta(sigils: U32) -> S.Simulation.Meta: S.Simulation.Meta{1,7,41,17,100,200,sigils,19,51,450}
def fixture_world(players: List<&2,P.Players.State>,sigils: U32) -> W.Bq.World: Terrain.Terrain.World{fixture_meta(sigils),players,PT.mobs,[[101],[102],[103],[104]]}

def same_words(a: List<&2,U32>,b: List<&2,U32>) -> Bool:
  match a:
    case Nil{}:
      match b:
        case Nil{}: True{}
        case Con{x,xs}: False{}
    case Con{x,xs}:
      match b:
        case Nil{}: False{}
        case Con{y,ys}: Bool.and(U32.is_eq(x,y),same_words(xs,ys))

def same_maps(a: List<&2,List<&2,U32>>,b: List<&2,List<&2,U32>>) -> Bool:
  match a:
    case Nil{}:
      match b:
        case Nil{}: True{}
        case Con{x,xs}: False{}
    case Con{x,xs}:
      match b:
        case Nil{}: False{}
        case Con{y,ys}: Bool.and(same_words(x,y),same_maps(xs,ys))

@unsafe
def world_result(label: String,actual: C.Bq.Pair.Pair(W.Bq.World,(w => List<&1,W.Bq.OutL>)),expected: List<&2,P.Players.State>,sigils: U32,outputs: U32) -> IO(Unit):
  match actual:
    case Tuple{w,outs}:
      match w:
        case Terrain.Terrain.World{wm,players,monsters,maps}:
          +shared_outs = {outs : List<&1,W.Bq.OutL>}
          T.verdict(label,Bool.and(ST.same_meta(wm,fixture_meta(sigils)),Bool.and(T.same_players(players,expected),Bool.and(MT.same_list(monsters,PT.mobs),Bool.and(same_maps(maps,[[101],[102],[103],[104]]),U32.is_eq(T.out_count(shared_outs),outputs))))))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- check_step("move masks direction and retains coordinates",I.Interaction.step(I.Interaction.Move{4294967295},elder_ready),fixture_player(2,0,6,4,3,1,0,40),I.Interaction.Quiet{})
    Unit <- check_step("move masks direction four to zero",I.Interaction.step(I.Interaction.Move{4},elder_ready),fixture_player(2,0,6,4,0,1,0,40),I.Interaction.Quiet{})
    Unit <- check_step("halt retains direction and complete profile",I.Interaction.step(I.Interaction.Halt{},elder_ready),fixture_player(2,0,6,4,2,0,0,40),I.Interaction.Quiet{})
    Unit <- check_step("elder starts quest and credits score",I.Interaction.talk(elder_ready,0),elder_started,I.Interaction.ElderStart{})
    Unit <- check_step("elder repeat conversation does not pay twice",I.Interaction.talk(elder_started,0),elder_started,I.Interaction.Elder{1})
    Unit <- check_step("elder later stage remains unchanged",I.Interaction.talk(fixture_player(2,0,6,4,2,1,5,50),0),fixture_player(2,0,6,4,2,1,5,50),I.Interaction.Elder{5})
    Unit <- check_step("elder diagonal radius boundary",I.Interaction.talk(fixture_player(2,0,4,2,2,1,0,40),0),fixture_player(2,0,4,2,2,1,1,50),I.Interaction.ElderStart{})
    Unit <- check_step("elder outside radius no-op",I.Interaction.talk(fixture_player(2,0,3,4,2,1,0,40),0),fixture_player(2,0,3,4,2,1,0,40),I.Interaction.Quiet{})
    Unit <- check_step("elder wrong zone no-op",I.Interaction.talk(fixture_player(2,1,6,4,2,1,0,40),0),fixture_player(2,1,6,4,2,1,0,40),I.Interaction.Quiet{})
    Unit <- check_step("unknown NPC no-op",I.Interaction.talk(elder_ready,4294967295),elder_ready,I.Interaction.Quiet{})
    Unit <- check_step("shop conversation preserves quest and score",I.Interaction.talk(fixture_player(2,0,9,4,2,1,0,40),1),fixture_player(2,0,9,4,2,1,0,40),I.Interaction.Shop{})
    Unit <- check_step("NPC choice respected in overlapping range",I.Interaction.talk(fixture_player(2,0,7,4,2,1,0,40),1),fixture_player(2,0,7,4,2,1,0,40),I.Interaction.Shop{})
    Unit <- check_step("distant maximum coordinate cannot wrap near NPC",I.Interaction.talk(fixture_player(2,0,4294967295,4,2,1,0,40),0),fixture_player(2,0,4294967295,4,2,1,0,40),I.Interaction.Quiet{})
    Unit <- check_step("portal Hollow to Cavern",I.Interaction.enter(portal(0),0),fixture_player(2,1,2,8,3,0,2,50),I.Interaction.Entered{1})
    Unit <- check_step("portal Cavern to Frost",I.Interaction.enter(portal(1),0),fixture_player(2,2,2,8,3,0,2,50),I.Interaction.Entered{2})
    Unit <- check_step("portal Rift gate sealed without sigils",I.Interaction.enter(portal(2),0),portal(2),I.Interaction.Sealed{})
    Unit <- check_step("portal Rift gate rejects partial sigils",I.Interaction.enter(portal(2),3),portal(2),I.Interaction.Sealed{})
    Unit <- check_step("portal Rift gate opens with three sigils",I.Interaction.enter(portal(2),7),fixture_player(2,3,2,8,3,0,2,50),I.Interaction.Entered{3})
    Unit <- check_step("portal Rift gate rejects malformed sigils",I.Interaction.enter(portal(2),4294967295),portal(2),I.Interaction.Sealed{})
    Unit <- check_step("portal cannot advance beyond Rift",I.Interaction.enter(portal(3),7),portal(3),I.Interaction.Quiet{})
    Unit <- check_step("portal cannot return before Hollow",I.Interaction.enter(back_portal(0),7),back_portal(0),I.Interaction.Quiet{})
    Unit <- check_step("portal Cavern returns to Hollow",I.Interaction.enter(back_portal(1),0),fixture_player(2,0,27,8,2,0,2,50),I.Interaction.Returned{0})
    Unit <- check_step("portal Frost returns to Cavern",I.Interaction.enter(back_portal(2),0),fixture_player(2,1,27,8,2,0,2,50),I.Interaction.Returned{1})
    Unit <- check_step("portal Rift returns to Frost",I.Interaction.enter(back_portal(3),0),fixture_player(2,2,27,8,2,0,2,50),I.Interaction.Returned{2})
    Unit <- check_step("portal rejects adjacent nonportal tile",I.Interaction.enter(fixture_player(2,1,27,8,3,1,2,50),7),fixture_player(2,1,27,8,3,1,2,50),I.Interaction.Quiet{})
    Unit <- T.verdict("interaction missing target preserves roster",T.same_players(I.Interaction.roster(I.Interaction.run([T.a,elder_ready,T.c],99,I.Interaction.Move{0})),[T.a,elder_ready,T.c]))
    Unit <- T.verdict("interaction lookup preserves other records",T.same_players(I.Interaction.roster(I.Interaction.run([T.a,elder_ready,T.c],2,I.Interaction.Talk{0})),[elder_started,T.a,T.c]))
    Unit <- T.verdict("interaction repeated talks cannot farm score",T.same_players(I.Interaction.trace([I.Interaction.Input{2,I.Interaction.Talk{0}},I.Interaction.Input{2,I.Interaction.Talk{0}},I.Interaction.Input{2,I.Interaction.Talk{0}},I.Interaction.Input{2,I.Interaction.Halt{}}],[elder_ready]),[fixture_player(2,0,6,4,2,0,1,50)]))
    Unit <- world_result("server movement uses checked controls",W.Bq.cmd_move(fixture_world([T.a,elder_ready,T.c],0),2,4294967295),[fixture_player(2,0,6,4,3,1,0,40),T.a,T.c],0,0)
    Unit <- world_result("server halt uses checked controls",W.Bq.cmd_halt(fixture_world([elder_ready],0),2),[fixture_player(2,0,6,4,2,0,0,40)],0,0)
    Unit <- world_result("server elder starts quest once",W.Bq.cmd_talk(fixture_world([elder_ready],0),2,0),[elder_started],0,1)
    Unit <- world_result("server elder repeat retains score",W.Bq.cmd_talk(fixture_world([elder_started],0),2,0),[elder_started],0,1)
    Unit <- world_result("server missing talk no-op",W.Bq.cmd_talk(fixture_world([elder_ready],0),99,0),[elder_ready],0,0)
    Unit <- world_result("server portal preserves maps monsters metadata",W.Bq.cmd_enter(fixture_world([portal(0)],0),2),[fixture_player(2,1,2,8,3,0,2,50)],0,2)
    Unit <- world_result("server sealed gate leaves full world intact",W.Bq.cmd_enter(fixture_world([portal(2)],3),2),[portal(2)],3,1)
    Unit <- world_result("server reads actual sigils for Rift gate",W.Bq.cmd_enter(fixture_world([portal(2)],7),2),[fixture_player(2,3,2,8,3,0,2,50)],7,2)
    Unit <- world_result("server return portal sends destination",W.Bq.cmd_enter(fixture_world([back_portal(3)],0),2),[fixture_player(2,2,27,8,2,0,2,50)],0,2)
    return Unit{}

#| PASS move masks direction and retains coordinates
#| PASS move masks direction four to zero
#| PASS halt retains direction and complete profile
#| PASS elder starts quest and credits score
#| PASS elder repeat conversation does not pay twice
#| PASS elder later stage remains unchanged
#| PASS elder diagonal radius boundary
#| PASS elder outside radius no-op
#| PASS elder wrong zone no-op
#| PASS unknown NPC no-op
#| PASS shop conversation preserves quest and score
#| PASS NPC choice respected in overlapping range
#| PASS distant maximum coordinate cannot wrap near NPC
#| PASS portal Hollow to Cavern
#| PASS portal Cavern to Frost
#| PASS portal Rift gate sealed without sigils
#| PASS portal Rift gate rejects partial sigils
#| PASS portal Rift gate opens with three sigils
#| PASS portal Rift gate rejects malformed sigils
#| PASS portal cannot advance beyond Rift
#| PASS portal cannot return before Hollow
#| PASS portal Cavern returns to Hollow
#| PASS portal Frost returns to Cavern
#| PASS portal Rift returns to Frost
#| PASS portal rejects adjacent nonportal tile
#| PASS interaction missing target preserves roster
#| PASS interaction lookup preserves other records
#| PASS interaction repeated talks cannot farm score
#| PASS server movement uses checked controls
#| PASS server halt uses checked controls
#| PASS server elder starts quest once
#| PASS server elder repeat retains score
#| PASS server missing talk no-op
#| PASS server portal preserves maps monsters metadata
#| PASS server sealed gate leaves full world intact
#| PASS server reads actual sigils for Rift gate
#| PASS server return portal sends destination
