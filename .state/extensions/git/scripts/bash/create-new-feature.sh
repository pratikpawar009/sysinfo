#!/usr/bin/env bash
set -euo pipefail

# create-new-feature.sh - Create a new feature branch with sequential or timestamp numbering
# Usage: create-new-feature.sh [--json] [--timestamp] [--short-name NAME] "feature description"

JSON_OUTPUT=false
USE_TIMESTAMP=false
SHORT_NAME=""
FEATURE_DESC=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        --timestamp)
            USE_TIMESTAMP=true
            shift
            ;;
        --short-name)
            SHORT_NAME="$2"
            shift 2
            ;;
        *)
            FEATURE_DESC="$1"
            shift
            ;;
    esac
done

# Check if GIT_BRANCH_NAME override is set
if [[ -n "${GIT_BRANCH_NAME:-}" ]]; then
    BRANCH_NAME="$GIT_BRANCH_NAME"
    # Extract FEATURE_NUM from branch name if it starts with a number
    if [[ "$BRANCH_NAME" =~ ^([0-9]+)- ]]; then
        FEATURE_NUM="${BASH_REMATCH[1]}"
    else
        FEATURE_NUM="$BRANCH_NAME"
    fi
else
    # Determine next feature number or timestamp
    if $USE_TIMESTAMP; then
        FEATURE_NUM=$(date +%Y%m%d-%H%M%S)
    else
        # Find highest existing feature number
        MAX_NUM=0
        while IFS= read -r branch; do
            if [[ "$branch" =~ ^[[:space:]]*(remotes/[^/]+/)?([0-9]{3})- ]]; then
                NUM="${BASH_REMATCH[2]}"
                NUM=$((10#$NUM))  # Convert to decimal
                if (( NUM > MAX_NUM )); then
                    MAX_NUM=$NUM
                fi
            fi
        done < <(git branch -a 2>/dev/null || true)
        
        # Increment for next feature
        FEATURE_NUM=$(printf "%03d" $((MAX_NUM + 1)))
    fi
    
    # Build branch name
    if [[ -n "$SHORT_NAME" ]]; then
        BRANCH_NAME="${FEATURE_NUM}-${SHORT_NAME}"
    else
        # Generate from description (simplified)
        CLEAN_DESC=$(echo "$FEATURE_DESC" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-\|-$//g' | cut -c1-50)
        BRANCH_NAME="${FEATURE_NUM}-${CLEAN_DESC}"
    fi
fi

# Create and switch to branch
if git rev-parse --verify HEAD >/dev/null 2>&1; then
    git checkout -b "$BRANCH_NAME" 2>/dev/null || {
        echo "Warning: Branch $BRANCH_NAME already exists, switching to it" >&2
        git checkout "$BRANCH_NAME" 2>/dev/null
    }
else
    echo "Warning: Git repository not detected; skipped branch creation" >&2
fi

# Output results
if $JSON_OUTPUT; then
    cat << EOF
{
  "BRANCH_NAME": "$BRANCH_NAME",
  "FEATURE_NUM": "$FEATURE_NUM"
}
EOF
else
    echo "BRANCH_NAME=$BRANCH_NAME"
    echo "FEATURE_NUM=$FEATURE_NUM"
fi
