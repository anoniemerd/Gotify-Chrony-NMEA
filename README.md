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
Copy and paste the following code:

```bash
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

```

### 2️⃣ Make the Script Executable

```bash
sudo chmod +x /usr/local/bin/check_gps_status.sh
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

