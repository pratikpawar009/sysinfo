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

# Parse JSON manually
FEATURE_NUM=$(grep -o '"feature_num"[[:space:]]*:[[:space:]]*"[^"]*"' "$FEATURE_JSON" | cut -d'"' -f4)
FEATURE_DIR_REL=$(grep -o '"feature_dir"[[:space:]]*:[[:space:]]*"[^"]*"' "$FEATURE_JSON" | cut -d'"' -f4)

FEATURE_DIR="$REPO_ROOT/$FEATURE_DIR_REL"

# Check if feature directory exists
if [[ ! -d "$FEATURE_DIR" ]]; then
    echo "Error: Feature directory not found at $FEATURE_DIR" >&2
    exit 1
fi

# Find available docs
AVAILABLE_DOCS=()
if [[ -f "$FEATURE_DIR/spec.md" ]]; then
    AVAILABLE_DOCS+=("spec.md")
fi
if [[ -f "$FEATURE_DIR/plan.md" ]]; then
    AVAILABLE_DOCS+=("plan.md")
fi
if [[ -f "$FEATURE_DIR/research.md" ]]; then
    AVAILABLE_DOCS+=("research.md")
fi
if [[ -f "$FEATURE_DIR/data-model.md" ]]; then
    AVAILABLE_DOCS+=("data-model.md")
fi
if [[ -f "$FEATURE_DIR/quickstart.md" ]]; then
    AVAILABLE_DOCS+=("quickstart.md")
fi
if [[ -d "$FEATURE_DIR/contracts" ]]; then
    AVAILABLE_DOCS+=("contracts/")
fi

# Tasks template
TASKS_TEMPLATE="$REPO_ROOT/.state/templates/tasks-template.md"
if [[ ! -f "$TASKS_TEMPLATE" ]]; then
    TASKS_TEMPLATE=""
fi

# Output results
if $JSON_OUTPUT; then
    # Build JSON array for available docs
    DOCS_JSON="["
    FIRST=true
    for doc in "${AVAILABLE_DOCS[@]}"; do
        if [ "$FIRST" = true ]; then
            FIRST=false
        else
            DOCS_JSON+=","
        fi
        DOCS_JSON+="\"$doc\""
    done
    DOCS_JSON+="]"
    
    cat << EOF
{
  "FEATURE_DIR": "$FEATURE_DIR",
  "TASKS_TEMPLATE": "$TASKS_TEMPLATE",
  "AVAILABLE_DOCS": $DOCS_JSON
}
EOF
else
    echo "FEATURE_DIR=$FEATURE_DIR"
    echo "TASKS_TEMPLATE=$TASKS_TEMPLATE"
    echo "AVAILABLE_DOCS=${AVAILABLE_DOCS[*]}"
fi
