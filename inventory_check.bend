import Base
import ./terrain.bend as Terrain
import ./inventory.bend as I
import ./players.bend as P
import ./vitals.bend as V
import ./game.bend as G
import ./world.bend as W
import ./compat.bend as C
import ./players_check.bend as T
import ./simulation.bend as S
import ./simulation_check.bend as ST

def same_bag(a: List<&2, Nat>, b: List<&2, Nat>) -> Bool:
  match a:
    case Nil{}:
      match b:
        case Nil{}:
          True{}
        case Con{head, rest}:
          False{}
    case Con{ah, at}:
      match b:
        case Nil{}:
          False{}
        case Con{bh, bt}:
          Bool.and(Cmp.is_eq(Nat.cmp(ah, bh)), same_bag(at, bt))

def same_hero(a: G.Bq.Hero, b: G.Bq.Hero) -> Bool:
  match a:
    case G.Bq.Hero.Hero{a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10}:
      match b:
        case G.Bq.Hero.Hero{b0, b1, b2, b3, b4, b5, b6, b7, b8, b9, b10}:
          Bool.and(same_bag(a0, b0), Bool.and(T.same_slot(a1, b1), Bool.and(T.same_slot(a2, b2), Bool.and(T.same_slot(a3, b3), Bool.and(T.same_slot(a4, b4), Bool.and(G.Bq.Nat.eq(a5, b5), Bool.and(G.Bq.Nat.eq(a6, b6), Bool.and(G.Bq.Nat.eq(a7, b7), Bool.and(G.Bq.Nat.eq(a8, b8), Bool.and(G.Bq.Nat.eq(a9, b9), Bool.and(G.Bq.Nat.eq(a10, b10), True{})))))))))))

def same_player(a: P.Players.State, b: P.Players.State) -> Bool:
  match a:
    case P.Players.State{a0, a1, a2, a3, a4, a5, a6, a7}:
      match b:
        case P.Players.State{b0, b1, b2, b3, b4, b5, b6, b7}:
          Bool.and(U32.is_eq(a0, b0), Bool.and(U32.is_eq(a1, b1), Bool.and(same_hero(a2, b2), Bool.and(T.same_pos(a3, b3), Bool.and(T.same_vitals(a4, b4), Bool.and(T.same_style(a5, b5), Bool.and(T.same_quest(a6, b6), Bool.and(T.same_meta(a7, b7), True{}))))))))

def same_players(a: List<&2, P.Players.State>, b: List<&2, P.Players.State>) -> Bool:
  match a:
    case Nil{}:
      match b:
        case Nil{}:
          True{}
        case Con{head, rest}:
          False{}
    case Con{ah, at}:
      match b:
        case Nil{}:
          False{}
        case Con{bh, bt}:
          Bool.and(same_player(ah, bh), same_players(at, bt))

def hero(bag: G.Bq.Bag, weapon: G.Bq.Maybe(Nat), charm: G.Bq.Maybe(Nat), gold: Nat, level: Nat, vitality: Nat, points: Nat) -> G.Bq.Hero:
  G.Bq.Hero.Hero{bag, weapon, Fail{Unit{}}, Fail{Unit{}}, charm, gold, level, 3n, 3n, vitality, points}

def bare(bag: G.Bq.Bag, gold: Nat, points: Nat) -> G.Bq.Hero:
  hero(bag, Fail{Unit{}}, Fail{Unit{}}, gold, 1n, 3n, points)

def player(hero: G.Bq.Hero, hp: U32, dead: U32, zone: U32, x: U32) -> P.Players.State:
  P.Players.State{2, 12, hero, P.Players.Pos{zone,x,4,3,1}, V.Vitals.State{hp,42,dead,7,3,9}, P.Players.Style{1,2,3,4,5,6}, P.Players.Quest{1,2,3,4,5,6}, P.Players.Meta{7,8,9,T.name()}}

def fresh() -> P.Players.State: player(G.Bq.fresh_hero, 20, 0, 0, 9)
def stocked() -> P.Players.State: player(bare([1n],10n,0n), 20, 0, 0, 9)
def bought() -> P.Players.State: player(bare([1n],2n,0n), 20, 0, 0, 9)
def drank() -> P.Players.State: player(bare([0n],10n,0n), 35, 0, 0, 9)
def departed() -> P.Players.State: player(bare([1n],10n,1n), 0, 1, 0, 9)
def sword() -> P.Players.State: player(bare([0n,1n],10n,0n),20,0,0,9)
def armed() -> P.Players.State: player(hero([0n,0n],Done{1n},Fail{Unit{}},10n,1n,3n,0n),20,0,0,9)
def amulet() -> P.Players.State: player(hero(Nil{},Fail{Unit{}},Done{17n},10n,9n,5n,0n),91,0,0,9)
def charm_bag() -> G.Bq.Bag: [0n,0n,0n,0n,0n,0n,0n,0n,0n,0n,0n,0n,0n,0n,0n,0n,0n,1n]
def removed(hp: U32) -> P.Players.State: player(hero(charm_bag,Fail{Unit{}},Fail{Unit{}},10n,9n,5n,0n),hp,0,0,9)
def giant() -> P.Players.State: player(bare([Succ{U32.to_nat(4294967295)}],10n,0n),20,0,0,9)
def giant_drank() -> P.Players.State: player(bare([U32.to_nat(4294967295)],10n,0n),35,0,0,9)

def step(label: String, op: G.Bq.HOp, before: P.Players.State, near: Bool, amount: U32, expected: P.Players.State) -> IO(Unit):
  T.verdict(label, same_player(I.Inventory.step(op,before,near,amount),expected))

def same_notice(a: I.Inventory.Notice, b: I.Inventory.Notice) -> Bool:
  match a:
    case I.Inventory.Quiet{}:
      match b:
        case I.Inventory.Quiet{}: True{}
        case I.Inventory.TooFar{}: False{}
        case I.Inventory.NoGold{}: False{}
    case I.Inventory.TooFar{}:
      match b:
        case I.Inventory.Quiet{}: False{}
        case I.Inventory.TooFar{}: True{}
        case I.Inventory.NoGold{}: False{}
    case I.Inventory.NoGold{}:
      match b:
        case I.Inventory.Quiet{}: False{}
        case I.Inventory.TooFar{}: False{}
        case I.Inventory.NoGold{}: True{}

def list_result(label: String, result: I.Inventory.Result, expected: List<&2,P.Players.State>) -> IO(Unit):
  match result:
    case I.Inventory.Result{players, reply}:
      T.verdict(label,same_players(players,expected))

def meta() -> S.Simulation.Meta: S.Simulation.Meta{1,7,41,23,100,200,3,400,51,450}
def world(players: List<&2,P.Players.State>) -> W.Bq.World: Terrain.Terrain.World{meta,players,Nil{},[[123]]}

def same_maps(maps: List<&2,List<&2,U32>>) -> Bool:
  match maps:
    case Nil{}: False{}
    case Con{head,tail}:
      match head:
        case Nil{}: False{}
        case Con{x,xs}:
          match xs:
            case Con{h,t}: False{}
            case Nil{}:
              match tail:
                case Con{h,t}: False{}
                case Nil{}: U32.is_eq(x,123)

@unsafe
def world_result(label: String, actual: C.Bq.Pair.Pair(W.Bq.World,(w => List<&1,W.Bq.OutL>)), expected: List<&2,P.Players.State>, outputs: U32) -> IO(Unit):
  match actual:
    case Tuple{w,outs}:
      match w:
        case Terrain.Terrain.World{wm,players,mobs,maps}:
          match mobs:
            case Con{h,t}: T.verdict(label,False{})
            case Nil{}:
              +shared_outs = {outs : List<&1,W.Bq.OutL>}
              T.verdict(label,Bool.and(ST.same_meta(wm,meta),Bool.and(same_players(players,expected),Bool.and(same_maps(maps),U32.is_eq(T.out_count(shared_outs),outputs)))))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- step("inventory purchase exact item and gold",G.Bq.HOp.Buy{0n},fresh,True{},40,bought)
    Unit <- step("inventory distant shop rejects",G.Bq.HOp.Buy{0n},fresh,False{},40,fresh)
    Unit <- step("inventory insufficient gold exact no-op",G.Bq.HOp.Buy{0n},bought,True{},40,bought)
    Unit <- step("inventory unsold item rejected",G.Bq.HOp.Buy{17n},fresh,True{},40,fresh)
    Unit <- step("inventory potion consumes and heals",G.Bq.HOp.Quaff{},stocked,False{},40,drank)
    Unit <- step("inventory empty potion exact no-op",G.Bq.HOp.Quaff{},fresh,False{},40,fresh)
    Unit <- step("inventory huge count potion heals",G.Bq.HOp.Quaff{},giant,False{},40,giant_drank)
    Unit <- step("inventory healing saturates",G.Bq.HOp.Quaff{},stocked,False{},4294967295,drank)
    Unit <- step("inventory dead potion no-op",G.Bq.HOp.Quaff{},departed,True{},40,departed)
    Unit <- step("inventory dead purchase no-op",G.Bq.HOp.Buy{0n},departed,True{},40,departed)
    Unit <- step("inventory dead allocation no-op",G.Bq.HOp.Alloc{2n},departed,True{},40,departed)
    Unit <- step("inventory equip transfers sword",G.Bq.HOp.Equip{1n},sword,False{},40,armed)
    Unit <- step("inventory occupied slot rejects",G.Bq.HOp.Equip{1n},armed,False{},40,armed)
    Unit <- step("inventory unequip restores sword",G.Bq.HOp.Unequip{G.Bq.ISlot.SlotW{}},armed,False{},40,player(bare([0n,1n],10n,0n),20,0,0,9))
    Unit <- step("inventory charm removal clamps health",G.Bq.HOp.Unequip{G.Bq.ISlot.SlotC{}},amulet,False{},40,removed(61))
    Unit <- step("inventory charm equip does not heal",G.Bq.HOp.Equip{17n},removed(61),False{},40,player(hero(G.Bq.Bag.sub(charm_bag,G.Bq.one(17n)),Fail{Unit{}},Done{17n},10n,9n,5n,0n),61,0,0,9))
    Unit <- step("inventory vitality spends one point",G.Bq.HOp.Alloc{2n},player(bare(Nil{},10n,1n),35,0,0,9),False{},40,player(hero(Nil{},Fail{Unit{}},Fail{Unit{}},10n,1n,4n,0n),35,0,0,9))
    Unit <- step("inventory no points no-op",G.Bq.HOp.Alloc{2n},fresh,False{},40,fresh)
    Unit <- list_result("inventory lookup retains other players",I.Inventory.run([T.a,fresh,T.c],2,G.Bq.HOp.Buy{0n},True{},40),[bought,T.a,T.c])
    Unit <- list_result("inventory missing target exact roster",I.Inventory.run([T.a,fresh,T.c],99,G.Bq.HOp.Buy{0n},True{},40),[T.a,fresh,T.c])
    Unit <- T.verdict("inventory sequential purchases cannot overspend",same_players(I.Inventory.trace([I.Inventory.Command{2,G.Bq.HOp.Buy{0n},True{}},I.Inventory.Command{2,G.Bq.HOp.Buy{0n},True{}},I.Inventory.Command{2,G.Bq.HOp.Quaff{},False{}}],[fresh],40),[player(bare([0n],2n,0n),35,0,0,9)]))
    Unit <- world_result("server purchase uses checked command",W.Bq.cmd_buy(world([T.a,fresh,T.c]),2,0),[bought,T.a,T.c],0)
    Unit <- world_result("server shop checks actual position",W.Bq.cmd_buy(world([player(G.Bq.fresh_hero,20,0,0,4)]),2,0),[player(G.Bq.fresh_hero,20,0,0,4)],1)
    Unit <- world_result("server shop checks actual zone",W.Bq.cmd_buy(world([player(G.Bq.fresh_hero,20,0,1,9)]),2,0),[player(G.Bq.fresh_hero,20,0,1,9)],1)
    Unit <- world_result("server unfunded purchase feedback",W.Bq.cmd_buy(world([bought]),2,0),[bought],1)
    Unit <- world_result("server huge potion count heals",W.Bq.cmd_quaff(world([giant]),2),[giant_drank],0)
    Unit <- world_result("server dead command no feedback",W.Bq.cmd_buy(world([departed]),2,0),[departed],0)
    Unit <- world_result("server charm removal clamps health",W.Bq.cmd_uneq(world([amulet]),2,3),[removed(61)],0)
    Unit <- world_result("server equip uses checked command",W.Bq.cmd_equip(world([sword]),2,1),[armed],0)
    Unit <- world_result("server allocation clamps wire index",W.Bq.cmd_alloc(world([player(bare(Nil{},10n,1n),35,0,0,9)]),2,4294967295),[player(hero(Nil{},Fail{Unit{}},Fail{Unit{}},10n,1n,4n,0n),35,0,0,9)],0)
    return Unit{}

#| PASS inventory purchase exact item and gold
#| PASS inventory distant shop rejects
#| PASS inventory insufficient gold exact no-op
#| PASS inventory unsold item rejected
#| PASS inventory potion consumes and heals
#| PASS inventory empty potion exact no-op
#| PASS inventory huge count potion heals
#| PASS inventory healing saturates
#| PASS inventory dead potion no-op
#| PASS inventory dead purchase no-op
#| PASS inventory dead allocation no-op
#| PASS inventory equip transfers sword
#| PASS inventory occupied slot rejects
#| PASS inventory unequip restores sword
#| PASS inventory charm removal clamps health
#| PASS inventory charm equip does not heal
#| PASS inventory vitality spends one point
#| PASS inventory no points no-op
#| PASS inventory lookup retains other players
#| PASS inventory missing target exact roster
#| PASS inventory sequential purchases cannot overspend
#| PASS server purchase uses checked command
#| PASS server shop checks actual position
#| PASS server shop checks actual zone
#| PASS server unfunded purchase feedback
#| PASS server huge potion count heals
#| PASS server dead command no feedback
#| PASS server charm removal clamps health
#| PASS server equip uses checked command
#| PASS server allocation clamps wire index
