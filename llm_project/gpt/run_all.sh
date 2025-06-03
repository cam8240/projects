#!/bin/bash

# Kill existing processes on ports
fuser -k 5000/tcp 8080/tcp 6000/tcp

# Start each in a new terminal or detached process
python3 ./app.py &
FLASK_PID=$!

python3 -m http.server 8080 &
HTTP_PID=$!

go run analyzer.go &
GO_PID=$!

# Trap Ctrl+C to kill everything
trap "kill $FLASK_PID $HTTP_PID $GO_PID; exit" INT

# Wait on all
wait
