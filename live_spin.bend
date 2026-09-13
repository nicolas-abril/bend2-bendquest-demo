# Checked live spin planning from the exact admitted actor and world snapshot.
import Base
import ./live_combat.bend as L
import ./combat.bend as C
import ./combat_admitted.bend as Admit
import ./combat_actor.bend as A
import ./players.bend as P
import ./monsters.bend as M
import ./simulation.bend as S
import ./terrain.bend as T
import ./combat_targets.bend as Targets
import ./spin_plans.bend as Spin
import ./identity.bend as I

def LiveSpin.Builder() -> Type:
  @+monsters: List<&2,M.Monsters.State> -> @+player: P.Players.State -> @+meta: S.Simulation.Meta -> @+selected: List<&2,M.Monsters.State> -> Spin.SpinPlans.Powers(selected)

def LiveSpin.point(player: P.Players.State) -> Targets.Targets.Point:
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
      match pos:
        case P.Players.Pos{zone,x,y,dir,moving}: Targets.Targets.Point{zone,x,y}

law LiveSpin.point_same:
  for +player: P.Players.State
  {LiveSpin.point(player) == A.Actor.point(player) : Targets.Targets.Point}

def LiveSpin.point_same(player):
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
      match pos:
        case P.Players.Pos{zone,x,y,dir,moving}: Equal.sym(Targets.Targets.Point,A.Actor.point(P.Players.State{pid,cid,hero,P.Players.Pos{zone,x,y,dir,moving},vitals,style,quest,meta}),Targets.Targets.Point{zone,x,y},A.Actor.point_of(pid,cid,hero,zone,x,y,dir,moving,vitals,style,quest,meta))

def LiveSpin.plan(ready: L.LiveCombat.Ready,build: LiveSpin.Builder) -> L.LiveCombat.Plan:
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,score}:
      match admitted:
        case C.Combat.Result{players,actor}:
          match actor:
            case None{}: L.LiveCombat.Plan{Nil{},L.LiveCombat.Quiet{}}
            case Some{player}:
              +player = player
              +monsters = monsters
              +meta = meta
              Spin.SpinPlans.run(monsters,LiveSpin.point(player),build(monsters,player,meta))

law LiveSpin.rejected:
  for +meta: S.Simulation.Meta
  for +monsters: List<&2,M.Monsters.State>
  for +maps: T.Terrain.Maps
  for +players: List<&2,P.Players.State>
  for +pid: U32
  for +score: U32
  for build: LiveSpin.Builder
  {LiveSpin.plan(L.LiveCombat.Ready{meta,monsters,maps,C.Combat.Result{players,None{}},pid,score},build) == L.LiveCombat.Plan{Nil{},L.LiveCombat.Quiet{}} : L.LiveCombat.Plan}

def LiveSpin.rejected(meta,monsters,maps,players,pid,score,build): {==}

law LiveSpin.accepted:
  for +meta: S.Simulation.Meta
  for +monsters: List<&2,M.Monsters.State>
  for +maps: T.Terrain.Maps
  for +players: List<&2,P.Players.State>
  for +actor: P.Players.State
  for +pid: U32
  for +score: U32
  for build: LiveSpin.Builder
  {LiveSpin.plan(L.LiveCombat.Ready{meta,monsters,maps,C.Combat.Result{players,Some{actor}},pid,score},build) == Spin.SpinPlans.run(monsters,LiveSpin.point(actor),build(monsters,actor,meta)) : L.LiveCombat.Plan}

def LiveSpin.accepted(meta,monsters,maps,players,actor,pid,score,build): {==}

def LiveSpin.Unique(ready: L.LiveCombat.Ready) -> Data:
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,score}: I.Identity.Monsters(monsters)

def LiveSpin.Checked(+ready: L.LiveCombat.Ready,+plan: L.LiveCombat.Plan) -> Data:
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,score}:
      match admitted:
        case C.Combat.Result{players,actor}:
          match actor:
            case None{}: {plan == L.LiveCombat.Plan{Nil{},L.LiveCombat.Quiet{}} : L.LiveCombat.Plan}
            case Some{player}: Admit.Admitted.Sequence(L.LiveCombat.inputs(plan),S.Simulation.State{meta,players,monsters},player,pid,score)

law LiveSpin.plan_checked:
  for +ready: L.LiveCombat.Ready
  for build: LiveSpin.Builder
  for +valid: Admit.Admitted.Ready(ready)
  for +unique: LiveSpin.Unique(ready)
  LiveSpin.Checked(ready,LiveSpin.plan(ready,build))

def LiveSpin.plan_checked(ready,build,valid,unique):
  match ready:
    case L.LiveCombat.Ready{meta,monsters,maps,admitted,pid,score}:
      match admitted:
        case C.Combat.Result{players,actor}:
          match actor:
            case None{}: {==}
            case Some{player}:
              %Equal.sym(Targets.Targets.Point,LiveSpin.point(player),A.Actor.point(player),LiveSpin.point_same(player)) : Admit.Admitted.Sequence(L.LiveCombat.inputs(Spin.SpinPlans.run(monsters,_,build(monsters,player,meta))),S.Simulation.State{meta,players,monsters},player,pid,score)
              Admit.Admitted.spin_sequence(meta,players,monsters,player,pid,score,build(monsters,player,meta),valid,unique)

law LiveSpin.prepare_unique:
  for +world: T.Terrain.World
  for +pid: U32
  for +score: U32
  for +unique: I.Identity.Monsters(S.Simulation.monsters(T.Terrain.simulation(world)))
  LiveSpin.Unique(L.LiveCombat.prepare(world,C.Combat.Spin{},pid,score))

def LiveSpin.prepare_unique(world,pid,score,unique):
  match world:
    case T.Terrain.World{meta,players,monsters,maps}: unique

law LiveSpin.prepared_checked:
  for +world: T.Terrain.World
  for +pid: U32
  for +score: U32
  for build: LiveSpin.Builder
  for +unique: I.Identity.Monsters(S.Simulation.monsters(T.Terrain.simulation(world)))
  LiveSpin.Checked(L.LiveCombat.prepare(world,C.Combat.Spin{},pid,score),LiveSpin.plan(L.LiveCombat.prepare(world,C.Combat.Spin{},pid,score),build))

def LiveSpin.prepared_checked(world,pid,score,build,unique): LiveSpin.plan_checked(L.LiveCombat.prepare(world,C.Combat.Spin{},pid,score),build,Admit.Admitted.live_prepare(world,C.Combat.Spin{},pid,score),LiveSpin.prepare_unique(world,pid,score,unique))

law LiveSpin.live_actor:
  for +world: T.Terrain.World
  for +pid: U32
  for +score: U32
  for build: LiveSpin.Builder
  Admit.Admitted.Finished(L.LiveCombat.prepare(world,C.Combat.Spin{},pid,score),L.LiveCombat.run(world,C.Combat.Spin{},pid,score,(ready => LiveSpin.plan(ready,build))))

def LiveSpin.live_actor(world,pid,score,build): Admit.Admitted.live_run(world,C.Combat.Spin{},pid,score,(ready => LiveSpin.plan(ready,build)))
