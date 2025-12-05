#!/usr/bin/env python3

import csv
import json
import subprocess
import string
import random
import sys
from pathlib import Path

def detect_delimiter(csv_file):
    """Auto-detect the CSV delimiter"""
    delimiters = [';', ',', '\t', '|']
    
    try:
        with open(csv_file, 'r', encoding='utf-8') as f:
            first_line = f.readline()
            
            for delimiter in delimiters:
                if delimiter in first_line:
                    count = first_line.count(delimiter)
                    # Return the first delimiter found with at least 2+ occurrences
                    if count >= 2:
                        return delimiter
            
            # Default to semicolon if no delimiter found
            return ';'
    except Exception:
        return ';'

def generate_random_id(length=6):
    """Generate a random ID of 6 characters"""
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length)).lower()

def print_help():
    """Display help message"""
    help_text = """
╔════════════════════════════════════════════════════════════════════════╗
║          IMAPSYNC Task Creator - Bulk User Import Tool                 ║
╚════════════════════════════════════════════════════════════════════════╝

USAGE:
    python3 create_tasks_from_csv.py <module_id> <csv_file>

ARGUMENTS:
    module_id   : The imapsync module ID (e.g., imapsync1, imapsync2)
    csv_file    : Path to the CSV file with user data

EXAMPLE:
    python3 create_tasks_from_csv.py imapsync1 users.csv

CSV FILE FORMAT:
    - Delimiter: semicolon (;), comma (,), pipe (|), or tab (auto-detected)
    - Required columns: localusername, remoteusername, remotepassword,
                       remotehostname, remoteport, security
    - All required columns must be present in the header row

CSV HEADER EXAMPLE:
    localusername;remoteusername;remotepassword;remotehostname;remoteport;security

CSV DATA EXAMPLE:
    pansy.dumbledore5;user1@domain.com;"enquotedPasswordIfSeparatorInside";smtp.domain.com;993;ssl
    lavender.umbridge7;user2@domain.com;"enquotedPasswordIfSeparatorInside";smtp.domain.com;993;ssl

CREATED FIELDS (auto-populated):
    - task_id              : Random 6-character ID (auto-generated)
    - cron                 : Empty string (for scheduling)
    - delete_local         : false
    - delete_remote        : false
    - delete_remote_older  : 0
    - exclude              : Empty string
    - foldersynchronization: "all"
    - sieve_enabled        : false

API CALL:
    api-cli run module/<module_id>/create-task --data '<json_data>'

OPTIONS:
    -h, --help             : Show this help message
    -c, --check            : Check CSV format without creating tasks

TROUBLESHOOTING:
    - you need to have sufficient permissions to create tasks
    - Ensure 'api-cli' command is installed and available in PATH
    - Check that all 6 required columns are present in the CSV header
    - Verify the module_id matches an existing imapsync module
    - Make sure remoteport values are numeric (e.g., 993, 143)
    - Verify security values are valid (ssl, tls, empty '')
    """
    print(help_text)

def validate_csv_columns(csv_file, delimiter):
    """Check if CSV has all required columns"""
    required_columns = {
        'localusername',
        'remoteusername',
        'remotepassword',
        'remotehostname',
        'remoteport',
        'security'
    }
    
    try:
        with open(csv_file, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f, delimiter=delimiter)
            
            if reader.fieldnames is None:
                print("✗ Error: CSV file is empty or invalid")
                return False, None, delimiter
            
            csv_columns = set(reader.fieldnames)
            missing_columns = required_columns - csv_columns
            
            print(f"\n📋 CSV Column Validation:")
            print(f"   Delimiter detected: '{delimiter}'")
            print(f"   Found {len(csv_columns)} column(s): {', '.join(sorted(csv_columns))}")
            
            if missing_columns:
                print(f"\n✗ Missing {len(missing_columns)} required column(s):")
                for col in sorted(missing_columns):
                    print(f"   - {col}")
                return False, None, delimiter
            else:
                print(f"✓ All {len(required_columns)} required columns present")
                
                # Count data rows
                row_count = sum(1 for _ in reader)
                print(f"✓ Found {row_count} data row(s)")
                
                return True, row_count, delimiter
    
    except FileNotFoundError:
        print(f"✗ Error: File '{csv_file}' not found")
        return False, None, delimiter
    except Exception as e:
        print(f"✗ Error reading CSV: {str(e)}")
        return False, None, delimiter

def parse_csv_line(row):
    """Parse a CSV line and return a dictionary with all required fields"""
    
    # Default values
    task_data = {
        "cron": "",
        "delete_local": False,
        "delete_remote": False,
        "delete_remote_older": 0,
        "exclude": "",
        "foldersynchronization": "all",
        "sieve_enabled": False,
        "task_id": generate_random_id(),
    }
    
    # Mapping of CSV fields to JSON keys
    mapping = {
        'localusername': 'localuser',
        'remoteusername': 'remoteusername',
        'remotepassword': 'remotepassword',
        'remotehostname': 'remotehostname',
        'remoteport': 'remoteport',
        'security': 'security',
    }
    
    # Update with CSV values
    for csv_key, json_key in mapping.items():
        if csv_key in row and row[csv_key]:
            # Convert port to integer
            if json_key == 'remoteport':
                try:
                    task_data[json_key] = int(row[csv_key])
                except ValueError:
                    raise ValueError(f"Invalid port number: {row[csv_key]}")
            else:
                task_data[json_key] = row[csv_key]
    
    return task_data

def create_task(module_id, task_data):
    """Call the API to create a task"""
    
    # Convert dictionary to JSON
    json_data = json.dumps(task_data)
    
    # Build the command
    cmd = ['api-cli', 'run', f'module/{module_id}/create-task', '--data', json_data]
    
    print(f"Creating task for {task_data['localuser']} (ID: {task_data['task_id']})...")
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        print(f"✓ Success: {task_data['localuser']}")
        if result.stdout:
            print(f"  Response: {result.stdout. strip()}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"✗ Error for {task_data['localuser']}")
        if e.stderr:
            print(f"  Error: {e.stderr. strip()}")
        return False
    except FileNotFoundError:
        print("✗ Error: The 'api-cli' command was not found")
        print("  Make sure api-cli is installed and in the PATH")
        return False

def main():
    # Parse command line arguments
    if len(sys.argv) < 2:
        print_help()
        sys.exit(1)
    
    # Handle help flags
    if sys.argv[1] in ['-h', '--help']:
        print_help()
        sys.exit(0)
    
    # Handle check flag
    check_only = False
    if sys.argv[1] in ['-c', '--check']:
        check_only = True
        if len(sys.argv) < 4:
            print("Usage: python3 create_tasks_from_csv.py -c <module_id> <csv_file>")
            sys.exit(1)
        module_id = sys.argv[2]
        csv_file = sys.argv[3]
    else:
        if len(sys.argv) < 3:
            print("Usage: python3 create_tasks_from_csv.py <module_id> <csv_file>")
            print("       python3 create_tasks_from_csv.py -h")
            sys.exit(1)
        module_id = sys. argv[1]
        csv_file = sys.argv[2]
    
    # Auto-detect delimiter
    delimiter = detect_delimiter(csv_file)
    print(f"Validating CSV file: {csv_file}")
    
    # Validate CSV columns
    is_valid, row_count, delimiter = validate_csv_columns(csv_file, delimiter)
    
    if not is_valid:
        sys.exit(1)
    
    if check_only:
        print("\n✓ CSV file is valid.  No tasks were created (check-only mode).")
        sys.exit(0)
    
    # Proceed with creating tasks
    print(f"\n📦 Starting task creation with module: {module_id}")
    print(f"   Processing {row_count} user(s).. .\n")
    
    successful = 0
    failed = 0
    
    try:
        with open(csv_file, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f, delimiter=delimiter)
            
            for row_num, row in enumerate(reader, start=2):
                try:
                    task_data = parse_csv_line(row)
                    if create_task(module_id, task_data):
                        successful += 1
                    else:
                        failed += 1
                except Exception as e:
                    print(f"✗ Error on line {row_num}: {str(e)}")
                    failed += 1
                
                print()
        
        # Summary
        print("=" * 70)
        print(f"📊 Summary: {successful} successful, {failed} failed")
        print("=" * 70)
        
        if failed > 0:
            sys.exit(1)
    
    except Exception as e:
        print(f"✗ Error reading CSV: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()
