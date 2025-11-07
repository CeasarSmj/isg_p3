#!/bin/bash

# Usage: bash tar_x.bash {s|m} {filename} {password}
# For split (s): Compress and split filename into parts < 20MB, encrypted with password
# For merge (m): Merge and decrypt parts named {filename}_part* back to original

if [ $# -ne 3 ]; then
    echo "Usage: $0 {s|m} {filename} {password}"
    exit 1
fi

MODE=$1
FILENAME=$2
PASSWORD=$3
PART_SIZE="20m"
BASE_NAME="${FILENAME}_part"

case $MODE in
    s|split)
        # Compress with tar.gz, encrypt with openssl, then split
        tar -czf - "$FILENAME" | openssl enc -aes-256-cbc -salt -pbkdf2 -pass pass:"$PASSWORD" | split -b "$PART_SIZE" - "$BASE_NAME"
        echo "Split completed: Created $BASE_NAME* files."
        ;;
    m|merge)
        # Find all part files matching $BASE_NAME*
        PARTS=($BASE_NAME*)
        if [ ${#PARTS[@]} -eq 0 ]; then
            echo "No part files found matching $BASE_NAME*"
            exit 1
        fi
        # Merge parts, decrypt, and extract
        cat $BASE_NAME* | openssl enc -d -aes-256-cbc -salt -pbkdf2 -pass pass:"$PASSWORD" | tar -xzf -
        echo "Merge completed: Extracted contents from $BASE_NAME*."
        # rename into file_name.tar.gz
        mv "$FILENAME" "${FILENAME}.tar.gz"
        ;;
    *)
        echo "Invalid mode: Use 's' for split or 'm' for merge."
        exit 1
        ;;
esac
