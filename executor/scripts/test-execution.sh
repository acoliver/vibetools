#!/bin/bash
# Test script to verify plan execution works

set -euo pipefail

echo "Testing plan executor with hello world example..."

# Clean up any previous state
rm -rf ./plan-execution

# Initialize
./plan-control.sh init ../test-plan/plan -w ../test-plan

# Check status
echo ""
echo "Initial status:"
./plan-control.sh status

# Start execution 
echo ""
echo "Starting execution..."
./plan-control.sh start

# Wait a bit for it to start
sleep 2

# Monitor progress
echo ""
echo "Monitoring progress for 10 seconds..."
timeout 10 ./plan-monitor.sh -c 2 || true

# Check final status
echo ""
echo "Final status:"
./plan-control.sh status

# Check if build checks ran
echo ""
echo "Build check results:"
if [ -f "./plan-execution/reports/build-checks-01.txt" ]; then
  cat "./plan-execution/reports/build-checks-01.txt"
else
  echo "No build checks found for phase 01"
fi

# Show logs
echo ""
echo "Execution logs (last 20 lines):"
tail -20 ./plan-execution/execution.log || echo "No logs found"

echo ""
echo "Test complete!"