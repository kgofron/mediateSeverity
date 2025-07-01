#!/bin/bash

# Script to check EPICS PVs in mediaSeverity.STATUSEXT file and print all values
# Usage: ./check_pv_severity.sh

# Check if the file exists
if [ ! -f "mediaSeverity.STATUSEXT" ]; then
    echo "Error: mediaSeverity.STATUSEXT file not found in current directory"
    exit 1
fi

# Check if caget is available
if ! command -v caget &> /dev/null; then
    echo "Error: caget command not found. Please ensure EPICS tools are installed and in PATH"
    exit 1
fi

echo "Checking EPICS PVs in mediaSeverity.STATUSEXT for all values..."
echo "================================================================"

# Counter for successful reads and non-zero values
success_count=0
non_zero_count=0

# Read each line from the file and check the PV value
while IFS= read -r pv_name; do
    # Skip empty lines
    if [ -z "$pv_name" ]; then
        continue
    fi
    
    # Remove any leading/trailing whitespace
    pv_name=$(echo "$pv_name" | xargs)
    
    # Get the PV value using caget with numeric output
    # -n flag for numeric value, -t flag for timeout, -w flag for wait
    pv_value=$(caget -n -t -w 1.0 "$pv_name" 2>/dev/null)
    
    # Check if caget was successful
    if [ $? -eq 0 ]; then
        # For caget -n, the output is just the numeric value
        value=$(echo "$pv_value" | tr -d ' ')
        
        ((success_count++))
        
        # Count non-zero values and print only those
        if [ "$value" != "0" ]; then
            echo "$pv_name = $value"
            ((non_zero_count++))
        fi
    else
        echo "ERROR: Could not read PV $pv_name"
    fi
done < "mediaSeverity.STATUSEXT"

echo "================================================================"
echo "Summary: Successfully read $success_count PV(s)"
echo "Non-zero PV values: $non_zero_count"
echo "Script completed." 