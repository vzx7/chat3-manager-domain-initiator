#!/bin/bash

set -e
set -u

PSQL=/usr/bin/psql
DB_HOST=localhost

$PSQL \
    -X \
    -h $DB_HOST \
    -U $PG_USER_CHAT3_MANAGER \
    -w \
    -c "select \"id\", \"domain\" from services where \"isInitialization\" = false" \
    --single-transaction \
    --set AUTOCOMMIT=off \
    --set ON_ERROR_STOP=on \
    --no-align \
    -t \
    --field-separator ' ' \
    --quiet \
    -d $PG_BD_CHAT3_MANAGER \
| while read id domain; do
    # Add a domain using the hestia CLI API
    v-add-web-domain $CHAT3_DOMAIN_USER "$domain.$CHAT3_DOMAIN_BASE" $CHAT3_DOMAIN_IP yes "www.$domain.$CHAT3_DOMAIN_BASE";
    if [ $? -ne 0 ]
        then
        echo "Could not create domain: $domain">>error.log
        exit 1
    fi
    v-add-dns-domain $CHAT3_DOMAIN_USER "$domain.$CHAT3_DOMAIN_BASE" $CHAT3_DOMAIN_IP $CHAT3_DOMAIN_NS_SERVER_1 $CHAT3_DOMAIN_NS_SERVER_2;
    if [ $? -ne 0 ]
        then
        echo "Could not create DNS for domain: $domain">>error.log
        exit 1
    fi
    v-add-letsencrypt-domain $CHAT3_DOMAIN_USER "$domain.$CHAT3_DOMAIN_BASE" "www.$domain.$CHAT3_DOMAIN_BASE"
    if [ $? -ne 0 ]
        then
        echo "Could not create ssl cert for domain:$domain">>error.log
        exit 1
    fi
    v-add-web-domain-ssl-force $CHAT3_DOMAIN_USER "$domain.$CHAT3_DOMAIN_BASE"
        if [ $? -ne 0 ]
        then
        echo "Could not create ssl forse for domain:$domain">>error.log
        exit 1
    fi
    $PSQL \
        -X \
        -h $DB_HOST \
        -U $PG_USER_CHAT3_MANAGER \
        -w \
        -c "update services set \"isInitialization\" = true where \"id\" = $id" \
        --quiet \
        -d $PG_BD_CHAT3_MANAGER
done

exit;