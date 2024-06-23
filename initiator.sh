#!/bin/bash

set -e
set -u

PSQL=/usr/bin/psql
DB_HOST=localhost

$PSQL \
    -X \
    -h $DB_HOST \
    -U $PG_USER \
    -w \
    -c "select \"id\", \"domain\" from services where \"isInitialization\" = false" \
    --single-transaction \
    --set AUTOCOMMIT=off \
    --set ON_ERROR_STOP=on \
    --no-align \
    -t \
    --field-separator ' ' \
    --quiet \
    -d $PG_BD \
| while read id domain; do
    # Add a domain using the hestia CLI API
    v-add-web-domain $HESTIA_DOMAIN_USER "$domain.$HESTIA_DOMAIN_BASE" $HESTIA_DOMAIN_IP yes "www.$domain.$HESTIA_DOMAIN_BASE";
    if [ $? -ne 0 ]
        then
        echo "Could not create domain: $domain">>error.log
        exit 1
    fi
    v-add-dns-domain $HESTIA_DOMAIN_USER "$domain.$HESTIA_DOMAIN_BASE" $HESTIA_DOMAIN_IP $HESTIA_DOMAIN_NS_SERVER_1 $HESTIA_DOMAIN_NS_SERVER_2;
    if [ $? -ne 0 ]
        then
        echo "Could not create DNS for domain: $domain">>error.log
        exit 1
    fi
    v-add-letsencrypt-domain $HESTIA_DOMAIN_USER "$domain.$HESTIA_DOMAIN_BASE" "www.$domain.$HESTIA_DOMAIN_BASE"
    if [ $? -ne 0 ]
        then
        echo "Could not create ssl cert for domain:$domain">>error.log
        exit 1
    fi
    v-add-web-domain-ssl-force $HESTIA_DOMAIN_USER "$domain.$HESTIA_DOMAIN_BASE"
        if [ $? -ne 0 ]
        then
        echo "Could not create ssl forse for domain:$domain">>error.log
        exit 1
    fi
    $PSQL \
        -X \
        -h $DB_HOST \
        -U $PG_USER \
        -w \
        -c "update services set \"isInitialization\" = true where \"id\" = $id" \
        --quiet \
        -d $PG_BD
done

exit;