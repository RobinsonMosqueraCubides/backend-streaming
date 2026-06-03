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
    ('Netflix'), ('Disney+'), ('HBO Max'), ('Star+'), ('Prime Video'),
    ('Crunchyroll'), ('Directv Go'), ('Spotify'), ('ChatGPT'),
    ('Paramount+'), ('VIX'), ('YouTube Premium');

-- ============================================================
-- 2. PROVEEDORES (quienes venden las cuentas)
-- ============================================================
CREATE TABLE providers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    contact VARCHAR(255),
    phone VARCHAR(30),
    notes TEXT,
    observaciones TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO providers (name, phone) VALUES
    ('P SIR', '2222'),
    ('P Brayan', '2222'),
    ('P Charlies', '2222'),
    ('P Willian', '2222'),
    ('P Fenix', '2222'),
    ('P Varios', '2222'),
    ('P Adriana', '2222');

-- ============================================================
-- 3. CORREOS (Gmails que maneja el negocio)
--    Reemplazamos "dueño" por "provider_id" como FK
-- ============================================================
CREATE TABLE emails (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    password VARCHAR(255),
    verification_email VARCHAR(255),
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
-- 5. ORDENES (agrupa pantallas + cuentas vendidas a un cliente)
--    Un cliente puede comprar 1+N pantallas y/o cuentas en combo
-- ============================================================
CREATE TABLE orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    total DECIMAL(10,2),
    status ENUM('activo', 'por_vencer', 'vencida', 'caida') DEFAULT 'activo',
    fecha_inicio DATE,
    fecha_cobro DATE,
    fecha_corte DATE,
    observaciones TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);

-- ============================================================
-- 6. CUENTAS (inventario — compradas a proveedores)
-- ============================================================
CREATE TABLE accounts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email_id INT,
    platform_id INT NOT NULL,
    max_screens TINYINT NOT NULL DEFAULT 1,
    credentials VARCHAR(255),
    status ENUM('activo', 'por_vencer', 'vencida', 'caida') DEFAULT 'activo',
    purchase_price DECIMAL(10,2),
    fecha_compra DATE,
    fecha_pago DATE,
    fecha_corte DATE,
    observaciones TEXT,
    notes TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (email_id) REFERENCES emails(id) ON DELETE SET NULL,
    FOREIGN KEY (platform_id) REFERENCES platforms(id),
    CONSTRAINT chk_screens CHECK (max_screens BETWEEN 1 AND 5)
);

-- ============================================================
-- 7. PANTALLAS (perfiles vendidos a clientes)
-- ============================================================
CREATE TABLE screens (
    id INT AUTO_INCREMENT PRIMARY KEY,
    account_id INT NOT NULL,
    customer_id INT,                          -- quién la compró
    order_id INT,                             -- FK a orders (si es parte de un combo)
    pin CHAR(4) NOT NULL,
    precio_venta DECIMAL(10,2),
    profile_name VARCHAR(255),
    status ENUM('disponible', 'activo', 'por_vencer', 'vencida', 'caida') DEFAULT 'disponible',
    fecha_inicio DATE,
    fecha_cobro DATE,                          -- calculado al crear (inicio+29d), editable
    fecha_corte DATE,                          -- calculado al crear (inicio+30d), editable
    observaciones TEXT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE SET NULL,
    CONSTRAINT chk_pin CHECK (pin REGEXP '^[0-9]{4}$')
);

-- ============================================================
-- 8. CUENTAS_CLIENTE (cuentas completas vendidas a clientes)
--    Misma lógica que pantallas, pero con contraseña en vez de PIN
-- ============================================================
CREATE TABLE customer_accounts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    account_id INT NOT NULL,                  -- la cuenta del inventario que se vendió
    customer_id INT NOT NULL,                 -- a quién se le vendió
    order_id INT,                             -- FK a orders (si es parte de un combo)
    contraseña VARCHAR(255) NOT NULL,         -- en vez de PIN
    precio_venta DECIMAL(10,2),
    profile_name VARCHAR(255),
    status ENUM('activo', 'por_vencer', 'vencida', 'caida') DEFAULT 'activo',
    fecha_inicio DATE,
    fecha_cobro DATE,                          -- calculado al crear (inicio+29d), editable
    fecha_corte DATE,                          -- calculado al crear (inicio+30d), editable
    observaciones TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE SET NULL
);

-- ============================================================
-- EMAILS — extraídos del Excel (85 correos de 7 proveedores)
-- ============================================================

-- Proveedor: P SIR (id=1) — 3 correos
INSERT INTO emails (email, password, provider_id) VALUES
  ('crunchroll0020-fz0056@strampre77.com', 'castillos9871
bananas123', 1),
  ('hbo.71ca+9i6@gmail.com', 'e5f4kpmefa', 1),
  ('Vix77pre+dmor@gmail.com', 'duendes2521', 1);

-- Proveedor: P Brayan (id=2) — 6 correos
INSERT INTO emails (email, password, provider_id) VALUES
  ('fuuanse48256@worldstreaming.shop', 'max20200@@', 2),
  ('quindu@valltre34.click', 'nortett21@', 2),
  ('nikson873737@worldstreaming.shop', 'disney2020@', 2),
  ('poumax10010@worldstreaming.shop', 'tiendaworld12
Streaming2026', 2),
  ('theriamperro@gmail.com', 'Theriam14@', 2),
  ('lilian872552@worldstreaming.shop', 'disney2020@', 2);

-- Proveedor: P CHARLIES (id=3) — 11 correos
INSERT INTO emails (email, password, provider_id) VALUES
  ('ch311564+22@gmail.com', 'Max123456@', 3),
  ('rey.19.84c@gmail.com', 'BETTYLAFEA
999999@', 3),
  ('Je.ili2.0143@gmail.com', 'BETTYLAFEA
999999@', 3),
  ('dairo10@newaddr.com', 'BETTYLAFEA
999999@', 3),
  ('Ssh251521@gmail.com', 'Max202584#', 3),
  ('Luisusraez2772@gmail.com', '555555@', 3),
  ('za.ul49.51@gmail.com', '555555@', 3),
  ('der.1984c@gmail.com', '555555@', 3),
  ('xilen.a.89.8@gmail.com', 'CAFECONLECHE', 3),
  ('ihamdiaz568@gmail.com', 'CAFECONLECHE', 3),
  ('geileissatteroi-4218@yopmail.com', '333333@', 3);

-- Proveedor: P WILLIAM (id=4) — 21 correos
INSERT INTO emails (email, password, provider_id) VALUES
  ('netflow10@kikoshop.net', NULL, 4),
  ('tolidisney230@kikoshop.net', NULL, 4),
  ('netflixoriginal55@kikoshop.net', NULL, 4),
  ('moviplus4@kikoshop.net', NULL, 4),
  ('tucuentanetflix309@kikoshop.net', NULL, 4),
  ('moviplus9@kikoshop.net', NULL, 4),
  ('tolidisney211@kikoshop.net', NULL, 4),
  ('disneypremium25@kikoshop.net', NULL, 4),
  ('tuamazonetigo01@kikoshop.net', NULL, 4),
  ('tolidisney228@kikoshop.net', 'PREMIUM2026', 4),
  ('paramex1@kikoshop.net', 'premium2026', 4),
  ('disneypremium07@kikoshop.net', 'NUEVA2026', 4),
  ('disneyfeb2@kikoshop.net', 'CAROLINA90', 4),
  ('disneypremium171@kikoshop.net', 'NUEVA2026*', 4),
  ('tolidisney45@kikoshop.net', 'NUEVA2026@', 4),
  ('paramountetb3@kikoshop.net', 'calidad2026', 4),
  ('humberto2026@kikoshop.net', 'Mundial2026*', 4),
  ('martha2026ballesteros@kikoshop.net', 'Mundial2026@@', 4),
  ('jhon2026@kikoshop.net', 'Mundial2026*', 4),
  ('paramountetb1@kikoshop.net', NULL, 4),
  ('netflow2@kikoshop.net', NULL, 4);

-- Proveedor: P FENIX (id=5) — 5 correos
INSERT INTO emails (email, password, provider_id) VALUES
  ('y.lachkar@fenixis.co', 'Tablasx158*', 5),
  ('minerxxs118620@yarift.com', 'Tablasx158*', 5),
  ('btracy27@yarift.com', 'Tablasx158*', 5),
  ('eborahfac@yarift.com', 'Mistrs9*', 5),
  ('farhadakbari07@fenixis.co', 'anadil1', 5);

-- Proveedor: P VARIOS (id=6) — 25 correos
INSERT INTO emails (email, password, provider_id) VALUES
  ('streamingmodz+tussi@gmail.com', 'Santi2024*', 6),
  ('morenosilvajuan2@gmail.com', 'Santi2024*', 6),
  ('lucasgakvism@gmail.com', 'remogaray1899', 6),
  ('morenosilvajaime194@gmail.com', 'remogaray1899', 6),
  ('dia.naleonn63@santreamteo.com', 'amazon7686', 6),
  ('mendozasilvahellen@gmail.com', 'amazon7686', 6),
  ('mendozamorenomilena@gmail.com', 'Bugg67778@', 6),
  ('endersonmolinaneuque@gmail.com', 'Moncada892@@', 6),
  ('callista644ff@hotmail.com', 'Prime211@', 6),
  ('ovidiomorenosilva@gmail.com', 'Desayuno2892@', 6),
  ('robin.mosquera13@gmail.com', 'anime1234', 6),
  ('stremingflix001@gmail.com', 'MARGARITAP*
Desayuno2892@', 6),
  ('stremingflix002@gmail.com', 'MARGARITAP*', 6),
  ('agaray2107@gmail.com', NULL, 6),
  ('duarteandr@twoperfil.com', 'Sebas2022***', 6),
  ('paramountetb3@kikoshop.net', 'calidad2026', 6),
  ('julioadams377@gmail.com', 'Empres889axx', 6),
  ('sotomanu0273k+sds2@gmail.com', 'Libre8899ssxx', 6),
  ('humberto2026@kikoshop.net', 'Mundial2026*', 6),
  ('paramex1@kikoshop.net', 'premium2026', 6),
  ('martha2026ballesteros@kikoshop.net', 'Mundial2026@@', 6),
  ('jhon2026@kikoshop.net', 'Mundial2026*', 6),
  ('web.disneyplus+G0047@gmail.com', 'JT256S45L*', 6),
  ('wellian57@oneperfil.com', 'JT256S45L*', 6),
  ('nicolasalonso2510@gmail.com', 'YT', 6);

-- Proveedor: P ADRIANA (id=7) — 23 correos
INSERT INTO emails (email, password, provider_id) VALUES
  ('stremingflix009@gmail.com', NULL, 7),
  ('stremingflix024@gmail.com', NULL, 7),
  ('stremingflix025@gmail.com', NULL, 7),
  ('stremingflix001@gmail.com', NULL, 7),
  ('stremingflix010@gmail.com', 'ECOPITCH', 7),
  ('stremingflix031@gmail.com', 'FUTBOL', 7),
  ('stremingflix002@gmail.com', 'MARGARITAP*', 7),
  ('agaray2107@gmail.com', NULL, 7),
  ('stremingflix015@gmail.com', 'MARGARITAP', 7),
  ('robin.mosquera13@gmail.com', 'anime1234', 7),
  ('stremingflix019@gmail.com', NULL, 7),
  ('stremingflix016@gmail.com', 'CARTONCON', 7),
  ('agaraystore@gmail.com', NULL, 7),
  ('stremingflix020@gmail.com', 'SABRINA21', 7),
  ('stremingflix006@gmail.com', 'REVIEW2026', 7),
  ('stremingflix022@gmail.com', 'ATLASFIT', 7),
  ('stremingflix017@gmail.com', 'CARNITAR', 7),
  ('stremingflix021@gmail.com', NULL, 7),
  ('stremingflix011@gmail.com', 'BETTYLAFEA', 7),
  ('stremingflix004@gmail.com', 'PANICO', 7),
  ('stremingflix026@gmail.com', 'FRANCIA15', 7),
  ('stremingflix007@gmail.com', 'CARNITAR', 7),
  ('stremingflix005@gmail.com', 'CARNITAR', 7);

-- Total: 94 correos

-- ============================================================
-- ACCOUNTS — inventario extraído de hojas de proveedores
-- ============================================================

-- P SIR — 3 cuentas
INSERT INTO accounts (email_id, platform_id, purchase_price, status, is_active, observaciones) VALUES
  ((SELECT id FROM emails WHERE email = 'crunchroll0020-fz0056@strampre77.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Crunchyroll'), '5000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'hbo.71ca+9i6@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'HBO Max'), '7000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'Vix77pre+dmor@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'VIX'), '1666.666667', 'vencida', FALSE, NULL);

-- P Brayan — 4 cuentas
INSERT INTO accounts (email_id, platform_id, purchase_price, status, is_active, observaciones) VALUES
  ((SELECT id FROM emails WHERE email = 'fuuanse48256@worldstreaming.shop' LIMIT 1), (SELECT id FROM platforms WHERE name = 'HBO Max'), '4000.0', 'vencida', FALSE, NULL),
  ((SELECT id FROM emails WHERE email = 'quindu@valltre34.click' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Paramount+'), '4500.0', 'vencida', FALSE, 'PARAM,A'),
  ((SELECT id FROM emails WHERE email = 'poumax10010@worldstreaming.shop' LIMIT 1), (SELECT id FROM platforms WHERE name = 'HBO Max'), '4000.0', 'vencida', FALSE, NULL),
  ((SELECT id FROM emails WHERE email = 'theriamperro@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'YouTube Premium'), '4666.666667', 'vencida', FALSE, NULL);

-- P CHARLIES — 11 cuentas
INSERT INTO accounts (email_id, platform_id, purchase_price, status, is_active, observaciones) VALUES
  ((SELECT id FROM emails WHERE email = 'ch311564+22@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'HBO Max'), '7000.0', 'activo', TRUE, 'No ha preguntado y no la han cobrado'),
  ((SELECT id FROM emails WHERE email = 'rey.19.84c@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '32000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'Je.ili2.0143@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '32000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'dairo10@newaddr.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '32000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'Ssh251521@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'HBO Max'), '8000.0', 'activo', TRUE, 'No ha preguntado y no la han cobrado'),
  ((SELECT id FROM emails WHERE email = 'Luisusraez2772@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '32000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'za.ul49.51@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '32000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'der.1984c@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '32000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'xilen.a.89.8@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '32000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'ihamdiaz568@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '32000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'geileissatteroi-4218@yopmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '32000.0', 'vencida', FALSE, 'me debe 2 dias');

-- P WILLIAM — 21 cuentas
INSERT INTO accounts (email_id, platform_id, purchase_price, status, is_active, observaciones) VALUES
  ((SELECT id FROM emails WHERE email = 'netflow10@kikoshop.net' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Disney+'), '18000.0', 'activo', TRUE, '15/08/1998 HOMBRE'),
  ((SELECT id FROM emails WHERE email = 'tolidisney230@kikoshop.net' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Disney+'), '18000.0', 'activo', TRUE, '15/08/1998 HOMBRE'),
  ((SELECT id FROM emails WHERE email = 'netflixoriginal55@kikoshop.net' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '30000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'moviplus4@kikoshop.net' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Disney+'), '18000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'tucuentanetflix309@kikoshop.net' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '25000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'moviplus9@kikoshop.net' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Disney+'), '22000.0', 'activo', TRUE, '15/8/1998 hombre'),
  ((SELECT id FROM emails WHERE email = 'tolidisney211@kikoshop.net' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Disney+'), '22000.0', 'activo', TRUE, '15/8/1998 hombre'),
  ((SELECT id FROM emails WHERE email = 'disneypremium25@kikoshop.net' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Disney+'), '18000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'tuamazonetigo01@kikoshop.net' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Prime Video'), '8000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'tolidisney228@kikoshop.net' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Disney+'), '18000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'paramex1@kikoshop.net' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Paramount+'), '8000.0', 'activo', TRUE, 'Valor inesperado en vencimiento: 10000.0'),
  ((SELECT id FROM emails WHERE email = 'disneypremium07@kikoshop.net' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Disney+'), '18000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'disneyfeb2@kikoshop.net' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Disney+'), '18000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'disneypremium171@kikoshop.net' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Disney+'), '18000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'tolidisney45@kikoshop.net' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Disney+'), '18000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'paramountetb3@kikoshop.net' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Paramount+'), '8000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'humberto2026@kikoshop.net' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Directv Go'), '24000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'martha2026ballesteros@kikoshop.net' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Directv Go'), '24000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'jhon2026@kikoshop.net' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Directv Go'), '24000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'paramountetb1@kikoshop.net' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Paramount+'), '8000.0', 'activo', TRUE, 'no renovar | Valor inesperado en vencimiento: 10000.0'),
  ((SELECT id FROM emails WHERE email = 'netflow2@kikoshop.net' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Disney+'), '18000.0', 'activo', TRUE, '15/08/1998 HOMBRE');

-- P FENIX — 5 cuentas
INSERT INTO accounts (email_id, platform_id, purchase_price, status, is_active, observaciones) VALUES
  ((SELECT id FROM emails WHERE email = 'y.lachkar@fenixis.co' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '30000.0', 'vencida', FALSE, NULL),
  ((SELECT id FROM emails WHERE email = 'minerxxs118620@yarift.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '30000.0', 'vencida', FALSE, NULL),
  ((SELECT id FROM emails WHERE email = 'btracy27@yarift.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '30000.0', 'vencida', FALSE, NULL),
  ((SELECT id FROM emails WHERE email = 'eborahfac@yarift.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '30000.0', 'vencida', FALSE, NULL),
  ((SELECT id FROM emails WHERE email = 'farhadakbari07@fenixis.co' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '30000.0', 'activo', TRUE, 'no la cobaron parece gratis');

-- P VARIOS — 28 cuentas
INSERT INTO accounts (email_id, platform_id, purchase_price, status, is_active, observaciones) VALUES
  ((SELECT id FROM emails WHERE email = 'streamingmodz+tussi@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'HBO Max'), '10000.0', 'activo', TRUE, 'ModzStreaming  Proveedor'),
  ((SELECT id FROM emails WHERE email = 'morenosilvajuan2@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'HBO Max'), '10000.0', 'activo', TRUE, 'ModzStreaming  Proveedor'),
  ((SELECT id FROM emails WHERE email = 'lucasgakvism@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Prime Video'), '12000.0', 'activo', TRUE, 'ModzStreaming  Proveedor'),
  ((SELECT id FROM emails WHERE email = 'morenosilvajaime194@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Prime Video'), '12000.0', 'activo', TRUE, 'ModzStreaming  Proveedor'),
  ((SELECT id FROM emails WHERE email = 'dia.naleonn63@santreamteo.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Prime Video'), '13000.0', 'activo', TRUE, 'ModzStreaming  Proveedor'),
  ((SELECT id FROM emails WHERE email = 'mendozasilvahellen@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Prime Video'), '13000.0', 'activo', TRUE, 'ModzStreaming  Proveedor'),
  ((SELECT id FROM emails WHERE email = 'mendozamorenomilena@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Prime Video'), '12000.0', 'activo', TRUE, 'ModzStreaming  Proveedor'),
  ((SELECT id FROM emails WHERE email = 'endersonmolinaneuque@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Prime Video'), '12000.0', 'activo', TRUE, 'ModzStreaming  Proveedor'),
  ((SELECT id FROM emails WHERE email = 'callista644ff@hotmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Prime Video'), '3000.0', 'activo', TRUE, 'Elias Pizarro Proveedor Valencia StreamContraseña Hotmail:Prime211'),
  ((SELECT id FROM emails WHERE email = 'ovidiomorenosilva@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Prime Video'), '12000.0', 'activo', TRUE, 'ModzStreaming  Proveedor'),
  ((SELECT id FROM emails WHERE email = 'robin.mosquera13@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Crunchyroll'), NULL, 'vencida', FALSE, 'Adriana'),
  ((SELECT id FROM emails WHERE email = 'robin.mosquera13@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Crunchyroll'), NULL, 'activo', TRUE, 'Adriana'),
  ((SELECT id FROM emails WHERE email = 'robin.mosquera13@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Crunchyroll'), NULL, 'activo', TRUE, 'Adriana'),
  ((SELECT id FROM emails WHERE email = 'stremingflix001@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Spotify'), NULL, 'activo', TRUE, 'Adriana'),
  ((SELECT id FROM emails WHERE email = 'stremingflix002@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Spotify'), '10166.66667', 'activo', TRUE, 'Adriana'),
  ((SELECT id FROM emails WHERE email = 'agaray2107@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Spotify'), '10166.66667', 'activo', TRUE, 'Adriana'),
  ((SELECT id FROM emails WHERE email = 'robin.mosquera13@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Spotify'), '10166.66667', 'activo', TRUE, 'Adriana'),
  ((SELECT id FROM emails WHERE email = 'duarteandr@twoperfil.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'ChatGPT'), '20000.0', 'activo', TRUE, 'ModzStreaming  Proveedor'),
  ((SELECT id FROM emails WHERE email = 'paramountetb3@kikoshop.net' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Paramount+'), '4000.0', 'activo', TRUE, 'Paramount Wiliam'),
  ((SELECT id FROM emails WHERE email = 'paramountetb3@kikoshop.net' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Paramount+'), '4000.0', 'activo', TRUE, 'Paramount Wiliam'),
  ((SELECT id FROM emails WHERE email = 'julioadams377@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'HBO Max'), '10000.0', 'activo', TRUE, 'ModzStreaming  Proveedor'),
  ((SELECT id FROM emails WHERE email = 'sotomanu0273k+sds2@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'HBO Max'), '10000.0', 'activo', TRUE, 'ModzStreaming  Proveedor'),
  ((SELECT id FROM emails WHERE email = 'humberto2026@kikoshop.net' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Directv Go'), '24000.0', 'activo', TRUE, 'William'),
  ((SELECT id FROM emails WHERE email = 'paramex1@kikoshop.net' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Paramount+'), '8000.0', 'activo', TRUE, 'William'),
  ((SELECT id FROM emails WHERE email = 'martha2026ballesteros@kikoshop.net' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Directv Go'), '24000.0', 'activo', TRUE, 'William'),
  ((SELECT id FROM emails WHERE email = 'jhon2026@kikoshop.net' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Directv Go'), '24000.0', 'activo', TRUE, 'William'),
  ((SELECT id FROM emails WHERE email = 'web.disneyplus+G0047@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Disney+'), '20000.0', 'activo', TRUE, 'ModzStreaming  Proveedor'),
  ((SELECT id FROM emails WHERE email = 'wellian57@oneperfil.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Disney+'), '20000.0', 'activo', TRUE, 'ModzStreaming  Proveedor');

-- P ADRIANA — 23 cuentas
INSERT INTO accounts (email_id, platform_id, purchase_price, status, is_active, observaciones) VALUES
  ((SELECT id FROM emails WHERE email = 'stremingflix009@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '30000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'stremingflix024@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '20000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'stremingflix025@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '20000.0', 'activo', TRUE, 'cliente jodido'),
  ((SELECT id FROM emails WHERE email = 'stremingflix001@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '26900.0', 'activo', TRUE, 'TARJETA NU'),
  ((SELECT id FROM emails WHERE email = 'stremingflix010@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '20000.0', 'activo', TRUE, '2P'),
  ((SELECT id FROM emails WHERE email = 'stremingflix031@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '9900.0', 'activo', TRUE, 'ASOCIADO A NATALY'),
  ((SELECT id FROM emails WHERE email = 'stremingflix002@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Spotify'), NULL, 'activo', TRUE, 'Carrera 3W #8N-265, Piedecuesta, Santander'),
  ((SELECT id FROM emails WHERE email = 'stremingflix001@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Spotify'), NULL, 'activo', TRUE, 'Carrera 3W #8N-265, Piedecuesta, Santander'),
  ((SELECT id FROM emails WHERE email = 'agaray2107@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Spotify'), NULL, 'activo', TRUE, 'Carrera 3W #8N-265, Piedecuesta, Santander'),
  ((SELECT id FROM emails WHERE email = 'stremingflix015@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '20000.0', 'activo', TRUE, 'Cliente jodido'),
  ((SELECT id FROM emails WHERE email = 'robin.mosquera13@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Crunchyroll'), NULL, 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'stremingflix019@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '50000.0', 'por_vencer', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'stremingflix016@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '20000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'agaray2107@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '40000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'agaraystore@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '9900.0', 'por_vencer', TRUE, 'asociado a stremingflix019@gmail.com'),
  ((SELECT id FROM emails WHERE email = 'stremingflix020@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '20000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'stremingflix002@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '20000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'stremingflix006@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '20000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'stremingflix022@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '20000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'stremingflix017@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '20000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'stremingflix007@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '20000.0', 'vencida', FALSE, NULL),
  ((SELECT id FROM emails WHERE email = 'stremingflix005@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '20000.0', 'vencida', FALSE, NULL),
  ((SELECT id FROM emails WHERE email = 'stremingflix009@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'HBO Max'), '12000.0', 'activo', TRUE, 'TARJETA NU');

-- Total: 95 cuentas
