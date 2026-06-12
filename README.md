# Backend Streaming

Backend en Django REST Framework para una dashboard de gestion de inventario de cuentas de streaming.

El sistema permite administrar compras a proveedores, ventas a clientes, inventario disponible, pantallas vendidas, cuentas completas vendidas, cobros, garantias y resumenes para dashboard.

---

## Estado actual

- `schema.sql` crea la base `streaming_business` desde cero y carga informacion inicial.
- `indices.sql` fue corregido para usar columnas reales del esquema.
- Los tests pasan con:

```bash
python -m pytest -q
```

- La API esta construida con Django REST Framework.
- La documentacion Swagger esta disponible en `/api/docs/`.
- La API todavia no tiene autenticacion activa: en desarrollo los endpoints estan abiertos.

---

## En que quedamos

Este proyecto es el backend de una dashboard para gestionar inventario de cuentas de streaming.

Permite manejar:

- Proveedores.
- Plataformas.
- Correos comprados o controlados por el negocio.
- Clientes.
- Cuentas compradas a proveedores.
- Pantallas vendidas a clientes.
- Cuentas completas vendidas a clientes.
- Ordenes de venta.
- Cobros.
- Garantias y reemplazos.
- Indicadores para dashboard.

El flujo principal es:

1. Se compra una cuenta a un proveedor.
2. La cuenta entra al inventario con una capacidad definida en `max_screens`.
3. La cuenta puede venderse por pantallas individuales o como cuenta completa.
4. Si se vende por pantallas, no se puede superar la capacidad de la cuenta.
5. Si una cuenta ya tiene pantallas activas, no se debe vender como cuenta completa.
6. Si una cuenta ya fue vendida completa, no se deben vender pantallas de esa cuenta.
7. Las ventas transaccionales se crean desde `POST /api/orders/sell/`.
8. Las garantias o reemplazos se registran desde `POST /api/orders/warranty/`.

---

## Modelo de negocio

### Actores

| Actor | Descripcion |
|---|---|
| Proveedor | Vende cuentas completas al negocio. |
| Cliente | Compra pantallas, cuentas completas o combos. |
| Correo | Email asociado a una cuenta. El proveedor se obtiene desde el correo. |
| Plataforma | Servicio vendido, por ejemplo Netflix, Disney+, HBO Max o Prime Video. |

### Productos

| Producto | Tabla | Descripcion |
|---|---|---|
| Cuenta de inventario | `accounts` | Cuenta comprada a proveedor. Tiene plataforma, correo, costo, fechas y `max_screens`. |
| Pantalla | `screens` | Perfil individual vendido a un cliente desde una cuenta. |
| Cuenta completa vendida | `customer_accounts` | Cuenta completa asignada directamente a un cliente. |
| Orden | `orders` | Agrupa una venta. Puede contener pantallas, cuentas completas o ambas. |
| Garantia | `warranty_claims` | Registra caidas, reemplazos y trazabilidad de garantias. |

### Estados principales

| Estado | Uso |
|---|---|
| `disponible` | Pantalla disponible para venta. |
| `activo` | Servicio vendido y funcionando. |
| `por_vencer` | Servicio proximo a vencer. |
| `vencida` | Servicio vencido. |
| `caida` | Servicio con falla o caida. |

---

## Stack

| Componente | Tecnologia |
|---|---|
| Backend | Python + Django |
| API | Django REST Framework |
| Documentacion API | drf-spectacular / Swagger |
| Base de datos | MySQL o MariaDB |
| Tests | pytest |
| Schema | SQL externo con modelos Django `managed = False` |

---

## Estructura principal

```text
backend-streaming/
|-- manage.py
|-- schema.sql
|-- indices.sql
|-- requirements.txt
|-- streaming_project/
|-- providers/
|-- emails/
|-- customers/
|-- accounts/
|-- screens/
|-- customer_accounts/
|-- orders/
|-- dashboard/
`-- status_log/
```

---

## Instalacion local

### 1. Crear entorno virtual

En Windows PowerShell:

```powershell
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

En Linux o macOS:

```bash
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 2. Configurar `.env`

Crear un archivo `.env` en la raiz del proyecto:

```env
DB_NAME=streaming_business
DB_USER=root
DB_PASSWORD=tu_password
DB_HOST=localhost
DB_PORT=3306
SECRET_KEY=django-insecure-dev-key
DEBUG=True
```

No subas credenciales reales al repositorio.

### 3. Crear base de datos con datos iniciales

Desde la raiz del proyecto:

```bash
mysql -u root -p < schema.sql
```

Luego aplicar indices:

```bash
mysql -u root -p streaming_business < indices.sql
```

### 4. Verificar Django

```bash
python manage.py check
```

### 5. Ejecutar tests

```bash
python -m pytest -q
```

---

## Ejecutar servidor

Si el puerto `8000` esta libre:

```bash
python manage.py runserver 127.0.0.1:8000
```

Si Postman muestra `socket hang up` al llamar `localhost:8000`, puede ser porque Docker/WSL esta ocupando el puerto. En ese caso usa el puerto `8001`:

```bash
python manage.py runserver 127.0.0.1:8001
```

Prueba en Postman:

```http
GET http://127.0.0.1:8001/api/accounts/
```

Nota: usa la barra final `/` porque Django REST Framework la espera en estas rutas.

---

## Endpoints recomendados para probar

### Inventario y catalogos

| Metodo | Endpoint | Descripcion |
|---|---|---|
| `GET` | `/api/platforms/` | Lista plataformas. |
| `GET` | `/api/providers/` | Lista proveedores. |
| `GET` | `/api/emails/` | Lista correos. |
| `GET` | `/api/customers/` | Lista clientes. |
| `GET` | `/api/accounts/` | Lista cuentas compradas en inventario. |
| `GET` | `/api/screens/` | Lista pantallas vendidas o disponibles. |
| `GET` | `/api/customer-accounts/` | Lista cuentas completas vendidas. |
| `GET` | `/api/orders/` | Lista ordenes. |

### Acciones principales

| Metodo | Endpoint | Descripcion |
|---|---|---|
| `GET` | `/api/accounts/{id}/screens/` | Lista pantallas de una cuenta. |
| `PATCH` | `/api/accounts/{id}/change_status/` | Cambia estado de una cuenta. |
| `PATCH` | `/api/screens/{id}/change_status/` | Cambia estado de una pantalla. |
| `POST` | `/api/orders/sell/` | Crea una venta transaccional con pantallas, cuentas completas o combo. |
| `POST` | `/api/orders/warranty/` | Registra garantia, caida o reemplazo. |

### Dashboard

| Metodo | Endpoint | Descripcion |
|---|---|---|
| `GET` | `/api/dashboard/resumen/` | Resumen financiero y operativo. |
| `GET` | `/api/dashboard/inventario/` | Disponibilidad real por plataforma. |
| `GET` | `/api/dashboard/cobros/` | Cobros pendientes. |
| `GET` | `/api/dashboard/vencimientos/` | Vencimientos de clientes. |
| `GET` | `/api/dashboard/clientes-inactivos/` | Clientes sin servicios activos. |
| `GET` | `/api/dashboard/ingresos/plataforma/` | Ingresos por plataforma. |
| `GET` | `/api/dashboard/ingresos/proveedor/` | Ingresos por proveedor. |
| `GET` | `/api/dashboard/ingresos/cliente/` | Ingresos por cliente. |
| `GET` | `/api/dashboard/egresos/proveedor/` | Compras por proveedor. |
| `GET` | `/api/dashboard/egresos/plataforma/` | Compras por plataforma. |

### Documentacion

| Metodo | Endpoint | Descripcion |
|---|---|---|
| `GET` | `/api/docs/` | Swagger UI. |
| `GET` | `/api/schema/` | Schema OpenAPI. |

---

## Ejemplo de venta

`POST /api/orders/sell/`

```json
{
  "customer": 1,
  "fecha_inicio": "2026-06-11",
  "status": "activo",
  "observaciones": "Venta de prueba",
  "items": [
    {
      "type": "screen",
      "account": 1,
      "profile_name": "Perfil 1",
      "pin": "1234",
      "precio_venta": "15000.00"
    },
    {
      "type": "customer_account",
      "account": 2,
      "email": "cliente@example.com",
      "contrasena": "clave123",
      "precio_venta": "30000.00"
    }
  ]
}
```

El backend calcula el total de la orden desde los items y aplica validaciones de disponibilidad.

---

## Seguridad pendiente

Actualmente la API no tiene autenticacion activa. Esto sirve para desarrollo local, pero antes de usar el sistema en produccion se recomienda:

- Agregar autenticacion JWT.
- Proteger endpoints con `IsAuthenticated`.
- Separar permisos por rol, por ejemplo administrador, vendedor y consulta.
- Mover credenciales reales a variables de entorno seguras.
- Revisar `DEBUG=False` en produccion.

---

## Comandos utiles

```bash
python manage.py check
python -m pytest -q
python manage.py runserver 127.0.0.1:8001
mysql -u root -p < schema.sql
mysql -u root -p streaming_business < indices.sql
```
