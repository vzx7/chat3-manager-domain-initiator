#!/bin/bash

set -e
set -u

if [ $# -ne 5 ]
  then
    printf "All command arguments were not passed!\nExample: ./initiator.sh user 0.2.3.4 domain.com ns1.serv.com ns2.serv.com\n"
    exit 1;
fi

PSQL=/usr/bin/psql

DB_USER=root
DB_HOST=localhost
DB_NAME=dev

DOMAIN_USER=$1
DOMAIN_IP=$2
DOMAIN_BASE=$3
DOMAIN_NS_SERVER_1=$4
DOMAIN_NS_SERVER_2=$5

$PSQL \
    -X \
    -h $DB_HOST \
    -U $DB_USER \
    -w \
    -c "select \"id\", \"domain\" from services where \"isInitialization\" = false" \
    --single-transaction \
    --set AUTOCOMMIT=off \
    --set ON_ERROR_STOP=on \
    --no-align \
    -t \
    --field-separator ' ' \
    --quiet \
    -d $DB_NAME \
| while read id domain; do
    # Add a domain using the hestia CLI API
    v-add-web-domain $DOMAIN_USER "$domain.$DOMAIN_BASE" $DOMAIN_IP yes "www.$domain.$DOMAIN_BASE";
    if [ $? -ne 0 ]
        then
        echo "Could not create domain: $domain">>error.log
        exit 1
    fi
    v-add-dns-domain $DOMAIN_USER "$domain.$DOMAIN_BASE" $DOMAIN_IP $DOMAIN_NS_SERVER_1 $DOMAIN_NS_SERVER_2;
    if [ $? -ne 0 ]
        then
        echo "Could not create DNS for domain: $domain">>error.log
        exit 1
    fi
    v-add-letsencrypt-domain $DOMAIN_USER "$domain.$DOMAIN_BASE" "www.$domain.$DOMAIN_BASE"
    if [ $? -ne 0 ]
        then
        echo "Could not create ssl cert for domain:$domain">>error.log
        exit 1
    fi
    v-add-web-domain-ssl-force $DOMAIN_USER "$domain.$DOMAIN_BASE"
        if [ $? -ne 0 ]
        then
        echo "Could not create ssl forse for domain:$domain">>error.log
        exit 1
    fi
    $PSQL \
        -X \
        -h $DB_HOST \
        -U $DB_USER \
        -w \
        -c "update services set \"isInitialization\" = true where \"id\" = $id" \
        --quiet \
        -d $DB_NAME
done

exit;