attach 'md:';

attach 'local.db' as local_db;

COPY FROM DATABASE duckdb_stats TO local_db;