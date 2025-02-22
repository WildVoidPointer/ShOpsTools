#!/bin/bash

ini_file="config.ini"
section="database"
key="host"

current_section=""
while IFS='=' read -r line_key line_value; do
  line_key=$(echo "$line_key" | xargs)
  line_value=$(echo "$line_value" | xargs)


  if [[ $line_key =~ ^\[(.*)\]$ ]]; then
    current_section="${BASH_REMATCH[1]}"
  elif [[ $current_section == "$section" && $line_key == "$key" ]]; then
    echo "[$section] $key = $line_value"
    break
  fi
done < "$ini_file"
