#!/bin/bash

set -e
set -u

PSQL=/usr/bin/psql

DB_USER=root
DB_HOST=localhost
DB_NAME=dev

$PSQL \
    -X \
    -h $DB_HOST \
    -U $DB_USER \
    -c "select \"id\", \"isInitialization\" from services" \
    --single-transaction \
    --set AUTOCOMMIT=off \
    --set ON_ERROR_STOP=on \
    --no-align \
    -t \
    --field-separator ' ' \
    --quiet \
    -d $DB_NAME \
| while read id isInitialization; do
    echo "SERVICE: $id $isInitialization"
done