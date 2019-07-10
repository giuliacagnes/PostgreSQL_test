### USAGE
```
docker run --name some-postgres -v /home/giulia/postgres-docker/data:/tmp -d postgres
docker run -it --rm --link some-postgres:postgres postgres psql -h postgres -U postgres
```

```
CREATE EXTENSION file_fdw;

CREATE SERVER topups_srv FOREIGN DATA WRAPPER file_fdw;

CREATE FOREIGN TABLE topups (
  seq         integer,
  id_user     integer,
  topup_date  date,
  topup_val integer
) SERVER topups_srv
OPTIONS ( filename '/tmp/topups.tsv', format 'csv', delimiter E'\t', header 'true' );
```
