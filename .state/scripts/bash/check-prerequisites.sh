#!/usr/bin/env bash
set -euo pipefail

# Parse arguments
JSON_OUTPUT=false
REQUIRE_TASKS=false
INCLUDE_TASKS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --json|-Json)
            JSON_OUTPUT=true
            shift
            ;;
        --require-tasks|-RequireTasks)
            REQUIRE_TASKS=true
            shift
            ;;
        --include-tasks|-IncludeTasks)
            INCLUDE_TASKS=true
            shift
            ;;
        --paths-only|-PathsOnly)
            # Minimal mode, just return paths
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Get repository root
REPO_ROOT="$(pwd)"

# Load feature.json
FEATURE_JSON="$REPO_ROOT/.state/feature.json"
if [[ ! -f "$FEATURE_JSON" ]]; then
    echo "Error: Feature not initialized. Run /git.feature first." >&2
    exit 1
fi

# Parse JSON
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
    AVAILABLE_DOCS+=("$FEATURE_DIR/spec.md")
fi
if [[ -f "$FEATURE_DIR/plan.md" ]]; then
    AVAILABLE_DOCS+=("$FEATURE_DIR/plan.md")
fi
if [[ -f "$FEATURE_DIR/tasks.md" ]]; then
    AVAILABLE_DOCS+=("$FEATURE_DIR/tasks.md")
fi
if [[ -f "$FEATURE_DIR/research.md" ]]; then
    AVAILABLE_DOCS+=("$FEATURE_DIR/research.md")
fi
if [[ -f "$FEATURE_DIR/data-model.md" ]]; then
    AVAILABLE_DOCS+=("$FEATURE_DIR/data-model.md")
fi
if [[ -f "$FEATURE_DIR/quickstart.md" ]]; then
    AVAILABLE_DOCS+=("$FEATURE_DIR/quickstart.md")
fi

# Check for tasks.md if required
if [[ "$REQUIRE_TASKS" == "true" && ! -f "$FEATURE_DIR/tasks.md" ]]; then
    echo "Error: tasks.md not found. Run /tasks first." >&2
    exit 1
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
  "FEATURE_NUM": "$FEATURE_NUM",
  "AVAILABLE_DOCS": $DOCS_JSON
}
EOF
else
    echo "FEATURE_DIR=$FEATURE_DIR"
    echo "FEATURE_NUM=$FEATURE_NUM"
    echo "AVAILABLE_DOCS=${AVAILABLE_DOCS[*]}"
fi
