#!/usr/bin/env python3
 
import argparse
import json
from json.decoder import JSONDecodeError
from os import path
import subprocess
from datetime import datetime, timezone
from dateutil import parser as date_parser
 
 
def runas(profile, options):
    if not path.exists(path.expanduser("~/.aws/.aws_runas.cookies")):
        print("aws-runas cookies file not found. run 'aws-runas' command to initialize authentication.")
        raise SystemExit(1)
    
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
 
 
def parse_credential(credential, to_env=False):
    expiration = credential["Expiration"]
    remaining_time = date_parser.parse(expiration) - datetime.now(tz=timezone.utc)
    print(f"session remaining time: {remaining_time}")
    key_id = credential['AccessKeyId']
    access_key = credential['SecretAccessKey']
    security_key = credential['SessionToken']
    if to_env:
        print(f'''\
export AWS_ACCESS_KEY_ID="{key_id}"
export AWS_SECRET_ACCESS_KEY="{access_key}"
export AWS_SECURITY_TOKEN="{security_key}"''')
    else:
        with open(path.expanduser("~/.aws/credentials"), "w") as file:
            file.write(f"""[default]
aws_access_key_id={key_id}
aws_secret_access_key={access_key}
aws_security_token={security_key}""")
 
 
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