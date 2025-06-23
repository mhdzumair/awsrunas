#!/usr/bin/env pwsh

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Profile,
    
    [Parameter(Mandatory = $false)]
    [switch]$Env,
    
    [Parameter(Mandatory = $false)]
    [string]$RunAsOptions = ""
)

function Invoke-RunAs {
    param(
        [string]$Profile,
        [array]$Options
    )
    
    try {
        $command = @("aws-runas", "-O", "json") + $Options + @($Profile)
        $result = & $command[0] $command[1..($command.Length - 1)] 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "aws-runas command failed: $result"
            exit 1
        }
        
        return $result | Out-String
    }
    catch {
        Write-Error "aws-runas not found in system. Check the installation guide: https://mmmorris1975.github.io/aws-runas/quickstart.html"
        exit 1
    }
}

function Parse-Credential {
    param(
        [string]$CredentialJson,
        [bool]$ToEnv = $false
    )
    
    try {
        $credential = $CredentialJson | ConvertFrom-Json
    }
    catch {
        Write-Error "Failed to parse JSON response from aws-runas"
        exit 1
    }
    
    $expiration = [DateTime]::Parse($credential.Expiration)
    $remainingTime = $expiration - [DateTime]::UtcNow
    $keyId = $credential.AccessKeyId
    $accessKey = $credential.SecretAccessKey
    $securityKey = $credential.SessionToken
    
    if ($ToEnv) {
        Write-Output "export AWS_ACCESS_KEY_ID=`"$keyId`""
        Write-Output "export AWS_SECRET_ACCESS_KEY=`"$accessKey`""
        Write-Output "export AWS_SECURITY_TOKEN=`"$securityKey`""
    }
    else {
        # Use proper Windows path separators
        $awsDir = Join-Path $env:USERPROFILE ".aws"
        $credentialsPath = Join-Path $awsDir "credentials"
        
        # Ensure .aws directory exists
        if (!(Test-Path $awsDir)) {
            New-Item -ItemType Directory -Path $awsDir -Force | Out-Null
        }
        
        $credentialsContent = @"
[default]
aws_access_key_id=$keyId
aws_secret_access_key=$accessKey
aws_session_token=$securityKey
"@
        
        # Write without BOM using UTF8NoBomEncoding
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($credentialsPath, $credentialsContent, $utf8NoBom)
        
        Write-Output "AWS credentials stored to $credentialsPath. Session remaining time: $remainingTime"
    }
}

# Main execution
if ([string]::IsNullOrWhiteSpace($RunAsOptions)) {
    $runAsOptionsArray = @()
}
else {
    $runAsOptionsArray = $RunAsOptions -split '\s+'
}

$credentialJson = Invoke-RunAs -Profile $Profile -Options $runAsOptionsArray
Parse-Credential -CredentialJson $credentialJson -ToEnv $Env.IsPresent
