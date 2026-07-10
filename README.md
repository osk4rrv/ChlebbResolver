# Chlebb Resolver

A lightweight, educational CS:GO resolver script with an expanded **LuaJIT FFI** layer for reading player animation state, animation layers and entity data directly from memory.

> **Warning:** This project is provided for educational and research purposes only. Using it on live matchmaking or third-party servers may violate the Terms of Service of the game and/or the platform. The authors are not responsible for any bans or penalties caused by misuse.

---

## Features

- **Extended FFI definitions** for `CCSGOPlayerAnimState`, `C_CSPlayer` and animation layers.
- **Safe memory reads** wrapped in `pcall` to avoid hard crashes when offsets change.
- Helper functions:
  - `resolver_ffi.read_animstate(idx)` — read the player's animation state.
  - `resolver_ffi.read_player(idx)` — read the raw `C_CSPlayer` struct.
  - `resolver_ffi.read_layers(idx, count)` — read animation layers.
  - `resolver_ffi.get_desync_delta(idx)` — estimate the current desync delta.
  - `resolver_ffi.get_velocity_2d(idx)` — get the player's horizontal velocity.
- Configurable UI: enable/disable, resolver type, learning mode, extrapolation, clantag and trashtalk.
- Clean hit/miss logging with extrapolation tick info.

---

## Requirements

- A LuaJIT-based CS:GO scripting platform that exposes the following libraries:
  - `ffi`
  - `bit`
  - `vector`
  - `ui`, `client`, `entity`, `memory`, `globals`

---

## Installation

1. Copy `chlebb_resolver.lua` into your script directory.
2. Load the script via your platform's script manager.
3. Use the **RAGE > Other** menu to configure the resolver.

---

## Offsets

The offsets in this script are based on publicly available CS:GO SDK data. They may become outdated after game updates:

```lua
local animstate_offset = 0x9960
local animlayer_offset = 0x2980
local poseparam_offset = 0x2764
```

If the game crashes or helpers return `nil`, verify these offsets against the current game build.

---

## Repository

This repository is intentionally kept local. To publish it on GitHub:

1. Create a new empty repository named `ChlebbResolver` on GitHub.
2. Replace the placeholder remote URL:
   ```bash
   git remote set-url origin https://github.com/YOUR_USERNAME/ChlebbResolver.git
   ```
3. Push the code:
   ```bash
   git push -u origin main
   ```

---

## License

This project is licensed under the **GNU General Public License v3.0**. See [LICENSE](LICENSE) for details.
