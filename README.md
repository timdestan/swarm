# Swarm

A Galaga-inspired arcade shooter built with [Odin](https://odin-lang.org/) and
[Raylib](https://www.raylib.com/).

Enemy ships fly into formation along bezier curves, then drift in formation
while firing at the player. Survive as long as you can across increasingly large
waves.

## Building

**Requirements**

- [Odin compiler](https://odin-lang.org/docs/install/) (includes Raylib via
  `vendor:raylib`)

**Build and run**

```sh
odin run .
```

**Build only**

```sh
odin build . -out:swarm.exe
```

**WebAssembly**

```sh
odin build . -target:js_wasm32 -out:swarm.wasm
```

Requires a host page that loads `odin.js` from the Odin compiler's
`core/sys/wasm/js/` directory. Settings are persisted via `localStorage`
instead of a config file.

## Controls

| Key | Action |
|-----|--------|
| WASD / Arrow keys | Move |
| Space / Left Ctrl | Shoot |
| R | Restart (after game over) |

## Powerups

Enemies occasionally drop powerups when killed.

| Icon | Effect |
|------|--------|
| `2x` | Double shot — fires two bullets simultaneously |
| `$`  | Score bonus — instant +500 points |
| `X`  | Exploding shot — bullets explode on impact, damaging nearby enemies |

## Credits

See [ACKNOWLEDGEMENTS.md](ACKNOWLEDGEMENTS.md) for credits.
