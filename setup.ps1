Write-Host "=== Fantasy Terminal Windows Setup ===" -ForegroundColor Cyan

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "Error: winget not found. Please install winget and re-run this script." -ForegroundColor Red
    exit 1
}

Write-Host "`nInstalling LÖVE (Love2d.Love2d) if missing..." -ForegroundColor Yellow
if (-not (Get-Command love -ErrorAction SilentlyContinue)) {
    winget install --source=winget --id=Love2d.Love2d --accept-source-agreements --accept-package-agreements
} else {
    Write-Host "LÖVE already installed." -ForegroundColor Green
}

if (-not (Get-Command love -ErrorAction SilentlyContinue)) {
    $lovePath = "C:\Program Files\LOVE"
    if (Test-Path $lovePath) {
        if ($env:Path -notmatch "LOVE") {
            Write-Host "Adding LÖVE to PATH..." -ForegroundColor Yellow
            setx PATH "$($env:Path);$lovePath" | Out-Null
            Write-Host "LÖVE path added. Restart PowerShell to apply." -ForegroundColor Green
        }
    } else {
        Write-Host "LÖVE not found in default location ($lovePath). Please add it manually." -ForegroundColor Red
    }
} else {
    Write-Host "LÖVE is already in PATH." -ForegroundColor Green
}

Write-Host "`nInstalling LuaJIT and LuaRocks (DEVCOM.LuaJIT)..." -ForegroundColor Yellow
if (-not (Get-Command luajit -ErrorAction SilentlyContinue)) {
    winget install --source=winget --id=DEVCOM.LuaJIT --accept-source-agreements --accept-package-agreements
} else {
    Write-Host "LuaJIT already installed." -ForegroundColor Green
}

Write-Host "`nVerifying tools..." -ForegroundColor Yellow
$loveVersion = (Get-Command love -ErrorAction SilentlyContinue)
$luajitVersion = (Get-Command luajit -ErrorAction SilentlyContinue)
$luarocksVersion = (Get-Command luarocks -ErrorAction SilentlyContinue)

if (-not $loveVersion) { Write-Host "LÖVE not detected after install." -ForegroundColor Red }
if (-not $luajitVersion) { Write-Host "LuaJIT not detected after install." -ForegroundColor Red }
if (-not $luarocksVersion) { Write-Host "LuaRocks not detected after install." -ForegroundColor Red }

Write-Host "`nUsing existing repository (no clone needed)." -ForegroundColor Green

Write-Host "`nInitializing local LuaRocks environment..." -ForegroundColor Yellow
luarocks init --local

Write-Host "`nInstalling Lua dependencies..." -ForegroundColor Yellow
luarocks --tree=lua_modules install --only-deps fantasy-terminal-scm-1.rockspec

$repoRoot = Get-Location
$env:PATH += ";$repoRoot\lua_modules\bin"
$env:LUA_PATH = "$repoRoot\lua_modules\share\lua\5.1\?.lua;$repoRoot\lua_modules\share\lua\5.1\?\init.lua;;"
$env:LUA_CPATH = "$repoRoot\lua_modules\lib\lua\5.1\?.dll;;"

Write-Host "`nSetup complete! You can now launch Fantasy Terminal by running:" -ForegroundColor Cyan
Write-Host "love ." -ForegroundColor Yellow
