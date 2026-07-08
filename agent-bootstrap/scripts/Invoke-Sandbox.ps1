[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$Code,

    [Parameter(Mandatory=$false)]
    [string]$FilePath,

    [Parameter(Mandatory=$false)]
    [switch]$AllowUnsandboxed
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrEmpty($Code) -and [string]::IsNullOrEmpty($FilePath)) {
    throw "Must provide either -Code or -FilePath"
}

if (-not [string]::IsNullOrEmpty($FilePath)) {
    $Code = Get-Content -Path $FilePath -Raw
}

if (-Not (Get-Command "python" -ErrorAction SilentlyContinue)) {
    throw "SANDBOX_ERROR: Python is not installed. Cannot execute code."
}

$pyScript = @"
import sys
import os

try:
    from e2b_code_interpreter import Sandbox
except ImportError:
    print("ERROR: e2b_code_interpreter not installed. Fallback to local eval.", file=sys.stderr)
    sys.exit(2)

# Verify API key
if not os.environ.get("E2B_API_KEY"):
    print("ERROR: E2B_API_KEY environment variable not set.", file=sys.stderr)
    sys.exit(1)

code = sys.stdin.read()
try:
    with Sandbox() as sandbox:
        execution = sandbox.run_code(code)
        if execution.logs.stdout:
            print("\n".join(execution.logs.stdout))
        if execution.logs.stderr:
            print("\n".join(execution.logs.stderr), file=sys.stderr)
        if execution.error:
            print(f"Error: {execution.error.name} - {execution.error.value}", file=sys.stderr)
            sys.exit(1)
except Exception as e:
    print(f"Sandbox initialization failed: {e}", file=sys.stderr)
    sys.exit(1)
"@

$tempPy = [System.IO.Path]::GetTempFileName()
Set-Content -Path $tempPy -Value $pyScript -Encoding utf8

try {
    $ProcessOutput = $Code | python $tempPy 2>&1
    if ($LASTEXITCODE -eq 2) {
        if ($AllowUnsandboxed) {
            Write-Warning "E2B not available. Running Python locally (-AllowUnsandboxed was set)."
            $ProcessOutput = $Code | python -c "import sys; exec(sys.stdin.read())" 2>&1
        } else {
            throw "SANDBOX_UNAVAILABLE: E2B sandbox is not installed and -AllowUnsandboxed was not specified. " +
                  "Install e2b_code_interpreter or pass -AllowUnsandboxed to run locally."
        }
    }
    Write-Output $ProcessOutput
} finally {
    Remove-Item $tempPy -Force -ErrorAction SilentlyContinue
}
