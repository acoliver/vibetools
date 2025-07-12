# Plan Executor - Automated TDD Workflow Engine

A flexible automation system for executing Test-Driven Development (TDD) plans with automatic build verification and error recovery.

## Features

- **Flexible Plan Execution**: Execute TDD plans from any directory
- **Automatic Build Verification**: Detects and runs build/lint/test commands
- **Smart Error Recovery**: Automatically fixes compilation and lint errors
- **Progress Monitoring**: Real-time progress tracking with visual feedback
- **State Persistence**: Resume execution after interruptions

## Quick Start

### 1. Initialize a Plan

```bash
./scripts/plan-control.sh init /path/to/your/plan -w /path/to/work/directory
```

### 2. Start Execution

```bash
./scripts/plan-control.sh start
```

### 3. Monitor Progress

```bash
./scripts/plan-control.sh monitor
```

## Plan Structure

Plans consist of numbered phase files in a directory:

```
plan/
├── 01-stub.md          # Create minimal implementation
├── 01a-verification.md # Verify stub (optional)
├── 02-tdd.md          # Write failing tests
├── 03-implementation.md # Make tests pass
└── ...
```

## Build Tool Detection

The executor automatically detects:

- **Node.js**: `package.json` scripts (build, lint, typecheck)
- **Python**: `setup.py`, ruff/flake8, mypy
- **TypeScript**: `tsconfig.json` → `tsc --noEmit`

Or provide custom commands via config:

```json
{
  "build_command": "make build",
  "lint_command": "make lint",
  "test_command": "make test",
  "typecheck_command": "mypy src/"
}
```

## Commands

### Control Script

```bash
# Initialize new plan
./scripts/plan-control.sh init PLAN_DIR [-w WORK_DIR] [-c CONFIG_FILE]

# Execution control
./scripts/plan-control.sh start     # Start execution
./scripts/plan-control.sh stop      # Stop execution
./scripts/plan-control.sh restart   # Restart execution
./scripts/plan-control.sh status    # Show status

# Phase management
./scripts/plan-control.sh reset-phase PHASE_NAME  # Reset specific phase
./scripts/plan-control.sh skip-phase PHASE_NAME   # Skip a phase
./scripts/plan-control.sh retry-current           # Retry current phase

# Monitoring
./scripts/plan-control.sh monitor   # Interactive monitor
./scripts/plan-control.sh logs [PHASE]  # View logs
```

### Monitor Script

```bash
# Continuous monitoring
./scripts/plan-monitor.sh -c [SECONDS]

# Check specific phase
./scripts/plan-monitor.sh -p PHASE_NAME

# Show build status
./scripts/plan-monitor.sh -b
```

## Example Plan

See `test-plan/` for a complete example implementing a "Hello World" module using TDD.

## How It Works

1. **Phase Execution**: Claude reads phase instructions and implements them
2. **Verification**: Optional verification phase checks deliverables
3. **Build Checks**: Automatic compilation, lint, and type checking
4. **Error Recovery**: On failure, Claude receives error details and fixes issues
5. **Progress Tracking**: State persisted for resumable execution

## Requirements

- Bash 4.0+
- Claude CLI
- jq (for JSON processing)
- Project-specific build tools (npm, python, etc.)

## Tips

- Always verify plans compile before committing
- Use verification phases for critical implementations
- Monitor build status with `-b` flag
- Check logs when phases fail for detailed errors
- State persists across restarts - no progress lost

## License

Part of the vibetools project.