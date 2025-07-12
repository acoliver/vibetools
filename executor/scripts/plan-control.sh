#!/bin/bash
# plan-control-v2.sh - Control script for flexible plan execution
# Usage: ./plan-control-v2.sh COMMAND [OPTIONS]

set -euo pipefail

# Default configuration
STATE_DIR="./plan-execution"
EXECUTOR_SCRIPT="./plan-executor-v2.sh"
PLAN_DIR=""
WORK_DIR=""
CONFIG_FILE=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Parse global options
parse_global_options() {
  while [[ $# -gt 0 ]] && [[ "$1" == -* ]]; do
    case $1 in
      -p|--plan-dir)
        PLAN_DIR="$2"
        shift 2
        ;;
      -w|--work-dir)
        WORK_DIR="$2"
        shift 2
        ;;
      -s|--state-dir)
        STATE_DIR="$2"
        shift 2
        ;;
      -c|--config)
        CONFIG_FILE="$2"
        shift 2
        ;;
      *)
        break
        ;;
    esac
  done
  
  # Return remaining args
  echo "$@"
}

# Get state file path
get_state_file() {
  echo "$STATE_DIR/plan-state.json"
}

# Read plan directory from state if not specified
get_plan_dir() {
  if [ -z "$PLAN_DIR" ] && [ -f "$(get_state_file)" ]; then
    PLAN_DIR=$(jq -r '.plan_dir // empty' "$(get_state_file)" 2>/dev/null || echo "")
  fi
  
  if [ -z "$PLAN_DIR" ]; then
    echo -e "${RED}Error: Plan directory not specified and not found in state${NC}" >&2
    echo "Use -p or --plan-dir to specify the plan directory" >&2
    return 1
  fi
  
  echo "$PLAN_DIR"
}

# Build executor arguments
build_executor_args() {
  local args=""
  
  if [ -n "$PLAN_DIR" ]; then
    args+=" -p $PLAN_DIR"
  fi
  
  if [ -n "$WORK_DIR" ]; then
    args+=" -w $WORK_DIR"
  fi
  
  if [ -n "$CONFIG_FILE" ]; then
    args+=" -c $CONFIG_FILE"
  fi
  
  if [ -n "$STATE_DIR" ]; then
    args+=" -s $STATE_DIR"
  fi
  
  echo "$args"
}

# Commands
cmd_start() {
  echo "Starting plan execution..."
  
  # Validate plan directory
  if ! PLAN_DIR=$(get_plan_dir); then
    exit 1
  fi
  
  if [ ! -d "$PLAN_DIR" ]; then
    echo -e "${RED}Error: Plan directory does not exist: $PLAN_DIR${NC}"
    exit 1
  fi
  
  # Check if already running
  if pgrep -f "plan-executor-v2.sh.*$PLAN_DIR" > /dev/null 2>&1; then
    echo -e "${YELLOW}Plan executor is already running for this plan${NC}"
    exit 1
  fi
  
  # Build executor arguments
  local executor_args=$(build_executor_args)
  
  # Start in background with nohup
  nohup $EXECUTOR_SCRIPT $executor_args > "$STATE_DIR/execution.log" 2>&1 &
  echo $! > "$STATE_DIR/.executor.pid"
  
  echo -e "${GREEN}Plan executor started (PID: $(cat "$STATE_DIR/.executor.pid"))${NC}"
  echo "Plan directory: $PLAN_DIR"
  if [ -n "$WORK_DIR" ]; then
    echo "Work directory: $WORK_DIR"
  fi
  echo "State directory: $STATE_DIR"
  echo ""
  echo "Monitor with: $0 monitor"
  echo "View logs with: $0 logs"
}

cmd_stop() {
  echo "Stopping plan execution..."
  
  if [ -f "$STATE_DIR/.executor.pid" ]; then
    PID=$(cat "$STATE_DIR/.executor.pid")
    if kill -0 "$PID" 2>/dev/null; then
      kill "$PID"
      echo -e "${GREEN}Plan executor stopped${NC}"
    else
      echo -e "${YELLOW}Plan executor not running${NC}"
    fi
    rm -f "$STATE_DIR/.executor.pid"
  else
    # Try to find by process name
    pkill -f "plan-executor-v2.sh" || echo -e "${YELLOW}No executor process found${NC}"
  fi
}

cmd_restart() {
  cmd_stop
  sleep 2
  cmd_start
}

cmd_status() {
  # Check if running
  if [ -f "$STATE_DIR/.executor.pid" ] && kill -0 "$(cat "$STATE_DIR/.executor.pid")" 2>/dev/null; then
    echo -e "${GREEN}Plan executor is RUNNING${NC}"
    echo "PID: $(cat "$STATE_DIR/.executor.pid")"
  else
    echo -e "${RED}Plan executor is NOT RUNNING${NC}"
  fi
  
  # Show brief progress
  local state_file=$(get_state_file)
  if [ -f "$state_file" ]; then
    local plan_dir=$(jq -r '.plan_dir // "unknown"' "$state_file")
    local work_dir=$(jq -r '.work_dir // "unknown"' "$state_file")
    local total=0
    
    if [ -d "$plan_dir" ]; then
      total=$(ls "$plan_dir" 2>/dev/null | grep -E "^[0-9]+-.*\.md$" | grep -v "^[0-9]+a-" | grep -v "^00-" | wc -l | tr -d ' ')
    fi
    
    local completed=$(jq -r '.completed_phases | length' "$state_file" 2>/dev/null || echo "0")
    local current=$(jq -r '.current_phase // "none"' "$state_file" 2>/dev/null || echo "none")
    
    echo ""
    echo "Plan: $plan_dir"
    echo "Work: $work_dir"
    echo "Progress: $completed / $total phases completed"
    echo "Current phase: $current"
    
    # Show build tools if detected
    local build_cmd=$(jq -r '.build_command // empty' "$state_file" 2>/dev/null)
    local lint_cmd=$(jq -r '.lint_command // empty' "$state_file" 2>/dev/null)
    if [ -n "$build_cmd" ] || [ -n "$lint_cmd" ]; then
      echo ""
      echo "Detected build tools:"
      [ -n "$build_cmd" ] && echo "  Build: $build_cmd"
      [ -n "$lint_cmd" ] && echo "  Lint: $lint_cmd"
    fi
  fi
}

cmd_reset() {
  echo "This will reset all progress. Are you sure? (yes/no)"
  read -r confirm
  if [ "$confirm" = "yes" ]; then
    rm -rf "$STATE_DIR"
    echo -e "${GREEN}Reset complete${NC}"
  else
    echo "Reset cancelled"
  fi
}

cmd_reset_phase() {
  local phase=$1
  
  if [ -z "$phase" ]; then
    echo "Usage: $0 reset-phase PHASE_NAME"
    echo "Example: $0 reset-phase 02-json-validation-tdd"
    exit 1
  fi
  
  echo "Resetting phase: $phase"
  
  local state_file=$(get_state_file)
  
  # Remove from completed phases
  if [ -f "$state_file" ]; then
    tmp=$(mktemp)
    jq ".completed_phases -= [\"$phase\"]" "$state_file" > "$tmp" && mv "$tmp" "$state_file"
    jq "del(.failed_attempts[\"$phase\"])" "$state_file" > "$tmp" && mv "$tmp" "$state_file"
  fi
  
  # Remove phase logs and reports
  local phase_num=$(echo "$phase" | cut -d'-' -f1)
  rm -f "$STATE_DIR/logs/phase-$phase_num"*.log
  rm -f "$STATE_DIR/logs/build-$phase_num"*.log
  rm -f "$STATE_DIR/logs/lint-$phase_num"*.log
  rm -f "$STATE_DIR/logs/typecheck-$phase_num"*.log
  rm -f "$STATE_DIR/logs/test-$phase_num"*.log
  rm -f "$STATE_DIR/reports/phase-$phase_num.json"
  rm -f "$STATE_DIR/reports/verify-$phase_num.json"
  rm -f "$STATE_DIR/reports/build-checks-$phase_num.txt"
  
  echo -e "${GREEN}Phase $phase reset${NC}"
}

cmd_logs() {
  local phase=$1
  
  if [ -n "$phase" ]; then
    # Show logs for specific phase
    local phase_num=$(echo "$phase" | cut -d'-' -f1)
    local log_file="$STATE_DIR/logs/phase-$phase_num.log"
    
    if [ -f "$log_file" ]; then
      less "$log_file"
    else
      echo "No logs found for phase $phase"
      
      # Show available phase logs
      echo ""
      echo "Available phase logs:"
      ls "$STATE_DIR/logs"/phase-*.log 2>/dev/null | sed 's|.*/phase-||; s|\.log||' | sort -n
    fi
  else
    # Show main execution log
    if [ -f "$STATE_DIR/execution.log" ]; then
      tail -f "$STATE_DIR/execution.log"
    else
      echo "No execution log found. Start execution with: $0 start"
    fi
  fi
}

cmd_skip_phase() {
  local phase=$1
  
  if [ -z "$phase" ]; then
    echo "Usage: $0 skip-phase PHASE_NAME"
    exit 1
  fi
  
  echo "Marking phase as completed (skipping): $phase"
  
  local state_file=$(get_state_file)
  
  if [ ! -f "$state_file" ]; then
    mkdir -p "$STATE_DIR"
    echo '{"current_phase": null, "completed_phases": [], "failed_attempts": {}}' > "$state_file"
  fi
  
  tmp=$(mktemp)
  jq ".completed_phases += [\"$phase\"] | .completed_phases |= unique" "$state_file" > "$tmp" && mv "$tmp" "$state_file"
  echo -e "${GREEN}Phase $phase marked as completed${NC}"
}

cmd_retry_current() {
  local state_file=$(get_state_file)
  
  if [ ! -f "$state_file" ]; then
    echo "No state file found"
    exit 1
  fi
  
  local current=$(jq -r '.current_phase' "$state_file")
  if [ "$current" = "null" ] || [ -z "$current" ]; then
    echo "No current phase to retry"
    exit 1
  fi
  
  echo "Retrying current phase: $current"
  cmd_reset_phase "$current"
  echo "Phase reset. Restart execution with: $0 restart"
}

cmd_monitor() {
  # Launch monitor script with state directory
  local monitor_script="${0%/*}/plan-monitor-v2.sh"
  
  if [ -f "$monitor_script" ]; then
    exec "$monitor_script" -s "$STATE_DIR" "$@"
  else
    echo "Monitor script not found: $monitor_script"
    echo "Showing basic status instead:"
    cmd_status
  fi
}

cmd_init() {
  local plan_dir=$1
  
  if [ -z "$plan_dir" ]; then
    echo "Usage: $0 init PLAN_DIR [OPTIONS]"
    echo ""
    echo "Initialize a new plan execution environment"
    echo ""
    echo "Options:"
    echo "  -w, --work-dir PATH    Working directory for implementation"
    echo "  -c, --config FILE      Configuration file"
    echo ""
    echo "Example:"
    echo "  $0 init ./project-plans/auth/plan -w ./src"
    exit 1
  fi
  
  if [ ! -d "$plan_dir" ]; then
    echo -e "${RED}Error: Plan directory does not exist: $plan_dir${NC}"
    exit 1
  fi
  
  # Convert to absolute path
  PLAN_DIR=$(cd "$plan_dir" && pwd)
  
  # Create state directory
  mkdir -p "$STATE_DIR"
  
  # Create initial state file
  local state_file=$(get_state_file)
  cat > "$state_file" << EOF
{
  "plan_dir": "$PLAN_DIR",
  "work_dir": "${WORK_DIR:-}",
  "current_phase": null,
  "completed_phases": [],
  "failed_attempts": {},
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

  # Create config file template if requested
  if [ -n "$CONFIG_FILE" ]; then
    cat > "$CONFIG_FILE" << 'EOF'
{
  "build_command": "npm run build",
  "lint_command": "npm run lint",
  "test_command": "npm test",
  "typecheck_command": "npm run typecheck",
  "timeout_seconds": 600,
  "max_retries": 3
}
EOF
    echo "Created config template: $CONFIG_FILE"
  fi
  
  echo -e "${GREEN}Initialized plan execution environment${NC}"
  echo "Plan directory: $PLAN_DIR"
  echo "State directory: $STATE_DIR"
  echo ""
  echo "Next steps:"
  echo "  1. Review/edit the plan files in: $PLAN_DIR"
  if [ -n "$CONFIG_FILE" ]; then
    echo "  2. Edit the configuration: $CONFIG_FILE"
  fi
  echo "  3. Start execution: $0 start"
}

cmd_help() {
  cat << EOF
Usage: $0 [GLOBAL_OPTIONS] COMMAND [ARGS]

Global Options:
  -p, --plan-dir PATH    Plan directory (can be stored in state)
  -w, --work-dir PATH    Working directory for implementation
  -s, --state-dir PATH   State directory (default: ./plan-execution)
  -c, --config FILE      Configuration file

Commands:
  init PLAN_DIR          Initialize new plan execution
  start                  Start plan execution in background
  stop                   Stop plan execution
  restart                Restart plan execution
  status                 Show execution status
  monitor                Launch interactive monitor
  reset                  Reset all progress (requires confirmation)
  reset-phase PHASE      Reset specific phase
  skip-phase PHASE       Mark phase as completed without executing
  retry-current          Reset and retry the current phase
  logs [PHASE]           Show execution logs or phase logs
  help                   Show this help

Examples:
  # Initialize a new plan
  $0 init ./project-plans/auth/plan -w ./src

  # Start execution
  $0 -p ./project-plans/auth/plan start

  # Monitor progress
  $0 monitor

  # View logs for specific phase
  $0 logs 02-json-validation-tdd

  # Reset and retry a phase
  $0 reset-phase 02-json-validation-tdd
  $0 restart

Build and Lint Verification:
  The executor automatically detects and runs build tools:
  - Node.js: npm run build, npm run lint, npm run typecheck
  - Python: setup.py build, ruff/flake8, mypy
  
  Configure custom commands in a JSON config file:
  {
    "build_command": "make build",
    "lint_command": "make lint",
    "test_command": "make test"
  }
EOF
}

# Main
main() {
  # Parse global options
  local remaining_args=$(parse_global_options "$@")
  set -- $remaining_args
  
  # Get command
  local command="${1:-help}"
  shift || true
  
  # Execute command
  case "$command" in
    init)
      cmd_init "$@"
      ;;
    start)
      cmd_start "$@"
      ;;
    stop)
      cmd_stop "$@"
      ;;
    restart)
      cmd_restart "$@"
      ;;
    status)
      cmd_status "$@"
      ;;
    monitor)
      cmd_monitor "$@"
      ;;
    reset)
      cmd_reset "$@"
      ;;
    reset-phase)
      cmd_reset_phase "$@"
      ;;
    skip-phase)
      cmd_skip_phase "$@"
      ;;
    retry-current)
      cmd_retry_current "$@"
      ;;
    logs)
      cmd_logs "$@"
      ;;
    help)
      cmd_help
      ;;
    *)
      echo -e "${RED}Unknown command: $command${NC}"
      cmd_help
      exit 1
      ;;
  esac
}

# Run main
main "$@"