#!/bin/sh
set -eu
cd "$(dirname "$0")"
./check-proofs.sh
actual=$(mktemp)
expected=$(mktemp)
trap 'rm -f "$actual" "$expected"' EXIT
for source in check.bend health_check.bend rewards_check.bend vitals_check.bend monsters_check.bend roster_check.bend ai_check.bend players_check.bend simulation_check.bend inventory_check.bend payouts_check.bend interactions_check.bend combat_check.bend battle_check.bend terrain_check.bend locomotion_check.bend landscape_check.bend pursuit_check.bend placement_check.bend allocation_check.bend references_check.bend targeting_check.bend ai_refs_check.bend sessions_check.bend selection_check.bend creation_check.bend disconnect_check.bend rebuild_check.bend rebinding_check.bend restart_check.bend connection_check.bend clock_check.bend live_tick_check.bend live_commands_check.bend live_combat_check.bend combat_targets_check.bend spin_plans_check.bend live_spin_check.bend live_attack_check.bend; do
  bun "${BEND2_CORE:-../bend2-core}/bend2/main.ts" "$source" > "$actual"
  sed -n 's/^#| //p' "$source" > "$expected"
  diff -u "$expected" "$actual"
  cat "$actual"
done
