#!/bin/bash


# Check if filename argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <filename>"
    echo "  Example: $0 my_text_file.txt"
    exit 1
fi

FILE_NAME="$1"

# Check if file exists
if [ ! -f "$FILE_NAME" ]; then
    echo "Error: File '$FILE_NAME' does not exist."
    exit 1
fi

echo "Processing file: $FILE_NAME"

# 1. Replace \[ with $$
# 2. Replace \] with $$
# 3. Replace \( with $
# 4. Replace \) with $
# Note: In sed, both square brackets [] and parentheses () are special characters
# and need to be escaped with backslash \ to match literal characters.
# The $ symbol in replacement string also needs escaping (but since we're using
# double quotes, the $ inside sed needs \ escaping to avoid shell variable substitution).

sed -i.bak \
    -e 's/\\\[/$$/g' \
    -e 's/\\\]/$$/g' \
    -e 's/\\(/$/g' \
    -e 's/\\)/$/g' \
    "$FILE_NAME"

# Delete backup file (comment out the next line if you want to keep the backup)
rm "${FILE_NAME}.bak"

echo "Replacement completed."
# echo "Original file backed up as: ${FILE_NAME}.bak"
