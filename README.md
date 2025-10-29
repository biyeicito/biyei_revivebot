## 🧑‍⚕️ Biyei Revive Bot

Bot NPC de reanimación configurable, compatible con `ox_target` o `qb-target`, y alternativa con TextUI de `ox_lib` cuando no usas target. El médico es client-side: camina hasta tu posición, realiza animación de tratamiento si estás herido, o RCP si estás muerto, y al finalizar vuelve a su punto de origen. Incluye validaciones por framework (auto ESX/QBCore), whitelist por empleo y citizenid, y restricción por cantidad de médicos conectados. Al curar/revivir muestra un progressbar (ox_lib).

### Requisitos
- `ox_lib` (obligatorio)
- `ox_target` o `qb-target` (opcional según `Config.UseTarget` y `Config.Target`)
- Framework: ESX o QBCore (detección automática si `Config.Framework = 'auto'`)

### Instalación
1. Copia la carpeta `biyei_revivebot` a `resources/[standalone]/[bot revivir]/`.
2. Asegúrate de tener `ox_lib` iniciado antes de este recurso.
3. Inicia el recurso en tu `server.cfg`:

```cfg
ensure ox_lib
ensure biyei_revivebot
```

Si utilizas target, también inicia `ox_target` o `qb-target` según tu configuración.

### Configuración
Archivo: `config.lua`

- `Config.Framework`: `'auto' | 'esx' | 'qbcore'` – Detección del framework.
- `Config.MedicsJobs`: lista de jobs considerados como médicos (para el filtro de disponibilidad).
- `Config.EventRevive`: evento que se dispara al finalizar la reanimación (se invoca en cliente y servidor para mayor compatibilidad).
- `Config.UseTarget`: `true` para usar `ox_target`/`qb-target`, `false` para usar TextUI de `ox_lib` y tecla `E`.
- `Config.Target`: `'ox_target' | 'qb-target'` – Sólo aplica si `UseTarget = true`.
- `Config.Bots`: lista de bots. Cada entrada acepta:
  - `jobs`: `false` para permitir cualquiera o lista de empleos permitidos (ej. `{ 'police', 'ambulance' }`).
  - `citizenid`: `false` para permitir cualquiera o lista de IDs permitidos.
  - `model`: modelo del NPC (ej. `'s_m_m_doctor_01'`).
  - `minMedics`: número mínimo de médicos conectados para deshabilitar al bot. Si hay `>= minMedics`, se deniega el uso.
  - `coords`: `vector4(x, y, z, w)` posición y heading del bot.
  - `secondsToRevive`: segundos de la barra de progreso de curación.

Nota sobre médicos: el bot permite reanimar solo cuando la cantidad de médicos conectados es menor a `minMedics`. Por ejemplo, si `minMedics = 1` y hay 1 o más médicos conectados, el bot denegará el servicio.

### Uso
- Acércate al NPC.
  - Si `UseTarget = true`, interactúa con el target y elige “Revivir”.
  - Si `UseTarget = false`, aparecerá TextUI `[E] Hablar con médico`; presiona `E`.
- Debes estar inconsciente para poder usarlo. Comenzará un progressbar “Reanimando…”, tras el cual se disparará `Config.EventRevive`.

### Créditos
- Creado por: Biyei
- Créditos adicionales: TuNombreAquí

Si compartes o modificas, por favor mantén los créditos.

### Soporte
Si necesitas ajustes (más checks, animaciones o integración con tu sistema de ambulancias), abre un issue o personaliza el `client.lua` y `server.lua` según tus necesidades.