#!/bin/bash
MESSAGE="$1"
MODE="${2:-friendly}"        # Default mode is 'friendly'
SESSION="${3:-default}"      # Optional session ID

curl -s -X POST http://localhost:5000/chat \
  -H "Content-Type: application/json" \
  -d "{\"message\": \"$MESSAGE\", \"mode\": \"$MODE\", \"session_id\": \"$SESSION\"}" \
  | jq -r '.reply'