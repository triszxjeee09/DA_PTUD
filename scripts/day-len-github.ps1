<#
  Commit + push toàn bộ thay đổi lên nhánh feature trên GitHub.
  Dùng:   powershell -ExecutionPolicy Bypass -File scripts\day-len-github.ps1 "mô tả thay đổi"
  (không điền mô tả thì tự đặt theo ngày giờ)
  Lần đầu GitHub sẽ mở cửa sổ đăng nhập (Git Credential Manager) - đăng nhập tài khoản triszxjeee09.
#>
param([string]$Message = "")
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) '..')

$branch = 'feature/hoan-thien-tinh-nang'
$remote = 'https://github.com/triszxjeee09/DA_PTUD.git'

if (-not (git remote | Select-String -Quiet '^origin$')) { git remote add origin $remote }
git remote set-url origin $remote

# chuyển/tạo nhánh
$current = git branch --show-current
if ($current -ne $branch) {
    if (git branch --list $branch) { git checkout $branch } else { git checkout -b $branch }
}

git add -A
if (git status --porcelain) {
    if (-not $Message) { $Message = 'Cap nhat ' + (Get-Date -Format 'yyyy-MM-dd HH:mm') }
    git -c user.name='DucTri' -c user.email='ductri@antam.local' commit -m $Message
} else {
    Write-Host 'Khong co thay doi moi de commit.'
}

git push -u origin $branch
Write-Host "Da day len: $remote (nhanh $branch)"
