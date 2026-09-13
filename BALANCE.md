# BendQuest balance notes, from a full bot campaign

Written after driving the game to completion with teams of 5-8
protocol bots (level 1 through the Nulltide Maw seal, hall of fame,
world restart), including four failed assaults on the Maw before the
winning one. Numbers below are from those runs. Ranked by how much
each change would matter to a player; the last section is what NOT to
touch.

## 1. Give portals a landing pad

Mobs cluster at zone entrances (they chase crossers, then linger), so
arriving at (2,8) at the natural level is a coin-flip death: it
killed low-level walkers 8/8 times in transit tests and drove most
mid-game bot deaths. A small mob-exclusion stamp around both portal
tiles (same mechanism as in_village) removes the spike without
touching difficulty anywhere else. The zone-1 entrance at level 4-5
is the worst offender (bat/golem clusters vs ~56hp).

## 2. Share boss XP among players in the zone

Last-hit-takes-all produced a 3672 vs 1119 score spread and let one
hero snipe two wardens' XP (300/700/1300 are the biggest single
grants in the game). Since the Maw effectively requires the WHOLE
team leveled, killer-takes-all works against the game's cooperative
pitch. Keep the score/time-bonus for the killer; split the XP.

## 3. Stop the Maw's regen while it is enraged

The enrage (below 30%: attack 42 -> 84, regen still 30/tick ~= 250/s)
is a binary wall: a 6-hero level-8 wave reached 26% and then the
regen erased 90 seconds of progress during the wipe. Trading regen
for damage in the last 30% turns the finale into a burn-phase
decision -- still cooperative (nobody solos the first 70%), but a
near-miss team can finish through attrition instead of resetting to
6500 every wipe. For reference, the winning composition was six
level-10 heroes with cave picks and ~36 potions each; the fight took
~3 minutes with the first 12 seconds already netting -57 hp/s.

## 4. Elder catch-up for the main quest

sigil_advance only advances players AT the falling warden's stage, so
a late joiner whose stage-warden is already dead is stuck forever
("Claim Mossback's sigil" for a corpse). elder_line already reads the
world sigils: talking to Elder Fern could advance any stage whose
sigil is lit. Thematic, and localized to cmd_talk.

## 5. One item that is both a gold sink and travel QoL

Gold outruns spending by mid-game (bots idled on 500-1000g against a
~570g full-gear budget; potions are the only late sink), and the
walk-back after dying at the Maw is the real cost of a wipe. A
warp-to-village scroll (~25g), or respawn at a zone's entrance once
its sigil is claimed, tunes both dials with one mechanic.

## 6. Small fixes

- Allow walking during phase 2: spectators stand frozen through the
  5-minute hall-of-fame ceremony (upkeep_plr is skipped entirely, so
  movement dies with combat).
- Re-send OVER rows and FAMEB to clients that join during phase 2 --
  a late joiner currently sees "THE REALM IS SAVED!" over an empty
  scoreboard.
- Put the mob tgt field into SNAP so the client can draw a "targeted!"
  marker: the Maw retargets by proximity and the aggro handoff --
  the most important fact in the finale -- is invisible.

## What NOT to touch

- Zone-0 pacing: level 1-4 in 6-8 minutes with the fists -> wooden ->
  iron ladder and the cull quest is genuinely well-tuned.
- Cheap deaths (5s + walk): they are what make warden chip-tactics
  and sustained Maw pressure viable; the Maw's regen is the correct
  counterweight. Do not add gold/XP loss -- it would starve the
  potion economy the endgame depends on.
- Rare spawns: an avoided rare never dies, so one can camp a corridor
  for an hour of world time -- but that is emergent territory control
  with a designed counter (pack kill, x10 score, guaranteed rare
  gear). Killing it as a group is exactly the cooperation the game
  wants to teach; it just should not guard a portal mouth (item 1
  covers that case).
- The side-quest ladder: each side quest auto-tracks and pays out
  precisely the gear the next zone wants (potions -> miner helm ->
  ember ring). Lovely as-is.
- The "no lone hero" claim: empirically true at every scale tested
  (solo, duo, and an uncoordinated trickle all failed; only a
  simultaneous, provisioned wave won). It is the game's thesis and it
  holds.
