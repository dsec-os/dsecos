# bootstrap.ps1 – Windows native (runs WSL if needed)
$repo = "https://github.com/dsec-os/dsecos.git"
$dir  = "$env:USERPROFILE\dsecos"

Write-Host "Setting up DsecOS in $dir ..." -ForegroundColor Green

# Install WSL + Debian if missing
if (!(wsl -l | Select-String "Debian")) {
    Write-Host "Installing WSL2 + Debian..."
    wsl --install -d Debian
    Write-Host "Please restart terminal and re-run this script" -ForegroundColor Yellow
    exit
}

# Clone inside WSL
wsl -d Debian bash -c @"
cd ~
if [ ! -d dsecos ]; then
  git clone $repo dsecos
fi
cd dsecos
curl -fsSL https://raw.githubusercontent.com/dsec-os/dsecos/main/bootstrap.sh | bash
"@

Write-Host "Done! Open WSL Debian and run: cd ~/dsecos && ./build.sh" -ForegroundColor Cyan
