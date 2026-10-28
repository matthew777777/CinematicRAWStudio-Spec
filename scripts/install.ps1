# SPDX-License-Identifier: Apache-2.0
# Windows 10/11 desktop installer. Run in PowerShell; no tests are run.
[CmdletBinding()]
param(
    [string]$Prefix = "$env:LOCALAPPDATA\CRAW\bin",
    [string]$SourceRoot = "$env:LOCALAPPDATA\CRAW\src",
    [string]$Owner = 'matthew777777',
    [string]$Ref = 'main',
    [switch]$NoDeps,
    [switch]$NoMount
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
function Invoke-Checked([string]$Program, [string[]]$Arguments) {
    if ($Program -eq 'cmake' -and $script:BuildLog) {
        & $Program @Arguments *>> $script:BuildLog
    } else {
        & $Program @Arguments
    }
    if ($LASTEXITCODE -ne 0) { throw "$Program failed (exit $LASTEXITCODE). Build details: $script:BuildLog. Fix the reported problem, then rerun this command." }
}
function Refresh-Path {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
}
function Install-Package([string]$Id, [string[]]$Extra = @()) {
    Write-Host "Installing $Id ..."
    & winget install --exact --id $Id --accept-package-agreements --accept-source-agreements --disable-interactivity @Extra
    # WinGet may report a no-op as an error; check required tools below.
    if ($LASTEXITCODE -notin @(0, -1978335189, 3010)) {
        throw "Could not install $Id (exit $LASTEXITCODE). Complete any Windows installation prompts, then rerun."
    }
    Refresh-Path
}
try {
    if (-not $env:LOCALAPPDATA) { throw 'This installer needs Windows. On Mac or Linux, use install.sh.' }
    $localSource = $false
    if ($PSScriptRoot -and -not $PSBoundParameters.ContainsKey('SourceRoot')) {
        $candidate = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
        if ((Test-Path "$candidate\CinematicRAWStudio-Encoder") -and (Test-Path "$candidate\CinematicRAWStudio-Decoder") -and (Test-Path "$candidate\CinematicRAWStudio-TUI")) {
            $SourceRoot = $candidate; $localSource = $true
        }
    }
    if (-not $NoDeps) {
        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
            throw 'Install App Installer from the Microsoft Store (https://aka.ms/getwinget), then run this same command again.'
        }
        foreach ($item in @(@('git','Git.Git'), @('cmake','Kitware.CMake'), @('ffmpeg','Gyan.FFmpeg'), @('adb','Google.PlatformTools'))) {
            if (-not (Get-Command $item[0] -ErrorAction SilentlyContinue)) { Install-Package $item[1] }
        }
        $python = "$env:LOCALAPPDATA\Programs\Python\Python313\python.exe"
        if (-not (Test-Path $python)) { Install-Package 'Python.Python.3.13' @('--scope','user') }
        $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
        $vs = if (Test-Path $vswhere) { & $vswhere -version '[17.0,18.0)' -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath }
        if (-not $vs) {
            $existingVs = if (Test-Path $vswhere) { & $vswhere -latest -version '[17.0,18.0)' -products '*' -property installationPath }
            if ($existingVs) {
                $setup = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\setup.exe"
                Invoke-Checked $setup @('modify','--installPath',"$existingVs",'--passive','--norestart','--add','Microsoft.VisualStudio.Workload.VCTools','--includeRecommended')
            } else {
                Install-Package 'Microsoft.VisualStudio.2022.BuildTools' @('--override', '--wait --passive --norestart --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended')
            }
        }
        if (-not $NoMount -and -not (Test-Path "${env:ProgramFiles(x86)}\WinFsp\inc\fuse\fuse.h")) {
            Install-Package 'WinFsp.WinFsp' @('--force', '--override', '/passive /norestart ADDLOCAL=ALL')
        }
    }
    $python = "$env:LOCALAPPDATA\Programs\Python\Python313\python.exe"
    if (-not (Test-Path $python)) {
        $python = (Get-Command python -ErrorAction SilentlyContinue).Source
        if (-not $python -or $python -like '*WindowsApps*') { throw 'Python 3 is missing. Rerun without -NoDeps.' }
    }
    foreach ($program in @('git','cmake')) {
        if (-not (Get-Command $program -ErrorAction SilentlyContinue)) { throw "$program is missing. Rerun without -NoDeps." }
    }
    New-Item -ItemType Directory -Force $Prefix | Out-Null
    New-Item -ItemType Directory -Force $SourceRoot | Out-Null
    if (-not $localSource) {
        foreach ($part in @('Spec','Encoder','Decoder','TUI')) {
            $repo = Join-Path $SourceRoot "CinematicRAWStudio-$part"
            if (Test-Path $repo) {
                if (-not (Test-Path "$repo\.git")) { throw "$repo already exists. Choose another -SourceRoot." }
                $dirty = & git -C $repo status --porcelain
                if ($LASTEXITCODE -ne 0 -or $dirty) { throw "$repo has local changes. Choose another -SourceRoot to keep them safe." }
                Invoke-Checked git @('-C',$repo,'fetch','origin',$Ref,'--depth','1')
                Invoke-Checked git @('-C',$repo,'merge','--ff-only','FETCH_HEAD')
            } else {
                Invoke-Checked git @('clone','--depth','1','--branch',$Ref,"https://github.com/$Owner/CinematicRAWStudio-$part.git",$repo)
            }
        }
    }
    $script:BuildLog = Join-Path $env:LOCALAPPDATA 'CRAW\install.log'
    New-Item -ItemType Directory -Force (Split-Path $script:BuildLog -Parent) | Out-Null
    Set-Content -Path $script:BuildLog -Value 'CRAW desktop build'
    $spec = Join-Path $SourceRoot 'CinematicRAWStudio-Spec'
    if (-not (Test-Path "$spec\scripts\desktop\craw.py")) { throw 'The selected branch does not contain the desktop installer. Use the published branch or a local checkout.' }
    $mount = if ($NoMount) { 'OFF' } else { 'ON' }
    foreach ($part in @('Encoder','Decoder','TUI')) {
        Write-Host "Building CRAW $part. The first installation takes a few minutes."
        $repo = Join-Path $SourceRoot "CinematicRAWStudio-$part"
        $build = Join-Path $repo 'build-desktop-install-windows'
        $options = @('-S',$repo,'-B',$build,'-G','Visual Studio 17 2022','-A','x64','-DCRAW_BUILD_TESTS=OFF')
        if ($part -eq 'Decoder') { $options += @("-DCRAW_BUILD_MOUNT=$mount", "-DCRAW_REQUIRE_MOUNT=$mount") }
        Invoke-Checked cmake $options
        $targets = switch ($part) {
            Encoder { @('craw_enc','craw_bench') }
            Decoder { @('craw_dec','craw2dng','craw_compact'); if (-not $NoMount) { 'craw_mount' } }
            TUI { @('craw-tui') }
        }
        Invoke-Checked cmake (@('--build',$build,'--config','Release','--parallel','4','--target') + $targets)
        foreach ($binary in $targets) { Copy-Item -Force "$build\Release\$binary.exe" $Prefix }
    }
    # The WinFsp DLL must be beside the executable when delay-loaded.
    if (-not $NoMount) {
        $dll = "${env:ProgramFiles(x86)}\WinFsp\bin\winfsp-x64.dll"
        if (-not (Test-Path $dll)) { throw 'WinFsp runtime is missing. Repair WinFsp, then rerun.' }
        Copy-Item -Force $dll $Prefix
    }
    Copy-Item -Force "$spec\scripts\desktop\craw.py" $Prefix
    $pythonBatch = $python.Replace('%','%%')
    foreach ($name in @('craw','craw-mount','craw-unmount','craw-pull')) {
        $action = switch ($name) { 'craw-mount' { 'mount ' }; 'craw-unmount' { 'unmount ' }; 'craw-pull' { 'pull ' }; default { '' } }
        $body = "@echo off`r`n`"$pythonBatch`" `"%~dp0craw.py`" $action%*`r`nexit /b %errorlevel%`r`n"
        [IO.File]::WriteAllText((Join-Path $Prefix "$name.cmd"), $body, [Text.Encoding]::Default)
    }
    $userPath = [Environment]::GetEnvironmentVariable('Path','User')
    if ($Prefix -notin ($userPath -split ';')) { [Environment]::SetEnvironmentVariable('Path', "$Prefix;$userPath", 'User') }
    Refresh-Path
    $menu = Join-Path ([Environment]::GetFolderPath('Programs')) 'CRAW Studio.lnk'
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($menu)
    $shortcut.TargetPath = $env:ComSpec
    $shortcut.Arguments = '/k ""' + (Join-Path $Prefix 'craw.cmd') + '" tui"'
    $shortcut.WorkingDirectory = [Environment]::GetFolderPath('UserProfile')
    $shortcut.Save()
    # Offer Open With without replacing the user's default application.
    $classes = 'HKCU:\Software\Classes'
    New-Item -Force "$classes\CRAW.Take\shell\open\command" | Out-Null
    Set-Item "$classes\CRAW.Take" -Value 'CRAW Studio'
    Set-Item "$classes\CRAW.Take\shell\open\command" -Value ('"' + $python + '" "' + (Join-Path $Prefix 'craw.py') + '" mount "%1"')
    New-Item -Force "$classes\.craw\OpenWithProgids" | Out-Null
    New-ItemProperty -Force "$classes\.craw\OpenWithProgids" -Name 'CRAW.Take' -PropertyType String -Value '' | Out-Null
    Write-Host "`nInstalled. Open a new terminal and type: craw"
    Write-Host 'Or open CRAW Studio from the Start menu.'
    Write-Host 'craw mount "take.craw"     Open for Resolve'
    Write-Host 'craw unmount               Close mounted takes'
    Write-Host 'craw export "take.craw"    Save CinemaDNG and audio'
    Write-Host 'craw pull --mount          Copy and open the newest phone take'
} catch {
    Write-Error "CRAW: $_"
    exit 1
}
