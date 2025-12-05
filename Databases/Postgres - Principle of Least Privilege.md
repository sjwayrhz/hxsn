Never use the postgres superuser role for your application. This role can bypass all permissions and drop the entire database cluster.

Instead, create specific roles for each application or user, granting only the permissions they need.
Example: Create a read-only user for an analytics application.

- Create the role. This role cannot log in

```
postgres=# CREATE ROLE analytics_user;
```

- Grant it CONNECT access to your database.

```
postgres=# GRANT CONNECT ON DATABASE sammydb TO analytics_user;
```

- Grant it USAGE on the schema (e.g., the public schema).

```
postgres=# GRANT USAGE ON SCHEMA public TO analytics_user;
```

- Grant it SELECT permissions on specific tables

```
postgres=# GRANT SELECT ON my_table, another_table TO analytics_user;
```
