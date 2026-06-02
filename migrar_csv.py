#!/usr/bin/env python3
"""
Migración: CSV Correos A → Base streaming_business

Script one-off para cargar datos históricos desde un CSV exportado de Google Sheets.
Usa pymysql directamente por velocidad (bypassea el ORM para inserts masivos).

Uso:
    python migrar_csv.py <ruta-al-csv>

Requiere variables de entorno (mismas que .env):
    DB_NAME, DB_USER, DB_PASSWORD, DB_HOST, DB_PORT
"""

import csv
import os
import sys
import re
from datetime import datetime

import pymysql
from decouple import config

DB_CONFIG = {
    'host': config('DB_HOST', default='localhost'),
    'user': config('DB_USER'),
    'password': config('DB_PASSWORD'),
    'database': config('DB_NAME'),
    'port': int(config('DB_PORT', default='3306')),
    'charset': 'utf8mb4',
}

# Column mapping (0-indexed from csv)
COL = {
    'item': 1,
    'email': 2,
    'password': 3,
    'verification_email': 4,
    'phone': 5,
    'last_login': 6,
    'requires_validation': 7,
    'general_note': 8,
    'payment_notes': 9,
    'owner_name': 10,
    'birth_date': 11,
    'gender': 12,
    # Platform columns
    'netflix_x': 13,
    'netflix_note1': 14,
    'netflix_note2': 15,
    'disney_x': 16,
    'disney_note': 17,
    'hbo_x': 18,
    'hbo_note': 19,
    'star_x': 20,
    'star_note': 21,
    'prime_x': 22,
    'prime_note': 23,
}

# Platform config: (column_name, platform_name, note_cols)
PLATFORMS = [
    ('netflix', 'Netflix', ['netflix_note1', 'netflix_note2']),
    ('disney', 'Disney+', ['disney_note']),
    ('hbo', 'HBO Max', ['hbo_note']),
    ('star', 'Star+', ['star_note']),
    ('prime', 'Prime Video', ['prime_note']),
]


def parse_date(val):
    """Try to parse date from CSV, return None if empty/invalid."""
    val = val.strip() if val else ''
    if not val:
        return None
    for fmt in ('%d/%m/%Y', '%Y-%m-%d', '%d/%m/%y'):
        try:
            return datetime.strptime(val, fmt).date()
        except ValueError:
            continue
    return None


def parse_bool(val):
    """NO → 0, SI → 1, empty → None"""
    v = val.strip().upper() if val else ''
    if v == 'NO':
        return 0
    elif v in ('SI', 'YES', 'TRUE'):
        return 1
    return None


def detect_status(notes):
    """Detect if caída or active based on notes."""
    combined = ' '.join(n for n in notes if n).upper()
    if any(word in combined for word in ('CAÍDA', 'CAIDA', 'CAIDO')):
        return 'caida'
    return 'activo'


def clean(val):
    return val.strip() if val else ''


def run():
    conn = pymysql.connect(**DB_CONFIG)
    cur = conn.cursor()

    # ── Default provider ──
    cur.execute("SELECT id FROM providers WHERE name = 'Proveedor General'")
    row = cur.fetchone()
    if row:
        provider_id = row[0]
    else:
        cur.execute("INSERT INTO providers (name, notes) VALUES ('Proveedor General', 'Creado automáticamente desde migración CSV')")
        provider_id = cur.lastrowid

    # ── Platform IDs cache ──
    cur.execute("SELECT id, name FROM platforms")
    platform_map = {name: pid for pid, name in cur.fetchall()}

    # ── Read CSV path from CLI arg ──
    csv_path = sys.argv[1] if len(sys.argv) > 1 else None
    if not csv_path:
        print("Uso: python migrar_csv.py <ruta-al-csv>", file=sys.stderr)
        sys.exit(1)
    if not os.path.exists(csv_path):
        print(f"Archivo no encontrado: {csv_path}", file=sys.stderr)
        sys.exit(1)

    with open(csv_path, encoding='utf-8') as f:
        reader = csv.reader(f)
        rows = list(reader)

    total_emails = 0
    total_accounts = 0

    # Skip header rows (first 2)
    data_rows = rows[2:]

    for row in data_rows:
        if len(row) < 14:
            continue

        email = clean(row[COL['email']])
        if not email:
            continue

        # ── Insert email ──
        try:
            cur.execute("""
                INSERT INTO emails (email, password, verification_email, phone_number,
                    last_login, requires_validation, owner_name, birth_date, gender,
                    provider_id, notes)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (
                email,
                clean(row[COL['password']]) or None,
                clean(row[COL['verification_email']]) or None,
                clean(row[COL['phone']]) or None,
                parse_date(row[COL['last_login']]),
                parse_bool(row[COL['requires_validation']]),
                clean(row[COL['owner_name']]) or None,
                parse_date(row[COL['birth_date']]),
                clean(row[COL['gender']]) or None,
                provider_id,
                clean(row[COL['general_note']]) or None,
            ))
            email_id = cur.lastrowid
            total_emails += 1
        except pymysql.IntegrityError:
            # Duplicate email, fetch existing
            cur.execute("SELECT id FROM emails WHERE email = %s", (email,))
            existing = cur.fetchone()
            if existing:
                email_id = existing[0]
            else:
                print(f"  ⚠ Error con email duplicado: {email}")
                continue

        # ── Create accounts for each platform ──
        payment_notes = clean(row[COL['payment_notes']]) or None

        for pf_key, pf_name, note_cols in PLATFORMS:
            x_val = clean(row[COL[f'{pf_key}_x']])
            if x_val and x_val.upper() in ('X', 'SI', 'YES', 'TRUE'):
                # Gather notes
                notes_list = []
                for nc in note_cols:
                    v = clean(row[COL[nc]])
                    if v:
                        notes_list.append(v)

                status = detect_status(notes_list + ([payment_notes] if payment_notes else []))
                observaciones = ' | '.join(notes_list) if notes_list else None
                # If there's a note that looks like a password, put it in credentials
                credentials = None
                if notes_list:
                    # Take first non-obvious-note value that could be a credential
                    for n in notes_list:
                        if n and not any(x in n.upper() for x in ('LIBRE', 'CAÍDA', 'CAIDA', 'SIBLINGS', 'COATING')):
                            credentials = n
                            break

                # payment_notes goes to observaciones too
                full_obs = observaciones
                if payment_notes:
                    extra = f"Pago: {payment_notes}"
                    full_obs = f"{full_obs} | {extra}" if full_obs else extra

                try:
                    cur.execute("""
                        INSERT INTO accounts (email_id, platform_id, provider_id,
                            max_screens, credentials, status, observaciones, notes)
                        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                    """, (
                        email_id,
                        platform_map[pf_name],
                        provider_id,
                        1,  # default max_screens
                        credentials,
                        status,
                        full_obs,
                        payment_notes,
                    ))
                    total_accounts += 1
                except Exception as e:
                    print(f"  ⚠ Error insertando cuenta {pf_name} para {email}: {e}")

    conn.commit()
    conn.close()

    print(f"\n✅ Migración completada:")
    print(f"   - {total_emails} correos insertados")
    print(f"   - {total_accounts} cuentas de plataforma creadas")


if __name__ == '__main__':
    run()
