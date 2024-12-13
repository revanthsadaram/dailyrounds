#!/bin/bash

# Function to show usage
display_help() {
    echo "Usage: $0 [--interval <seconds>] [--format <text|json|csv>]"
    echo "Default interval is 5 seconds and default format is text."
    exit 1

}

# Check for execute permissions
check_permissions() {
    if [[ ! -x "$0" ]]; then
        echo "Error: You do not have execute permissions for this script."
        exit 1
    fi
}

# Ensure log directory exists
setup_logs() {
    mkdir -p "$LOG_DIR"

    # Backup existing file if present
    if [[ -f "$OUTPUT_FILE" ]]; then
        TIMESTAMP=$(date "+%Y%m%d%H%M%S")
        mv "$OUTPUT_FILE" "$LOG_DIR/$(basename "$OUTPUT_FILE").${TIMESTAMP}"
    fi

    # Remove files older than 5 days
    find "$LOG_DIR" -type f -mtime +5 -exec rm -f {} \;
}

# Check for required commands
check_required_commands() {
    REQUIRED_COMMANDS=("top" "free" "df" "awk" "ps" "find")

    for cmd in "${REQUIRED_COMMANDS[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "Error: Required command '$cmd' is not available. Please install it and ensure it's in your PATH."
            exit 1
        fi
    done
}

# Validate OS compatibility
check_os() {
    SUPPORTED_OS=("Linux" "RHEL" "CentOS" "CentOS Linux")
    OS_NAME=$(cat /etc/os-release | grep -E '^NAME=' | awk -F= '{print $2}' | tr -d '"')

    if [[ ! " ${SUPPORTED_OS[*]} " =~ " $OS_NAME " ]]; then
        echo "Error: Unsupported operating system '$OS_NAME'. This script supports only Linux, RHEL, and CentOS."
        exit 1
    fi
}

# Function to collect system performance data
collect_data() {
    local CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
    local MEM_INFO=$(free -m | awk 'NR==2{printf "%s %s %s", $2, $3, $4}')
    local DISK_INFO=$(df -h --output=source,size,used,avail,pcent | tail -n +2 | awk '{printf "%s,%s,%s,%s,%s\n", $1, $2, $3, $4, $5}')
    local TOP_PROCESSES=$(ps -eo pid,comm,%cpu --sort=-%cpu | awk 'NR>1 && NR<=6 {printf "%s,%s,%s\n", $1, $2, $3}')


    IFS=' ' read -r TOTAL_MEM USED_MEM FREE_MEM <<< "$MEM_INFO"

    echo "$CPU_USAGE" "$TOTAL_MEM" "$USED_MEM" "$FREE_MEM" "$DISK_INFO" "$TOP_PROCESSES"
}

# Function to generate report
generate_report() {
    local CPU=$1
    local TOTAL_MEM=$2
    local USED_MEM=$3
    local FREE_MEM=$4
    local DISK=$5
    local PROCESSES=$6

    if [[ "$FORMAT" == "text" ]]; then
        {
            echo "System Performance Report"
            echo "CPU Usage: $CPU%"
            echo "Memory Usage: Total: ${TOTAL_MEM}MB, Used: ${USED_MEM}MB, Free: ${FREE_MEM}MB"
            echo "Disk Space Usage:"
            echo "$DISK" | awk -F',' '{printf "Filesystem: %s, Size: %s, Used: %s, Available: %s, Usage: %s\n", $1, $2, $3, $4, $5}'
            echo "Top 5 CPU-consuming processes:"
	    echo "$PROCESSES" | sed 's/ $//' | tr ' ' '\n' | awk -F',' '{printf "PID: %-5s Command: %-20s CPU Usage: %-5s%%\n", $1, $2, $3}'
        } > "$OUTPUT_FILE"
    elif [[ "$FORMAT" == "json" ]]; then
        {
            echo "{"
            echo "  \"CPU_Usage\": \"$CPU%\",\n  \"Memory_Usage\": {\"Total\": \"${TOTAL_MEM}MB\", \"Used\": \"${USED_MEM}MB\", \"Free\": \"${FREE_MEM}MB\"},"
            echo "  \"Disk_Usage\": ["
            echo "$DISK" | awk -F',' '{printf "    {\"Filesystem\": \"%s\", \"Size\": \"%s\", \"Used\": \"%s\", \"Available\": \"%s\", \"Usage\": \"%s\"},\n", $1, $2, $3, $4, $5}'
            echo "  ],"
            echo "  \"Top_Processes\": ["
            echo "$PROCESSES" | sed 's/ $//' | tr ' ' '\n' | awk -F',' '{printf "    {\"PID\": \"%s\", \"Command\": \"%s\", \"CPU_Usage\": \"%s%%\"},\n", $1, $2, $3}'
            echo "  ]"
            echo "}"
        } > "$OUTPUT_FILE"
    elif [[ "$FORMAT" == "csv" ]]; then
        {
            echo "Metric,Value"
            echo "CPU_Usage,$CPU%"
            echo "Memory_Usage,Total:${TOTAL_MEM}MB,Used:${USED_MEM}MB,Free:${FREE_MEM}MB"
            echo "$DISK" | awk -F',' '{printf "Disk_Usage,Filesystem=%s,Size=%s,Used=%s,Available=%s,Usage=%s\n", $1, $2, $3, $4, $5}'
            echo "$PROCESSES" | sed 's/ $//' | tr ' ' '\n' | awk -F',' '{printf "Top_Process,PID=%s,Command=%s,CPU_Usage=%s%%\n", $1, $2, $3}'
        } > "$OUTPUT_FILE"
    fi
}

parse_arguments() {
    # Parse arguments
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --interval)
                INTERVAL="$2"
                if ! [[ "$INTERVAL" =~ ^[0-9]+$ ]]; then
                    echo "Error: Interval must be a positive integer."
                    exit 1
                fi
                shift 2
                ;;
            --format)
                FORMAT="${2,,}" # Convert to lowercase
                if [[ "$FORMAT" != "text" && "$FORMAT" != "json" && "$FORMAT" != "csv" ]]; then
                    echo "Error: Invalid format. Use text, json, or csv."
                    exit 1
                fi
                shift 2
                ;;
            --help)
                display_help
                ;;
            *)
                echo "Error: Unknown argument $1"
                display_help
                ;;
        esac
    done
    
    # Set output file based on format
    case "$FORMAT" in
        text)
            OUTPUT_FILE="$LOG_DIR/system_report.txt"
            ;;
        json)
            OUTPUT_FILE="$LOG_DIR/system_report.json"
            ;;
        csv)
            OUTPUT_FILE="$LOG_DIR/system_report.csv"
            ;;
    esac
}


# Default settings
INTERVAL=5
FORMAT="text"
SCRIPT_DIR=$(dirname "$(realpath "$0")")
LOG_DIR="$SCRIPT_DIR/logs"
OUTPUT_FILE="$LOG_DIR/system_report.txt"

# Main execution
parse_arguments "$@"
check_permissions
check_required_commands
check_os
setup_logs

SYSTEM_DATA=$(collect_data)

IFS=' ' read -r CPU_USAGE TOTAL_MEM USED_MEM FREE_MEM DISK_INFO TOP_PROCESSES <<< "$SYSTEM_DATA"

TOP_PROCESSES=$(echo "$SYSTEM_DATA" | grep -oP '\d+,[^\s]+,\d+\.\d+' | tr '\n' ' ')

generate_report "$CPU_USAGE" "$TOTAL_MEM" "$USED_MEM" "$FREE_MEM" "$DISK_INFO" "$TOP_PROCESSES"

