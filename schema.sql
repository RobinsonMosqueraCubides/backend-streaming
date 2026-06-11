-- ============================================================
-- SCHEMA V2 â€” Streaming Accounts Business
-- ============================================================

DROP DATABASE IF EXISTS streaming_business;
CREATE DATABASE IF NOT EXISTS streaming_business
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE streaming_business;

-- ============================================================
-- 1. PLATAFORMAS (catÃ¡logo)
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
--    Reemplazamos "dueÃ±o" por "provider_id" como FK
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
    provider_id INT,                          -- â† FK al proveedor asociado
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
    status ENUM('activo', 'por_cobrar', 'por_vencer', 'por_cortar', 'vencida', 'caida') DEFAULT 'activo',
    fecha_inicio DATE,
    fecha_cobro DATE,
    fecha_corte DATE,
    observaciones TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);

-- ============================================================
-- 6. CUENTAS (inventario â€” compradas a proveedores)
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
    customer_id INT,                          -- quiÃ©n la comprÃ³
    order_id INT,                             -- FK a orders (si es parte de un combo)
    pin CHAR(4) DEFAULT NULL,
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
--    Misma lÃ³gica que pantallas, pero con contrasena en vez de PIN
-- ============================================================
CREATE TABLE customer_accounts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    account_id INT NOT NULL,                  -- la cuenta del inventario que se vendiÃ³
    customer_id INT NOT NULL,                 -- a quiÃ©n se le vendiÃ³
    order_id INT,                             -- FK a orders (si es parte de un combo)
    contrasena VARCHAR(255) NOT NULL,         -- en vez de PIN
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
-- 9. COBRO_ESTADO (tracking de envÃ­os de WhatsApp)
-- ============================================================
CREATE TABLE cobro_estado (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL UNIQUE,
    aviso_enviado BOOLEAN DEFAULT FALSE,
    notificacion_enviada BOOLEAN DEFAULT FALSE,
    corte_enviado BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
);

-- ============================================================
-- 10. STATUS_LOG (historial de cambios de estado)
-- ============================================================
CREATE TABLE status_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    model_name VARCHAR(50) NOT NULL,
    object_id INT NOT NULL,
    old_status VARCHAR(20),
    new_status VARCHAR(20) NOT NULL,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 11. WARRANTY_CLAIMS (garantias y reemplazos iniciales)
-- ============================================================
CREATE TABLE warranty_claims (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    original_screen_id INT,
    original_customer_account_id INT,
    replacement_screen_id INT,
    replacement_customer_account_id INT,
    reason TEXT,
    status ENUM('abierta', 'resuelta', 'rechazada') DEFAULT 'abierta',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (original_screen_id) REFERENCES screens(id) ON DELETE SET NULL,
    FOREIGN KEY (original_customer_account_id) REFERENCES customer_accounts(id) ON DELETE SET NULL,
    FOREIGN KEY (replacement_screen_id) REFERENCES screens(id) ON DELETE SET NULL,
    FOREIGN KEY (replacement_customer_account_id) REFERENCES customer_accounts(id) ON DELETE SET NULL
);

-- ============================================================
-- EMAILS â€” extraÃ­dos del Excel (85 correos de 7 proveedores)
-- ============================================================

-- Proveedor: P SIR (id=1) â€” 3 correos
INSERT INTO emails (email, password, provider_id) VALUES
  ('crunchroll0020-fz0056@strampre77.com', 'bananas123', 1),
  ('hbo.71ca+9i6@gmail.com', 'e5f4kpmefa', 1),
  ('Vix77pre+dmor@gmail.com', 'duendes2521', 1);

-- Proveedor: P Brayan (id=2) â€” 6 correos
INSERT INTO emails (email, password, provider_id) VALUES
  ('fuuanse48256@worldstreaming.shop', 'max20200@@', 2),
  ('quindu@valltre34.click', 'nortett21@', 2),
  ('nikson873737@worldstreaming.shop', 'disney2020@', 2),
  ('poumax10010@worldstreaming.shop', 'Streaming2026', 2),
  ('theriamperro@gmail.com', 'Theriam14@', 2),
  ('lilian872552@worldstreaming.shop', 'disney2020@', 2);

-- Proveedor: P CHARLIES (id=3) â€” 11 correos
INSERT INTO emails (email, password, provider_id) VALUES
  ('ch311564+22@gmail.com', 'Max123456@', 3),
  ('rey.19.84c@gmail.com', '999999@', 3),
  ('dairo10@newaddr.com', '888888@', 3),
  ('dairo10@newaddr.com', '999999@', 3),
  ('Ssh251521@gmail.com', 'Max202584#', 3),
  ('Luisusraez2772@gmail.com', '555555@', 3),
  ('za.ul49.51@gmail.com', '555555@', 3),
  ('der.1984c@gmail.com', '555555@', 3),
  ('xilen.a.89.8@gmail.com', 'CAFECONLECHE', 3),
  ('ihamdiaz568@gmail.com', 'CAFECONLECHE', 3),
  ('geileissatteroi-4218@yopmail.com', '333333@', 3);

-- Proveedor: P WILLIAM (id=4) â€” 21 correos
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

-- Proveedor: P FENIX (id=5) â€” 5 correos
INSERT INTO emails (email, password, provider_id) VALUES
  ('y.lachkar@fenixis.co', 'Tablasx158*', 5),
  ('minerxxs118620@yarift.com', 'Tablasx158*', 5),
  ('btracy27@yarift.com', 'Tablasx158*', 5),
  ('eborahfac@yarift.com', 'Mistrs9*', 5),
  ('farhadakbari07@fenixis.co', 'anadil1', 5);

-- Proveedor: P VARIOS (id=6) â€” 21 correos (4 duplicados con P ADRIANA eliminados)
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
  ('nicolasalonso2510@gmail.com', 'YT', 6),
  ('BRUMA286@servineira.com', NULL, 6);

-- Proveedor: P ADRIANA (id=7) â€” 23 correos
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

-- Total: 91 correos

-- ============================================================
-- ACCOUNTS â€” inventario extraÃ­do de hojas de proveedores
-- ============================================================

-- P SIR â€” 3 cuentas
INSERT INTO accounts (email_id, platform_id, purchase_price, status, is_active, observaciones) VALUES
  ((SELECT id FROM emails WHERE email = 'crunchroll0020-fz0056@strampre77.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Crunchyroll'), '5000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'hbo.71ca+9i6@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'HBO Max'), '7000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'Vix77pre+dmor@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'VIX'), '1666.666667', 'vencida', FALSE, NULL);

-- P Brayan â€” 4 cuentas
INSERT INTO accounts (email_id, platform_id, purchase_price, status, is_active, observaciones) VALUES
  ((SELECT id FROM emails WHERE email = 'fuuanse48256@worldstreaming.shop' LIMIT 1), (SELECT id FROM platforms WHERE name = 'HBO Max'), '4000.0', 'vencida', FALSE, NULL),
  ((SELECT id FROM emails WHERE email = 'quindu@valltre34.click' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Paramount+'), '4500.0', 'vencida', FALSE, 'PARAM,A'),
  ((SELECT id FROM emails WHERE email = 'poumax10010@worldstreaming.shop' LIMIT 1), (SELECT id FROM platforms WHERE name = 'HBO Max'), '4000.0', 'vencida', FALSE, NULL),
  ((SELECT id FROM emails WHERE email = 'theriamperro@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'YouTube Premium'), '4666.666667', 'vencida', FALSE, NULL);

-- P CHARLIES â€” 11 cuentas
INSERT INTO accounts (email_id, platform_id, purchase_price, status, is_active, observaciones) VALUES
  ((SELECT id FROM emails WHERE email = 'ch311564+22@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'HBO Max'), '7000.0', 'activo', TRUE, 'No ha preguntado y no la han cobrado'),
  ((SELECT id FROM emails WHERE email = 'rey.19.84c@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '32000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'dairo10@newaddr.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '32000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'dairo10@newaddr.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '32000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'Ssh251521@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'HBO Max'), '8000.0', 'activo', TRUE, 'No ha preguntado y no la han cobrado'),
  ((SELECT id FROM emails WHERE email = 'Luisusraez2772@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '32000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'za.ul49.51@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '32000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'der.1984c@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '32000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'xilen.a.89.8@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '32000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'ihamdiaz568@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '32000.0', 'activo', TRUE, NULL),
  ((SELECT id FROM emails WHERE email = 'geileissatteroi-4218@yopmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '32000.0', 'vencida', FALSE, 'me debe 2 dias');

-- P WILLIAM â€” 21 cuentas
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

-- P FENIX â€” 5 cuentas
INSERT INTO accounts (email_id, platform_id, purchase_price, status, is_active, observaciones) VALUES
  ((SELECT id FROM emails WHERE email = 'y.lachkar@fenixis.co' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '30000.0', 'vencida', FALSE, NULL),
  ((SELECT id FROM emails WHERE email = 'minerxxs118620@yarift.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '30000.0', 'vencida', FALSE, NULL),
  ((SELECT id FROM emails WHERE email = 'btracy27@yarift.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '30000.0', 'vencida', FALSE, NULL),
  ((SELECT id FROM emails WHERE email = 'eborahfac@yarift.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '30000.0', 'vencida', FALSE, NULL),
  ((SELECT id FROM emails WHERE email = 'farhadakbari07@fenixis.co' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Netflix'), '30000.0', 'activo', TRUE, 'no la cobaron parece gratis');

-- P VARIOS â€” 21 cuentas (7 eliminadas por emails duplicados con P ADRIANA)
INSERT INTO accounts (email_id, platform_id, purchase_price, status, is_active, observaciones) VALUES
  ((SELECT id FROM emails WHERE email = 'streamingmodz+tussi@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'HBO Max'), '10000.0', 'activo', TRUE, 'ModzStreaming ï£¿ Proveedor'),
  ((SELECT id FROM emails WHERE email = 'morenosilvajuan2@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'HBO Max'), '10000.0', 'activo', TRUE, 'ModzStreaming ï£¿ Proveedor'),
  ((SELECT id FROM emails WHERE email = 'lucasgakvism@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Prime Video'), '12000.0', 'activo', TRUE, 'ModzStreaming ï£¿ Proveedor'),
  ((SELECT id FROM emails WHERE email = 'morenosilvajaime194@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Prime Video'), '12000.0', 'activo', TRUE, 'ModzStreaming ï£¿ Proveedor'),
  ((SELECT id FROM emails WHERE email = 'dia.naleonn63@santreamteo.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Prime Video'), '13000.0', 'activo', TRUE, 'ModzStreaming ï£¿ Proveedor'),
  ((SELECT id FROM emails WHERE email = 'mendozasilvahellen@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Prime Video'), '13000.0', 'activo', TRUE, 'ModzStreaming ï£¿ Proveedor'),
  ((SELECT id FROM emails WHERE email = 'mendozamorenomilena@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Prime Video'), '12000.0', 'activo', TRUE, 'ModzStreaming ï£¿ Proveedor'),
  ((SELECT id FROM emails WHERE email = 'endersonmolinaneuque@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Prime Video'), '12000.0', 'activo', TRUE, 'ModzStreaming ï£¿ Proveedor'),
  ((SELECT id FROM emails WHERE email = 'callista644ff@hotmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Prime Video'), '3000.0', 'activo', TRUE, 'Elias Pizarro Proveedor Valencia Stream password Hotmail:Prime211'),
  ((SELECT id FROM emails WHERE email = 'ovidiomorenosilva@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Prime Video'), '12000.0', 'activo', TRUE, 'ModzStreaming ï£¿ Proveedor'),
  ((SELECT id FROM emails WHERE email = 'duarteandr@twoperfil.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'ChatGPT'), '20000.0', 'activo', TRUE, 'ModzStreaming ï£¿ Proveedor'),
  ((SELECT id FROM emails WHERE email = 'paramountetb3@kikoshop.net' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Paramount+'), '4000.0', 'activo', TRUE, 'Paramount Wiliam'),
  ((SELECT id FROM emails WHERE email = 'paramountetb3@kikoshop.net' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Paramount+'), '4000.0', 'activo', TRUE, 'Paramount Wiliam'),
  ((SELECT id FROM emails WHERE email = 'julioadams377@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'HBO Max'), '10000.0', 'activo', TRUE, 'ModzStreaming ï£¿ Proveedor'),
  ((SELECT id FROM emails WHERE email = 'sotomanu0273k+sds2@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'HBO Max'), '10000.0', 'activo', TRUE, 'ModzStreaming ï£¿ Proveedor'),
  ((SELECT id FROM emails WHERE email = 'humberto2026@kikoshop.net' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Directv Go'), '24000.0', 'activo', TRUE, 'William'),
  ((SELECT id FROM emails WHERE email = 'paramex1@kikoshop.net' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Paramount+'), '8000.0', 'activo', TRUE, 'William'),
  ((SELECT id FROM emails WHERE email = 'martha2026ballesteros@kikoshop.net' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Directv Go'), '24000.0', 'activo', TRUE, 'William'),
  ((SELECT id FROM emails WHERE email = 'jhon2026@kikoshop.net' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Directv Go'), '24000.0', 'activo', TRUE, 'William'),
  ((SELECT id FROM emails WHERE email = 'web.disneyplus+G0047@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Disney+'), '20000.0', 'activo', TRUE, 'ModzStreaming ï£¿ Proveedor'),
  ((SELECT id FROM emails WHERE email = 'wellian57@oneperfil.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Disney+'), '20000.0', 'activo', TRUE, 'ModzStreaming ï£¿ Proveedor');

-- P ADRIANA â€” 23 cuentas
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
  ((SELECT id FROM emails WHERE email = 'stremingflix009@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'HBO Max'), '12000.0', 'activo', TRUE, 'TARJETA NU'),
  ((SELECT id FROM emails WHERE email = 'stremingflix001@gmail.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'HBO Max'), '12000.0', 'activo', TRUE, 'HBO Max â€” pantalla adicional');

-- Total: 90 cuentas

-- ============================================================
-- Cuenta faltante (solo aparece en ventas, no en proveedores)
INSERT INTO accounts (email_id, platform_id, status, is_active) VALUES
  ((SELECT id FROM emails WHERE email = 'BRUMA286@servineira.com' LIMIT 1), (SELECT id FROM platforms WHERE name = 'Prime Video'), 'activo', TRUE);

-- CUSTOMERS â€” extraÃ­dos de hojas de ventas/pantallas
-- ============================================================
INSERT INTO customers (name, phone) VALUES
  ('Leidisita', '2222'),
  ('Nataly COPOWER', '2222'),
  ('Salome Esposo', '2222'),
  ('Gustavo Adolfo Errera 4', '2222'),
  ('Raquel / Javier Fernando GarcÃ­a Insurcol', '2222'),
  ('William Ricardo Martinez Insurcol', '2222'),
  ('Jesus Instructor Dibujo Sena', '2222'),
  ('Lennys Gomez Personal cliente jodido', '2222'),
  ('Mechas 2', '2222'),
  ('Silvia Garcia', '2222'),
  ('Andrea Picon', '2222'),
  ('Sara GÃ³mez', '2222'),
  ('Adriana RodrÃ­guez', '2222'),
  ('Yulitza Sanguino', '2222'),
  ('Stephanie Fuentes', '2222'),
  ('Dania Buitrago', '2222'),
  ('Dairo Vargas', '2222'),
  ('Yeli Galvan', '2222'),
  ('Flaco / Albeiro Manteco 2', '2222'),
  ('Ander BriceÃ±o', '2222'),
  ('Juliana Torres', '2222'),
  ('Lady sanchez', '2222'),
  ('Blanca Toro', '2222'),
  ('Vanessa Rodriguez', '2222'),
  ('camila', '2222'),
  ('Mami', '2222'),
  ('Katerine Arenas', '2222'),
  ('Yonkly Scorcia', '2222'),
  ('Natalia Valencia', '2222'),
  ('Albeiro Manteco 2', '2222'),
  ('Carlos Osorio Marval Cliente', '2222'),
  ('Tifany / Robinson Mosquera', '2222'),
  ('Cristian Calderon Cliente Marval', '2222'),
  ('RMAG', '2222'),
  ('Laura / Lady sanchez', '2222'),
  ('Yeini Prima de AdriÃ¡n', '2222'),
  ('Luis Felipe Dibujo Sena', '2222'),
  ('Daniel Gomez', '2222'),
  ('Yeimer David', '2222'),
  ('Caren gomez insurcol', '2222'),
  ('Aldemar Parqueadero', '2222'),
  ('NicolÃ¡s V 2 /  Roger Personal Insurcol', '2222'),
  ('Edison Archila Marin', '2222'),
  ('Yenni Bueno', '2222'),
  ('Wilson / Wilmer Gelvez Distribuidor', '2222'),
  ('AndrÃ©s Ruiz', '2222'),
  ('Nilsson Giovanni Insurcol', '2222'),
  ('Papaya/Jhon Amado', '2222'),
  ('Mauricio Guerrero / Wilmer  Gelvez', '2222'),
  ('Francisco Alba', '2222'),
  ('jhona / Yeini Prima de AdriÃ¡n', '2222'),
  ('Saray Gomez', '2222'),
  ('Anderson LeÃ³n', '2222'),
  ('Ãngel terraza', '2222'),
  ('JosÃ© bruges', '2222'),
  ('Paola RodrÃ­guez InglÃ©s', '2222'),
  ('Yesid GÃ³mez', '2222'),
  ('Sergio Murallas', '2222'),
  ('Maryith MontaÃ±o / John NÃºÃ±ez', '2222'),
  ('Pipe Pantalla Carlos', '2222'),
  ('Raul Quintero', '2222'),
  ('Duvan Rubio', '2222'),
  ('Neiman Henao', '2222'),
  ('Pilar Baez Dibujo Sena', '2222'),
  ('Leidy Hermana Yenni Bueno', '2222'),
  ('Luis Chinomes', '2222'),
  ('Brady lee silva', '2222'),
  ('Freddy Solano 2', '2222'),
  ('Olger Bayona Quintero', '2222'),
  ('Luis Miguel pin 5388', '2222'),
  ('mia', '2222'),
  ('Robin', '2222'),
  ('John NÃºÃ±ez', '2222'),
  ('Carlos Murillo', '2222'),
  ('Gustavo Molina', '2222'),
  ('Pilar', '2222'),
  ('John NÃºÃ±ez MARYITH', '2222'),
  ('Juan Carlos Personal Ins', '2222'),
  ('Roger Personal Insurcol', '2222'),
  ('NicolÃ¡s LeÃ³n NÃºÅ„ez Hermano Mafe?', '2222');

-- Total: 80 clientes

-- ============================================================

-- ============================================================
-- VENTAS: C NETFLIX + P NETFLIX + DISNEY + MAX + AMAZON
-- ============================================================

-- ==================== C NETFLIX ====================

-- Leidisita (combo: N4G,D,A,H) [C NETFLIX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Leidisita' LIMIT 1), '37000', 'vencida', '2022-10-22', '2026-05-26', '2026-05-25');
SET @order_id = LAST_INSERT_ID();
INSERT INTO customer_accounts (account_id, customer_id, order_id, contrasena, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, observaciones) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'netflixoriginal55@kikoshop.net' AND p.name = 'Netflix' LIMIT 1), (SELECT id FROM customers WHERE name = 'Leidisita' LIMIT 1), @order_id, 'PANICO', '37000', 'vencida', '2022-10-22', '2026-05-26', '2026-05-25', NULL);
UPDATE accounts SET credentials = 'PANICO' WHERE email_id = (SELECT id FROM emails WHERE email = 'netflixoriginal55@kikoshop.net' LIMIT 1) AND platform_id = (SELECT id FROM platforms WHERE name = 'Netflix');
-- Combo: Disney+
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'disneypremium25@kikoshop.net' AND p.name = 'Disney+' LIMIT 1), (SELECT id FROM customers WHERE name = 'Leidisita' LIMIT 1), @order_id, '1212', '12000', 'vencida', '2021-02-10', '2026-05-26', '2026-05-25', NULL);
UPDATE accounts SET credentials = 'CARNEYPAN1' WHERE email_id = (SELECT id FROM emails WHERE email = 'disneypremium25@kikoshop.net' LIMIT 1) AND platform_id = (SELECT id FROM platforms WHERE name = 'Disney+');
-- Combo: Prime Video
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'morenosilvajaime194@gmail.com' AND p.name = 'Prime Video' LIMIT 1), (SELECT id FROM customers WHERE name = 'Leidisita' LIMIT 1), @order_id, '0000', '8000', 'vencida', '2022-08-15', '2026-05-28', '2026-05-27', NULL);
-- Combo: HBO Max
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'stremingflix001@gmail.com' AND p.name = 'HBO Max' LIMIT 1), (SELECT id FROM customers WHERE name = 'Leidisita' LIMIT 1), @order_id, '1212', '9000', 'vencida', '2026-02-16', '2026-05-18', '2026-05-17', NULL);


-- Nataly COPOWER (combo: N2O,D,A) [C NETFLIX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Nataly COPOWER' LIMIT 1), '34000', 'activo', '2023-06-18', '2026-06-06', '2026-06-05');
SET @order_id = LAST_INSERT_ID();
INSERT INTO customer_accounts (account_id, customer_id, order_id, contrasena, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, observaciones) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'stremingflix009@gmail.com' AND p.name = 'Netflix' LIMIT 1), (SELECT id FROM customers WHERE name = 'Nataly COPOWER' LIMIT 1), @order_id, 'COATING', '34000', 'activo', '2023-06-18', '2026-06-06', '2026-06-05', NULL);
UPDATE accounts SET credentials = 'COATING' WHERE email_id = (SELECT id FROM emails WHERE email = 'stremingflix009@gmail.com' LIMIT 1) AND platform_id = (SELECT id FROM platforms WHERE name = 'Netflix');
-- Combo: Disney+
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'disneyfeb2@kikoshop.net' AND p.name = 'Disney+' LIMIT 1), (SELECT id FROM customers WHERE name = 'Nataly COPOWER' LIMIT 1), @order_id, '6571', '12000', 'por_vencer', '2022-01-20', '2026-06-04', '2026-06-03', NULL);
UPDATE accounts SET credentials = 'CAROLINA90' WHERE email_id = (SELECT id FROM emails WHERE email = 'disneyfeb2@kikoshop.net' LIMIT 1) AND platform_id = (SELECT id FROM platforms WHERE name = 'Disney+');
-- Combo: Prime Video
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'BRUMA286@servineira.com' AND p.name = 'Prime Video' LIMIT 1), (SELECT id FROM customers WHERE name = 'Nataly COPOWER' LIMIT 1), @order_id, '0000', '9000', 'activo', '2025-09-12', '2026-06-09', '2026-06-08', NULL);


-- Salome Esposo (combo: N1O,D) [C NETFLIX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Salome Esposo' LIMIT 1), '27000', 'activo', '2023-07-02', '2026-06-17', '2026-06-16');
SET @order_id = LAST_INSERT_ID();
INSERT INTO customer_accounts (account_id, customer_id, order_id, contrasena, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, observaciones) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'stremingflix025@gmail.com' AND p.name = 'Netflix' LIMIT 1), (SELECT id FROM customers WHERE name = 'Salome Esposo' LIMIT 1), @order_id, 'TACHA20', '27000', 'activo', '2023-07-02', '2026-06-17', '2026-06-16', NULL);
UPDATE accounts SET credentials = 'TACHA20' WHERE email_id = (SELECT id FROM emails WHERE email = 'stremingflix025@gmail.com' LIMIT 1) AND platform_id = (SELECT id FROM platforms WHERE name = 'Netflix');
-- Combo: Disney+
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'tolidisney211@kikoshop.net' AND p.name = 'Disney+' LIMIT 1), (SELECT id FROM customers WHERE name = 'Salome Esposo' LIMIT 1), @order_id, '7878', '10000', 'activo', '2023-07-02', '2026-06-18', '2026-06-17', NULL);
UPDATE accounts SET credentials = 'PREMIUM2026*' WHERE email_id = (SELECT id FROM emails WHERE email = 'tolidisney211@kikoshop.net' LIMIT 1) AND platform_id = (SELECT id FROM platforms WHERE name = 'Disney+');


-- Gustavo Adolfo Errera 4 (combo: N2O,C) [C NETFLIX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Gustavo Adolfo Errera 4' LIMIT 1), '35000', 'activo', '2023-11-22', '2026-07-08', '2026-07-07');
SET @order_id = LAST_INSERT_ID();
INSERT INTO customer_accounts (account_id, customer_id, order_id, contrasena, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, observaciones) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'stremingflix001@gmail.com' AND p.name = 'Netflix' LIMIT 1), (SELECT id FROM customers WHERE name = 'Gustavo Adolfo Errera 4' LIMIT 1), @order_id, 'PEPITO22', '35000', 'activo', '2023-11-22', '2026-07-08', '2026-07-07', 'TARJETA NU');
UPDATE accounts SET credentials = 'PEPITO22' WHERE email_id = (SELECT id FROM emails WHERE email = 'stremingflix001@gmail.com' LIMIT 1) AND platform_id = (SELECT id FROM platforms WHERE name = 'Netflix');


-- Raquel / Javier Fernando GarcÃ­a Insurcol (combo: ninguno) [C NETFLIX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Raquel / Javier Fernando GarcÃ­a Insurcol' LIMIT 1), '25000', 'activo', '2024-06-18', '2026-06-11', '2026-06-10');
SET @order_id = LAST_INSERT_ID();
INSERT INTO customer_accounts (account_id, customer_id, order_id, contrasena, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, observaciones) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'stremingflix024@gmail.com' AND p.name = 'Netflix' LIMIT 1), (SELECT id FROM customers WHERE name = 'Raquel / Javier Fernando GarcÃ­a Insurcol' LIMIT 1), @order_id, 'VISPERA', '25000', 'activo', '2024-06-18', '2026-06-11', '2026-06-10', NULL);
UPDATE accounts SET credentials = 'VISPERA' WHERE email_id = (SELECT id FROM emails WHERE email = 'stremingflix024@gmail.com' LIMIT 1) AND platform_id = (SELECT id FROM platforms WHERE name = 'Netflix');


-- William Ricardo Martinez Insurcol (combo: N1O) [C NETFLIX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'William Ricardo Martinez Insurcol' LIMIT 1), '16000', 'activo', '2024-09-14', '2026-07-07', '2026-07-06');
SET @order_id = LAST_INSERT_ID();
INSERT INTO customer_accounts (account_id, customer_id, order_id, contrasena, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, observaciones) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'stremingflix031@gmail.com' AND p.name = 'Netflix' LIMIT 1), (SELECT id FROM customers WHERE name = 'William Ricardo Martinez Insurcol' LIMIT 1), @order_id, 'FUTBOL', '16000', 'activo', '2024-09-14', '2026-07-07', '2026-07-06', NULL);
UPDATE accounts SET credentials = 'FUTBOL' WHERE email_id = (SELECT id FROM emails WHERE email = 'stremingflix031@gmail.com' LIMIT 1) AND platform_id = (SELECT id FROM platforms WHERE name = 'Netflix');


-- Jesus Instructor Dibujo Sena (combo: N1O, A) [C NETFLIX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Jesus Instructor Dibujo Sena' LIMIT 1), '37000', 'activo', '2025-09-12', '2026-06-09', '2026-06-08');
SET @order_id = LAST_INSERT_ID();
INSERT INTO customer_accounts (account_id, customer_id, order_id, contrasena, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, observaciones) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'stremingflix010@gmail.com' AND p.name = 'Netflix' LIMIT 1), (SELECT id FROM customers WHERE name = 'Jesus Instructor Dibujo Sena' LIMIT 1), @order_id, 'SOLOMIA', '37000', 'activo', '2025-09-12', '2026-06-09', '2026-06-08', NULL);
UPDATE accounts SET credentials = 'SOLOMIA' WHERE email_id = (SELECT id FROM emails WHERE email = 'stremingflix010@gmail.com' LIMIT 1) AND platform_id = (SELECT id FROM platforms WHERE name = 'Netflix');


-- Lennys Gomez Personal cliente jodido (combo: ninguno) [C NETFLIX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Lennys Gomez Personal cliente jodido' LIMIT 1), '27000', 'activo', '2026-05-06', '2026-06-05', '2026-06-04');
SET @order_id = LAST_INSERT_ID();
INSERT INTO customer_accounts (account_id, customer_id, order_id, contrasena, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, observaciones) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'stremingflix015@gmail.com' AND p.name = 'Netflix' LIMIT 1), (SELECT id FROM customers WHERE name = 'Lennys Gomez Personal cliente jodido' LIMIT 1), @order_id, 'LENNYS5', '27000', 'activo', '2026-05-06', '2026-06-05', '2026-06-04', NULL);
UPDATE accounts SET credentials = 'LENNYS5' WHERE email_id = (SELECT id FROM emails WHERE email = 'stremingflix015@gmail.com' LIMIT 1) AND platform_id = (SELECT id FROM platforms WHERE name = 'Netflix');


-- Mechas 2 (combo: N1O,H) [C NETFLIX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Mechas 2' LIMIT 1), '27000', 'activo', '2026-02-23', '2026-06-30', '2026-06-29');
SET @order_id = LAST_INSERT_ID();
INSERT INTO customer_accounts (account_id, customer_id, order_id, contrasena, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, observaciones) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'stremingflix016@gmail.com' AND p.name = 'Netflix' LIMIT 1), (SELECT id FROM customers WHERE name = 'Mechas 2' LIMIT 1), @order_id, 'REVIEW2026', '27000', 'activo', '2026-02-23', '2026-06-30', '2026-06-29', NULL);
UPDATE accounts SET credentials = 'REVIEW2026' WHERE email_id = (SELECT id FROM emails WHERE email = 'stremingflix016@gmail.com' LIMIT 1) AND platform_id = (SELECT id FROM platforms WHERE name = 'Netflix');
-- Combo: HBO Max
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'hbo.71ca+9i6@gmail.com' AND p.name = 'HBO Max' LIMIT 1), (SELECT id FROM customers WHERE name = 'Mechas 2' LIMIT 1), @order_id, '1474', '6000', 'activo', '2026-06-02', '2026-07-02', '2026-07-01', NULL);
UPDATE accounts SET credentials = 'e5f4kpmefa' WHERE email_id = (SELECT id FROM emails WHERE email = 'hbo.71ca+9i6@gmail.com' LIMIT 1) AND platform_id = (SELECT id FROM platforms WHERE name = 'HBO Max');


-- Silvia Garcia (combo: N1O,DTV,H) [C NETFLIX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Silvia Garcia' LIMIT 1), '25000', 'activo', '2026-03-15', '2026-06-13', '2026-06-12');
SET @order_id = LAST_INSERT_ID();
INSERT INTO customer_accounts (account_id, customer_id, order_id, contrasena, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, observaciones) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'agaraystore@gmail.com' AND p.name = 'Netflix' LIMIT 1), (SELECT id FROM customers WHERE name = 'Silvia Garcia' LIMIT 1), @order_id, 'CARTON80', '25000', 'activo', '2026-03-15', '2026-06-13', '2026-06-12', NULL);
UPDATE accounts SET credentials = 'CARTON80' WHERE email_id = (SELECT id FROM emails WHERE email = 'agaraystore@gmail.com' LIMIT 1) AND platform_id = (SELECT id FROM platforms WHERE name = 'Netflix');
-- Combo: HBO Max
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'sotomanu0273k+sds2@gmail.com' AND p.name = 'HBO Max' LIMIT 1), (SELECT id FROM customers WHERE name = 'Silvia Garcia' LIMIT 1), @order_id, '5151', '6000', 'activo', '2026-03-20', '2026-06-18', '2026-06-17', NULL);


-- Andrea Picon (combo: ninguno) [C NETFLIX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Andrea Picon' LIMIT 1), '27000', 'activo', '2026-04-30', '2026-06-29', '2026-06-28');
SET @order_id = LAST_INSERT_ID();
INSERT INTO customer_accounts (account_id, customer_id, order_id, contrasena, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, observaciones) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'stremingflix020@gmail.com' AND p.name = 'Netflix' LIMIT 1), (SELECT id FROM customers WHERE name = 'Andrea Picon' LIMIT 1), @order_id, 'HOTELLUNA', '27000', 'activo', '2026-04-30', '2026-06-29', '2026-06-28', NULL);
UPDATE accounts SET credentials = 'HOTELLUNA' WHERE email_id = (SELECT id FROM emails WHERE email = 'stremingflix020@gmail.com' LIMIT 1) AND platform_id = (SELECT id FROM platforms WHERE name = 'Netflix');


-- Sara GÃ³mez (combo: ninguno) [C NETFLIX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Sara GÃ³mez' LIMIT 1), '27000', 'activo', '2026-04-12', '2026-06-11', '2026-06-10');
SET @order_id = LAST_INSERT_ID();
INSERT INTO customer_accounts (account_id, customer_id, order_id, contrasena, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, observaciones) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'stremingflix002@gmail.com' AND p.name = 'Netflix' LIMIT 1), (SELECT id FROM customers WHERE name = 'Sara GÃ³mez' LIMIT 1), @order_id, 'SARA22', '27000', 'activo', '2026-04-12', '2026-06-11', '2026-06-10', NULL);
UPDATE accounts SET credentials = 'SARA22' WHERE email_id = (SELECT id FROM emails WHERE email = 'stremingflix002@gmail.com' LIMIT 1) AND platform_id = (SELECT id FROM platforms WHERE name = 'Netflix');


-- Adriana RodrÃ­guez (combo: ninguno) [C NETFLIX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Adriana RodrÃ­guez' LIMIT 1), '27000', 'vencida', '2026-05-03', '2026-06-02', '2026-06-01');
SET @order_id = LAST_INSERT_ID();
INSERT INTO customer_accounts (account_id, customer_id, order_id, contrasena, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, observaciones) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'stremingflix006@gmail.com' AND p.name = 'Netflix' LIMIT 1), (SELECT id FROM customers WHERE name = 'Adriana RodrÃ­guez' LIMIT 1), @order_id, 'ADRIANAR2', '27000', 'vencida', '2026-05-03', '2026-06-02', '2026-06-01', NULL);
UPDATE accounts SET credentials = 'ADRIANAR2' WHERE email_id = (SELECT id FROM emails WHERE email = 'stremingflix006@gmail.com' LIMIT 1) AND platform_id = (SELECT id FROM platforms WHERE name = 'Netflix');


-- Yulitza Sanguino (combo: N1O,DTV,M,A) [C NETFLIX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Yulitza Sanguino' LIMIT 1), '27000', 'activo', '2026-05-12', '2026-06-11', '2026-06-10');
SET @order_id = LAST_INSERT_ID();
INSERT INTO customer_accounts (account_id, customer_id, order_id, contrasena, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, observaciones) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'stremingflix022@gmail.com' AND p.name = 'Netflix' LIMIT 1), (SELECT id FROM customers WHERE name = 'Yulitza Sanguino' LIMIT 1), @order_id, 'ATLASFIT', '27000', 'activo', '2026-05-12', '2026-06-11', '2026-06-10', NULL);
UPDATE accounts SET credentials = 'ATLASFIT' WHERE email_id = (SELECT id FROM emails WHERE email = 'stremingflix022@gmail.com' LIMIT 1) AND platform_id = (SELECT id FROM platforms WHERE name = 'Netflix');
-- Combo: HBO Max
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'fuuanse48256@worldstreaming.shop' AND p.name = 'HBO Max' LIMIT 1), (SELECT id FROM customers WHERE name = 'Yulitza Sanguino' LIMIT 1), @order_id, '1477', '6000', 'activo', '2026-05-12', '2026-06-11', '2026-06-10', NULL);
-- Combo: Prime Video
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'ovidiomorenosilva@gmail.com' AND p.name = 'Prime Video' LIMIT 1), (SELECT id FROM customers WHERE name = 'Yulitza Sanguino' LIMIT 1), @order_id, '0000', '9000', 'activo', '2026-05-12', '2026-06-11', '2026-06-10', NULL);
UPDATE accounts SET credentials = 'Desayuno2892@' WHERE email_id = (SELECT id FROM emails WHERE email = 'ovidiomorenosilva@gmail.com' LIMIT 1) AND platform_id = (SELECT id FROM platforms WHERE name = 'Prime Video');


-- Stephanie Fuentes (combo: ninguno) [C NETFLIX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Stephanie Fuentes' LIMIT 1), '27000', 'activo', '2026-05-18', '2026-06-18', '2026-06-17');
SET @order_id = LAST_INSERT_ID();
INSERT INTO customer_accounts (account_id, customer_id, order_id, contrasena, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, observaciones) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'stremingflix017@gmail.com' AND p.name = 'Netflix' LIMIT 1), (SELECT id FROM customers WHERE name = 'Stephanie Fuentes' LIMIT 1), @order_id, 'CARNITAR', '27000', 'activo', '2026-05-18', '2026-06-18', '2026-06-17', NULL);
UPDATE accounts SET credentials = 'CARNITAR' WHERE email_id = (SELECT id FROM emails WHERE email = 'stremingflix017@gmail.com' LIMIT 1) AND platform_id = (SELECT id FROM platforms WHERE name = 'Netflix');


-- ==================== P NETFLIX ====================

-- Dania Buitrago | Netflix screen [tucuentanetflix309@kikoshop.net] [P NETFLIX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Dania Buitrago' LIMIT 1), '14000', 'activo', '2024-02-20', '2026-06-13', '2026-06-12');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'tucuentanetflix309@kikoshop.net' AND p.name = 'Netflix' LIMIT 1), (SELECT id FROM customers WHERE name = 'Dania Buitrago' LIMIT 1), @order_id, '5522', '14000', 'activo', '2024-02-20', '2026-06-13', '2026-06-12', NULL);
UPDATE accounts SET credentials = 'VENTAS12' WHERE email_id = (SELECT id FROM emails WHERE email = 'tucuentanetflix309@kikoshop.net' LIMIT 1) AND platform_id = (SELECT id FROM platforms WHERE name = 'Netflix');


-- Dairo Vargas | Netflix screen [tucuentanetflix309@kikoshop.net] [P NETFLIX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Dairo Vargas' LIMIT 1), '14000', 'activo', '2022-04-25', '2026-06-05', '2026-06-04');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'tucuentanetflix309@kikoshop.net' AND p.name = 'Netflix' LIMIT 1), (SELECT id FROM customers WHERE name = 'Dairo Vargas' LIMIT 1), @order_id, '4000', '14000', 'activo', '2022-04-25', '2026-06-05', '2026-06-04', NULL);


-- Yeli Galvan | Netflix screen [tucuentanetflix309@kikoshop.net] [P NETFLIX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Yeli Galvan' LIMIT 1), '15000', 'activo', '2026-05-08', '2026-06-07', '2026-06-06');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'tucuentanetflix309@kikoshop.net' AND p.name = 'Netflix' LIMIT 1), (SELECT id FROM customers WHERE name = 'Yeli Galvan' LIMIT 1), @order_id, '6111', '15000', 'activo', '2026-05-08', '2026-06-07', '2026-06-06', NULL);


-- Flaco / Albeiro Manteco 2 | Netflix screen [tucuentanetflix309@kikoshop.net] [P NETFLIX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Flaco / Albeiro Manteco 2' LIMIT 1), '16000', 'activo', '2026-05-27', '2026-06-26', '2026-06-25');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'tucuentanetflix309@kikoshop.net' AND p.name = 'Netflix' LIMIT 1), (SELECT id FROM customers WHERE name = 'Flaco / Albeiro Manteco 2' LIMIT 1), @order_id, '3434', '16000', 'activo', '2026-05-27', '2026-06-26', '2026-06-25', NULL);


-- Ander BriceÃ±o | Netflix screen [der.1984c@gmail.com] [P NETFLIX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Ander BriceÃ±o' LIMIT 1), '15000', 'activo', '2026-05-24', '2026-06-23', '2026-06-22');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'der.1984c@gmail.com' AND p.name = 'Netflix' LIMIT 1), (SELECT id FROM customers WHERE name = 'Ander BriceÃ±o' LIMIT 1), @order_id, '4333', '15000', 'activo', '2026-05-24', '2026-06-23', '2026-06-22', NULL);


-- Juliana Torres | Netflix screen [der.1984c@gmail.com] [P NETFLIX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Juliana Torres' LIMIT 1), '15000', 'activo', '2026-05-28', '2026-06-27', '2026-06-26');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'der.1984c@gmail.com' AND p.name = 'Netflix' LIMIT 1), (SELECT id FROM customers WHERE name = 'Juliana Torres' LIMIT 1), @order_id, '5555', '15000', 'activo', '2026-05-28', '2026-06-27', '2026-06-26', NULL);


-- Lady sanchez | Netflix screen [dairo10@newaddr.com] [P NETFLIX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Lady sanchez' LIMIT 1), '16000', 'activo', '2025-01-09', '2026-06-19', '2026-06-18');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'dairo10@newaddr.com' AND p.name = 'Netflix' LIMIT 1), (SELECT id FROM customers WHERE name = 'Lady sanchez' LIMIT 1), @order_id, '1998', '16000', 'activo', '2025-01-09', '2026-06-19', '2026-06-18', NULL);


-- Blanca Toro | Netflix screen [dairo10@newaddr.com] [P NETFLIX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Blanca Toro' LIMIT 1), '15000', 'vencida', '2026-04-02', '2026-06-01', '2026-05-31');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'dairo10@newaddr.com' AND p.name = 'Netflix' LIMIT 1), (SELECT id FROM customers WHERE name = 'Blanca Toro' LIMIT 1), @order_id, '7676', '15000', 'vencida', '2026-04-02', '2026-06-01', '2026-05-31', NULL);


-- Vanessa Rodriguez | Netflix screen [xilen.a.89.8@gmail.com] [P NETFLIX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Vanessa Rodriguez' LIMIT 1), '15000', 'activo', '2026-02-22', '2026-06-22', '2026-06-21');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'xilen.a.89.8@gmail.com' AND p.name = 'Netflix' LIMIT 1), (SELECT id FROM customers WHERE name = 'Vanessa Rodriguez' LIMIT 1), @order_id, '5123', '15000', 'activo', '2026-02-22', '2026-06-22', '2026-06-21', NULL);


-- Katerine Arenas | Netflix screen [ihamdiaz568@gmail.com] [P NETFLIX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Katerine Arenas' LIMIT 1), '15000', 'activo', '2026-04-12', '2026-06-11', '2026-06-10');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'ihamdiaz568@gmail.com' AND p.name = 'Netflix' LIMIT 1), (SELECT id FROM customers WHERE name = 'Katerine Arenas' LIMIT 1), @order_id, '4334', '15000', 'activo', '2026-04-12', '2026-06-11', '2026-06-10', NULL);
UPDATE accounts SET credentials = 'CAFECONLECHE' WHERE email_id = (SELECT id FROM emails WHERE email = 'ihamdiaz568@gmail.com' LIMIT 1) AND platform_id = (SELECT id FROM platforms WHERE name = 'Netflix');


-- Yonkly Scorcia | Netflix screen [ihamdiaz568@gmail.com] [P NETFLIX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Yonkly Scorcia' LIMIT 1), '15000', 'activo', '2026-04-28', '2026-06-27', '2026-06-26');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'ihamdiaz568@gmail.com' AND p.name = 'Netflix' LIMIT 1), (SELECT id FROM customers WHERE name = 'Yonkly Scorcia' LIMIT 1), @order_id, '7771', '15000', 'activo', '2026-04-28', '2026-06-27', '2026-06-26', NULL);


-- Natalia Valencia | Netflix screen [stremingflix019@gmail.com] [P NETFLIX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Natalia Valencia' LIMIT 1), '14000', 'activo', '2025-12-26', '2026-06-24', '2026-06-23');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'stremingflix019@gmail.com' AND p.name = 'Netflix' LIMIT 1), (SELECT id FROM customers WHERE name = 'Natalia Valencia' LIMIT 1), @order_id, '8090', '14000', 'activo', '2025-12-26', '2026-06-24', '2026-06-23', NULL);


-- Albeiro Manteco 2 | Netflix screen [stremingflix019@gmail.com] [P NETFLIX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Albeiro Manteco 2' LIMIT 1), '16000', 'activo', '2025-06-01', '2026-06-27', '2026-06-26');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'stremingflix019@gmail.com' AND p.name = 'Netflix' LIMIT 1), (SELECT id FROM customers WHERE name = 'Albeiro Manteco 2' LIMIT 1), @order_id, '3434', '16000', 'activo', '2025-06-01', '2026-06-27', '2026-06-26', NULL);


-- Carlos Osorio Marval Cliente | Netflix screen [agaray2107@gmail.com] [P NETFLIX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Carlos Osorio Marval Cliente' LIMIT 1), '15000', 'por_vencer', '2026-03-06', '2026-06-04', '2026-06-03');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'agaray2107@gmail.com' AND p.name = 'Netflix' LIMIT 1), (SELECT id FROM customers WHERE name = 'Carlos Osorio Marval Cliente' LIMIT 1), @order_id, '4040', '15000', 'por_vencer', '2026-03-06', '2026-06-04', '2026-06-03', NULL);
UPDATE accounts SET credentials = 'CAROLINA21' WHERE email_id = (SELECT id FROM emails WHERE email = 'agaray2107@gmail.com' LIMIT 1) AND platform_id = (SELECT id FROM platforms WHERE name = 'Netflix');


-- Tifany / Robinson Mosquera | Netflix screen [agaray2107@gmail.com] [P NETFLIX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Tifany / Robinson Mosquera' LIMIT 1), '15000', 'activo', '2026-03-10', '2026-06-08', '2026-06-07');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'agaray2107@gmail.com' AND p.name = 'Netflix' LIMIT 1), (SELECT id FROM customers WHERE name = 'Tifany / Robinson Mosquera' LIMIT 1), @order_id, '1996', '15000', 'activo', '2026-03-10', '2026-06-08', '2026-06-07', NULL);


-- Cristian Calderon Cliente Marval | Netflix screen [agaray2107@gmail.com] [P NETFLIX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Cristian Calderon Cliente Marval' LIMIT 1), '15000', 'activo', '2026-03-21', '2026-06-19', '2026-06-18');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'agaray2107@gmail.com' AND p.name = 'Netflix' LIMIT 1), (SELECT id FROM customers WHERE name = 'Cristian Calderon Cliente Marval' LIMIT 1), @order_id, '8080', '15000', 'activo', '2026-03-21', '2026-06-19', '2026-06-18', NULL);


-- ==================== DISNEY (Disney+) ====================

-- Laura / Lady sanchez | Disney+ (combo: NTV,DTV, A) [DISNEY]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Laura / Lady sanchez' LIMIT 1), '16000', 'activo', '2024-12-27', '2026-06-29', '2026-06-28');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'tolidisney230@kikoshop.net' AND p.name = 'Disney+' LIMIT 1), (SELECT id FROM customers WHERE name = 'Laura / Lady sanchez' LIMIT 1), @order_id, '1998', '16000', 'activo', '2024-12-27', '2026-06-29', '2026-06-28', '23/9/1989 mujer');
UPDATE accounts SET credentials = 'CARNEQUESO1' WHERE email_id = (SELECT id FROM emails WHERE email = 'tolidisney230@kikoshop.net' LIMIT 1) AND platform_id = (SELECT id FROM platforms WHERE name = 'Disney+');


-- Yeini Prima de AdriÃ¡n | Disney+ (combo: DTV) [DISNEY]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Yeini Prima de AdriÃ¡n' LIMIT 1), '16000', 'vencida', '2025-04-03', '2026-05-31', '2026-05-30');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'tolidisney230@kikoshop.net' AND p.name = 'Disney+' LIMIT 1), (SELECT id FROM customers WHERE name = 'Yeini Prima de AdriÃ¡n' LIMIT 1), @order_id, '7070', '16000', 'vencida', '2025-04-03', '2026-05-31', '2026-05-30', NULL);


-- Luis Felipe Dibujo Sena | Disney+ (combo: D,M) [DISNEY]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Luis Felipe Dibujo Sena' LIMIT 1), '6000', 'vencida', '2026-02-28', '2026-05-31', '2026-05-30');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'tolidisney230@kikoshop.net' AND p.name = 'Disney+' LIMIT 1), (SELECT id FROM customers WHERE name = 'Luis Felipe Dibujo Sena' LIMIT 1), @order_id, '8844', '6000', 'vencida', '2026-02-28', '2026-05-31', '2026-05-30', NULL);


-- Daniel Gomez | Disney+ (combo: DES,M) [DISNEY]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Daniel Gomez' LIMIT 1), '6000', 'vencida', '2026-05-04', '2026-06-03', '2026-06-02');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'tolidisney230@kikoshop.net' AND p.name = 'Disney+' LIMIT 1), (SELECT id FROM customers WHERE name = 'Daniel Gomez' LIMIT 1), @order_id, '5959', '6000', 'vencida', '2026-05-04', '2026-06-03', '2026-06-02', NULL);


-- Yeimer David | Disney+ (combo: ninguno) [DISNEY]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Yeimer David' LIMIT 1), '13000', 'activo', '2026-03-02', '2026-06-30', '2026-06-29');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'moviplus4@kikoshop.net' AND p.name = 'Disney+' LIMIT 1), (SELECT id FROM customers WHERE name = 'Yeimer David' LIMIT 1), @order_id, '6262', '13000', 'activo', '2026-03-02', '2026-06-30', '2026-06-29', NULL);


-- Caren gomez insurcol | Disney+ (combo: ninguno) [DISNEY]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Caren gomez insurcol' LIMIT 1), '13000', 'activo', '2026-04-28', '2026-06-27', '2026-06-26');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'moviplus4@kikoshop.net' AND p.name = 'Disney+' LIMIT 1), (SELECT id FROM customers WHERE name = 'Caren gomez insurcol' LIMIT 1), @order_id, '4747', '13000', 'activo', '2026-04-28', '2026-06-27', '2026-06-26', NULL);


-- Aldemar Parqueadero | Disney+ (combo: ninguno) [DISNEY]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Aldemar Parqueadero' LIMIT 1), '12000', 'vencida', '2024-07-10', '2026-05-01', '2026-04-30');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'tolidisney211@kikoshop.net' AND p.name = 'Disney+' LIMIT 1), (SELECT id FROM customers WHERE name = 'Aldemar Parqueadero' LIMIT 1), @order_id, '2121', '12000', 'vencida', '2024-07-10', '2026-05-01', '2026-04-30', 'no cortar');


-- NicolÃ¡s V 2 /  Roger Personal Insurcol | Disney+ (combo: ninguno) [DISNEY]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'NicolÃ¡s V 2 /  Roger Personal Insurcol' LIMIT 1), '12000', 'por_vencer', '2024-10-12', '2026-06-04', '2026-06-03');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'tolidisney211@kikoshop.net' AND p.name = 'Disney+' LIMIT 1), (SELECT id FROM customers WHERE name = 'NicolÃ¡s V 2 /  Roger Personal Insurcol' LIMIT 1), @order_id, '4000', '12000', 'por_vencer', '2024-10-12', '2026-06-04', '2026-06-03', NULL);


-- Edison Archila Marin | Disney+ (combo: ninguno) [DISNEY]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Edison Archila Marin' LIMIT 1), '13000', 'activo', '2024-07-08', '2026-06-30', '2026-06-29');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'disneypremium25@kikoshop.net' AND p.name = 'Disney+' LIMIT 1), (SELECT id FROM customers WHERE name = 'Edison Archila Marin' LIMIT 1), @order_id, '2080', '13000', 'activo', '2024-07-08', '2026-06-30', '2026-06-29', NULL);


-- Yenni Bueno | Disney+ (combo: DTV,M) [DISNEY]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Yenni Bueno' LIMIT 1), '13000', 'activo', '2023-01-06', '2026-06-18', '2026-06-17');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'disneypremium25@kikoshop.net' AND p.name = 'Disney+' LIMIT 1), (SELECT id FROM customers WHERE name = 'Yenni Bueno' LIMIT 1), @order_id, '2222', '13000', 'activo', '2023-01-06', '2026-06-18', '2026-06-17', NULL);


-- Wilson / Wilmer Gelvez Distribuidor | Disney+ (combo: ninguno) [DISNEY]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Wilson / Wilmer Gelvez Distribuidor' LIMIT 1), '13000', 'activo', '2026-04-28', '2026-06-27', '2026-06-26');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'disneypremium25@kikoshop.net' AND p.name = 'Disney+' LIMIT 1), (SELECT id FROM customers WHERE name = 'Wilson / Wilmer Gelvez Distribuidor' LIMIT 1), @order_id, '1717', '13000', 'activo', '2026-04-28', '2026-06-27', '2026-06-26', NULL);


-- AndrÃ©s Ruiz | Disney+ (combo: ninguno) [DISNEY]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'AndrÃ©s Ruiz' LIMIT 1), '13000', 'por_vencer', '2026-03-06', '2026-06-04', '2026-06-03');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'tolidisney228@kikoshop.net' AND p.name = 'Disney+' LIMIT 1), (SELECT id FROM customers WHERE name = 'AndrÃ©s Ruiz' LIMIT 1), @order_id, '6446', '13000', 'por_vencer', '2026-03-06', '2026-06-04', '2026-06-03', NULL);
UPDATE accounts SET credentials = 'PREMIUM2026' WHERE email_id = (SELECT id FROM emails WHERE email = 'tolidisney228@kikoshop.net' LIMIT 1) AND platform_id = (SELECT id FROM platforms WHERE name = 'Disney+');


-- Nilsson Giovanni Insurcol | Disney+ (combo: D,H) [DISNEY]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Nilsson Giovanni Insurcol' LIMIT 1), '13000', 'activo', '2026-05-22', '2026-06-21', '2026-06-20');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'tolidisney228@kikoshop.net' AND p.name = 'Disney+' LIMIT 1), (SELECT id FROM customers WHERE name = 'Nilsson Giovanni Insurcol' LIMIT 1), @order_id, '8888', '13000', 'activo', '2026-05-22', '2026-06-21', '2026-06-20', NULL);


-- Papaya/Jhon Amado | Disney+ (combo: ninguno) [DISNEY]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Papaya/Jhon Amado' LIMIT 1), '13000', 'activo', '2026-04-27', '2026-06-26', '2026-06-25');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'tolidisney228@kikoshop.net' AND p.name = 'Disney+' LIMIT 1), (SELECT id FROM customers WHERE name = 'Papaya/Jhon Amado' LIMIT 1), @order_id, '1144', '13000', 'activo', '2026-04-27', '2026-06-26', '2026-06-25', NULL);


-- Mauricio Guerrero / Wilmer  Gelvez | Disney+ (combo: ninguno) [DISNEY]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Mauricio Guerrero / Wilmer  Gelvez' LIMIT 1), '13000', 'activo', '2026-04-08', '2026-06-07', '2026-06-06');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'disneyfeb2@kikoshop.net' AND p.name = 'Disney+' LIMIT 1), (SELECT id FROM customers WHERE name = 'Mauricio Guerrero / Wilmer  Gelvez' LIMIT 1), @order_id, '6565', '13000', 'activo', '2026-04-08', '2026-06-07', '2026-06-06', NULL);


-- Gustavo Adolfo Errera 4 | Disney+ (combo: ninguno) [DISNEY]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Gustavo Adolfo Errera 4' LIMIT 1), '13000', 'activo', '2026-04-14', '2026-06-13', '2026-06-12');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'disneyfeb2@kikoshop.net' AND p.name = 'Disney+' LIMIT 1), (SELECT id FROM customers WHERE name = 'Gustavo Adolfo Errera 4' LIMIT 1), @order_id, '1111', '13000', 'activo', '2026-04-14', '2026-06-13', '2026-06-12', NULL);


-- Silvia Garcia | Disney+ (combo: N1O,DTV,H) [DISNEY]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Silvia Garcia' LIMIT 1), '11000', 'activo', '2026-03-24', '2026-06-22', '2026-06-21');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'disneypremium07@kikoshop.net' AND p.name = 'Disney+' LIMIT 1), (SELECT id FROM customers WHERE name = 'Silvia Garcia' LIMIT 1), @order_id, '5151', '11000', 'activo', '2026-03-24', '2026-06-22', '2026-06-21', NULL);
UPDATE accounts SET credentials = 'SABRINA21' WHERE email_id = (SELECT id FROM emails WHERE email = 'disneypremium07@kikoshop.net' LIMIT 1) AND platform_id = (SELECT id FROM platforms WHERE name = 'Disney+');


-- Francisco Alba | Disney+ (combo: ninguno) [DISNEY]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Francisco Alba' LIMIT 1), '13000', 'activo', '2026-06-01', '2026-07-01', '2026-06-30');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'disneypremium07@kikoshop.net' AND p.name = 'Disney+' LIMIT 1), (SELECT id FROM customers WHERE name = 'Francisco Alba' LIMIT 1), @order_id, '8999', '13000', 'activo', '2026-06-01', '2026-07-01', '2026-06-30', NULL);


-- jhona / Yeini Prima de AdriÃ¡n | Disney+ (combo: ninguno) [DISNEY]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'jhona / Yeini Prima de AdriÃ¡n' LIMIT 1), '13000', 'activo', '2026-04-08', '2026-06-07', '2026-06-06');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'disneypremium07@kikoshop.net' AND p.name = 'Disney+' LIMIT 1), (SELECT id FROM customers WHERE name = 'jhona / Yeini Prima de AdriÃ¡n' LIMIT 1), @order_id, '7474', '13000', 'activo', '2026-04-08', '2026-06-07', '2026-06-06', NULL);


-- Albeiro Manteco 2 | Disney+ (combo: ninguno) [DISNEY]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Albeiro Manteco 2' LIMIT 1), '13000', 'activo', '2026-04-15', '2026-06-14', '2026-06-13');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'disneypremium07@kikoshop.net' AND p.name = 'Disney+' LIMIT 1), (SELECT id FROM customers WHERE name = 'Albeiro Manteco 2' LIMIT 1), @order_id, '3434', '13000', 'activo', '2026-04-15', '2026-06-14', '2026-06-13', NULL);


-- Saray Gomez | Disney+ (combo: ninguno) [DISNEY]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Saray Gomez' LIMIT 1), '13000', 'vencida', '2026-05-03', '2026-06-02', '2026-06-01');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'disneypremium171@kikoshop.net' AND p.name = 'Disney+' LIMIT 1), (SELECT id FROM customers WHERE name = 'Saray Gomez' LIMIT 1), @order_id, '8181', '13000', 'vencida', '2026-05-03', '2026-06-02', '2026-06-01', NULL);
UPDATE accounts SET credentials = 'NUEVA2026*' WHERE email_id = (SELECT id FROM emails WHERE email = 'disneypremium171@kikoshop.net' LIMIT 1) AND platform_id = (SELECT id FROM platforms WHERE name = 'Disney+');


-- Anderson LeÃ³n | Disney+ (combo: ninguno) [DISNEY]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Anderson LeÃ³n' LIMIT 1), '13000', 'activo', '2026-05-07', '2026-06-06', '2026-06-05');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'disneypremium171@kikoshop.net' AND p.name = 'Disney+' LIMIT 1), (SELECT id FROM customers WHERE name = 'Anderson LeÃ³n' LIMIT 1), @order_id, '4545', '13000', 'activo', '2026-05-07', '2026-06-06', '2026-06-05', NULL);


-- Yulitza Sanguino | Disney+ (combo: N1O,DTV,M,A) [DISNEY]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Yulitza Sanguino' LIMIT 1), '13000', 'activo', '2026-05-12', '2026-06-11', '2026-06-10');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'disneypremium171@kikoshop.net' AND p.name = 'Disney+' LIMIT 1), (SELECT id FROM customers WHERE name = 'Yulitza Sanguino' LIMIT 1), @order_id, '1477', '13000', 'activo', '2026-05-12', '2026-06-11', '2026-06-10', NULL);


-- Ãngel terraza | Disney+ (combo: ninguno) [DISNEY]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Ãngel terraza' LIMIT 1), '13000', 'activo', '2026-05-06', '2026-06-05', '2026-06-04');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'tolidisney45@kikoshop.net' AND p.name = 'Disney+' LIMIT 1), (SELECT id FROM customers WHERE name = 'Ãngel terraza' LIMIT 1), @order_id, '1212', '13000', 'activo', '2026-05-06', '2026-06-05', '2026-06-04', NULL);
UPDATE accounts SET credentials = 'NUEVA2026@' WHERE email_id = (SELECT id FROM emails WHERE email = 'tolidisney45@kikoshop.net' LIMIT 1) AND platform_id = (SELECT id FROM platforms WHERE name = 'Disney+');


-- JosÃ© bruges | Disney+ (combo: ninguno) [DISNEY]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'JosÃ© bruges' LIMIT 1), '13000', 'activo', '2026-05-06', '2026-06-05', '2026-06-04');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'tolidisney45@kikoshop.net' AND p.name = 'Disney+' LIMIT 1), (SELECT id FROM customers WHERE name = 'JosÃ© bruges' LIMIT 1), @order_id, '8080', '13000', 'activo', '2026-05-06', '2026-06-05', '2026-06-04', NULL);


-- Paola RodrÃ­guez InglÃ©s | Disney+ (combo: ninguno) [DISNEY]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Paola RodrÃ­guez InglÃ©s' LIMIT 1), '13000', 'activo', '2026-05-10', '2026-06-09', '2026-06-08');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'tolidisney45@kikoshop.net' AND p.name = 'Disney+' LIMIT 1), (SELECT id FROM customers WHERE name = 'Paola RodrÃ­guez InglÃ©s' LIMIT 1), @order_id, '2423', '13000', 'activo', '2026-05-10', '2026-06-09', '2026-06-08', NULL);


-- Yesid GÃ³mez | Disney+ (combo: ninguno) [DISNEY]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Yesid GÃ³mez' LIMIT 1), '13000', 'activo', '2026-05-10', '2026-06-09', '2026-06-08');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'tolidisney45@kikoshop.net' AND p.name = 'Disney+' LIMIT 1), (SELECT id FROM customers WHERE name = 'Yesid GÃ³mez' LIMIT 1), @order_id, '5544', '13000', 'activo', '2026-05-10', '2026-06-09', '2026-06-08', NULL);


-- ==================== MAX (HBO Max) ====================

-- Daniel Gomez | HBO Max (combo: DES,M) [MAX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Daniel Gomez' LIMIT 1), '6000', 'vencida', '2026-03-04', '2026-06-02', '2026-06-01');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'stremingflix001@gmail.com' AND p.name = 'HBO Max' LIMIT 1), (SELECT id FROM customers WHERE name = 'Daniel Gomez' LIMIT 1), @order_id, '5959', '6000', 'vencida', '2026-03-04', '2026-06-02', '2026-06-01', NULL);
UPDATE accounts SET credentials = 'CAROLA212121' WHERE email_id = (SELECT id FROM emails WHERE email = 'stremingflix001@gmail.com' LIMIT 1) AND platform_id = (SELECT id FROM platforms WHERE name = 'HBO Max');


-- Sergio Murallas | HBO Max (combo: ninguno) [MAX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Sergio Murallas' LIMIT 1), '9000', 'activo', '2026-02-21', '2026-06-21', '2026-06-20');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'ch311564+22@gmail.com' AND p.name = 'HBO Max' LIMIT 1), (SELECT id FROM customers WHERE name = 'Sergio Murallas' LIMIT 1), @order_id, '5454', '9000', 'activo', '2026-02-21', '2026-06-21', '2026-06-20', NULL);
UPDATE accounts SET credentials = 'Max123456@' WHERE email_id = (SELECT id FROM emails WHERE email = 'ch311564+22@gmail.com' LIMIT 1) AND platform_id = (SELECT id FROM platforms WHERE name = 'HBO Max');


-- Yenni Bueno | HBO Max (combo: D,M) [MAX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Yenni Bueno' LIMIT 1), '8000', 'activo', '2024-12-28', '2026-06-24', '2026-06-23');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'ch311564+22@gmail.com' AND p.name = 'HBO Max' LIMIT 1), (SELECT id FROM customers WHERE name = 'Yenni Bueno' LIMIT 1), @order_id, '2222', '8000', 'activo', '2024-12-28', '2026-06-24', '2026-06-23', NULL);


-- Maryith MontaÃ±o / John NÃºÃ±ez | HBO Max (combo: H,A,P) [MAX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Maryith MontaÃ±o / John NÃºÃ±ez' LIMIT 1), '7000', 'activo', '2023-05-12', '2026-06-07', '2026-06-06');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'Ssh251521@gmail.com' AND p.name = 'HBO Max' LIMIT 1), (SELECT id FROM customers WHERE name = 'Maryith MontaÃ±o / John NÃºÃ±ez' LIMIT 1), @order_id, '9009', '7000', 'activo', '2023-05-12', '2026-06-07', '2026-06-06', NULL);
UPDATE accounts SET credentials = 'Max202584#' WHERE email_id = (SELECT id FROM emails WHERE email = 'Ssh251521@gmail.com' LIMIT 1) AND platform_id = (SELECT id FROM platforms WHERE name = 'HBO Max');


-- Pipe Pantalla Carlos | HBO Max (combo: M,A) [MAX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Pipe Pantalla Carlos' LIMIT 1), '9000', 'vencida', '2026-05-03', '2026-06-02', '2026-06-01');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'fuuanse48256@worldstreaming.shop' AND p.name = 'HBO Max' LIMIT 1), (SELECT id FROM customers WHERE name = 'Pipe Pantalla Carlos' LIMIT 1), @order_id, '5151', '9000', 'vencida', '2026-05-03', '2026-06-02', '2026-06-01', NULL);
UPDATE accounts SET credentials = 'max20200@@' WHERE email_id = (SELECT id FROM emails WHERE email = 'fuuanse48256@worldstreaming.shop' LIMIT 1) AND platform_id = (SELECT id FROM platforms WHERE name = 'HBO Max');


-- Dairo Vargas | HBO Max (combo: OE) [MAX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Dairo Vargas' LIMIT 1), '6000', 'activo', '2024-09-07', '2026-06-29', '2026-06-28');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'fuuanse48256@worldstreaming.shop' AND p.name = 'HBO Max' LIMIT 1), (SELECT id FROM customers WHERE name = 'Dairo Vargas' LIMIT 1), @order_id, '4000', '6000', 'activo', '2024-09-07', '2026-06-29', '2026-06-28', NULL);


-- Raul Quintero | HBO Max (combo: ninguno) [MAX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Raul Quintero' LIMIT 1), '9000', 'activo', '2026-05-21', '2026-06-20', '2026-06-19');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'morenosilvajuan2@gmail.com' AND p.name = 'HBO Max' LIMIT 1), (SELECT id FROM customers WHERE name = 'Raul Quintero' LIMIT 1), @order_id, '5888', '9000', 'activo', '2026-05-21', '2026-06-20', '2026-06-19', NULL);
UPDATE accounts SET credentials = 'OtroPedo999@' WHERE email_id = (SELECT id FROM emails WHERE email = 'morenosilvajuan2@gmail.com' LIMIT 1) AND platform_id = (SELECT id FROM platforms WHERE name = 'HBO Max');


-- Duvan Rubio | HBO Max (combo: ninguno) [MAX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Duvan Rubio' LIMIT 1), '9000', 'por_vencer', '2026-05-05', '2026-06-04', '2026-06-03');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'morenosilvajuan2@gmail.com' AND p.name = 'HBO Max' LIMIT 1), (SELECT id FROM customers WHERE name = 'Duvan Rubio' LIMIT 1), @order_id, '4949', '9000', 'por_vencer', '2026-05-05', '2026-06-04', '2026-06-03', NULL);


-- Neiman Henao | HBO Max (combo: PAR,M) [MAX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Neiman Henao' LIMIT 1), '6000', 'activo', '2026-05-09', '2026-06-08', '2026-06-07');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'julioadams377@gmail.com' AND p.name = 'HBO Max' LIMIT 1), (SELECT id FROM customers WHERE name = 'Neiman Henao' LIMIT 1), @order_id, '4499', '6000', 'activo', '2026-05-09', '2026-06-08', '2026-06-07', NULL);
UPDATE accounts SET credentials = 'Empres889axx' WHERE email_id = (SELECT id FROM emails WHERE email = 'julioadams377@gmail.com' LIMIT 1) AND platform_id = (SELECT id FROM platforms WHERE name = 'HBO Max');


-- Nilsson Giovanni Insurcol | HBO Max (combo: D,H) [MAX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Nilsson Giovanni Insurcol' LIMIT 1), '6000', 'activo', '2026-05-22', '2026-06-21', '2026-06-20');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'julioadams377@gmail.com' AND p.name = 'HBO Max' LIMIT 1), (SELECT id FROM customers WHERE name = 'Nilsson Giovanni Insurcol' LIMIT 1), @order_id, '8888', '6000', 'activo', '2026-05-22', '2026-06-21', '2026-06-20', NULL);


-- Luis Felipe Dibujo Sena | HBO Max (combo: D,M) [MAX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Luis Felipe Dibujo Sena' LIMIT 1), '6000', 'activo', '2026-01-05', '2026-06-04', '2026-06-03');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'sotomanu0273k+sds2@gmail.com' AND p.name = 'HBO Max' LIMIT 1), (SELECT id FROM customers WHERE name = 'Luis Felipe Dibujo Sena' LIMIT 1), @order_id, '6767', '6000', 'activo', '2026-01-05', '2026-06-04', '2026-06-03', NULL);
UPDATE accounts SET credentials = 'Libre8899ssxx' WHERE email_id = (SELECT id FROM emails WHERE email = 'sotomanu0273k+sds2@gmail.com' LIMIT 1) AND platform_id = (SELECT id FROM platforms WHERE name = 'HBO Max');


-- Pilar Baez Dibujo Sena | HBO Max (combo: ninguno) [MAX]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Pilar Baez Dibujo Sena' LIMIT 1), '9000', 'activo', '2026-06-02', '2026-07-02', '2026-07-01');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'hbo.71ca+9i6@gmail.com' AND p.name = 'HBO Max' LIMIT 1), (SELECT id FROM customers WHERE name = 'Pilar Baez Dibujo Sena' LIMIT 1), @order_id, '5050', '9000', 'activo', '2026-06-02', '2026-07-02', '2026-07-01', NULL);


-- ==================== AMAZON P (Prime Video) ====================

-- Lady Sanchez | Prime Video (combo: NTV,DTV, A) [AMAZON P]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Lady Sanchez' LIMIT 1), '8000', 'activo', '2025-02-24', '2026-06-20', '2026-06-19');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'mendozasilvahellen@gmail.com' AND p.name = 'Prime Video' LIMIT 1), (SELECT id FROM customers WHERE name = 'Lady Sanchez' LIMIT 1), @order_id, '0000', '8000', 'activo', '2025-02-24', '2026-06-20', '2026-06-19', NULL);


-- Carlos Osorio Marval Cliente | Prime Video (combo: NTV,A) [AMAZON P]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Carlos Osorio Marval Cliente' LIMIT 1), '6000', 'por_vencer', '2026-03-06', '2026-06-04', '2026-06-03');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'mendozasilvahellen@gmail.com' AND p.name = 'Prime Video' LIMIT 1), (SELECT id FROM customers WHERE name = 'Carlos Osorio Marval Cliente' LIMIT 1), @order_id, '0000', '6000', 'por_vencer', '2026-03-06', '2026-06-04', '2026-06-03', NULL);


-- Gustavo Adolfo Errera 4 | Prime Video (combo: ninguno) [AMAZON P]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Gustavo Adolfo Errera 4' LIMIT 1), '9000', 'activo', '2026-04-28', '2026-06-27', '2026-06-26');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'tuamazonetigo01@kikoshop.net' AND p.name = 'Prime Video' LIMIT 1), (SELECT id FROM customers WHERE name = 'Gustavo Adolfo Errera 4' LIMIT 1), @order_id, '0000', '9000', 'activo', '2026-04-28', '2026-06-27', '2026-06-26', NULL);
UPDATE accounts SET credentials = 'premium123@' WHERE email_id = (SELECT id FROM emails WHERE email = 'tuamazonetigo01@kikoshop.net' LIMIT 1) AND platform_id = (SELECT id FROM platforms WHERE name = 'Prime Video');


-- Pipe Pantalla Carlos | Prime Video (combo: ninguno) [AMAZON P]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Pipe Pantalla Carlos' LIMIT 1), '9000', 'vencida', '2024-12-08', '2026-06-01', '2026-05-31');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'tuamazonetigo01@kikoshop.net' AND p.name = 'Prime Video' LIMIT 1), (SELECT id FROM customers WHERE name = 'Pipe Pantalla Carlos' LIMIT 1), @order_id, '0000', '9000', 'vencida', '2024-12-08', '2026-06-01', '2026-05-31', NULL);


-- Maryith MontaÃ±o / John NÃºÃ±ez | Prime Video (combo: H,A,P) [AMAZON P]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Maryith MontaÃ±o / John NÃºÃ±ez' LIMIT 1), '7000', 'activo', '2023-05-12', '2026-06-10', '2026-06-09');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'endersonmolinaneuque@gmail.com' AND p.name = 'Prime Video' LIMIT 1), (SELECT id FROM customers WHERE name = 'Maryith MontaÃ±o / John NÃºÃ±ez' LIMIT 1), @order_id, '0000', '7000', 'activo', '2023-05-12', '2026-06-10', '2026-06-09', NULL);
UPDATE accounts SET credentials = 'Moncada892@@' WHERE email_id = (SELECT id FROM emails WHERE email = 'endersonmolinaneuque@gmail.com' LIMIT 1) AND platform_id = (SELECT id FROM platforms WHERE name = 'Prime Video');


-- Brady lee silva | Prime Video (combo: ninguno) [AMAZON P]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Brady lee silva' LIMIT 1), '8000', 'activo', '2024-02-23', '2026-07-20', '2026-07-19');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'endersonmolinaneuque@gmail.com' AND p.name = 'Prime Video' LIMIT 1), (SELECT id FROM customers WHERE name = 'Brady lee silva' LIMIT 1), @order_id, '0000', '8000', 'activo', '2024-02-23', '2026-07-20', '2026-07-19', NULL);


-- Freddy Solano 2 | Prime Video (combo: ninguno) [AMAZON P]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Freddy Solano 2' LIMIT 1), '9000', 'activo', '2026-05-30', '2026-06-29', '2026-06-28');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'ovidiomorenosilva@gmail.com' AND p.name = 'Prime Video' LIMIT 1), (SELECT id FROM customers WHERE name = 'Freddy Solano 2' LIMIT 1), @order_id, '0000', '9000', 'activo', '2026-05-30', '2026-06-29', '2026-06-28', NULL);


-- Olger Bayona Quintero | Prime Video (combo: ninguno) [AMAZON P]
INSERT INTO orders (customer_id, total, status, fecha_inicio, fecha_corte, fecha_cobro) VALUES
  ((SELECT id FROM customers WHERE name = 'Olger Bayona Quintero' LIMIT 1), '20000', 'activo', '2025-10-09', '2026-06-06', '2026-06-05');
SET @order_id = LAST_INSERT_ID();
INSERT INTO screens (account_id, customer_id, order_id, pin, precio_venta, status, fecha_inicio, fecha_corte, fecha_cobro, notes) VALUES
  ((SELECT a.id FROM accounts a JOIN emails e ON a.email_id = e.id JOIN platforms p ON a.platform_id = p.id WHERE e.email = 'mendozamorenomilena@gmail.com' AND p.name = 'Prime Video' LIMIT 1), (SELECT id FROM customers WHERE name = 'Olger Bayona Quintero' LIMIT 1), @order_id, '0000', '20000', 'activo', '2025-10-09', '2026-06-06', '2026-06-05', NULL);
UPDATE accounts SET credentials = 'Bugg67778@' WHERE email_id = (SELECT id FROM emails WHERE email = 'mendozamorenomilena@gmail.com' LIMIT 1) AND platform_id = (SELECT id FROM platforms WHERE name = 'Prime Video');

-- Actualizar capacidad de cuentas Netflix a 4 pantallas
UPDATE accounts SET max_screens = 4 WHERE platform_id = (SELECT id FROM platforms WHERE name = 'Netflix');

-- Totales: 78 Ã³rdenes, 15 customer_accounts, 73 screens
-- No encontrados (4):
--   C NETFLIX combo: Gustavo Adolfo Errera 4/Crunchyroll
--   C NETFLIX combo: Jesus Instructor Dibujo Sena/Prime Video
--   C NETFLIX combo: Silvia Garcia/Directv Go
--   C NETFLIX combo: Yulitza Sanguino/Directv Go
