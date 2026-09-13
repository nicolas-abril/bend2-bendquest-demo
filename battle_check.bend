import Base
import ./battle.bend as B
import ./combat.bend as K
import ./players.bend as P
import ./vitals.bend as V
import ./monsters.bend as M
import ./roster.bend as R
import ./payouts.bend as Pay
import ./simulation.bend as S
import ./players_check.bend as T
import ./payouts_check.bend as PT
import ./simulation_check.bend as ST

def fixture_actor(gold: Nat,score: U32,kills: U32,main: U32,attack: U32,spin: U32) -> P.Players.State:
  P.Players.State{2,12,PT.fixture_hero(Nil{},gold,1n,0n),P.Players.Pos{0,9,4,3,1},V.Vitals.State{35,0,0,7,attack,spin},P.Players.Style{1,2,3,4,5,6},P.Players.Quest{main,0,0,0,0,0},P.Players.Meta{score,kills,0,T.name}}

def initial_actor() -> P.Players.State: fixture_actor(10n,0,0,0,0,0)
def once_actor() -> P.Players.State: fixture_actor(15n,2,1,0,0,0)
def twice_actor() -> P.Players.State: fixture_actor(20n,4,2,0,0,0)
def fixture_meta(phase: U32,sigils: U32,fame: U32) -> S.Simulation.Meta: S.Simulation.Meta{phase,7,41,17,100,200,sigils,fame,51,450}
def start_meta() -> S.Simulation.Meta: fixture_meta(1,0,19)

def live(mid: U32,kind: U32,hp: U32) -> M.Monsters.State: M.Monsters.State{mid,kind,0,0,9,4,hp,10,7,3,0,0}
def fallen(mid: U32,kind: U32,timer: U32) -> M.Monsters.State: M.Monsters.State{mid,kind,0,0,9,4,0,10,0,0,1,timer}
def fixture_plan(kind: U32) -> Pay.Payout.Plan: Pay.Payout.Plan{kind,0,5,2,99,50,4294967295,60,0,99,60}
def hit(mid: U32,damage: U32,kind: U32) -> B.Battle.Input: B.Battle.Input{mid,damage,fixture_plan(kind)}
def fixture_state(monsters: List<&2,M.Monsters.State>) -> S.Simulation.State: S.Simulation.State{start_meta,[initial_actor],monsters}

def notice(mid: U32,kind: U32,actor: P.Players.State,players: List<&2,P.Players.State>,ended: Bool) -> B.Battle.Notice:
  B.Battle.Notice{R.Roster.Kill{kind,0,0,mid},Pay.Payout.Kill{actor,None{},None{},0},100,ended,players}

def same_kill(a: R.Roster.Kill,b: R.Roster.Kill) -> Bool:
  match a:
    case R.Roster.Kill{kind,rare,zone,mid}:
      match b:
        case R.Roster.Kill{k,r,z,m}: Bool.and(U32.is_eq(kind,k),Bool.and(U32.is_eq(rare,r),Bool.and(U32.is_eq(zone,z),U32.is_eq(mid,m))))

def same_award(a: Pay.Payout.Kill,b: Pay.Payout.Kill) -> Bool:
  match a:
    case Pay.Payout.Kill{player,side,drop,levels}:
      match b:
        case Pay.Payout.Kill{p,s,d,l}: Bool.and(T.same_player(player,p),Bool.and(PT.same_maybe(side,s),Bool.and(PT.same_maybe(drop,d),U32.is_eq(levels,l))))

def same_notice(a: B.Battle.Notice,b: B.Battle.Notice) -> Bool:
  match a:
    case B.Battle.Notice{kill,award,elapsed,ended,players}:
      match b:
        case B.Battle.Notice{k,a,e,d,p}: Bool.and(same_kill(kill,k),Bool.and(same_award(award,a),Bool.and(U32.is_eq(elapsed,e),Bool.and(Bool.not(Bool.xor(ended,d)),T.same_players(players,p)))))

def same_notices(a: List<&2,B.Battle.Notice>,b: List<&2,B.Battle.Notice>) -> Bool:
  match a:
    case Nil{}:
      match b:
        case Nil{}: True{}
        case Con{head,rest}: False{}
    case Con{head,rest}:
      match b:
        case Nil{}: False{}
        case Con{other,tail}: Bool.and(same_notice(head,other),same_notices(rest,tail))

def check_result(label: String,actual: B.Battle.Result,expected: S.Simulation.State,notices: List<&2,B.Battle.Notice>) -> IO(Unit):
  match actual:
    case B.Battle.Result{state,emitted}: T.verdict(label,Bool.and(ST.same_state(state,expected),same_notices(emitted,notices)))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- check_result("nonlethal hit cannot pay supplied rewards",B.Battle.strike(hit(7,4,9),fixture_state([live(7,0,10)]),2,60),fixture_state([live(7,0,6)]),[])
    Unit <- check_result("zero damage cannot pay supplied rewards",B.Battle.strike(hit(7,0,9),fixture_state([live(7,0,10)]),2,60),fixture_state([live(7,0,10)]),[])
    Unit <- check_result("missing monster preserves complete state",B.Battle.strike(hit(99,4294967295,9),fixture_state([live(7,0,10)]),2,60),fixture_state([live(7,0,10)]),[])
    Unit <- check_result("dead monster produces no second payout",B.Battle.strike(hit(7,4294967295,9),fixture_state([fallen(7,0,80)]),2,60),fixture_state([fallen(7,0,80)]),[])
    Unit <- check_result("lethal hit pays exact gold score and kill credit",B.Battle.strike(hit(7,10,0),fixture_state([live(7,0,10)]),2,60),S.Simulation.State{start_meta,[once_actor],[fallen(7,0,80)]},[notice(7,0,once_actor,[once_actor],False{})])
    Unit <- check_result("actual slain kind overrides mismatched reward kind",B.Battle.strike(hit(7,10,9),fixture_state([live(7,0,10)]),2,60),S.Simulation.State{start_meta,[once_actor],[fallen(7,0,80)]},[notice(7,0,once_actor,[once_actor],False{})])
    Unit <- check_result("missing killer retains death but grants no reward",B.Battle.strike(hit(7,10,9),fixture_state([live(7,9,10)]),99,60),fixture_state([fallen(7,9,4294967295)]),[])
    Unit <- check_result("repeated lethal inputs pay only the first death",B.Battle.run([hit(7,10,0),hit(7,10,0),hit(7,4294967295,0)],fixture_state([live(7,0,10)]),2,60),S.Simulation.State{start_meta,[once_actor],[fallen(7,0,80)]},[notice(7,0,once_actor,[once_actor],False{})])
    Unit <- check_result("sequential hits observe previous damage",B.Battle.run([hit(7,4,0),hit(7,6,0)],fixture_state([live(7,0,10)]),2,60),S.Simulation.State{start_meta,[once_actor],[fallen(7,0,80)]},[notice(7,0,once_actor,[once_actor],False{})])
    Unit <- check_result("sequential kills preserve reward notice snapshots",B.Battle.run([hit(7,10,0),hit(8,10,0)],fixture_state([live(7,0,10),live(8,0,10)]),2,60),S.Simulation.State{start_meta,[twice_actor],[fallen(8,0,80),fallen(7,0,80)]},[notice(7,0,once_actor,[once_actor],False{}),notice(8,0,twice_actor,[twice_actor],False{})])
    Unit <- check_result("first warden grants sigil and permanent death",B.Battle.strike(hit(7,10,6),fixture_state([live(7,6,10)]),2,60),S.Simulation.State{fixture_meta(1,1,19),[once_actor],[fallen(7,6,4294967295)]},[notice(7,6,once_actor,[once_actor],False{})])
    Unit <- check_result("second warden grants second sigil",B.Battle.strike(hit(7,10,7),fixture_state([live(7,7,10)]),2,60),S.Simulation.State{fixture_meta(1,2,19),[once_actor],[fallen(7,7,4294967295)]},[notice(7,7,once_actor,[once_actor],False{})])
    Unit <- check_result("third warden grants third sigil",B.Battle.strike(hit(7,10,8),fixture_state([live(7,8,10)]),2,60),S.Simulation.State{fixture_meta(1,4,19),[once_actor],[fallen(7,8,4294967295)]},[notice(7,8,once_actor,[once_actor],False{})])
    Unit <- check_result("final boss ends phase and captures finish time",B.Battle.strike(hit(7,10,9),fixture_state([live(7,9,10)]),2,60),S.Simulation.State{fixture_meta(2,0,200),[once_actor],[fallen(7,9,4294967295)]},[notice(7,9,once_actor,[once_actor],True{})])
    Unit <- check_result("spin retains intermediate game over snapshot",B.Battle.run([hit(7,10,9),hit(8,10,6)],fixture_state([live(7,9,10),live(8,6,10)]),2,60),S.Simulation.State{fixture_meta(2,1,200),[twice_actor],[fallen(8,6,4294967295),fallen(7,9,4294967295)]},[notice(7,9,once_actor,[once_actor],True{}),notice(8,6,twice_actor,[twice_actor],False{})])
    Unit <- check_result("sigil notice distinguishes award from advanced roster",B.Battle.strike(hit(7,10,6),S.Simulation.State{start_meta,[fixture_actor(10n,0,0,2,0,0)],[live(7,6,10)]},2,60),S.Simulation.State{fixture_meta(1,1,19),[fixture_actor(15n,62,1,3,0,0)],[fallen(7,6,4294967295)]},[notice(7,6,fixture_actor(15n,2,1,2,0,0),[fixture_actor(15n,62,1,3,0,0)],False{})])
    Unit <- check_result("empty strike sequence is an exact no-op",B.Battle.run([],fixture_state([live(7,0,10)]),2,60),fixture_state([live(7,0,10)]),[])
    Unit <- check_result("rejected admission discards a lethal plan",B.Battle.execute(start_meta,[live(7,9,10)],K.Combat.Result{[initial_actor],None{}},[hit(7,10,9)],2,60),fixture_state([live(7,9,10)]),[])
    Unit <- check_result("ready command commits cooldown before payout",B.Battle.command(K.Combat.Attack{},fixture_state([live(7,0,10)]),[hit(7,10,0)],2,60),S.Simulation.State{start_meta,[fixture_actor(15n,2,1,0,4,0)],[fallen(7,0,80)]},[notice(7,0,fixture_actor(15n,2,1,0,4,0),[fixture_actor(15n,2,1,0,4,0)],False{})])
    Unit <- check_result("ready spin commits cooldown before all payouts",B.Battle.command(K.Combat.Spin{},fixture_state([live(7,0,10)]),[hit(7,10,0)],2,60),S.Simulation.State{start_meta,[fixture_actor(15n,2,1,0,0,25)],[fallen(7,0,80)]},[notice(7,0,fixture_actor(15n,2,1,0,0,25),[fixture_actor(15n,2,1,0,0,25)],False{})])
    Unit <- check_result("inactive command cannot execute supplied boss hit",B.Battle.command(K.Combat.Attack{},S.Simulation.State{fixture_meta(0,0,19),[initial_actor],[live(7,9,10)]},[hit(7,10,9)],2,60),S.Simulation.State{fixture_meta(0,0,19),[initial_actor],[live(7,9,10)]},[])
    Unit <- check_result("missing actor cannot execute supplied boss hit",B.Battle.command(K.Combat.Spin{},fixture_state([live(7,9,10)]),[hit(7,10,9)],99,60),fixture_state([live(7,9,10)]),[])
    Unit <- check_result("cooling actor cannot execute supplied boss hit",B.Battle.command(K.Combat.Attack{},S.Simulation.State{start_meta,[fixture_actor(10n,0,0,0,1,0)],[live(7,9,10)]},[hit(7,10,9)],2,60),S.Simulation.State{start_meta,[fixture_actor(10n,0,0,0,1,0)],[live(7,9,10)]},[])
    return Unit{}

#| PASS nonlethal hit cannot pay supplied rewards
#| PASS zero damage cannot pay supplied rewards
#| PASS missing monster preserves complete state
#| PASS dead monster produces no second payout
#| PASS lethal hit pays exact gold score and kill credit
#| PASS actual slain kind overrides mismatched reward kind
#| PASS missing killer retains death but grants no reward
#| PASS repeated lethal inputs pay only the first death
#| PASS sequential hits observe previous damage
#| PASS sequential kills preserve reward notice snapshots
#| PASS first warden grants sigil and permanent death
#| PASS second warden grants second sigil
#| PASS third warden grants third sigil
#| PASS final boss ends phase and captures finish time
#| PASS spin retains intermediate game over snapshot
#| PASS sigil notice distinguishes award from advanced roster
#| PASS empty strike sequence is an exact no-op
#| PASS rejected admission discards a lethal plan
#| PASS ready command commits cooldown before payout
#| PASS ready spin commits cooldown before all payouts
#| PASS inactive command cannot execute supplied boss hit
#| PASS missing actor cannot execute supplied boss hit
#| PASS cooling actor cannot execute supplied boss hit
