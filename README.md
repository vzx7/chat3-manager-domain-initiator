# chat3-manager-domain-initiator
Adding domains using the Hestia CLI API
**Attention!**
This script must be executed as a user with root rights or on behalf of the user who owns hestia!

## Necessary actions
For the script to work, you need to create a **.pgpass** file in the user’s home directory and give it 600 permissions.
The file must contain the following data

```sh
hostname:port:database:username:password
```
So, let's create a file
```sh
cd ~
echo "hostname:port:database:username:password" > .pgpass
chmod 600 .pgpass
```
Add environment variables to file ./.env:
```bash
# ENV FOR chat3 scripts
export PG_USER=your_pg_user
export PG_BD=your_pg_bd
export HESTIA_DOMAIN_USER=user
export HESTIA_DOMAIN_IP=111.111.111.111
export HESTIA_DOMAIN_BASE=example.com
export HESTIA_DOMAIN_NS_SERVER_1=ns1.example.ru 
export HESTIA_DOMAIN_NS_SERVER_2=ns2.example.ru
# Attention! In my case, all subdomains created by this script look into the same root directory, where the root application is located... In your case it may be different.
export HESTIA_ROOT_APP=example.ru
export PSQL=/usr/bin/psql
export DB_HOST=localhost
```
Attention! Please note that this is not an ini format.
The .env file will be used for the "source" statement, so all variables must be added via export!
## Run
```sh
git clone git@github.com:vzx7/chat3-manager-domain-initiator.git
cd chat3-manager-domain-initiator
./initiator.sh
```