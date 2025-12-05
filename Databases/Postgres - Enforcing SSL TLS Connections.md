If you transmit sensitive data over a network, you must encrypt the connection.

## Enable SSL in postgresql.conf

Uncomment the ssl line and set it to on. You must also provide paths to your certificate and private key files.

```
# - SSL -
ssl = on
ssl_cert_file = '/etc/ssl/certs/your_server_cert.pem'
ssl_key_file = '/etc/ssl/private/your_server_key.key'
```

For testing, you can generate a self-signed certificate, but for production, you should use a certificate from a trusted authority.

## Enforce SSL in pg_hba.conf

To require that remote connections use SSL, change the host record type to hostssl. A connection using host can use SSL, but it is not mandatory. A hostssl connection will be rejected if it does not use SSL.

```
# TYPE     DATABASE        USER            ADDRESS                 METHOD

# Reject if not using SSL
hostssl    sammydb         sammy           198.51.100.5/32         scram-sha-256

# Allow local connections without SSL (optional)
host       all             all             127.0.0.1/32            scram-sha-256
```
