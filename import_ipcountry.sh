#!/bin/bash

# Check if the URL and output file arguments are provided
if [ $# -lt 1 ]; then
    echo "Usage: $0 <URL_TOKEN>"
    exit 1
fi

# Variables
TOKEN="$1"  # URL to download the zip file from
TEMP_DIR="/tmp/temp_dir/geolocation"  # Temporary directory to store the zip file and extracted contents
ZIP_FILE="$TEMP_DIR/temp.zip"
URL="https://www.ip2location.com/download?token=${TOKEN}&file=DB1


rm -R "$TEMP_DIR"  # Remove the temporary directory if it already exists
# Create a temporary directory
mkdir -p "$TEMP_DIR"

# Clear output file if it already exists
> "$OUTPUT_FILE"

# Download the zip file from the URL
echo "Downloading ZIP file from $URL..."
curl -L "$URL" -o "$ZIP_FILE"

# Unzip the downloaded file
echo "Unzipping the file..."
unzip -o "$ZIP_FILE" -d "$TEMP_DIR"

# Find the path of IPCountry.csv inside the extracted folder
DUMP_FILE=$(find "$TEMP_DIR" -name "IPCountry.mysql.dump" | head -n 1)

# Check if the CSV file exists
if [ -z "$DUMP_FILE" ]; then
    echo "IPCountry.mysql.dump not found in the downloaded zip file."
    exit 1
fi

echo "Found IPCountry.mysql.dump at $DUMP_FILE"


mysql -e 'TRUNCATE TABLE geolocation.ipcountry;'
sed -i '1,15d' $DUMP_FILE
sed -i '1i USE geolocation; START TRANSACTION;' $DUMP_FILE
sed -i '10000~10000a\ COMMIT; START TRANSACTION;'  $DUMP_FILE
echo "COMMIT;" >> $DUMP_FILE
echo "Starting import, it may take few minutes..."
mysql < $DUMP_FILE
 
mysql -e "RENAME TABLE geolocation.ip_country TO geolocation.ipcountry_old;"
mysql -e "RENAME TABLE geolocation.ipcountry TO geolocation.ip_country;"
mysql -e "RENAME TABLE geolocation.ipcountry_old TO geolocation.ipcountry;"

echo "SQL INSERT statements have been updated to $DUMP_FILE"
