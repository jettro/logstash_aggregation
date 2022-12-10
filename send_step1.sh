#!/usr/bin/env bash

result=$(curl -s -X POST http://localhost:8080 \
   -H "Content-Type: application/json" \
   -d '{"user_id": 123456, "timestamp": "2017-08-17T12:47:16+02:00", "action": "start_session"}' \
)

echo "Send step 1: $result"