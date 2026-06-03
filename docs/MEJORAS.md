# 📈 MEJORAS — Backend Streaming

**Proyecto:** backend-streaming
**Fecha:** 2026-06-01 (actualizado)
**Resultado tests:** ✅ **103 tests passing** — pytest + SQLite in-memory (ver `pytest.ini`, `conftest.py`, `streaming_project/test_settings.py`)

---

## 🧪 Cobertura de Tests

| App | Tests | Coverage |
|-----|-------|----------|
| `accounts` | 20 tests | Modelos, serializers, views, actions, filtros |
| `screens` | 19 tests | Modelo, validación PIN, serializers, views |
| `customers` | 9 tests | Modelo, serializer, views, subresource |
| `providers` | 12 tests | Platform + Provider, serializers, views |
| `emails` | 13 tests | Modelo, serializers, views, filtros |
| `customer_accounts` | 18 tests | Modelo, fecha_cobro/corte, serializers, views |
| `dashboard` | 4 tests | Endpoints summary y vencidas |
| **Total** | **103** | ✅ Todos pasando |

### Cómo correr los tests

```bash
source venv/bin/activate
pytest

# Con más detalle:
pytest -v --tb=short

# Solo una app:
pytest accounts/
```

---

## 🔒 Seguridad

| # | Mejora | Prioridad | Estado | Notas |
|---|--------|-----------|--------|-------|
| 1 | **Contraseñas en .env** | 🔴 Alta | ⚠️ `.env` con password real de DB en texto plano | El `.env` debe estar en `.gitignore`. Agregar `.env.example` con valores dummy. Crear script para generar secretos. |
| 2 | **Secret Key de Django** | 🔴 Alta | ⚠️ `SECRET_KEY` hardcodeada en `.env` | Usar `python -c "import secrets; print(secrets.token_urlsafe(50))"` para generar. En producción usar vault o variable de sistema. |
| 3 | **Autenticación en API** | 🔴 Alta | 🔴 Sin auth — CRUD abierto | Implementar `TokenAuthentication` de DRF o JWT (`djangorestframework-simplejwt`). Al menos proteger POST/PUT/PATCH/DELETE. Ver `REST_FRAMEWORK` en `settings.py`. |
| 4 | **CORS** | 🟡 Media | ❌ Sin config | Instalar `django-cors-headers`, configurar `CORS_ALLOWED_ORIGINS` si se consume desde frontend. |
| 5 | **HTTPS** | 🟡 Media | Solo HTTP dev | En producción: `SECURE_SSL_REDIRECT=True`, `SESSION_COOKIE_SECURE=True`, `CSRF_COOKIE_SECURE=True`. |
| 6 | **Rate limiting** | 🟢 Baja | Sin límites | Agregar throttling en DRF: `rest_framework.throttling.ScopedRateThrottle`. |

---

## 🧹 Calidad de Código

| # | Mejora | Prioridad | Estado | Notas |
|---|--------|-----------|--------|-------|
| 7 | **Tests** | 🔴 Alta | ✅ 103 tests (completado) | Siguiente: agregar tests de Edge cases y tests de integración entre apps. |
| 8 | **Manejo de errores** | 🟡 Media | Genérico DRF | Personalizar respuestas de error con mensajes en español. Crear mixin `ErrorResponseMixin`. |
| 9 | **Logging** | 🟡 Media | Django por defecto | Configurar logging estructurado: registrar cambios de estado, errores de BD, peticiones lentas. Agregar a `settings.py`. |
| 10 | **Validación de PIN** | 🟢 Baja | ✅ Ya tiene `RegexValidator` en modelo | Considerar agregar `validate_pin()` en el serializer también para mensajes de error más descriptivos. |
| 11 | **Docstrings** | 🟢 Baja | Sin docs | Agregar docstrings a models, views y serializers. Priorizar los métodos con lógica de negocio (`fecha_pago`, `fecha_cobro`, etc.). |
| 12 | **Type hints** | 🟢 Baja | Sin tipos | Agregar type hints a métodos de modelos y views. Ejecutar `mypy` periódicamente. |
| 13 | **Cleanup modelos** | 🟡 Media | `managed=False` en todos | Los modelos usan `managed=False` (schema externo). Evaluar crear migraciones para control de versiones o documentar por qué se mantiene así. |

---

## ⚡ Rendimiento

| # | Mejora | Prioridad | Estado | Notas |
|---|--------|-----------|--------|-------|
| 14 | **`select_related` / `prefetch_related`** | 🟡 Media | Parcial | `AccountViewSet` usa `select_related` ✅. Revisar `ScreenViewSet`, `CustomerAccountViewSet` — ya lo usan ✅. `CustomerViewSet.purchases` no hace prefetch de screens/accounts → N+1 query potencial. |
| 15 | **Índices en DB** | 🟡 Media | Solo PK/FK por defecto | Agregar índices compuestos: `(status, platform_id)` en accounts, `(status, fecha_inicio)` en screens, `(customer_id, status)` en screens. |
| 16 | **Paginación** | 🟢 Baja | ✅ 25 por página | Correcto. Si la tabla supera 10k registros, considerar `CursorPagination`. |
| 17 | **Fechas calculadas en Python** | 🟢 Baja | ✅ `@property` correcto | `fecha_pago`, `fecha_cobro`, `fecha_corte` son `@property` — está bien para reads. Si necesitas filtrar por fecha calculada, usar `annotate` con `F()`. |

---

## 🧩 Features Faltantes

| # | Mejora | Prioridad | Estado | Notas |
|---|--------|-----------|--------|-------|
| 18 | **Documentación API (Swagger)** | 🟡 Media | Sin docs | Instalar `drf-spectacular` (`pip install drf-spectacular`), agregar a `INSTALLED_APPS`, generar schema en `/api/schema/` y UI en `/api/docs/`. |
| 19 | **Filtro por fechas calculadas** | 🟡 Media | No disponible | No se puede filtrar por `fecha_pago` porque es `@property`. Solución: usar `.annotate(fecha_pago=...)` en los querysets de filtrado. |
| 20 | **Notificaciones de vencimiento** | 🟡 Media | Sin alertas | Crear `python manage.py check_vencimientos` que revise pantallas por vencer y envíe notificaciones (email/Telegram/WhatsApp). |
| 21 | **Búsqueda global** | 🟢 Baja | No existe | Crear `GET /api/search/?q=...` que busque en emails, clientes, cuentas y pantallas simultáneamente. |
| 22 | **Historial de cambios de estado** | 🟡 Media | Sin tracking | Cada cambio de estado sobreescribe el anterior. Crear tabla `status_log` con `django-simple-history` o a mano: timestamp, usuario, modelo, ID, estado_anterior, estado_nuevo. |
| 23 | **Exportación Excel/CSV** | 🟢 Baja | Solo JSON | Agregar `django-import-export` o endpoints que devuelvan CSV para reportes de dashboard. |
| 24 | **Panel admin mejorado** | 🟢 Baja | Básico | `AccountAdmin` con `ScreenInline` ✅. Agregar filtros por rango de fechas, actions en lote (marcar como caída), exportar desde admin. |
| 25 | **Validación de negocio** | 🟡 Media | Sin validación | No se valida que las pantallas vendidas no excedan `max_screens`. Al crear `Screen`, verificar que `account.screens.count() < account.max_screens`. |

---

## 🐳 DevOps

| # | Mejora | Prioridad | Estado | Notas |
|---|--------|-----------|--------|-------|
| 26 | **Docker** | 🟡 Media | Sin Docker | Crear `Dockerfile` + `docker-compose.yml` con MariaDB + Django para desarrollo reproducible. |
| 27 | **Script de backup** | 🟡 Media | Sin backup | Crear script que haga `mysqldump` de la BD periódicamente. |
| 28 | **CI/CD** | 🟡 Media | Sin pipeline | Agregar GitHub Actions para correr `pytest` automáticamente en cada push. |

---

## 📊 Resumen de Prioridades

| Prioridad | Cantidad | Items clave |
|-----------|----------|-------------|
| 🔴 Alta | 4 | Tests ✅, Auth API, Secrets en `.env`, SECRET_KEY |
| 🟡 Media | 13 | Swagger, Índices DB, Docker, Logging, Limpieza models, Validación negocio, Historial estados, Búsqueda global |
| 🟢 Baja | 11 | Type hints, Docstrings, Rate limiting, CORS, HTTPS, Export CSV |
| **Total** | **28** | |

### Sprint 1 recomendado (orden sugerido)

1. 🔴 **Auth en la API** — TokenAuthentication o JWT (`djangorestframework-simplejwt`)
2. 🔴 **Mover secrets a variables de sistema** — `.env` en gitignore, valores dummy en repo
3. 🟡 **Swagger** (`drf-spectacular`)
4. 🟡 **Validación de negocio** — no vender más pantallas de `max_screens`
5. 🟡 **Dockerizar** — Dockerfile + docker-compose para dev reproducible
6. 🟡 **Índices en DB** — para queries frecuentes por `(status, platform_id)`