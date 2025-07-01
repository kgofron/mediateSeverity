#!/bin/bash

# Script to check EPICS PVs and print non-zero values
# Usage: ./check_pv_severity.sh [OPTIONS]
# Options:
#   -f FILE    Use specified file containing PV names (default: mediaSeverity.STATUSEXT)
#   -d         Dynamically discover STATUSEXT PVs from EPICS applications
#   -h         Show this help message

# Default values
pv_file="mediaSeverity.STATUSEXT"
dynamic_discovery=false

# Parse command line arguments
while getopts "f:dh" opt; do
    case $opt in
        f) pv_file="$OPTARG" ;;
        d) dynamic_discovery=true ;;
        h) 
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -f FILE    Use specified file containing PV names (default: mediaSeverity.STATUSEXT)"
            echo "  -d         Dynamically discover STATUSEXT PVs from EPICS applications"
            echo "  -h         Show this help message"
            exit 0
            ;;
        \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
    esac
done

# Function to dynamically discover STATUSEXT PVs
discover_statusext_pvs() {
    # Convert BL environment variable to lowercase for path
    beamline=$(echo "$BL" | awk '{print tolower($0)}')
    
    echo "Discovering STATUSEXT PVs from EPICS applications..." >&2
    echo "Using beamline path: /home/controls/$beamline/applications" >&2
    
    grep -r :STATUSEXT /home/controls/$beamline/applications 2>/dev/null | grep record | cut -f2 -d" " | sed 's/\"//g' | sed 's/)//g' | sort -u
}

# Check if using dynamic discovery or file
if [ "$dynamic_discovery" = true ]; then
    # Check if BL environment variable is set
    if [ -z "$BL" ]; then
        echo "Error: BL environment variable not set. Please set BL to your beamline name (e.g., export BL=BL11A)"
        exit 1
    fi
    
    echo "Using dynamic discovery of STATUSEXT PVs..."
    pv_list=$(discover_statusext_pvs)
    if [ -z "$pv_list" ]; then
        echo "Error: No STATUSEXT PVs found or unable to access EPICS applications directory"
        exit 1
    fi
else
    # Check if the file exists
    if [ ! -f "$pv_file" ]; then
        echo "Error: $pv_file file not found in current directory"
        exit 1
    fi
fi

# Check if caget is available
if ! command -v caget &> /dev/null; then
    echo "Error: caget command not found. Please ensure EPICS tools are installed and in PATH"
    exit 1
fi

if [ "$dynamic_discovery" = true ]; then
    echo "Checking dynamically discovered EPICS PVs for non-zero values..."
else
    echo "Checking EPICS PVs in $pv_file for non-zero values..."
fi
echo "================================================================"

# Counter for successful reads and non-zero values
success_count=0
non_zero_count=0

# Process PVs based on mode
if [ "$dynamic_discovery" = true ]; then
    # Process dynamically discovered PVs
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
    done <<< "$pv_list"
else
    # Process PVs from file
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
    done < "$pv_file"
fi

echo "================================================================"
echo "Summary: Successfully read $success_count PV(s)"
echo "Non-zero PV values: $non_zero_count"
echo "Script completed." 