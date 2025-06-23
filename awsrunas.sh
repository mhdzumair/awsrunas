#!/bin/bash

# Function to display usage
usage() {
    echo "Usage: $0 <profile> [-e|--env] [-o|--run-as-options <options>]"
    echo "  profile              AWS account profile name"
    echo "  -e, --env           If provided, credentials will print for env export, else store to ~/.aws/credentials"
    echo "  -o, --run-as-options AWS-runas options to pass"
    exit 1
}

# Function to run aws-runas and capture output
runas() {
    local profile="$1"
    shift
    local options=("$@")
    
    if ! command -v aws-runas &> /dev/null; then
        echo "aws-runas not found in system. Check the installation guide: https://mmmorris1975.github.io/aws-runas/quickstart.html" >&2
        exit 1
    fi
    
    local output
    local exit_code
    
    output=$(aws-runas -O json "${options[@]}" "$profile" 2>&1)
    exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        echo "$output" >&2
        exit 1
    fi
    
    echo "$output"
}

# Function to parse credentials and handle output
parse_credential() {
    local credential_json="$1"
    local to_env="$2"
    
    # Check if jq is available for JSON parsing
    if ! command -v jq &> /dev/null; then
        echo "Error: jq is required but not installed. Please install jq to parse JSON." >&2
        exit 1
    fi
    
    # Parse JSON using jq
    local key_id access_key security_key expiration
    key_id=$(echo "$credential_json" | jq -r '.AccessKeyId')
    access_key=$(echo "$credential_json" | jq -r '.SecretAccessKey')
    security_key=$(echo "$credential_json" | jq -r '.SessionToken')
    expiration=$(echo "$credential_json" | jq -r '.Expiration')
    
    # Check if parsing was successful
    if [ "$key_id" = "null" ] || [ "$access_key" = "null" ] || [ "$security_key" = "null" ]; then
        echo "Error: Failed to parse credentials from JSON response" >&2
        exit 1
    fi
    
    if [ "$to_env" = "true" ]; then
        echo "export AWS_ACCESS_KEY_ID=\"$key_id\""
        echo "export AWS_SECRET_ACCESS_KEY=\"$access_key\""
        echo "export AWS_SECURITY_TOKEN=\"$security_key\""
    else
        # Create .aws directory if it doesn't exist
        mkdir -p ~/.aws
        
        # Write credentials to file
        cat > ~/.aws/credentials << EOF
[default]
aws_access_key_id=$key_id
aws_secret_access_key=$access_key
aws_security_token=$security_key
EOF
        
        # Calculate remaining time (basic approach)
        if command -v date &> /dev/null; then
            local current_time expiration_time remaining_seconds
            current_time=$(date -u +%s)
            
            # Try to parse the expiration time (ISO 8601 format)
            if command -v gdate &> /dev/null; then
                # Use GNU date if available (macOS with coreutils)
                expiration_time=$(gdate -d "$expiration" +%s 2>/dev/null)
            else
                # Try standard date command
                expiration_time=$(date -d "$expiration" +%s 2>/dev/null)
            fi
            
            if [ -n "$expiration_time" ] && [ "$expiration_time" -gt 0 ]; then
                remaining_seconds=$((expiration_time - current_time))
                local hours minutes seconds
                hours=$((remaining_seconds / 3600))
                minutes=$(((remaining_seconds % 3600) / 60))
                seconds=$((remaining_seconds % 60))
                echo "AWS credentials stored to ~/.aws/credentials. Session remaining time: ${hours}h ${minutes}m ${seconds}s"
            else
                echo "AWS credentials stored to ~/.aws/credentials. (Could not calculate remaining time)"
            fi
        else
            echo "AWS credentials stored to ~/.aws/credentials."
        fi
    fi
}

# Parse command line arguments
profile=""
env_export="false"
run_as_options=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--env)
            env_export="true"
            shift
            ;;
        -o|--run-as-options)
            run_as_options="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        -*)
            echo "Unknown option: $1" >&2
            usage
            ;;
        *)
            if [ -z "$profile" ]; then
                profile="$1"
            else
                echo "Error: Multiple profiles specified" >&2
                usage
            fi
            shift
            ;;
    esac
done

# Check if profile is provided
if [ -z "$profile" ]; then
    echo "Error: Profile is required" >&2
    usage
fi

# Split run_as_options into array
IFS=' ' read -ra options_array <<< "$run_as_options"

# Main execution
credential_json=$(runas "$profile" "${options_array[@]}")
parse_credential "$credential_json" "$env_export"
