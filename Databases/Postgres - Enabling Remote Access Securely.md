
# Enabling Remote Access Securely

By default, PostgreSQL only listens for connections from the local machine (localhost). To allow other computers to connect to your database, you must perform three steps:

Configure PostgreSQL to listen on its public IP address.
Add a host-based authentication (HBA) rule to allow remote connections for your user.
Open port 5432 in your server’s firewall.

## Step 1: Edit postgresql.conf

First, find your main PostgreSQL configuration file. On Ubuntu, this is typically located at /etc/postgresql/17/main/postgresql.conf. The version number (e.g., 17) may vary.

```
sudo nano /etc/postgresql/17/main/postgresql.conf
```

Inside this file, find the listen_addresses line. By default, it is set to localhost.

```
#------------------------------------------------------------------------------
# CONNECTIONS AND AUTHENTICATION
#------------------------------------------------------------------------------

# - Connection Settings -

listen_addresses = 'localhost'    # what IP address(es) to listen on;
```

Change localhost to * to listen on all available IP addresses, or set it to your server’s public IP address for more specificity.

```
listen_addresses = '*'
```

Save and close the file.

## Step 2: Edit pg_hba.conf

Next, you must configure the “host-based authentication” file, pg_hba.conf, to tell PostgreSQL how to authenticate remote users.

```
sudo nano /etc/postgresql/17/main/pg_hba.conf
```

At the bottom of this file, add a new line to allow connections for your user from a specific IP address. The ident method will not work for remote TCP/IP connections. You must use a password-based method like scram-sha-256 or md5.

```
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# Example for remote access:
host    sammydb         sammy           0.0.0.0/0               scram-sha-256
```

Let’s break down this line:

- host: Specifies a connection using a TCP/IP socket (a network connection).
- sammydb: The database name.
- sammy: The role (user) name.
- 198.51.100.5/32: The IP address of the remote machine. /32 means this rule applies only to this single IP. Use - 198.51.100.0/24 to allow all IPs in that subnet. Never use 0.0.0.0/0 in production.
- scram-sha-256: A secure, modern password-based authentication method. This requires that your user has a - password, which you can set using the SQL method (CREATE ROLE ... PASSWORD ... or ALTER ROLE sammy WITH PASSWORD - 'new_password';).
- Warning: Never hardcode passwords in scripts or documentation. The 'new_password' value above is a - placeholder—always use a strong, unique password and manage it securely (for example, using a password manager or - environment variables). Avoid sharing or storing plaintext passwords in version control or public places.

## Step 3: Open Firewall and Restart Service

With the configuration files updated, allow traffic on port 5432 through UFW:

```
sudo ufw allow 5432/tcp
```

Finally, restart the PostgreSQL service to apply all changes:

```
sudo systemctl restart postgresql
```

You can now test the connection from your remote machine (e.g., 198.51.100.5):

```
psql -h your_server_ip -U sammy -d sammydb
```

You will be prompted for the password you set for the sammy role.
