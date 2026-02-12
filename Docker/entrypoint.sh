#!/usr/bin/env bash
set -e

source /opt/ros/jazzy/setup.bash

echo ""
echo "======================================"
echo "Container is running (debug mode)"
echo "You can now exec into it:"
echo "  ./scripts/alias shell"
echo ""
echo "To test the real launch, run inside the shell:"
echo "  ros2 launch husarion_ugv_autonomy autonomy.launch.py"
echo "  # or with SLAM:"
echo "  ros2 launch husarion_ugv_autonomy autonomy.launch.py slam:=true use_sim_time:=false"
echo "======================================"
echo ""

# Keep container alive forever
exec tail -f /dev/null
# or: exec sleep infinity
