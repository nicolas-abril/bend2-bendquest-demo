import Base
import ./targeting.bend as Sel
import ./pursuit.bend as Q
import ./world.bend as W
import ./players.bend as P
import ./simulation_check.bend as ST
import ./players_check.bend as Test
import ./landscape.bend as L
import ./monsters.bend as M
import ./planning.bend as Plan

def same_bool(a: Bool,b: Bool) -> Bool:
  match a:
    case True{}: b
    case False{}: Bool.not(b)

def same_target(a: Q.Pursuit.Target,b: Q.Pursuit.Target) -> Bool:
  match a:
    case Q.Pursuit.Target{ap,ax,ay,av}:
      match b:
        case Q.Pursuit.Target{bp,bx,by,bv}: Bool.and(U32.is_eq(ap,bp),Bool.and(U32.is_eq(ax,bx),Bool.and(U32.is_eq(ay,by),same_bool(av,bv))))

def same_candidates(a: Sel.Targeting.Candidates,b: Sel.Targeting.Candidates) -> Bool:
  match a:
    case Nil{}:
      match b:
        case Nil{}: True{}
        case Con{head,rest}: False{}
    case Con{head,rest}:
      match head:
        case Sel.Targeting.Candidate{ap,ax,ay}:
          match b:
            case Nil{}: False{}
            case Con{other,later}:
              match other:
                case Sel.Targeting.Candidate{bp,bx,by}: Bool.and(U32.is_eq(ap,bp),Bool.and(U32.is_eq(ax,bx),Bool.and(U32.is_eq(ay,by),same_candidates(rest,later))))

def candidate(pid: U32,x: U32,y: U32) -> Sel.Targeting.Candidate: Sel.Targeting.Candidate{pid,x,y}
def present(pid: U32,x: U32,y: U32) -> Q.Pursuit.Target: Q.Pursuit.Target{pid,x,y,True{}}
def player(pid: U32,zone: U32,x: U32,y: U32,+dead: U32) -> P.Players.State: ST.player(pid,zone,x,y,0,L.Landscape.pick(U32.is_eq(dead,0),35,0),dead,0,0,0)

def selected(label: String,actual: Q.Pursuit.Target,expected: Q.Pursuit.Target) -> IO(Unit): Test.verdict(label,same_target(actual,expected))
def filtered(label: String,actual: Sel.Targeting.Candidates,expected: Sel.Targeting.Candidates) -> IO(Unit): Test.verdict(label,same_candidates(actual,expected))

@unsafe
def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- filtered("targets exclude wrong zone dead and village players",Sel.Targeting.filter([player(1,0,14,8,0),player(2,1,14,8,0),player(3,0,15,8,1),player(4,0,4,8,0),player(5,0,16,8,0)],0),[candidate(1,14,8),candidate(5,16,8)])
    Unit <- filtered("same coordinates in another zone are outside village",Sel.Targeting.filter([player(1,1,4,8,0),player(2,0,4,8,0)],1),[candidate(1,4,8)])
    Unit <- filtered("nonzero death flag is ineligible",Sel.Targeting.filter([player(1,0,14,8,2),player(2,0,15,8,0)],0),[candidate(2,15,8)])
    Unit <- filtered("filter preserves zero MAX and duplicate input IDs",Sel.Targeting.filter([player(0,0,14,8,0),player(4294967295,0,15,8,0),player(1,0,16,8,0),player(1,0,17,8,0)],0),[candidate(0,14,8),candidate(4294967295,15,8),candidate(1,16,8),candidate(1,17,8)])
    Unit <- filtered("village boundary remains excluded",Sel.Targeting.filter([player(1,0,12,9,0),player(2,0,13,9,0),player(3,0,12,10,0)],0),[candidate(2,13,9),candidate(3,12,10)])
    Unit <- selected("empty acquisition has no target",Sel.Targeting.acquire(Nil{},14,8),Sel.Targeting.absent)
    Unit <- selected("acquisition includes distance three",Sel.Targeting.acquire([candidate(1,17,8)],14,8),present(1,17,8))
    Unit <- selected("acquisition excludes distance four",Sel.Targeting.acquire([candidate(1,18,8)],14,8),Sel.Targeting.absent)
    Unit <- selected("diagonal acquisition uses Chebyshev distance",Sel.Targeting.acquire([candidate(1,17,11)],14,8),present(1,17,11))
    Unit <- selected("acquisition keeps earliest equal distance",Sel.Targeting.acquire([candidate(2,13,8),candidate(1,15,8)],14,8),present(2,13,8))
    Unit <- selected("acquisition chooses nearer later candidate",Sel.Targeting.acquire([candidate(1,17,8),candidate(2,15,8)],14,8),present(2,15,8))
    Unit <- selected("zero ID retains legacy no-target semantics",Sel.Targeting.acquire([candidate(0,14,8),candidate(1,15,8)],14,8),Sel.Targeting.absent)
    Unit <- selected("maximum player ID can be acquired",Sel.Targeting.acquire([candidate(4294967295,14,8)],14,8),present(4294967295,14,8))
    Unit <- selected("MAX coordinates do not wrap into nearby targets",Sel.Targeting.acquire([candidate(1,4294967295,4294967295)],0,0),Sel.Targeting.absent)
    Unit <- selected("large unsigned coordinates remain comparable",Sel.Targeting.acquire([candidate(1,4294967292,4294967295)],4294967295,4294967295),present(1,4294967292,4294967295))
    Unit <- selected("duplicate ID acquisition uses first matching coordinates",Sel.Targeting.acquire([candidate(1,25,8),candidate(1,14,8)],14,8),present(1,25,8))
    Unit <- selected("retention includes distance nine",Sel.Targeting.keep([candidate(1,23,8)],1,14,8),present(1,23,8))
    Unit <- selected("retention excludes distance ten",Sel.Targeting.keep([candidate(1,24,8)],1,14,8),Sel.Targeting.absent)
    Unit <- selected("retained target wins over nearer newcomer",Sel.Targeting.keep([candidate(1,23,8),candidate(2,14,8)],1,14,8),present(1,23,8))
    Unit <- selected("far target triggers reacquisition",Sel.Targeting.keep([candidate(1,24,8),candidate(2,15,8)],1,14,8),present(2,15,8))
    Unit <- selected("missing target triggers reacquisition",Sel.Targeting.keep([candidate(2,15,8)],1,14,8),present(2,15,8))
    Unit <- selected("sentinel triggers acquisition",Sel.Targeting.keep([candidate(2,15,8)],0,14,8),present(2,15,8))
    Unit <- selected("empty roster clears current target",Sel.Targeting.keep(Nil{},1,14,8),Sel.Targeting.absent)
    Unit <- selected("dead current target is replaced",Sel.Targeting.select([player(1,0,15,8,1),player(2,0,16,8,0)],0,1,14,8),present(2,16,8))
    Unit <- selected("target in another zone is replaced",Sel.Targeting.select([player(1,1,15,8,0),player(2,0,16,8,0)],0,1,14,8),present(2,16,8))
    Unit <- selected("target entering village is released",Sel.Targeting.select([player(1,0,12,8,0)],0,1,14,8),Sel.Targeting.absent)
    Unit <- selected("server acquire adapter preserves coordinates",W.Bq.pursuit_target(W.Bq.tgt_acquire([Tuple{7,Tuple{17,11}}],14,8)),present(7,17,11))
    Unit <- selected("server retention adapter preserves threshold",W.Bq.pursuit_target(W.Bq.tgt_keep([Tuple{7,Tuple{23,8}}],7,14,8)),present(7,23,8))
    Unit <- filtered("server candidate filter delegates checked selector",W.Bq.target_candidates(W.Bq.plr_targets([player(1,0,14,8,0),player(2,0,4,8,0),player(3,0,16,8,1)],0)),[candidate(1,14,8)])
    Unit <- selected("server tick context uses checked target",Sel.Targeting.context_target(W.Bq.ai_context_data(M.Monsters.tick(M.Monsters.spawn(7,0,0,0,14,8,18)),[candidate(1,15,8)])),present(1,15,8))
    IO.pure(Unit,Unit{})

#| PASS targets exclude wrong zone dead and village players
#| PASS same coordinates in another zone are outside village
#| PASS nonzero death flag is ineligible
#| PASS filter preserves zero MAX and duplicate input IDs
#| PASS village boundary remains excluded
#| PASS empty acquisition has no target
#| PASS acquisition includes distance three
#| PASS acquisition excludes distance four
#| PASS diagonal acquisition uses Chebyshev distance
#| PASS acquisition keeps earliest equal distance
#| PASS acquisition chooses nearer later candidate
#| PASS zero ID retains legacy no-target semantics
#| PASS maximum player ID can be acquired
#| PASS MAX coordinates do not wrap into nearby targets
#| PASS large unsigned coordinates remain comparable
#| PASS duplicate ID acquisition uses first matching coordinates
#| PASS retention includes distance nine
#| PASS retention excludes distance ten
#| PASS retained target wins over nearer newcomer
#| PASS far target triggers reacquisition
#| PASS missing target triggers reacquisition
#| PASS sentinel triggers acquisition
#| PASS empty roster clears current target
#| PASS dead current target is replaced
#| PASS target in another zone is replaced
#| PASS target entering village is released
#| PASS server acquire adapter preserves coordinates
#| PASS server retention adapter preserves threshold
#| PASS server candidate filter delegates checked selector
#| PASS server tick context uses checked target
