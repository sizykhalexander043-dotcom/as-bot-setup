# Backup manifest — AS-CORE

- Captured at: 2026-11-26
- Supabase project ref: `qsiderzmnpjjvccgzels`
- Supabase region: `eu-central-1`
- Project status at capture: `ACTIVE_HEALTHY`
- Edge Function: `as-telegram-bot`
- Edge Function version: `10`
- Function status: `ACTIVE`
- verify_jwt: `false`
- Function source SHA-256 reported by Supabase: `b174e17d6891a05f829bbefb95ea4806a6a35443b10a29dfcbe9f80143bd23d1`
- Application tables captured: 10
- Application rows exported: 0 (all tables empty at capture)
- Applied migrations:
  - `20261125031947` — `initial_as_core_schema`
  - `20261125034748` — `secure_private_telegram_tables`

## Files

- `supabase/functions/as-telegram-bot/index.ts`: live function source from Supabase.
- `supabase/schema_snapshot.sql`: schema reconstructed from live database introspection (tables, constraints, indexes, trigger, RLS and policies).
- `supabase/types/database.types.ts`: generated TypeScript database types.
- `docs/restore.md`: restore checklist.

## Excluded intentionally

- Telegram bot token.
- Telegram webhook secret.
- Supabase service-role key and all other secrets.
- Client records and personal data.
- Supabase project passwords and connection credentials.

## Important limitations

The original SQL text of the two applied migrations was not available from the migration-list API. The SQL snapshot is reconstructed from the live schema and must be reviewed on a separate test project before it is used for restoration. It does not contain project-level settings, auth users, storage objects, secrets, or logs.
