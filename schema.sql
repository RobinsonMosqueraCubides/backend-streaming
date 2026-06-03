-- ============================================================
-- SCHEMA V2 — Streaming Accounts Business
-- ============================================================

CREATE DATABASE IF NOT EXISTS streaming_business
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE streaming_business;

-- ============================================================
-- 1. PLATAFORMAS (catálogo)
-- ============================================================
CREATE TABLE platforms (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);

INSERT INTO platforms (name) VALUES
    ('Netflix'), ('Disney+'), ('HBO Max'), ('Star+'), ('Prime Video');

-- ============================================================
-- 2. PROVEEDORES (quienes venden las cuentas)
-- ============================================================
CREATE TABLE providers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    contact VARCHAR(255),
    phone VARCHAR(30),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 3. CORREOS (Gmails que maneja el negocio)
--    Reemplazamos "dueño" por "provider_id" como FK
-- ============================================================
CREATE TABLE emails (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255),
    verification_email VARCHAR(255),
    phone_number VARCHAR(30),
    last_login DATE,
    requires_validation BOOLEAN DEFAULT NULL,
    owner_name VARCHAR(255),
    birth_date DATE,
    gender VARCHAR(20),
    provider_id INT,                          -- ← FK al proveedor asociado
    notes TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (provider_id) REFERENCES providers(id) ON DELETE SET NULL
);

-- ============================================================
-- 4. CLIENTES (quienes compran)
-- ============================================================
CREATE TABLE customers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(30) NOT NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ============================================================
-- 5. CUENTAS (inventario — compradas a proveedores)
-- ============================================================
CREATE TABLE accounts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email_id INT,
    platform_id INT NOT NULL,
    provider_id INT,
    max_screens TINYINT NOT NULL DEFAULT 1,
    credentials VARCHAR(255),
    status ENUM('activo', 'por_vencer', 'vencida', 'caida') DEFAULT 'activo',
    purchase_price DECIMAL(10,2),
    precio_venta DECIMAL(10,2),
    fecha_compra DATE,
    -- fecha_pago se calcula sola: compra + 28 días
    fecha_pago DATE GENERATED ALWAYS AS (fecha_compra + INTERVAL 28 DAY) STORED,
    observaciones TEXT,
    notes TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (email_id) REFERENCES emails(id) ON DELETE SET NULL,
    FOREIGN KEY (platform_id) REFERENCES platforms(id),
    FOREIGN KEY (provider_id) REFERENCES providers(id) ON DELETE SET NULL,
    CONSTRAINT chk_screens CHECK (max_screens BETWEEN 1 AND 5)
);

-- ============================================================
-- 6. PANTALLAS (perfiles vendidos a clientes)
-- ============================================================
CREATE TABLE screens (
    id INT AUTO_INCREMENT PRIMARY KEY,
    account_id INT NOT NULL,
    customer_id INT,                          -- quién la compró
    pin CHAR(4) NOT NULL,
    precio_venta DECIMAL(10,2),
    profile_name VARCHAR(255),
    status ENUM('disponible', 'activo', 'por_vencer', 'vencida', 'caida') DEFAULT 'disponible',
    fecha_inicio DATE,
    -- Se calculan solas desde fecha_inicio
    fecha_cobro DATE GENERATED ALWAYS AS (fecha_inicio + INTERVAL 29 DAY) STORED,
    fecha_corte DATE GENERATED ALWAYS AS (fecha_inicio + INTERVAL 30 DAY) STORED,
    observaciones TEXT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL,
    CONSTRAINT chk_pin CHECK (pin REGEXP '^[0-9]{4}$')
);

-- ============================================================
-- 7. CUENTAS_CLIENTE (cuentas completas vendidas a clientes)
--    Misma lógica que pantallas, pero con contraseña en vez de PIN
-- ============================================================
CREATE TABLE customer_accounts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    account_id INT NOT NULL,                  -- la cuenta del inventario que se vendió
    customer_id INT NOT NULL,                 -- a quién se le vendió
    contraseña VARCHAR(255) NOT NULL,         -- en vez de PIN
    precio_venta DECIMAL(10,2),
    profile_name VARCHAR(255),
    status ENUM('activo', 'por_vencer', 'vencida', 'caida') DEFAULT 'activo',
    fecha_inicio DATE,
    fecha_cobro DATE GENERATED ALWAYS AS (fecha_inicio + INTERVAL 29 DAY) STORED,
    fecha_corte DATE GENERATED ALWAYS AS (fecha_inicio + INTERVAL 30 DAY) STORED,
    observaciones TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);
