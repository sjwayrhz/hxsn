>A regular backup strategy is non-negotiable for any database. PostgreSQL provides two main methods for backups: logical and physical.

# Logical Backups with pg_dump

The pg_dump utility creates a “logical” backup by generating a file containing SQL commands. When this file is run, it recreates the database, tables, and data

- Pros: Flexible, human-readable (as plain text), can be restored onto different machine architectures or PostgreSQL major versions. Ideal for single databases.
- Cons: Can be slow for very large databases.

## To back up a single database

The custom format (-F c) is compressed and is the recommended format for most use cases.

```
pg_dump -U sammy -W -F c -f sammydb.dump sammydb
```

- -U sammy: Connect as the sammy user.
- -W: Prompt for the user’s password.
- -F c: Output in the custom (compressed) format.
- -f sammydb.dump: Write the output to a file named sammydb.dump.
- sammydb: The name of the database to back up.

To restore from a custom-format dump:
You must use the pg_restore utility. This command will not work if the database newdb already exists and has tables in it.

- First, create a new, empty database:

```
createdb -U sammy newdb
```

- Then, restore the dump into it:

```
pg_restore -U sammy -W -d newdb sammydb.dump
```

- -d newdb: Restore into the database named newdb.

## Physical Backups and Point-in-Time Recovery (PITR)

A physical backup is a binary-level copy of the entire database cluster’s data files. This method is used in conjunction with Write-Ahead Logs (WALs) to enable Point-in-Time Recovery (PITR).

PITR allows you to restore your database to any specific moment since your last base backup (for example, to five minutes before a user accidentally dropped a major table).

This is an advanced strategy with two main components:

- Base Backup: A full physical copy of the database, taken using a tool like pg_basebackup.
- WAL Archiving: The database is configured to continuously copy its transaction logs (WAL files) to a separate storage location.
To enable this, you must edit postgresql.conf:

```
wal_level = replica       # Minimum level for WAL archiving
archive_mode = on         # Enables archiving
archive_command = 'cp %p /path/to/wal/archive/%f'  # A command to copy WAL files
```

The archive_command is a simple example; production setups use more reliable tools like wal-g or pgBackRest to manage this process.
