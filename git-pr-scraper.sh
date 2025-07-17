#!/bin/bash

# GitHub PR Description and Diff Collector
# Usage: ./collect_pr_descriptions.sh --target <repo-or-org> [options]

set -e

# Default values
TARGET=""
OUTPUT_FILE=""
INCLUDE_DIFFS=false
CUSTOM_DATE=""
SHOW_HELP=false

# Function to show help
show_help() {
    cat << 'EOF'
GitHub PR Description and Diff Collector

USAGE:
    ./collect_pr_descriptions.sh --target <repo-or-org> [options]

REQUIRED FLAGS:
    --target, -t       Repository (owner/repo) or organization/username

OPTIONAL FLAGS:
    --output, -o       Output filename (default: pr_descriptions_YYYYMMDD.md)
    --include-diffs    Include full diff content for each PR
    --since            Set custom start date in YYYY-MM-DD format (default: 6 months ago)
    --help, -h         Show this help message

EXAMPLES:
    # Single repository (default 6 months)
    ./collect_pr_descriptions.sh --target microsoft/vscode

    # Organization with custom output file
    ./collect_pr_descriptions.sh --target microsoft --output my_work.md

    # Include diffs and custom date
    ./collect_pr_descriptions.sh --target microsoft --include-diffs --since 2024-01-01

    # All options combined
    ./collect_pr_descriptions.sh --target microsoft --output complete_report.md --include-diffs --since 2023-06-01

MODES:
    Repository Mode:  Uses format "owner/repo" - processes single repository
    Organization Mode: Uses format "organization" - processes all repos in org/user

OUTPUT:
    - Creates new file if none exists
    - Appends to existing file with run separator
    - Groups PRs by repository in organization mode
    - Includes PR descriptions, status, URLs, and optionally diffs

REQUIREMENTS:
    - GitHub CLI (gh) must be installed and authenticated
    - jq must be installed for JSON processing

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --target|-t)
            TARGET="$2"
            shift 2
            ;;
        --output|-o)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --include-diffs)
            INCLUDE_DIFFS=true
            shift
            ;;
        --since)
            CUSTOM_DATE="$2"
            shift 2
            ;;
        --help|-h)
            SHOW_HELP=true
            shift
            ;;
        *)
            echo "Error: Unknown option $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Show help if requested or no arguments provided
if [ "$SHOW_HELP" = true ] || [ $# -eq 0 ] && [ -z "$TARGET" ]; then
    show_help
    exit 0
fi

# Validate required arguments
if [ -z "$TARGET" ]; then
    echo "Error: --target is required"
    echo "Use --help for usage information"
    exit 1
fi

# Set default output file if not specified
if [ -z "$OUTPUT_FILE" ]; then
    if [ "$INCLUDE_DIFFS" = true ]; then
        OUTPUT_FILE="pr_descriptions_with_diffs_$(date +%Y%m%d).md"
    else
        OUTPUT_FILE="pr_descriptions_$(date +%Y%m%d).md"
    fi
fi

# Determine if we're dealing with a single repo or organization/user
if [[ "$TARGET" == *"/"* ]]; then
    MODE="repo"
    REPO="$TARGET"
    echo "Mode: Single repository ($REPO)"
else
    MODE="org"
    ORG_OR_USER="$TARGET"
    echo "Mode: All repositories for $ORG_OR_USER"
fi

# Calculate date range
if [ -n "$CUSTOM_DATE" ]; then
    # Validate custom date format (basic regex check)
    if [[ ! "$CUSTOM_DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        echo "Error: Invalid date format '$CUSTOM_DATE'. Use YYYY-MM-DD format."
        exit 1
    fi
    SINCE_DATE="$CUSTOM_DATE"
    DATE_DESCRIPTION="since $CUSTOM_DATE"
else
    # Calculate date 6 months ago (1st of that month)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        SINCE_DATE=$(date -v-6m +%Y-%m-01)
    else
        # Linux
        SINCE_DATE=$(date -d "6 months ago" +%Y-%m-01)
    fi
    DATE_DESCRIPTION="since $SINCE_DATE (6 months ago)"
fi

echo "Collecting PR descriptions $DATE_DESCRIPTION..."
if [ "$INCLUDE_DIFFS" = true ]; then
    echo "Including diffs (this may take longer)..."
fi
echo "Output file: $OUTPUT_FILE"

# Get your GitHub username
USERNAME=$(gh api user --jq '.login')
echo "Your GitHub username: $USERNAME"

if [ "$MODE" = "org" ]; then
    # Get list of repositories for the organization/user
    echo "Fetching repositories for $ORG_OR_USER..."
    REPO_LIST=$(gh repo list "$ORG_OR_USER" --limit 1000 --json name,owner --jq '.[] | "\(.owner.login)/\(.name)"')
    
    if [ -z "$REPO_LIST" ]; then
        echo "No repositories found for $ORG_OR_USER"
        exit 1
    fi
    
    REPO_COUNT=$(echo "$REPO_LIST" | wc -l | xargs)
    echo "Found $REPO_COUNT repositories"
else
    REPO_LIST="$REPO"
    REPO_COUNT=1
fi

# Add run header (will create file if it doesn't exist, append if it does)
cat >> "$OUTPUT_FILE" << EOF

================================================================================
# Run - $(date)
**Target:** $TARGET ($MODE mode)
**Author:** $USERNAME  
**Period:** $DATE_DESCRIPTION  
**Includes Diffs:** $INCLUDE_DIFFS
**Repositories:** $REPO_COUNT

================================================================================

EOF

# Process each repository
TOTAL_PRS=0
REPO_COUNTER=1

while read -r CURRENT_REPO; do
    if [ "$MODE" = "org" ]; then
        echo ""
        echo "🔍 Processing repository $REPO_COUNTER/$REPO_COUNT: $CURRENT_REPO"
    fi
    
    # Get list of PRs created by you in the specified date range for this repo
    PR_LIST=$(gh pr list --repo "$CURRENT_REPO" --author "$USERNAME" --state all --limit 1000 --json number,title,createdAt,state,url | jq -r --arg date "$SINCE_DATE" '.[] | select(.createdAt >= $date) | "\(.number)|\(.title)|\(.state)|\(.url)"')
    
    if [ -z "$PR_LIST" ]; then
        if [ "$MODE" = "org" ]; then
            echo "  └── No PRs found in $CURRENT_REPO"
        else
            echo "No pull requests found for $USERNAME in $CURRENT_REPO $DATE_DESCRIPTION"
        fi
        ((REPO_COUNTER++))
        continue
    fi
    
    # Count PRs for this repo
    REPO_PR_COUNT=$(echo "$PR_LIST" | wc -l | xargs)
    TOTAL_PRS=$((TOTAL_PRS + REPO_PR_COUNT))
    
    if [ "$MODE" = "org" ]; then
        echo "  └── Found $REPO_PR_COUNT PRs"
    else
        echo "Found $REPO_PR_COUNT pull requests. Processing..."
    fi
    
    # Add repository header
    cat >> "$OUTPUT_FILE" << EOF
# Repository: $CURRENT_REPO
**PRs Found:** $REPO_PR_COUNT

EOF
    
    # Process each PR in this repository
    PR_COUNTER=1
    while IFS='|' read -r pr_number title state url; do
        if [ "$MODE" = "org" ]; then
            echo "    Processing PR #$pr_number ($PR_COUNTER/$REPO_PR_COUNT): $title"
        else
            echo "Processing PR #$pr_number ($PR_COUNTER/$REPO_PR_COUNT): $title"
        fi
        
        # Get PR description
        DESCRIPTION=$(gh pr view "$pr_number" --repo "$CURRENT_REPO" --json body --jq '.body // "No description provided"')
        
        # Add to output file
        cat >> "$OUTPUT_FILE" << EOF
## PR #$pr_number: $title
**Status:** $state  
**URL:** $url

### Description:
$DESCRIPTION

EOF

        # Get diff if requested
        if [ "$INCLUDE_DIFFS" = true ]; then
            if [ "$MODE" = "org" ]; then
                echo "      └── Fetching diff..."
            else
                echo "  └── Fetching diff..."
            fi
            
            # Get the diff using gh pr diff
            DIFF_OUTPUT=$(gh pr diff "$pr_number" --repo "$CURRENT_REPO" 2>/dev/null || echo "Diff not available (PR may be too old or has conflicts)")
            
            cat >> "$OUTPUT_FILE" << EOF
### Diff:
\`\`\`diff
$DIFF_OUTPUT
\`\`\`

EOF
        fi
        
        echo "---" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        
        ((PR_COUNTER++))
    done <<< "$PR_LIST"
    
    ((REPO_COUNTER++))
done <<< "$REPO_LIST"

echo ""
echo "✅ Complete! Collected descriptions from $TOTAL_PRS pull requests across $REPO_COUNT repositories."
if [ "$INCLUDE_DIFFS" = true ]; then
    echo "📄 Output with diffs saved to: $OUTPUT_FILE"
else
    echo "📄 Output saved to: $OUTPUT_FILE"
fi
echo ""
echo "Summary:"
echo "- Target: $TARGET ($MODE mode)"
echo "- Author: $USERNAME"
echo "- Period: $DATE_DESCRIPTION"
echo "- Repositories: $REPO_COUNT"
echo "- Total PRs: $TOTAL_PRS"
echo "- Includes Diffs: $INCLUDE_DIFFS"
