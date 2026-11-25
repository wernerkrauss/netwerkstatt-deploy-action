#!/usr/bin/env bash
set -uo pipefail

message="${NOTIFICATION_MESSAGE:?Notification message is required}"
sent_any=false
failed=false

if [[ -n "${DISCORD_WEBHOOK_URL:-}" ]]; then
  sent_any=true
  payload="$(jq -n --arg content "$message" '{content: $content}')"
  if ! curl --silent --fail --max-time 15 \
    --header 'Content-Type: application/json' \
    --data "$payload" \
    "$DISCORD_WEBHOOK_URL" \
    --output /dev/null; then
    echo "Discord notification failed." >&2
    failed=true
  fi
fi

callmebot_phone="${CALLMEBOT_PHONE:-}"
callmebot_api_key="${CALLMEBOT_API_KEY:-}"
if [[ -n "$callmebot_phone" || -n "$callmebot_api_key" ]]; then
  sent_any=true
  if [[ -z "$callmebot_phone" || -z "$callmebot_api_key" ]]; then
    echo "CallMeBot requires both CALLMEBOT_PHONE and CALLMEBOT_API_KEY." >&2
    failed=true
  elif ! curl --silent --fail --max-time 15 --get \
    --data-urlencode "phone=$callmebot_phone" \
    --data-urlencode "text=$message" \
    --data-urlencode "apikey=$callmebot_api_key" \
    'https://api.callmebot.com/whatsapp.php' \
    --output /dev/null; then
    echo "CallMeBot notification failed." >&2
    failed=true
  fi
fi

if [[ "$sent_any" == false ]]; then
  echo "::warning::No notification endpoint configured; add DISCORD_WEBHOOK_URL as an Actions secret or configure CallMeBot secrets."
fi

if [[ "$failed" == true ]]; then
  exit 1
fi
