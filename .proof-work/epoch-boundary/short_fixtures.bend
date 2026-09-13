
def epoch_short_entries() -> List<&2,History.History.Entry>: [History.History.Entry{epoch_world,History.History.Tick{2},epoch_w1}]
def epoch_short_follow() -> E.Epoch.Follow<epoch_short_entries,epoch_world,epoch_corpse(2)>:
  E.Epoch.Wait{2,Nil{},{==},Z.Zones.Hollow{{==}},epoch_in0,{==},Some{AI.AI.Rest{}},{==},TL.TickLife.run(epoch_world,2,epoch_corpse(2),Z.Zones.Hollow{{==}},epoch_in0,{==},epoch_zones0,epoch_unique0),{==},{==},E.Epoch.Done{{==},epoch_in1,epoch_unique1,{==}}}

law epoch_short_no_birth:
  {E.Epoch.reborn(epoch_short_entries,epoch_world,epoch_corpse(2),epoch_short_follow) == False{} : Bool}
def epoch_short_no_birth(): {==}

law epoch_short_exhausted:
  {E.Epoch.remaining(epoch_short_entries,epoch_world,epoch_corpse(2),epoch_short_follow) == Nil{} : List<&2,History.History.Entry>}
def epoch_short_exhausted(): E.Epoch.exhausted(epoch_short_entries,epoch_world,epoch_corpse(2),epoch_short_follow,{==})

law epoch_short_zero:
  {Dead.Dead.count(7,PH.Permanent.notices(E.Epoch.prefix(epoch_short_entries,epoch_world,epoch_corpse(2),epoch_short_follow)(epoch_world,epoch_corpse(2)))) == 0n : Nat}
def epoch_short_zero(): E.Epoch.zero(epoch_corpse(2),epoch_short_entries,epoch_world,epoch_short_follow)
