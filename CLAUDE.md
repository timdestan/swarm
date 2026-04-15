# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Build commands

```sh
odin run .                                    # build and run (native)
odin build .                                  # build only (produces swarm.exe)
odin build . -target:js_wasm32 -out:swarm.wasm  # cross-compile to wasm
```

There are no tests or linter. The compiler is the only correctness check — a
clean `odin build .` is the definition of "passes".

The wasm build requires a host page that loads `odin.js` (from the Odin
compiler's `core/sys/wasm/js/` directory) alongside `swarm.wasm`. Settings
persistence in the wasm build uses `localStorage` instead of `settings.cfg`
(see `settings_io_js.odin`).

## Formatting

Odin files should be formatted with `odinfmt filename.odin -w` after making
changes.

## Architecture

The game is a single Odin package (`package swarm`) spread across two files:

- **main.odin** — everything: types, constants, game loop, update, draw, and all
  helpers
- **settings.odin** — pause menu UI, volume slider, and settings file
  persistence (`settings.cfg`)

### Data flow

```
main()
  └─ init_game()        — constructs Game_State from LEVEL_DATA
  └─ loop:
       update()         — mutates Game_State each frame
       draw()           — reads Game_State, calls draw_settings_menu()
```

`Game_State` is the single source of truth. It is stack-allocated in `main` and
passed by pointer to `update` and by value (via pointer) to `draw`.

### Level / wave system

Waves are defined by `LEVEL_DATA`, a `[NUM_LEVELS][WAVES_PER_LEVEL]Wave_Config`
compile-time array at the top of main.odin. Each `Wave_Config` specifies row
count, enemy variant weights (Standard / Aggressive / Heavy / Burst), and boss
HP. The last wave of every level is always a boss wave (`is_boss = true`).

`init_wave` dispatches to `init_formation` (grid of enemies) or `init_boss_wave`
(single saucer). Progress is tracked with `Game_State.level` and
`Game_State.level_wave`; both cycle through `LEVEL_DATA` indefinitely.

### Enemy state machine

Each `Enemy` runs through:
`Waiting → Entering → Formation → Diving → Returning → Formation …`

- **Waiting**: staggered entry delay (`enter_delay`)
- **Entering**: follows a quadratic Bézier curve to its formation slot
- **Formation**: drifts with the formation (`drift_time` sin wave); randomly
  dives; fires on a timer. Boss variant uses its own `sway_t` timer and a wide
  sin oscillation instead of formation drift
- **Diving / Returning**: leaves formation, flies toward player, loops back from
  the top

### Rendering order

Stars → Particles → Blast rings → Powerups → Enemy bullets → Player bullets →
Enemies → Boss health bar → Hit flashes → Player → HUD → Pause menu

### Build tags

Odin's platform build constraint directive is `#+build` (not `//+build`, which is a plain comment and silently ignored). Comma-separated values on one line are OR'd; space-separated values are AND'd. `settings_io.odin` uses `#+build !js` to exclude itself from wasm builds, and `settings_io_js.odin` uses `#+build js` to provide no-op stubs for that target.

### Font system

The game loads `assets/font.ttf` at startup (falls back to Raylib's default if
missing). All text goes through the two helpers `fnt_draw` and `fnt_width`,
which wrap `DrawTextEx`/`MeasureTextEx` with the global `FONT_SPACING` constant.
Both helpers are defined in main.odin and are visible to settings.odin since
they share the same package.

### Key constants (top of main.odin)

Tuning values worth knowing: `BOSS_HP_BASE`, `BOSS_FIRE_RATE_HIGH/LOW`,
`BOSS_SPREAD_HIGH/LOW`, `EXTRA_LIFE_THRESHOLD_START`, `EXTRA_LIFE_GAP_START`,
`EXTRA_LIFE_GAP_INCREASE`, `FONT_PATH`, `FONT_SPACING`.

### Assets

All assets live in `assets/`. Sprite sheets are loaded once in `main()` and
passed into `draw()` — there is no asset manager. Enemy sprites come from
`ships_biomech.png`; the boss sprite comes from `ships_saucer.png` (cropped at
`{12, 724, 72, 72}`). The player sprite comes from `modular_ships.png`.
