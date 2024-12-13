**System Performance Monitoring Script**

The script collects and generates report system performance data such as CPU usage, memory usage, disk usage, and top CPU-consuming processes. The output can be generated in text, JSON, or CSV formats. 

**Features**

Validates OS compatibility and required commands.

Lists the top 5 CPU-consuming processes.

Outputs data in text, JSON, or CSV formats based on user input.

Handles logging and archival of old reports.

**Requirements**

Currently the scrpit supported OS are Linux.

Make Sure below commands are installed and accessible to the user.

top

free

df

awk

ps

find

**Permissions**

The script requires executable permissions to run. Use the following command to make the script executable:

chmod +x system_monitor.sh

**Usage**

Script can be executed in 2 ways:

./system_monitor.sh

In this case, the time interval is set to "5" seconds and format is set to "text"

and

./system_monitor.sh [--interval <seconds>] [--format <text|json|csv>] [--help]

Arguments

--interval <seconds>

Sets the time interval (in seconds) for monitoring.

Default: 5 seconds.

--format <text|json|csv>

Sets the output format for the report.

Default: text.

Supported formats: text, json, csv.

--help

Displays usage instructions.

Example Commands

Generate a report in text format:

./system_monitor.sh --interval 10 --format text

Generate a report in JSON format:

./system_monitor.sh --format json

Display help:

./system_monitor.sh --help

**Output**

Reports are saved in the logs/ directory within the script's directory. The output file name depends on the selected format:

system_report.txt for text format.

system_report.json for JSON format.

system_report.csv for CSV format.

**Log Management**

Existing reports are archived with a timestamp (e.g., system_report.txt.20240712103045).

Old log files (older than 5 days) are automatically removed.

**Script Functions**

1. Argument Parsing

Parses command-line arguments to set the interval and output format.

2. Permissions Check

Ensures the script has executable permissions.

3. Log Setup

Creates the logs/ directory if it doesn't exist.

Archives old log files and cleans up files older than 5 days.

4. Command Validation

Checks if required commands are available on the system.

5. OS Compatibility

Validates that the operating system is supported.

6. Data Collection

Collects system performance metrics:

CPU usage via top.

Memory usage via free.

Disk usage via df.

Top processes via ps.

7. Report Generation

Generates report based on the user selected format (text, JSON, or CSV).
