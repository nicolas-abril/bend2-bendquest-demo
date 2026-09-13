import Base
import ./main.bend as Application
import ./rebuild.bend as R
import ./server.bend as Live
import ./world.bend as Legacy
import ./players.bend as P
import ./players_check.bend as Test
import ./creation_check.bend as F
import ./sessions_check.bend as Names
import ./simulation_check.bend as ST
import ./simulation.bend as S
import ./terrain.bend as T
import ./population.bend as Pop
import ./connections.bend as Conn
import ./vitals.bend as V
import ./game.bend as G

# Independent reconstruction of the previous server loop, including the actual
# legacy add_plr adapter and its list-grade/name conversion.
@unsafe
def previous_world(result: Sigma<&1,&1,T.Terrain.World,(world => U32)>) -> T.Terrain.World:
  match result:
    case Tuple{before_world,pid}: before_world

@unsafe
def previous(before_world: T.Terrain.World,players: List<&2,P.Players.State>) -> T.Terrain.World:
  match players:
    case Nil{}: before_world
    case Con{head,rest}:
      match head:
        case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
          match style:
            case P.Players.Style{skin,hairs,hairc,shirt,hat,cape}:
              match meta:
                case P.Players.Meta{score,kills,found,name}:
                  previous(previous_world(Legacy.Bq.add_plr(before_world,cid,skin,hairs,hairc,shirt,hat,cape,P.Players.text_name(name))),rest)


def maps() -> T.Terrain.Maps: [[9,8,7],[6,5],Nil{}]
def base(hint: U32,players: List<&2,P.Players.State>) -> T.Terrain.World: T.Terrain.world(maps,F.world(hint,players))
def styled(pid: U32,cid: U32,name: String) -> P.Players.State:
  P.Players.State{pid,cid,G.Bq.fresh_hero,P.Players.Pos{3,12,13,2,1},V.Vitals.State{0,91,1,7,8,9},P.Players.Style{4,3,2,1,7,8},P.Players.Quest{9,8,7,6,5,4},P.Players.Meta{123,45,6,Names.name(name)}}

def same(+a: T.Terrain.World,+b: T.Terrain.World) -> Bool: Bool.and(ST.same_state(T.Terrain.simulation(a),T.Terrain.simulation(b)),F.same_maps(T.Terrain.maps(a),T.Terrain.maps(b)))

@unsafe
def checked(label: String,+before_world: T.Terrain.World,+players: List<&2,P.Players.State>) -> IO(Unit):
  Test.verdict(label,Bool.and(same(R.Rebuild.world(players,before_world),previous(before_world,players)),same(Live.Bq.readd_plrs(before_world,players),previous(before_world,players))))

@unsafe
def exact(label: String,before_world: T.Terrain.World,players: List<&2,P.Players.State>,expected: T.Terrain.World) -> IO(Unit): Test.verdict(label,same(Live.Bq.readd_plrs(before_world,players),expected))

@unsafe
def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- checked("rebuild empty",base(1,Nil{}),Nil{})
    Unit <- checked("rebuild preserves existing roster",base(40,[F.player(9,4,"Kept")]),Nil{})
    Unit <- checked("rebuild one",base(1,Nil{}),[F.player(90,7,"Ada")])
    Unit <- checked("rebuild multiplayer order",base(1,Nil{}),[F.player(90,7,"Ada"),F.player(18,4,"Bob"),F.player(5,99,"Cy")])
    Unit <- checked("rebuild reordered old roster",base(1,Nil{}),[F.player(5,99,"Cy"),F.player(90,7,"Ada"),F.player(18,4,"Bob")])
    Unit <- checked("rebuild resets gameplay retains appearance",base(3,Nil{}),[styled(90,7,"Ada")])
    Unit <- checked("rebuild UTF8 name",base(1,Nil{}),[styled(80,8,"Étoile猫")])
    Unit <- checked("rebuild empty name adapter",base(1,Nil{}),[styled(80,8,"")])
    Unit <- checked("rebuild zero hint",base(0,Nil{}),[F.player(9,7,"Ada"),F.player(10,8,"Bob")])
    Unit <- checked("rebuild MAX hint wraps",base(4294967295,Nil{}),[F.player(9,7,"Ada"),F.player(10,8,"Bob")])
    Unit <- checked("rebuild skips occupied PID",base(1,[F.player(1,99,"Kept")]),[F.player(10,7,"Ada"),F.player(20,8,"Bob")])
    Unit <- checked("rebuild MAX collision wraps",base(4294967295,[F.player(4294967295,99,"Kept")]),[F.player(10,7,"Ada"),F.player(20,8,"Bob")])
    Unit <- checked("rebuild MAX CID",base(1,Nil{}),[F.player(90,4294967295,"Max")])
    Unit <- checked("rebuild invalid zero CID retains old rejection",base(1,Nil{}),[F.player(9,0,"Zero"),F.player(10,7,"Ada")])
    Unit <- checked("rebuild duplicate CID retains old rejection",base(1,Nil{}),[F.player(9,7,"First"),F.player(10,7,"Second")])
    Unit <- checked("rebuild existing CID retains old rejection",base(40,[F.player(9,4,"Kept")]),[F.player(90,4,"Other"),F.player(20,8,"Bob")])
    Unit <- checked("rebuild seeded population zero",Pop.Population.fresh(1,0,50),[styled(9,7,"Ada"),styled(10,8,"Bob")])
    Unit <- checked("rebuild seeded population MAX",Pop.Population.fresh(4294967295,4294967295,4294967295),[styled(9,7,"Ada"),styled(10,8,"Bob")])
    Unit <- exact("rebuild exact reversed roster",base(1,Nil{}),[F.player(90,7,"Ada"),F.player(18,4,"Bob")],base(3,[F.player(2,4,"Bob"),F.player(1,7,"Ada")]))
    Unit <- exact("rebuild exact wrapped allocation",base(4294967295,Nil{}),[F.player(90,7,"Ada"),F.player(18,4,"Bob")],base(2,[F.player(1,4,"Bob"),F.player(4294967295,7,"Ada")]))
    IO.pure(Unit,Unit{})
#| PASS rebuild empty
#| PASS rebuild preserves existing roster
#| PASS rebuild one
#| PASS rebuild multiplayer order
#| PASS rebuild reordered old roster
#| PASS rebuild resets gameplay retains appearance
#| PASS rebuild UTF8 name
#| PASS rebuild empty name adapter
#| PASS rebuild zero hint
#| PASS rebuild MAX hint wraps
#| PASS rebuild skips occupied PID
#| PASS rebuild MAX collision wraps
#| PASS rebuild MAX CID
#| PASS rebuild invalid zero CID retains old rejection
#| PASS rebuild duplicate CID retains old rejection
#| PASS rebuild existing CID retains old rejection
#| PASS rebuild seeded population zero
#| PASS rebuild seeded population MAX
#| PASS rebuild exact reversed roster
#| PASS rebuild exact wrapped allocation
