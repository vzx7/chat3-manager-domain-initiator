# Systemd service for executing the initiator.sh script

I use a systemd timer to execute the script **initiator.sh**.
You need to move the files to the systemd directory: **/etc/systemd/system**.
And start the timer:
```sh
systemctl start domainInitiator.timer
```
You can add a timer start with system boot:
```sh
systemctl enable domainInitiator.timer
```
You can view the execution log like this:
```sh
journalctl -S today -f -u domainInitiator.service
```