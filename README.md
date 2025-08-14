# Gotify-Chrony-NMEA
Easy script that monitors the GPS Chrony NTP source and sends Gotify alerts on status changes.

<img width="1144" height="555" alt="afbeelding" src="https://github.com/user-attachments/assets/66e38159-861a-47b4-a224-100502599d4d" />


### **Script Summary**

1.  **Checks the NTP GPS source:**
    
    - Uses chronyc sources to find the GPS/NMEA source by name (e.g., "NMEA") and read its primary marker and reach value.
        
2.  **Determines GPS status:**
    
    -  Status is OK if the GPS source is the primary time source (#*) and its reach value is greater than 0 (has signal).

    -  Status is FAIL if it is not the primary source or the reach value is 0 (lost signal).
        
3.  **Compares with previous status:**
    
    -  Reads the last known status from a temporary file and only proceeds if the status has changed.
        
4.  **Sends Gotify notification on status change:**
    -  If GPS fails: sends a **high-priority alert**.
        
    -  If GPS is restored: sends a **restoration notice**.
        
5.  **Stores the current status:**
    
    - Saves the current status to a file for the next check.

## By Anoniemerd

### 1️⃣ Create the Script

Create the monitoring script:

```bash
sudo nano /usr/local/bin/check_gps_status.sh
```
Copy and paste the following code:

```bash
#!/bin/bash

######################################
# CONFIGURATION (to customize)
######################################

# Gotify server URL + API token
# REPLACE with your own server address and token
GOTIFY_URL="https://your-gotify-server.com/message?token=YOUR_TOKEN"

# Name of the GPS/NMEA source as it appears in 'chronyc sources'
# Change this if your source has a different name than "NMEA"
GPS_NAME="NMEA"

# Location of the temporary status file
# Usually, you don't need to change this
STATUS_FILE="/var/tmp/gps_primary_status"


######################################
# FETCH DATA FROM CHRONYC
######################################

# Search 'chronyc sources' output for the line matching GPS_NAME
# If found, store the full line. If not found, PRIMARY_LINE will be empty
PRIMARY_LINE=$(chronyc sources | awk '$2=="'"$GPS_NAME"'" {print $0; exit}')

# If no line is found, set default values (FAIL status)
if [[ -z "$PRIMARY_LINE" ]]; then
    LINE_MARKER=""   # symbol for primary status, e.g. "#*"
    REACH=0          # reach value (connectivity)
else
    LINE_MARKER=$(echo "$PRIMARY_LINE" | awk '{print $1}')  # Column 1 = marker
    REACH=$(echo "$PRIMARY_LINE" | awk '{print $5}')        # Column 5 = reach value
fi


######################################
# DETERMINE CURRENT STATUS
######################################

# Status is FAIL if:
# - The GPS source is NOT primary (marker != "#*")
# - OR the reach value equals 0 (no signal)
if [[ "$LINE_MARKER" != "#*" || "$REACH" -eq 0 ]]; then
    CURRENT_STATUS="FAIL"
else
    CURRENT_STATUS="OK"
fi


######################################
# LOAD PREVIOUS STATUS
######################################

# Read the previous status from the temporary file, if it exists
if [[ -f "$STATUS_FILE" ]]; then
    PREV_STATUS=$(cat "$STATUS_FILE")
else
    PREV_STATUS=""
fi


######################################
# SEND GOTIFY NOTIFICATIONS
######################################

# Only send a notification if the status has changed
if [[ "$CURRENT_STATUS" != "$PREV_STATUS" ]]; then
    if [[ "$CURRENT_STATUS" == "FAIL" ]]; then
        # FAIL message
        MSG="🔴 GPS/NMEA is either not primary or has lost signal (reach=0) on SERVER-NAME!"
        curl -s -X POST "$GOTIFY_URL" \
             -F "title=GPS issue detected" \
             -F "message=$MSG" \
             -F "priority=10" >/dev/null
    else
        # OK message
        MSG="✅ GPS/NMEA is primary and has signal again on SERVER-NAME."
        curl -s -X POST "$GOTIFY_URL" \
             -F "title=GPS restored" \
             -F "message=$MSG" \
             -F "priority=5" >/dev/null
    fi
fi


######################################
# SAVE CURRENT STATUS
######################################

# Save the current status for comparison in the next run
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

