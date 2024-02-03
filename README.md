# Wrapstic
Wraps restic in a shell script and adds comfort features as well as notification.

## Usage
```bash
export $(cat /config/scripts/.env | xargs) && ./wrapstic.sh <restic parameters>
```

## Setup
Add `.env` file with configuraiton parameters.
```
SERVER=<server>
RESTIC_REPOSITORY=<repository>
RESTIC_PASSWORD=<password>

# MAX_STORAGE and THRESHOLD enable the storage check incl. warning
MAX_STORAGE=1000000000 # 1TB in kib
THRESHOLD=80           # 80%

# MAIL_FROM and MAIL_TO enable the email notification (does not work on macOS)
MAIL_FROM=<email>
MAIL_TO=<email>
```

Configure ssh keys for passwordless access to the server for convinience featues as storage check. Add following lines to `~/.ssh/config``
```bash
Host <alias> <hotname>
    HostName <hotname>
    Port <port>
    User <username>
    IdentityFile <path to identity file>
```

For email install `sendmail`
```bash
sudo apt install -y ssmtp
sudo mkdir -p /etc/ssmtp
```

And configure `sendmail`
```bash
echo "UseSTARTTLS=YES
FromLineOverride=YES
root=<root mail address>
mailhub=<server:port>
AuthUser=<user>
AuthPass=<password>" | sudo tee /etc/ssmtp/ssmtp.conf
```
