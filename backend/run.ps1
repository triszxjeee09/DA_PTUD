$ErrorActionPreference = 'Stop'
$backendDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $backendDir
$firebaseKey = Join-Path $env:LOCALAPPDATA 'AnTamPharma\firebase-service-account.json'
if (Test-Path -LiteralPath $firebaseKey) {
    $env:FIREBASE_SERVICE_ACCOUNT_FILE = $firebaseKey
}
python app.py
