# GitHub PR Collector

A powerful bash script to collect and consolidate all your pull request descriptions and diffs across GitHub repositories. Perfect for creating comprehensive reports of your contributions, tracking your work over time, or preparing performance reviews.

## Features

- 🔍 **Dual Mode Operation**: Process a single repository or entire organizations/users
- 📅 **Flexible Date Ranges**: Default 6-month lookback or custom date ranges
- 🔧 **Optional Diff Inclusion**: Include full code diffs for comprehensive analysis
- 📁 **Append-Only Output**: Multiple runs accumulate data in the same file
- 🎯 **Smart Filtering**: Only collects PRs authored by you
- 📊 **Detailed Progress**: Real-time feedback during processing
- 🏷️ **Rich Metadata**: Includes PR status, URLs, and timestamps
- 🚀 **Flag-Based Interface**: Professional CLI with explicit, order-independent flags

## Prerequisites

Before using this script, ensure you have:

1. **GitHub CLI (gh)** installed and authenticated
   ```bash
   # Install GitHub CLI
   brew install gh  # macOS
   # or visit: https://cli.github.com/
   
   # Authenticate
   gh auth login
   ```

2. **jq** for JSON processing
   ```bash
   brew install jq  # macOS
   sudo apt install jq  # Ubuntu/Debian
   ```

## Installation

1. Download the script:
   ```bash
   curl -O https://raw.githubusercontent.com/your-repo/github-pr-collector/main/collect_pr_descriptions.sh
   ```

2. Make it executable:
   ```bash
   chmod +x collect_pr_descriptions.sh
   ```

## Usage

### Basic Syntax
```bash
./collect_pr_descriptions.sh --target <repo-or-org> [options]
```

### Required Flags
- `--target`, `-t`: Repository (`owner/repo`) or organization/username

### Optional Flags
- `--output`, `-o`: Output filename (default: `pr_descriptions_YYYYMMDD.md`)
- `--include-diffs`: Include full diff content for each PR
- `--since`: Set custom start date in YYYY-MM-DD format (default: 6 months ago)
- `--help`, `-h`: Show help message

## Examples

### Single Repository
```bash
# Basic usage - last 6 months
./collect_pr_descriptions.sh --target microsoft/vscode

# With custom date range
./collect_pr_descriptions.sh --target microsoft/vscode --since 2024-01-01

# Include diffs and custom filename
./collect_pr_descriptions.sh --target microsoft/vscode --output my_vscode_work.md --include-diffs

# Using short flags
./collect_pr_descriptions.sh -t microsoft/vscode -o my_work.md
```

### Organization/User Mode
```bash
# All repositories in an organization
./collect_pr_descriptions.sh --target microsoft

# Personal repositories with diffs
./collect_pr_descriptions.sh --target octocat --include-diffs

# Custom date range across all repos
./collect_pr_descriptions.sh --target mycompany --since 2023-06-01

# With custom output file
./collect_pr_descriptions.sh --target mycompany --output company_contributions.md
```

### Advanced Examples
```bash
# Comprehensive report with all options
./collect_pr_descriptions.sh --target microsoft --output my_complete_work.md --include-diffs --since 2024-01-01

# Annual review preparation
./collect_pr_descriptions.sh --target mycompany --output annual_review_2024.md --since 2024-01-01

# Recent activity check (flags can be in any order)
./collect_pr_descriptions.sh --since 2025-06-01 --target mycompany --output recent_work.md --include-diffs

# Using short form target flag
./collect_pr_descriptions.sh -t mycompany -o quarterly_report.md --since 2025-04-01
```

## Operation Modes

### Repository Mode
When you provide a target in the format `owner/repo`, the script processes a single repository:
- Faster execution
- Focused analysis
- Ideal for project-specific reviews

### Organization Mode  
When you provide just an organization or username, the script:
- Uses `gh repo list` to discover all repositories
- Processes each repository sequentially
- Groups results by repository
- Provides comprehensive cross-project analysis

## Output Format

The script generates markdown files with the following structure:

```markdown
================================================================================
# Run - Thu Jul 17 14:30:22 PDT 2025
**Target:** microsoft (org mode)
**Author:** your-username
**Period:** since 2025-01-01
**Includes Diffs:** true
**Repositories:** 25
================================================================================

# Repository: microsoft/vscode
**PRs Found:** 5

## PR #12345: Add new feature for syntax highlighting
**Status:** merged
**URL:** https://github.com/microsoft/vscode/pull/12345

### Description:
This PR adds improved syntax highlighting for...

### Diff:
```diff
+ added new functionality
- removed old code
```

---
```

## File Behavior

- **New File**: Creates a clean file with header information
- **Existing File**: Appends new data with run separator
- **Multiple Runs**: Accumulates data from different repositories or time periods
- **Run History**: Each run is clearly separated and timestamped

## Performance Considerations

### Without Diffs
- **Fast**: Processes dozens of repositories quickly
- **Lightweight**: Small output files
- **Network Efficient**: Minimal API calls

### With Diffs (`--include-diffs`)
- **Comprehensive**: Complete code change history
- **Slower**: Requires additional API calls per PR
- **Large Files**: Can generate substantial output
- **Detailed**: Perfect for thorough analysis

### Optimization Tips
- Use `--since` to limit date ranges for faster processing
- Run without diffs first to see PR counts, then re-run with diffs if needed
- Consider processing organizations in smaller chunks for very large organizations

## Troubleshooting

### Authentication Issues
```bash
# Re-authenticate with GitHub
gh auth login

# Verify authentication
gh auth status
```

### Permission Errors
```bash
# Make script executable
chmod +x collect_pr_descriptions.sh

# Check GitHub permissions
gh api user
```

### Missing Dependencies
```bash
# Check if jq is installed
which jq

# Check if gh is installed
which gh
gh --version
```

### Rate Limiting
If you encounter rate limiting with large organizations:
- Process repositories in smaller batches
- Add delays between runs
- Use personal access tokens with higher limits

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests to improve the script.

### Development
- The script is designed to be portable across macOS and Linux
- Date handling accommodates different `date` command implementations
- Error handling gracefully manages API failures and missing data

## License

This project is open source. Feel free to use, modify, and distribute as needed.

## Changelog

### v2.0.0
- **BREAKING CHANGE**: Converted to explicit flag-based arguments
- Added `--target`/`-t` required flag for repository or organization
- Added `--output`/`-o` optional flag for output filename
- Improved argument parsing with order-independent flags
- Enhanced help documentation
- Better error handling for missing required arguments

### v1.0.0
- Initial release with dual-mode operation
- Support for custom date ranges
- Optional diff inclusion
- Append-only file behavior
- Comprehensive help documentation
