attach 'md:';

attach 'local.db' as local_db;

COPY FROM DATABASE fsq TO local_db;