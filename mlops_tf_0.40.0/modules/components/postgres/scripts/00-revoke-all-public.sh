#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    REVOKE ALL ON SCHEMA public FROM public;
EOSQL
