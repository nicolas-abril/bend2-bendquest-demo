# Authoritative attack admission and cooldown updates on complete players.
import Base
import ./game.bend as G
import ./players.bend as P
import ./vitals.bend as V
import ./navigation.bend as N

type Combat.Kind is Data:
  Combat.Attack{}
  Combat.Spin{}

def Combat.attack_ticks() -> U32: 4
def Combat.spin_ticks() -> U32: 25

def Combat.delay(kind: Combat.Kind) -> U32:
  match kind:
    case Combat.Attack{}: Combat.attack_ticks
    case Combat.Spin{}: Combat.spin_ticks

def Combat.cooldown(kind: Combat.Kind, vitals: V.Vitals.State) -> U32:
  match kind:
    case Combat.Attack{}:
      match vitals:
        case V.Vitals.State{hp,xp,dead,respawn,attack,spin}: attack
    case Combat.Spin{}:
      match vitals:
        case V.Vitals.State{hp,xp,dead,respawn,attack,spin}: spin

def Combat.other(kind: Combat.Kind) -> Combat.Kind:
  match kind:
    case Combat.Attack{}: Combat.Spin{}
    case Combat.Spin{}: Combat.Attack{}

def Combat.stamp_vitals(kind: Combat.Kind, vitals: V.Vitals.State) -> V.Vitals.State:
  match kind:
    case Combat.Attack{}:
      match vitals:
        case V.Vitals.State{hp,xp,dead,respawn,attack,spin}: V.Vitals.State{hp,xp,dead,respawn,Combat.attack_ticks,spin}
    case Combat.Spin{}:
      match vitals:
        case V.Vitals.State{hp,xp,dead,respawn,attack,spin}: V.Vitals.State{hp,xp,dead,respawn,attack,Combat.spin_ticks}

def Combat.stamp(kind: Combat.Kind, player: P.Players.State) -> P.Players.State:
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
      P.Players.State{pid,cid,hero,pos,Combat.stamp_vitals(kind,vitals),style,quest,meta}

# Match the live protocol's gate exactly, including arbitrary word inputs.
def Combat.blocked(+kind: Combat.Kind, phase: U32, +player: P.Players.State) -> Bool:
  Bool.or(Bool.or(U32.is_eq(V.Vitals.dead(P.Players.vitals(player)),1),U32.is_gt(Combat.cooldown(kind,P.Players.vitals(player)),0)),U32.is_ne(phase,1))

type Combat.Step is Data:
  Combat.Step{player: P.Players.State, accepted: Bool}

def Combat.player(step: Combat.Step) -> P.Players.State:
  match step:
    case Combat.Step{player,accepted}: player

def Combat.accepted(step: Combat.Step) -> Bool:
  match step:
    case Combat.Step{player,accepted}: accepted

def Combat.gate(blocked: Bool, kind: Combat.Kind, player: P.Players.State) -> Combat.Step:
  match blocked:
    case True{}: Combat.Step{player,False{}}
    case False{}: Combat.Step{Combat.stamp(kind,player),True{}}

def Combat.prepare(+kind: Combat.Kind, phase: U32, +player: P.Players.State) -> Combat.Step:
  Combat.gate(Combat.blocked(kind,phase,player),kind,player)

law Combat.stamp_vitals_ok:
  for +kind: Combat.Kind
  for +vitals: V.Vitals.State
  for +maximum: U32
  for +valid: V.Vitals.OK<vitals,maximum>
  V.Vitals.OK<Combat.stamp_vitals(kind,vitals),maximum>

def Combat.stamp_vitals_ok(kind,vitals,maximum,valid):
  match kind:
    case Combat.Attack{}:
      match vitals:
        case V.Vitals.State{hp,xp,dead,respawn,attack,spin}:
          match valid:
            case V.Vitals.OK{bound,life}: V.Vitals.OK{bound,life}
    case Combat.Spin{}:
      match vitals:
        case V.Vitals.State{hp,xp,dead,respawn,attack,spin}:
          match valid:
            case V.Vitals.OK{bound,life}: V.Vitals.OK{bound,life}

law Combat.stamp_ok:
  for +kind: Combat.Kind
  for +player: P.Players.State
  for +valid: P.Players.OK<player>
  P.Players.OK<Combat.stamp(kind,player)>

def Combat.stamp_ok(kind,player,valid):
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
      match valid:
        case P.Players.OK{vital_ok,equipped}:
          P.Players.OK{Combat.stamp_vitals_ok(kind,vitals,P.Players.maximum(P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}),vital_ok),equipped}

law Combat.gate_ok:
  for +blocked: Bool
  for +kind: Combat.Kind
  for +player: P.Players.State
  for +valid: P.Players.OK<player>
  P.Players.OK<Combat.player(Combat.gate(blocked,kind,player))>

def Combat.gate_ok(blocked,kind,player,valid):
  match blocked:
    case True{}: valid
    case False{}: Combat.stamp_ok(kind,player,valid)

law Combat.prepare_ok:
  for +kind: Combat.Kind
  for +phase: U32
  for +player: P.Players.State
  for +valid: P.Players.OK<player>
  P.Players.OK<Combat.player(Combat.prepare(kind,phase,player))>

def Combat.prepare_ok(kind,phase,player,valid): Combat.gate_ok(Combat.blocked(kind,phase,player),kind,player,valid)

# A complete frame: every player field except the two cooldowns.
type Combat.Frame is Data:
  Combat.Frame{pid: U32,cid: U32,hero: G.Bq.Hero,pos: P.Players.Pos,hp: U32,xp: U32,dead: U32,respawn: U32,style: P.Players.Style,quest: P.Players.Quest,meta: P.Players.Meta}

def Combat.frame(player: P.Players.State) -> Combat.Frame:
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
      match vitals:
        case V.Vitals.State{hp,xp,dead,respawn,attack,spin}: Combat.Frame{pid,cid,hero,pos,hp,xp,dead,respawn,style,quest,meta}

law Combat.stamp_frame:
  for +kind: Combat.Kind
  for +player: P.Players.State
  {Combat.frame(Combat.stamp(kind,player)) == Combat.frame(player) : Combat.Frame}

def Combat.stamp_frame(kind,player):
  match kind:
    case Combat.Attack{}:
      match player:
        case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
          match vitals:
            case V.Vitals.State{hp,xp,dead,respawn,attack,spin}: {==}
    case Combat.Spin{}:
      match player:
        case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
          match vitals:
            case V.Vitals.State{hp,xp,dead,respawn,attack,spin}: {==}

law Combat.gate_frame:
  for +blocked: Bool
  for +kind: Combat.Kind
  for +player: P.Players.State
  {Combat.frame(Combat.player(Combat.gate(blocked,kind,player))) == Combat.frame(player) : Combat.Frame}

def Combat.gate_frame(blocked,kind,player):
  match blocked:
    case True{}: {==}
    case False{}: Combat.stamp_frame(kind,player)

law Combat.prepare_frame:
  for +kind: Combat.Kind
  for +phase: U32
  for +player: P.Players.State
  {Combat.frame(Combat.player(Combat.prepare(kind,phase,player))) == Combat.frame(player) : Combat.Frame}

def Combat.prepare_frame(kind,phase,player): Combat.gate_frame(Combat.blocked(kind,phase,player),kind,player)

law Combat.stamp_position:
  for +kind: Combat.Kind
  for +player: P.Players.State
  {N.Navigation.pos(Combat.stamp(kind,player)) == N.Navigation.pos(player) : P.Players.Pos}

def Combat.stamp_position(kind,player):
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}: {==}

law Combat.gate_position:
  for +blocked: Bool
  for +kind: Combat.Kind
  for +player: P.Players.State
  {N.Navigation.pos(Combat.player(Combat.gate(blocked,kind,player))) == N.Navigation.pos(player) : P.Players.Pos}

def Combat.gate_position(blocked,kind,player):
  match blocked:
    case True{}: {==}
    case False{}: Combat.stamp_position(kind,player)

law Combat.prepare_bounds:
  for +kind: Combat.Kind
  for +phase: U32
  for +player: P.Players.State
  for +valid: N.Navigation.Bounds<N.Navigation.pos(player)>
  N.Navigation.Bounds<N.Navigation.pos(Combat.player(Combat.prepare(kind,phase,player)))>

def Combat.prepare_bounds(kind,phase,player,valid):
  %Equal.sym(P.Players.Pos,N.Navigation.pos(Combat.player(Combat.prepare(kind,phase,player))),N.Navigation.pos(player),Combat.gate_position(Combat.blocked(kind,phase,player),kind,player)) : N.Navigation.Bounds<_>
  valid

law Combat.stamp_cooldown:
  for +kind: Combat.Kind
  for +vitals: V.Vitals.State
  {Combat.cooldown(kind,Combat.stamp_vitals(kind,vitals)) == Combat.delay(kind) : U32}

def Combat.stamp_cooldown(kind,vitals):
  match kind:
    case Combat.Attack{}:
      match vitals:
        case V.Vitals.State{hp,xp,dead,respawn,attack,spin}: {==}
    case Combat.Spin{}:
      match vitals:
        case V.Vitals.State{hp,xp,dead,respawn,attack,spin}: {==}

law Combat.stamp_other:
  for +kind: Combat.Kind
  for +vitals: V.Vitals.State
  {Combat.cooldown(Combat.other(kind),Combat.stamp_vitals(kind,vitals)) == Combat.cooldown(Combat.other(kind),vitals) : U32}

def Combat.stamp_other(kind,vitals):
  match kind:
    case Combat.Attack{}:
      match vitals:
        case V.Vitals.State{hp,xp,dead,respawn,attack,spin}: {==}
    case Combat.Spin{}:
      match vitals:
        case V.Vitals.State{hp,xp,dead,respawn,attack,spin}: {==}

law Combat.or_true:
  for +value: Bool
  {Bool.or(value,True{}) == True{} : Bool}

def Combat.or_true(value):
  match value:
    case True{}: {==}
    case False{}: {==}

law Combat.blocked_stamp:
  for +kind: Combat.Kind
  for +phase: U32
  for +player: P.Players.State
  {Combat.blocked(kind,phase,Combat.stamp(kind,player)) == True{} : Bool}

def Combat.blocked_stamp(kind,phase,player):
  match kind:
    case Combat.Attack{}:
      match player:
        case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
          match vitals:
            case V.Vitals.State{hp,xp,dead,respawn,attack,spin}:
              %Equal.sym(Bool,Bool.or(U32.is_eq(dead,1),True{}),True{},Combat.or_true(U32.is_eq(dead,1))) : {Bool.or(_,U32.is_ne(phase,1)) == True{} : Bool}
              {==}
    case Combat.Spin{}:
      match player:
        case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
          match vitals:
            case V.Vitals.State{hp,xp,dead,respawn,attack,spin}:
              %Equal.sym(Bool,Bool.or(U32.is_eq(dead,1),True{}),True{},Combat.or_true(U32.is_eq(dead,1))) : {Bool.or(_,U32.is_ne(phase,1)) == True{} : Bool}
              {==}

law Combat.reject:
  for +kind: Combat.Kind
  for +phase: U32
  for +player: P.Players.State
  for +blocked: {Combat.blocked(kind,phase,player) == True{} : Bool}
  {Combat.prepare(kind,phase,player) == Combat.Step{player,False{}} : Combat.Step}

def Combat.reject(kind,phase,player,blocked):
  %Equal.sym(Bool,Combat.blocked(kind,phase,player),True{},blocked) : {Combat.gate(_,kind,player) == Combat.Step{player,False{}} : Combat.Step}
  {==}

law Combat.ready:
  for +kind: Combat.Kind
  for +phase: U32
  for +player: P.Players.State
  for +ready: {Combat.blocked(kind,phase,player) == False{} : Bool}
  {Combat.prepare(kind,phase,player) == Combat.Step{Combat.stamp(kind,player),True{}} : Combat.Step}

def Combat.ready(kind,phase,player,ready):
  %Equal.sym(Bool,Combat.blocked(kind,phase,player),False{},ready) : {Combat.gate(_,kind,player) == Combat.Step{Combat.stamp(kind,player),True{}} : Combat.Step}
  {==}

law Combat.stamped_rejected:
  for +kind: Combat.Kind
  for +phase: U32
  for +player: P.Players.State
  {Combat.prepare(kind,phase,Combat.stamp(kind,player)) == Combat.Step{Combat.stamp(kind,player),False{}} : Combat.Step}

def Combat.stamped_rejected(kind,phase,player): Combat.reject(kind,phase,Combat.stamp(kind,player),Combat.blocked_stamp(kind,phase,player))

law Combat.gate_repeat:
  for +blocked: Bool
  for +kind: Combat.Kind
  for +phase: U32
  for +player: P.Players.State
  for +decision: {Combat.blocked(kind,phase,player) == blocked : Bool}
  {Combat.prepare(kind,phase,Combat.player(Combat.gate(blocked,kind,player))) == Combat.Step{Combat.player(Combat.gate(blocked,kind,player)),False{}} : Combat.Step}

def Combat.gate_repeat(blocked,kind,phase,player,decision):
  match blocked:
    case True{}: Combat.reject(kind,phase,player,decision)
    case False{}: Combat.stamped_rejected(kind,phase,player)

law Combat.prepare_repeat:
  for +kind: Combat.Kind
  for +phase: U32
  for +player: P.Players.State
  {Combat.prepare(kind,phase,Combat.player(Combat.prepare(kind,phase,player))) == Combat.Step{Combat.player(Combat.prepare(kind,phase,player)),False{}} : Combat.Step}

def Combat.prepare_repeat(kind,phase,player): Combat.gate_repeat(Combat.blocked(kind,phase,player),kind,phase,player,{==})

law Combat.dead_rejected:
  for +kind: Combat.Kind
  for +phase: U32
  for +player: P.Players.State
  for +dead: {V.Vitals.dead(P.Players.vitals(player)) == 1 : U32}
  {Combat.prepare(kind,phase,player) == Combat.Step{player,False{}} : Combat.Step}

def Combat.dead_rejected(kind,phase,player,dead):
  Combat.reject(kind,phase,player,(%Equal.sym(U32,V.Vitals.dead(P.Players.vitals(player)),1,dead) : {Bool.or(Bool.or(U32.is_eq(_,1),U32.is_gt(Combat.cooldown(kind,P.Players.vitals(player)),0)),U32.is_ne(phase,1)) == True{} : Bool}; {==}))

law Combat.cooling_rejected:
  for +kind: Combat.Kind
  for +phase: U32
  for +player: P.Players.State
  for +cooling: {U32.is_gt(Combat.cooldown(kind,P.Players.vitals(player)),0) == True{} : Bool}
  {Combat.prepare(kind,phase,player) == Combat.Step{player,False{}} : Combat.Step}

def Combat.cooling_rejected(kind,phase,player,cooling):
  Combat.reject(kind,phase,player,
    (%Equal.sym(Bool,U32.is_gt(Combat.cooldown(kind,P.Players.vitals(player)),0),True{},cooling) : {Bool.or(Bool.or(U32.is_eq(V.Vitals.dead(P.Players.vitals(player)),1),_),U32.is_ne(phase,1)) == True{} : Bool}
     %Equal.sym(Bool,Bool.or(U32.is_eq(V.Vitals.dead(P.Players.vitals(player)),1),True{}),True{},Combat.or_true(U32.is_eq(V.Vitals.dead(P.Players.vitals(player)),1))) : {Bool.or(_,U32.is_ne(phase,1)) == True{} : Bool}
     {==}))

law Combat.inactive_rejected:
  for +kind: Combat.Kind
  for +phase: U32
  for +player: P.Players.State
  for +inactive: {U32.is_ne(phase,1) == True{} : Bool}
  {Combat.prepare(kind,phase,player) == Combat.Step{player,False{}} : Combat.Step}

def Combat.inactive_rejected(kind,phase,player,inactive):
  Combat.reject(kind,phase,player,
    (%Equal.sym(Bool,U32.is_ne(phase,1),True{},inactive) : {Bool.or(Bool.or(U32.is_eq(V.Vitals.dead(P.Players.vitals(player)),1),U32.is_gt(Combat.cooldown(kind,P.Players.vitals(player)),0)),_) == True{} : Bool}
     Combat.or_true(Bool.or(U32.is_eq(V.Vitals.dead(P.Players.vitals(player)),1),U32.is_gt(Combat.cooldown(kind,P.Players.vitals(player)),0)))))

law Combat.live_ready:
  for +kind: Combat.Kind
  for +player: P.Players.State
  for +alive: {V.Vitals.dead(P.Players.vitals(player)) == 0 : U32}
  for +ready: {Combat.cooldown(kind,P.Players.vitals(player)) == 0 : U32}
  {Combat.prepare(kind,1,player) == Combat.Step{Combat.stamp(kind,player),True{}} : Combat.Step}

def Combat.live_ready(kind,player,alive,ready):
  Combat.ready(kind,1,player,
    (%Equal.sym(U32,V.Vitals.dead(P.Players.vitals(player)),0,alive) : {Bool.or(Bool.or(U32.is_eq(_,1),U32.is_gt(Combat.cooldown(kind,P.Players.vitals(player)),0)),False{}) == False{} : Bool}
     %Equal.sym(U32,Combat.cooldown(kind,P.Players.vitals(player)),0,ready) : {Bool.or(U32.is_gt(_,0),False{}) == False{} : Bool}
     {==}))

# Admission returns the exact cooldown-updated actor used by the server.
# Missing or rejected commands return no actor; no combat effect is dispatched.
type Combat.Result is Data:
  Combat.Result{players: List<&2,P.Players.State>,attacker: Maybe<&2,P.Players.State>}

def Combat.roster(result: Combat.Result) -> List<&2,P.Players.State>:
  match result:
    case Combat.Result{players,attacker}: players

def Combat.actor(accepted: Bool, player: P.Players.State) -> Maybe<&2,P.Players.State>:
  match accepted:
    case False{}: None{}
    case True{}: Some{player}

def Combat.finish(step: Combat.Step, others: List<&2,P.Players.State>) -> Combat.Result:
  match step:
    case Combat.Step{player,accepted}:
      +shared = player
      Combat.Result{Con{shared,others},Combat.actor(accepted,shared)}

def Combat.apply_taken(taken: P.Players.Take, kind: Combat.Kind, phase: U32) -> Combat.Result:
  match taken:
    case P.Players.Take{others,found}:
      match found:
        case None{}: Combat.Result{others,None{}}
        case Some{player}: Combat.finish(Combat.prepare(kind,phase,player),others)

def Combat.run(players: List<&2,P.Players.State>, target: U32, kind: Combat.Kind, phase: U32) -> Combat.Result:
  Combat.apply_taken(P.Players.take(players,target),kind,phase)

law Combat.finish_roster:
  for +step: Combat.Step
  for +others: List<&2,P.Players.State>
  {Combat.roster(Combat.finish(step,others)) == Con{Combat.player(step),others} : List<&2,P.Players.State>}

def Combat.finish_roster(step,others):
  match step:
    case Combat.Step{player,accepted}: {==}

law Combat.apply_taken_ok:
  for +taken: P.Players.Take
  for +kind: Combat.Kind
  for +phase: U32
  for +valid: P.Players.TakeOK<taken>
  P.Players.All(Combat.roster(Combat.apply_taken(taken,kind,phase)))

def Combat.apply_taken_ok(taken,kind,phase,valid):
  match taken:
    case P.Players.Take{others,found}:
      match found:
        case None{}:
          match valid:
            case P.Players.ValidTake{others_ok,found_ok}: others_ok
        case Some{player}:
          match valid:
            case P.Players.ValidTake{others_ok,found_ok}:
              %Equal.sym(List<&2,P.Players.State>,Combat.roster(Combat.finish(Combat.prepare(kind,phase,player),others)),Con{Combat.player(Combat.prepare(kind,phase,player)),others},Combat.finish_roster(Combat.prepare(kind,phase,player),others)) : P.Players.All(_)
              Tuple{Combat.prepare_ok(kind,phase,player,found_ok),others_ok}

law Combat.run_ok:
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +kind: Combat.Kind
  for +phase: U32
  for +valid: P.Players.All(players)
  P.Players.All(Combat.roster(Combat.run(players,target,kind,phase)))

def Combat.run_ok(players,target,kind,phase,valid): Combat.apply_taken_ok(P.Players.take(players,target),kind,phase,P.Players.take_ok(players,target,valid))

law Combat.apply_taken_bounds:
  for +taken: P.Players.Take
  for +kind: Combat.Kind
  for +phase: U32
  for +valid: N.Navigation.All(P.Players.restore(taken))
  N.Navigation.All(Combat.roster(Combat.apply_taken(taken,kind,phase)))

def Combat.apply_taken_bounds(taken,kind,phase,valid):
  match taken:
    case P.Players.Take{others,found}:
      match found:
        case None{}: valid
        case Some{player}:
          match valid:
            case Tuple{player_ok,others_ok}:
              %Equal.sym(List<&2,P.Players.State>,Combat.roster(Combat.finish(Combat.prepare(kind,phase,player),others)),Con{Combat.player(Combat.prepare(kind,phase,player)),others},Combat.finish_roster(Combat.prepare(kind,phase,player),others)) : N.Navigation.All(_)
              Tuple{Combat.prepare_bounds(kind,phase,player,player_ok),others_ok}

law Combat.run_bounds:
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +kind: Combat.Kind
  for +phase: U32
  for +valid: N.Navigation.All(players)
  N.Navigation.All(Combat.roster(Combat.run(players,target,kind,phase)))

def Combat.run_bounds(players,target,kind,phase,valid): Combat.apply_taken_bounds(P.Players.take(players,target),kind,phase,N.Navigation.take_bounds(players,target,valid))

law Combat.apply_taken_count:
  for +taken: P.Players.Take
  for +kind: Combat.Kind
  for +phase: U32
  {P.Players.length(Combat.roster(Combat.apply_taken(taken,kind,phase))) == P.Players.length(P.Players.restore(taken)) : Nat}

def Combat.apply_taken_count(taken,kind,phase):
  match taken:
    case P.Players.Take{others,found}:
      match found:
        case None{}: {==}
        case Some{player}:
          %Equal.sym(List<&2,P.Players.State>,Combat.roster(Combat.finish(Combat.prepare(kind,phase,player),others)),Con{Combat.player(Combat.prepare(kind,phase,player)),others},Combat.finish_roster(Combat.prepare(kind,phase,player),others)) : {P.Players.length(_) == Succ{P.Players.length(others)} : Nat}
          {==}

law Combat.run_count:
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +kind: Combat.Kind
  for +phase: U32
  {P.Players.length(Combat.roster(Combat.run(players,target,kind,phase))) == P.Players.length(players) : Nat}

def Combat.run_count(players,target,kind,phase):
  Equal.trans(Nat,P.Players.length(Combat.roster(Combat.run(players,target,kind,phase))),P.Players.length(P.Players.restore(P.Players.take(players,target))),P.Players.length(players),Combat.apply_taken_count(P.Players.take(players,target),kind,phase),P.Players.take_count(players,target))

law Combat.run_missing:
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +kind: Combat.Kind
  for +phase: U32
  for +missing: {P.Players.has_id(players,target) == False{} : Bool}
  {Combat.run(players,target,kind,phase) == Combat.Result{players,None{}} : Combat.Result}

def Combat.run_missing(players,target,kind,phase,missing):
  %Equal.sym(P.Players.Take,P.Players.take(players,target),P.Players.Take{players,None{}},P.Players.take_missing(players,target,missing)) : {Combat.apply_taken(_,kind,phase) == Combat.Result{players,None{}} : Combat.Result}
  {==}

def Combat.frames(players: List<&2,P.Players.State>) -> List<&2,Combat.Frame>:
  match players:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{Combat.frame(head),Combat.frames(rest)}

law Combat.apply_taken_frames:
  for +taken: P.Players.Take
  for +kind: Combat.Kind
  for +phase: U32
  {Combat.frames(Combat.roster(Combat.apply_taken(taken,kind,phase))) == Combat.frames(P.Players.restore(taken)) : List<&2,Combat.Frame>}

def Combat.apply_taken_frames(taken,kind,phase):
  match taken:
    case P.Players.Take{others,found}:
      match found:
        case None{}: {==}
        case Some{player}:
          %Equal.sym(List<&2,P.Players.State>,Combat.roster(Combat.finish(Combat.prepare(kind,phase,player),others)),Con{Combat.player(Combat.prepare(kind,phase,player)),others},Combat.finish_roster(Combat.prepare(kind,phase,player),others)) : {Combat.frames(_) == Con{Combat.frame(player),Combat.frames(others)} : List<&2,Combat.Frame>}
          %Combat.prepare_frame(kind,phase,player) : {Con{Combat.frame(Combat.player(Combat.prepare(kind,phase,player))),Combat.frames(others)} == Con{_,Combat.frames(others)} : List<&2,Combat.Frame>}
          {==}

type Combat.Conserved<-before: List<&2,P.Players.State>,-after: List<&2,P.Players.State>> is Data:
  Combat.Conserved{ordered: List<&2,P.Players.State>,permutation: P.Players.Perm<ordered,before>,frames: {Combat.frames(after) == Combat.frames(ordered) : List<&2,Combat.Frame>}}

law Combat.run_conserves:
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +kind: Combat.Kind
  for +phase: U32
  Combat.Conserved<players,Combat.roster(Combat.run(players,target,kind,phase))>

def Combat.run_conserves(players,target,kind,phase):
  Combat.Conserved{P.Players.restore(P.Players.take(players,target)),P.Players.take_restores(players,target),Combat.apply_taken_frames(P.Players.take(players,target),kind,phase)}

law Combat.stamp_other_player:
  for +kind: Combat.Kind
  for +player: P.Players.State
  {Combat.cooldown(Combat.other(kind),P.Players.vitals(Combat.stamp(kind,player))) == Combat.cooldown(Combat.other(kind),P.Players.vitals(player)) : U32}

def Combat.stamp_other_player(kind,player):
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}: Combat.stamp_other(kind,vitals)

law Combat.gate_other:
  for +blocked: Bool
  for +kind: Combat.Kind
  for +player: P.Players.State
  {Combat.cooldown(Combat.other(kind),P.Players.vitals(Combat.player(Combat.gate(blocked,kind,player)))) == Combat.cooldown(Combat.other(kind),P.Players.vitals(player)) : U32}

def Combat.gate_other(blocked,kind,player):
  match blocked:
    case True{}: {==}
    case False{}: Combat.stamp_other_player(kind,player)

law Combat.prepare_other:
  for +kind: Combat.Kind
  for +phase: U32
  for +player: P.Players.State
  {Combat.cooldown(Combat.other(kind),P.Players.vitals(Combat.player(Combat.prepare(kind,phase,player)))) == Combat.cooldown(Combat.other(kind),P.Players.vitals(player)) : U32}

def Combat.prepare_other(kind,phase,player): Combat.gate_other(Combat.blocked(kind,phase,player),kind,player)

law Combat.finish_exact:
  for +step: Combat.Step
  for +others: List<&2,P.Players.State>
  {Combat.finish(step,others) == Combat.Result{Con{Combat.player(step),others},Combat.actor(Combat.accepted(step),Combat.player(step))} : Combat.Result}

def Combat.finish_exact(step,others):
  match step:
    case Combat.Step{player,accepted}: {==}

# The actor exists exactly when admission succeeds, and is the committed record.
law Combat.admit_ready:
  for +kind: Combat.Kind
  for +phase: U32
  for +player: P.Players.State
  for +others: List<&2,P.Players.State>
  for +ready: {Combat.blocked(kind,phase,player) == False{} : Bool}
  {Combat.apply_taken(P.Players.Take{others,Some{player}},kind,phase) == Combat.Result{Con{Combat.stamp(kind,player),others},Some{Combat.stamp(kind,player)}} : Combat.Result}

def Combat.admit_ready(kind,phase,player,others,ready):
  %Equal.sym(Combat.Step,Combat.prepare(kind,phase,player),Combat.Step{Combat.stamp(kind,player),True{}},Combat.ready(kind,phase,player,ready)) : {Combat.finish(_,others) == Combat.Result{Con{Combat.stamp(kind,player),others},Some{Combat.stamp(kind,player)}} : Combat.Result}
  {==}

law Combat.admit_rejected:
  for +kind: Combat.Kind
  for +phase: U32
  for +player: P.Players.State
  for +others: List<&2,P.Players.State>
  for +blocked: {Combat.blocked(kind,phase,player) == True{} : Bool}
  {Combat.apply_taken(P.Players.Take{others,Some{player}},kind,phase) == Combat.Result{Con{player,others},None{}} : Combat.Result}

def Combat.admit_rejected(kind,phase,player,others,blocked):
  %Equal.sym(Combat.Step,Combat.prepare(kind,phase,player),Combat.Step{player,False{}},Combat.reject(kind,phase,player,blocked)) : {Combat.finish(_,others) == Combat.Result{Con{player,others},None{}} : Combat.Result}
  {==}

type Combat.Input is Data:
  Combat.Input{target: U32,kind: Combat.Kind,phase: U32}

def Combat.trace(inputs: List<&2,Combat.Input>,players: List<&2,P.Players.State>) -> List<&2,P.Players.State>:
  match inputs:
    case Nil{}: players
    case Con{head,rest}:
      match head:
        case Combat.Input{target,kind,phase}: Combat.trace(rest,Combat.roster(Combat.run(players,target,kind,phase)))

law Combat.trace_ok:
  for +inputs: List<&2,Combat.Input>
  for +players: List<&2,P.Players.State>
  for +valid: P.Players.All(players)
  P.Players.All(Combat.trace(inputs,players))

def Combat.trace_ok(inputs,players,valid):
  match inputs:
    case Nil{}: valid
    case Con{head,rest}:
      match head:
        case Combat.Input{target,kind,phase}: Combat.trace_ok(rest,Combat.roster(Combat.run(players,target,kind,phase)),Combat.run_ok(players,target,kind,phase,valid))

law Combat.trace_bounds:
  for +inputs: List<&2,Combat.Input>
  for +players: List<&2,P.Players.State>
  for +valid: N.Navigation.All(players)
  N.Navigation.All(Combat.trace(inputs,players))

def Combat.trace_bounds(inputs,players,valid):
  match inputs:
    case Nil{}: valid
    case Con{head,rest}:
      match head:
        case Combat.Input{target,kind,phase}: Combat.trace_bounds(rest,Combat.roster(Combat.run(players,target,kind,phase)),Combat.run_bounds(players,target,kind,phase,valid))
