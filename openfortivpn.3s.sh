#!/bin/bash
set -x

# Get current status of a OpenFortiVPN connection with options to connect/disconnect.
# Also show the status of certificate with options to renew from 1Password.
# Commands that require admin permissions should be whitelisted with 'visudo', e.g.:
# YOURUSERNAME ALL=(ALL) NOPASSWD: /usr/local/bin/openfortivpn
# YOURUSERNAME ALL=(ALL) NOPASSWD: /usr/bin/killall -2 openfortivpn

# <xbar.title>OpenFortiVPN</xbar.title>
# <xbar.version>v1.0</xbar.version>
# <xbar.author>Anton Bastin</xbar.author>
# <xbar.author.github>to4kin</xbar.author.github>
# <xbar.desc>Displays status of a OpenFortiVPN interface with option to connect/disconnect.</xbar.desc>
# <xbar.image>https://i.imgur.com/v2aW5mo.png</xbar.image>

VPN_INTERFACE=ppp0
VPN_EXECUTABLE=/opt/homebrew/bin/openfortivpn

VPN_GATEWAY="\$(op item get windows --vault \"Deutsche Telekom\" --field FortiVPN.gateway)"
VPN_USERNAME="\$(op item get windows --vault \"Deutsche Telekom\" --field username)"
VPN_PASSWORD="\$(op item get windows --vault \"Deutsche Telekom\" --field password)"
VPN_TRUSTED_CERT="\$(op item get windows --vault \"Deutsche Telekom\" --field FortiVPN.trusted-cert)"

KEYS_PATH="$HOME/Documents/OpenFortiVPN"
if [ ! -d "$KEYS_PATH" ]; then
    mkdir -p $KEYS_PATH
fi

USER_KEY_FILE="$KEYS_PATH/key.pem"
USER_KEY_DELETE="rm $USER_KEY_FILE"
USER_KEY_DOWNLOAD="\$(op document get \"Windows Key\" --vault \"Deutsche Telekom\" > \"$USER_KEY_FILE\")"
USER_KEY_CREATED="stat -f '%Sm' $USER_KEY_FILE"

USER_CERT_FILE="$KEYS_PATH/certificate.pem"
USER_CERT_DELETE="rm $USER_CERT_FILE"
USER_CERT_DOWNLOAD="\$(op document get \"Windows Certificate\" --vault \"Deutsche Telekom\" > \"$USER_CERT_FILE\")"
USER_CERT_CREATED="stat -f '%Sm' $USER_CERT_FILE"
USER_CERT_EXPIRATION="openssl x509 -enddate -noout -in $USER_CERT_FILE | cut -d'=' -f2"

VPN_EXECUTABLE_PARAMS="\"$VPN_GATEWAY\" -u \"$VPN_USERNAME\" --trusted-cert \"$VPN_TRUSTED_CERT\" \
                    --user-cert=\"$USER_CERT_FILE\" --user-key=\"$USER_KEY_FILE\" --pppd-use-peerdns=1"

# Command to determine if OpenFortiVPN is connected or disconnected
VPN_CONNECTED="/sbin/ifconfig | egrep -A1 $VPN_INTERFACE | grep inet"
# Command to run to disconnect OpenFortiVPN
VPN_DISCONNECT_CMD="sudo killall -2 openfortivpn"

case "$1" in
    connect)
        # VPN connection command, should eventually result in $VPN_CONNECTED,
        eval echo "$VPN_PASSWORD" | eval sudo "$VPN_EXECUTABLE" "$VPN_EXECUTABLE_PARAMS" &> /dev/null &
        # Wait for connection so menu item refreshes instantly
        until eval "$VPN_CONNECTED"; do sleep 1; done
        ;;
    disconnect)
        eval "$VPN_DISCONNECT_CMD"
        # Wait for disconnection so menu item refreshes instantly
        until [ -z "$(eval "$VPN_CONNECTED")" ]; do sleep 1; done
        ;;
    sync)
        case "$2" in
            cert)
                # Dwonload the certificate file from the 1Password
                eval "$USER_CERT_DOWNLOAD"
                ;;
            key)
                # Dwonload the key file from the 1Password
                eval "$USER_KEY_DOWNLOAD"
                ;;
        esac
        ;;
    delete)
        case "$2" in
            cert)
                # Delete local cert file
                eval "$USER_CERT_DELETE"
                ;;
            key)
                # Delete local key file
                eval "$USER_KEY_DELETE"
                ;;
        esac
        ;;
esac

if [ -n "$(eval "$VPN_CONNECTED")" ]; then
    echo "✔"
    echo '---'
    echo 'Connected'
    echo "Disconnect OpenFortiVPN | bash='$0' param1=disconnect terminal=false refresh=true"
else
    echo "✘"
    echo '---'
    echo 'Disconnected'
    echo "Connect OpenFortiVPN | bash='$0' param1=connect terminal=false refresh=true"
fi

echo '---'
echo 'User Certificate'
if [ -f "$USER_CERT_FILE" ]; then
    echo "Synced: $(eval $USER_CERT_CREATED)"
    echo "Expiration date: $(eval $USER_CERT_EXPIRATION)"
    echo "Sync with 1Password | bash='$0' param1=sync param2=cert terminal=false refresh=true"
    echo "Delete local file | bash='$0' param1=delete param2=cert terminal=false refresh=true"
else
    echo "File not found"
    echo "Sync with 1Password | bash='$0' param1=sync param2=cert terminal=false refresh=true"
fi

echo '---'
echo 'User Key'
if [ -f "$USER_KEY_FILE" ]; then
    echo "Synced: $(eval $USER_KEY_CREATED)"
    echo "Sync with 1Password | bash='$0' param1=sync param2=key terminal=false refresh=true"
    echo "Delete local file | bash='$0' param1=delete param2=key terminal=false refresh=true"
else
    echo "File not found"
    echo "Sync with 1Password | bash='$0' param1=sync param2=key terminal=false refresh=true"
fi
