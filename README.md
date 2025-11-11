## 🧑‍⚕️ Biyei Revive Bot

Configurable resuscitation NPC bot, compatible with `ox_target` or `qb-target`, with an `ox_lib` TextUI fallback when you don't use a target. The doctor runs client-side: walks to your position, plays a treatment animation if you are injured, or CPR if you are dead, and then returns to the origin point. Includes framework checks (auto ESX/QBCore), whitelist by job and citizenid, and restriction based on the number of connected medics. When healing/reviving it shows a progress bar (ox_lib).

### Preview
https://streamable.com/h4uxci

### Requirements
- `ox_lib` (required)
- `ox_target` or `qb-target` (optional depending on `Config.UseTarget` and `Config.Target`)
- Framework: ESX or QBCore (auto-detection if `Config.Framework = 'auto'`)

### Installation
1. Copy the `biyei_revivebot` folder to `resources/[standalone]/[bot revivir]/`.
2. Make sure `ox_lib` is started before this resource.
3. Start the resource in your `server.cfg`:

```cfg
ensure ox_lib
ensure biyei_revivebot
```

If you use a target, also start `ox_target` or `qb-target` according to your configuration.

### Configuration
File: `config.lua`

- `Config.Framework`: `'auto' | 'esx' | 'qbcore'` – Framework detection.
- `Config.MedicsJobs`: list of jobs considered as medics (for the availability filter).
- `Config.EventRevive`: event fired when the resuscitation finishes (invoked on both client and server for broader compatibility).
- `Config.UseTarget`: `true` to use `ox_target`/`qb-target`, `false` to use `ox_lib` TextUI and the `E` key.
- `Config.Target`: `'ox_target' | 'qb-target'` – Only applies if `UseTarget = true`.
- `Config.Bots`: list of bots. Each entry accepts:
  - `jobs`: `false` to allow anyone or a list of allowed jobs (e.g. `{ 'police', 'ambulance' }`).
  - `citizenid`: `false` to allow anyone or a list of allowed IDs.
  - `model`: NPC model (e.g. `'s_m_m_doctor_01'`).
  - `minMedics`: minimum number of connected medics to disable the bot. If there are `>= minMedics`, usage is denied.
  - `coords`: `vector4(x, y, z, w)` bot position and heading.
  - `secondsToRevive`: seconds for the healing progress bar.

Note about medics: the bot only allows reviving when the number of connected medics is less than `minMedics`. For example, if `minMedics = 1` and there are 1 or more medics connected, the bot will deny the service.

### Usage
- Approach the NPC.
  - If `UseTarget = true`, interact with the target and choose "Revive".
  - If `UseTarget = false`, a TextUI will appear: `[E] Talk to doctor`; press `E`.
- You must be unconscious to use it. It will start a "Resuscitating…" progress bar, after which `Config.EventRevive` is triggered.

- ### Our store
- Store: https://store.biyei.net

### Credits
- Created by: Biyei


If you share or modify, please keep the credits.

### Support
If you need adjustments (more checks, animations, or integration with your ambulance system), open an issue or customize `client.lua` and `server.lua` to your needs.
