#!/usr/bin/env python3
"""
IMAPSYNC Bulk User Import Tool - Create multiple sync tasks from CSV
"""

import csv
import json
import subprocess
import string
import random
import sys
from typing import Optional, Tuple


# Configuration constants
DELIMITERS = [';', ',', '\t', '|']
DEFAULT_DELIMITER = ';'
REQUIRED_COLUMNS = {
    'localusername', 'remoteusername', 'remotepassword',
    'remotehostname', 'remoteport', 'security'
}
COLUMN_MAPPING = {
    'localusername': 'localuser',
    'remoteusername': 'remoteusername',
    'remotepassword': 'remotepassword',
    'remotehostname': 'remotehostname',
    'remoteport': 'remoteport',
    'security': 'security',
}
DEFAULT_TASK_DATA = {
    'cron': '',
    'delete_local': False,
    'delete_remote': False,
    'delete_remote_older': 0,
    'exclude': '',
    'foldersynchronization': 'all',
    'sieve_enabled': False,
}


def detect_delimiter(csv_file: str) -> str:
    """Auto-detect the CSV delimiter from first line"""
    try:
        with open(csv_file, 'r', encoding='utf-8') as f:
            first_line = f.readline()
            for delimiter in DELIMITERS:
                if first_line.count(delimiter) >= 2:
                    return delimiter
        return DEFAULT_DELIMITER
    except Exception:
        return DEFAULT_DELIMITER


def generate_random_id(length: int = 6) -> str:
    """Generate random alphanumeric ID"""
    chars = string.ascii_letters + string.digits
    return ''.join(random.choices(chars, k=length)).lower()


def validate_csv_columns(csv_file: str, delimiter: str) -> Tuple[bool, Optional[int], str]:
    """Validate CSV has all required columns and return row count"""
    try:
        with open(csv_file, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f, delimiter=delimiter)
            
            if reader.fieldnames is None:
                print("✗ Error: CSV file is empty or invalid")
                return False, None, delimiter
            
            csv_columns = set(reader.fieldnames)
            missing = REQUIRED_COLUMNS - csv_columns
            
            print(f"\n📋 CSV Column Validation:")
            print(f"   Delimiter detected: '{delimiter}'")
            print(f"   Found {len(csv_columns)} column(s): {', '.join(sorted(csv_columns))}")
            
            if missing:
                print(f"\n✗ Missing {len(missing)} required column(s):")
                for col in sorted(missing):
                    print(f"   - {col}")
                return False, None, delimiter
            
            print(f"✓ All {len(REQUIRED_COLUMNS)} required columns present")
            row_count = sum(1 for _ in reader)
            print(f"✓ Found {row_count} data row(s)")
            return True, row_count, delimiter
    
    except FileNotFoundError:
        print(f"✗ Error: File '{csv_file}' not found")
        return False, None, delimiter
    except Exception as e:
        print(f"✗ Error reading CSV ({type(e).__name__}): {str(e)}")
        return False, None, delimiter


def parse_csv_row(row: dict) -> dict:
    """Parse CSV row and return task data dictionary"""
    task_data = DEFAULT_TASK_DATA.copy()
    task_data['task_id'] = generate_random_id()
    
    # Validate that all required fields are present and non-empty
    missing_fields = []
    for csv_key in REQUIRED_COLUMNS:
        if csv_key not in row or not row[csv_key] or not row[csv_key].strip():
            missing_fields.append(csv_key)
    
    if missing_fields:
        raise ValueError(f"Required field(s) missing or empty: {', '.join(sorted(missing_fields))}")
    
    # Map CSV columns to task data fields
    for csv_key, json_key in COLUMN_MAPPING.items():
        value = row[csv_key]
        if json_key == 'remoteport':
            try:
                task_data[json_key] = int(value)
            except ValueError:
                raise ValueError(f"Invalid port number: {value}")
        else:
            task_data[json_key] = value
    
    return task_data


def create_task(module_id: str, task_data: dict) -> bool:
    """Create a task via API call"""
    json_data = json.dumps(task_data)
    cmd = ['api-cli', 'run', f'module/{module_id}/create-task', '--data', json_data]
    local_user = task_data.get('localuser', 'unknown')
    task_id = task_data.get('task_id', 'unknown')
    
    print(f"Creating task for {local_user} (ID: {task_id})...")
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        print(f"✓ Success: {local_user}")
        if result.stdout:
            print(f"  Response: {result.stdout.strip()}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"✗ Error for {local_user}")
        if e.stderr:
            print(f"  Error: {e.stderr.strip()}")
        return False
    except FileNotFoundError:
        print("✗ Error: The 'api-cli' command was not found")
        print("  Make sure api-cli is installed and in the PATH")
        return False


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
    pansy.dumbledore5;user1@domain.com;"quotedPassword";smtp.domain.com;993;ssl
    lavender.umbridge7;user2@domain.com;"quotedPassword";smtp.domain.com;993;ssl

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
    - Ensure 'api-cli' command is installed and available in PATH
    - Check that all 6 required columns are present in the CSV header
    - Verify the module_id matches an existing imapsync module
    - Make sure remoteport values are numeric (e.g., 993, 143)
    - Verify security values are valid (ssl, tls, empty '')
    """
    print(help_text)

def main():
    """Main entry point"""
    args = sys.argv[1:]
    
    # Handle help flags
    if not args or args[0] in ['-h', '--help']:
        print_help()
        sys.exit(0)
    
    # Handle check flag
    check_only = False
    if args[0] in ['-c', '--check']:
        check_only = True
        if len(args) < 3:
            print("Usage: python3 create_tasks_from_csv.py -c <module_id> <csv_file>")
            sys.exit(1)
        module_id, csv_file = args[1], args[2]
    else:
        if len(args) < 2:
            print("Usage: python3 create_tasks_from_csv.py <module_id> <csv_file>")
            print("       python3 create_tasks_from_csv.py -h")
            sys.exit(1)
        module_id, csv_file = args[0], args[1]
    
    # Validate CSV
    print(f"Validating CSV file: {csv_file}")
    delimiter = detect_delimiter(csv_file)
    is_valid, row_count, delimiter = validate_csv_columns(csv_file, delimiter)
    
    if not is_valid:
        sys.exit(1)
    
    if check_only:
        print("\n✓ CSV file is valid. No tasks were created (check-only mode).")
        sys.exit(0)
    
    # Process tasks
    print(f"\n📦 Starting task creation with module: {module_id}")
    print(f"   Processing {row_count} user(s)...\n")
    
    successful = 0
    failed = 0
    
    try:
        with open(csv_file, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f, delimiter=delimiter)
            for row_num, row in enumerate(reader, start=2):
                try:
                    task_data = parse_csv_row(row)
                    if create_task(module_id, task_data):
                        successful += 1
                    else:
                        failed += 1
                except KeyError as e:
                    print(f"✗ Missing field {e} on line {row_num}")
                    failed += 1
                except ValueError as e:
                    print(f"✗ Invalid value on line {row_num}: {str(e)}")
                    failed += 1
                except Exception as e:
                    print(f"✗ Unexpected error on line {row_num}: {str(e)}")
                    failed += 1
                print()
        
        # Summary
        print("=" * 70)
        print(f"📊 Summary: {successful} successful, {failed} failed")
        print("=" * 70)
        
        sys.exit(1 if failed > 0 else 0)
    
    except Exception as e:
        print(f"✗ Error reading CSV: {str(e)}")
        sys.exit(1)


if __name__ == "__main__":
    main()
