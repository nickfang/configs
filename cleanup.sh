#!/bin/bash

# This script removes node_modules and target folders from the current directory and its subdirectories.

echo "Starting cleanup..."

# Find and remove all node_modules directories
echo "Deleting the following node_modules directories:"
find . -name "node_modules" -type d -prune -print -exec rm -rf {} +

# Find and remove all target directories
echo "Deleting the following target directories:"
find . -name "target" -type d -prune -print -exec rm -rf {} +

echo "Cleanup complete."
