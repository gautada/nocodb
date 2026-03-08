# nocodb

A self-hosted nocodb container image

[github](https://github.com/nocodb/nocodb/)
[nocodb - dev](https://github.com/nocodb/nocodb/blob/develop/README.md)
[dev support](https://github.com/nocodb/nocodb/blob/master/.github/CONTRIBUTING.md)

## Database Configuration

By default, NocoDB uses SQLite stored at `/mnt/volumes/data/noco.db`. For production use, configure an external PostgreSQL database via the `NC_DB` environment variable.

### PostgreSQL

```yaml
env:
  - name: NC_DB
    value: "pg://user:password@postgres-host:5432/nocodb"
```

Connection string format: `pg://USER:PASSWORD@HOST:PORT/DATABASE`

### MySQL / MariaDB

```yaml
env:
  - name: NC_DB
    value: "mysql2://user:password@mysql-host:3306/nocodb"
```

### SQLite (default)

Leave `NC_DB` unset. Data is stored at `/mnt/volumes/data/noco.db`. Mount a persistent volume at `/mnt/volumes/data` to preserve data across restarts:

```yaml
volumeMounts:
  - name: nocodb-data
    mountPath: /mnt/volumes/data
```

### Migration

If migrating from an existing SQLite installation to PostgreSQL, export your data from NocoDB's admin panel before switching databases. There is no automatic migration path.

## Authentication

By default, NocoDB runs in **public mode** — the web UI is accessible without a login. To require user authentication, set the `NC_AUTH_JWT_SECRET` environment variable:

```yaml
# Kubernetes deployment example
env:
  - name: NC_AUTH_JWT_SECRET
    valueFrom:
      secretKeyRef:
        name: nocodb-secrets
        key: jwt-secret
```

Or with Docker:
```bash
docker run -d \
  -p 8080:8080 \
  -e NC_AUTH_JWT_SECRET="your-secret-key-here" \
  gautada/nocodb
```

When `NC_AUTH_JWT_SECRET` is set, NocoDB enables JWT-based authentication. Users must sign in before accessing any data. If the variable is empty or unset, NocoDB defaults to public mode.

> **Security note:** Always set `NC_AUTH_JWT_SECRET` in production deployments. Use a strong random value (e.g., `openssl rand -hex 32`).
