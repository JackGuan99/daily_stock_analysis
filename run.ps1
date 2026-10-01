param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CliArgs
)

$ErrorActionPreference = 'Stop'
$taskRepoPath = $PSScriptRoot
$taskPythonPath = Join-Path $PSScriptRoot '.venv\Scripts\python.exe'
if (-not (Test-Path -LiteralPath $taskPythonPath -PathType Leaf)) {
    throw 'Workspace Python environment is missing. Reinstall the workspace dependencies.'
}
if (-not $CliArgs -or $CliArgs.Count -eq 0) {
    $CliArgs = @('--help')
}

$taskPreviousEnvFile = [Environment]::GetEnvironmentVariable('ENV_FILE', 'Process')
$taskExitCode = 0
Push-Location -LiteralPath $taskRepoPath
try {
    $env:ENV_FILE = Join-Path $taskRepoPath '.env'
    & $taskPythonPath -X utf8 (Join-Path $taskRepoPath 'main.py') @CliArgs
    $taskExitCode = $LASTEXITCODE
}
finally {
    [Environment]::SetEnvironmentVariable('ENV_FILE', $taskPreviousEnvFile, 'Process')
    Pop-Location
}
exit $taskExitCode
