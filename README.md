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
## Run
```sh
git clone git@github.com:vzx7/chat3-manager-domain-initiator.git
cd chat3-manager-domain-initiator
./initiator.sh user 0.2.3.4 domain.com ns1.serv.com ns2.serv.com
```