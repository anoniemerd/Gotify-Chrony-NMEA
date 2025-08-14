# Gotify-Chrony-NMEA
Easy script that monitors the GPS Chrony NTP source and sends Gotify alerts on status changes.

<img width="1138" height="555" alt="afbeelding" src="https://github.com/user-attachments/assets/01ffc425-63d3-4ab3-bdfc-5fc81dbf1b7c" />

### **Script Summary**

1.  **Checks the NTP GPS source:**
    
    -   Uses `chronyc sources` to determine if the GPS (NMEA) is currently the **primary time source** (`#*`).
        
2.  **Determines GPS status:**
    
    -   If GPS is the primary source **and** reachable (`Reach > 0`), the status is `OK`.
        
    -   Otherwise, the status is `FAIL`.
        
3.  **Compares with previous status:**
    
    -   Reads the last known status from a temporary file.
        
    -   Only triggers a notification if the status has **changed**.
        
4.  **Sends Gotify notification on status change:**
    
    -   If GPS fails: sends a **high-priority alert**.
        
    -   If GPS is restored: sends a **restoration notice**.
        
5.  **Stores the current status:**
    
    -   Saves the current status to a file for the next check.

## By Anoniemerd

### 1️⃣ Create the Script

Create the monitoring script:

```bash
sudo nano /usr/local/bin/check_gps_status.sh
```


### 2️⃣ Make the Script Executable

```bash
sudo chmod +x /usr/local/bin/check_gps_status.sh
```
Copy and paste the following code:

```bash
#!/bin/bash

# Configuration
GOTIFY_URL="https://your-gotify-server/message?token=YOUR_TOKEN"
GPS_NAME="NMEA"                # Name of GPS source as shown in chronyc sources
STATUS_FILE="/var/tmp/gps_primary_status"

# Find the real primary source (marked with '*')
PRIMARY_LINE=$(chronyc sources | awk '/^\#\*/ {print $0; exit}')

if [[ -z "$PRIMARY_LINE" ]]; then
    # No primary source, pick first available
    PRIMARY_LINE=$(chronyc sources | awk '/^[\#\^\+\-x]/ {print $0; exit}')
fi

PRIMARY=$(echo "$PRIMARY_LINE" | awk '{print $2}')
REACH=$(echo "$PRIMARY_LINE" | awk '{print $4}')

# Default values if empty
if [[ -z "$PRIMARY" ]]; then
    PRIMARY="none"
    REACH=0
fi

# GPS is OK only if PRIMARY = GPS_NAME AND Reach > 0 AND actually '*'
LINE_MARKER=$(echo "$PRIMARY_LINE" | cut -c1-2)
if [[ "$PRIMARY" == "$GPS_NAME" && "$REACH" -gt 0 && "$LINE_MARKER" == "#*" ]]; then
    CURRENT_STATUS="OK"
else
    CURRENT_STATUS="FAIL"
fi

# Read previous status
if [[ -f "$STATUS_FILE" ]]; then
    PREV_STATUS=$(cat "$STATUS_FILE")
else
    PREV_STATUS=""
fi

# Send Gotify alert only on status change
if [[ "$CURRENT_STATUS" != "$PREV_STATUS" ]]; then
    if [[ "$CURRENT_STATUS" == "FAIL" ]]; then
        MSG="GPS/NMEA is no longer the primary time source!"
        curl -s -X POST "$GOTIFY_URL" \
             -F "title=GPS unavailable" \
             -F "message=$MSG" \
             -F "priority=10" >/dev/null
    else
        MSG="GPS/NMEA is now the primary time source."
        curl -s -X POST "$GOTIFY_URL" \
             -F "title=GPS connection restored" \
             -F "message=$MSG" \
             -F "priority=5" >/dev/null
    fi
fi

# Save current status
echo "$CURRENT_STATUS" > "$STATUS_FILE"

```

### 3️⃣ Schedule the Script
Set up a cron job to run the script every minute:
```bash
sudo crontab -e
```
Add the line:
```bash
* * * * * /usr/local/bin/check_gps_status.sh
```

### 4️⃣Finished 🎉
Your GPS monitoring script is now running in the background. Gotify alerts will notify you whenever the GPS/NMEA source stops or resumes being the primary NTP source.

