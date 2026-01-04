#!/bin/bash

# macOS System Cleanup Script
# -----------------------------------------------------------
# WARNING: Run this script at your own risk. It may delete
# files necessary for some applications. Backup your system
# before running.

echo "Starting macOS System Cleanup Script..."
echo "-----------------------------------------------------------"

# --- 1. Clean User Cache Files ---
echo "Cleaning user cache files (~/Library/Caches/)..."
# Ensure directory exists before cleaning, delete contents in quiet mode
if [ -d "$HOME/Library/Caches" ]; then
    sudo rm -rf "$HOME/Library/Caches/*"
    echo "User cache cleanup completed."
else
    echo "User cache directory not found, skipping."
fi

# --- 2. Clean System Log Files ---
echo "Cleaning system log files (/Library/Logs/)..."
# Requires administrator privileges to clean system logs
if [ -d "/Library/Logs" ]; then
    sudo rm -rf /Library/Logs/*
    echo "System log cleanup completed."
else
    echo "System log directory not found, skipping."
fi

echo "Cleaning user log files (~/Library/Logs/)..."
if [ -d "$HOME/Library/Logs" ]; then
    sudo rm -rf "$HOME/Library/Logs/*"
    echo "User log cleanup completed."
else
    echo "User log directory not found, skipping."
fi

# --- 3. Clean Old Download Files ---
# This step is more aggressive and is **disabled by default**.
# Uncomment if you need to execute it.
# echo "Cleaning download folder files older than 30 days..."
# find "$HOME/Downloads" -mtime +30 -exec rm {} \;
# echo "Download folder cleanup completed."

# --- 4. Empty Trash ---
echo "Emptying trash for all users..."
# Use `sudo` to ensure cleanup of permission-restricted files
sudo rm -rf "$HOME/.Trash/*"
# Clean .Trashes directories for other users and volumes
# sudo rm -rf /Volumes/*/.$UID/Trashes/*
# sudo rm -rf /private/var/folders/*/*/T/TemporaryItems/*
echo "Trash cleanup completed."

# --- 5. Run Maintenance Scripts ---
echo "Running built-in macOS daily, weekly, and monthly maintenance scripts (this may take some time)..."
# These scripts typically clean temporary files and databases
sudo periodic daily weekly monthly
echo "Maintenance scripts execution completed."

# --- 6. Rebuild Spotlight Index (Optional) ---
# This step is not cleanup but sometimes helps system performance.
# **Disabled by default**. Uncomment if you need to execute it.
# echo "Disabling and rebuilding Spotlight index (this may take a long time)..."
# sudo mdutil -i off /
# sudo mdutil -E /
# sudo mdutil -i on /
# echo "Spotlight index rebuild completed."

echo "-----------------------------------------------------------"
echo "macOS System Cleanup Script execution completed!"
echo "You may need to **restart** your Mac to fully release occupied space and memory."
