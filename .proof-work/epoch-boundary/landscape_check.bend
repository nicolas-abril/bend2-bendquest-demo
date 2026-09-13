import Base
import ./landscape.bend as L
import ./terrain.bend as T
import ./players.bend as P
import ./navigation.bend as N
import ./interactions.bend as I
import ./world.bend as W
import ./players_check.bend as Test
import ./interactions_check.bend as IT
import ./game.bend as G

def sizes(maps: T.Terrain.Maps) -> Bool:
  match maps:
    case Nil{}: True{}
    case Con{map,rest}: Bool.and(G.Bq.Nat.eq(T.Terrain.length(map),510n),sizes(rest))

def walk(count: Nat,+maps: T.Terrain.Maps,pos: P.Players.Pos) -> P.Players.Pos:
  match count:
    case Zero{}: pos
    case Succ{rest}: walk(rest,maps,T.Terrain.walk_if(maps,pos))

def corridor(+maps: T.Terrain.Maps,+zone: U32) -> Bool:
  Bool.and(Test.same_pos(walk(27n,maps,P.Players.Pos{zone,1,8,1,1}),P.Players.Pos{zone,28,8,1,1}),Test.same_pos(walk(27n,maps,P.Players.Pos{zone,28,8,0,1}),P.Players.Pos{zone,1,8,0,1}))

def corridors(+maps: T.Terrain.Maps) -> Bool:
  Bool.and(corridor(maps,0),Bool.and(corridor(maps,1),Bool.and(corridor(maps,2),corridor(maps,3))))

def on(maps: T.Terrain.Maps,pos: P.Players.Pos) -> Bool:
  T.Terrain.can_walk(maps,pos)

def enters(+maps: T.Terrain.Maps) -> Bool:
  Bool.and(on(maps,N.Navigation.pos(I.Interaction.player(I.Interaction.enter(IT.portal(0),3)))),Bool.and(on(maps,N.Navigation.pos(I.Interaction.player(I.Interaction.enter(IT.portal(1),3)))),Bool.and(on(maps,N.Navigation.pos(I.Interaction.player(I.Interaction.enter(IT.portal(2),3)))),Bool.and(on(maps,N.Navigation.pos(I.Interaction.player(I.Interaction.enter(IT.back_portal(1),3)))),Bool.and(on(maps,N.Navigation.pos(I.Interaction.player(I.Interaction.enter(IT.back_portal(2),3)))),on(maps,N.Navigation.pos(I.Interaction.player(I.Interaction.enter(IT.back_portal(3),3)))))))))

def npc_path(+maps: T.Terrain.Maps) -> Bool:
  +up = walk(4n,maps,P.Players.Pos{0,4,8,2,1})
  +right = walk(5n,maps,N.Navigation.control(up,1,1))
  Bool.and(Test.same_pos(up,P.Players.Pos{0,4,4,2,1}),Test.same_pos(right,P.Players.Pos{0,9,4,1,1}))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- Test.verdict("all four maps have 510 cells seed 0",sizes(W.Bq.gen_maps(0)))
    Unit <- Test.verdict("full portal corridor walks both ways seed 0",corridors(W.Bq.gen_maps(0)))
    Unit <- Test.verdict("all six portal crossings land on floor seed 0",enters(W.Bq.gen_maps(0)))
    Unit <- Test.verdict("spawn can walk to both village NPCs seed 0",npc_path(W.Bq.gen_maps(0)))
    Unit <- Test.verdict("all four maps have 510 cells seed 17",sizes(W.Bq.gen_maps(17)))
    Unit <- Test.verdict("full portal corridor walks both ways seed 17",corridors(W.Bq.gen_maps(17)))
    Unit <- Test.verdict("all six portal crossings land on floor seed 17",enters(W.Bq.gen_maps(17)))
    Unit <- Test.verdict("spawn can walk to both village NPCs seed 17",npc_path(W.Bq.gen_maps(17)))
    Unit <- Test.verdict("all four maps have 510 cells seed 2147483648",sizes(W.Bq.gen_maps(2147483648)))
    Unit <- Test.verdict("full portal corridor walks both ways seed 2147483648",corridors(W.Bq.gen_maps(2147483648)))
    Unit <- Test.verdict("all six portal crossings land on floor seed 2147483648",enters(W.Bq.gen_maps(2147483648)))
    Unit <- Test.verdict("spawn can walk to both village NPCs seed 2147483648",npc_path(W.Bq.gen_maps(2147483648)))
    Unit <- Test.verdict("all four maps have 510 cells seed 4294967295",sizes(W.Bq.gen_maps(4294967295)))
    Unit <- Test.verdict("full portal corridor walks both ways seed 4294967295",corridors(W.Bq.gen_maps(4294967295)))
    Unit <- Test.verdict("all six portal crossings land on floor seed 4294967295",enters(W.Bq.gen_maps(4294967295)))
    Unit <- Test.verdict("spawn can walk to both village NPCs seed 4294967295",npc_path(W.Bq.gen_maps(4294967295)))
    Unit <- Test.verdict("word hash vector 0 0",U32.is_eq(W.Bq.hash2(0,0),0))
    Unit <- Test.verdict("word hash vector 1 509",U32.is_eq(W.Bq.hash2(1,509),1844975641))
    Unit <- Test.verdict("word hash vector 4294967295 4294967295",U32.is_eq(W.Bq.hash2(4294967295,4294967295),2959167593))
    Unit <- Test.verdict("word hash vector 2147483648 510",U32.is_eq(W.Bq.hash2(2147483648,510),1610803394))
    Unit <- Test.verdict("raw generation clips the last two leaves",G.Bq.Nat.eq(T.Terrain.length(L.Landscape.raw(9n,3,4294967295,0)),510n))
    Unit <- Test.verdict("out of range map update preserves all cells",IT.same_words(L.Landscape.set([1,2,3],3n,9),[1,2,3]))
    return Unit{}

#| PASS all four maps have 510 cells seed 0
#| PASS full portal corridor walks both ways seed 0
#| PASS all six portal crossings land on floor seed 0
#| PASS spawn can walk to both village NPCs seed 0
#| PASS all four maps have 510 cells seed 17
#| PASS full portal corridor walks both ways seed 17
#| PASS all six portal crossings land on floor seed 17
#| PASS spawn can walk to both village NPCs seed 17
#| PASS all four maps have 510 cells seed 2147483648
#| PASS full portal corridor walks both ways seed 2147483648
#| PASS all six portal crossings land on floor seed 2147483648
#| PASS spawn can walk to both village NPCs seed 2147483648
#| PASS all four maps have 510 cells seed 4294967295
#| PASS full portal corridor walks both ways seed 4294967295
#| PASS all six portal crossings land on floor seed 4294967295
#| PASS spawn can walk to both village NPCs seed 4294967295
#| PASS word hash vector 0 0
#| PASS word hash vector 1 509
#| PASS word hash vector 4294967295 4294967295
#| PASS word hash vector 2147483648 510
#| PASS raw generation clips the last two leaves
#| PASS out of range map update preserves all cells
