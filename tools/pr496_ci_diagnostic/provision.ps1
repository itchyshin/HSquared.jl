param([Parameter(Mandatory=$true)][string]$DiagDir)
$ErrorActionPreference = 'Stop'
if (-not $env:RUNNER_TEMP) { throw 'RUNNER_TEMP is required' }
$base = Join-Path $env:RUNNER_TEMP 'hsq496-baseline'
$candidate = Join-Path $env:RUNNER_TEMP 'hsq496-candidate'
$evidence = Join-Path $env:RUNNER_TEMP 'pr496-paired-evidence'
$old = '623a54bddd82e7268cf3845a25e278c024515074'
$new = 'c2c18582fd53c76d760618684001a2758ba33ced'
$projectHash = '8797dab5ac93c3c03e29c6fa3924056c173873d40356e8be86a7367344cdd9dc'
$manifestHash = '272ce679b561dedde1d733b783905cc6201cd9ed08b99acc1f87082e5454597b'
$env:OPENBLAS_NUM_THREADS = '1'
$env:JULIA_NUM_THREADS = '2'
$env:JULIA_NUM_PRECOMPILE_TASKS = '1'
$env:JULIA_PKG_PRECOMPILE_AUTO = '0'
if ((Test-Path $base) -or (Test-Path $candidate) -or (Test-Path $evidence)) {
  throw 'Source and evidence paths must be new; no existing files are removed.'
}
New-Item -ItemType Directory -Path $evidence | Out-Null
@('provision started', "ImageOS=$env:ImageOS", "ImageVersion=$env:ImageVersion") | Set-Content (Join-Path $evidence 'provision-start.txt')
$juliaVersion = (& julia --startup-file=no -e 'print(VERSION)' | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $juliaVersion -ne '1.13.3') { throw 'Julia 1.13.3 is required.' }
$manifest = Join-Path $DiagDir 'pinned-Manifest-1.13.3.toml'
if ((Get-FileHash -Algorithm SHA256 $manifest).Hash.ToLowerInvariant() -ne $manifestHash) { throw 'Pinned manifest hash mismatch.' }
foreach ($entry in @(@{ name='baseline'; root=$base; commit=$old }, @{ name='candidate'; root=$candidate; commit=$new })) {
  $name = $entry.name; $root = $entry.root; $commit = $entry.commit
  & git -c core.autocrlf=false clone --no-checkout --filter=blob:none https://github.com/itchyshin/HSquared.jl.git $root
  if ($LASTEXITCODE -ne 0) { throw "$name clone failed" }
  & git -C $root -c core.autocrlf=false checkout --detach $commit
  if ($LASTEXITCODE -ne 0) { throw "$name checkout failed" }
  if ((& git -C $root rev-parse HEAD) -ne $commit) { throw "$name wrong commit" }
  if (& git -C $root status --porcelain --untracked-files=no) { throw "$name tracked changes" }
  $project = Join-Path $root 'Project.toml'; $targetManifest = Join-Path $root 'Manifest.toml'
  if ((Get-FileHash -Algorithm SHA256 $project).Hash.ToLowerInvariant() -ne $projectHash) { throw "$name project hash mismatch before instantiate" }
  Copy-Item $manifest $targetManifest
  if ((Get-FileHash -Algorithm SHA256 $targetManifest).Hash.ToLowerInvariant() -ne $manifestHash) { throw "$name manifest hash mismatch before instantiate" }
  & julia --startup-file=no --project=$root -e 'using Pkg; Pkg.instantiate()' *> (Join-Path $evidence "$name-instantiate.log")
  if ($LASTEXITCODE -ne 0) { throw "$name instantiate failed; log retained" }
  if ((Get-FileHash -Algorithm SHA256 $project).Hash.ToLowerInvariant() -ne $projectHash) { throw "$name project changed during instantiate" }
  if ((Get-FileHash -Algorithm SHA256 $targetManifest).Hash.ToLowerInvariant() -ne $manifestHash) { throw "$name manifest changed during instantiate" }
}
@("julia=$juliaVersion", "baseline=$old", "candidate=$new", "project_sha256=$projectHash", "manifest_sha256=$manifestHash", "ImageOS=$env:ImageOS", "ImageVersion=$env:ImageVersion") | Set-Content (Join-Path $evidence 'provision-identity.txt')
