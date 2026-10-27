param(
    [Parameter(Mandatory = $true)][int]$GamePid,
    [Parameter(Mandatory = $true)][string]$Archive,
    [Parameter(Mandatory = $true)][string]$TargetExe,
    [Parameter(Mandatory = $true)][string]$StatusFile
)

$ErrorActionPreference = 'Stop'
$targetDirectory = Split-Path -Parent $TargetExe
$stageDirectory = Join-Path $env:TEMP ("CaptainTsubasaUpdate-{0}" -f [guid]::NewGuid())
$updateSuffix = [guid]::NewGuid().ToString('N')
$backupExe = "$TargetExe.update-backup-$updateSuffix"
$temporaryExe = "$TargetExe.update-new-$updateSuffix"
$restoreNeeded = $false
$installed = $false
$failureCode = 'install'
$writeProbe = $null

try {
    try {
        $game = Get-Process -Id $GamePid -ErrorAction Stop
        $game.WaitForExit()
    } catch [System.ArgumentException] {
        # The game has already exited.
    } catch [Microsoft.PowerShell.Commands.ProcessCommandException] {
        # The game has already exited.
    }

    $failureCode = 'folder'
    if (-not (Test-Path -LiteralPath $TargetExe -PathType Leaf)) {
        throw 'The game executable is missing.'
    }
    $writeProbe = Join-Path $targetDirectory (".captain-tsubasa-write-test-{0}" -f [guid]::NewGuid())
    $probeStream = [System.IO.File]::Open($writeProbe, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
    $probeStream.Dispose()
    Remove-Item -LiteralPath $writeProbe -Force

    $failureCode = 'stage'
    New-Item -ItemType Directory -Path $stageDirectory -Force | Out-Null

    $failureCode = 'unpack'
    Expand-Archive -LiteralPath $Archive -DestinationPath $stageDirectory -Force
    $stagedExe = Join-Path $stageDirectory 'captain-tsubasa-2-remake.exe'
    $failureCode = 'package'
    if (-not (Test-Path -LiteralPath $stagedExe -PathType Leaf) -or (Get-Item -LiteralPath $stagedExe).Length -le 0) {
        throw 'The package does not contain the game executable.'
    }

    $failureCode = 'backup'
    Copy-Item -LiteralPath $TargetExe -Destination $backupExe -Force
    $restoreNeeded = $true

    $failureCode = 'install'
    Copy-Item -LiteralPath $stagedExe -Destination $temporaryExe -Force
    Move-Item -LiteralPath $temporaryExe -Destination $TargetExe -Force

    $stagedNotices = Join-Path $stageDirectory 'THIRD_PARTY_NOTICES.txt'
    if (Test-Path -LiteralPath $stagedNotices -PathType Leaf) {
        Copy-Item -LiteralPath $stagedNotices -Destination (Join-Path $targetDirectory 'THIRD_PARTY_NOTICES.txt') -Force
    }

    $failureCode = 'relaunch'
    [System.IO.File]::WriteAllText($StatusFile, 'installed', [System.Text.Encoding]::ASCII)
    $process = Start-Process -FilePath $TargetExe -WorkingDirectory $targetDirectory -PassThru
    if ($null -eq $process) {
        throw 'The updated game process could not be started.'
    }

    $installed = $true
    $restoreNeeded = $false
    Remove-Item -LiteralPath $backupExe -Force -ErrorAction SilentlyContinue
} catch {
    if ($restoreNeeded -and (Test-Path -LiteralPath $backupExe -PathType Leaf)) {
        try {
            Copy-Item -LiteralPath $backupExe -Destination $TargetExe -Force
            $restoreNeeded = $false
        } catch {
            # Keep the previous executable in its backup path for manual recovery.
            $failureCode = 'recovery'
        }
    }
    [System.IO.File]::WriteAllText($StatusFile, ("failed:{0}" -f $failureCode), [System.Text.Encoding]::ASCII)
} finally {
    if ($null -ne $writeProbe) {
        Remove-Item -LiteralPath $writeProbe -Force -ErrorAction SilentlyContinue
    }
    Remove-Item -LiteralPath $temporaryExe -Force -ErrorAction SilentlyContinue
    if ($installed -or -not $restoreNeeded) {
        Remove-Item -LiteralPath $backupExe -Force -ErrorAction SilentlyContinue
    }
    Remove-Item -LiteralPath $stageDirectory -Recurse -Force -ErrorAction SilentlyContinue
}

if (-not $installed) {
    if (Test-Path -LiteralPath $TargetExe -PathType Leaf) {
        try {
            Start-Process -FilePath $TargetExe -WorkingDirectory $targetDirectory | Out-Null
        } catch {
            # The failure status remains available if automatic relaunch is unavailable.
        }
    }
    exit 1
}
