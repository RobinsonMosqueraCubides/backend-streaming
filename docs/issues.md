# Issues — Migración Excel → Schema SQL

Fecha: 2026-06-03

## 1. Emails duplicados entre proveedores

**Descripción:** 10 correos aparecen en más de un proveedor. La columna `emails.email` perdió el `UNIQUE` para permitir duplicados. Esto genera ambigüedad en los `SELECT ... LIMIT 1` de las subqueries.

| Email | Proveedores |
|---|---|
| `agaray2107@gmail.com` | P VARIOS, P ADRIANA |
| `stremingflix001@gmail.com` | P VARIOS, P ADRIANA |
| `stremingflix002@gmail.com` | P VARIOS, P ADRIANA |
| `robin.mosquera13@gmail.com` | P VARIOS, P ADRIANA |
| `humberto2026@kikoshop.net` | P WILLIAM, P VARIOS |
| `jhon2026@kikoshop.net` | P WILLIAM, P VARIOS |
| `martha2026ballesteros@kikoshop.net` | P WILLIAM, P VARIOS |
| `paramex1@kikoshop.net` | P WILLIAM, P VARIOS |
| `paramountetb3@kikoshop.net` | P WILLIAM, P VARIOS |

**Decisión:** Se quitó `UNIQUE`, se permiten duplicados.

---

## 2. Valor numérico en columna de vencimiento

**Descripción:** 2 filas tienen `10000.0` (un número/precio) en la columna `VENCIMIENTO` en vez de un estado textual (`DISPONIBLE`, `VENCIDA`, `VENCE HOY`).

**Decisión:** Se dejaron como `status = 'activo'` con nota en `observaciones`: _"Valor inesperado en vencimiento: 10000.0"_.

---

## 3. Plataformas no mapeadas en el Excel

**Descripción:** Algunos nombres de plataforma en el Excel no coincidían exactamente con el catálogo. Se creó un mapeo de normalización:

| Excel | → BD |
|---|---|
| `DISNEY` | Disney+ |
| `AMazon`, `AMAZON`, `AMazon 6m` | Prime Video |
| `MAX`, `MAX NUEVO`, `Hbo max`, `hbo max` | HBO Max |
| `DGO`, `DGO TV` | Directv Go |
| `CRUNCHYROLL`, `Crunchyroll` | Crunchyroll |
| `SPOTIFY`, `Spotify x 3 meses` | Spotify |
| `CHAT GPT` | ChatGPT |
| `PARAMOUNT` | Paramount+ |
| `𝗩𝗜𝗫` (unicode bold) | VIX |
| `yt 3 meses` | YouTube Premium |

**Plataformas agregadas:** Paramount+, VIX, YouTube Premium

---

## 4. Pantallas sin correo electrónico (6 casos)

**Descripción:** En las hojas DISNEY, MAX y AMAZON P, algunas filas tienen cliente, PIN y contraseña pero **la columna CORREO está vacía**. No se puede crear el `screens` porque `account_id` es `NOT NULL` y no hay email para buscar la cuenta.

| Cliente | Plataforma | Hoja | ¿Tiene contraseña? |
|---|---|---|---|
| Leidisita | Prime Video | AMAZON P | ❌ |
| Leidisita | HBO Max | MAX | ✅ `SIBLINGS21` / `CAROLA212121` |
| Nataly COPOWER | Prime Video | AMAZON P | ❌ (dice "FALLÓ") |
| Silvia Garcia | HBO Max | MAX | ❌ |
| Yulitza Sanguino | HBO Max | MAX | ❌ |

**Estado:** ⚠️ Sin resolver. Posibles opciones:
- Buscar el email en otra hoja (misma cuenta compartida)
- Dejar `account_id = NULL` (requiere cambiar el schema)
- Crear la cuenta manualmente

---

## 5. Pantallas no encontradas en ninguna hoja (3 casos)

**Descripción:** El combo de C NETFLIX incluye plataformas (Crunchyroll, Directv Go) pero el cliente no aparece en `P VARIOS` ni en ninguna hoja de pantallas.

| Cliente | Plataforma | Código |
|---|---|---|
| Gustavo Adolfo Errera 4 | Crunchyroll | C |
| Silvia Garcia | Directv Go | DTV |
| Yulitza Sanguino | Directv Go | DTV |

**Estado:** ⚠️ Sin resolver. No hay datos para generar el `screens`.

---

## 6. Contraseñas con saltos de línea

**Descripción:** Varias celdas del Excel tienen contraseñas con `\n` (múltiples valores separados por nueva línea). Ej: `castillos9871\nbananas123`, `BETTYLAFEA\n999999@`.

**Decisión:** Se almacenaron tal cual en `emails.password`. Si se necesita split, debe hacerse manualmente.

---

## 7. Nombres de cliente inconsistentes entre hojas

**Descripción:** El mismo cliente aparece con variaciones de capitalización o espacios:
- `Nataly COPOWER` (C NETFLIX) vs `Nataly copower` (DISNEY) vs `Nataly copower` (AMAZON P)
- `Salome Esposo ` (C NETFLIX, con espacio al final) vs `Salome Esposo ` (DISNEY)

**Decisión:** El matching se hace case-insensitive y con trim. Pero puede haber falsos positivos/negativos en nombres muy similares.

---

## 8. Filas con headers repetidos dentro de los datos

**Descripción:** En varias hojas (especialmente C NETFLIX), hay filas que repiten los nombres de columna como si fueran datos. Ej: `CLIENTE = "CLIENTE"`, `CORREO = "CORREO"`.

**Decisión:** Se filtraron excluyendo valores que coinciden con nombres de header conocidos.

---

## Resumen

| Tipo | Cantidad | Estado |
|---|---|---|
| Emails duplicados | 10 | ✅ Permitidos (sin UNIQUE) |
| Vencimiento erróneo | 2 | ✅ Corregidos con nota |
| Plataformas normalizadas | ~10 variantes | ✅ Mapeadas |
| Pantallas sin email | 6 | ⚠️ Pendiente |
| Pantallas no encontradas | 3 | ⚠️ Pendiente |
| Contraseñas multilínea | ~8 | ✅ Almacenadas tal cual |
| Nombres inconsistentes | ~3 | ✅ Case-insensitive match |
| Headers como datos | ~5 filas | ✅ Filtrados |
