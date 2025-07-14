#!/bin/bash

cd $(dirname $(realpath $0))


PORT=5678
NGROK_LOG=ngrok.log
ENV_FILE=.env

start() {
  echo "Stopping any existing ngrok..."
  pkill ngrok

  echo "Starting ngrok on port $PORT..."
  nohup ngrok http $PORT > $NGROK_LOG 2>&1 &

  echo "Waiting for ngrok to initialize..."
  sleep 1

  NGROK_URL=$(curl --silent http://127.0.0.1:4040/api/tunnels | jq -r '.tunnels[0].public_url')

  if [[ -z "$NGROK_URL" || "$NGROK_URL" == "null" ]]; then
    echo "Failed to get ngrok URL"
    exit 1
  fi

  echo "Ngrok URL is $NGROK_URL"

  if grep -q '^WEBHOOK_URL=' $ENV_FILE; then
    sed -i "s|^WEBHOOK_URL=.*|WEBHOOK_URL=$NGROK_URL|" $ENV_FILE
  else
    echo "WEBHOOK_URL=$NGROK_URL" >> $ENV_FILE
  fi

  echo "Starting docker-compose..."
  docker-compose up -d
}

stop() {
  echo "Stopping docker-compose services..."
  docker-compose down

  echo "Stopping ngrok..."
  pkill ngrok

  echo "All stopped."
}

case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  *)
    echo "Usage: $0 {start|stop}"
    exit 1
    ;;
esac
