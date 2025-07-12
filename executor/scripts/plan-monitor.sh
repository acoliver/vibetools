#!/bin/bash
# plan-monitor.sh - Monitor execution progress with flexible configuration
# Usage: ./plan-monitor.sh [OPTIONS]

set -euo pipefail

# Default configuration
STATE_DIR="./plan-execution"
REFRESH_SECONDS=5

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

# Parse arguments
parse_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      -s|--state-dir)
        STATE_DIR="$2"
        shift 2
        ;;
      -c|--continuous)
        CONTINUOUS_MODE=true
        if [[ "${2:-}" =~ ^[0-9]+$ ]]; then
          REFRESH_SECONDS="$2"
          shift
        fi
        shift
        ;;
      -p|--phase)
        CHECK_PHASE="$2"
        shift 2
        ;;
      -l|--logs)
        SHOW_LOGS=true
        LOG_COUNT="${2:-20}"
        if [[ "$LOG_COUNT" =~ ^[0-9]+$ ]]; then
          shift
        else
          LOG_COUNT=20
        fi
        shift
        ;;
      -b|--build-status)
        SHOW_BUILD_STATUS=true
        shift
        ;;
      -h|--help)
        show_help
        exit 0
        ;;
      *)
        echo "Unknown option: $1"
        show_help
        exit 1
        ;;
    esac
  done
}

show_help() {
  cat << EOF
Usage: $0 [OPTIONS]

Monitor plan execution progress with build status tracking

Options:
  -s, --state-dir PATH       State directory (default: ./plan-execution)
  -c, --continuous [SECS]    Continuous monitoring (default: 5s refresh)
  -p, --phase PHASE          Check specific phase status
  -l, --logs [COUNT]         Show latest log entries (default: 20)
  -b, --build-status         Show detailed build/lint status
  -h, --help                 Show this help

Examples:
  $0                         # Show current status
  $0 -c                      # Continuous monitoring
  $0 -c 10                   # Continuous with 10s refresh
  $0 -p 02-json-tdd          # Check specific phase
  $0 -b                      # Show build status details
  $0 -l 50                   # Show last 50 log lines

Keyboard shortcuts (in continuous mode):
  q - Quit
  r - Refresh immediately
  b - Toggle build status details
  l - Toggle log view
EOF
}

# Get state file path
get_state_file() {
  echo "$STATE_DIR/plan-state.json"
}

# Check if execution is running
is_running() {
  if [ -f "$STATE_DIR/.executor.pid" ]; then
    kill -0 "$(cat "$STATE_DIR/.executor.pid")" 2>/dev/null
  else
    false
  fi
}

# Format duration
format_duration() {
  local seconds=$1
  local hours=$((seconds / 3600))
  local minutes=$(((seconds % 3600) / 60))
  local secs=$((seconds % 60))
  
  if [ $hours -gt 0 ]; then
    printf "%dh %dm %ds" $hours $minutes $secs
  elif [ $minutes -gt 0 ]; then
    printf "%dm %ds" $minutes $secs
  else
    printf "%ds" $secs
  fi
}

# Get phase status with icon
get_phase_status_icon() {
  local phase=$1
  local phase_num=$(echo "$phase" | cut -d'-' -f1)
  local state_file=$(get_state_file)
  
  # Check if completed
  local completed=$(jq -r ".completed_phases[] | select(. == \"$phase\")" "$state_file" 2>/dev/null || echo "")
  if [ -n "$completed" ]; then
    echo -e "${GREEN}✓${NC}"
    return
  fi
  
  # Check if current
  local current=$(jq -r '.current_phase' "$state_file" 2>/dev/null)
  if [ "$current" = "$phase" ]; then
    echo -e "${YELLOW}⟳${NC}"
    return
  fi
  
  # Check if failed
  local failed=$(jq -r ".failed_attempts[\"$phase\"]" "$state_file" 2>/dev/null)
  if [ "$failed" != "null" ] && [ -n "$failed" ]; then
    echo -e "${RED}✗${NC}"
    return
  fi
  
  # Not started
  echo "○"
}

# Show phase build status
show_phase_build_status() {
  local phase=$1
  local phase_num=$(echo "$phase" | cut -d'-' -f1)
  
  # Check for build check results
  local build_check_file="$STATE_DIR/reports/build-checks-$phase_num.txt"
  if [ -f "$build_check_file" ]; then
    echo -e "${BLUE}Build Status:${NC}"
    cat "$build_check_file" | sed 's/^/    /'
  fi
}

# Get latest log lines
get_latest_logs() {
  local count=${1:-10}
  local latest_log=$(ls -t "$STATE_DIR/logs"/*.log 2>/dev/null | head -1)
  
  if [ -n "$latest_log" ]; then
    echo -e "${BLUE}Latest Activity ($(basename "$latest_log")):${NC}"
    tail -n "$count" "$latest_log" 2>/dev/null | sed 's/^/  /'
  fi
}

# Calculate progress percentage
calculate_progress() {
  local total=$1
  local completed=$2
  
  if [ "$total" -eq 0 ]; then
    echo "0"
  else
    echo "$((completed * 100 / total))"
  fi
}

# Show progress bar with color
show_progress_bar() {
  local percentage=$1
  local width=50
  local filled=$((percentage * width / 100))
  local empty=$((width - filled))
  
  # Choose color based on percentage
  local color=$RED
  if [ $percentage -ge 75 ]; then
    color=$GREEN
  elif [ $percentage -ge 50 ]; then
    color=$YELLOW
  fi
  
  printf "["
  printf "${color}%${filled}s${NC}" | tr ' ' '█'
  printf "%${empty}s" | tr ' ' '░'
  printf "] ${BOLD}%d%%${NC}\n" "$percentage"
}

# Show detailed phase information
show_phase_details() {
  local phase=$1
  local phase_num=$(echo "$phase" | cut -d'-' -f1)
  local state_file=$(get_state_file)
  
  echo -e "\n${CYAN}=== Phase Details: $phase ===${NC}"
  
  # Show status
  local icon=$(get_phase_status_icon "$phase")
  echo -e "Status: $icon $phase"
  
  # Show timestamps
  local current=$(jq -r '.current_phase' "$state_file" 2>/dev/null)
  if [ "$current" = "$phase" ]; then
    echo -e "${YELLOW}Currently executing...${NC}"
    
    # Show phase report if exists
    if [ -f "$STATE_DIR/reports/phase-$phase_num.json" ]; then
      local status=$(jq -r '.status // "unknown"' "$STATE_DIR/reports/phase-$phase_num.json")
      local deliverables=$(jq -r '.deliverables[]? // empty' "$STATE_DIR/reports/phase-$phase_num.json" 2>/dev/null)
      
      if [ -n "$deliverables" ]; then
        echo -e "\n${BLUE}Deliverables:${NC}"
        echo "$deliverables" | sed 's/^/  - /'
      fi
    fi
  fi
  
  # Show verification results
  if [ -f "$STATE_DIR/reports/verify-$phase_num.json" ]; then
    echo -e "\n${BLUE}Verification Results:${NC}"
    local verify_status=$(jq -r '.status' "$STATE_DIR/reports/verify-$phase_num.json")
    local checks_passed=$(jq -r '.checks_passed // 0' "$STATE_DIR/reports/verify-$phase_num.json")
    local checks_failed=$(jq -r '.checks_failed // 0' "$STATE_DIR/reports/verify-$phase_num.json")
    
    if [ "$verify_status" = "pass" ]; then
      echo -e "  ${GREEN}✓ Passed${NC} ($checks_passed checks)"
    else
      echo -e "  ${RED}✗ Failed${NC} ($checks_failed failed, $checks_passed passed)"
      
      local issues=$(jq -r '.issues[]?' "$STATE_DIR/reports/verify-$phase_num.json" 2>/dev/null)
      if [ -n "$issues" ]; then
        echo -e "  ${RED}Issues:${NC}"
        echo "$issues" | sed 's/^/    - /'
      fi
    fi
  fi
  
  # Show build status
  if [ "${SHOW_BUILD_STATUS:-false}" = true ]; then
    echo ""
    show_phase_build_status "$phase"
  fi
  
  # Show recent logs
  echo -e "\n${BLUE}Recent Logs:${NC}"
  if [ -f "$STATE_DIR/logs/phase-$phase_num.log" ]; then
    tail -20 "$STATE_DIR/logs/phase-$phase_num.log" | sed 's/^/  /'
  else
    echo "  No logs available"
  fi
}

# Main monitoring display
show_monitor() {
  clear
  
  local state_file=$(get_state_file)
  
  if [ ! -f "$state_file" ]; then
    echo -e "${RED}No state file found at: $state_file${NC}"
    echo "Has the plan been initialized? Use: plan-control.sh init PLAN_DIR"
    return
  fi
  
  # Header
  echo -e "${CYAN}${BOLD}═══ Plan Execution Monitor ═══${NC}"
  echo -e "Time: $(date '+%Y-%m-%d %H:%M:%S')"
  
  # Execution status
  if is_running; then
    echo -e "Status: ${GREEN}${BOLD}RUNNING${NC} (PID: $(cat "$STATE_DIR/.executor.pid"))"
  else
    echo -e "Status: ${RED}${BOLD}NOT RUNNING${NC}"
  fi
  
  # Plan information
  local plan_dir=$(jq -r '.plan_dir // "unknown"' "$state_file")
  local work_dir=$(jq -r '.work_dir // "not specified"' "$state_file")
  
  echo -e "\n${BLUE}Plan Information:${NC}"
  echo "Plan: $plan_dir"
  echo "Work: $work_dir"
  
  # Build tools
  local build_cmd=$(jq -r '.build_command // empty' "$state_file" 2>/dev/null)
  local lint_cmd=$(jq -r '.lint_command // empty' "$state_file" 2>/dev/null)
  local typecheck_cmd=$(jq -r '.typecheck_command // empty' "$state_file" 2>/dev/null)
  
  if [ -n "$build_cmd" ] || [ -n "$lint_cmd" ] || [ -n "$typecheck_cmd" ]; then
    echo -e "\n${BLUE}Build Tools:${NC}"
    [ -n "$build_cmd" ] && echo "  Build: $build_cmd"
    [ -n "$lint_cmd" ] && echo "  Lint: $lint_cmd"
    [ -n "$typecheck_cmd" ] && echo "  Type Check: $typecheck_cmd"
  fi
  
  # Progress
  local all_phases=()
  if [ -d "$plan_dir" ]; then
    all_phases=($(ls "$plan_dir" 2>/dev/null | grep -E "^[0-9]+-.*\.md$" | grep -v "^[0-9]+a-" | grep -v "^00-" | sort -n | sed 's/\.md$//' || echo ""))
  fi
  
  local total=${#all_phases[@]}
  local completed=$(jq -r '.completed_phases | length' "$state_file" 2>/dev/null || echo "0")
  local percentage=$(calculate_progress "$total" "$completed")
  
  echo -e "\n${BLUE}Overall Progress:${NC}"
  show_progress_bar "$percentage"
  echo "Completed: $completed / $total phases"
  
  # Current phase details
  local current=$(jq -r '.current_phase // null' "$state_file" 2>/dev/null)
  if [ "$current" != "null" ] && [ -n "$current" ]; then
    echo -e "\n${BLUE}Current Phase:${NC} ${BOLD}$current${NC}"
    
    # Show execution time if available
    local start_time=$(jq -r '.created_at // empty' "$state_file" 2>/dev/null)
    if [ -n "$start_time" ] && command -v date >/dev/null 2>&1; then
      local start_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$start_time" +%s 2>/dev/null || date -d "$start_time" +%s 2>/dev/null || echo "0")
      if [ "$start_epoch" -gt 0 ]; then
        local now_epoch=$(date +%s)
        local duration=$((now_epoch - start_epoch))
        echo "Execution time: $(format_duration $duration)"
      fi
    fi
  fi
  
  # Phase list
  echo -e "\n${BLUE}Phase Status:${NC}"
  if [ ${#all_phases[@]} -gt 0 ]; then
    for phase in "${all_phases[@]}"; do
      local icon=$(get_phase_status_icon "$phase")
      local color=""
      
      # Add color based on status
      if [[ "$icon" == *"✓"* ]]; then
        color=$GREEN
      elif [[ "$icon" == *"⟳"* ]]; then
        color=$YELLOW
      elif [[ "$icon" == *"✗"* ]]; then
        color=$RED
      fi
      
      echo -e "  $icon ${color}$phase${NC}"
      
      # Show failure info if failed
      local failed=$(jq -r ".failed_attempts[\"$phase\"]" "$state_file" 2>/dev/null)
      if [ "$failed" != "null" ] && [ -n "$failed" ]; then
        local attempts=$(echo "$failed" | jq -r '.attempts')
        local last_error=$(echo "$failed" | jq -r '.last_error')
        echo -e "     ${RED}Failed $attempts times: $last_error${NC}"
      fi
    done
  else
    echo "  No phases found"
  fi
  
  # Recent activity
  if [ "${SHOW_LOGS:-true}" = true ]; then
    echo ""
    get_latest_logs 5
  fi
  
  # Footer
  if [ "${CONTINUOUS_MODE:-false}" = true ]; then
    echo -e "\n${MAGENTA}Refreshing every ${REFRESH_SECONDS}s (Press Ctrl+C to stop)${NC}"
  fi
}

# Check specific phase
check_phase() {
  local phase=$1
  local state_file=$(get_state_file)
  
  if [ ! -f "$state_file" ]; then
    echo -e "${RED}No state file found${NC}"
    exit 1
  fi
  
  show_phase_details "$phase"
}

# Show build status summary
show_build_summary() {
  local state_file=$(get_state_file)
  
  if [ ! -f "$state_file" ]; then
    echo -e "${RED}No state file found${NC}"
    exit 1
  fi
  
  echo -e "${CYAN}${BOLD}=== Build Status Summary ===${NC}"
  
  # Get all completed phases
  local completed_phases=($(jq -r '.completed_phases[]' "$state_file" 2>/dev/null))
  
  for phase in "${completed_phases[@]}"; do
    local phase_num=$(echo "$phase" | cut -d'-' -f1)
    local build_check_file="$STATE_DIR/reports/build-checks-$phase_num.txt"
    
    if [ -f "$build_check_file" ]; then
      echo -e "\n${BLUE}$phase:${NC}"
      cat "$build_check_file" | sed 's/^/  /'
    fi
  done
}

# Continuous monitoring
monitor_continuous() {
  while true; do
    show_monitor
    sleep "$REFRESH_SECONDS"
  done
}

# Main
main() {
  parse_args "$@"
  
  # Handle specific modes
  if [ "${CHECK_PHASE:-}" ]; then
    check_phase "$CHECK_PHASE"
  elif [ "${SHOW_LOGS:-false}" = true ]; then
    get_latest_logs "$LOG_COUNT"
  elif [ "${SHOW_BUILD_STATUS:-false}" = true ]; then
    show_build_summary
  elif [ "${CONTINUOUS_MODE:-false}" = true ]; then
    monitor_continuous
  else
    show_monitor
  fi
}

# Handle interrupts gracefully
trap 'echo -e "\n${MAGENTA}Monitoring stopped${NC}"; exit 0' INT TERM

# Run main
main "$@"