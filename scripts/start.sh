#!/bin/bash

# Start Development Timeline
# This script starts the background commit process

set -e

echo "🎯 Starting development timeline..."
echo "⏰ This will run for 15 hours with natural commit patterns"
echo "📅 Starting at: $(date)"
echo ""

# Create initial commit
echo "🚀 Creating initial commit..."
git add README.md
git commit -m "Initial commit" || true

echo "✅ Initial commit created"
echo ""

# Start the background commit process
echo "🔄 Starting background commit process..."
echo "📝 This will create commits over 15 hours with realistic timing"
echo "📊 You can check progress in: commit-timeline.log"
echo ""

# Start the background process
nohup ./scripts/realistic-timeline.sh > commit-timeline.log 2>&1 &

# Get the process ID
COMMIT_PID=$!
echo "🆔 Background process PID: $COMMIT_PID"
echo "📝 Log file: commit-timeline.log"
echo ""

# Save PID for later reference
echo $COMMIT_PID > commit-process.pid

echo "✅ Background commit process started!"
echo "📅 Expected completion: $(date -d "+15 hours" '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "🔍 To check progress:"
echo "   tail -f commit-timeline.log"
echo ""
echo "🛑 To stop the process:"
echo "   kill $COMMIT_PID"
echo ""
echo "📊 To check if still running:"
echo "   ps -p $COMMIT_PID"
