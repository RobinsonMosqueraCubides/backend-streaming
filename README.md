# 🎬 Backend Streaming

Sistema de gestión para la compra y venta de cuentas de plataformas de streaming.

---

## 📋 Modelo de Negocio

### Los actores

| Actor | Descripción |
|---|---|
| **Proveedor** | Vende cuentas completas al negocio. Hay 7: P SIR, P Brayan, P Charlies, P Willian, P Fenix, P Varios, P Adriana |
| **Cliente** | Persona que compra pantallas, cuentas, o combos de ambos |
| **Correo** | Gmail que el negocio controla. Cada correo está asociado a un proveedor |

---

### Los productos

| Producto | Qué es |
|---|---|
| **Cuenta** (Account) | Cuenta completa en inventario, comprada a un proveedor. Tiene capacidad de 1 a 5 pantallas. |
| **Pantalla** (Screen) | Perfil individual dentro de una cuenta, vendido a un cliente. Tiene PIN de 4 dígitos. |
| **Cuenta de Cliente** (CustomerAccount) | Cuenta completa vendida directamente a un cliente. |

---

### Órdenes y Combos

Un cliente puede comprar:

| Tipo | Cómo se modela |
|---|---|
| **1 pantalla sola** | `orders` (1) → `screens` (1) |
| **1 cuenta completa** | `orders` (1) → `customer_accounts` (1) |
| **Combo** (ej: Netflix + Disney + HBO) | `orders` (1) → `customer_accounts` (Netflix) + `screens` (Disney, HBO, etc.) |

Cada orden pertenece a un cliente y agrupa todos los items de una misma venta.

---

### Plataformas

| ID | Plataforma |
|---|---|
| 1 | Netflix |
| 2 | Disney+ |
| 3 | HBO Max |
| 4 | Star+ |
| 5 | Prime Video |
| 6 | Crunchyroll |
| 7 | Directv Go |
| 8 | Spotify |
| 9 | ChatGPT |
| 10 | Paramount+ |
| 11 | VIX |
| 12 | YouTube Premium |

---

### Ciclo de vida

1. **Proveedor** vende una cuenta → entra al **inventario** (`accounts`)
2. Se define su **capacidad** (max_screens, 1-5) y **precio de compra**
3. Un **cliente** compra → se crea una **orden** (`orders`) que agrupa los items
4. Si es pantalla → `screens` con PIN de 4 dígitos, hereda fechas
5. Si es cuenta completa → `customer_accounts` con contraseña, hereda fechas
6. El estado fluye: `activo → por_vencer → vencida` (o `caida`)

---

### Estados

| Estado | Significado |
|---|---|
| `disponible` | No se ha vendido aún (solo pantallas) |
| `activo` | Funcionando correctamente |
| `por_vencer` | Próximo a vencer |
| `vencida` | Pasó la fecha de corte |
| `caida` | Dejó de funcionar antes de tiempo |

---

### Fechas

| Campo | Dónde | Auto-cálculo | Editable |
|---|---|---|---|
| `fecha_compra` | accounts | Manual | ✅ |
| `fecha_pago` | accounts | `fecha_compra + 28d` | ✅ |
| `fecha_corte` | accounts, screens, customer_accounts | `fecha_inicio + 30d` | ✅ |
| `fecha_inicio` | orders, screens, customer_accounts | Manual | ✅ |
| `fecha_cobro` | orders, screens, customer_accounts | `fecha_inicio + 29d` | ✅ |

---

## 🛠️ Stack

| Componente | Tecnología |
|---|---|
| Backend | Python 3 + Django 6 |
| API | Django REST Framework + drf-spectacular (OpenAPI) |
| Base de datos | MariaDB 10+ |
| Schema | SQL gestionado externamente (`managed = False`) |

---

## 📦 Estructura

```
backend-streaming/
├── manage.py
├── schema.sql               ← Schema y datos iniciales
├── requirements.txt
├── .env
├── streaming_project/       ← Configuración Django
├── providers/               ← Platform + Provider
├── emails/                  ← Gmails del negocio
├── customers/               ← Clientes
├── accounts/                ← Cuentas en inventario
├── screens/                 ← Pantallas vendidas
├── customer_accounts/       ← Cuentas completas vendidas
├── orders/                  ← Órdenes (agrupa items de una venta)
├── dashboard/               ← Endpoints financieros
├── status_log/              ← Registro de cambios de estado
└── docs/                    ← Documentación
```

---

## 🌐 API Endpoints

### CRUD

| Método | Ruta | Descripción |
|---|---|---|
| `GET/POST` | `/api/platforms/` | Catálogo de plataformas |
| `GET/POST/PUT/DELETE` | `/api/providers/` | Proveedores |
| `GET/POST/PUT/DELETE` | `/api/emails/` | Correos |
| `GET/POST/PUT/DELETE` | `/api/customers/` | Clientes |
| `GET/POST/PUT/DELETE` | `/api/accounts/` | Cuentas (filtrable: status, platform, is_active) |
| `GET/POST/PUT/DELETE` | `/api/screens/` | Pantallas (filtrable: status, account, customer) |
| `GET/POST/PUT/DELETE` | `/api/customer_accounts/` | Cuentas de clientes |
| `GET/POST/PUT/DELETE` | `/api/orders/` | Órdenes (incluye items anidados) |

### Acciones

| Método | Ruta | Descripción |
|---|---|---|
| `PATCH` | `/api/accounts/:id/change_status/` | Cambiar estado de cuenta |
| `PATCH` | `/api/screens/:id/change_status/` | Cambiar estado de pantalla |
| `GET` | `/api/accounts/:id/screens/` | Pantallas de una cuenta |

### Dashboard Financiero

| Método | Ruta | Descripción |
|---|---|---|
| `GET` | `/api/dashboard/resumen/` | Ingresos, egresos, balance, conteos |
| `GET` | `/api/dashboard/ingresos/plataforma/` | Ingresos por plataforma |
| `GET` | `/api/dashboard/ingresos/proveedor/` | Ingresos por proveedor |
| `GET` | `/api/dashboard/ingresos/cliente/` | Ingresos por cliente |
| `GET` | `/api/dashboard/egresos/proveedor/` | Egresos (compras) por proveedor |
| `GET` | `/api/dashboard/egresos/plataforma/` | Egresos por plataforma |

### Docs

| Método | Ruta | Descripción |
|---|---|---|
| `GET` | `/api/docs/` | Swagger UI |
| `GET` | `/api/schema/` | OpenAPI schema |

---

## ⚙️ Setup

```bash
git clone https://github.com/RobinsonMosqueraCubides/backend-streaming.git
cd backend-streaming

python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Configurar .env
echo "DB_NAME=streaming_business
DB_USER=root
DB_PASSWORD=***
DB_HOST=localhost
DB_PORT=3306
SECRET_KEY=django-insecure-dev-key
DEBUG=True" > .env

# Cargar schema
mysql -u root -p < schema.sql

# Migrar y correr
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```
