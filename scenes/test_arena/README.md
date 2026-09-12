# Test Arena

Open `test_arena.tscn` in Godot and press **F6**. **F5** still starts the normal game.

Drag the reusable zero-cost card into the outlined left clearing. Units fight the
stationary Scarecrow. RESET DUMMY replaces the target at 9999 HP, even after death.
CLEAR UNITS removes all other test actors, sibling summons, corpses, and projectiles.
BACK TO MAIN GAME starts the normal main scene at Battle 1; it does not resume a
previously running battle. Permanent unlocks are untouched.

## Trying another unit

1. Open `test_unit_placeholder.tres` in the Inspector.
2. Change **Unit Scene** to a scene inheriting `Unit`.
3. Optionally update the presentation type/description. Leave cost at zero.
4. Run `test_arena.tscn` with F6 and summon repeatedly.

The Resource intentionally has no copied stat arrays: the referenced scene supplies
base Attack and HP. Existing `CardData` star profiles are also supported. The
sandbox sets the spawned instance to PLAYER before ready; it never edits the source
scene. Custom future units should respect their `team` field when targeting/summoning.

All actors share `UnitLayer` with Y-sort enabled. The Scarecrow uses normal damage,
health bars, target-owned attacker slots, and death presentation, but runs no combat
AI itself. It has no MonsterData and is not part of any catalog or progression pool.

The arena uses a fixed local 10/10 Power display and never spends run currencies.
There is no deck, BattleManager, reward, shop, victory, or defeat condition here.
