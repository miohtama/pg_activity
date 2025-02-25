-- Get waiting queries for versions >= 9.2
SELECT
      pg_locks.pid AS pid,
      a.application_name AS application_name,
      a.datname AS database,
      a.usename AS user,
      CASE WHEN a.client_addr IS NULL
          THEN 'local'
          ELSE a.client_addr::TEXT
      END AS client,
      pg_locks.mode AS mode,
      pg_locks.locktype AS type,
      pg_locks.relation::regclass AS relation,
      EXTRACT(epoch FROM (NOW() - a.{duration_column})) AS duration,
      a.state as state,
      convert_from(a.query::bytea, coalesce(pg_catalog.pg_encoding_to_char(b.encoding), 'UTF8')) AS query
  FROM
      pg_catalog.pg_locks
      JOIN pg_catalog.pg_stat_activity a ON(pg_catalog.pg_locks.pid = a.pid)
      LEFT OUTER JOIN pg_database b ON a.datid = b.oid
 WHERE
      NOT pg_catalog.pg_locks.granted
  AND a.pid <> pg_backend_pid()
  AND CASE WHEN %(min_duration)s = 0
          THEN true
          ELSE extract(epoch from now() - {duration_column}) > %(min_duration)s
      END
ORDER BY
      EXTRACT(epoch FROM (NOW() - a.{duration_column})) DESC;
