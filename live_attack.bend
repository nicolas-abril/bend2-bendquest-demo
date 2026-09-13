# Checked live attack selection; calculators supply only critical/payload data.
import Base
import ./game.bend as G
import ./vitals.bend as V
import ./targeting.bend as PlayerTarget
import ./live_combat.bend as L
import ./live_spin.bend as LS
import ./combat.bend as C
import ./combat_admitted.bend as Admit
import ./combat_actor.bend as A
import ./players.bend as P
import ./monsters.bend as M
import ./roster.bend as R
import ./simulation.bend as S
import ./terrain.bend as T
import ./combat_targets.bend as Targets
import ./target_plans.bend as TP
import ./identity.bend as I

# The payload closure remains affine. It is called only for a selected target.
type LiveAttack.Tuning is Type:
  LiveAttack.Tuning{crit: U32,build: M.Monsters.State -> TP.TargetPlans.Power}

def LiveAttack.Builder() -> Type:
  @+monsters: List<&2,M.Monsters.State> -> @+player: P.Players.State -> @+meta: S.Simulation.Meta -> @+pid: U32 -> LiveAttack.Tuning

def LiveAttack.direction(player: P.Players.State) -> U32:
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
      match pos:
        case P.Players.Pos{zone,x,y,dir,moving}: dir

law LiveAttack.direction_of:
  for +pid: U32
  for +cid: U32
  for +hero: G.Bq.Hero
  for +zone: U32
  for +x: U32
  for +y: U32
  for +dir: U32
  for +moving: U32
  for +vitals: V.Vitals.State
  for +style: P.Players.Style
  for +quest: P.Players.Quest
  for +meta: P.Players.Meta
  {LiveAttack.direction(P.Players.State{pid,cid,hero,P.Players.Pos{zone,x,y,dir,moving},vitals,style,quest,meta}) == dir : U32}

def LiveAttack.direction_of(pid,cid,hero,zone,x,y,dir,moving,vitals,style,quest,meta): {==}

def LiveAttack.finish(+monsters: List<&2,M.Monsters.State>,+player: P.Players.State,tuning: LiveAttack.Tuning) -> L.LiveCombat.Plan:
  match tuning:
    case LiveAttack.Tuning{crit,build}: TP.TargetPlans.attack(Targets.Targets.first(monsters,LS.LiveSpin.point(player)),LS.LiveSpin.point(player),LiveAttack.direction(player),crit,build)

def LiveAttack.plan(ready: L.LiveCombat.Ready,build: LiveAttack.Builder) -> L.LiveCombat.Plan:
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,score}:
      match admitted:
        case C.Combat.Result{players,actor}:
          match actor:
            case None{}: L.LiveCombat.Plan{Nil{},L.LiveCombat.Quiet{}}
            case Some{player}:
              +player = player
              +monsters = monsters
              LiveAttack.finish(monsters,player,build(monsters,player,meta,pid))

law LiveAttack.rejected:
  for +meta: S.Simulation.Meta
  for +monsters: List<&2,M.Monsters.State>
  for +maps: T.Terrain.Maps
  for +players: List<&2,P.Players.State>
  for +pid: U32
  for +score: U32
  for build: LiveAttack.Builder
  {LiveAttack.plan(L.LiveCombat.Ready{meta,monsters,maps,C.Combat.Result{players,None{}},pid,score},build) == L.LiveCombat.Plan{Nil{},L.LiveCombat.Quiet{}} : L.LiveCombat.Plan}

def LiveAttack.rejected(meta,monsters,maps,players,pid,score,build): {==}

law LiveAttack.accepted:
  for +meta: S.Simulation.Meta
  for +monsters: List<&2,M.Monsters.State>
  for +maps: T.Terrain.Maps
  for +players: List<&2,P.Players.State>
  for +actor: P.Players.State
  for +pid: U32
  for +score: U32
  for build: LiveAttack.Builder
  {LiveAttack.plan(L.LiveCombat.Ready{meta,monsters,maps,C.Combat.Result{players,Some{actor}},pid,score},build) == LiveAttack.finish(monsters,actor,build(monsters,actor,meta,pid)) : L.LiveCombat.Plan}

def LiveAttack.accepted(meta,monsters,maps,players,actor,pid,score,build): {==}

law LiveAttack.finish_exact:
  for +monsters: List<&2,M.Monsters.State>
  for +player: P.Players.State
  for +crit: U32
  for build: M.Monsters.State -> TP.TargetPlans.Power
  {LiveAttack.finish(monsters,player,LiveAttack.Tuning{crit,build}) == TP.TargetPlans.attack(Targets.Targets.first(monsters,LS.LiveSpin.point(player)),LS.LiveSpin.point(player),LiveAttack.direction(player),crit,build) : L.LiveCombat.Plan}

def LiveAttack.finish_exact(monsters,player,crit,build): {==}

law LiveAttack.ready_sequence:
  for +monster: M.Monsters.State
  for +point: Targets.Targets.Point
  for +dir: U32
  for +crit: U32
  for +power: TP.TargetPlans.Power
  for +state: S.Simulation.State
  for +actor: P.Players.State
  for +pid: U32
  for +score: U32
  for +inside: PlayerTarget.Targeting.In<actor,S.Simulation.players(state)>
  for +same: {point == A.Actor.point(actor) : Targets.Targets.Point}
  for +source: Targets.Targets.IDSource<S.Simulation.monsters(state),point,R.Roster.id(monster)>
  Admit.Admitted.Sequence(L.LiveCombat.inputs(TP.TargetPlans.ready(monster,point,dir,crit,power)),state,actor,pid,score)

def LiveAttack.ready_sequence(monster,point,dir,crit,power,state,actor,pid,score,inside,same,source):
  match point:
    case Targets.Targets.Point{zone,x,y}:
      match power:
        case TP.TargetPlans.Power{damage,payout}: Tuple{A.Actor.strike_witness(actor,state,R.Roster.id(monster),A.Actor.Member{actor,inside,{==}},(%same : Targets.Targets.IDSource<S.Simulation.monsters(state),_,R.Roster.id(monster)>; source)),Unit{}}

law LiveAttack.attack_sequence:
  for +found: Maybe<&2,M.Monsters.State>
  for +point: Targets.Targets.Point
  for +dir: U32
  for +crit: U32
  for build: M.Monsters.State -> TP.TargetPlans.Power
  for +state: S.Simulation.State
  for +actor: P.Players.State
  for +pid: U32
  for +score: U32
  for +inside: PlayerTarget.Targeting.In<actor,S.Simulation.players(state)>
  for +same: {point == A.Actor.point(actor) : Targets.Targets.Point}
  for +source: Targets.Targets.FirstLookup(S.Simulation.monsters(state),point,found)
  Admit.Admitted.Sequence(L.LiveCombat.inputs(TP.TargetPlans.attack(found,point,dir,crit,build)),state,actor,pid,score)

def LiveAttack.attack_sequence(found,point,dir,crit,build,state,actor,pid,score,inside,same,source):
  match found:
    case None{}: Unit{}
    case Some{monster}: LiveAttack.ready_sequence(monster,point,dir,crit,build(monster),state,actor,pid,score,inside,same,source)

law LiveAttack.finish_sequence:
  for +state: S.Simulation.State
  for +actor: P.Players.State
  for +pid: U32
  for +score: U32
  for tuning: LiveAttack.Tuning
  for +inside: PlayerTarget.Targeting.In<actor,S.Simulation.players(state)>
  for +unique: I.Identity.Monsters(S.Simulation.monsters(state))
  Admit.Admitted.Sequence(L.LiveCombat.inputs(LiveAttack.finish(S.Simulation.monsters(state),actor,tuning)),state,actor,pid,score)

def LiveAttack.finish_sequence(state,actor,pid,score,tuning,inside,unique):
  match tuning:
    case LiveAttack.Tuning{crit,build}: LiveAttack.attack_sequence(Targets.Targets.first(S.Simulation.monsters(state),LS.LiveSpin.point(actor)),LS.LiveSpin.point(actor),LiveAttack.direction(actor),crit,build,state,actor,pid,score,inside,LS.LiveSpin.point_same(actor),Targets.Targets.first_lookup(S.Simulation.monsters(state),LS.LiveSpin.point(actor),unique))

# The same adapter contract used for spins applies: rejection is exactly
# empty/Quiet, acceptance is a command-indexed sequence in the actual world.
def LiveAttack.Checked(ready: L.LiveCombat.Ready,plan: L.LiveCombat.Plan) -> Data: LS.LiveSpin.Checked(ready,plan)

law LiveAttack.plan_checked:
  for +ready: L.LiveCombat.Ready
  for build: LiveAttack.Builder
  for +valid: Admit.Admitted.Ready(ready)
  for +unique: LS.LiveSpin.Unique(ready)
  LiveAttack.Checked(ready,LiveAttack.plan(ready,build))

def LiveAttack.plan_checked(ready,build,valid,unique):
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,score}:
      match admitted:
        case C.Combat.Result{players,actor}:
          match actor:
            case None{}: {==}
            case Some{player}:
              match valid:
                case Tuple{inside,same}: LiveAttack.finish_sequence(S.Simulation.State{meta,players,monsters},player,pid,score,build(monsters,player,meta,pid),inside,unique)

law LiveAttack.prepare_unique:
  for +world: T.Terrain.World
  for +pid: U32
  for +score: U32
  for +unique: I.Identity.Monsters(S.Simulation.monsters(T.Terrain.simulation(world)))
  LS.LiveSpin.Unique(L.LiveCombat.prepare(world,C.Combat.Attack{},pid,score))

def LiveAttack.prepare_unique(world,pid,score,unique):
  match world:
    case T.Terrain.World{meta,players,monsters,maps}: unique

law LiveAttack.prepared_checked:
  for +world: T.Terrain.World
  for +pid: U32
  for +score: U32
  for build: LiveAttack.Builder
  for +unique: I.Identity.Monsters(S.Simulation.monsters(T.Terrain.simulation(world)))
  LiveAttack.Checked(L.LiveCombat.prepare(world,C.Combat.Attack{},pid,score),LiveAttack.plan(L.LiveCombat.prepare(world,C.Combat.Attack{},pid,score),build))

def LiveAttack.prepared_checked(world,pid,score,build,unique): LiveAttack.plan_checked(L.LiveCombat.prepare(world,C.Combat.Attack{},pid,score),build,Admit.Admitted.live_prepare(world,C.Combat.Attack{},pid,score),LiveAttack.prepare_unique(world,pid,score,unique))

law LiveAttack.live_actor:
  for +world: T.Terrain.World
  for +pid: U32
  for +score: U32
  for build: LiveAttack.Builder
  Admit.Admitted.Finished(L.LiveCombat.prepare(world,C.Combat.Attack{},pid,score),L.LiveCombat.run(world,C.Combat.Attack{},pid,score,(ready => LiveAttack.plan(ready,build))))

def LiveAttack.live_actor(world,pid,score,build): Admit.Admitted.live_run(world,C.Combat.Attack{},pid,score,(ready => LiveAttack.plan(ready,build)))
