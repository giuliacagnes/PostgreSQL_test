-- 
-- Load Dataset into PostgreSQL
-- We have a small data set of a mobile company available for download here. This extract contains the
-- history of top-up dates and the amounts. Load this dataset into the topups table. Would you able to
-- load this input file as-is (without any manual modifications to it) using the Foreign Table PostgreSQL
-- feature rather than COPY command?

-- DDL/DML - Data Definition Language - Data Manipulation Language

CREATE EXTENSION file_fdw;

CREATE SERVER topups_server FOREIGN DATA WRAPPER file_fdw;

CREATE FOREIGN TABLE topups (
    seq                integer,
    id_user            integer NOT NULL,
    topup_date         date NOT NULL,
    topup_val          integer  NOT NULL
) SERVER topups_server
OPTIONS ( filename '/home/giulia/postgres_test/topups.tsv', format 'csv' , delimiter E'\t', header 'true');
