# 📈 MEJORAS — Backend Streaming

**Proyecto:** backend-streaming  
**Fecha:** 2026-06-01  
**Autor:** Revisión automática

---

## 🔒 Seguridad

| # | Mejora | Prioridad | Estado actual | Estado deseado |
|---|--------|-----------|---------------|----------------|
| 1 | **Contraseñas en .env** | 🔴 Alta | `DB_PASSWORD=***` quemada en el `.env` con la contraseña real en texto plano | Usar variables de entorno del sistema o un vault. El `.env` debería estar en `.gitignore` y tener solo valores de ejemplo |
| 2 | **Secret Key de Django** | 🔴 Alta | `SECRET_KEY` hardcodeada en settings.py | Generar con `python -c "import secrets; print(secrets.token_urlsafe(50))"` y ponerla en `.env` |
| 3 | **Autenticación en API** | 🔴 Alta | La API REST no tiene autenticación — cualquiera puede hacer CRUD | Agregar DRF TokenAuthentication o JWT (SimpleJWT). Al menos proteger POST/PUT/DELETE |
| 4 | **CORS** | 🟡 Media | No hay configuración CORS | Si se consume desde frontend en otro puerto/dominio, instalar `django-cors-headers` y configurarlo |
| 5 | **HTTPS** | 🟡 Media | Solo HTTP en desarrollo | En producción forzar HTTPS. Configurar `SECURE_SSL_REDIRECT`, `SESSION_COOKIE_SECURE`, etc. |
| 6 | **Rate limiting** | 🟢 Baja | Sin límite de peticiones | Agregar `django-ratelimit` o DRF throttling pa' evitar abusos |

---

## 🧹 Calidad de Código

| # | Mejora | Prioridad | Estado actual | Estado deseado |
|---|--------|-----------|---------------|----------------|
| 7 | **Tests** | 🔴 Alta | 0 tests escritos (solo los archivos por defecto de Django) | Crear tests unitarios para modelos (validaciones, propiedades calculadas) y tests de API (CRUDs, filtros, change-status) |
| 8 | **Manejo de errores** | 🟡 Media | Los ViewSet usan el comportamiento por defecto de DRF | Personalizar respuestas de error con códigos y mensajes consistentes en español |
| 9 | **Logging** | 🟡 Media | Solo el logging por defecto de Django | Configurar logging estructurado para debug en producción: registrar cambios de estado, errores de BD, peticiones lentas |
| 10 | **Validación de PIN** | 🟢 Baja | RegexValidator en el modelo | La validación en modelo está bien, pero agregar también en el serializer una validación personalizada `validate_pin()` |
| 11 | **Docstrings** | 🟢 Baja | Sin documentación en el código | Agregar docstrings a models (explicar campos), views (explicar actions), serializers |
| 12 | **Type hints** | 🟢 Baja | Sin type hints | Agregar tipado Python a métodos de modelos y views |

---

## ⚡ Rendimiento

| # | Mejora | Prioridad | Estado actual | Estado deseado |
|---|--------|-----------|---------------|----------------|
| 13 | **select_related / prefetch_related** | 🟡 Media | `AccountViewSet` ya usa `select_related` pero otros viewsets quizás no | Revisar todos los list views y asegurar que usan `select_related` para FK y `prefetch_related` para reverse relations (ej: account → screens) |
| 14 | **Índices en DB** | 🟡 Media | Solo los índices por defecto (PK, FK) | Agregar índices compuestos para consultas frecuentes: (status, platform_id), (status, fecha_inicio), (customer_id) en screens |
| 15 | **Paginación** | 🟢 Baja | PageNumberPagination con 25 por página (valor por defecto) | Está bien, pero considerar CursorPagination si la tabla crece mucho (+10k registros) |
| 16 | **Campos calculados en DB vs Python** | 🟢 Baja | `fecha_pago`, `fecha_cobro`, `fecha_corte` son `@property` en Python | Evaluar si conviene usar los generated columns de MariaDB para consultas directas. Por ahora está bien en Python, pero si se necesitan filtros SQL pesados, mejor en DB |

---

## 🧩 Features faltantes

| # | Mejora | Prioridad | Estado actual | Estado deseado |
|---|--------|-----------|---------------|----------------|
| 17 | **Documentación de API (Swagger)** | 🟡 Media | No hay docs interactivos | Agregar `drf-spectacular` o `drf-yasg` para generar Swagger/OpenAPI en `/api/docs/` |
| 18 | **Filtro por fechas calculadas** | 🟡 Media | No se puede filtrar cuentas por `fecha_pago` porque es `@property` | Evaluar si filtrar por `fecha_compra + 28` en SQL o agregar un campo `fecha_pago` real en la consulta con annotate |
| 19 | **Notificaciones de vencimiento** | 🟡 Media | No hay alertas | Crear un management command tipo `python manage.py check_vencimientos` que revise pantallas por vencer/vencidas y envíe alertas |
| 20 | **Endpoint de búsqueda global** | 🟢 Baja | No hay búsqueda unificada | Crear `/api/search/?q=...` que busque en emails, clientes, cuentas, pantallas simultáneamente |
| 21 | **Historial de cambios de estado** | 🟡 Media | Cada cambio de estado sobreescribe el anterior | Crear tabla `status_log` o usar `django-simple-history` para trackear cuándo y quién cambió cada estado |
| 22 | **Exportación a Excel/CSV** | 🟢 Baja | Solo API JSON | Agregar exportación con `django-import-export` o endpoints que devuelvan CSV para reportes |
| 23 | **Panel admin más completo** | 🟢 Baja | Admin funcional pero básico | Agregar filtros por rango de fechas, actions personalizadas (marcar como caída en lote), exportar desde admin |

---

## 🐳 DevOps

| # | Mejora | Prioridad | Estado actual | Estado deseado |
|---|--------|-----------|---------------|----------------|
| 24 | **Dockerizar** | 🟡 Media | Sin Docker | Crear `Dockerfile` + `docker-compose.yml` con MariaDB + Django para desarrollo reproducible |
| 25 | **Script de backup** | 🟡 Media | Sin backup automatizado | Crear script que haga dump de la BD y respalde los archivos |
| 26 | **Migraciones gestionadas** | 🟡 Media | `managed = False` en todos los modelos | Evaluar si dejar `managed = False` (cambios manuales en DB) o cambiarlo a `managed = True` con migraciones Django para control de versiones del schema |

---

## 📊 Resumen

| Prioridad | Cantidad |
|-----------|----------|
| 🔴 Alta | 4 |
| 🟡 Media | 11 |
| 🟢 Baja | 11 |
| **Total** | **26** |

### Prioridades recomendadas (sprint 1)
1. 🔴 Poner SECRET_KEY y contraseñas en `.env`
2. 🔴 Agregar autenticación a la API
3. 🔴 Escribir tests básicos
4. 🟡 Agregar Swagger (`drf-spectacular`)
5. 🟡 Dockerizar el proyecto
