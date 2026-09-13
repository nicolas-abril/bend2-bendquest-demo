# Immediate repetition after either accepted or rejected combat admission.
import Base
import ./players.bend as P
import ./combat.bend as C
import ./numeric.bend as N
import ./combat_admitted.bend as Admit
import ./combat_repeat.bend as Repeat
import ./live_combat.bend as L
import ./simulation.bend as S
import ./terrain.bend as T
import ./admission.bend as J

law Rejected.none_decision:
  for +present: Bool
  for +players: List<&2,P.Players.State>
  for +pid: U32
  for +decision: {P.Players.has_id(players,pid) == present : Bool}
  for +none: {P.Players.found(P.Players.take(players,pid)) == None{} : Maybe<&2,P.Players.State>}
  {P.Players.has_id(players,pid) == False{} : Bool}

def Rejected.none_decision(present,players,pid,decision,none):
  match present:
    case False{}: decision
    case True{}: Empty.absurd({P.Players.has_id(players,pid) == False{} : Bool},N.Numeric.true_ne_false(Equal.sym(Bool,False{},True{},(%none : {P.Players.has(_) == True{} : Bool}; P.Players.take_success(players,pid,decision)))))

law Rejected.none_absent:
  for +players: List<&2,P.Players.State>
  for +pid: U32
  for +none: {P.Players.found(P.Players.take(players,pid)) == None{} : Maybe<&2,P.Players.State>}
  {P.Players.has_id(players,pid) == False{} : Bool}

def Rejected.none_absent(players,pid,none): Rejected.none_decision(P.Players.has_id(players,pid),players,pid,{==},none)

law Rejected.head_repeat:
  for +player: P.Players.State
  for +others: List<&2,P.Players.State>
  for +kind: C.Combat.Kind
  for +phase: U32
  for +pid: U32
  for +same: {P.Players.id(player) == pid : U32}
  for +rejected: {C.Combat.prepare(kind,phase,player) == C.Combat.Step{player,False{}} : C.Combat.Step}
  {C.Combat.run(Con{player,others},pid,kind,phase) == C.Combat.Result{Con{player,others},None{}} : C.Combat.Result}

def Rejected.head_repeat(player,others,kind,phase,pid,same,rejected):
  %same : {C.Combat.run(Con{player,others},_,kind,phase) == C.Combat.Result{Con{player,others},None{}} : C.Combat.Result}
  %Equal.sym(P.Players.Take,P.Players.take(Con{player,others},P.Players.id(player)),P.Players.Take{others,Some{player}},P.Players.take_head(player,others)) : {C.Combat.apply_taken(_,kind,phase) == C.Combat.Result{Con{player,others},None{}} : C.Combat.Result}
  %Equal.sym(C.Combat.Step,C.Combat.prepare(kind,phase,player),C.Combat.Step{player,False{}},rejected) : {C.Combat.finish(_,others) == C.Combat.Result{Con{player,others},None{}} : C.Combat.Result}
  {==}

law Rejected.finish_repeat:
  for +kind: C.Combat.Kind
  for +phase: U32
  for +player: P.Players.State
  for +others: List<&2,P.Players.State>
  for +pid: U32
  for +same: {P.Players.id(player) == pid : U32}
  {C.Combat.run(C.Combat.roster(C.Combat.finish(C.Combat.prepare(kind,phase,player),others)),pid,kind,phase) == C.Combat.Result{C.Combat.roster(C.Combat.finish(C.Combat.prepare(kind,phase,player),others)),None{}} : C.Combat.Result}

def Rejected.finish_repeat(kind,phase,player,others,pid,same):
  +step = C.Combat.prepare(kind,phase,player)
  +updated = C.Combat.player(step)
  %Equal.sym(List<&2,P.Players.State>,C.Combat.roster(C.Combat.finish(step,others)),Con{updated,others},C.Combat.finish_roster(step,others)) : {C.Combat.run(_,pid,kind,phase) == C.Combat.Result{_,None{}} : C.Combat.Result}
  Rejected.head_repeat(updated,others,kind,phase,pid,Equal.trans(U32,P.Players.id(updated),P.Players.id(player),pid,Admit.Admitted.prepare_pid(kind,phase,player),same),C.Combat.prepare_repeat(kind,phase,player))

law Rejected.taken_repeat:
  for +taken: P.Players.Take
  for +original: List<&2,P.Players.State>
  for +kind: C.Combat.Kind
  for +phase: U32
  for +pid: U32
  for +shape: {P.Players.take(original,pid) == taken : P.Players.Take}
  {C.Combat.run(C.Combat.roster(C.Combat.apply_taken(taken,kind,phase)),pid,kind,phase) == C.Combat.Result{C.Combat.roster(C.Combat.apply_taken(taken,kind,phase)),None{}} : C.Combat.Result}

def Rejected.taken_repeat(taken,original,kind,phase,pid,shape):
  match taken:
    case P.Players.Take{others,found}:
      match found:
        case None{}:
          +none = Equal.cong(P.Players.Take,Maybe<&2,P.Players.State>,(taken => P.Players.found(taken)),P.Players.take(original,pid),P.Players.Take{others,None{}},shape)
          +absent = Rejected.none_absent(original,pid,none)
          +same = Equal.cong(P.Players.Take,List<&2,P.Players.State>,(taken => P.Players.restore(taken)),P.Players.Take{others,None{}},P.Players.Take{original,None{}},Equal.trans(P.Players.Take,P.Players.Take{others,None{}},P.Players.take(original,pid),P.Players.Take{original,None{}},Equal.sym(P.Players.Take,P.Players.take(original,pid),P.Players.Take{others,None{}},shape),P.Players.take_missing(original,pid,absent)))
          %Equal.sym(List<&2,P.Players.State>,others,original,same) : {C.Combat.run(_,pid,kind,phase) == C.Combat.Result{_,None{}} : C.Combat.Result}
          C.Combat.run_missing(original,pid,kind,phase,absent)
        case Some{player}: Rejected.finish_repeat(kind,phase,player,others,pid,(%shape : P.Players.FoundID(P.Players.found(_),pid); P.Players.take_id(original,pid)))

law Rejected.admission_repeat:
  for +players: List<&2,P.Players.State>
  for +pid: U32
  for +kind: C.Combat.Kind
  for +phase: U32
  {C.Combat.run(C.Combat.roster(C.Combat.run(players,pid,kind,phase)),pid,kind,phase) == C.Combat.Result{C.Combat.roster(C.Combat.run(players,pid,kind,phase)),None{}} : C.Combat.Result}

def Rejected.admission_repeat(players,pid,kind,phase): Rejected.taken_repeat(P.Players.take(players,pid),players,kind,phase,pid,{==})

def Rejected.Replay(ready: L.LiveCombat.Ready,+kind: C.Combat.Kind) -> Data:
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,score}:
      {C.Combat.run(C.Combat.roster(admitted),pid,kind,S.Simulation.phase(meta)) == C.Combat.Result{C.Combat.roster(admitted),None{}} : C.Combat.Result}

law Rejected.prepared_replay:
  for +world: T.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  Rejected.Replay(L.LiveCombat.prepare(world,kind,pid,score),kind)

def Rejected.prepared_replay(world,kind,pid,score):
  match world:
    case T.Terrain.World{meta,players,monsters,maps}: Rejected.admission_repeat(players,pid,kind,S.Simulation.phase(meta))

# An inert result preserves every field and complete player record, allowing
# only the lookup's proved permutation of the roster. Notices/visual are empty.
def Rejected.with_players(world: T.Terrain.World,players: List<&2,P.Players.State>) -> T.Terrain.World:
  match world:
    case T.Terrain.World{meta,old,monsters,maps}: T.Terrain.World{meta,players,monsters,maps}

type Rejected.Inert<-before: T.Terrain.World,-result: L.LiveCombat.Result> is Data:
  Rejected.Inert{players: List<&2,P.Players.State>,permutation: P.Players.Perm<players,S.Simulation.players(T.Terrain.simulation(before))>,exact: {result == L.LiveCombat.Result{Rejected.with_players(before,players),Nil{},L.LiveCombat.Quiet{}} : L.LiveCombat.Result}}

law Rejected.same_inert:
  for +world: T.Terrain.World
  Rejected.Inert<world,L.LiveCombat.Result{world,Nil{},L.LiveCombat.Quiet{}}>

def Rejected.same_inert(world):
  match world:
    case T.Terrain.World{meta,players,monsters,maps}: Rejected.Inert{players,P.Players.Same{{==}},{==}}

law Rejected.quiet_inert:
  for +world: T.Terrain.World
  for +pid: U32
  Rejected.Inert<world,Repeat.Repeat.quiet(world,pid)>

def Rejected.quiet_inert(world,pid):
  match world:
    case T.Terrain.World{meta,players,monsters,maps}: Rejected.Inert{P.Players.restore(P.Players.take(players,pid)),P.Players.take_restores(players,pid),{==}}

law Rejected.at_same:
  for +world: T.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +score: U32
  for +plan: L.LiveCombat.Plan
  for +replay: {C.Combat.run(S.Simulation.players(T.Terrain.simulation(world)),pid,kind,S.Simulation.phase(S.Simulation.meta(T.Terrain.simulation(world)))) == C.Combat.Result{S.Simulation.players(T.Terrain.simulation(world)),None{}} : C.Combat.Result}
  {L.LiveCombat.at(world,kind,pid,score,plan) == L.LiveCombat.Result{world,Nil{},L.LiveCombat.Quiet{}} : L.LiveCombat.Result}

def Rejected.at_same(world,kind,pid,score,plan,replay):
  match world:
    case T.Terrain.World{meta,players,monsters,maps}:
      %Equal.sym(C.Combat.Result,C.Combat.run(players,pid,kind,S.Simulation.phase(meta)),C.Combat.Result{players,None{}},replay) : {L.LiveCombat.finish(L.LiveCombat.Ready{meta,monsters,maps,_,pid,score},plan) == L.LiveCombat.Result{T.Terrain.World{meta,players,monsters,maps},Nil{},L.LiveCombat.Quiet{}} : L.LiveCombat.Result}
      L.LiveCombat.finish_rejected(meta,players,monsters,maps,pid,score,plan)

law Rejected.combine:
  for +ready: L.LiveCombat.Ready
  for +kind: C.Combat.Kind
  for +first: L.LiveCombat.Plan
  for +score: U32
  for +second: L.LiveCombat.Plan
  for +replay: Rejected.Replay(ready,kind)
  for +accepted: Repeat.Repeat.Outcome(ready,L.LiveCombat.world(L.LiveCombat.finish(ready,first)),L.LiveCombat.at(L.LiveCombat.world(L.LiveCombat.finish(ready,first)),kind,Repeat.Repeat.pid(ready),score,second))
  Rejected.Inert<L.LiveCombat.world(L.LiveCombat.finish(ready,first)),L.LiveCombat.at(L.LiveCombat.world(L.LiveCombat.finish(ready,first)),kind,Repeat.Repeat.pid(ready),score,second)>

def Rejected.combine(ready,kind,first,score,second,replay,accepted):
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,first_score}:
      match admitted:
        case C.Combat.Result{players,actor}:
          match actor:
            case None{}:
              %Equal.sym(L.LiveCombat.Result,L.LiveCombat.at(T.Terrain.World{meta,players,monsters,maps},kind,pid,score,second),L.LiveCombat.Result{T.Terrain.World{meta,players,monsters,maps},Nil{},L.LiveCombat.Quiet{}},Rejected.at_same(T.Terrain.World{meta,players,monsters,maps},kind,pid,score,second,replay)) : Rejected.Inert<T.Terrain.World{meta,players,monsters,maps},_>
              Rejected.same_inert(T.Terrain.World{meta,players,monsters,maps})
            case Some{player}:
              +ready = {L.LiveCombat.Ready{meta,monsters,maps,C.Combat.Result{players,Some{player}},pid,first_score} : L.LiveCombat.Ready}
              +world = L.LiveCombat.world(L.LiveCombat.finish(ready,first))
              %Equal.sym(L.LiveCombat.Result,L.LiveCombat.at(world,kind,pid,score,second),Repeat.Repeat.quiet(world,pid),accepted) : Rejected.Inert<world,_>
              Rejected.quiet_inert(world,pid)

# Both first-admission branches are covered; the result is unconditional.
law Rejected.live_twice:
  for +world: T.Terrain.World
  for +kind: C.Combat.Kind
  for +pid: U32
  for +first_score: U32
  for +second_score: U32
  for first: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for second: L.LiveCombat.Ready -> L.LiveCombat.Plan
  for +unique: J.Admission.Unique<S.Simulation.players(T.Terrain.simulation(world))>
  Rejected.Inert<L.LiveCombat.world(L.LiveCombat.run(world,kind,pid,first_score,first)),L.LiveCombat.run(L.LiveCombat.world(L.LiveCombat.run(world,kind,pid,first_score,first)),kind,pid,second_score,second)>

def Rejected.live_twice(world,kind,pid,first_score,second_score,first,second,unique):
  +ready = L.LiveCombat.prepare(world,kind,pid,first_score)
  +plan = first(ready)
  +after = L.LiveCombat.world(L.LiveCombat.finish(ready,plan))
  +next = second(L.LiveCombat.prepare(after,kind,pid,second_score))
  %Repeat.Repeat.ready_pid(world,kind,pid,first_score) : Rejected.Inert<after,L.LiveCombat.at(after,kind,_,second_score,next)>
  Rejected.combine(ready,kind,plan,second_score,next,Rejected.prepared_replay(world,kind,pid,first_score),Repeat.Repeat.repeat_after(ready,kind,after,second_score,(unused => next),Repeat.Repeat.finish_held(ready,kind,plan,Admit.Admitted.live_prepare(world,kind,pid,first_score),Repeat.Repeat.prepare_cooled(world,kind,pid,first_score)),Repeat.Repeat.at_unique(world,kind,pid,first_score,plan,unique)))
