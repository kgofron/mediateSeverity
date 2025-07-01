#!/bin/bash

# Script to check EPICS PVs in mediaSeverity.STATUSEXT file and print those with non-zero values
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

echo "Checking EPICS PVs in mediaSeverity.STATUSEXT for non-zero values..."
echo "================================================================"

# Counter for non-zero PVs
non_zero_count=0

# Read each line from the file and check the PV value
while IFS= read -r pv_name; do
    # Skip empty lines
    if [ -z "$pv_name" ]; then
        continue
    fi
    
    # Remove any leading/trailing whitespace
    pv_name=$(echo "$pv_name" | xargs)
    
    # Get the PV value using caget
    # -t flag for timeout, -w flag for wait, -d flag for data type
    pv_value=$(caget -t -w 1.0 "$pv_name" 2>/dev/null)
    
    # Check if caget was successful
    if [ $? -eq 0 ]; then
        # Extract just the value (remove PV name and timestamp)
        value=$(echo "$pv_value" | awk '{print $2}')
        
        # Check if value is numeric and non-zero
        if [[ "$value" =~ ^[0-9]+\.?[0-9]*$ ]] && [ "$(echo "$value != 0" | bc -l 2>/dev/null)" -eq 1 ]; then
            echo "NON-ZERO: $pv_name = $value"
            ((non_zero_count++))
        fi
    else
        echo "ERROR: Could not read PV $pv_name"
    fi
done < "mediaSeverity.STATUSEXT"

echo "================================================================"
echo "Summary: Found $non_zero_count PV(s) with non-zero values"
echo "Script completed." 