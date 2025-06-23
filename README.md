# awsrunas

AWS-runas utility scripts to parse & setup AWS credentials. Choose your platform! :sunglasses:

## Requirements

- Setup [aws-runas](https://mmmorris1975.github.io/aws-runas/quickstart.html)
- **Windows**: PowerShell 5.1+ (built-in on Windows 10+)
- **Linux/macOS**: `jq` package (`sudo apt install jq` or `brew install jq`)
- **All platforms**: Python 3.6+ (optional, uses built-in libraries only)

## Quick Setup

### Windows (PowerShell)
```powershell
# Download script
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/mhdzumair/awsrunas/main/awsrunas.ps1" -OutFile "awsrunas.ps1"

# Allow script execution
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Ready to use!
.\awsrunas.ps1 my-account
```

### Linux/macOS (Bash)
```bash
# Download and setup
curl -o awsrunas.sh https://raw.githubusercontent.com/mhdzumair/awsrunas/main/awsrunas.sh
chmod +x awsrunas.sh

# Ready to use!
./awsrunas.sh my-account
```

### Python (All platforms)
```bash
# Download
curl -o awsrunas.py https://raw.githubusercontent.com/mhdzumair/awsrunas/main/awsrunas.py
# or
wget https://raw.githubusercontent.com/mhdzumair/awsrunas/main/awsrunas.py

# Make executable (Linux/macOS)
chmod +x awsrunas.py

# Ready to use!
python3 awsrunas.py my-account
```

## Usage

All scripts have the same functionality:

```bash
# Store credentials to ~/.aws/credentials (or %USERPROFILE%\.aws\credentials on Windows)
script my-account

# Export to environment variables
script my-account -e    # or --env

# Pass options to aws-runas
script my-account -o "-a 8h -r"    # or --run-as-options
```

### Examples

**Store credentials:**
```bash
# Windows
.\awsrunas.ps1 my-prod-account

# Linux/macOS
./awsrunas.sh my-prod-account

# Python (any platform)
python3 awsrunas.py my-prod-account
```

**Export to environment:**
```bash
# Windows (copy and paste output)
.\awsrunas.ps1 my-prod-account -Env

# Linux/macOS
eval $(./awsrunas.sh my-prod-account --env)

# Python
eval $(python3 awsrunas.py my-prod-account --env)
```

**With aws-runas options:**
```bash
# Assume role for 8 hours with refresh
.\awsrunas.ps1 my-account -RunAsOptions "-a 8h -r"     # Windows
./awsrunas.sh my-account -o "-a 8h -r"                 # Linux/macOS  
python3 awsrunas.py my-account -o "-a 8h -r"           # Python
```

## Optional: Add to PATH

**Windows:**
```powershell
# Copy to PowerShell Scripts directory
$scriptsPath = "$env:USERPROFILE\Documents\PowerShell\Scripts"
New-Item -Path $scriptsPath -Type Directory -Force
Move-Item awsrunas.ps1 $scriptsPath
# Then use: awsrunas my-account
```

**Linux/macOS:**
```bash
# Symlink to local bin
ln -s $(pwd)/awsrunas.sh ~/.local/bin/awsrunas
# or for Python
ln -s $(pwd)/awsrunas.py ~/.local/bin/awsrunas
# Then use: awsrunas my-account
```

That's it! Choose your preferred script and start using AWS credentials easily.
