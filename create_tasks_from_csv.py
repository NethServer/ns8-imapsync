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
MANDATORY_FIELDS = {'localusername', 'remoteusername', 'remotepassword', 'remotehostname', 'remoteport'}
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


def validate_and_load_csv(csv_file: str, delimiter: str) -> Tuple[bool, list, str]:
    """Validate CSV columns and load all rows in a single pass"""
    try:
        with open(csv_file, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f, delimiter=delimiter)
            
            if reader.fieldnames is None:
                print("✗ Error: CSV file is empty or invalid")
                return False, [], delimiter
            
            csv_columns = set(reader.fieldnames)
            missing = REQUIRED_COLUMNS - csv_columns
            
            print(f"\n📋 CSV Column Validation:")
            print(f"   Delimiter detected: '{delimiter}'")
            print(f"   Found {len(csv_columns)} column(s): {', '.join(sorted(csv_columns))}")
            print(f"   Column order: does not matter (mapped by header name)")
            
            if missing:
                print(f"\n✗ Missing {len(missing)} required column(s):")
                for col in sorted(missing):
                    print(f"   - {col}")
                return False, [], delimiter
            
            print(f"✓ All {len(REQUIRED_COLUMNS)} required columns present")
            
            # Load all rows at once, filtering empty lines
            rows = []
            for row in reader:
                # Skip empty rows (all values are empty or whitespace)
                if all(not value.strip() for value in row.values()):
                    continue
                rows.append(row)
            
            print(f"✓ Found {len(rows)} data row(s) (empty lines skipped)")
            return True, rows, delimiter
    
    except FileNotFoundError:
        print(f"✗ Error: File '{csv_file}' not found")
        return False, [], delimiter
    except Exception as e:
        print(f"✗ Error reading CSV ({type(e).__name__}): {str(e)}")
        return False, [], delimiter


def parse_csv_row(row: dict, existing_ids: set) -> dict:
    """Parse CSV row and return task data dictionary"""
    task_data = DEFAULT_TASK_DATA.copy()
    
    # Generate unique task ID (retry if collision)
    max_attempts = 100
    for _ in range(max_attempts):
        task_id = generate_random_id()
        if task_id not in existing_ids:
            existing_ids.add(task_id)
            task_data['task_id'] = task_id
            break
    else:
        raise RuntimeError(f"Failed to generate unique task ID after {max_attempts} attempts")
    
    # Check mandatory fields are not empty
    missing_values = []
    for field in MANDATORY_FIELDS:
        if field not in row or not row[field].strip():
            missing_values.append(field)
    
    if missing_values:
        raise ValueError(f"Missing required value(s): {', '.join(sorted(missing_values))}")
    
    # Parse and populate fields
    for csv_key, json_key in COLUMN_MAPPING.items():
        if csv_key not in row:
            continue
        
        value = row[csv_key].strip()
        
        # Security can be empty (no encryption)
        if not value and csv_key != 'security':
            continue
        
        if json_key == 'remoteport':
            try:
                task_data[json_key] = int(value)
            except ValueError:
                raise ValueError(f"Invalid port number: '{value}'")
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
    
    # Validate and load CSV in a single pass
    print(f"Validating CSV file: {csv_file}")
    delimiter = detect_delimiter(csv_file)
    is_valid, rows, delimiter = validate_and_load_csv(csv_file, delimiter)
    
    if not is_valid:
        sys.exit(1)
    
    if check_only:
        print("\n🔍 Validating row data...")
        validation_errors = 0
        existing_ids = set()
        
        for idx, row in enumerate(rows, start=1):
            try:
                parse_csv_row(row, existing_ids)
            except ValueError as e:
                print(f"  ✗ Row {idx}: {str(e)}")
                validation_errors += 1
            except Exception as e:
                print(f"  ✗ Row {idx}: Unexpected error - {str(e)}")
                validation_errors += 1
        
        if validation_errors > 0:
            print(f"\n✗ Validation failed: {validation_errors} row(s) with errors")
            sys.exit(1)
        
        print(f"✓ All {len(rows)} rows validated successfully")
        print(f"✓ Generated {len(existing_ids)} unique task IDs")
        print("\n✓ CSV file is valid. No tasks were created (check-only mode).")
        sys.exit(0)
    
    # Process tasks
    print(f"\n📦 Starting task creation with module: {module_id}")
    print(f"   Processing {len(rows)} user(s)...\n")
    
    successful = 0
    failed = 0
    existing_ids = set()
    
    for idx, row in enumerate(rows, start=1):
        try:
            task_data = parse_csv_row(row, existing_ids)
            if create_task(module_id, task_data):
                successful += 1
            else:
                failed += 1
        except KeyError as e:
            print(f"✗ Missing field {e} on row {idx}")
            failed += 1
        except ValueError as e:
            print(f"✗ Invalid value on row {idx}: {str(e)}")
            failed += 1
        except Exception as e:
            print(f"✗ Unexpected error on row {idx}: {str(e)}")
            failed += 1
        print()
    
    # Summary
    print("=" * 70)
    print(f"📊 Summary: {successful} successful, {failed} failed")
    print("=" * 70)
    
    sys.exit(1 if failed > 0 else 0)


if __name__ == "__main__":
    main()
