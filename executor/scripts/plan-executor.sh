#!/bin/bash
# plan-executor.sh - Flexible automated execution of TDD plan phases
# Usage: ./plan-executor.sh [OPTIONS]
#   -p, --plan-dir PATH     Path to plan directory (required)
#   -w, --work-dir PATH     Working directory for implementation (defaults to parent of plan dir)
#   -c, --config FILE       Configuration file (optional)
#   -s, --state-dir PATH    Directory for state/logs (defaults to ./plan-execution)
#   -h, --help              Show help

set -euo pipefail

# Default configuration
PLAN_DIR=""
WORK_DIR=""
STATE_DIR="./plan-execution"
CONFIG_FILE=""
MAX_RETRIES=3
TIMEOUT_SECONDS=600

# State files and directories (will be set after parsing args)
STATE_FILE=""
LOG_DIR=""
REPORT_DIR=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse command line arguments
parse_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      -p|--plan-dir)
        PLAN_DIR="$2"
        shift 2
        ;;
      -w|--work-dir)
        WORK_DIR="$2"
        shift 2
        ;;
      -c|--config)
        CONFIG_FILE="$2"
        shift 2
        ;;
      -s|--state-dir)
        STATE_DIR="$2"
        shift 2
        ;;
      -h|--help)
        show_help
        exit 0
        ;;
      *)
        error "Unknown option: $1"
        show_help
        exit 1
        ;;
    esac
  done
}

show_help() {
  cat << EOF
Usage: $0 [OPTIONS]

Required:
  -p, --plan-dir PATH     Path to plan directory containing phase files

Optional:
  -w, --work-dir PATH     Working directory for implementation 
                          (defaults to parent of plan directory)
  -c, --config FILE       Configuration file with project settings
  -s, --state-dir PATH    Directory for state/logs (defaults to ./plan-execution)
  -h, --help              Show this help

Example:
  $0 -p ./project-plans/feature-x/plan -w ./src
  $0 -p ~/projects/myapp/plans/auth -c ./plan-config.json

Configuration file format (JSON):
{
  "build_command": "npm run build",
  "lint_command": "npm run lint",
  "test_command": "npm test",
  "typecheck_command": "npm run typecheck",
  "timeout_seconds": 600,
  "max_retries": 3
}
EOF
}

# Load configuration from file
load_config() {
  if [ -n "$CONFIG_FILE" ] && [ -f "$CONFIG_FILE" ]; then
    log "Loading configuration from $CONFIG_FILE"
    
    # Parse JSON config
    if command -v jq >/dev/null 2>&1; then
      BUILD_COMMAND=$(jq -r '.build_command // empty' "$CONFIG_FILE" 2>/dev/null || echo "")
      LINT_COMMAND=$(jq -r '.lint_command // empty' "$CONFIG_FILE" 2>/dev/null || echo "")
      TEST_COMMAND=$(jq -r '.test_command // empty' "$CONFIG_FILE" 2>/dev/null || echo "")
      TYPECHECK_COMMAND=$(jq -r '.typecheck_command // empty' "$CONFIG_FILE" 2>/dev/null || echo "")
      TIMEOUT_SECONDS=$(jq -r '.timeout_seconds // 600' "$CONFIG_FILE" 2>/dev/null || echo "600")
      MAX_RETRIES=$(jq -r '.max_retries // 3' "$CONFIG_FILE" 2>/dev/null || echo "3")
    else
      warn "jq not found, cannot parse config file"
    fi
  fi
}

# Auto-detect build tools
detect_build_tools() {
  log "Detecting build tools in $WORK_DIR"
  
  cd "$WORK_DIR"
  
  # Node.js/npm project
  if [ -f "package.json" ]; then
    log "Detected Node.js project"
    
    # Check for common scripts in package.json
    if command -v jq >/dev/null 2>&1; then
      local scripts=$(jq -r '.scripts // {}' package.json)
      
      # Build command
      if [ -z "${BUILD_COMMAND:-}" ]; then
        if echo "$scripts" | jq -e '.build' >/dev/null 2>&1; then
          BUILD_COMMAND="npm run build"
        elif echo "$scripts" | jq -e '.compile' >/dev/null 2>&1; then
          BUILD_COMMAND="npm run compile"
        fi
      fi
      
      # Lint command
      if [ -z "${LINT_COMMAND:-}" ]; then
        if echo "$scripts" | jq -e '.lint' >/dev/null 2>&1; then
          LINT_COMMAND="npm run lint"
        elif echo "$scripts" | jq -e '."lint:fix"' >/dev/null 2>&1; then
          LINT_COMMAND="npm run lint:fix"
        fi
      fi
      
      # Type check command
      if [ -z "${TYPECHECK_COMMAND:-}" ]; then
        if echo "$scripts" | jq -e '.typecheck' >/dev/null 2>&1; then
          TYPECHECK_COMMAND="npm run typecheck"
        elif echo "$scripts" | jq -e '."type-check"' >/dev/null 2>&1; then
          TYPECHECK_COMMAND="npm run type-check"
        elif [ -f "tsconfig.json" ]; then
          TYPECHECK_COMMAND="npx tsc --noEmit"
        fi
      fi
      
      # Test command
      if [ -z "${TEST_COMMAND:-}" ]; then
        if echo "$scripts" | jq -e '.test' >/dev/null 2>&1; then
          TEST_COMMAND="npm test"
        fi
      fi
    fi
  fi
  
  # Python project
  if [ -f "setup.py" ] || [ -f "pyproject.toml" ]; then
    log "Detected Python project"
    
    if [ -z "${BUILD_COMMAND:-}" ] && [ -f "setup.py" ]; then
      BUILD_COMMAND="python setup.py build"
    fi
    
    if [ -z "${LINT_COMMAND:-}" ]; then
      if command -v ruff >/dev/null 2>&1; then
        LINT_COMMAND="ruff check ."
      elif command -v flake8 >/dev/null 2>&1; then
        LINT_COMMAND="flake8"
      fi
    fi
    
    if [ -z "${TYPECHECK_COMMAND:-}" ] && command -v mypy >/dev/null 2>&1; then
      TYPECHECK_COMMAND="mypy ."
    fi
    
    if [ -z "${TEST_COMMAND:-}" ] && command -v pytest >/dev/null 2>&1; then
      TEST_COMMAND="pytest"
    fi
  fi
  
  # Log detected commands
  log "Detected build tools:"
  log "  Build: ${BUILD_COMMAND:-not found}"
  log "  Lint: ${LINT_COMMAND:-not found}"
  log "  Type check: ${TYPECHECK_COMMAND:-not found}"
  log "  Test: ${TEST_COMMAND:-not found}"
  
  cd - >/dev/null
}

# Initialize directories and state
initialize() {
  # Validate required arguments
  if [ -z "$PLAN_DIR" ]; then
    error "Plan directory is required. Use -p or --plan-dir"
    show_help
    exit 1
  fi
  
  if [ ! -d "$PLAN_DIR" ]; then
    error "Plan directory does not exist: $PLAN_DIR"
    exit 1
  fi
  
  # Convert to absolute path
  PLAN_DIR=$(cd "$PLAN_DIR" && pwd)
  
  # Set work directory if not specified
  if [ -z "$WORK_DIR" ]; then
    WORK_DIR=$(dirname "$PLAN_DIR")
    # Go up one more level if we're in a 'plan' subdirectory
    if [[ "$PLAN_DIR" == */plan ]]; then
      WORK_DIR=$(dirname "$WORK_DIR")
    fi
  fi
  
  # Convert to absolute path
  WORK_DIR=$(cd "$WORK_DIR" && pwd)
  
  # Set up state directory structure
  STATE_FILE="$STATE_DIR/plan-state.json"
  LOG_DIR="$STATE_DIR/logs"
  REPORT_DIR="$STATE_DIR/reports"
  
  # Initialize directories
  mkdir -p "$STATE_DIR" "$LOG_DIR" "$REPORT_DIR"
  
  # Initialize state file if not exists
  if [ ! -f "$STATE_FILE" ]; then
    cat > "$STATE_FILE" << EOF
{
  "plan_dir": "$PLAN_DIR",
  "work_dir": "$WORK_DIR",
  "current_phase": null,
  "completed_phases": [],
  "failed_attempts": {},
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
  fi
  
  # Load configuration
  load_config
  
  # Detect build tools
  detect_build_tools
  
  # Save detected commands to state
  local tmp=$(mktemp)
  jq ". + {
    \"build_command\": \"${BUILD_COMMAND:-}\",
    \"lint_command\": \"${LINT_COMMAND:-}\",
    \"typecheck_command\": \"${TYPECHECK_COMMAND:-}\",
    \"test_command\": \"${TEST_COMMAND:-}\"
  }" "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
}

# Logging functions
log() {
  echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
  echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" >&2
}

warn() {
  echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARN:${NC} $1"
}

info() {
  echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] INFO:${NC} $1"
}

# State management functions
get_state() {
  jq -r ".$1" "$STATE_FILE" 2>/dev/null || echo "null"
}

update_state() {
  local key=$1
  local value=$2
  local tmp=$(mktemp)
  jq ".$key = $value" "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
}

add_completed_phase() {
  local phase=$1
  local tmp=$(mktemp)
  jq ".completed_phases += [\"$phase\"]" "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
}

record_failure() {
  local phase=$1
  local error=$2
  local tmp=$(mktemp)
  jq ".failed_attempts[\"$phase\"] = {
    \"attempts\": (.failed_attempts[\"$phase\"].attempts // 0) + 1,
    \"last_error\": \"$error\",
    \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"
  }" "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
}

# Get all phases from plan directory
get_all_phases() {
  ls "$PLAN_DIR" | grep -E "^[0-9]+-.*\.md$" | grep -v "^[0-9]+a-" | grep -v "^00-" | sort -n
}

# Get verification file for a phase
get_verification_file() {
  local phase_file=$1
  local phase_num=$(echo "$phase_file" | cut -d'-' -f1)
  echo "${phase_num}a-$(echo "$phase_file" | cut -d'-' -f2-)"
}

# Run build and lint checks
run_build_checks() {
  local phase_name=$1
  local check_results=()
  local all_passed=true
  
  info "Running build and lint checks for phase $phase_name"
  
  cd "$WORK_DIR"
  
  # Run build
  if [ -n "${BUILD_COMMAND:-}" ]; then
    log "Running build: $BUILD_COMMAND"
    if eval "$BUILD_COMMAND" > "$LOG_DIR/build-$phase_name.log" 2>&1; then
      check_results+=("✓ Build passed")
    else
      check_results+=("✗ Build failed")
      all_passed=false
      error "Build failed. See $LOG_DIR/build-$phase_name.log"
    fi
  fi
  
  # Run type check
  if [ -n "${TYPECHECK_COMMAND:-}" ]; then
    log "Running type check: $TYPECHECK_COMMAND"
    if eval "$TYPECHECK_COMMAND" > "$LOG_DIR/typecheck-$phase_name.log" 2>&1; then
      check_results+=("✓ Type check passed")
    else
      check_results+=("✗ Type check failed")
      all_passed=false
      error "Type check failed. See $LOG_DIR/typecheck-$phase_name.log"
    fi
  fi
  
  # Run lint
  if [ -n "${LINT_COMMAND:-}" ]; then
    log "Running lint: $LINT_COMMAND"
    if eval "$LINT_COMMAND" > "$LOG_DIR/lint-$phase_name.log" 2>&1; then
      check_results+=("✓ Lint passed")
    else
      check_results+=("✗ Lint failed")
      all_passed=false
      error "Lint failed. See $LOG_DIR/lint-$phase_name.log"
    fi
  fi
  
  # Run tests if specified
  if [ -n "${TEST_COMMAND:-}" ] && [[ "$phase_name" == *"test"* || "$phase_name" == *"tdd"* ]]; then
    log "Running tests: $TEST_COMMAND"
    if eval "$TEST_COMMAND" > "$LOG_DIR/test-$phase_name.log" 2>&1; then
      check_results+=("✓ Tests passed")
    else
      # For TDD phases, failing tests might be expected
      if [[ "$phase_name" == *"tdd"* ]]; then
        check_results+=("⚠ Tests failing (expected for TDD)")
        warn "Tests failing - this may be expected for TDD phase"
      else
        check_results+=("✗ Tests failed")
        all_passed=false
        error "Tests failed. See $LOG_DIR/test-$phase_name.log"
      fi
    fi
  fi
  
  cd - >/dev/null
  
  # Save results
  printf '%s\n' "${check_results[@]}" > "$REPORT_DIR/build-checks-$phase_name.txt"
  
  if [ "$all_passed" = true ]; then
    log "All build checks passed"
    return 0
  else
    error "Some build checks failed"
    return 1
  fi
}

# Execute a single phase
execute_phase() {
  local phase_file=$1
  local phase_num=$(echo "$phase_file" | cut -d'-' -f1)
  local phase_name=$(echo "$phase_file" | sed 's/\.md$//')
  
  log "Executing phase: $phase_name"
  update_state "current_phase" "\"$phase_name\""
  
  # Read phase content to understand deliverables
  local phase_content=$(cat "$PLAN_DIR/$phase_file")
  
  # Create phase-specific prompt
  local prompt="Execute the implementation phase defined in $PLAN_DIR/$phase_file

WORKING DIRECTORY: $WORK_DIR
You should create/modify files in this directory.

IMPORTANT INSTRUCTIONS:
1. Read and follow ALL instructions in the phase file
2. Create all deliverables listed in the file
3. Run all self-verification steps
4. Output a JSON status to $REPORT_DIR/phase-$phase_num.json with format:
   {
     \"phase\": \"$phase_num\",
     \"status\": \"complete\" or \"failed\",
     \"deliverables\": [list of created files],
     \"errors\": [any errors encountered]
   }
5. Do NOT ask for confirmation or whether to continue
6. Complete ALL work specified in the phase file
7. Work in the directory: $WORK_DIR"

  # Execute with timeout
  local log_file="$LOG_DIR/phase-$phase_num.log"
  local status_file="$REPORT_DIR/phase-$phase_num.json"
  
  # Remove old status file
  rm -f "$status_file"
  
  # Run Claude
  local claude_exit_code
  
  # Check if timeout command exists
  if command -v timeout >/dev/null 2>&1; then
    timeout "$TIMEOUT_SECONDS" claude --dangerously-skip-permissions -p "$prompt" > "$log_file" 2>&1
    claude_exit_code=$?
  else
    # Fallback: run without timeout on macOS
    if command -v gtimeout >/dev/null 2>&1; then
      gtimeout "$TIMEOUT_SECONDS" claude --dangerously-skip-permissions -p "$prompt" > "$log_file" 2>&1
      claude_exit_code=$?
    else
      warn "timeout command not found, running without timeout limit"
      claude --dangerously-skip-permissions -p "$prompt" > "$log_file" 2>&1
      claude_exit_code=$?
    fi
  fi
  
  if [ $claude_exit_code -eq 0 ]; then
    # Check if status file was created
    if [ -f "$status_file" ]; then
      local status=$(jq -r '.status' "$status_file" 2>/dev/null || echo "unknown")
      if [ "$status" = "complete" ]; then
        log "Phase $phase_name completed successfully"
        return 0
      else
        error "Phase $phase_name failed with status: $status"
        return 1
      fi
    else
      error "Phase $phase_name did not create status file"
      return 1
    fi
  else
    error "Phase $phase_name timed out or failed (exit code: $claude_exit_code)"
    return 1
  fi
}

# Execute verification for a phase
execute_verification() {
  local phase_file=$1
  local phase_num=$2
  local verification_file=$(get_verification_file "$phase_file")
  
  if [ ! -f "$PLAN_DIR/$verification_file" ]; then
    warn "No verification file found for $phase_file, running build checks only"
    # Still run build checks even without verification file
    if run_build_checks "$phase_num"; then
      return 0
    else
      return 1
    fi
  fi
  
  log "Running verification: $verification_file"
  
  local prompt="Execute the verification defined in $PLAN_DIR/$verification_file

WORKING DIRECTORY: $WORK_DIR
Check files in this directory.

IMPORTANT INSTRUCTIONS:
1. Run ALL verification steps in the file
2. Check all deliverables exist and are correct
3. Run all automated checks
4. Output results to $REPORT_DIR/verify-$phase_num.json with format:
   {
     \"phase\": \"${phase_num}a\",
     \"status\": \"pass\" or \"fail\",
     \"issues\": [list of any issues found],
     \"checks_passed\": number,
     \"checks_failed\": number
   }
5. Do NOT ask for confirmation
6. Be thorough in verification
7. Work in the directory: $WORK_DIR"

  local log_file="$LOG_DIR/verify-$phase_num.log"
  local verify_file="$REPORT_DIR/verify-$phase_num.json"
  
  # Remove old verification file
  rm -f "$verify_file"
  
  # Run verification
  local claude_exit_code
  
  if command -v timeout >/dev/null 2>&1; then
    timeout "$TIMEOUT_SECONDS" claude --dangerously-skip-permissions -p "$prompt" > "$log_file" 2>&1
    claude_exit_code=$?
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout "$TIMEOUT_SECONDS" claude --dangerously-skip-permissions -p "$prompt" > "$log_file" 2>&1
    claude_exit_code=$?
  else
    claude --dangerously-skip-permissions -p "$prompt" > "$log_file" 2>&1
    claude_exit_code=$?
  fi
  
  if [ $claude_exit_code -eq 0 ]; then
    if [ -f "$verify_file" ]; then
      local status=$(jq -r '.status' "$verify_file" 2>/dev/null || echo "unknown")
      if [ "$status" = "pass" ]; then
        log "Verification passed for phase $phase_num"
        
        # Run build checks after verification
        if run_build_checks "$phase_num"; then
          return 0
        else
          error "Build checks failed after verification"
          return 1
        fi
      else
        local issues=$(jq -r '.issues[]' "$verify_file" 2>/dev/null || echo "Unknown issues")
        error "Verification failed for phase $phase_num: $issues"
        return 1
      fi
    else
      error "Verification did not create results file"
      return 1
    fi
  else
    error "Verification timed out or failed"
    return 1
  fi
}

# Fix issues and retry phase
fix_and_retry() {
  local phase_file=$1
  local phase_num=$2
  local retry_num=$3
  
  log "Attempting to fix issues in phase $phase_num (retry $retry_num)"
  
  # Gather all issues
  local issues=""
  
  # Get verification issues
  local verify_file="$REPORT_DIR/verify-$phase_num.json"
  if [ -f "$verify_file" ]; then
    issues+="VERIFICATION ISSUES:\n"
    issues+=$(jq -r '.issues[]' "$verify_file" 2>/dev/null || echo "Unknown issues")
    issues+="\n\n"
  fi
  
  # Get build check results
  local build_check_file="$REPORT_DIR/build-checks-$phase_num.txt"
  if [ -f "$build_check_file" ]; then
    issues+="BUILD CHECK RESULTS:\n"
    issues+=$(cat "$build_check_file")
    issues+="\n\n"
  fi
  
  # Get build/lint/test logs for failures
  for log_type in build typecheck lint test; do
    local log_file="$LOG_DIR/${log_type}-$phase_num.log"
    if [ -f "$log_file" ] && grep -q "error\|Error\|ERROR\|fail\|Fail\|FAIL" "$log_file" 2>/dev/null; then
      issues+="${log_type^^} ERRORS:\n"
      issues+=$(tail -50 "$log_file" | grep -A2 -B2 "error\|Error\|ERROR\|fail\|Fail\|FAIL" || tail -20 "$log_file")
      issues+="\n\n"
    fi
  done
  
  local prompt="Fix the implementation issues found in phase $phase_num.

WORKING DIRECTORY: $WORK_DIR

ISSUES FOUND:
$issues

INSTRUCTIONS:
1. Read the original phase file: $PLAN_DIR/$phase_file
2. Understand what went wrong from the verification issues and build errors
3. Fix ONLY the specific issues identified
4. Re-create or update the deliverables as needed
5. Ensure the code compiles, passes lint, and type checks
6. Output status to $REPORT_DIR/phase-$phase_num.json
7. Do NOT ask for confirmation
8. Focus on fixing the specific issues, don't redo everything
9. Work in the directory: $WORK_DIR"

  local log_file="$LOG_DIR/phase-$phase_num-fix-$retry_num.log"
  
  local claude_exit_code
  
  if command -v timeout >/dev/null 2>&1; then
    timeout "$TIMEOUT_SECONDS" claude --dangerously-skip-permissions -p "$prompt" > "$log_file" 2>&1
    claude_exit_code=$?
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout "$TIMEOUT_SECONDS" claude --dangerously-skip-permissions -p "$prompt" > "$log_file" 2>&1
    claude_exit_code=$?
  else
    claude --dangerously-skip-permissions -p "$prompt" > "$log_file" 2>&1
    claude_exit_code=$?
  fi
  
  if [ $claude_exit_code -eq 0 ]; then
    log "Fix attempt completed for phase $phase_num"
    return 0
  else
    error "Fix attempt failed or timed out"
    return 1
  fi
}

# Process a single phase with retries
process_phase_with_retries() {
  local phase_file=$1
  local phase_num=$(echo "$phase_file" | cut -d'-' -f1)
  local phase_name=$(echo "$phase_file" | sed 's/\.md$//')
  
  # Check if already completed
  local completed=$(jq -r ".completed_phases[] | select(. == \"$phase_name\")" "$STATE_FILE" 2>/dev/null || echo "")
  if [ -n "$completed" ]; then
    log "Phase $phase_name already completed, skipping"
    return 0
  fi
  
  local retry_count=0
  
  while [ $retry_count -le $MAX_RETRIES ]; do
    if [ $retry_count -gt 0 ]; then
      log "Retry attempt $retry_count for phase $phase_name"
    fi
    
    # Execute phase
    if execute_phase "$phase_file"; then
      # Run verification
      if execute_verification "$phase_file" "$phase_num"; then
        # Success!
        add_completed_phase "$phase_name"
        log "Phase $phase_name completed and verified successfully"
        return 0
      else
        # Verification failed
        if [ $retry_count -lt $MAX_RETRIES ]; then
          # Try to fix
          if ! fix_and_retry "$phase_file" "$phase_num" "$((retry_count + 1))"; then
            error "Failed to fix issues in phase $phase_name"
          fi
        fi
      fi
    else
      # Implementation failed
      record_failure "$phase_name" "Implementation failed"
    fi
    
    ((retry_count++))
  done
  
  error "Phase $phase_name failed after $MAX_RETRIES retries"
  record_failure "$phase_name" "Max retries exceeded"
  return 1
}

# Show progress
show_progress() {
  local all_phases=($(get_all_phases))
  local total=${#all_phases[@]}
  local completed=$(jq -r '.completed_phases | length' "$STATE_FILE")
  local current=$(get_state "current_phase")
  
  echo ""
  echo "===== PROGRESS REPORT ====="
  echo "Plan: $PLAN_DIR"
  echo "Work: $WORK_DIR"
  echo "Total phases: $total"
  echo "Completed: $completed"
  echo "Current phase: $current"
  echo ""
  echo "Completed phases:"
  jq -r '.completed_phases[]' "$STATE_FILE" | sed 's/^/  - /'
  echo ""
  
  # Show failed attempts if any
  local failed_count=$(jq -r '.failed_attempts | length' "$STATE_FILE")
  if [ "$failed_count" -gt 0 ]; then
    echo "Failed attempts:"
    jq -r '.failed_attempts | to_entries[] | "  - \(.key): \(.value.attempts) attempts, last error: \(.value.last_error)"' "$STATE_FILE"
    echo ""
  fi
}

# Main execution
main() {
  # Parse arguments
  parse_args "$@"
  
  # Initialize
  initialize
  
  log "Starting automated plan execution"
  log "Plan directory: $PLAN_DIR"
  log "Work directory: $WORK_DIR"
  log "State directory: $STATE_DIR"
  
  # Get all phases
  local all_phases=($(get_all_phases))
  log "Found ${#all_phases[@]} phases to execute"
  
  # Process each phase
  for phase_file in "${all_phases[@]}"; do
    echo ""
    echo "========================================="
    echo "Processing: $phase_file"
    echo "========================================="
    
    if process_phase_with_retries "$phase_file"; then
      log "Phase completed successfully"
    else
      error "Phase failed, stopping execution"
      show_progress
      exit 1
    fi
    
    # Show progress after each phase
    show_progress
  done
  
  log "All phases completed successfully!"
  show_progress
}

# Handle interrupts
trap 'error "Interrupted"; show_progress; exit 130' INT TERM

# Run main
main "$@"