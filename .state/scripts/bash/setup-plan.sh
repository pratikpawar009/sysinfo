#!/usr/bin/env bash
set -euo pipefail

# Parse arguments
JSON_OUTPUT=false
if [[ "${1:-}" == "--json" || "${1:-}" == "-Json" ]]; then
    JSON_OUTPUT=true
fi

# Get repository root
REPO_ROOT="$(pwd)"

# Load feature.json
FEATURE_JSON="$REPO_ROOT/.state/feature.json"
if [[ ! -f "$FEATURE_JSON" ]]; then
    echo "Error: Feature not initialized. Run /git.feature first." >&2
    exit 1
fi

# Parse JSON manually (portable approach)
FEATURE_NUM=$(grep -o '"feature_num"[[:space:]]*:[[:space:]]*"[^"]*"' "$FEATURE_JSON" | cut -d'"' -f4)
FEATURE_DIR_REL=$(grep -o '"feature_dir"[[:space:]]*:[[:space:]]*"[^"]*"' "$FEATURE_JSON" | cut -d'"' -f4)
BRANCH=$(grep -o '"branch_name"[[:space:]]*:[[:space:]]*"[^"]*"' "$FEATURE_JSON" | cut -d'"' -f4)

FEATURE_DIR="$REPO_ROOT/$FEATURE_DIR_REL"
FEATURE_SPEC="$FEATURE_DIR/spec.md"
IMPL_PLAN="$FEATURE_DIR/plan.md"
DOCS_DIR="$FEATURE_DIR"

# Validate spec exists
if [[ ! -f "$FEATURE_SPEC" ]]; then
    echo "Error: Specification not found at $FEATURE_SPEC. Run /specify first." >&2
    exit 1
fi

# Copy plan template if plan doesn't exist
PLAN_TEMPLATE="$REPO_ROOT/.state/templates/plan-template.md"
if [[ ! -f "$IMPL_PLAN" ]]; then
    if [[ -f "$PLAN_TEMPLATE" ]]; then
        cp "$PLAN_TEMPLATE" "$IMPL_PLAN"
    else
        echo "Error: Plan template not found at $PLAN_TEMPLATE" >&2
        exit 1
    fi
fi

# Output results
if $JSON_OUTPUT; then
    cat << EOF
{
  "FEATURE_SPEC": "$FEATURE_SPEC",
  "IMPL_PLAN": "$IMPL_PLAN",
  "DOCS_DIR": "$DOCS_DIR",
  "BRANCH": "$BRANCH",
  "FEATURE_NUM": "$FEATURE_NUM"
}
EOF
else
    echo "FEATURE_SPEC=$FEATURE_SPEC"
    echo "IMPL_PLAN=$IMPL_PLAN"
    echo "DOCS_DIR=$DOCS_DIR"
    echo "BRANCH=$BRANCH"
    echo "FEATURE_NUM=$FEATURE_NUM"
fi
