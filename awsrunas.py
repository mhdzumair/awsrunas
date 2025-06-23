#!/usr/bin/env python3
 
import argparse
import json
from json.decoder import JSONDecodeError
from os import path
import subprocess
from datetime import datetime, timezone
import re
 
 
def runas(profile, options):
    try:
        shell_response = subprocess.run(["aws-runas", "-O", "json", *options, profile], capture_output=True)
    except FileNotFoundError:
        print("aws-runas not found in system. check the installation guide: https://mmmorris1975.github.io/aws-runas/quickstart.html")
        raise SystemExit(1)
    try:
        credential = json.loads(shell_response.stdout)
    except JSONDecodeError:
        print(shell_response.stderr.decode())
        raise SystemExit(1)
    return credential


def parse_iso8601_datetime(date_string):
    """Parse ISO 8601 datetime string without external dependencies"""
    # Remove 'Z' suffix and replace with '+00:00' for UTC
    if date_string.endswith('Z'):
        date_string = date_string[:-1] + '+00:00'
    
    # Handle different ISO 8601 formats
    # Format: 2024-01-15T10:30:45+00:00 or 2024-01-15T10:30:45.123+00:00
    pattern = r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.(\d+))?([+-]\d{2}):?(\d{2})$'
    match = re.match(pattern, date_string)
    
    if not match:
        # Try simpler format without timezone
        pattern = r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.(\d+))?$'
        match = re.match(pattern, date_string)
        if match:
            year, month, day, hour, minute, second, microsecond = match.groups()
            microsecond = int((microsecond or '0').ljust(6, '0')[:6])
            return datetime(int(year), int(month), int(day), int(hour), int(minute), int(second), microsecond, timezone.utc)
        else:
            raise ValueError(f"Unable to parse datetime: {date_string}")
    
    year, month, day, hour, minute, second, microsecond, tz_hour, tz_minute = match.groups()
    
    # Handle microseconds
    microsecond = int((microsecond or '0').ljust(6, '0')[:6])
    
    # Create timezone offset
    tz_offset_hours = int(tz_hour)
    tz_offset_minutes = int(tz_minute)
    if tz_offset_hours < 0:
        tz_offset_minutes = -tz_offset_minutes
    
    total_offset_minutes = tz_offset_hours * 60 + tz_offset_minutes
    tz_offset = timezone(datetime.timedelta(minutes=total_offset_minutes))
    
    return datetime(int(year), int(month), int(day), int(hour), int(minute), int(second), microsecond, tz_offset)


def parse_credential(credential, to_env=False):
    expiration = credential["Expiration"]
    try:
        expiration_dt = parse_iso8601_datetime(expiration)
        remaining_time = expiration_dt - datetime.now(tz=timezone.utc)
    except (ValueError, TypeError) as e:
        print(f"Warning: Could not parse expiration time '{expiration}': {e}")
        remaining_time = None
    
    key_id = credential['AccessKeyId']
    access_key = credential['SecretAccessKey']
    security_key = credential['SessionToken']
    
    if to_env:
        print(f'''\
export AWS_ACCESS_KEY_ID="{key_id}"
export AWS_SECRET_ACCESS_KEY="{access_key}"
export AWS_SECURITY_TOKEN="{security_key}"''')
    else:
        # Ensure .aws directory exists
        aws_dir = path.expanduser("~/.aws")
        if not path.exists(aws_dir):
            import os
            os.makedirs(aws_dir, exist_ok=True)
        
        credentials_file = path.join(aws_dir, "credentials")
        with open(credentials_file, "w") as file:
            file.write(f"""[default]
aws_access_key_id={key_id}
aws_secret_access_key={access_key}
aws_security_token={security_key}""")
        
        if remaining_time is not None:
            print(f"aws credentials stored to ~/.aws/credentials. session remaining time: {remaining_time}")
        else:
            print("aws credentials stored to ~/.aws/credentials.")
 
 
if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='aws-runas utility script to parse & setup aws credentials'
    )
    parser.add_argument('profile', type=str, help='AWS account profile name')
    parser.add_argument('-e', '--env', action='store_true',
                        help='if provided, credentials will print for env export. else store to ~/.aws/credentials')
    parser.add_argument('-o', '--run-as-options', default="", help="aws-runas options to pass")
    args = parser.parse_args()
 
    runas_options = args.run_as_options.split()
    parse_credential(runas(args.profile, runas_options), args.env)
