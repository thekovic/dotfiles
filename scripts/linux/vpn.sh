#!/bin/bash

sudo true

VPN_HOST=""
VPN_USER=""
PASSFILE="$HOME/.vpn_heslo"

# Start VPN in background
sudo openconnect --protocol=anyconnect \
                 --user="$VPN_USER" \
                 --passwd-on-stdin \
                 "$VPN_HOST" < "$PASSFILE" &
VPN_PID=$!

echo "VPN started (PID: $VPN_PID). Press Ctrl+C to disconnect."

# When the script exits (Ctrl+C, kill, etc), disconnect gracefully
cleanup() {
    echo "Disconnecting VPN..."
    sudo kill -2 "$VPN_PID" 2>/dev/null
    wait "$VPN_PID" 2>/dev/null
    echo "VPN disconnected."
}
trap cleanup EXIT

# Keep script alive until openconnect exits or Ctrl+C is pressed
wait "$VPN_PID"
