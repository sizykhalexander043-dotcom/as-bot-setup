# Applied migration history (source project)

The live AS-CORE project reported these applied migration records:

- `20261125031947_initial_as_core_schema`
- `20261125034748_secure_private_telegram_tables`

The original SQL bodies were not available from the migration-list interface during this backup. The current database structure has therefore been exported separately to `../schema_snapshot.sql` using live schema introspection.

Do not rename the introspection snapshot as either original migration. Before replaying it on a new project, test it on an empty development database and compare the resulting tables, constraints, indexes, triggers, RLS settings, and policies with the source project.
