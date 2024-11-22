#!/bin/bash

# Check if the URL and output file arguments are provided
if [ $# -lt 1 ]; then
    echo "Usage: $0 <url_to_zip_file>"
    exit 1
fi

# Variables
URL="$1"  # URL to download the zip file from
TEMP_DIR="/tmp/temp_dir"  # Temporary directory to store the zip file and extracted contents
ZIP_FILE="$TEMP_DIR/temp.zip"

# Clear output file if it already exists
> "$OUTPUT_FILE"

# Create a temporary directory
mkdir -p "$TEMP_DIR"

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

mysql -e 'USE ip2location;'
mysql -e 'TRUNCATE TABLE ipcountry;'
sed -i '1,15d' $DUMP_FILE
mysql < $DUMP_FILE

mysql -e "RENAME TABLE ip_country TO ipcountry_old;"
mysql -e "RENAME TABLE ipcountry TO ip_country;"
mysql -e "RENAME TABLE ipcountry_old TO ipcountry;"
rm -rf $TEMP_DIR
echo "SQL INSERT statements have been updated to $DUMP_FILE"
