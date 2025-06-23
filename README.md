# awsrunas

AWS-runas utility scripts to parse & setup AWS credentials. Available in Python, PowerShell, and Bash to make your life easier across different platforms! :sunglasses:

## Requirements

- Setup [aws-runas](https://mmmorris1975.github.io/aws-runas/quickstart.html)
- **For Bash version**: `jq` command-line JSON processor
  ```bash
  # Ubuntu/Debian
  sudo apt install jq
  # macOS
  brew install jq
  # RHEL/CentOS/Fedora
  sudo yum install jq  # or dnf install jq
  ```
- **For Python version**: `python-dateutil` package
  ```bash
  pip install python-dateutil
  ```

## Setup

```bash
git clone https://github.com/mhdzumair/awsrunas.git
cd awsrunas
```

### Choose Your Preferred Version

#### Option 1: Python Script (Original)
```bash
# Make executable and symlink to local bin
chmod +x awsrunas.py
ln -s $(pwd)/awsrunas.py ~/.local/bin/awsrunas
```

#### Option 2: PowerShell Script (Cross-platform)
```bash
# Make executable
chmod +x awsrunas.ps1

# Create wrapper script for easier usage
cat > ~/.local/bin/awsrunas << 'EOF'
#!/bin/bash
pwsh "$(dirname "$(readlink -f "$0")")/../path/to/awsrunas.ps1" "$@"
EOF
chmod +x ~/.local/bin/awsrunas
```

Or use directly:
```powershell
# Windows PowerShell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### Option 3: Bash Script (Linux/macOS)
```bash
# Make executable and symlink to local bin
chmod +x awsrunas.sh
ln -s $(pwd)/awsrunas.sh ~/.local/bin/awsrunas
```

## Usage

### Python Version
```bash
# See script help
awsrunas -h

# Setup ~/.aws/credentials file
awsrunas my-account

# Export to current shell environment  
eval $(awsrunas -e my-account)

# Run with aws-runas options
awsrunas my-account -o "-a 8h -r"
```

### PowerShell Version
```powershell
# See script help
./awsrunas.ps1 -?

# Setup credentials file (~/.aws/credentials or %USERPROFILE%\.aws\credentials)
./awsrunas.ps1 my-account

# Export to environment variables (copy and paste output)
./awsrunas.ps1 my-account -Env

# Run with aws-runas options
./awsrunas.ps1 my-account -RunAsOptions "-a 8h -r"
```

### Bash Version
```bash
# See script help
./awsrunas.sh --help

# Setup ~/.aws/credentials file
./awsrunas.sh my-account

# Export to current shell environment
eval $(./awsrunas.sh my-account --env)

# Run with aws-runas options
./awsrunas.sh my-account -o "-a 8h -r"
```

## Command Line Arguments

| Argument | Python | PowerShell | Bash | Description |
|----------|--------|------------|------|-------------|
| Profile | `profile` | `Profile` | `profile` | AWS account profile name (required) |
| Environment Export | `-e, --env` | `-Env` | `-e, --env` | Export credentials as environment variables instead of storing to file |
| RunAs Options | `-o, --run-as-options` | `-RunAsOptions` | `-o, --run-as-options` | Additional options to pass to aws-runas command |
| Help | `-h, --help` | `-?` | `-h, --help` | Show help message |

## Examples

### Store credentials to AWS credentials file:
```bash
# Python
awsrunas my-prod-account

# PowerShell  
./awsrunas.ps1 my-prod-account

# Bash
./awsrunas.sh my-prod-account
```

### Export to environment variables:
```bash
# Python
eval $(awsrunas -e my-prod-account)

# PowerShell (manual export)
./awsrunas.ps1 my-prod-account -Env
# Then copy and paste the output

# Bash
eval $(./awsrunas.sh my-prod-account --env)
```

### Use with aws-runas options:
```bash
# Python - assume role for 8 hours with refresh
awsrunas my-account -o "-a 8h -r"

# PowerShell - same functionality
./awsrunas.ps1 my-account -RunAsOptions "-a 8h -r"

# Bash - same functionality  
./awsrunas.sh my-account -o "-a 8h -r"
```

## Platform Compatibility

| Feature | Python | PowerShell | Bash |
|---------|--------|------------|------|
| Windows | ✅ | ✅ | ✅ (WSL/Git Bash) |
| macOS | ✅ | ✅ | ✅ |
| Linux | ✅ | ✅ | ✅ |
| Dependencies | python-dateutil | None (built-in) | jq |
| JSON Parsing | Built-in | Built-in | jq |
| Date Calculation | python-dateutil | Built-in | Basic (date command) |

## Notes

- All versions create the `~/.aws` directory automatically if it doesn't exist
- The PowerShell version works cross-platform with PowerShell Core 6+
- The Bash version provides basic time calculation for session duration
- Credentials are stored in the `[default]` profile section
- Environment variable export allows temporary credential usage without modifying files
