-- Indices recomendados para consultas frecuentes en streaming_business.
-- Correr despues de schema.sql:
-- mariadb -u root -p streaming_business < indices.sql

USE streaming_business;

-- Correos y cuentas
CREATE INDEX idx_emails_provider ON emails(provider_id);
CREATE INDEX idx_accounts_email ON accounts(email_id);
CREATE INDEX idx_accounts_platform_status ON accounts(platform_id, status);

-- Pantallas
CREATE INDEX idx_screens_account_status ON screens(account_id, status);
CREATE INDEX idx_screens_customer_status ON screens(customer_id, status);
CREATE INDEX idx_screens_status_fecha ON screens(status, fecha_corte);

-- Cuentas completas vendidas
CREATE INDEX idx_customer_accounts_account_status ON customer_accounts(account_id, status);
CREATE INDEX idx_customer_accounts_status_fecha ON customer_accounts(status, fecha_corte);

-- Ordenes
CREATE INDEX idx_orders_customer_status ON orders(customer_id, status);

-- Emails
CREATE INDEX idx_emails_owner ON emails(owner_name);
