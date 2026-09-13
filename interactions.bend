# Checked movement controls, NPC conversations, and portal commands.
import Base
import ./game.bend as G
import ./players.bend as P
import ./vitals.bend as V
import ./navigation.bend as N

def Interaction.elder_x() -> U32: 6
def Interaction.elder_y() -> U32: 4
def Interaction.shop_x() -> U32: 9
def Interaction.shop_y() -> U32: 4
def Interaction.talk_score() -> U32: 10

def Interaction.delta(greater: Bool, a: U32, b: U32) -> U32:
  match greater:
    case True{}: U32.sub(a,b)
    case False{}: U32.sub(b,a)

def Interaction.distance(+a: U32, +b: U32) -> U32:
  Interaction.delta(U32.is_ge(a,b),a,b)

def Interaction.near(pos: P.Players.Pos, nx: U32, ny: U32) -> Bool:
  match pos:
    case P.Players.Pos{zone,x,y,dir,moving}:
      Bool.and(U32.is_eq(zone,0),Bool.and(U32.is_le(Interaction.distance(x,nx),2),U32.is_le(Interaction.distance(y,ny),2)))

def Interaction.set_pos(player: P.Players.State, pos: P.Players.Pos) -> P.Players.State:
  match player:
    case P.Players.State{pid,cid,hero,old,vitals,style,quest,meta}: P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}

law Interaction.set_pos_ok:
  for +player: P.Players.State
  for +pos: P.Players.Pos
  for +valid: P.Players.OK<player>
  P.Players.OK<Interaction.set_pos(player,pos)>

def Interaction.set_pos_ok(player,pos,valid):
  match player:
    case P.Players.State{pid,cid,hero,old,vitals,style,quest,meta}:
      match valid:
        case P.Players.OK{vitals_ok,equipped}: P.Players.OK{vitals_ok,equipped}

law Interaction.set_pos_position:
  for +player: P.Players.State
  for +pos: P.Players.Pos
  {N.Navigation.pos(Interaction.set_pos(player,pos)) == pos : P.Players.Pos}

def Interaction.set_pos_position(player,pos):
  match player:
    case P.Players.State{pid,cid,hero,old,vitals,style,quest,meta}: {==}

law Interaction.set_pos_bounds:
  for +player: P.Players.State
  for +pos: P.Players.Pos
  for +valid: N.Navigation.Bounds<pos>
  N.Navigation.Bounds<N.Navigation.pos(Interaction.set_pos(player,pos))>

def Interaction.set_pos_bounds(player,pos,valid):
  %Equal.sym(P.Players.Pos,N.Navigation.pos(Interaction.set_pos(player,pos)),pos,Interaction.set_pos_position(player,pos)) : N.Navigation.Bounds<_>
  valid

def Interaction.move(+player: P.Players.State, direction: U32) -> P.Players.State:
  Interaction.set_pos(player,N.Navigation.control(N.Navigation.pos(player),U32.and(direction,3),1))

def Interaction.halt(+player: P.Players.State) -> P.Players.State:
  Interaction.set_pos(player,N.Navigation.control(N.Navigation.pos(player),N.Navigation.direction(N.Navigation.pos(player)),0))

def Interaction.main(player: P.Players.State) -> U32:
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
      match quest:
        case P.Players.Quest{main,cull,side0,side1,side2,claimed}: main

# Only the main-quest stage and score change when the elder starts a quest.
def Interaction.begin(player: P.Players.State) -> P.Players.State:
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
      match quest:
        case P.Players.Quest{main,cull,side0,side1,side2,claimed}:
          match meta:
            case P.Players.Meta{score,kills,found,name}:
              P.Players.State{pid,cid,hero,pos,vitals,style,P.Players.Quest{1,cull,side0,side1,side2,claimed},P.Players.Meta{U32.add(score,Interaction.talk_score),kills,found,name}}

law Interaction.begin_ok:
  for +player: P.Players.State
  for +valid: P.Players.OK<player>
  P.Players.OK<Interaction.begin(player)>

def Interaction.begin_ok(player,valid):
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
      match quest:
        case P.Players.Quest{main,cull,side0,side1,side2,claimed}:
          match meta:
            case P.Players.Meta{score,kills,found,name}:
              match valid:
                case P.Players.OK{vitals_ok,equipped}: P.Players.OK{vitals_ok,equipped}

law Interaction.begin_position:
  for +player: P.Players.State
  {N.Navigation.pos(Interaction.begin(player)) == N.Navigation.pos(player) : P.Players.Pos}

def Interaction.begin_position(player):
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
      match quest:
        case P.Players.Quest{main,cull,side0,side1,side2,claimed}:
          match meta:
            case P.Players.Meta{score,kills,found,name}: {==}

law Interaction.begin_bounds:
  for +player: P.Players.State
  for +valid: N.Navigation.Bounds<N.Navigation.pos(player)>
  N.Navigation.Bounds<N.Navigation.pos(Interaction.begin(player))>

def Interaction.begin_bounds(player,valid):
  %Equal.sym(P.Players.Pos,N.Navigation.pos(Interaction.begin(player)),N.Navigation.pos(player),Interaction.begin_position(player)) : N.Navigation.Bounds<_>
  valid

type Interaction.Event is Data:
  Interaction.Quiet{}
  Interaction.ElderStart{}
  Interaction.Elder{main: U32}
  Interaction.Shop{}
  Interaction.Sealed{}
  Interaction.Entered{zone: U32}
  Interaction.Returned{zone: U32}

type Interaction.Step is Data:
  Interaction.Step{player: P.Players.State,event: Interaction.Event}

def Interaction.player(step: Interaction.Step) -> P.Players.State:
  match step:
    case Interaction.Step{player,event}: player

def Interaction.elder_gate(start: Bool, +player: P.Players.State) -> Interaction.Step:
  match start:
    case True{}: Interaction.Step{Interaction.begin(player),Interaction.ElderStart{}}
    case False{}: Interaction.Step{player,Interaction.Elder{Interaction.main(player)}}

def Interaction.elder(+player: P.Players.State) -> Interaction.Step:
  Interaction.elder_gate(U32.is_eq(Interaction.main(player),0),player)

def Interaction.shop_gate(near: Bool, player: P.Players.State) -> Interaction.Step:
  match near:
    case True{}: Interaction.Step{player,Interaction.Shop{}}
    case False{}: Interaction.Step{player,Interaction.Quiet{}}

def Interaction.talk_gate(elder: Bool, shop: Bool, player: P.Players.State) -> Interaction.Step:
  match elder:
    case True{}: Interaction.elder(player)
    case False{}: Interaction.shop_gate(shop,player)

def Interaction.talk(+player: P.Players.State, +npc: U32) -> Interaction.Step:
  Interaction.talk_gate(Bool.and(U32.is_eq(npc,0),Interaction.near(N.Navigation.pos(player),Interaction.elder_x,Interaction.elder_y)),Bool.and(U32.is_eq(npc,1),Interaction.near(N.Navigation.pos(player),Interaction.shop_x,Interaction.shop_y)),player)

def Interaction.route_event(route: N.Navigation.Route) -> Interaction.Event:
  match route:
    case N.Navigation.Stay{}: Interaction.Quiet{}
    case N.Navigation.Sealed{}: Interaction.Sealed{}
    case N.Navigation.Travel{zone,forward}:
      match forward:
        case True{}: Interaction.Entered{zone}
        case False{}: Interaction.Returned{zone}

def Interaction.finish_enter(+route: N.Navigation.Route, +player: P.Players.State) -> Interaction.Step:
  Interaction.Step{Interaction.set_pos(player,N.Navigation.land(route,N.Navigation.pos(player),N.Navigation.rules)),Interaction.route_event(route)}

def Interaction.enter(+player: P.Players.State, sigils: U32) -> Interaction.Step:
  Interaction.finish_enter(N.Navigation.route_for(N.Navigation.pos(player),sigils,N.Navigation.rules),player)

type Interaction.Command is Data:
  Interaction.Move{direction: U32}
  Interaction.Halt{}
  Interaction.Talk{npc: U32}
  Interaction.Enter{sigils: U32}

def Interaction.step(command: Interaction.Command, player: P.Players.State) -> Interaction.Step:
  match command:
    case Interaction.Move{direction}: Interaction.Step{Interaction.move(player,direction),Interaction.Quiet{}}
    case Interaction.Halt{}: Interaction.Step{Interaction.halt(player),Interaction.Quiet{}}
    case Interaction.Talk{npc}: Interaction.talk(player,npc)
    case Interaction.Enter{sigils}: Interaction.enter(player,sigils)

law Interaction.move_ok:
  for +player: P.Players.State
  for +direction: U32
  for +valid: P.Players.OK<player>
  P.Players.OK<Interaction.move(player,direction)>

def Interaction.move_ok(player,direction,valid):
  Interaction.set_pos_ok(player,N.Navigation.control(N.Navigation.pos(player),U32.and(direction,3),1),valid)

law Interaction.halt_ok:
  for +player: P.Players.State
  for +valid: P.Players.OK<player>
  P.Players.OK<Interaction.halt(player)>

def Interaction.halt_ok(player,valid):
  Interaction.set_pos_ok(player,N.Navigation.control(N.Navigation.pos(player),N.Navigation.direction(N.Navigation.pos(player)),0),valid)

law Interaction.elder_gate_ok:
  for +start: Bool
  for +player: P.Players.State
  for +valid: P.Players.OK<player>
  P.Players.OK<Interaction.player(Interaction.elder_gate(start,player))>

def Interaction.elder_gate_ok(start,player,valid):
  match start:
    case True{}: Interaction.begin_ok(player,valid)
    case False{}: valid

law Interaction.elder_ok:
  for +player: P.Players.State
  for +valid: P.Players.OK<player>
  P.Players.OK<Interaction.player(Interaction.elder(player))>

def Interaction.elder_ok(player,valid):
  Interaction.elder_gate_ok(U32.is_eq(Interaction.main(player),0),player,valid)

law Interaction.shop_gate_ok:
  for +near: Bool
  for +player: P.Players.State
  for +valid: P.Players.OK<player>
  P.Players.OK<Interaction.player(Interaction.shop_gate(near,player))>

def Interaction.shop_gate_ok(near,player,valid):
  match near:
    case True{}: valid
    case False{}: valid

law Interaction.talk_gate_ok:
  for +elder: Bool
  for +shop: Bool
  for +player: P.Players.State
  for +valid: P.Players.OK<player>
  P.Players.OK<Interaction.player(Interaction.talk_gate(elder,shop,player))>

def Interaction.talk_gate_ok(elder,shop,player,valid):
  match elder:
    case True{}: Interaction.elder_ok(player,valid)
    case False{}: Interaction.shop_gate_ok(shop,player,valid)

law Interaction.talk_ok:
  for +player: P.Players.State
  for +npc: U32
  for +valid: P.Players.OK<player>
  P.Players.OK<Interaction.player(Interaction.talk(player,npc))>

def Interaction.talk_ok(player,npc,valid):
  Interaction.talk_gate_ok(Bool.and(U32.is_eq(npc,0),Interaction.near(N.Navigation.pos(player),Interaction.elder_x,Interaction.elder_y)),Bool.and(U32.is_eq(npc,1),Interaction.near(N.Navigation.pos(player),Interaction.shop_x,Interaction.shop_y)),player,valid)

law Interaction.enter_ok:
  for +player: P.Players.State
  for +sigils: U32
  for +valid: P.Players.OK<player>
  P.Players.OK<Interaction.player(Interaction.enter(player,sigils))>

def Interaction.enter_ok(player,sigils,valid):
  Interaction.set_pos_ok(player,N.Navigation.land(N.Navigation.route_for(N.Navigation.pos(player),sigils,N.Navigation.rules),N.Navigation.pos(player),N.Navigation.rules),valid)

law Interaction.step_ok:
  for +command: Interaction.Command
  for +player: P.Players.State
  for +valid: P.Players.OK<player>
  P.Players.OK<Interaction.player(Interaction.step(command,player))>

def Interaction.step_ok(command,player,valid):
  match command:
    case Interaction.Move{direction}: Interaction.move_ok(player,direction,valid)
    case Interaction.Halt{}: Interaction.halt_ok(player,valid)
    case Interaction.Talk{npc}: Interaction.talk_ok(player,npc,valid)
    case Interaction.Enter{sigils}: Interaction.enter_ok(player,sigils,valid)

law Interaction.move_bounds:
  for +player: P.Players.State
  for +direction: U32
  for +valid: N.Navigation.Bounds<N.Navigation.pos(player)>
  N.Navigation.Bounds<N.Navigation.pos(Interaction.move(player,direction))>

def Interaction.move_bounds(player,direction,valid):
  Interaction.set_pos_bounds(player,N.Navigation.control(N.Navigation.pos(player),U32.and(direction,3),1),N.Navigation.control_bounds(N.Navigation.pos(player),U32.and(direction,3),1,valid))

law Interaction.halt_bounds:
  for +player: P.Players.State
  for +valid: N.Navigation.Bounds<N.Navigation.pos(player)>
  N.Navigation.Bounds<N.Navigation.pos(Interaction.halt(player))>

def Interaction.halt_bounds(player,valid):
  Interaction.set_pos_bounds(player,N.Navigation.control(N.Navigation.pos(player),N.Navigation.direction(N.Navigation.pos(player)),0),N.Navigation.control_bounds(N.Navigation.pos(player),N.Navigation.direction(N.Navigation.pos(player)),0,valid))

law Interaction.elder_gate_bounds:
  for +start: Bool
  for +player: P.Players.State
  for +valid: N.Navigation.Bounds<N.Navigation.pos(player)>
  N.Navigation.Bounds<N.Navigation.pos(Interaction.player(Interaction.elder_gate(start,player)))>

def Interaction.elder_gate_bounds(start,player,valid):
  match start:
    case True{}: Interaction.begin_bounds(player,valid)
    case False{}: valid

law Interaction.elder_bounds:
  for +player: P.Players.State
  for +valid: N.Navigation.Bounds<N.Navigation.pos(player)>
  N.Navigation.Bounds<N.Navigation.pos(Interaction.player(Interaction.elder(player)))>

def Interaction.elder_bounds(player,valid):
  Interaction.elder_gate_bounds(U32.is_eq(Interaction.main(player),0),player,valid)

law Interaction.shop_gate_bounds:
  for +near: Bool
  for +player: P.Players.State
  for +valid: N.Navigation.Bounds<N.Navigation.pos(player)>
  N.Navigation.Bounds<N.Navigation.pos(Interaction.player(Interaction.shop_gate(near,player)))>

def Interaction.shop_gate_bounds(near,player,valid):
  match near:
    case True{}: valid
    case False{}: valid

law Interaction.talk_gate_bounds:
  for +elder: Bool
  for +shop: Bool
  for +player: P.Players.State
  for +valid: N.Navigation.Bounds<N.Navigation.pos(player)>
  N.Navigation.Bounds<N.Navigation.pos(Interaction.player(Interaction.talk_gate(elder,shop,player)))>

def Interaction.talk_gate_bounds(elder,shop,player,valid):
  match elder:
    case True{}: Interaction.elder_bounds(player,valid)
    case False{}: Interaction.shop_gate_bounds(shop,player,valid)

law Interaction.talk_bounds:
  for +player: P.Players.State
  for +npc: U32
  for +valid: N.Navigation.Bounds<N.Navigation.pos(player)>
  N.Navigation.Bounds<N.Navigation.pos(Interaction.player(Interaction.talk(player,npc)))>

def Interaction.talk_bounds(player,npc,valid):
  Interaction.talk_gate_bounds(Bool.and(U32.is_eq(npc,0),Interaction.near(N.Navigation.pos(player),Interaction.elder_x,Interaction.elder_y)),Bool.and(U32.is_eq(npc,1),Interaction.near(N.Navigation.pos(player),Interaction.shop_x,Interaction.shop_y)),player,valid)

law Interaction.enter_bounds:
  for +player: P.Players.State
  for +sigils: U32
  for +valid: N.Navigation.Bounds<N.Navigation.pos(player)>
  N.Navigation.Bounds<N.Navigation.pos(Interaction.player(Interaction.enter(player,sigils)))>

def Interaction.enter_bounds(player,sigils,valid):
  Interaction.set_pos_bounds(player,N.Navigation.land(N.Navigation.route_for(N.Navigation.pos(player),sigils,N.Navigation.rules),N.Navigation.pos(player),N.Navigation.rules),N.Navigation.cross_bounds(N.Navigation.pos(player),sigils,valid))

law Interaction.step_bounds:
  for +command: Interaction.Command
  for +player: P.Players.State
  for +valid: N.Navigation.Bounds<N.Navigation.pos(player)>
  N.Navigation.Bounds<N.Navigation.pos(Interaction.player(Interaction.step(command,player)))>

def Interaction.step_bounds(command,player,valid):
  match command:
    case Interaction.Move{direction}: Interaction.move_bounds(player,direction,valid)
    case Interaction.Halt{}: Interaction.halt_bounds(player,valid)
    case Interaction.Talk{npc}: Interaction.talk_bounds(player,npc,valid)
    case Interaction.Enter{sigils}: Interaction.enter_bounds(player,sigils,valid)

# Fields outside movement, main-quest stage, and score remain identical.
type Interaction.Frame is Data:
  Interaction.Frame{pid: U32,cid: U32,hero: G.Bq.Hero,vitals: V.Vitals.State,style: P.Players.Style,cull: U32,side0: U32,side1: U32,side2: U32,claimed: U32,kills: U32,found: U32,name: List<&2,Char>}

def Interaction.frame(player: P.Players.State) -> Interaction.Frame:
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
      match quest:
        case P.Players.Quest{main,cull,side0,side1,side2,claimed}:
          match meta:
            case P.Players.Meta{score,kills,found,name}: Interaction.Frame{pid,cid,hero,vitals,style,cull,side0,side1,side2,claimed,kills,found,name}

law Interaction.set_pos_frame:
  for +player: P.Players.State
  for +pos: P.Players.Pos
  {Interaction.frame(Interaction.set_pos(player,pos)) == Interaction.frame(player) : Interaction.Frame}

def Interaction.set_pos_frame(player,pos):
  match player:
    case P.Players.State{pid,cid,hero,old,vitals,style,quest,meta}:
      match quest:
        case P.Players.Quest{main,cull,side0,side1,side2,claimed}:
          match meta:
            case P.Players.Meta{score,kills,found,name}: {==}

law Interaction.begin_frame:
  for +player: P.Players.State
  {Interaction.frame(Interaction.begin(player)) == Interaction.frame(player) : Interaction.Frame}

def Interaction.begin_frame(player):
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
      match quest:
        case P.Players.Quest{main,cull,side0,side1,side2,claimed}:
          match meta:
            case P.Players.Meta{score,kills,found,name}: {==}

law Interaction.move_frame:
  for +player: P.Players.State
  for +direction: U32
  {Interaction.frame(Interaction.move(player,direction)) == Interaction.frame(player) : Interaction.Frame}

def Interaction.move_frame(player,direction):
  Interaction.set_pos_frame(player,N.Navigation.control(N.Navigation.pos(player),U32.and(direction,3),1))

law Interaction.halt_frame:
  for +player: P.Players.State
  {Interaction.frame(Interaction.halt(player)) == Interaction.frame(player) : Interaction.Frame}

def Interaction.halt_frame(player):
  Interaction.set_pos_frame(player,N.Navigation.control(N.Navigation.pos(player),N.Navigation.direction(N.Navigation.pos(player)),0))

law Interaction.elder_gate_frame:
  for +start: Bool
  for +player: P.Players.State
  {Interaction.frame(Interaction.player(Interaction.elder_gate(start,player))) == Interaction.frame(player) : Interaction.Frame}

def Interaction.elder_gate_frame(start,player):
  match start:
    case True{}: Interaction.begin_frame(player)
    case False{}: {==}

law Interaction.elder_frame:
  for +player: P.Players.State
  {Interaction.frame(Interaction.player(Interaction.elder(player))) == Interaction.frame(player) : Interaction.Frame}

def Interaction.elder_frame(player):
  Interaction.elder_gate_frame(U32.is_eq(Interaction.main(player),0),player)

law Interaction.shop_gate_frame:
  for +near: Bool
  for +player: P.Players.State
  {Interaction.frame(Interaction.player(Interaction.shop_gate(near,player))) == Interaction.frame(player) : Interaction.Frame}

def Interaction.shop_gate_frame(near,player):
  match near:
    case True{}: {==}
    case False{}: {==}

law Interaction.talk_gate_frame:
  for +elder: Bool
  for +shop: Bool
  for +player: P.Players.State
  {Interaction.frame(Interaction.player(Interaction.talk_gate(elder,shop,player))) == Interaction.frame(player) : Interaction.Frame}

def Interaction.talk_gate_frame(elder,shop,player):
  match elder:
    case True{}: Interaction.elder_frame(player)
    case False{}: Interaction.shop_gate_frame(shop,player)

law Interaction.talk_frame:
  for +player: P.Players.State
  for +npc: U32
  {Interaction.frame(Interaction.player(Interaction.talk(player,npc))) == Interaction.frame(player) : Interaction.Frame}

def Interaction.talk_frame(player,npc):
  Interaction.talk_gate_frame(Bool.and(U32.is_eq(npc,0),Interaction.near(N.Navigation.pos(player),Interaction.elder_x,Interaction.elder_y)),Bool.and(U32.is_eq(npc,1),Interaction.near(N.Navigation.pos(player),Interaction.shop_x,Interaction.shop_y)),player)

law Interaction.enter_frame:
  for +player: P.Players.State
  for +sigils: U32
  {Interaction.frame(Interaction.player(Interaction.enter(player,sigils))) == Interaction.frame(player) : Interaction.Frame}

def Interaction.enter_frame(player,sigils):
  Interaction.set_pos_frame(player,N.Navigation.land(N.Navigation.route_for(N.Navigation.pos(player),sigils,N.Navigation.rules),N.Navigation.pos(player),N.Navigation.rules))

law Interaction.step_frame:
  for +command: Interaction.Command
  for +player: P.Players.State
  {Interaction.frame(Interaction.player(Interaction.step(command,player))) == Interaction.frame(player) : Interaction.Frame}

def Interaction.step_frame(command,player):
  match command:
    case Interaction.Move{direction}: Interaction.move_frame(player,direction)
    case Interaction.Halt{}: Interaction.halt_frame(player)
    case Interaction.Talk{npc}: Interaction.talk_frame(player,npc)
    case Interaction.Enter{sigils}: Interaction.enter_frame(player,sigils)

def Interaction.cid(player: P.Players.State) -> U32:
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}: cid

def Interaction.event(step: Interaction.Step) -> Interaction.Event:
  match step:
    case Interaction.Step{player,event}: event

type Interaction.Reply is Data:
  Interaction.Reply{cid: U32,event: Interaction.Event}

type Interaction.Result is Data:
  Interaction.Result{players: List<&2,P.Players.State>,reply: Maybe<&2,Interaction.Reply>}

def Interaction.roster(result: Interaction.Result) -> List<&2,P.Players.State>:
  match result:
    case Interaction.Result{players,reply}: players

def Interaction.finish_taken(others: List<&2,P.Players.State>, +step: Interaction.Step) -> Interaction.Result:
  Interaction.Result{Con{Interaction.player(step),others},Some{Interaction.Reply{Interaction.cid(Interaction.player(step)),Interaction.event(step)}}}

def Interaction.apply_taken(taken: P.Players.Take, command: Interaction.Command) -> Interaction.Result:
  match taken:
    case P.Players.Take{others,found}:
      match found:
        case None{}: Interaction.Result{others,None{}}
        case Some{player}: Interaction.finish_taken(others,Interaction.step(command,player))

def Interaction.run(players: List<&2,P.Players.State>, target: U32, command: Interaction.Command) -> Interaction.Result:
  Interaction.apply_taken(P.Players.take(players,target),command)

law Interaction.apply_taken_ok:
  for +taken: P.Players.Take
  for +command: Interaction.Command
  for +valid: P.Players.TakeOK<taken>
  P.Players.All(Interaction.roster(Interaction.apply_taken(taken,command)))

def Interaction.apply_taken_ok(taken,command,valid):
  match taken:
    case P.Players.Take{others,found}:
      match found:
        case None{}:
          match valid:
            case P.Players.ValidTake{others_ok,found_ok}: others_ok
        case Some{player}:
          match valid:
            case P.Players.ValidTake{others_ok,found_ok}: Tuple{Interaction.step_ok(command,player,found_ok),others_ok}

law Interaction.run_ok:
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +command: Interaction.Command
  for +valid: P.Players.All(players)
  P.Players.All(Interaction.roster(Interaction.run(players,target,command)))

def Interaction.run_ok(players,target,command,valid):
  Interaction.apply_taken_ok(P.Players.take(players,target),command,P.Players.take_ok(players,target,valid))

law Interaction.apply_taken_bounds:
  for +taken: P.Players.Take
  for +command: Interaction.Command
  for +valid: N.Navigation.All(P.Players.restore(taken))
  N.Navigation.All(Interaction.roster(Interaction.apply_taken(taken,command)))

def Interaction.apply_taken_bounds(taken,command,valid):
  match taken:
    case P.Players.Take{others,found}:
      match found:
        case None{}: valid
        case Some{player}:
          match valid:
            case Tuple{player_ok,others_ok}: Tuple{Interaction.step_bounds(command,player,player_ok),others_ok}

law Interaction.run_bounds:
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +command: Interaction.Command
  for +valid: N.Navigation.All(players)
  N.Navigation.All(Interaction.roster(Interaction.run(players,target,command)))

def Interaction.run_bounds(players,target,command,valid):
  Interaction.apply_taken_bounds(P.Players.take(players,target),command,N.Navigation.take_bounds(players,target,valid))

law Interaction.apply_taken_count:
  for +taken: P.Players.Take
  for +command: Interaction.Command
  {P.Players.length(Interaction.roster(Interaction.apply_taken(taken,command))) == P.Players.length(P.Players.restore(taken)) : Nat}

def Interaction.apply_taken_count(taken,command):
  match taken:
    case P.Players.Take{others,found}:
      match found:
        case None{}: {==}
        case Some{player}: {==}

law Interaction.run_count:
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +command: Interaction.Command
  {P.Players.length(Interaction.roster(Interaction.run(players,target,command))) == P.Players.length(players) : Nat}

def Interaction.run_count(players,target,command):
  Equal.trans(Nat,P.Players.length(Interaction.roster(Interaction.run(players,target,command))),P.Players.length(P.Players.restore(P.Players.take(players,target))),P.Players.length(players),Interaction.apply_taken_count(P.Players.take(players,target),command),P.Players.take_count(players,target))

law Interaction.run_missing:
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +command: Interaction.Command
  for +missing: {P.Players.has_id(players,target) == False{} : Bool}
  {Interaction.run(players,target,command) == Interaction.Result{players,None{}} : Interaction.Result}

def Interaction.run_missing(players,target,command,missing):
  %Equal.sym(P.Players.Take,P.Players.take(players,target),P.Players.Take{players,None{}},P.Players.take_missing(players,target,missing)) : {Interaction.apply_taken(_,command) == Interaction.Result{players,None{}} : Interaction.Result}
  {==}

def Interaction.frames(players: List<&2,P.Players.State>) -> List<&2,Interaction.Frame>:
  match players:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{Interaction.frame(head),Interaction.frames(rest)}

law Interaction.apply_taken_frames:
  for +taken: P.Players.Take
  for +command: Interaction.Command
  {Interaction.frames(Interaction.roster(Interaction.apply_taken(taken,command))) == Interaction.frames(P.Players.restore(taken)) : List<&2,Interaction.Frame>}

def Interaction.apply_taken_frames(taken,command):
  match taken:
    case P.Players.Take{others,found}:
      match found:
        case None{}: {==}
        case Some{player}:
          %Interaction.step_frame(command,player) : {Con{Interaction.frame(Interaction.player(Interaction.step(command,player))),Interaction.frames(others)} == Con{_,Interaction.frames(others)} : List<&2,Interaction.Frame>}
          {==}

type Interaction.Conserved<-before: List<&2,P.Players.State>,-after: List<&2,P.Players.State>> is Data:
  Interaction.Conserved{ordered: List<&2,P.Players.State>,permutation: P.Players.Perm<ordered,before>,frames: {Interaction.frames(after) == Interaction.frames(ordered) : List<&2,Interaction.Frame>}}

law Interaction.run_conserves:
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +command: Interaction.Command
  Interaction.Conserved<players,Interaction.roster(Interaction.run(players,target,command))>

def Interaction.run_conserves(players,target,command):
  Interaction.Conserved{P.Players.restore(P.Players.take(players,target)),P.Players.take_restores(players,target),Interaction.apply_taken_frames(P.Players.take(players,target),command)}

type Interaction.Input is Data:
  Interaction.Input{target: U32,command: Interaction.Command}

def Interaction.trace(inputs: List<&2,Interaction.Input>, players: List<&2,P.Players.State>) -> List<&2,P.Players.State>:
  match inputs:
    case Nil{}: players
    case Con{head,rest}:
      match head:
        case Interaction.Input{target,command}: Interaction.trace(rest,Interaction.roster(Interaction.run(players,target,command)))

law Interaction.trace_ok:
  for +inputs: List<&2,Interaction.Input>
  for +players: List<&2,P.Players.State>
  for +valid: P.Players.All(players)
  P.Players.All(Interaction.trace(inputs,players))

def Interaction.trace_ok(inputs,players,valid):
  match inputs:
    case Nil{}: valid
    case Con{head,rest}:
      match head:
        case Interaction.Input{target,command}: Interaction.trace_ok(rest,Interaction.roster(Interaction.run(players,target,command)),Interaction.run_ok(players,target,command,valid))

law Interaction.trace_bounds:
  for +inputs: List<&2,Interaction.Input>
  for +players: List<&2,P.Players.State>
  for +valid: N.Navigation.All(players)
  N.Navigation.All(Interaction.trace(inputs,players))

def Interaction.trace_bounds(inputs,players,valid):
  match inputs:
    case Nil{}: valid
    case Con{head,rest}:
      match head:
        case Interaction.Input{target,command}: Interaction.trace_bounds(rest,Interaction.roster(Interaction.run(players,target,command)),Interaction.run_bounds(players,target,command,valid))

law Interaction.move_position:
  for +player: P.Players.State
  for +direction: U32
  {N.Navigation.pos(Interaction.move(player,direction)) == N.Navigation.control(N.Navigation.pos(player),U32.and(direction,3),1) : P.Players.Pos}

def Interaction.move_position(player,direction):
  Interaction.set_pos_position(player,N.Navigation.control(N.Navigation.pos(player),U32.and(direction,3),1))

law Interaction.halt_position:
  for +player: P.Players.State
  {N.Navigation.pos(Interaction.halt(player)) == N.Navigation.control(N.Navigation.pos(player),N.Navigation.direction(N.Navigation.pos(player)),0) : P.Players.Pos}

def Interaction.halt_position(player):
  Interaction.set_pos_position(player,N.Navigation.control(N.Navigation.pos(player),N.Navigation.direction(N.Navigation.pos(player)),0))

law Interaction.begin_main:
  for +player: P.Players.State
  {Interaction.main(Interaction.begin(player)) == 1 : U32}

def Interaction.begin_main(player):
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
      match quest:
        case P.Players.Quest{main,cull,side0,side1,side2,claimed}:
          match meta:
            case P.Players.Meta{score,kills,found,name}: {==}

def Interaction.score(player: P.Players.State) -> U32:
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
      match meta:
        case P.Players.Meta{score,kills,found,name}: score

law Interaction.begin_score:
  for +player: P.Players.State
  {Interaction.score(Interaction.begin(player)) == U32.add(Interaction.score(player),10) : U32}

def Interaction.begin_score(player):
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
      match quest:
        case P.Players.Quest{main,cull,side0,side1,side2,claimed}:
          match meta:
            case P.Players.Meta{score,kills,found,name}: {==}

law Interaction.talk_start:
  for +player: P.Players.State
  for +near: {Interaction.near(N.Navigation.pos(player),Interaction.elder_x,Interaction.elder_y) == True{} : Bool}
  for +initial: {U32.is_eq(Interaction.main(player),0) == True{} : Bool}
  {Interaction.talk(player,0) == Interaction.Step{Interaction.begin(player),Interaction.ElderStart{}} : Interaction.Step}

def Interaction.talk_start(player,near,initial):
  %Equal.sym(Bool,Interaction.near(N.Navigation.pos(player),Interaction.elder_x,Interaction.elder_y),True{},near) : {Interaction.talk_gate(_,False{},player) == Interaction.Step{Interaction.begin(player),Interaction.ElderStart{}} : Interaction.Step}
  %Equal.sym(Bool,U32.is_eq(Interaction.main(player),0),True{},initial) : {Interaction.elder_gate(_,player) == Interaction.Step{Interaction.begin(player),Interaction.ElderStart{}} : Interaction.Step}
  {==}

law Interaction.elder_after_begin:
  for +player: P.Players.State
  {Interaction.elder(Interaction.begin(player)) == Interaction.Step{Interaction.begin(player),Interaction.Elder{1}} : Interaction.Step}

def Interaction.elder_after_begin(player):
  %Equal.sym(U32,Interaction.main(Interaction.begin(player)),1,Interaction.begin_main(player)) : {Interaction.elder_gate(U32.is_eq(_,0),Interaction.begin(player)) == Interaction.Step{Interaction.begin(player),Interaction.Elder{1}} : Interaction.Step}
  %Interaction.begin_main(player) : {Interaction.Step{Interaction.begin(player),Interaction.Elder{Interaction.main(Interaction.begin(player))}} == Interaction.Step{Interaction.begin(player),Interaction.Elder{_}} : Interaction.Step}
  {==}

def Interaction.repeat_event(near: Bool) -> Interaction.Event:
  match near:
    case True{}: Interaction.Elder{1}
    case False{}: Interaction.Quiet{}

law Interaction.talk_gate_after_begin:
  for +near: Bool
  for +player: P.Players.State
  {Interaction.talk_gate(near,False{},Interaction.begin(player)) == Interaction.Step{Interaction.begin(player),Interaction.repeat_event(near)} : Interaction.Step}

def Interaction.talk_gate_after_begin(near,player):
  match near:
    case True{}: Interaction.elder_after_begin(player)
    case False{}: {==}

law Interaction.talk_after_begin:
  for +player: P.Players.State
  {Interaction.talk(Interaction.begin(player),0) == Interaction.Step{Interaction.begin(player),Interaction.repeat_event(Interaction.near(N.Navigation.pos(player),Interaction.elder_x,Interaction.elder_y))} : Interaction.Step}

def Interaction.talk_after_begin(player):
  %Equal.sym(P.Players.Pos,N.Navigation.pos(Interaction.begin(player)),N.Navigation.pos(player),Interaction.begin_position(player)) : {Interaction.talk_gate(Interaction.near(_,Interaction.elder_x,Interaction.elder_y),False{},Interaction.begin(player)) == Interaction.Step{Interaction.begin(player),Interaction.repeat_event(Interaction.near(N.Navigation.pos(player),Interaction.elder_x,Interaction.elder_y))} : Interaction.Step}
  Interaction.talk_gate_after_begin(Interaction.near(N.Navigation.pos(player),Interaction.elder_x,Interaction.elder_y),player)

law Interaction.finish_enter_exact:
  for +route: N.Navigation.Route
  for +player: P.Players.State
  {Interaction.finish_enter(route,player) == Interaction.Step{Interaction.set_pos(player,N.Navigation.land(route,N.Navigation.pos(player),N.Navigation.rules)),Interaction.route_event(route)} : Interaction.Step}

def Interaction.finish_enter_exact(route,player): {==}

law Interaction.move_direction:
  for +player: P.Players.State
  for +direction: U32
  {G.Bq.Nat.lt(U32.to_nat(N.Navigation.direction(N.Navigation.pos(Interaction.move(player,direction)))),4n) == True{} : Bool}

def Interaction.move_direction(player,direction):
  %Equal.sym(P.Players.Pos,N.Navigation.pos(Interaction.move(player,direction)),N.Navigation.control(N.Navigation.pos(player),U32.and(direction,3),1),Interaction.move_position(player,direction)) : {G.Bq.Nat.lt(U32.to_nat(N.Navigation.direction(_)),4n) == True{} : Bool}
  %Equal.sym(U32,N.Navigation.direction(N.Navigation.control(N.Navigation.pos(player),U32.and(direction,3),1)),U32.and(direction,3),N.Navigation.control_direction(N.Navigation.pos(player),U32.and(direction,3),1)) : {G.Bq.Nat.lt(U32.to_nat(_),4n) == True{} : Bool}
  N.Navigation.mask_direction(direction)

# Movement controls and portal crossings change position only; in particular
# they cannot reset the quest stage or score between conversations.
type Interaction.Profile is Data:
  Interaction.Profile{pid: U32,cid: U32,hero: G.Bq.Hero,vitals: V.Vitals.State,style: P.Players.Style,quest: P.Players.Quest,meta: P.Players.Meta}

def Interaction.profile(player: P.Players.State) -> Interaction.Profile:
  match player:
    case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}: Interaction.Profile{pid,cid,hero,vitals,style,quest,meta}

law Interaction.set_pos_profile:
  for +player: P.Players.State
  for +pos: P.Players.Pos
  {Interaction.profile(Interaction.set_pos(player,pos)) == Interaction.profile(player) : Interaction.Profile}

def Interaction.set_pos_profile(player,pos):
  match player:
    case P.Players.State{pid,cid,hero,old,vitals,style,quest,meta}: {==}

law Interaction.move_profile:
  for +player: P.Players.State
  for +direction: U32
  {Interaction.profile(Interaction.move(player,direction)) == Interaction.profile(player) : Interaction.Profile}

def Interaction.move_profile(player,direction):
  Interaction.set_pos_profile(player,N.Navigation.control(N.Navigation.pos(player),U32.and(direction,3),1))

law Interaction.halt_profile:
  for +player: P.Players.State
  {Interaction.profile(Interaction.halt(player)) == Interaction.profile(player) : Interaction.Profile}

def Interaction.halt_profile(player):
  Interaction.set_pos_profile(player,N.Navigation.control(N.Navigation.pos(player),N.Navigation.direction(N.Navigation.pos(player)),0))

law Interaction.enter_profile:
  for +player: P.Players.State
  for +sigils: U32
  {Interaction.profile(Interaction.player(Interaction.enter(player,sigils))) == Interaction.profile(player) : Interaction.Profile}

def Interaction.enter_profile(player,sigils):
  Interaction.set_pos_profile(player,N.Navigation.land(N.Navigation.route_for(N.Navigation.pos(player),sigils,N.Navigation.rules),N.Navigation.pos(player),N.Navigation.rules))
