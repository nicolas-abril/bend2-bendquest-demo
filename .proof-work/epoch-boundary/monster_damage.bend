# Actual attack catalogue and post-upkeep damage inputs for monster planning.
# U32 arithmetic retains the current runtime's wrapping semantics.
import Base
import ./monsters.bend as M
import ./roster.bend as R
import ./payouts.bend as P
import ./ai_refs.bend as AI

def MonsterDamage.catalog(+kind: U32) -> U32:
  P.Payout.choose(U32.is_eq(kind,0),4,P.Payout.choose(U32.is_eq(kind,1),6,P.Payout.choose(U32.is_eq(kind,2),10,P.Payout.choose(U32.is_eq(kind,3),14,P.Payout.choose(U32.is_eq(kind,4),18,P.Payout.choose(U32.is_eq(kind,5),22,P.Payout.choose(U32.is_eq(kind,6),14,P.Payout.choose(U32.is_eq(kind,7),22,P.Payout.choose(U32.is_eq(kind,8),30,42)))))))))

def MonsterDamage.current(+kind: U32,hp: U32,maximum: U32) -> U32:
  +base = MonsterDamage.catalog(kind)
  P.Payout.choose(Bool.and(U32.is_eq(kind,9),U32.is_lt(U32.mul(hp,10),U32.mul(maximum,3))),U32.mul(base,2),base)

def MonsterDamage.amount(monster: M.Monsters.State) -> U32:
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}: U32.mul(MonsterDamage.current(kind,hp,maximum),U32.add(1,rare))

def MonsterDamage.list(monsters: List<&2,M.Monsters.State>) -> List<&2,U32>:
  match monsters:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{MonsterDamage.amount(M.Monsters.tick_state(M.Monsters.tick(head))),MonsterDamage.list(rest)}

def MonsterDamage.zones(+monsters: List<&2,M.Monsters.State>) -> AI.AIRefs.Damages:
  AI.AIRefs.Damages{MonsterDamage.list(R.Roster.zone(monsters,0)),MonsterDamage.list(R.Roster.zone(monsters,1)),MonsterDamage.list(R.Roster.zone(monsters,2)),MonsterDamage.list(R.Roster.zone(monsters,3))}
