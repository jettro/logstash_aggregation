#!/usr/bin/env bash

result=$(curl -s -X POST http://localhost:8080 \
   -H "Content-Type: application/json" \
   -d '{"user_id": 111111, "timestamp": "2017-08-17T12:48:16+02:00", "action": "start_session"}' \
)

echo "Send step 2 - create session : $result"

result=$(curl -s -X POST http://localhost:8080 \
   -H "Content-Type: application/json" \
   -d '{"user_id": 111111, "timestamp": "2017-08-17T12:49:16+02:00", "action": "visit_url", "visit_url": "https://luminis.eu"}' \
)

echo "Send step 2 - add visited url: $result"

result=$(curl -s -X POST http://localhost:8080 \
   -H "Content-Type: application/json" \
   -d '{"user_id": 111111, "timestamp": "2017-08-17T12:49:16+02:00", "action": "visit_url", "visit_url": "https://luminis.eu/blogs"}' \
)

echo "Send step 2 - add 2nd visited url: $result"