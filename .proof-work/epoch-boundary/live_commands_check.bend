import Base
import ./main.bend as Application
import ./world.bend as W
import ./live_commands.bend as LC
import ./inventory.bend as I
import ./interactions.bend as Interact
import ./terrain.bend as Terrain
import ./simulation.bend as S
import ./players.bend as P
import ./game.bend as Game
import ./compat.bend as C
import ./support.bend as Support
import ./data.bend as Data
import ./inventory_check.bend as Inv
import ./interactions_check.bend as Inter
import ./players_check.bend as Test
import ./rebuild_check.bend as Old

# Preserved original complete command/lookup/result bodies.
law Previous.sigils:
  (@+m_0: W.Bq.WMeta -> U32)

law Previous.enter:
  (@+w_0: W.Bq.World -> (@+pid_1: U32 -> C.Bq.Pair.Pair(W.Bq.World, (__2 => List<&1, W.Bq.OutL>))))

law Previous.talk:
  (@+w_0: W.Bq.World -> (@+pid_1: U32 -> (@+npc_2: U32 -> C.Bq.Pair.Pair(W.Bq.World, (__3 => List<&1, W.Bq.OutL>)))))

law Previous.halt:
  (@+w_0: W.Bq.World -> (@+pid_1: U32 -> C.Bq.Pair.Pair(W.Bq.World, (__2 => List<&1, W.Bq.OutL>))))

law Previous.move:
  (@+w_0: W.Bq.World -> (@+pid_1: U32 -> (@+d_2: U32 -> C.Bq.Pair.Pair(W.Bq.World, (__3 => List<&1, W.Bq.OutL>)))))

law Previous.buy:
  (@+w_0: W.Bq.World -> (@+pid_1: U32 -> (@+k_2: U32 -> C.Bq.Pair.Pair(W.Bq.World, (__3 => List<&1, W.Bq.OutL>)))))

law Previous.alloc:
  (@+w_0: W.Bq.World -> (@+pid_1: U32 -> (@+s_2: U32 -> C.Bq.Pair.Pair(W.Bq.World, (__3 => List<&1, W.Bq.OutL>)))))

law Previous.uneq:
  (@+w_0: W.Bq.World -> (@+pid_1: U32 -> (@+s_2: U32 -> C.Bq.Pair.Pair(W.Bq.World, (__3 => List<&1, W.Bq.OutL>)))))

law Previous.equip:
  (@+w_0: W.Bq.World -> (@+pid_1: U32 -> (@+k_2: U32 -> C.Bq.Pair.Pair(W.Bq.World, (__3 => List<&1, W.Bq.OutL>)))))

law Previous.quaff:
  (@+w_0: W.Bq.World -> (@+pid_1: U32 -> C.Bq.Pair.Pair(W.Bq.World, (__2 => List<&1, W.Bq.OutL>))))

law Previous.slot:
  (@+s_0: U32 -> Game.Bq.ISlot)

@unsafe
def Previous.sigils():
  \{S.Simulation.Meta: (phase_0 => (wno_1 => (seed_2 => (tick_3 => (t0_4 => (now_5 => (sigils_6 => (fame_t_7 => (nextpid_8 => (nextmid_9 => sigils_6)))))))))); \{}}
def Output.same_line(a: List<&1,Char>,b: List<&1,Char>) -> Bool: Test.same_name(P.Players.share_name(a),P.Players.share_name(b))

@unsafe
def Previous.near(found: Maybe<&2, P.Players.State>) -> Bool:
  match found:
    case None{}: False{}
    case Some{player}:
      match player:
        case P.Players.State{pid, cid, hero, pos, vitals, style, quest, meta}:
          match pos:
            case P.Players.Pos{zone, x, y, dir, moving}:
              U32.is_eq(W.Bq.near_shop(zone, x, y), 1)

@unsafe
def Previous.inventory_result(wm: W.Bq.WMeta, mobs: List<&2, W.Bq.Mob>, maps: List<&2,List<&2,U32>>, result: I.Inventory.Result) -> Sigma<&1, &1, W.Bq.World, (world => List<&1, W.Bq.OutL>)>:
  match result:
    case I.Inventory.Result{players, reply}:
      Tuple{Terrain.Terrain.World{wm, players, mobs, maps}, W.Bq.inventory_reply(reply)}

@unsafe
def Previous.interaction_result(+wm: W.Bq.WMeta, +mobs: List<&2,W.Bq.Mob>, +maps: List<&2,List<&2,U32>>, result: Interact.Interaction.Result) -> C.Bq.Pair.Pair(W.Bq.World,(w => List<&1,W.Bq.OutL>)):
  match result:
    case Interact.Interaction.Result{players,reply}:
      Tuple{Terrain.Terrain.World{wm,players,mobs,maps},W.Bq.interaction_reply(reply,maps,Previous.sigils(wm))}

@unsafe
def Previous.interact(world: W.Bq.World, pid: U32, command: Interact.Interaction.Command) -> C.Bq.Pair.Pair(W.Bq.World,(w => List<&1,W.Bq.OutL>)):
  match world:
    case Terrain.Terrain.World{wm,players,mobs,maps}:
      Previous.interaction_result(wm,mobs,maps,Interact.Interaction.run(players,pid,command))

@unsafe
def Previous.hop(world: W.Bq.World, pid: U32, op: Game.Bq.HOp) -> Sigma<&1, &1, W.Bq.World, (world => List<&1, W.Bq.OutL>)>:
  match world:
    case Terrain.Terrain.World{wm, players, mobs, maps}:
      +taken = P.Players.take(players, pid)
      Previous.inventory_result(wm, mobs, maps, I.Inventory.apply_taken(taken, op, Previous.near(P.Players.found(taken)), Data.Bq.POTION_HEAL))

@unsafe
def Previous.enter(world,pid):
  match world:
    case Terrain.Terrain.World{wm,players,mobs,maps}:
      Previous.interaction_result(wm,mobs,maps,Interact.Interaction.run(players,pid,Interact.Interaction.Enter{Previous.sigils(wm)}))

@unsafe
def Previous.talk(world,pid,npc):
  Previous.interact(world,pid,Interact.Interaction.Talk{npc})

@unsafe
def Previous.halt(world,pid):
  Previous.interact(world,pid,Interact.Interaction.Halt{})

@unsafe
def Previous.move(world,pid,direction):
  Previous.interact(world,pid,Interact.Interaction.Move{direction})

@unsafe
def Previous.slot():
  (s_0 => (+apply_127 = {(s_0 => (word => C.Bq.word_case(Game.Bq.ISlot, word, 0, (unit => (+apply_128 = {(s_0 => (word => C.Bq.word_case(Game.Bq.ISlot, word, 0, (unit => (+apply_129 = {(word => C.Bq.word_case(Game.Bq.ISlot, word, 0, (unit => Game.Bq.ISlot.SlotC{}), (_1153_0 => Game.Bq.ISlot.SlotH{}), 0)) : (@+___0: U32 -> Game.Bq.ISlot)}; apply_129(C.Bq.bit(U32.is_eq(s_0, 2))))), (_1155_1 => Game.Bq.ISlot.SlotA{}), 0))) : (@+s_0: U32 -> (@+___1: U32 -> Game.Bq.ISlot))}; apply_128(s_0, C.Bq.bit(U32.is_eq(s_0, 1))))), (_1157_1 => Game.Bq.ISlot.SlotW{}), 0))) : (@+s_0: U32 -> (@+___1: U32 -> Game.Bq.ISlot))}; apply_127(s_0, C.Bq.bit(U32.is_eq(s_0, 0)))))

@unsafe
def Previous.buy():
  (w_0 => (pid_1 => (k_2 => Previous.hop(w_0, pid_1, Game.Bq.HOp.Buy{Support.Bq.Nat.from_u32(Support.Bq.U32.min(k_2, 17))}))))

@unsafe
def Previous.alloc():
  (w_0 => (pid_1 => (s_2 => Previous.hop(w_0, pid_1, Game.Bq.HOp.Alloc{Support.Bq.Nat.from_u32(Support.Bq.U32.min(s_2, 2))}))))

@unsafe
def Previous.uneq():
  (w_0 => (pid_1 => (s_2 => Previous.hop(w_0, pid_1, Game.Bq.HOp.Unequip{Previous.slot(s_2)}))))

@unsafe
def Previous.equip():
  (w_0 => (pid_1 => (k_2 => Previous.hop(w_0, pid_1, Game.Bq.HOp.Equip{Support.Bq.Nat.from_u32(Support.Bq.U32.min(k_2, 17))}))))

@unsafe
def Previous.quaff():
  (w_0 => (pid_1 => Previous.hop(w_0, pid_1, Game.Bq.HOp.Quaff{})))



def Output.same_out(a: W.Bq.OutL,b: W.Bq.OutL) -> Bool:
  match a:
    case W.Bq.OutL.All{line}:
      match b:
        case W.Bq.OutL.All{other_line}: Output.same_line(line,other_line)
        case W.Bq.OutL.To{other_cid,other_line}: False{}
        case W.Bq.OutL.ZoneL{other_zone,other_line}: False{}
        case W.Bq.OutL.Log{other_line}: False{}
    case W.Bq.OutL.To{cid,line}:
      match b:
        case W.Bq.OutL.All{other_line}: False{}
        case W.Bq.OutL.To{other_cid,other_line}: Bool.and(U32.is_eq(cid,other_cid),Output.same_line(line,other_line))
        case W.Bq.OutL.ZoneL{other_zone,other_line}: False{}
        case W.Bq.OutL.Log{other_line}: False{}
    case W.Bq.OutL.ZoneL{zone,line}:
      match b:
        case W.Bq.OutL.All{other_line}: False{}
        case W.Bq.OutL.To{other_cid,other_line}: False{}
        case W.Bq.OutL.ZoneL{other_zone,other_line}: Bool.and(U32.is_eq(zone,other_zone),Output.same_line(line,other_line))
        case W.Bq.OutL.Log{other_line}: False{}
    case W.Bq.OutL.Log{line}:
      match b:
        case W.Bq.OutL.All{other_line}: False{}
        case W.Bq.OutL.To{other_cid,other_line}: False{}
        case W.Bq.OutL.ZoneL{other_zone,other_line}: False{}
        case W.Bq.OutL.Log{other_line}: Output.same_line(line,other_line)

def Output.same_outs(a: List<&1,W.Bq.OutL>,b: List<&1,W.Bq.OutL>) -> Bool:
  match a:
    case Nil{}:
      match b:
        case Nil{}: True{}
        case Con{head,rest}: False{}
    case Con{head,rest}:
      match b:
        case Nil{}: False{}
        case Con{other,later}: Bool.and(Output.same_out(head,other),Output.same_outs(rest,later))

def Output.same_result(a: Terrain.Terrain.World & List<&1,W.Bq.OutL>,b: Terrain.Terrain.World & List<&1,W.Bq.OutL>) -> Bool:
  match a:
    case Tuple{world,outs}:
      match b:
        case Tuple{other,lines}: Bool.and(Old.same(world,other),Output.same_outs(outs,lines))

def Output.after(result: Terrain.Terrain.World & List<&1,W.Bq.OutL>) -> Terrain.Terrain.World:
  match result:
    case Tuple{world,outs}: world

def same_bool(a: Bool,b: Bool) -> Bool:
  match a:
    case True{}: b
    case False{}: Bool.not(b)

type CommandCase is Data:
  CommandCase.Buy{pid: U32,kind: U32}
  CommandCase.Equip{pid: U32,kind: U32}
  CommandCase.Unequip{pid: U32,slot: U32}
  CommandCase.Alloc{pid: U32,stat: U32}
  CommandCase.Quaff{pid: U32}
  CommandCase.Hop{pid: U32,op: Game.Bq.HOp}
  CommandCase.Move{pid: U32,direction: U32}
  CommandCase.Halt{pid: U32}
  CommandCase.Talk{pid: U32,npc: U32}
  CommandCase.Enter{pid: U32}

@unsafe
def current(op: CommandCase,world: Terrain.Terrain.World) -> Terrain.Terrain.World & List<&1,W.Bq.OutL>:
  match op:
    case CommandCase.Buy{pid,kind}: W.Bq.cmd_buy(world,pid,kind)
    case CommandCase.Equip{pid,kind}: W.Bq.cmd_equip(world,pid,kind)
    case CommandCase.Unequip{pid,slot}: W.Bq.cmd_uneq(world,pid,slot)
    case CommandCase.Alloc{pid,stat}: W.Bq.cmd_alloc(world,pid,stat)
    case CommandCase.Quaff{pid}: W.Bq.cmd_quaff(world,pid)
    case CommandCase.Hop{pid,op}: W.Bq.cmd_hop(world,pid,op)
    case CommandCase.Move{pid,direction}: W.Bq.cmd_move(world,pid,direction)
    case CommandCase.Halt{pid}: W.Bq.cmd_halt(world,pid)
    case CommandCase.Talk{pid,npc}: W.Bq.cmd_talk(world,pid,npc)
    case CommandCase.Enter{pid}: W.Bq.cmd_enter(world,pid)

@unsafe
def previous(op: CommandCase,world: Terrain.Terrain.World) -> Terrain.Terrain.World & List<&1,W.Bq.OutL>:
  match op:
    case CommandCase.Buy{pid,kind}: Previous.buy(world,pid,kind)
    case CommandCase.Equip{pid,kind}: Previous.equip(world,pid,kind)
    case CommandCase.Unequip{pid,slot}: Previous.uneq(world,pid,slot)
    case CommandCase.Alloc{pid,stat}: Previous.alloc(world,pid,stat)
    case CommandCase.Quaff{pid}: Previous.quaff(world,pid)
    case CommandCase.Hop{pid,op}: Previous.hop(world,pid,op)
    case CommandCase.Move{pid,direction}: Previous.move(world,pid,direction)
    case CommandCase.Halt{pid}: Previous.halt(world,pid)
    case CommandCase.Talk{pid,npc}: Previous.talk(world,pid,npc)
    case CommandCase.Enter{pid}: Previous.enter(world,pid)

@unsafe
def checked(label: String,+op: CommandCase,+world: Terrain.Terrain.World) -> IO(Unit): Test.verdict(label,Output.same_result(current(op,world),previous(op,world)))

@unsafe
def near(label: String,+found: Maybe<&2,P.Players.State>) -> IO(Unit): Test.verdict(label,Bool.and(same_bool(LC.LiveCommands.near(found),Previous.near(found)),same_bool(W.Bq.inventory_near(found),Previous.near(found))))

@unsafe
def twice(label: String,+first: CommandCase,+last: CommandCase,+world: Terrain.Terrain.World) -> IO(Unit):
  Test.verdict(label,Bool.and(Output.same_result(current(first,world),previous(first,world)),Output.same_result(current(last,Output.after(current(first,world))),previous(last,Output.after(previous(first,world))))))

@unsafe
def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- near("live command shop missing",None{})
    Unit <- near("live command shop inside",Some{Inv.fresh})
    Unit <- near("live command shop left boundary",Some{Inv.player(Game.Bq.fresh_hero,20,0,0,7)})
    Unit <- near("live command shop right boundary",Some{Inv.player(Game.Bq.fresh_hero,20,0,0,11)})
    Unit <- near("live command shop outside",Some{Inv.player(Game.Bq.fresh_hero,20,0,0,12)})
    Unit <- near("live command shop wrong zone",Some{Inv.player(Game.Bq.fresh_hero,20,0,1,9)})
    Unit <- near("live command shop MAX coordinate",Some{Inv.player(Game.Bq.fresh_hero,20,0,0,4294967295)})
    Unit <- near("live command shop dead profile",Some{Inv.departed})
    Unit <- checked("live command funded buy",CommandCase.Buy{2,0},Inter.fixture_world([Test.a,Inv.fresh,Test.c],7))
    Unit <- checked("live command poor buy",CommandCase.Buy{2,0},Inter.fixture_world([Test.a,Inv.player(Inv.bare(Nil{},0n,0n),20,0,0,9),Test.c],7))
    Unit <- checked("live command distant buy",CommandCase.Buy{2,0},Inter.fixture_world([Test.a,Inv.player(Game.Bq.fresh_hero,20,0,0,20),Test.c],7))
    Unit <- checked("live command wrong zone buy",CommandCase.Buy{2,0},Inter.fixture_world([Test.a,Inv.player(Game.Bq.fresh_hero,20,0,1,9),Test.c],7))
    Unit <- checked("live command dead buy",CommandCase.Buy{2,0},Inter.fixture_world([Test.a,Inv.departed,Test.c],7))
    Unit <- checked("live command MAX item clamp",CommandCase.Buy{2,4294967295},Inter.fixture_world([Test.a,Inv.fresh,Test.c],7))
    Unit <- checked("live command equip owned",CommandCase.Equip{2,1},Inter.fixture_world([Test.a,Inv.sword,Test.c],7))
    Unit <- checked("live command equip missing",CommandCase.Equip{2,1},Inter.fixture_world([Test.a,Inv.fresh,Test.c],7))
    Unit <- checked("live command equip MAX",CommandCase.Equip{2,4294967295},Inter.fixture_world([Test.a,Inv.amulet,Test.c],7))
    Unit <- checked("live command unequip weapon",CommandCase.Unequip{2,0},Inter.fixture_world([Test.a,Inv.armed,Test.c],7))
    Unit <- checked("live command unequip charm",CommandCase.Unequip{2,3},Inter.fixture_world([Test.a,Inv.amulet,Test.c],7))
    Unit <- checked("live command unequip MAX slot",CommandCase.Unequip{2,4294967295},Inter.fixture_world([Test.a,Inv.amulet,Test.c],7))
    Unit <- checked("live command drink stocked",CommandCase.Quaff{2},Inter.fixture_world([Test.a,Inv.stocked,Test.c],7))
    Unit <- checked("live command drink empty",CommandCase.Quaff{2},Inter.fixture_world([Test.a,Inv.fresh,Test.c],7))
    Unit <- checked("live command drink dead",CommandCase.Quaff{2},Inter.fixture_world([Test.a,Inv.departed,Test.c],7))
    Unit <- checked("live command allocate point",CommandCase.Alloc{2,0},Inter.fixture_world([Test.a,Inv.player(Inv.bare(Nil{},10n,1n),20,0,0,9),Test.c],7))
    Unit <- checked("live command allocate missing point",CommandCase.Alloc{2,0},Inter.fixture_world([Test.a,Inv.fresh,Test.c],7))
    Unit <- checked("live command allocate MAX",CommandCase.Alloc{2,4294967295},Inter.fixture_world([Test.a,Inv.player(Inv.bare(Nil{},10n,1n),20,0,0,9),Test.c],7))
    Unit <- checked("live command direct level operation",CommandCase.Hop{2,Game.Bq.HOp.LevelUp{}},Inter.fixture_world([Test.a,Inv.fresh,Test.c],7))
    Unit <- checked("live command missing player",CommandCase.Buy{99,0},Inter.fixture_world([Test.a,Inv.fresh,Test.c],7))
    Unit <- checked("live command move zero",CommandCase.Move{2,0},Inter.fixture_world([Test.a,Inter.elder_ready,Test.c],0))
    Unit <- checked("live command move three",CommandCase.Move{2,3},Inter.fixture_world([Test.a,Inter.elder_ready,Test.c],0))
    Unit <- checked("live command move masks four",CommandCase.Move{2,4},Inter.fixture_world([Test.a,Inter.elder_ready,Test.c],0))
    Unit <- checked("live command move masks MAX",CommandCase.Move{2,4294967295},Inter.fixture_world([Test.a,Inter.elder_ready,Test.c],0))
    Unit <- checked("live command halt",CommandCase.Halt{2},Inter.fixture_world([Test.a,Inter.elder_ready,Test.c],0))
    Unit <- checked("live command elder starts",CommandCase.Talk{2,0},Inter.fixture_world([Test.a,Inter.elder_ready,Test.c],0))
    Unit <- checked("live command elder repeat",CommandCase.Talk{2,0},Inter.fixture_world([Test.a,Inter.elder_started,Test.c],0))
    Unit <- checked("live command elder far",CommandCase.Talk{2,0},Inter.fixture_world([Test.a,Inter.fixture_player(2,0,3,4,2,1,0,40),Test.c],0))
    Unit <- checked("live command unknown NPC",CommandCase.Talk{2,4294967295},Inter.fixture_world([Test.a,Inter.elder_ready,Test.c],0))
    Unit <- checked("live command shop talk",CommandCase.Talk{2,1},Inter.fixture_world([Test.a,Inv.fresh,Test.c],0))
    Unit <- checked("live command portal meadow",CommandCase.Enter{2},Inter.fixture_world([Test.a,Inter.portal(0),Test.c],0))
    Unit <- checked("live command portal cavern",CommandCase.Enter{2},Inter.fixture_world([Test.a,Inter.portal(1),Test.c],0))
    Unit <- checked("live command portal sealed",CommandCase.Enter{2},Inter.fixture_world([Test.a,Inter.portal(2),Test.c],0))
    Unit <- checked("live command portal partial sigils",CommandCase.Enter{2},Inter.fixture_world([Test.a,Inter.portal(2),Test.c],3))
    Unit <- checked("live command portal actual full sigils",CommandCase.Enter{2},Inter.fixture_world([Test.a,Inter.portal(2),Test.c],7))
    Unit <- checked("live command portal MAX sigils",CommandCase.Enter{2},Inter.fixture_world([Test.a,Inter.portal(2),Test.c],4294967295))
    Unit <- checked("live command portal final zone",CommandCase.Enter{2},Inter.fixture_world([Test.a,Inter.portal(3),Test.c],7))
    Unit <- checked("live command return portal",CommandCase.Enter{2},Inter.fixture_world([Test.a,Inter.back_portal(3),Test.c],0))
    Unit <- checked("live command talk missing player",CommandCase.Talk{99,0},Inter.fixture_world([Test.a,Inter.elder_ready,Test.c],0))
    Unit <- checked("live command portal missing player",CommandCase.Enter{99},Inter.fixture_world([Test.a,Inter.portal(0),Test.c],0))
    Unit <- twice("live command sequence buy then drink",CommandCase.Buy{2,0},CommandCase.Quaff{2},Inter.fixture_world([Inv.fresh],7))
    Unit <- twice("live command sequence elder twice",CommandCase.Talk{2,0},CommandCase.Talk{2,0},Inter.fixture_world([Inter.elder_ready],0))
    Unit <- twice("live command sequence equip then unequip",CommandCase.Equip{2,1},CommandCase.Unequip{2,0},Inter.fixture_world([Inv.sword],7))
    twice("live command sequence move then halt",CommandCase.Move{2,4294967295},CommandCase.Halt{2},Inter.fixture_world([Inter.elder_ready],0))

#| PASS live command shop missing
#| PASS live command shop inside
#| PASS live command shop left boundary
#| PASS live command shop right boundary
#| PASS live command shop outside
#| PASS live command shop wrong zone
#| PASS live command shop MAX coordinate
#| PASS live command shop dead profile
#| PASS live command funded buy
#| PASS live command poor buy
#| PASS live command distant buy
#| PASS live command wrong zone buy
#| PASS live command dead buy
#| PASS live command MAX item clamp
#| PASS live command equip owned
#| PASS live command equip missing
#| PASS live command equip MAX
#| PASS live command unequip weapon
#| PASS live command unequip charm
#| PASS live command unequip MAX slot
#| PASS live command drink stocked
#| PASS live command drink empty
#| PASS live command drink dead
#| PASS live command allocate point
#| PASS live command allocate missing point
#| PASS live command allocate MAX
#| PASS live command direct level operation
#| PASS live command missing player
#| PASS live command move zero
#| PASS live command move three
#| PASS live command move masks four
#| PASS live command move masks MAX
#| PASS live command halt
#| PASS live command elder starts
#| PASS live command elder repeat
#| PASS live command elder far
#| PASS live command unknown NPC
#| PASS live command shop talk
#| PASS live command portal meadow
#| PASS live command portal cavern
#| PASS live command portal sealed
#| PASS live command portal partial sigils
#| PASS live command portal actual full sigils
#| PASS live command portal MAX sigils
#| PASS live command portal final zone
#| PASS live command return portal
#| PASS live command talk missing player
#| PASS live command portal missing player
#| PASS live command sequence buy then drink
#| PASS live command sequence elder twice
#| PASS live command sequence equip then unequip
#| PASS live command sequence move then halt
