#!/usr/bin/env pwsh
param(
    [switch]$Json
)

$ErrorActionPreference = "Stop"

# Get repository root (current directory assumed to be repo root)
$REPO_ROOT = Get-Location

# Load feature.json
$featureJsonPath = Join-Path $REPO_ROOT ".state/feature.json"
if (-not (Test-Path $featureJsonPath)) {
    Write-Error "Feature not initialized. Run /git.feature first."
    exit 1
}

$featureData = Get-Content $featureJsonPath | ConvertFrom-Json
$FEATURE_NUM = $featureData.feature_num
$FEATURE_DIR = Join-Path $REPO_ROOT $featureData.feature_dir

# Paths
$FEATURE_SPEC = Join-Path $FEATURE_DIR "spec.md"
$IMPL_PLAN = Join-Path $FEATURE_DIR "plan.md"
$DOCS_DIR = $FEATURE_DIR
$BRANCH = $featureData.branch_name

# Validate spec exists
if (-not (Test-Path $FEATURE_SPEC)) {
    Write-Error "Specification not found at $FEATURE_SPEC. Run /specify first."
    exit 1
}

# Copy plan template if plan doesn't exist
$planTemplate = Join-Path $REPO_ROOT ".state/templates/plan-template.md"
if (-not (Test-Path $IMPL_PLAN)) {
    if (Test-Path $planTemplate) {
        Copy-Item $planTemplate $IMPL_PLAN
    } else {
        Write-Error "Plan template not found at $planTemplate"
        exit 1
    }
}

# Output results
if ($Json) {
    @{
        FEATURE_SPEC = $FEATURE_SPEC
        IMPL_PLAN = $IMPL_PLAN
        DOCS_DIR = $DOCS_DIR
        BRANCH = $BRANCH
        FEATURE_NUM = $FEATURE_NUM
    } | ConvertTo-Json
} else {
    Write-Host "FEATURE_SPEC=$FEATURE_SPEC"
    Write-Host "IMPL_PLAN=$IMPL_PLAN"
    Write-Host "DOCS_DIR=$DOCS_DIR"
    Write-Host "BRANCH=$BRANCH"
    Write-Host "FEATURE_NUM=$FEATURE_NUM"
}
