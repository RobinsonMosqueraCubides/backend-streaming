# 🎬 Backend Streaming

Sistema de gestión para la compra y venta de cuentas de plataformas de streaming.

---

## 📋 Modelo de Negocio

### Los actores

**Proveedor** — Persona o entidad que vende cuentas completas de streaming. El negocio les compra cuentas de Netflix, Disney+, HBO Max, Star+ y Prime Video para luego revenderlas.

**Cliente** — Persona natural que compra ya sea una pantalla (perfil) o una cuenta completa.

**Correo A** — Correo Gmail que el negocio controla al 100%. Es la puerta de entrada a las cuentas de streaming. Algunos correos están asociados a un proveedor.

---

### Los productos

| Producto | Sigla | Qué es |
|---|---|---|
| **Cuenta** | **C** | Cuenta completa de una plataforma. Se compra a un proveedor y tiene capacidad para 1 a 5 pantallas (perfiles). |
| **Pantalla** | **P** | Perfil individual dentro de una cuenta. Tiene un PIN de 4 dígitos. Es lo que normalmente se vende al cliente final. |

---

### Cómo fluye el negocio

```
                    ┌──────────────┐
                    │  PROVEEDOR   │
                    └──────┬───────┘
                           │ vende
                    ┌──────▼───────┐
                    │   CUENTA     │ ← Se compra, se guarda en inventario
                    │  (1 a 5 P)   │
                    └──────┬───────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
     ┌────────▼────┐  ┌───▼────┐  ┌───▼────────┐
     │  PANTALLA   │  │  ...   │  │  PANTALLA   │
     │  (perfil)   │  │        │  │  (perfil)   │
     └──────┬──────┘  └────────┘  └──────┬──────┘
            │                            │
            │ se vende                   │ se vende
            │                            │
     ┌──────▼──────┐             ┌───────▼──────┐
     │  CLIENTE A  │             │  CLIENTE B   │
     │  (compra P) │             │  (compra P)  │
     └─────────────┘             └──────────────┘

     ──── SI EL CLIENTE COMPRA UNA CUENTA COMPLETA ────

     ┌──────────────┐         ┌───────────────┐
     │   CUENTA     │────────►│ CUENTA_CLIENTE│
     │  (inventario)│         │ (asignada a   │
     └──────────────┘         │  un cliente)  │
                              └───────┬───────┘
                                      │
                              ┌───────▼──────┐
                              │   CLIENTE    │
                              │ (compra C)   │
                              └──────────────┘
```

---

### Ciclo de vida de una cuenta

1. El **proveedor** vende una cuenta al negocio → entra al **inventario**
2. Se define su **capacidad** (1 a 5 pantallas) y sus **precios** (compra y venta)
3. Las pantallas se marcan como **disponibles**
4. Un cliente compra una pantalla → se le asigna, se genera un **PIN de 4 dígitos** y se activa con **fecha de inicio**
5. A partir de esa fecha se calculan **automáticamente** el cobro (+29 días) y el corte (+30 días)
6. El estado cambia según el ciclo: `disponible → activo → por vencer → vencida`

> Si el cliente compra una **cuenta completa** en vez de una pantalla, se le asigna directamente con una **contraseña** y el mismo esquema de fechas.

---

### Estados

Una cuenta o pantalla puede estar en estos estados:

| Estado | Significado |
|---|---|
| **disponible** | No se ha vendido aún (solo aplica a pantallas) |
| **activo** | Está funcionando, todo bien |
| **por vencer** | Próxima a vencer (próximos días) |
| **vencida** | Se pasó la fecha de corte |
| **caída** | Dejó de funcionar antes de tiempo (problema técnico) |

---

### Fechas clave

Toda venta (pantalla o cuenta) tiene tres fechas:

| Fecha | Cálculo inicial | Editable |
|---|---|---|
| **fecha_inicio** | La que se registre al vender | ✅ Sí |
| **fecha_cobro** | `fecha_inicio + 29 días` | ✅ Sí, se puede ajustar manualmente |
| **fecha_corte** | `fecha_inicio + 30 días` | ✅ Sí, se puede ajustar manualmente |
| **fecha_pago** (cuentas) | `fecha_compra + 28 días` | ✅ Sí, se puede ajustar manualmente |

Las fechas se **calculan automáticamente al crear el registro**, pero el usuario puede editarlas después si necesita ajustar fechas específicas (ej: el cliente pidió extensión, cayó en fin de semana, etc.).

---

### Precios

| Concepto | Dónde se guarda |
|---|---|
| **precio_compra** | En la cuenta (lo que pagamos al proveedor) |
| **precio_venta** | En la cuenta (precio de venta de la cuenta completa) |
| **precio_venta** | En cada pantalla (precio de venta del perfil individual) |
| **precio_venta** | En cuenta_cliente (precio de venta cuando se vende cuenta completa) |

---

## 🛠️ Stack

| Componente | Tecnología |
|---|---|
| Backend | Python 3 + Django 6 |
| API | Django REST Framework |
| Base de datos | MariaDB (MySQL) |
| Tests | pytest (103 tests) |

---

## 📦 Estructura del proyecto

```
backend-streaming/
├── manage.py
├── requirements.txt
├── .env
├── pytest.ini
├── conftest.py
├── streaming_project/        ← Configuración Django
│   ├── settings.py
│   ├── urls.py
│   └── ...
├── providers/                ← Proveedores y plataformas
├── emails/                   ← Correos Gmail
├── customers/                ← Clientes
├── accounts/                 ← Cuentas en inventario
├── screens/                  ← Pantallas vendidas
├── customer_accounts/        ← Cuentas vendidas a clientes
└── dashboard/                ← Endpoints de resumen
```

---

## 🌐 API endpoints

| Ruta | Descripción |
|---|---|
| `GET /api/providers/` | Lista de proveedores |
| `GET /api/platforms/` | Catálogo de plataformas |
| `GET /api/emails/` | Correos del negocio |
| `GET /api/customers/` | Clientes |
| `GET /api/customers/:id/purchases/` | Compras de un cliente (pantallas + cuentas) |
| `GET /api/accounts/` | Cuentas en inventario (filtrable por plataforma, estado) |
| `PATCH /api/accounts/:id/change-status/` | Cambiar estado de una cuenta |
| `GET /api/accounts/:id/screens/` | Pantallas de una cuenta |
| `GET /api/screens/` | Pantallas vendidas (filtrable por estado, cliente) |
| `PATCH /api/screens/:id/change-status/` | Cambiar estado de una pantalla |
| `GET /api/customer-accounts/` | Cuentas completas vendidas |
| `GET /api/dashboard/summary/` | Resumen del negocio |

---

## ⚙️ Para correr local

```bash
git clone https://github.com/RobinsonMosqueraCubides/backend-streaming.git
cd backend-streaming

python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

cp .env.example .env   # y editá las credenciales

python manage.py runserver
```

```bash
# Correr tests
pytest -v
```
