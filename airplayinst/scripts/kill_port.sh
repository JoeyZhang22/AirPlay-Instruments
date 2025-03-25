#!/bin/bash

PORT=60003

echo "Looking for processes running on port $PORT..."

# Get PIDs as an array
mapfile -t PIDS < <(lsof -ti tcp:$PORT)

if [ ${#PIDS[@]} -eq 0 ]; then
  echo "No processes found on port $PORT."
else
  echo "Killing the following PIDs using port $PORT: ${PIDS[*]}"
  for PID in "${PIDS[@]}"; do
    kill -9 "$PID" && echo "Killed PID $PID"
  done
  echo "Processes terminated."
fi
