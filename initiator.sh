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
    if v-add-web-domain $HESTIA_DOMAIN_USER "$domain.$HESTIA_DOMAIN_BASE" $HESTIA_DOMAIN_IP yes "www.$domain.$HESTIA_DOMAIN_BASE"; then
       printf "\n#######################################################\nDomain $domain created.\n">>success.log
       else 
       echo "Could not create domain: $domain.">>error.log
       continue
    fi

    # Add DNS note
    if v-add-dns-domain $HESTIA_DOMAIN_USER "$domain.$HESTIA_DOMAIN_BASE" $HESTIA_DOMAIN_IP $HESTIA_DOMAIN_NS_SERVER_1 $HESTIA_DOMAIN_NS_SERVER_2; then
       echo "DNS record was successfully added for the domain $domain.">>success.log
       else 
       echo "Could not create DNS for domain: $domain">>error.log
       continue
    fi

    # Add ssl for domain
    if v-add-letsencrypt-domain $HESTIA_DOMAIN_USER "$domain.$HESTIA_DOMAIN_BASE" "www.$domain.$HESTIA_DOMAIN_BASE"; then
       echo "Successfully added ssl certificate for domain $domain.">>success.log
       else 
       echo "Could not create ssl cert for domain:$domain.">>error.log
       continue
    fi
    # Add forse ssl
    if v-add-web-domain-ssl-force $HESTIA_DOMAIN_USER "$domain.$HESTIA_DOMAIN_BASE"; then
       echo "Successfully added mandatory redirect to ssl for the domain $domain.">>success.log
       else 
       echo "Could not create ssl forse for domain:$domain.">>error.log
       continue;
    fi

    if rm -R /home/$HESTIA_DOMAIN_USER/web/$domain.$HESTIA_DOMAIN_BASE/public_html; then
        ln -s /home/$HESTIA_DOMAIN_USER/web/$HESTIA_ROOT_APP/public_html /home/$HESTIA_DOMAIN_USER/web/$domain.$HESTIA_DOMAIN_BASE/public_html
        echo "Successfully added a link to the root directory for the domain $domain.">>success.log
        else
        echo "Failed to create a link to the application root directory for domain: $domain.">>error.log
        continue;
    fi
    # update isInitialization for domain
    $PSQL \
        -X \
        -h $DB_HOST \
        -U $PG_USER \
        -w \
        -c "update services set \"isInitialization\" = true where \"id\" = $id" \
        --quiet \
        -d $PG_BD;
    printf "The domain: $domain has been successfully created, all data has been updated.\n#######################################################\n"
done

exit;