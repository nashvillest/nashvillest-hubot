#!/bin/bash

# Start the Slack instance
npm run start:slack &

# Start the Discord adapter
npm run start:discord &

# Wait for any process to exit
wait -n

# Exit with status of process that exited first
exit $?
