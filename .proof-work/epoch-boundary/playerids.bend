# Player and connection IDs across authoritative roster operations.
import Base
import ./references.bend as Ref
import ./allocation.bend as A
import ./admission.bend as J
import ./identity.bend as I
import ./players.bend as P
import ./terrain.bend as T
import ./simulation.bend as S
import ./locomotion.bend as Walk
import ./inventory.bend as Inv
import ./interactions.bend as Inter
import ./combat.bend as C
import ./game.bend as G
import ./vitals.bend as V
import ./payouts.bend as Pay
import ./battle.bend as B
import ./monsters.bend as M
import ./roster.bend as R
import ./ai.bend as AI
import ./planning.bend as Plan
import ./population.bend as Pop
import ./landscape.bend as Land

type PlayerIds.Kind is Data:
  PlayerIds.Player{}
  PlayerIds.Connection{}

def PlayerIds.key(kind: PlayerIds.Kind,player: P.Players.State) -> U32:
  match kind:
    case PlayerIds.Player{}: P.Players.id(player)
    case PlayerIds.Connection{}: J.Admission.cid(player)

def PlayerIds.project(+kind: PlayerIds.Kind,players: List<&2,P.Players.State>) -> A.Allocation.Ids:
  match players:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{PlayerIds.key(kind,head),PlayerIds.project(kind,rest)}

law PlayerIds.player_projection:
  for +players: List<&2,P.Players.State>
  {PlayerIds.project(PlayerIds.Player{},players) == J.Admission.pids(players) : A.Allocation.Ids}

def PlayerIds.player_projection(players):
  match players:
    case Nil{}: {==}
    case Con{head,rest}:
      %PlayerIds.player_projection(rest) : {Con{P.Players.id(head),PlayerIds.project(PlayerIds.Player{},rest)} == Con{P.Players.id(head),_} : A.Allocation.Ids}
      {==}

law PlayerIds.connection_projection:
  for +players: List<&2,P.Players.State>
  {PlayerIds.project(PlayerIds.Connection{},players) == J.Admission.cids(players) : A.Allocation.Ids}

def PlayerIds.connection_projection(players):
  match players:
    case Nil{}: {==}
    case Con{head,rest}:
      %PlayerIds.connection_projection(rest) : {Con{J.Admission.cid(head),PlayerIds.project(PlayerIds.Connection{},rest)} == Con{J.Admission.cid(head),_} : A.Allocation.Ids}
      {==}

law PlayerIds.from_admission:
  for +kind: PlayerIds.Kind
  for +players: List<&2,P.Players.State>
  for +valid: J.Admission.Unique<players>
  A.Allocation.Unique(PlayerIds.project(kind,players))

def PlayerIds.from_admission(kind,players,valid):
  match kind:
    case PlayerIds.Player{}:
      match valid:
        case J.Admission.Unique{pids,cids}:
          %Equal.sym(A.Allocation.Ids,PlayerIds.project(PlayerIds.Player{},players),J.Admission.pids(players),PlayerIds.player_projection(players)) : A.Allocation.Unique(_)
          pids
    case PlayerIds.Connection{}:
      match valid:
        case J.Admission.Unique{pids,cids}:
          %Equal.sym(A.Allocation.Ids,PlayerIds.project(PlayerIds.Connection{},players),J.Admission.cids(players),PlayerIds.connection_projection(players)) : A.Allocation.Unique(_)
          cids

law PlayerIds.to_admission:
  for +players: List<&2,P.Players.State>
  for +pids: A.Allocation.Unique(PlayerIds.project(PlayerIds.Player{},players))
  for +cids: A.Allocation.Unique(PlayerIds.project(PlayerIds.Connection{},players))
  J.Admission.Unique<players>

def PlayerIds.to_admission(players,pids,cids):
  J.Admission.Unique{(%PlayerIds.player_projection(players) : A.Allocation.Unique(_); pids),(%PlayerIds.connection_projection(players) : A.Allocation.Unique(_); cids)}
law PlayerIds.absent_swap:
  for +id: U32
  for +first: U32
  for +second: U32
  for +rest: A.Allocation.Ids
  for +valid: A.Allocation.Absent(id,Con{first,Con{second,rest}})
  A.Allocation.Absent(id,Con{second,Con{first,rest}})

def PlayerIds.absent_swap(id,first,second,rest,valid):
  match valid:
    case Tuple{a,later}:
      match later:
        case Tuple{b,tail}: Tuple{b,Tuple{a,tail}}

law PlayerIds.unique_swap:
  for +first: U32
  for +second: U32
  for +rest: A.Allocation.Ids
  for +valid: A.Allocation.Unique(Con{first,Con{second,rest}})
  A.Allocation.Unique(Con{second,Con{first,rest}})

def PlayerIds.unique_swap(first,second,rest,valid):
  match valid:
    case Tuple{first_absent,later}:
      match first_absent:
        case Tuple{different,first_rest}:
          match later:
            case Tuple{second_rest,tail}: Tuple{Tuple{I.Identity.neq_sym(first,second,different),second_rest},Tuple{first_rest,tail}}

def PlayerIds.absent_head(id: U32,head: U32,rest: A.Allocation.Ids,valid: A.Allocation.Absent(id,Con{head,rest})) -> {U32.is_eq(id,head) == False{} : Bool}:
  match valid:
    case Tuple{different,tail}: different

def PlayerIds.absent_tail(id: U32,head: U32,rest: A.Allocation.Ids,valid: A.Allocation.Absent(id,Con{head,rest})) -> A.Allocation.Absent(id,rest):
  match valid:
    case Tuple{different,tail}: tail

def PlayerIds.unique_head(head: U32,rest: A.Allocation.Ids,valid: A.Allocation.Unique(Con{head,rest})) -> A.Allocation.Absent(head,rest):
  match valid:
    case Tuple{absent,tail}: absent

def PlayerIds.unique_tail(head: U32,rest: A.Allocation.Ids,valid: A.Allocation.Unique(Con{head,rest})) -> A.Allocation.Unique(rest):
  match valid:
    case Tuple{absent,tail}: tail

law PlayerIds.perm_absent:
  for +kind: PlayerIds.Kind
  for -left: List<&2,P.Players.State>
  for -right: List<&2,P.Players.State>
  for +permutation: P.Players.Perm<left,right>
  for +id: U32
  for +valid: A.Allocation.Absent(id,PlayerIds.project(kind,right))
  A.Allocation.Absent(id,PlayerIds.project(kind,left))

def PlayerIds.perm_absent(kind,left,right,permutation,id,valid):
  match permutation:
    case P.Players.Same{equal}:
      %Equal.sym(List<&2,P.Players.State>,left,right,equal) : A.Allocation.Absent(id,PlayerIds.project(kind,_))
      valid
    case P.Players.Common{head,lt,rt,ls,rs,tails}:
      +given = {(%rs : A.Allocation.Absent(id,PlayerIds.project(kind,_)); valid) : A.Allocation.Absent(id,PlayerIds.project(kind,Con{head,rt}))}
      %Equal.sym(List<&2,P.Players.State>,left,Con{head,lt},ls) : A.Allocation.Absent(id,PlayerIds.project(kind,_))
      Tuple{PlayerIds.absent_head(id,PlayerIds.key(kind,head),PlayerIds.project(kind,rt),given),PlayerIds.perm_absent(kind,lt,rt,tails,id,PlayerIds.absent_tail(id,PlayerIds.key(kind,head),PlayerIds.project(kind,rt),given))}
    case P.Players.Swap{first,second,rest,ls,rs}:
      %Equal.sym(List<&2,P.Players.State>,left,Con{first,Con{second,rest}},ls) : A.Allocation.Absent(id,PlayerIds.project(kind,_))
      PlayerIds.absent_swap(id,PlayerIds.key(kind,second),PlayerIds.key(kind,first),PlayerIds.project(kind,rest),(%rs : A.Allocation.Absent(id,PlayerIds.project(kind,_)); valid))
    case P.Players.Then{middle,before,after}:
      PlayerIds.perm_absent(kind,left,middle,before,id,PlayerIds.perm_absent(kind,middle,right,after,id,valid))

law PlayerIds.perm_unique:
  for +kind: PlayerIds.Kind
  for -left: List<&2,P.Players.State>
  for -right: List<&2,P.Players.State>
  for +permutation: P.Players.Perm<left,right>
  for +valid: A.Allocation.Unique(PlayerIds.project(kind,right))
  A.Allocation.Unique(PlayerIds.project(kind,left))

def PlayerIds.perm_unique(kind,left,right,permutation,valid):
  match permutation:
    case P.Players.Same{equal}:
      %Equal.sym(List<&2,P.Players.State>,left,right,equal) : A.Allocation.Unique(PlayerIds.project(kind,_))
      valid
    case P.Players.Common{head,lt,rt,ls,rs,tails}:
      +given = {(%rs : A.Allocation.Unique(PlayerIds.project(kind,_)); valid) : A.Allocation.Unique(PlayerIds.project(kind,Con{head,rt}))}
      %Equal.sym(List<&2,P.Players.State>,left,Con{head,lt},ls) : A.Allocation.Unique(PlayerIds.project(kind,_))
      Tuple{PlayerIds.perm_absent(kind,lt,rt,tails,PlayerIds.key(kind,head),PlayerIds.unique_head(PlayerIds.key(kind,head),PlayerIds.project(kind,rt),given)),PlayerIds.perm_unique(kind,lt,rt,tails,PlayerIds.unique_tail(PlayerIds.key(kind,head),PlayerIds.project(kind,rt),given))}
    case P.Players.Swap{first,second,rest,ls,rs}:
      %Equal.sym(List<&2,P.Players.State>,left,Con{first,Con{second,rest}},ls) : A.Allocation.Unique(PlayerIds.project(kind,_))
      PlayerIds.unique_swap(PlayerIds.key(kind,second),PlayerIds.key(kind,first),PlayerIds.project(kind,rest),(%rs : A.Allocation.Unique(PlayerIds.project(kind,_)); valid))
    case P.Players.Then{middle,before,after}:
      PlayerIds.perm_unique(kind,left,middle,before,PlayerIds.perm_unique(kind,middle,right,after,valid))

law PlayerIds.take_unique:
  for +kind: PlayerIds.Kind
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +valid: A.Allocation.Unique(PlayerIds.project(kind,players))
  A.Allocation.Unique(PlayerIds.project(kind,P.Players.restore(P.Players.take(players,target))))

def PlayerIds.take_unique(kind,players,target,valid):
  PlayerIds.perm_unique(kind,P.Players.restore(P.Players.take(players,target)),players,P.Players.take_restores(players,target),valid)

law PlayerIds.others_unique:
  for +kind: PlayerIds.Kind
  for +taken: P.Players.Take
  for +valid: A.Allocation.Unique(PlayerIds.project(kind,P.Players.restore(taken)))
  A.Allocation.Unique(PlayerIds.project(kind,P.Players.others(taken)))

def PlayerIds.others_unique(kind,taken,valid):
  match taken:
    case P.Players.Take{others,found}:
      match found:
        case None{}: valid
        case Some{player}: PlayerIds.unique_tail(PlayerIds.key(kind,player),PlayerIds.project(kind,others),valid)

law PlayerIds.remove_unique:
  for +kind: PlayerIds.Kind
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +valid: A.Allocation.Unique(PlayerIds.project(kind,players))
  A.Allocation.Unique(PlayerIds.project(kind,P.Players.others(P.Players.take(players,target))))

def PlayerIds.remove_unique(kind,players,target,valid):
  PlayerIds.others_unique(kind,P.Players.take(players,target),PlayerIds.take_unique(kind,players,target,valid))

law PlayerIds.remove_both:
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +valid: J.Admission.Unique<players>
  J.Admission.Unique<P.Players.others(P.Players.take(players,target))>

def PlayerIds.remove_both(players,target,valid):
  PlayerIds.to_admission(P.Players.others(P.Players.take(players,target)),PlayerIds.remove_unique(PlayerIds.Player{},players,target,PlayerIds.from_admission(PlayerIds.Player{},players,valid)),PlayerIds.remove_unique(PlayerIds.Connection{},players,target,PlayerIds.from_admission(PlayerIds.Connection{},players,valid)))

# A selected record's IDs occur nowhere in the remaining roster.
def PlayerIds.Separated(+kind: PlayerIds.Kind,+others: List<&2,P.Players.State>,found: Maybe<&2,P.Players.State>) -> Data:
  match found:
    case None{}: Unit
    case Some{player}: A.Allocation.Absent(PlayerIds.key(kind,player),PlayerIds.project(kind,others))

law PlayerIds.separated:
  for +kind: PlayerIds.Kind
  for +taken: P.Players.Take
  for +valid: A.Allocation.Unique(PlayerIds.project(kind,P.Players.restore(taken)))
  PlayerIds.Separated(kind,P.Players.others(taken),P.Players.found(taken))

def PlayerIds.separated(kind,taken,valid):
  match taken:
    case P.Players.Take{others,found}:
      match found:
        case None{}: Unit{}
        case Some{player}: PlayerIds.unique_head(PlayerIds.key(kind,player),PlayerIds.project(kind,others),valid)

law PlayerIds.take_separated:
  for +kind: PlayerIds.Kind
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +valid: A.Allocation.Unique(PlayerIds.project(kind,players))
  PlayerIds.Separated(kind,P.Players.others(P.Players.take(players,target)),P.Players.found(P.Players.take(players,target)))

def PlayerIds.take_separated(kind,players,target,valid):
  PlayerIds.separated(kind,P.Players.take(players,target),PlayerIds.take_unique(kind,players,target,valid))

law PlayerIds.replace_unique:
  for +kind: PlayerIds.Kind
  for +before: P.Players.State
  for +after: P.Players.State
  for +others: List<&2,P.Players.State>
  for +same: {PlayerIds.key(kind,after) == PlayerIds.key(kind,before) : U32}
  for +valid: A.Allocation.Unique(PlayerIds.project(kind,Con{before,others}))
  A.Allocation.Unique(PlayerIds.project(kind,Con{after,others}))

def PlayerIds.replace_unique(kind,before,after,others,same,valid):
  %Equal.sym(U32,PlayerIds.key(kind,after),PlayerIds.key(kind,before),same) : A.Allocation.Unique(Con{_,PlayerIds.project(kind,others)})
  valid


def PlayerIds.inventory_key(kind: PlayerIds.Kind,frame: Inv.Inventory.Frame) -> U32:
  match kind:
    case PlayerIds.Player{}:
      match frame:
        case Inv.Inventory.Frame{pid,cid,pos,xp,dead,respawn,attack,spin,style,quest,meta}: pid
    case PlayerIds.Connection{}:
      match frame:
        case Inv.Inventory.Frame{pid,cid,pos,xp,dead,respawn,attack,spin,style,quest,meta}: cid

law PlayerIds.inventory_key_of:
  for +kind: PlayerIds.Kind
  for +player: P.Players.State
  {PlayerIds.inventory_key(kind,Inv.Inventory.frame(player)) == PlayerIds.key(kind,player) : U32}

def PlayerIds.inventory_key_of(kind,player):
  match kind:
    case PlayerIds.Player{}:
      match player:
        case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
          match vitals:
            case V.Vitals.State{hp,xp,dead,respawn,attack,spin}: {==}
    case PlayerIds.Connection{}:
      match player:
        case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
          match vitals:
            case V.Vitals.State{hp,xp,dead,respawn,attack,spin}: {==}

def PlayerIds.inventory_keys(+kind: PlayerIds.Kind,frames: List<&2,Inv.Inventory.Frame>) -> A.Allocation.Ids:
  match frames:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{PlayerIds.inventory_key(kind,head),PlayerIds.inventory_keys(kind,rest)}

law PlayerIds.inventory_projection:
  for +kind: PlayerIds.Kind
  for +players: List<&2,P.Players.State>
  {PlayerIds.inventory_keys(kind,Inv.Inventory.frames(players)) == PlayerIds.project(kind,players) : A.Allocation.Ids}

def PlayerIds.inventory_projection(kind,players):
  match players:
    case Nil{}: {==}
    case Con{head,rest}:
      %PlayerIds.inventory_key_of(kind,head) : {Con{PlayerIds.inventory_key(kind,Inv.Inventory.frame(head)),PlayerIds.inventory_keys(kind,Inv.Inventory.frames(rest))} == Con{_,PlayerIds.project(kind,rest)} : A.Allocation.Ids}
      %PlayerIds.inventory_projection(kind,rest) : {Con{PlayerIds.inventory_key(kind,Inv.Inventory.frame(head)),PlayerIds.inventory_keys(kind,Inv.Inventory.frames(rest))} == Con{PlayerIds.inventory_key(kind,Inv.Inventory.frame(head)),_} : A.Allocation.Ids}
      {==}

law PlayerIds.inventory_unique:
  for +kind: PlayerIds.Kind
  for +before: List<&2,P.Players.State>
  for +after: List<&2,P.Players.State>
  for +conserved: Inv.Inventory.Conserved<before,after>
  for +valid: A.Allocation.Unique(PlayerIds.project(kind,before))
  A.Allocation.Unique(PlayerIds.project(kind,after))

def PlayerIds.inventory_unique(kind,before,after,conserved,valid):
  match conserved:
    case Inv.Inventory.Conserved{ordered,permutation,frames}:
      %PlayerIds.inventory_projection(kind,after) : A.Allocation.Unique(_)
      %Equal.sym(List<&2,Inv.Inventory.Frame>,Inv.Inventory.frames(after),Inv.Inventory.frames(ordered),frames) : A.Allocation.Unique(PlayerIds.inventory_keys(kind,_))
      %Equal.sym(A.Allocation.Ids,PlayerIds.inventory_keys(kind,Inv.Inventory.frames(ordered)),PlayerIds.project(kind,ordered),PlayerIds.inventory_projection(kind,ordered)) : A.Allocation.Unique(_)
      PlayerIds.perm_unique(kind,ordered,before,permutation,valid)


def PlayerIds.interaction_key(kind: PlayerIds.Kind,frame: Inter.Interaction.Frame) -> U32:
  match kind:
    case PlayerIds.Player{}:
      match frame:
        case Inter.Interaction.Frame{pid,cid,hero,vitals,style,cull,side0,side1,side2,claimed,kills,found,name}: pid
    case PlayerIds.Connection{}:
      match frame:
        case Inter.Interaction.Frame{pid,cid,hero,vitals,style,cull,side0,side1,side2,claimed,kills,found,name}: cid

law PlayerIds.interaction_key_of:
  for +kind: PlayerIds.Kind
  for +player: P.Players.State
  {PlayerIds.interaction_key(kind,Inter.Interaction.frame(player)) == PlayerIds.key(kind,player) : U32}

def PlayerIds.interaction_key_of(kind,player):
  match kind:
    case PlayerIds.Player{}:
      match player:
        case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
          match quest:
            case P.Players.Quest{main,cull,side0,side1,side2,claimed}:
              match meta:
                case P.Players.Meta{score,kills,found,name}: {==}
    case PlayerIds.Connection{}:
      match player:
        case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
          match quest:
            case P.Players.Quest{main,cull,side0,side1,side2,claimed}:
              match meta:
                case P.Players.Meta{score,kills,found,name}: {==}

def PlayerIds.interaction_keys(+kind: PlayerIds.Kind,frames: List<&2,Inter.Interaction.Frame>) -> A.Allocation.Ids:
  match frames:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{PlayerIds.interaction_key(kind,head),PlayerIds.interaction_keys(kind,rest)}

law PlayerIds.interaction_projection:
  for +kind: PlayerIds.Kind
  for +players: List<&2,P.Players.State>
  {PlayerIds.interaction_keys(kind,Inter.Interaction.frames(players)) == PlayerIds.project(kind,players) : A.Allocation.Ids}

def PlayerIds.interaction_projection(kind,players):
  match players:
    case Nil{}: {==}
    case Con{head,rest}:
      %PlayerIds.interaction_key_of(kind,head) : {Con{PlayerIds.interaction_key(kind,Inter.Interaction.frame(head)),PlayerIds.interaction_keys(kind,Inter.Interaction.frames(rest))} == Con{_,PlayerIds.project(kind,rest)} : A.Allocation.Ids}
      %PlayerIds.interaction_projection(kind,rest) : {Con{PlayerIds.interaction_key(kind,Inter.Interaction.frame(head)),PlayerIds.interaction_keys(kind,Inter.Interaction.frames(rest))} == Con{PlayerIds.interaction_key(kind,Inter.Interaction.frame(head)),_} : A.Allocation.Ids}
      {==}

law PlayerIds.interaction_unique:
  for +kind: PlayerIds.Kind
  for +before: List<&2,P.Players.State>
  for +after: List<&2,P.Players.State>
  for +conserved: Inter.Interaction.Conserved<before,after>
  for +valid: A.Allocation.Unique(PlayerIds.project(kind,before))
  A.Allocation.Unique(PlayerIds.project(kind,after))

def PlayerIds.interaction_unique(kind,before,after,conserved,valid):
  match conserved:
    case Inter.Interaction.Conserved{ordered,permutation,frames}:
      %PlayerIds.interaction_projection(kind,after) : A.Allocation.Unique(_)
      %Equal.sym(List<&2,Inter.Interaction.Frame>,Inter.Interaction.frames(after),Inter.Interaction.frames(ordered),frames) : A.Allocation.Unique(PlayerIds.interaction_keys(kind,_))
      %Equal.sym(A.Allocation.Ids,PlayerIds.interaction_keys(kind,Inter.Interaction.frames(ordered)),PlayerIds.project(kind,ordered),PlayerIds.interaction_projection(kind,ordered)) : A.Allocation.Unique(_)
      PlayerIds.perm_unique(kind,ordered,before,permutation,valid)


def PlayerIds.combat_key(kind: PlayerIds.Kind,frame: C.Combat.Frame) -> U32:
  match kind:
    case PlayerIds.Player{}:
      match frame:
        case C.Combat.Frame{pid,cid,hero,pos,hp,xp,dead,respawn,style,quest,meta}: pid
    case PlayerIds.Connection{}:
      match frame:
        case C.Combat.Frame{pid,cid,hero,pos,hp,xp,dead,respawn,style,quest,meta}: cid

law PlayerIds.combat_key_of:
  for +kind: PlayerIds.Kind
  for +player: P.Players.State
  {PlayerIds.combat_key(kind,C.Combat.frame(player)) == PlayerIds.key(kind,player) : U32}

def PlayerIds.combat_key_of(kind,player):
  match kind:
    case PlayerIds.Player{}:
      match player:
        case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
          match vitals:
            case V.Vitals.State{hp,xp,dead,respawn,attack,spin}: {==}
    case PlayerIds.Connection{}:
      match player:
        case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
          match vitals:
            case V.Vitals.State{hp,xp,dead,respawn,attack,spin}: {==}

def PlayerIds.combat_keys(+kind: PlayerIds.Kind,frames: List<&2,C.Combat.Frame>) -> A.Allocation.Ids:
  match frames:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{PlayerIds.combat_key(kind,head),PlayerIds.combat_keys(kind,rest)}

law PlayerIds.combat_projection:
  for +kind: PlayerIds.Kind
  for +players: List<&2,P.Players.State>
  {PlayerIds.combat_keys(kind,C.Combat.frames(players)) == PlayerIds.project(kind,players) : A.Allocation.Ids}

def PlayerIds.combat_projection(kind,players):
  match players:
    case Nil{}: {==}
    case Con{head,rest}:
      %PlayerIds.combat_key_of(kind,head) : {Con{PlayerIds.combat_key(kind,C.Combat.frame(head)),PlayerIds.combat_keys(kind,C.Combat.frames(rest))} == Con{_,PlayerIds.project(kind,rest)} : A.Allocation.Ids}
      %PlayerIds.combat_projection(kind,rest) : {Con{PlayerIds.combat_key(kind,C.Combat.frame(head)),PlayerIds.combat_keys(kind,C.Combat.frames(rest))} == Con{PlayerIds.combat_key(kind,C.Combat.frame(head)),_} : A.Allocation.Ids}
      {==}

law PlayerIds.combat_unique:
  for +kind: PlayerIds.Kind
  for +before: List<&2,P.Players.State>
  for +after: List<&2,P.Players.State>
  for +conserved: C.Combat.Conserved<before,after>
  for +valid: A.Allocation.Unique(PlayerIds.project(kind,before))
  A.Allocation.Unique(PlayerIds.project(kind,after))

def PlayerIds.combat_unique(kind,before,after,conserved,valid):
  match conserved:
    case C.Combat.Conserved{ordered,permutation,frames}:
      %PlayerIds.combat_projection(kind,after) : A.Allocation.Unique(_)
      %Equal.sym(List<&2,C.Combat.Frame>,C.Combat.frames(after),C.Combat.frames(ordered),frames) : A.Allocation.Unique(PlayerIds.combat_keys(kind,_))
      %Equal.sym(A.Allocation.Ids,PlayerIds.combat_keys(kind,C.Combat.frames(ordered)),PlayerIds.project(kind,ordered),PlayerIds.combat_projection(kind,ordered)) : A.Allocation.Unique(_)
      PlayerIds.perm_unique(kind,ordered,before,permutation,valid)

def PlayerIds.payout_key(kind: PlayerIds.Kind,frame: Pay.Payout.Frame) -> U32:
  match kind:
    case PlayerIds.Player{}:
      match frame:
        case Pay.Payout.Frame{pid,cid,pos,hp,dead,respawn,attack,spin,style,name}: pid
    case PlayerIds.Connection{}:
      match frame:
        case Pay.Payout.Frame{pid,cid,pos,hp,dead,respawn,attack,spin,style,name}: cid

law PlayerIds.payout_key_of:
  for +kind: PlayerIds.Kind
  for +player: P.Players.State
  {PlayerIds.payout_key(kind,Pay.Payout.frame(player)) == PlayerIds.key(kind,player) : U32}

def PlayerIds.payout_key_of(kind,player):
  match kind:
    case PlayerIds.Player{}:
      match player:
        case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
          match vitals:
            case V.Vitals.State{hp,xp,dead,respawn,attack,spin}:
              match meta:
                case P.Players.Meta{score,kills,found,name}: {==}
    case PlayerIds.Connection{}:
      match player:
        case P.Players.State{pid,cid,hero,pos,vitals,style,quest,meta}:
          match vitals:
            case V.Vitals.State{hp,xp,dead,respawn,attack,spin}:
              match meta:
                case P.Players.Meta{score,kills,found,name}: {==}

def PlayerIds.payout_keys(+kind: PlayerIds.Kind,frames: List<&2,Pay.Payout.Frame>) -> A.Allocation.Ids:
  match frames:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{PlayerIds.payout_key(kind,head),PlayerIds.payout_keys(kind,rest)}

law PlayerIds.payout_projection:
  for +kind: PlayerIds.Kind
  for +players: List<&2,P.Players.State>
  {PlayerIds.payout_keys(kind,Pay.Payout.frames(players)) == PlayerIds.project(kind,players) : A.Allocation.Ids}

def PlayerIds.payout_projection(kind,players):
  match players:
    case Nil{}: {==}
    case Con{head,rest}:
      %PlayerIds.payout_key_of(kind,head) : {Con{PlayerIds.payout_key(kind,Pay.Payout.frame(head)),PlayerIds.payout_keys(kind,Pay.Payout.frames(rest))} == Con{_,PlayerIds.project(kind,rest)} : A.Allocation.Ids}
      %PlayerIds.payout_projection(kind,rest) : {Con{PlayerIds.payout_key(kind,Pay.Payout.frame(head)),PlayerIds.payout_keys(kind,Pay.Payout.frames(rest))} == Con{PlayerIds.payout_key(kind,Pay.Payout.frame(head)),_} : A.Allocation.Ids}
      {==}

law PlayerIds.payout_unique:
  for +kind: PlayerIds.Kind
  for +before: List<&2,P.Players.State>
  for +after: List<&2,P.Players.State>
  for +conserved: Pay.Payout.Conserved<before,after>
  for +valid: A.Allocation.Unique(PlayerIds.project(kind,before))
  A.Allocation.Unique(PlayerIds.project(kind,after))

def PlayerIds.payout_unique(kind,before,after,conserved,valid):
  match conserved:
    case Pay.Payout.Conserved{ordered,permutation,frames}:
      %PlayerIds.payout_projection(kind,after) : A.Allocation.Unique(_)
      %Equal.sym(List<&2,Pay.Payout.Frame>,Pay.Payout.frames(after),Pay.Payout.frames(ordered),frames) : A.Allocation.Unique(PlayerIds.payout_keys(kind,_))
      %Equal.sym(A.Allocation.Ids,PlayerIds.payout_keys(kind,Pay.Payout.frames(ordered)),PlayerIds.project(kind,ordered),PlayerIds.payout_projection(kind,ordered)) : A.Allocation.Unique(_)
      PlayerIds.perm_unique(kind,ordered,before,permutation,valid)


law PlayerIds.inventory_both:
  for +before: List<&2,P.Players.State>
  for +after: List<&2,P.Players.State>
  for +conserved: Inv.Inventory.Conserved<before,after>
  for +valid: J.Admission.Unique<before>
  J.Admission.Unique<after>

def PlayerIds.inventory_both(before,after,conserved,valid):
  PlayerIds.to_admission(after,PlayerIds.inventory_unique(PlayerIds.Player{},before,after,conserved,PlayerIds.from_admission(PlayerIds.Player{},before,valid)),PlayerIds.inventory_unique(PlayerIds.Connection{},before,after,conserved,PlayerIds.from_admission(PlayerIds.Connection{},before,valid)))

law PlayerIds.inventory_run:
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +op: G.Bq.HOp
  for +near_shop: Bool
  for +amount: U32
  for +valid: J.Admission.Unique<players>
  J.Admission.Unique<Inv.Inventory.roster(Inv.Inventory.run(players,target,op,near_shop,amount))>

def PlayerIds.inventory_run(players,target,op,near_shop,amount,valid):
  PlayerIds.inventory_both(players,Inv.Inventory.roster(Inv.Inventory.run(players,target,op,near_shop,amount)),Inv.Inventory.run_conserves(players,target,op,near_shop,amount),valid)


law PlayerIds.interaction_both:
  for +before: List<&2,P.Players.State>
  for +after: List<&2,P.Players.State>
  for +conserved: Inter.Interaction.Conserved<before,after>
  for +valid: J.Admission.Unique<before>
  J.Admission.Unique<after>

def PlayerIds.interaction_both(before,after,conserved,valid):
  PlayerIds.to_admission(after,PlayerIds.interaction_unique(PlayerIds.Player{},before,after,conserved,PlayerIds.from_admission(PlayerIds.Player{},before,valid)),PlayerIds.interaction_unique(PlayerIds.Connection{},before,after,conserved,PlayerIds.from_admission(PlayerIds.Connection{},before,valid)))

law PlayerIds.interaction_run:
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +command: Inter.Interaction.Command
  for +valid: J.Admission.Unique<players>
  J.Admission.Unique<Inter.Interaction.roster(Inter.Interaction.run(players,target,command))>

def PlayerIds.interaction_run(players,target,command,valid):
  PlayerIds.interaction_both(players,Inter.Interaction.roster(Inter.Interaction.run(players,target,command)),Inter.Interaction.run_conserves(players,target,command),valid)


law PlayerIds.combat_both:
  for +before: List<&2,P.Players.State>
  for +after: List<&2,P.Players.State>
  for +conserved: C.Combat.Conserved<before,after>
  for +valid: J.Admission.Unique<before>
  J.Admission.Unique<after>

def PlayerIds.combat_both(before,after,conserved,valid):
  PlayerIds.to_admission(after,PlayerIds.combat_unique(PlayerIds.Player{},before,after,conserved,PlayerIds.from_admission(PlayerIds.Player{},before,valid)),PlayerIds.combat_unique(PlayerIds.Connection{},before,after,conserved,PlayerIds.from_admission(PlayerIds.Connection{},before,valid)))

law PlayerIds.combat_run:
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +kind: C.Combat.Kind
  for +phase: U32
  for +valid: J.Admission.Unique<players>
  J.Admission.Unique<C.Combat.roster(C.Combat.run(players,target,kind,phase))>

def PlayerIds.combat_run(players,target,kind,phase,valid):
  PlayerIds.combat_both(players,C.Combat.roster(C.Combat.run(players,target,kind,phase)),C.Combat.run_conserves(players,target,kind,phase),valid)


law PlayerIds.payout_both:
  for +before: List<&2,P.Players.State>
  for +after: List<&2,P.Players.State>
  for +conserved: Pay.Payout.Conserved<before,after>
  for +valid: J.Admission.Unique<before>
  J.Admission.Unique<after>

def PlayerIds.payout_both(before,after,conserved,valid):
  PlayerIds.to_admission(after,PlayerIds.payout_unique(PlayerIds.Player{},before,after,conserved,PlayerIds.from_admission(PlayerIds.Player{},before,valid)),PlayerIds.payout_unique(PlayerIds.Connection{},before,after,conserved,PlayerIds.from_admission(PlayerIds.Connection{},before,valid)))

law PlayerIds.payout_run:
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +plan: Pay.Payout.Plan
  for +score: U32
  for +valid: J.Admission.Unique<players>
  J.Admission.Unique<Pay.Payout.roster(Pay.Payout.run(players,target,plan,score))>

def PlayerIds.payout_run(players,target,plan,score,valid):
  PlayerIds.payout_both(players,Pay.Payout.roster(Pay.Payout.run(players,target,plan,score)),Pay.Payout.run_conserves(players,target,plan,score),valid)


law PlayerIds.finish_hit_key:
  for +kind: PlayerIds.Kind
  for +player: P.Players.State
  for +hit: V.Vitals.Hit
  {PlayerIds.key(kind,P.Players.player(P.Players.finish_hit(player,hit))) == PlayerIds.key(kind,player) : U32}

def PlayerIds.finish_hit_key(kind,player,hit):
  match kind:
    case PlayerIds.Player{}:
      match player:
        case P.Players.State{pid,cid,hero,pos,old,style,quest,meta}:
          match hit:
            case V.Vitals.Hit{vitals,fell}:
              match fell:
                case False{}: {==}
                case True{}: {==}
    case PlayerIds.Connection{}:
      match player:
        case P.Players.State{pid,cid,hero,pos,old,style,quest,meta}:
          match hit:
            case V.Vitals.Hit{vitals,fell}:
              match fell:
                case False{}: {==}
                case True{}: {==}


law PlayerIds.finish_upkeep_key:
  for +kind: PlayerIds.Kind
  for +player: P.Players.State
  for +plan: P.Players.Plan
  for +result: V.Vitals.Upkeep
  for +spawn_x: U32
  for +spawn_y: U32
  {PlayerIds.key(kind,P.Players.player(P.Players.finish_upkeep(player,plan,result,spawn_x,spawn_y))) == PlayerIds.key(kind,player) : U32}

def PlayerIds.finish_upkeep_key(kind,player,plan,result,spawn_x,spawn_y):
  match kind:
    case PlayerIds.Player{}:
      match player:
        case P.Players.State{pid,cid,hero,pos,old,style,quest,meta}:
          match result:
            case V.Vitals.Upkeep{vitals,revived,walk}:
              match revived:
                case False{}: {==}
                case True{}: {==}
    case PlayerIds.Connection{}:
      match player:
        case P.Players.State{pid,cid,hero,pos,old,style,quest,meta}:
          match result:
            case V.Vitals.Upkeep{vitals,revived,walk}:
              match revived:
                case False{}: {==}
                case True{}: {==}


law PlayerIds.hurt_key:
  for +kind: PlayerIds.Kind
  for +player: P.Players.State
  for +attack: U32
  for +timer: U32
  {PlayerIds.key(kind,P.Players.player(P.Players.hurt(player,attack,timer))) == PlayerIds.key(kind,player) : U32}

def PlayerIds.hurt_key(kind,player,attack,timer): PlayerIds.finish_hit_key(kind,player,V.Vitals.hit(P.Players.vitals(player),P.Players.mob_hit(attack,P.Players.hero(player)),timer))

law PlayerIds.upkeep_key:
  for +kind: PlayerIds.Kind
  for +player: P.Players.State
  for +plan: P.Players.Plan
  for +tick: U32
  for +spawn_x: U32
  for +spawn_y: U32
  {PlayerIds.key(kind,P.Players.player(P.Players.upkeep(player,plan,tick,spawn_x,spawn_y))) == PlayerIds.key(kind,player) : U32}

def PlayerIds.upkeep_key(kind,player,plan,tick,spawn_x,spawn_y): PlayerIds.finish_upkeep_key(kind,player,plan,V.Vitals.upkeep_hero(P.Players.vitals(player),P.Players.regen(tick,V.Vitals.hp(P.Players.vitals(player)),P.Players.maximum(player)),P.Players.hero(player),4294967295),spawn_x,spawn_y)

law PlayerIds.prepend_projection:
  for +kind: PlayerIds.Kind
  for +step: P.Players.Step
  for +result: P.Players.Result
  {PlayerIds.project(kind,P.Players.roster(P.Players.prepend_step(step,result))) == Con{PlayerIds.key(kind,P.Players.player(step)),PlayerIds.project(kind,P.Players.roster(result))} : A.Allocation.Ids}

def PlayerIds.prepend_projection(kind,step,result):
  match step:
    case P.Players.Step{player,event}:
      match result:
        case P.Players.Result{players,events}: {==}

law PlayerIds.hit_taken_projection:
  for +kind: PlayerIds.Kind
  for +taken: P.Players.Take
  for +attack: U32
  for +timer: U32
  {PlayerIds.project(kind,P.Players.roster(P.Players.hit_taken(taken,attack,timer))) == PlayerIds.project(kind,P.Players.restore(taken)) : A.Allocation.Ids}

def PlayerIds.hit_taken_projection(kind,taken,attack,timer):
  match taken:
    case P.Players.Take{others,found}:
      match found:
        case None{}: {==}
        case Some{player}:
          %Equal.sym(A.Allocation.Ids,PlayerIds.project(kind,P.Players.roster(P.Players.prepend_step(P.Players.hurt(player,attack,timer),P.Players.Result{others,Nil{}}))),Con{PlayerIds.key(kind,P.Players.player(P.Players.hurt(player,attack,timer))),PlayerIds.project(kind,others)},PlayerIds.prepend_projection(kind,P.Players.hurt(player,attack,timer),P.Players.Result{others,Nil{}})) : {_ == PlayerIds.project(kind,Con{player,others}) : A.Allocation.Ids}
          %PlayerIds.hurt_key(kind,player,attack,timer) : {Con{PlayerIds.key(kind,P.Players.player(P.Players.hurt(player,attack,timer))),PlayerIds.project(kind,others)} == Con{_,PlayerIds.project(kind,others)} : A.Allocation.Ids}
          {==}

law PlayerIds.strike_unique:
  for +kind: PlayerIds.Kind
  for +players: List<&2,P.Players.State>
  for +target: U32
  for +attack: U32
  for +timer: U32
  for +valid: A.Allocation.Unique(PlayerIds.project(kind,players))
  A.Allocation.Unique(PlayerIds.project(kind,P.Players.roster(P.Players.strike(players,target,attack,timer))))

def PlayerIds.strike_unique(kind,players,target,attack,timer,valid):
  %Equal.sym(A.Allocation.Ids,PlayerIds.project(kind,P.Players.roster(P.Players.strike(players,target,attack,timer))),PlayerIds.project(kind,P.Players.restore(P.Players.take(players,target))),PlayerIds.hit_taken_projection(kind,P.Players.take(players,target),attack,timer)) : A.Allocation.Unique(_)
  PlayerIds.take_unique(kind,players,target,valid)

law PlayerIds.apply_hits_unique:
  for +hits: List<&2,P.Players.Attack>
  for +kind: PlayerIds.Kind
  for +players: List<&2,P.Players.State>
  for +timer: U32
  for +valid: A.Allocation.Unique(PlayerIds.project(kind,players))
  A.Allocation.Unique(PlayerIds.project(kind,P.Players.roster(P.Players.apply_hits(hits,players,timer))))

def PlayerIds.apply_hits_unique(hits,kind,players,timer,valid):
  match hits:
    case Nil{}: valid
    case Con{head,rest}:
      match head:
        case P.Players.Attack{target,attack}:
          +first = P.Players.strike(players,target,attack,timer)
          +later = P.Players.apply_hits(rest,P.Players.roster(first),timer)
          %Equal.sym(List<&2,P.Players.State>,P.Players.roster(P.Players.before(first,later)),P.Players.roster(later),P.Players.before_roster(first,later)) : A.Allocation.Unique(PlayerIds.project(kind,_))
          PlayerIds.apply_hits_unique(rest,kind,P.Players.roster(first),timer,PlayerIds.strike_unique(kind,players,target,attack,timer,valid))

law PlayerIds.prepend_same_projection:
  for +kind: PlayerIds.Kind
  for +step: P.Players.Step
  for +result: P.Players.Result
  for +head: P.Players.State
  for +rest: List<&2,P.Players.State>
  for +same: {PlayerIds.key(kind,P.Players.player(step)) == PlayerIds.key(kind,head) : U32}
  for +tail: {PlayerIds.project(kind,P.Players.roster(result)) == PlayerIds.project(kind,rest) : A.Allocation.Ids}
  {PlayerIds.project(kind,P.Players.roster(P.Players.prepend_step(step,result))) == PlayerIds.project(kind,Con{head,rest}) : A.Allocation.Ids}

def PlayerIds.prepend_same_projection(kind,step,result,head,rest,same,tail):
  %same : {PlayerIds.project(kind,P.Players.roster(P.Players.prepend_step(step,result))) == Con{_,PlayerIds.project(kind,rest)} : A.Allocation.Ids}
  %tail : {PlayerIds.project(kind,P.Players.roster(P.Players.prepend_step(step,result))) == Con{PlayerIds.key(kind,P.Players.player(step)),_} : A.Allocation.Ids}
  PlayerIds.prepend_projection(kind,step,result)

law PlayerIds.upkeep_projection:
  for +players: List<&2,P.Players.State>
  for +plans: List<&2,P.Players.Plan>
  for +kind: PlayerIds.Kind
  for +tick: U32
  for +spawn_x: U32
  for +spawn_y: U32
  {PlayerIds.project(kind,P.Players.roster(P.Players.upkeep_all(players,plans,tick,spawn_x,spawn_y))) == PlayerIds.project(kind,players) : A.Allocation.Ids}

def PlayerIds.upkeep_projection(players,plans,kind,tick,spawn_x,spawn_y):
  match players:
    case Nil{}: {==}
    case Con{head,rest}:
      match plans:
        case Nil{}: PlayerIds.prepend_same_projection(kind,P.Players.upkeep(head,P.Players.stay(head),tick,spawn_x,spawn_y),P.Players.upkeep_all(rest,Nil{},tick,spawn_x,spawn_y),head,rest,PlayerIds.upkeep_key(kind,head,P.Players.stay(head),tick,spawn_x,spawn_y),PlayerIds.upkeep_projection(rest,Nil{},kind,tick,spawn_x,spawn_y))
        case Con{plan,later}: PlayerIds.prepend_same_projection(kind,P.Players.upkeep(head,plan,tick,spawn_x,spawn_y),P.Players.upkeep_all(rest,later,tick,spawn_x,spawn_y),head,rest,PlayerIds.upkeep_key(kind,head,plan,tick,spawn_x,spawn_y),PlayerIds.upkeep_projection(rest,later,kind,tick,spawn_x,spawn_y))

law PlayerIds.begin_gate_projection:
  for +kind: PlayerIds.Kind
  for +running: Bool
  for +state: S.Simulation.State
  for +plans: List<&2,P.Players.Plan>
  for +rules: S.Simulation.Rules
  {PlayerIds.project(kind,P.Players.roster(S.Simulation.prepared_upkeep(S.Simulation.begin_gate(running,state,plans,rules)))) == PlayerIds.project(kind,S.Simulation.players(state)) : A.Allocation.Ids}

def PlayerIds.begin_gate_projection(kind,running,state,plans,rules):
  match running:
    case False{}:
      match state:
        case S.Simulation.State{meta,players,monsters}: {==}
    case True{}:
      match state:
        case S.Simulation.State{meta,players,monsters}:
          match rules:
            case S.Simulation.Rules{spawn_x,spawn_y,timer}: PlayerIds.upkeep_projection(players,plans,kind,S.Simulation.clock(meta),spawn_x,spawn_y)

law PlayerIds.begin_projection:
  for +kind: PlayerIds.Kind
  for +state: S.Simulation.State
  for +plans: List<&2,P.Players.Plan>
  for +rules: S.Simulation.Rules
  {PlayerIds.project(kind,P.Players.roster(S.Simulation.prepared_upkeep(S.Simulation.begin(state,plans,rules)))) == PlayerIds.project(kind,S.Simulation.players(state)) : A.Allocation.Ids}

def PlayerIds.begin_projection(kind,state,plans,rules): PlayerIds.begin_gate_projection(kind,U32.is_eq(S.Simulation.phase(S.Simulation.meta(state)),1),state,plans,rules)

law PlayerIds.finish_unique:
  for +kind: PlayerIds.Kind
  for +prepared: S.Simulation.Prepared
  for +p0: List<&2,AI.AI.Plan>
  for +p1: List<&2,AI.AI.Plan>
  for +p2: List<&2,AI.AI.Plan>
  for +p3: List<&2,AI.AI.Plan>
  for +rules: S.Simulation.Rules
  for +valid: A.Allocation.Unique(PlayerIds.project(kind,P.Players.roster(S.Simulation.prepared_upkeep(prepared))))
  A.Allocation.Unique(PlayerIds.project(kind,S.Simulation.players(S.Simulation.state(S.Simulation.finish(prepared,p0,p1,p2,p3,rules)))))

def PlayerIds.finish_unique(kind,prepared,p0,p1,p2,p3,rules,valid):
  match prepared:
    case S.Simulation.Prepared{meta,monsters,upkeep,running}:
      match running:
        case False{}: valid
        case True{}:
          match rules:
            case S.Simulation.Rules{spawn_x,spawn_y,timer}: PlayerIds.apply_hits_unique(S.Simulation.attacks(S.Simulation.ai_hits(AI.AI.run_zones(monsters,p0,p1,p2,p3))),kind,P.Players.roster(upkeep),timer,valid)

law PlayerIds.tick_unique:
  for +kind: PlayerIds.Kind
  for +state: S.Simulation.State
  for +plan: S.Simulation.Plan
  for +rules: S.Simulation.Rules
  for +valid: A.Allocation.Unique(PlayerIds.project(kind,S.Simulation.players(state)))
  A.Allocation.Unique(PlayerIds.project(kind,S.Simulation.players(S.Simulation.state(S.Simulation.tick(state,plan,rules)))))

def PlayerIds.tick_unique(kind,state,plan,rules,valid):
  match plan:
    case S.Simulation.Plan{players,p0,p1,p2,p3}:
      PlayerIds.finish_unique(kind,S.Simulation.begin(state,players,rules),p0,p1,p2,p3,rules,(%Equal.sym(A.Allocation.Ids,PlayerIds.project(kind,P.Players.roster(S.Simulation.prepared_upkeep(S.Simulation.begin(state,players,rules)))),PlayerIds.project(kind,S.Simulation.players(state)),PlayerIds.begin_projection(kind,state,players,rules)) : A.Allocation.Unique(_); valid))

law PlayerIds.tick_both:
  for +state: S.Simulation.State
  for +plan: S.Simulation.Plan
  for +rules: S.Simulation.Rules
  for +valid: J.Admission.Unique<S.Simulation.players(state)>
  J.Admission.Unique<S.Simulation.players(S.Simulation.state(S.Simulation.tick(state,plan,rules)))>

def PlayerIds.tick_both(state,plan,rules,valid):
  PlayerIds.to_admission(S.Simulation.players(S.Simulation.state(S.Simulation.tick(state,plan,rules))),PlayerIds.tick_unique(PlayerIds.Player{},state,plan,rules,PlayerIds.from_admission(PlayerIds.Player{},S.Simulation.players(state),valid)),PlayerIds.tick_unique(PlayerIds.Connection{},state,plan,rules,PlayerIds.from_admission(PlayerIds.Connection{},S.Simulation.players(state),valid)))

law PlayerIds.actions_unique:
  for +kind: PlayerIds.Kind
  for +prepared: S.Simulation.Prepared
  for +actions: Walk.Locomotion.Actions
  for +rules: S.Simulation.Rules
  for +valid: A.Allocation.Unique(PlayerIds.project(kind,P.Players.roster(S.Simulation.prepared_upkeep(prepared))))
  A.Allocation.Unique(PlayerIds.project(kind,S.Simulation.players(S.Simulation.state(Walk.Locomotion.finish(prepared,actions,rules)))))

def PlayerIds.actions_unique(kind,prepared,actions,rules,valid):
  match actions:
    case Walk.Locomotion.Actions{p0,p1,p2,p3}: PlayerIds.finish_unique(kind,prepared,p0,p1,p2,p3,rules,valid)

law PlayerIds.planning_finish_unique:
  for +kind: PlayerIds.Kind
  for +prepared: S.Simulation.Prepared
  for +maps: T.Terrain.Maps
  for +c0: List<&2,Plan.Planning.Context>
  for +c1: List<&2,Plan.Planning.Context>
  for +c2: List<&2,Plan.Planning.Context>
  for +c3: List<&2,Plan.Planning.Context>
  for +rules: S.Simulation.Rules
  for +valid: A.Allocation.Unique(PlayerIds.project(kind,P.Players.roster(S.Simulation.prepared_upkeep(prepared))))
  A.Allocation.Unique(PlayerIds.project(kind,S.Simulation.players(S.Simulation.state(Plan.Planning.finish(prepared,maps,c0,c1,c2,c3,rules)))))

def PlayerIds.planning_finish_unique(kind,prepared,maps,c0,c1,c2,c3,rules,valid):
  +actions = Plan.Planning.actions(S.Simulation.prepared_monsters(prepared),c0,c1,c2,c3,maps,S.Simulation.clock(S.Simulation.prepared_meta(prepared)))
  %Equal.sym(S.Simulation.Result,Plan.Planning.finish(prepared,maps,c0,c1,c2,c3,rules),Walk.Locomotion.finish(prepared,actions,rules),Plan.Planning.finish_refines(prepared,maps,c0,c1,c2,c3,rules)) : A.Allocation.Unique(PlayerIds.project(kind,S.Simulation.players(S.Simulation.state(_))))
  PlayerIds.actions_unique(kind,prepared,actions,rules,valid)

law PlayerIds.planning_tick_unique:
  for +kind: PlayerIds.Kind
  for +state: S.Simulation.State
  for +input: Plan.Planning.Input
  for +maps: T.Terrain.Maps
  for +rules: S.Simulation.Rules
  for +valid: A.Allocation.Unique(PlayerIds.project(kind,S.Simulation.players(state)))
  A.Allocation.Unique(PlayerIds.project(kind,S.Simulation.players(S.Simulation.state(Plan.Planning.tick(state,input,maps,rules)))))

def PlayerIds.planning_tick_unique(kind,state,input,maps,rules,valid):
  match input:
    case Plan.Planning.Input{c0,c1,c2,c3}:
      +running = U32.is_eq(S.Simulation.phase(S.Simulation.meta(state)),1)
      +plans = Walk.Locomotion.tick_plans(running,S.Simulation.players(state),maps)
      +prepared = Walk.Locomotion.begin(state,maps,rules)
      PlayerIds.planning_finish_unique(kind,prepared,maps,c0,c1,c2,c3,rules,(%Equal.sym(A.Allocation.Ids,PlayerIds.project(kind,P.Players.roster(S.Simulation.prepared_upkeep(prepared))),PlayerIds.project(kind,S.Simulation.players(state)),PlayerIds.begin_gate_projection(kind,running,state,plans,rules)) : A.Allocation.Unique(_); valid))

law PlayerIds.planning_tick_both:
  for +state: S.Simulation.State
  for +input: Plan.Planning.Input
  for +maps: T.Terrain.Maps
  for +rules: S.Simulation.Rules
  for +valid: J.Admission.Unique<S.Simulation.players(state)>
  J.Admission.Unique<S.Simulation.players(S.Simulation.state(Plan.Planning.tick(state,input,maps,rules)))>

def PlayerIds.planning_tick_both(state,input,maps,rules,valid):
  PlayerIds.to_admission(S.Simulation.players(S.Simulation.state(Plan.Planning.tick(state,input,maps,rules))),PlayerIds.planning_tick_unique(PlayerIds.Player{},state,input,maps,rules,PlayerIds.from_admission(PlayerIds.Player{},S.Simulation.players(state),valid)),PlayerIds.planning_tick_unique(PlayerIds.Connection{},state,input,maps,rules,PlayerIds.from_admission(PlayerIds.Connection{},S.Simulation.players(state),valid)))

law PlayerIds.reward_unique:
  for +state: S.Simulation.State
  for +pid: U32
  for +kill: R.Roster.Kill
  for +plan: Pay.Payout.Plan
  for +score: U32
  for +valid: J.Admission.Unique<S.Simulation.players(state)>
  J.Admission.Unique<S.Simulation.players(B.Battle.state(B.Battle.reward(state,pid,kill,plan,score)))>

def PlayerIds.reward_unique(state,pid,kill,plan,score,valid):
  match state:
    case S.Simulation.State{meta,players,monsters}:
      +bound = B.Battle.bind_kind(plan,B.Battle.kind(kill))
      +paid = Pay.Payout.run(players,pid,bound,score)
      %Equal.sym(List<&2,P.Players.State>,S.Simulation.players(B.Battle.state(B.Battle.finish_reward(meta,monsters,kill,paid))),Pay.Payout.roster(paid),B.Battle.finish_reward_players(meta,monsters,kill,paid)) : J.Admission.Unique<_>
      PlayerIds.payout_run(players,pid,bound,score,valid)

law PlayerIds.after_unique:
  for +kill: Maybe<&2,R.Roster.Kill>
  for +state: S.Simulation.State
  for +pid: U32
  for +plan: Pay.Payout.Plan
  for +score: U32
  for +valid: J.Admission.Unique<S.Simulation.players(state)>
  J.Admission.Unique<S.Simulation.players(B.Battle.state(B.Battle.after(kill,state,pid,plan,score)))>

def PlayerIds.after_unique(kill,state,pid,plan,score,valid):
  match kill:
    case None{}: valid
    case Some{info}: PlayerIds.reward_unique(state,pid,info,plan,score,valid)

law PlayerIds.finish_hit_unique:
  for +meta: S.Simulation.Meta
  for +players: List<&2,P.Players.State>
  for +hit: R.Roster.Strike
  for +pid: U32
  for +plan: Pay.Payout.Plan
  for +score: U32
  for +valid: J.Admission.Unique<players>
  J.Admission.Unique<S.Simulation.players(B.Battle.state(B.Battle.finish_hit(meta,players,hit,pid,plan,score)))>

def PlayerIds.finish_hit_unique(meta,players,hit,pid,plan,score,valid):
  match hit:
    case R.Roster.Strike{monsters,kill,dealt}: PlayerIds.after_unique(kill,S.Simulation.State{meta,players,monsters},pid,plan,score,valid)

law PlayerIds.battle_strike_unique:
  for +input: B.Battle.Input
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  for +valid: J.Admission.Unique<S.Simulation.players(state)>
  J.Admission.Unique<S.Simulation.players(B.Battle.state(B.Battle.strike(input,state,pid,score)))>

def PlayerIds.battle_strike_unique(input,state,pid,score,valid):
  match input:
    case B.Battle.Input{mid,damage,plan}:
      match state:
        case S.Simulation.State{meta,players,monsters}: PlayerIds.finish_hit_unique(meta,players,R.Roster.strike(monsters,mid,damage),pid,plan,score,valid)

law PlayerIds.battle_run_unique:
  for +inputs: List<&2,B.Battle.Input>
  for +state: S.Simulation.State
  for +pid: U32
  for +score: U32
  for +valid: J.Admission.Unique<S.Simulation.players(state)>
  J.Admission.Unique<S.Simulation.players(B.Battle.state(B.Battle.run(inputs,state,pid,score)))>

def PlayerIds.battle_run_unique(inputs,state,pid,score,valid):
  match inputs:
    case Nil{}: valid
    case Con{head,rest}: PlayerIds.battle_run_unique(rest,B.Battle.state(B.Battle.strike(head,state,pid,score)),pid,score,PlayerIds.battle_strike_unique(head,state,pid,score,valid))

law PlayerIds.execute_unique:
  for +meta: S.Simulation.Meta
  for +monsters: List<&2,M.Monsters.State>
  for +admitted: C.Combat.Result
  for +inputs: List<&2,B.Battle.Input>
  for +pid: U32
  for +score: U32
  for +valid: J.Admission.Unique<C.Combat.roster(admitted)>
  J.Admission.Unique<S.Simulation.players(B.Battle.state(B.Battle.execute(meta,monsters,admitted,inputs,pid,score)))>

def PlayerIds.execute_unique(meta,monsters,admitted,inputs,pid,score,valid):
  match admitted:
    case C.Combat.Result{players,attacker}:
      match attacker:
        case None{}: valid
        case Some{actor}: PlayerIds.battle_run_unique(inputs,S.Simulation.State{meta,players,monsters},pid,score,valid)

law PlayerIds.command_unique:
  for +kind: C.Combat.Kind
  for +state: S.Simulation.State
  for +inputs: List<&2,B.Battle.Input>
  for +pid: U32
  for +score: U32
  for +valid: J.Admission.Unique<S.Simulation.players(state)>
  J.Admission.Unique<S.Simulation.players(B.Battle.state(B.Battle.command(kind,state,inputs,pid,score)))>

def PlayerIds.command_unique(kind,state,inputs,pid,score,valid):
  match state:
    case S.Simulation.State{meta,players,monsters}:
      PlayerIds.execute_unique(meta,monsters,C.Combat.run(players,pid,kind,S.Simulation.phase(meta)),inputs,pid,score,PlayerIds.combat_run(players,pid,kind,S.Simulation.phase(meta),valid))

law PlayerIds.transition_unique:
  for +transition: B.Battle.Transition
  for +state: S.Simulation.State
  for +valid: J.Admission.Unique<S.Simulation.players(state)>
  J.Admission.Unique<S.Simulation.players(B.Battle.transition(transition,state))>

def PlayerIds.transition_unique(transition,state,valid):
  match transition:
    case B.Battle.Fighting{kind,inputs,pid,score}: PlayerIds.command_unique(kind,state,inputs,pid,score,valid)
    case B.Battle.Ticking{plan,rules}: PlayerIds.tick_both(state,plan,rules,valid)

law PlayerIds.battle_trace_unique:
  for +transitions: List<&2,B.Battle.Transition>
  for +state: S.Simulation.State
  for +valid: J.Admission.Unique<S.Simulation.players(state)>
  J.Admission.Unique<S.Simulation.players(B.Battle.trace(transitions,state))>

def PlayerIds.battle_trace_unique(transitions,state,valid):
  match transitions:
    case Nil{}: valid
    case Con{head,rest}: PlayerIds.battle_trace_unique(rest,B.Battle.transition(head,state),PlayerIds.transition_unique(head,state,valid))

law PlayerIds.planning_trace_unique:
  for +inputs: List<&2,Plan.Planning.Input>
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +rules: S.Simulation.Rules
  for +valid: J.Admission.Unique<S.Simulation.players(state)>
  J.Admission.Unique<S.Simulation.players(Plan.Planning.trace(inputs,state,maps,rules))>

def PlayerIds.planning_trace_unique(inputs,state,maps,rules,valid):
  match inputs:
    case Nil{}: valid
    case Con{head,rest}: PlayerIds.planning_trace_unique(rest,S.Simulation.state(Plan.Planning.tick(state,head,maps,rules)),maps,rules,PlayerIds.planning_tick_both(state,head,maps,rules,valid))

# This sequence composes the same pure operations used by the server.
# Connection authentication and the full effectful dispatcher are separate.
type PlayerIds.Change is Data:
  PlayerIds.Create{cid: U32,style: P.Players.Style,name: List<&2,Char>}
  PlayerIds.Remove{target: U32}
  PlayerIds.Inventory{target: U32,op: G.Bq.HOp,near_shop: Bool,amount: U32}
  PlayerIds.Interact{target: U32,command: Inter.Interaction.Command}
  PlayerIds.Fight{kind: C.Combat.Kind,inputs: List<&2,B.Battle.Input>,pid: U32,score: U32}
  PlayerIds.Tick{input: Plan.Planning.Input,rules: S.Simulation.Rules}

def PlayerIds.run_change(change: PlayerIds.Change,state: S.Simulation.State,maps: T.Terrain.Maps) -> S.Simulation.State:
  match change:
    case PlayerIds.Create{cid,style,name}: J.Admission.state(J.Admission.add(state,cid,style,name))
    case PlayerIds.Remove{target}: Ref.References.remove_state(state,target)
    case PlayerIds.Inventory{target,op,near_shop,amount}:
      match state:
        case S.Simulation.State{meta,players,monsters}: S.Simulation.State{meta,Inv.Inventory.roster(Inv.Inventory.run(players,target,op,near_shop,amount)),monsters}
    case PlayerIds.Interact{target,command}:
      match state:
        case S.Simulation.State{meta,players,monsters}: S.Simulation.State{meta,Inter.Interaction.roster(Inter.Interaction.run(players,target,command)),monsters}
    case PlayerIds.Fight{kind,inputs,pid,score}: B.Battle.state(B.Battle.command(kind,state,inputs,pid,score))
    case PlayerIds.Tick{input,rules}: S.Simulation.state(Plan.Planning.tick(state,input,maps,rules))

law PlayerIds.remove_state_unique:
  for +state: S.Simulation.State
  for +pid: U32
  for +valid: J.Admission.Unique<S.Simulation.players(state)>
  J.Admission.Unique<S.Simulation.players(Ref.References.remove_state(state,pid))>

def PlayerIds.remove_state_unique(state,pid,valid):
  match state:
    case S.Simulation.State{meta,players,monsters}: PlayerIds.remove_both(players,pid,valid)

law PlayerIds.change_unique:
  for +change: PlayerIds.Change
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +valid: J.Admission.Unique<S.Simulation.players(state)>
  J.Admission.Unique<S.Simulation.players(PlayerIds.run_change(change,state,maps))>

def PlayerIds.change_unique(change,state,maps,valid):
  match change:
    case PlayerIds.Create{cid,style,name}: J.Admission.add_unique(state,cid,style,name,valid)
    case PlayerIds.Remove{target}: PlayerIds.remove_state_unique(state,target,valid)
    case PlayerIds.Inventory{target,op,near_shop,amount}:
      match state:
        case S.Simulation.State{meta,players,monsters}: PlayerIds.inventory_run(players,target,op,near_shop,amount,valid)
    case PlayerIds.Interact{target,command}:
      match state:
        case S.Simulation.State{meta,players,monsters}: PlayerIds.interaction_run(players,target,command,valid)
    case PlayerIds.Fight{kind,inputs,pid,score}: PlayerIds.command_unique(kind,state,inputs,pid,score,valid)
    case PlayerIds.Tick{input,rules}: PlayerIds.planning_tick_both(state,input,maps,rules,valid)

def PlayerIds.trace(changes: List<&2,PlayerIds.Change>,state: S.Simulation.State,+maps: T.Terrain.Maps) -> S.Simulation.State:
  match changes:
    case Nil{}: state
    case Con{head,rest}: PlayerIds.trace(rest,PlayerIds.run_change(head,state,maps),maps)

law PlayerIds.trace_unique:
  for +changes: List<&2,PlayerIds.Change>
  for +state: S.Simulation.State
  for +maps: T.Terrain.Maps
  for +valid: J.Admission.Unique<S.Simulation.players(state)>
  J.Admission.Unique<S.Simulation.players(PlayerIds.trace(changes,state,maps))>

def PlayerIds.trace_unique(changes,state,maps,valid):
  match changes:
    case Nil{}: valid
    case Con{head,rest}: PlayerIds.trace_unique(rest,PlayerIds.run_change(head,state,maps),maps,PlayerIds.change_unique(head,state,maps,valid))

law PlayerIds.fresh_trace_unique:
  for +changes: List<&2,PlayerIds.Change>
  for +world: U32
  for +seed: U32
  for +now: U32
  J.Admission.Unique<S.Simulation.players(PlayerIds.trace(changes,T.Terrain.simulation(Pop.Population.fresh(world,seed,now)),Land.Landscape.maps(seed)))>

def PlayerIds.fresh_trace_unique(changes,world,seed,now):
  PlayerIds.trace_unique(changes,T.Terrain.simulation(Pop.Population.fresh(world,seed,now)),Land.Landscape.maps(seed),J.Admission.Unique{Unit{},Unit{}})
