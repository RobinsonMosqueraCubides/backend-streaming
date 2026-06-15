"""
conftest.py â€” Fixtures globales para los tests del backend streaming.

Estrategia: override de django_db_setup para crear las tablas manualmente
(visto que todos los modelos tienen managed=False).
"""
import pytest
import tempfile
import os
from pathlib import Path


# â”€â”€â”€ Session-scoped DB setup (corre antes que pytest-django toque la DB) â”€â”€â”€â”€â”€â”€

@pytest.fixture(scope="session")
def django_db_setup(django_db_blocker):
    """
    Override del setup por defecto de pytest-django.
    Crea las 7 tablas en un archivo SQLite temporal (no :memory: para que persistan
    durante la session de tests).
    """
    from django.db import connection

    with django_db_blocker.unblock():
        with connection.cursor() as cur:
            # Eliminar tablas si ya existÃ­an (re-run)
            for table in [
                "provider_warranty_claims", "warranty_claims", "status_log", "cobro_estado",
                "screens", "customer_accounts", "orders", "accounts",
                "emails", "customers", "providers", "platforms",
            ]:
                cur.execute(f"DROP TABLE IF EXISTS {table}")

            cur.execute("""
                CREATE TABLE platforms (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name VARCHAR(50) UNIQUE NOT NULL
                )
            """)
            cur.execute("""
                CREATE TABLE providers (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name VARCHAR(255) NOT NULL,
                    contact VARCHAR(255),
                    phone VARCHAR(30),
                    notes TEXT,
                    observaciones TEXT,
                    created_at DATETIME
                )
            """)
            cur.execute("""
                CREATE TABLE emails (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    email VARCHAR(255) UNIQUE NOT NULL,
                    password VARCHAR(255),
                    verification_email VARCHAR(255),
                    last_login DATE,
                    requires_validation BOOL,
                    owner_name VARCHAR(255),
                    birth_date DATE,
                    gender VARCHAR(20),
                    provider_id INTEGER,
                    notes TEXT,
                    is_active BOOL DEFAULT 1,
                    created_at DATETIME,
                    updated_at DATETIME,
                    FOREIGN KEY (provider_id) REFERENCES providers(id)
                )
            """)
            cur.execute("""
                CREATE TABLE customers (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name VARCHAR(255) NOT NULL,
                    phone VARCHAR(30),
                    notes TEXT,
                    created_at DATETIME,
                    updated_at DATETIME
                )
            """)
            cur.execute("""
                CREATE TABLE accounts (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    email_id INTEGER,
                    platform_id INTEGER NOT NULL,
                    max_screens INTEGER DEFAULT 1,
                    credentials VARCHAR(255),
                    status VARCHAR(10) DEFAULT 'activo',
                    purchase_price DECIMAL(10,2),
                    fecha_compra DATE,
                    fecha_pago DATE,
                    fecha_corte DATE,
                    observaciones TEXT,
                    notes TEXT,
                    is_active BOOL DEFAULT 1,
                    created_at DATETIME,
                    updated_at DATETIME,
                    FOREIGN KEY (email_id) REFERENCES emails(id),
                    FOREIGN KEY (platform_id) REFERENCES platforms(id)
                )
            """)
            cur.execute("""
                CREATE TABLE orders (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    customer_id INTEGER NOT NULL,
                    total DECIMAL(10,2),
                    status VARCHAR(10) DEFAULT 'activo',
                    fecha_inicio DATE,
                    fecha_cobro DATE,
                    fecha_corte DATE,
                    observaciones TEXT,
                    created_at DATETIME,
                    updated_at DATETIME,
                    FOREIGN KEY (customer_id) REFERENCES customers(id)
                )
            """)
            cur.execute("""
                CREATE TABLE screens (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    account_id INTEGER NOT NULL,
                    customer_id INTEGER,
                    order_id INTEGER,
                    pin VARCHAR(4) NOT NULL,
                    precio_venta DECIMAL(10,2),
                    profile_name VARCHAR(255),
                    status VARCHAR(10) DEFAULT 'disponible',
                    fecha_inicio DATE,
                    fecha_cobro DATE,
                    fecha_corte DATE,
                    observaciones TEXT,
                    notes TEXT,
                    created_at DATETIME,
                    updated_at DATETIME,
                    FOREIGN KEY (account_id) REFERENCES accounts(id),
                    FOREIGN KEY (customer_id) REFERENCES customers(id),
                    FOREIGN KEY (order_id) REFERENCES orders(id)
                )
            """)
            cur.execute("""
                CREATE TABLE customer_accounts (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    account_id INTEGER NOT NULL,
                    customer_id INTEGER NOT NULL,
                    order_id INTEGER,
                    contrasena VARCHAR(255) NOT NULL,
                    precio_venta DECIMAL(10,2),
                    profile_name VARCHAR(255),
                    status VARCHAR(10) DEFAULT 'activo',
                    fecha_inicio DATE,
                    fecha_cobro DATE,
                    fecha_corte DATE,
                    observaciones TEXT,
                    created_at DATETIME,
                    updated_at DATETIME,
                    FOREIGN KEY (account_id) REFERENCES accounts(id),
                    FOREIGN KEY (customer_id) REFERENCES customers(id),
                    FOREIGN KEY (order_id) REFERENCES orders(id)
                )
            """)
            cur.execute("""
                CREATE TABLE cobro_estado (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    order_id INTEGER NOT NULL UNIQUE,
                    aviso_enviado BOOL DEFAULT 0,
                    notificacion_enviada BOOL DEFAULT 0,
                    corte_enviado BOOL DEFAULT 0,
                    created_at DATETIME,
                    updated_at DATETIME,
                    FOREIGN KEY (order_id) REFERENCES orders(id)
                )
            """)
            cur.execute("""
                CREATE TABLE status_log (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    model_name VARCHAR(50) NOT NULL,
                    object_id INTEGER NOT NULL,
                    old_status VARCHAR(20),
                    new_status VARCHAR(20) NOT NULL,
                    changed_at DATETIME
                )
            """)
            cur.execute("""
                CREATE TABLE warranty_claims (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    order_id INTEGER NOT NULL,
                    original_screen_id INTEGER,
                    original_customer_account_id INTEGER,
                    replacement_screen_id INTEGER,
                    replacement_customer_account_id INTEGER,
                    reason TEXT,
                    status VARCHAR(10) DEFAULT 'abierta',
                    created_at DATETIME,
                    resolved_at DATETIME,
                    FOREIGN KEY (order_id) REFERENCES orders(id),
                    FOREIGN KEY (original_screen_id) REFERENCES screens(id),
                    FOREIGN KEY (original_customer_account_id) REFERENCES customer_accounts(id),
                    FOREIGN KEY (replacement_screen_id) REFERENCES screens(id),
                    FOREIGN KEY (replacement_customer_account_id) REFERENCES customer_accounts(id)
                )
            """)
            cur.execute("""
                CREATE TABLE provider_warranty_claims (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    account_id INTEGER NOT NULL,
                    provider_id INTEGER NOT NULL,
                    claim_type VARCHAR(20) NOT NULL,
                    fecha_reclamo DATE NOT NULL,
                    purchase_price DECIMAL(10,2) NOT NULL,
                    fecha_corte DATE NOT NULL,
                    remaining_days INTEGER NOT NULL,
                    calculated_credit DECIMAL(10,2) DEFAULT 0.00,
                    new_credentials VARCHAR(255),
                    replacement_account_id INTEGER,
                    notes TEXT,
                    created_at DATETIME,
                    FOREIGN KEY (account_id) REFERENCES accounts(id),
                    FOREIGN KEY (provider_id) REFERENCES providers(id),
                    FOREIGN KEY (replacement_account_id) REFERENCES accounts(id)
                )
            """)


# â”€â”€â”€ db marker: requerido por pytest-django para permitir acceso a la DB â”€â”€â”€â”€â”€â”€â”€â”€

@pytest.fixture
def db(django_db_setup, django_db_blocker):
    """Limpia datos entre tests sin recrear el esquema manual."""
    from django.db import connection

    with django_db_blocker.unblock():
        with connection.cursor() as cur:
            for table in [
                "provider_warranty_claims", "warranty_claims", "status_log", "cobro_estado",
                "screens", "customer_accounts", "orders", "accounts",
                "emails", "customers", "providers", "platforms",
            ]:
                cur.execute(f"DELETE FROM {table}")


# â”€â”€â”€ api_client fixture â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

@pytest.fixture
def api_client(db):
    """Client de API REST (sin auth)."""
    from rest_framework.test import APIClient
    return APIClient()


# â”€â”€â”€ Data fixtures â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

@pytest.fixture
def platform(db):
    """Plataforma de prueba: Netflix."""
    from django.db import connection
    with connection.cursor() as cur:
        cur.execute("INSERT INTO platforms (name) VALUES ('Netflix')")
        cur.execute("SELECT last_insert_rowid()")
        return cur.fetchone()[0]


@pytest.fixture
def platform_disney(db):
    """Plataforma de prueba: Disney+."""
    from django.db import connection
    with connection.cursor() as cur:
        cur.execute("INSERT INTO platforms (name) VALUES ('Disney+')")
        cur.execute("SELECT last_insert_rowid()")
        return cur.fetchone()[0]


@pytest.fixture
def provider(db):
    """Proveedor de prueba."""
    from django.db import connection
    with connection.cursor() as cur:
        cur.execute(
            "INSERT INTO providers (name, contact, phone) VALUES ('Proveedor Test', 'test@email.com', '3001234567')"
        )
        cur.execute("SELECT last_insert_rowid()")
        return cur.fetchone()[0]


@pytest.fixture
def provider_2(db):
    """Segundo proveedor."""
    from django.db import connection
    with connection.cursor() as cur:
        cur.execute("INSERT INTO providers (name) VALUES ('Otro Proveedor')")
        cur.execute("SELECT last_insert_rowid()")
        return cur.fetchone()[0]


@pytest.fixture
def email_obj(db, provider):
    """Email de prueba."""
    from django.db import connection
    with connection.cursor() as cur:
        cur.execute(
            "INSERT INTO emails (email, password, provider_id, is_active) "
            "VALUES ('test@gmail.com', 'pass123', %s, 1)",
            [provider],
        )
        cur.execute("SELECT last_insert_rowid()")
        return cur.fetchone()[0]


@pytest.fixture
def account(db, platform, provider, email_obj):
    """Cuenta de prueba con fecha_compra=2026-05-01, 4 pantallas, status=activo."""
    from django.db import connection
    with connection.cursor() as cur:
        cur.execute(
            "INSERT INTO accounts (email_id, platform_id, max_screens, "
            "credentials, status, fecha_compra, fecha_pago, is_active) "
            "VALUES (%s, %s, 4, 'user:pass', 'activo', '2026-05-01', '2026-05-29', 1)",
            [email_obj, platform],
        )
        cur.execute("SELECT last_insert_rowid()")
        return cur.fetchone()[0]


@pytest.fixture
def account_por_vencer(db, platform, provider):
    """Cuenta con status=por_vencer para tests de dashboard."""
    from django.db import connection
    with connection.cursor() as cur:
        cur.execute(
            "INSERT INTO accounts (platform_id, max_screens, status, is_active) "
            "VALUES (%s, 2, 'por_vencer', 1)",
            [platform],
        )
        cur.execute("SELECT last_insert_rowid()")
        return cur.fetchone()[0]


@pytest.fixture
def customer(db):
    """Cliente de prueba."""
    from django.db import connection
    with connection.cursor() as cur:
        cur.execute(
            "INSERT INTO customers (name, phone) VALUES ('Cliente Test', '3112223344')"
        )
        cur.execute("SELECT last_insert_rowid()")
        return cur.fetchone()[0]


@pytest.fixture
def customer_2(db):
    """Segundo cliente."""
    from django.db import connection
    with connection.cursor() as cur:
        cur.execute(
            "INSERT INTO customers (name, phone) VALUES ('Otro Cliente', '3225556677')"
        )
        cur.execute("SELECT last_insert_rowid()")
        return cur.fetchone()[0]


@pytest.fixture
def screen(db, account, customer):
    """Pantalla de prueba con fecha_inicio=2026-05-01, status=activo."""
    from django.db import connection
    with connection.cursor() as cur:
        cur.execute(
            "INSERT INTO screens (account_id, customer_id, pin, profile_name, status, fecha_inicio, fecha_cobro, fecha_corte) "
            "VALUES (%s, %s, '1234', 'Perfil 1', 'activo', '2026-05-01', '2026-05-30', '2026-05-31')",
            [account, customer],
        )
        cur.execute("SELECT last_insert_rowid()")
        return cur.fetchone()[0]


@pytest.fixture
def screen_disponible(db, account):
    """Pantalla con status=disponible."""
    from django.db import connection
    with connection.cursor() as cur:
        cur.execute(
            "INSERT INTO screens (account_id, pin, status) VALUES (%s, '5678', 'disponible')",
            [account],
        )
        cur.execute("SELECT last_insert_rowid()")
        return cur.fetchone()[0]


@pytest.fixture
def customer_account(db, account, customer):
    """Cuenta de cliente con fecha_inicio=2026-05-01, status=activo."""
    from django.db import connection
    with connection.cursor() as cur:
        cur.execute(
            "INSERT INTO customer_accounts (account_id, customer_id, contrasena, profile_name, status, fecha_inicio, fecha_cobro, fecha_corte) "
            "VALUES (%s, %s, 'secret123', 'Perfil Principal', 'activo', '2026-05-01', '2026-05-30', '2026-05-31')",
            [account, customer],
        )
        cur.execute("SELECT last_insert_rowid()")
        return cur.fetchone()[0]
