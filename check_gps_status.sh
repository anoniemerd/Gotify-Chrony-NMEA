#!/bin/bash

# Configuration
# -------------------------------
# URL for Gotify notifications
GOTIFY_URL="https://your-gotify-server.com/message?token=YOUR_TOKEN"
# Name of the GPS source as shown in chronyc
GPS_NAME="GPS_SOURCE"
# File to store the last known status
STATUS_FILE="/var/tmp/gps_primary_status"

# Find the GPS line in chronyc sources
# -------------------------------
# Look for the line corresponding to the GPS source
PRIMARY_LINE=$(chronyc sources | awk -v gps="$GPS_NAME" '$2==gps {print $0; exit}')

# If GPS source is not found, use defaults
if [[ -z "$PRIMARY_LINE" ]]; then
    LINE_MARKER=""
    REACH=0
else
    # Get the line marker (#*, ^+, etc.)
    LINE_MARKER=$(echo "$PRIMARY_LINE" | cut -c1-2)
    # Get the reachability value
    REACH=$(echo "$PRIMARY_LINE" | awk '{print $4}')
fi

# Determine current GPS status
# -------------------------------
# GPS is considered OK only if it's the primary source (#*) and reachable
if [[ "$LINE_MARKER" == "#*" && "$REACH" -gt 0 ]]; then
    CURRENT_STATUS="OK"
else
    CURRENT_STATUS="FAIL"
fi

# Read previous status
# -------------------------------
if [[ -f "$STATUS_FILE" ]]; then
    PREV_STATUS=$(cat "$STATUS_FILE")
else
    PREV_STATUS=""
fi

# Send Gotify notification only on status change
# -------------------------------
if [[ "$CURRENT_STATUS" != "$PREV_STATUS" ]]; then
    if [[ "$CURRENT_STATUS" == "FAIL" ]]; then
        MSG="GPS is no longer the primary time source!"
        curl -s -X POST "$GOTIFY_URL" \
             -F "title=GPS unavailable" \
             -F "message=$MSG" \
             -F "priority=10" >/dev/null
    else
        MSG="GPS is again the primary time source."
        curl -s -X POST "$GOTIFY_URL" \
             -F "title=GPS connection restored" \
             -F "message=$MSG" \
             -F "priority=5" >/dev/null
    fi
fi

# Save current status for next check
# -------------------------------
echo "$CURRENT_STATUS" > "$STATUS_FILE"