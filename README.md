# 🎬 Backend Streaming — Sistema de Gestión de Cuentas

Sistema backend para la administración y venta de cuentas de plataformas de streaming (Netflix, Disney+, HBO Max, Star+, Prime Video). Gestiona el inventario de cuentas compradas a proveedores, la venta de pantallas (perfiles) y cuentas completas a clientes, con control de fechas de cobro y corte.

---

## 📋 Modelo de Negocio

### Conceptos clave

| Término | Descripción |
|---|---|
| **Correos A** | Correos Gmail que el negocio controla al 100%. Son la base de las cuentas de streaming. |
| **C — Cuenta** | Cuenta completa de una plataforma, comprada a un proveedor. Tiene capacidad de 1 a 5 pantallas (perfiles). |
| **P — Pantalla** | Perfil individual dentro de una cuenta. Se vende a un cliente con un PIN de 4 dígitos. |
| **Antiguo** | Cuenta o pantalla que ya salió de circulación (estado: caída, vencida). |

### Flujo del negocio

```
Proveedor ──vende──> Cuenta (inventario) ──contiene──> Pantallas (1-5)
                            │                                │
                            │                          Cliente compra P (pantalla)
                            │
                     Cliente compra C (cuenta completa)
```

- Los **proveedores** venden cuentas completas al negocio.
- Los **clientes** pueden comprar **pantallas individuales** (con PIN) o **cuentas completas** (con contraseña).
- Cada pantalla tiene fechas de **inicio, cobro (+29 días) y corte (+30 días)**.
- Cada cuenta comprada tiene fecha de **compra y pago (+28 días)**.

---

## 🗄️ Esquema de Base de Datos

Motor: **MariaDB 12+** (MySQL compatible)

Base: `streaming_business`

### Tablas

```
streaming_business
├── platforms          ← Catálogo de plataformas (Netflix, Disney+...)
├── providers          ← Proveedores que venden cuentas
├── emails             ← Correos Gmail del negocio
├── customers          ← Clientes finales
├── accounts           ← Cuentas en inventario
├── screens            ← Pantallas vendidas a clientes
└── customer_accounts  ← Cuentas completas vendidas a clientes
```

### Relaciones

```
platforms  1──N accounts
providers  1──N accounts
providers  1──N emails
emails     1──N accounts
customers  1──N screens
customers  1──N customer_accounts
accounts   1──N screens
accounts   1──N customer_accounts
```

### Fechas calculadas (generated columns)

| Tabla | Campo | Cálculo |
|---|---|---|
| `accounts` | `fecha_pago` | `fecha_compra + 28 días` |
| `screens` | `fecha_cobro` | `fecha_inicio + 29 días` |
| `screens` | `fecha_corte` | `fecha_inicio + 30 días` |
| `customer_accounts` | `fecha_cobro` | `fecha_inicio + 29 días` |
| `customer_accounts` | `fecha_corte` | `fecha_inicio + 30 días` |

### Estados

| Tabla | Posibles valores |
|---|---|
| `accounts.status` | `activo`, `por_vencer`, `vencida`, `caida` |
| `screens.status` | `disponible`, `activo`, `por_vencer`, `vencida`, `caida` |
| `customer_accounts.status` | `activo`, `por_vencer`, `vencida`, `caida` |

---

## 🛠️ Stack Tecnológico

| Componente | Tecnología |
|---|---|
| **Backend** | Python 3.12+ / Django 5.x |
| **Base de datos** | MariaDB 12 |
| **ORM** | Django ORM (integrado) |
| **API** | Django REST Framework (DRF) |
| **Conector DB** | mysqlclient |
| **Autenticación** | DRF + TokenAuth / JWT (opcional) |
| **Entorno** | virtualenv + pip |

---

## 📁 Estructura de carpetas propuesta

```
backend-streaming/
├── manage.py
├── requirements.txt
├── .env
├── .gitignore
├── README.md
├── schema.sql                    ← DDL de la base
├── streaming_project/
│   ├── __init__.py
│   ├── settings.py
│   ├── urls.py
│   ├── wsgi.py
│   └── asgi.py
└── apps/
    ├── accounts/                 ← Gestión de cuentas (inventario)
    │   ├── models.py
    │   ├── serializers.py
    │   ├── views.py
    │   ├── urls.py
    │   └── admin.py
    ├── customers/                ← Clientes
    │   ├── models.py
    │   ├── serializers.py
    │   ├── views.py
    │   ├── urls.py
    │   └── admin.py
    ├── screens/                  ← Pantallas
    │   ├── models.py
    │   ├── serializers.py
    │   ├── views.py
    │   ├── urls.py
    │   └── admin.py
    └── providers/                ← Proveedores
        ├── models.py
        ├── serializers.py
        ├── views.py
        ├── urls.py
        └── admin.py
```

---

## 🧩 Modelos Django (resumen)

### `Platform`
- `name`: CharField(unique=True) — Netflix, Disney+...

### `Provider`
- `name`, `contact`, `phone`, `notes`

### `Email`
- `email` (unique), `password`, `verification_email`, `phone_number`
- `last_login`, `requires_validation`
- `owner_name`, `birth_date`, `gender`
- `provider` → FK Provider (nullable)
- `notes`, `is_active`

### `Customer`
- `name`, `phone`, `notes`

### `Account`
- `email` → FK Email (nullable)
- `platform` → FK Platform
- `provider` → FK Provider
- `max_screens`: IntegerField (1-5)
- `credentials`, `status` (CharField con choices)
- `purchase_price`, `fecha_compra`
- `fecha_pago`: no se almacena, se calcula vía propiedad o anotación
- `observaciones`, `notes`, `is_active`

### `Screen`
- `account` → FK Account
- `customer` → FK Customer (nullable)
- `pin` (CharField 4 dígitos), `profile_name`
- `status`, `fecha_inicio`
- `fecha_cobro`, `fecha_corte` → calculados
- `observaciones`, `notes`

### `CustomerAccount`
- `account` → FK Account
- `customer` → FK Customer
- `contraseña`, `profile_name`
- `status`, `fecha_inicio`
- `fecha_cobro`, `fecha_corte` → calculados
- `observaciones`

---

## 🌐 API Endpoints planeados

### Proveedores
| Método | Ruta | Acción |
|---|---|---|
| GET | `/api/providers/` | Listar proveedores |
| POST | `/api/providers/` | Crear proveedor |
| GET | `/api/providers/:id/` | Detalle proveedor |
| PUT | `/api/providers/:id/` | Actualizar |
| DELETE | `/api/providers/:id/` | Eliminar |

### Correos
| Método | Ruta | Acción |
|---|---|---|
| GET | `/api/emails/` | Listar correos |
| POST | `/api/emails/` | Crear |
| GET | `/api/emails/:id/` | Detalle |
| PUT | `/api/emails/:id/` | Actualizar |

### Cuentas (inventario)
| Método | Ruta | Acción |
|---|---|---|
| GET | `/api/accounts/` | Listar cuentas (filtrables por plataforma, estado, proveedor) |
| POST | `/api/accounts/` | Crear cuenta |
| GET | `/api/accounts/:id/` | Detalle con pantallas |
| PATCH | `/api/accounts/:id/status/` | Cambiar estado |

### Pantallas
| Método | Ruta | Acción |
|---|---|---|
| GET | `/api/screens/` | Listar (filtro: disponible, activa, cliente) |
| POST | `/api/screens/` | Asignar/crear pantalla |
| GET | `/api/screens/:id/` | Detalle |
| PATCH | `/api/screens/:id/status/` | Cambiar estado |

### Clientes
| Método | Ruta | Acción |
|---|---|---|
| GET | `/api/customers/` | Listar |
| POST | `/api/customers/` | Crear |
| GET | `/api/customers/:id/` | Detalle con sus compras |

### Dashboard / Consultas
| Método | Ruta | Acción |
|---|---|---|
| GET | `/api/dashboard/summary/` | Resumen: cuentas activas, caídas, por vencer |
| GET | `/api/dashboard/vencidas/` | Cuentas y pantallas por vencer/vencidas |

---

## 📐 Principios de diseño

1. **Fechas calculadas en Python**, no en DB — Django maneja la lógica con propiedades del modelo o anotaciones de queryset
2. **Validación de PIN** con `RegexValidator` (4 dígitos exactos)
3. **Estados manejados con `choices`** y señales para logging de cambios
4. **Admin de Django** registrado para todas las tablas (gestión rápida)
5. **Filtros en DRF** con `django-filter` para plataforma, estado, fechas
6. **Entorno configurable** via `.env` (usando `django-environ` o `python-decouple`)

---

## 🚀 Próximos pasos

1. ✅ Diseño de base de datos y migración inicial
2. ✅ Proyecto Django + apps creadas
3. Modelos con sus campos y validaciones
4. Serializers + ViewSets (CRUDs)
5. URLs y routers
6. Autenticación básica (Token o Session)
7. Panel admin personalizado
8. Endpoints de dashboard y consultas

---

## ⚙️ Instalación y configuración

```bash
# Clonar repo
git clone <url-del-repo>
cd backend-streaming

# Virtualenv
python -m venv venv
source venv/bin/activate

# Dependencias
pip install -r requirements.txt

# Variables de entorno (crear .env)
DB_NAME=streaming_business
DB_USER=root
DB_PASSWORD=<tu-password>
DB_HOST=localhost
DB_PORT=3306
SECRET_KEY=<generar-con-python-manage.py-shell-o-secrets>

# Migrar
python manage.py migrate

# Correr
python manage.py runserver
```
