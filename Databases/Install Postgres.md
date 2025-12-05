from [toturail](https://www.digitalocean.com/community/tutorials/how-to-install-postgresql-on-ubuntu-20-04-quickstart#introduction)

# Prerequisites

To follow along with this tutorial, you will need one Ubuntu server that has been configured by following our Initial Server Setup for Ubuntu guide. After completing this prerequisite tutorial, your server should have a non-root user with sudo permissions and a basic firewall.

# Step 1 — Installing PostgreSQL

To install PostgreSQL, first refresh your server’s local package index:

```
sudo apt update
```

Then, install the postgres package along with a -contrib package that adds some additional utilities and functionality:

```
sudo apt install postgresql postgresql-contrib
```

You can check the version by running the following command:

```
psql --version
```

Ensure that the service is started:

```
sudo systemctl enable --now postgresql.service
```

# Step 2 — Using PostgreSQL Roles and Databases

By default, Postgres uses a concept called “roles” to handle authentication and authorization. These are, in some ways, similar to regular Unix-style users and groups.

Upon installation, Postgres is set up to use ident authentication, meaning that it associates Postgres roles with a matching Unix/Linux system account. If a role exists within Postgres, a Unix/Linux username with the same name is able to sign in as that role.

The installation procedure created a user account called postgres that is associated with the default Postgres role. There are a few ways to utilize this account to access Postgres. One way is to switch over to the postgres account on your server by running the following command:

```
sudo -i -u postgres
```

Then you can access the Postgres prompt by running:

```
postgres@dynamic:~$ psql
```

This will log you into the PostgreSQL prompt, and from here you are free to interact with the database management system right away.

To exit out of the PostgreSQL prompt, run the following:

```
postgres=# \q
```

This will bring you back to the postgres Linux command prompt. To return to your regular system user, run the exit command:

```
postgres=# exit
```

Another way to connect to the Postgres prompt is to run the psql command as the postgres account directly with sudo:

```
sudo -u postgres psql
```

This will log you directly into Postgres without the intermediary bash shell in between.

Again, you can exit the interactive Postgres session by running the following:

```
postgres=# \q
```

# Step 3 — The SQL Method to Create a New User and Database (Optional)

The createuser and createdb shell commands are convenient helpers. However, for more control, you can perform these same actions directly within PostgreSQL using SQL commands. This approach is often clearer when setting passwords or granting specific permissions from the start.

## First, connect as the administrative postgres user

```
sudo -u postgres psql
```

Once at the PostgreSQL prompt, you can use CREATE ROLE and CREATE DATABASE to set up your new user and database.

## Create a New Role (User)

While the createuser shell command is interactive, the CREATE ROLE command lets you define everything in one statement. To create a user named sammy that can log in (LOGIN) and has a password, run:

```
postgres=# CREATE ROLE sammy WITH LOGIN PASSWORD 'your_strong_password';
```

If this user will also need to create databases, you can grant that permission at the same time:

```
postgres=# CREATE ROLE sammy WITH LOGIN PASSWORD 'your_strong_password' CREATEDB;
```

This is equivalent to answering “yes” to the superuser question in the interactive helper, though SUPERUSER is a much broader and more dangerous permission. Granting CREATEDB is safer if that’s all the user needs.

## Create a New Database

Next, create the database. It’s good practice to assign ownership of the new database to the new role you just created.

```
postgres=# CREATE DATABASE sammydb OWNER sammy;
```

If you are already connected to the sammy database and want to grant all privileges on it to the sammy user, you would run:

```
postgres=# GRANT ALL PRIVILEGES ON DATABASE sammydb TO sammy;
```

## Exit the postgres session

```
postgres=# \q
```

# Step 4 — Opening a Postgres Prompt with the New Role

To log in with ident based authentication, you’ll need a Linux user with the same name as your Postgres role and database.

If you don’t have a matching Linux user available, you can create one with the adduser command. You will have to do this from your non-root account with sudo privileges (meaning, not logged in as the postgres user):

```
sudo adduser sammy
```

Once this new account is available, you can either switch over and connect to the database by running the following:

```
sudo -i -u sammy
sammy@dynamic:~$ psql -d sammydb
```

This command will log you in automatically, assuming that all of the components have been properly configured.

If you want your user to connect to a different database, you can do so by specifying the database like the following:

```
sammy=# psql -d postgres
```

Once logged in, you can check your current connection information by running:

```
sammy-# \conninfo
```

Output

```
You are connected to database "sammy" as user "sammy" via socket in "/var/run/postgresql" at port "5432".
```
