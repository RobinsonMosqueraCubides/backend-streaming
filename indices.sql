-- Índices recomendados para consultas frecuentes en streaming_business
-- Correr con: mariadb -u root -p streaming_business < indices.sql

USE streaming_business;

-- Cuentas: filtrar por estado + plataforma (dashboard, listados)
CREATE INDEX idx_accounts_status_platform ON accounts(status, platform_id);

-- Cuentas: filtrar por proveedor (compras por proveedor)
CREATE INDEX idx_accounts_provider ON accounts(provider_id);

-- Pantallas: filtrar por estado + cliente (qué tiene cada quien)
CREATE INDEX idx_screens_customer_status ON screens(customer_id, status);

-- Pantallas: filtrar por estado + fecha (vencimientos próximos)
CREATE INDEX idx_screens_status_fecha ON screens(status, fecha_corte);

-- Cuentas de cliente: filtrar por estado + fecha
CREATE INDEX idx_customer_accounts_status_fecha ON customer_accounts(status, fecha_corte);

-- Emails: búsqueda por teléfono y nombre
CREATE INDEX idx_emails_owner ON emails(owner_name);
CREATE INDEX idx_emails_phone ON emails(phone_number);
