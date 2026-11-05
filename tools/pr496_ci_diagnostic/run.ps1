param([Parameter(Mandatory=$true)][string]$DiagDir)
$ErrorActionPreference = 'Stop'
if (-not $env:RUNNER_TEMP) { throw 'RUNNER_TEMP is required' }
$base = Join-Path $env:RUNNER_TEMP 'hsq496-baseline'
$candidate = Join-Path $env:RUNNER_TEMP 'hsq496-candidate'
$evidence = Join-Path $env:RUNNER_TEMP 'pr496-paired-evidence'
$results = Join-Path $evidence 'results'
if (-not (Test-Path $evidence)) { throw 'Run provision.ps1 first.' }
$oldSrc = 'af70fd707b0e142eb5dede4da74a638f239e1805683ec16a160f78126eb8f04b'
$newSrc = 'b1087932ea7324a0422ddb3a877e865335bba522529e430bab5481b933a20182'
$env:OPENBLAS_NUM_THREADS = '1'
$env:JULIA_NUM_THREADS = '2'
$env:JULIA_NUM_PRECOMPILE_TASKS = '1'
$env:JULIA_PKG_PRECOMPILE_AUTO = '0'
& julia --startup-file=no (Join-Path $DiagDir 'paired.jl') $base $candidate $oldSrc $newSrc $results 2>&1 | Tee-Object -FilePath (Join-Path $evidence 'driver.log')
$exitCode = $LASTEXITCODE
if ($exitCode -ne 0) { throw "Paired diagnostic failed with exit $exitCode; evidence retained." }
