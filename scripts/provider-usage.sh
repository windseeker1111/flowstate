#!/bin/bash
# Unified Provider Usage Dashboard
# Queries all configured LLM providers for real-time usage data:
#   - Anthropic Claude Max (via OAuth API)
#   - Google Antigravity (via CodexBar CLI)

set -euo pipefail

FORMAT="text"
FORCE_REFRESH=0
TOKEN_DIR="${TOKEN_DIR:-$HOME/.openclaw/usage-tokens}"
CACHE_FILE="/tmp/provider-usage-cache"
CACHE_TTL=60
SHOW_ANTHROPIC=1
SHOW_ANTIGRAVITY=1

while [[ $# -gt 0 ]]; do
  case $1 in
    --json) FORMAT="json"; shift ;;
    --fresh|--force) FORCE_REFRESH=1; shift ;;
    --cache-ttl) CACHE_TTL="$2"; shift 2 ;;
    --anthropic-only) SHOW_ANTIGRAVITY=0; shift ;;
    --antigravity-only) SHOW_ANTHROPIC=0; shift ;;
    -h|--help)
      cat <<'EOF'
Usage: provider-usage.sh [OPTIONS]

Unified usage dashboard for all LLM providers.

Options:
  --fresh, --force       Force refresh (ignore cache)
  --json                 JSON output
  --cache-ttl SEC        Cache TTL (default: 60)
  --anthropic-only       Show only Anthropic accounts
  --antigravity-only     Show only Antigravity
  -h, --help             Show this help
EOF
      exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Check cache
if [ "$FORCE_REFRESH" -eq 0 ] && [ -f "$CACHE_FILE" ]; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
    age=$(($(date +%s) - $(stat -f%m "$CACHE_FILE")))
  else
    age=$(($(date +%s) - $(stat -c%Y "$CACHE_FILE")))
  fi
  if [ "$age" -lt "$CACHE_TTL" ]; then
    cat "$CACHE_FILE"
    exit 0
  fi
fi

# ── Helpers ──────────────────────────────────────────────────────────

secs_to_human() {
  local secs=$1
  if [ "$secs" -lt 0 ]; then secs=0; fi
  local days=$((secs / 86400))
  local hours=$(((secs % 86400) / 3600))
  local mins=$(((secs % 3600) / 60))
  if [ "$days" -gt 0 ]; then echo "${days}d ${hours}h"
  elif [ "$hours" -gt 0 ]; then echo "${hours}h ${mins}m"
  else echo "${mins}m"
  fi
}

bar() {
  local pct=${1%.*}
  local filled=$((pct / 10))
  local empty=$((10 - filled))
  local b=""
  for ((i=0; i<filled; i++)); do b+="█"; done
  for ((i=0; i<empty; i++)); do b+="░"; done
  echo "$b"
}

dot() {
  local pct=${1%.*}
  if [ "$pct" -ge 80 ]; then echo "🔴"
  elif [ "$pct" -ge 50 ]; then echo "🟡"
  else echo "🟢"
  fi
}

NOW=$(date +%s)
JSON_SECTIONS=""
TEXT_OUTPUT=""

# ── Anthropic Claude Max ─────────────────────────────────────────────

if [ "$SHOW_ANTHROPIC" -eq 1 ] && [ -d "$TOKEN_DIR" ]; then
  ACCT_FILES=$(ls "$TOKEN_DIR"/account-*.json 2>/dev/null || echo "")
  if [ -n "$ACCT_FILES" ]; then
    TEXT_OUTPUT+="━━━ Anthropic Claude Max ━━━━━━━━━━━━━━━━━━━━\n\n"

    for TOKEN_FILE in $ACCT_FILES; do
      LABEL=$(python3 -c "import json; d=json.load(open('$TOKEN_FILE')); print(d.get('label','?'))")
      EMAIL=$(python3 -c "import json; d=json.load(open('$TOKEN_FILE')); print(d.get('email','?'))")
      TOKEN=$(python3 -c "import json; d=json.load(open('$TOKEN_FILE')); print(d.get('accessToken',''))")

      if [ -z "$TOKEN" ]; then
        TEXT_OUTPUT+="  ⚠️  $LABEL: No token\n\n"
        continue
      fi

      RESP=$(curl -s --max-time 10 "https://api.anthropic.com/api/oauth/usage" \
        -H "Authorization: Bearer $TOKEN" \
        -H "anthropic-beta: oauth-2025-04-20" 2>/dev/null || echo "")

      if echo "$RESP" | grep -q '"error"' 2>/dev/null; then
        ERROR_MSG=$(echo "$RESP" | python3 -c "import json,sys; print(json.load(sys.stdin)['error']['message'])" 2>/dev/null || echo "API error")
        TEXT_OUTPUT+="  ⚠️  $LABEL ($EMAIL): $ERROR_MSG\n\n"
        JSON_SECTIONS+="${JSON_SECTIONS:+,}{\"provider\":\"anthropic\",\"account\":\"$LABEL\",\"email\":\"$EMAIL\",\"error\":\"$ERROR_MSG\"}"
        continue
      fi

      # Parse all fields
      PARSED=$(python3 << PYEOF
import json
d = json.loads('''$RESP''')
fh = d.get('five_hour') or {}
sd = d.get('seven_day') or {}
sn = d.get('seven_day_sonnet') or {}
op = d.get('seven_day_opus') or {}
ex = d.get('extra_usage') or {}
cw = d.get('seven_day_cowork') or {}
print(fh.get('utilization', 0))
print(fh.get('resets_at', ''))
print(sd.get('utilization', 0))
print(sd.get('resets_at', ''))
print(sn.get('utilization', 0))
print(sn.get('resets_at', ''))
print(op.get('utilization', 0))
print(op.get('resets_at', ''))
print(ex.get('is_enabled', False))
print(ex.get('utilization', 0))
print(ex.get('used_credits', 0))
print(ex.get('monthly_limit', 0))
print(cw.get('utilization', 0))
PYEOF
      )

      SESSION_PCT=$(echo "$PARSED" | sed -n '1p')
      SESSION_RESET=$(echo "$PARSED" | sed -n '2p')
      WEEKLY_PCT=$(echo "$PARSED" | sed -n '3p')
      WEEKLY_RESET=$(echo "$PARSED" | sed -n '4p')
      SONNET_PCT=$(echo "$PARSED" | sed -n '5p')
      SONNET_RESET=$(echo "$PARSED" | sed -n '6p')
      OPUS_PCT=$(echo "$PARSED" | sed -n '7p')
      OPUS_RESET=$(echo "$PARSED" | sed -n '8p')
      EXTRA_ENABLED=$(echo "$PARSED" | sed -n '9p')
      EXTRA_PCT=$(echo "$PARSED" | sed -n '10p')
      EXTRA_USED=$(echo "$PARSED" | sed -n '11p')
      EXTRA_LIMIT=$(echo "$PARSED" | sed -n '12p')
      COWORK_PCT=$(echo "$PARSED" | sed -n '13p')

      # Convert reset timestamps to human-readable
      parse_reset() {
        local reset_ts="$1"
        if [ -z "$reset_ts" ] || [ "$reset_ts" = "None" ] || [ "$reset_ts" = "" ]; then
          echo "—"
          return
        fi
        local clean=$(echo "$reset_ts" | sed 's/\.[0-9]*+.*//;s/\.[0-9]*Z//')
        local epoch=0
        if [[ "$OSTYPE" == "darwin"* ]]; then
          epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$clean" +%s 2>/dev/null || echo 0)
        else
          epoch=$(date -d "$reset_ts" +%s 2>/dev/null || echo 0)
        fi
        if [ "$epoch" -gt 0 ]; then
          secs_to_human $((epoch - NOW))
        else
          echo "—"
        fi
      }

      S_LEFT=$(parse_reset "$SESSION_RESET")
      W_LEFT=$(parse_reset "$WEEKLY_RESET")

      SI=${SESSION_PCT%.*}; WI=${WEEKLY_PCT%.*}; SNI=${SONNET_PCT%.*}; OPI=${OPUS_PCT%.*}; EI=${EXTRA_PCT%.*}

      TIER_LABEL=$(python3 -c "import json; d=json.load(open('$TOKEN_FILE')); print(d.get('rateLimitTier', d.get('subscriptionType', 'Max')))" 2>/dev/null || echo "Max")
      TEXT_OUTPUT+="  👤 $LABEL ($EMAIL) — $TIER_LABEL\n"
      TEXT_OUTPUT+="     ⏱️  5h Session:  $(dot $SI) $(bar $SI) ${SI}%  ⏳${S_LEFT}\n"
      TEXT_OUTPUT+="     📅 7d Overall:   $(dot $WI) $(bar $WI) ${WI}%  ⏳${W_LEFT}\n"
      TEXT_OUTPUT+="     💎 7d Opus:      $(dot $OPI) $(bar $OPI) ${OPI}%\n"
      TEXT_OUTPUT+="     💬 7d Sonnet:    $(dot $SNI) $(bar $SNI) ${SNI}%\n"
      if [ "$EXTRA_ENABLED" = "True" ]; then
        EXTRA_USED_FMT=$(python3 -c "print(f'{${EXTRA_USED}/100:.2f}')")
        EXTRA_LIMIT_FMT=$(python3 -c "print(f'{${EXTRA_LIMIT}/100:.2f}')")
        TEXT_OUTPUT+="     💰 Extra usage:  $(dot $EI) \$${EXTRA_USED_FMT}/\$${EXTRA_LIMIT_FMT}\n"
      fi
      TEXT_OUTPUT+="\n"

      JSON_SECTIONS+="${JSON_SECTIONS:+,}{\"provider\":\"anthropic\",\"account\":\"$LABEL\",\"email\":\"$EMAIL\",\"session\":{\"utilization\":$SESSION_PCT,\"resets_in\":\"$S_LEFT\"},\"weekly\":{\"utilization\":$WEEKLY_PCT,\"resets_in\":\"$W_LEFT\"},\"opus\":{\"utilization\":$OPUS_PCT},\"sonnet\":{\"utilization\":$SONNET_PCT},\"extra\":{\"enabled\":$( [ "$EXTRA_ENABLED" = "True" ] && echo true || echo false ),\"utilization\":$EXTRA_PCT,\"used\":$EXTRA_USED,\"limit\":$EXTRA_LIMIT}}"
    done
  fi
fi

# ── Google Antigravity ───────────────────────────────────────────────

if [ "$SHOW_ANTIGRAVITY" -eq 1 ] && command -v codexbar >/dev/null 2>&1; then
  AG_JSON=$(codexbar usage --json 2>/dev/null || echo "[]")

  if [ "$AG_JSON" != "[]" ] && [ -n "$AG_JSON" ]; then
    TEXT_OUTPUT+="━━━ Google Antigravity ━━━━━━━━━━━━━━━━━━━━━━\n\n"

    AG_PARSED=$(python3 << PYEOF
import json
data = json.loads('''$AG_JSON''')
for entry in data:
    u = entry.get('usage', {})
    identity = u.get('identity', {})
    email = identity.get('accountEmail', u.get('accountEmail', '?'))
    plan = u.get('loginMethod', '?')
    primary = u.get('primary', {})
    secondary = u.get('secondary', {})
    tertiary = u.get('tertiary', {})
    
    p_pct = primary.get('usedPercent', 0)
    p_reset = primary.get('resetsAt', '')
    s_pct = secondary.get('usedPercent', 0)
    s_reset = secondary.get('resetsAt', '')
    t_pct = tertiary.get('usedPercent', 0)
    t_reset = tertiary.get('resetsAt', '')
    
    print(f"{email}|{plan}|{p_pct}|{p_reset}|{s_pct}|{s_reset}|{t_pct}|{t_reset}")
PYEOF
    )

    while IFS='|' read -r AG_EMAIL AG_PLAN AG_P_PCT AG_P_RESET AG_S_PCT AG_S_RESET AG_T_PCT AG_T_RESET; do
      AG_P_LEFT="—"; AG_S_LEFT="—"; AG_T_LEFT="—"
      if [ -n "$AG_P_RESET" ]; then
        AG_P_TS=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${AG_P_RESET%Z}" +%s 2>/dev/null || echo 0)
        [ "$AG_P_TS" -gt 0 ] && AG_P_LEFT=$(secs_to_human $((AG_P_TS - NOW)))
      fi
      if [ -n "$AG_S_RESET" ]; then
        AG_S_TS=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${AG_S_RESET%Z}" +%s 2>/dev/null || echo 0)
        [ "$AG_S_TS" -gt 0 ] && AG_S_LEFT=$(secs_to_human $((AG_S_TS - NOW)))
      fi
      if [ -n "$AG_T_RESET" ]; then
        AG_T_TS=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${AG_T_RESET%Z}" +%s 2>/dev/null || echo 0)
        [ "$AG_T_TS" -gt 0 ] && AG_T_LEFT=$(secs_to_human $((AG_T_TS - NOW)))
      fi

      USED_P=${AG_P_PCT%.*}; USED_S=${AG_S_PCT%.*}; USED_T=${AG_T_PCT%.*}

      TEXT_OUTPUT+="  🌐 $AG_EMAIL — $AG_PLAN\n"
      TEXT_OUTPUT+="     🤖 Claude:      $(dot $USED_P) $(bar $USED_P) ${USED_P}%  ⏳${AG_P_LEFT}\n"
      TEXT_OUTPUT+="     ♊ Gemini Pro:   $(dot $USED_S) $(bar $USED_S) ${USED_S}%  ⏳${AG_S_LEFT}\n"
      TEXT_OUTPUT+="     ⚡ Gemini Flash: $(dot $USED_T) $(bar $USED_T) ${USED_T}%  ⏳${AG_T_LEFT}\n"
      TEXT_OUTPUT+="\n"

      JSON_SECTIONS+="${JSON_SECTIONS:+,}{\"provider\":\"antigravity\",\"email\":\"$AG_EMAIL\",\"plan\":\"$AG_PLAN\",\"claude\":{\"used_pct\":$USED_P,\"resets_in\":\"$AG_P_LEFT\"},\"gemini_pro\":{\"used_pct\":$USED_S,\"resets_in\":\"$AG_S_LEFT\"},\"gemini_flash\":{\"used_pct\":$USED_T,\"resets_in\":\"$AG_T_LEFT\"}}"
    done <<< "$AG_PARSED"
  fi
fi

# ── Ollama (Local Models) ────────────────────────────────────────────

if command -v ollama >/dev/null 2>&1; then
  OLLAMA_RUNNING=$(curl -s --max-time 2 http://localhost:11434/api/tags 2>/dev/null || echo "")
  if [ -n "$OLLAMA_RUNNING" ] && echo "$OLLAMA_RUNNING" | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null; then
    OLLAMA_MODELS=$(echo "$OLLAMA_RUNNING" | python3 -c "
import json, sys
d = json.load(sys.stdin)
models = d.get('models', [])
for m in models:
    name = m.get('name', '?')
    size_gb = m.get('size', 0) / (1024**3)
    print(f'{name}|{size_gb:.1f}GB')
")
    if [ -n "$OLLAMA_MODELS" ]; then
      TEXT_OUTPUT+="━━━ Ollama (Local) ━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"
      while IFS='|' read -r OL_NAME OL_SIZE; do
        TEXT_OUTPUT+="  🖥️  $OL_NAME ($OL_SIZE)  🟢 Always available\n"
        JSON_SECTIONS+="${JSON_SECTIONS:+,}{\"provider\":\"ollama\",\"model\":\"$OL_NAME\",\"size\":\"$OL_SIZE\",\"available\":true}"
      done <<< "$OLLAMA_MODELS"
      TEXT_OUTPUT+="\n"
    fi
  fi
fi

# ── Output ───────────────────────────────────────────────────────────

if [ -z "$TEXT_OUTPUT" ]; then
  TEXT_OUTPUT="❌ No providers configured.\n"
fi

if [ "$FORMAT" = "json" ]; then
  OUTPUT="{\"providers\":[$JSON_SECTIONS],\"checked_at\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"
else
  OUTPUT="🦞 LLM Provider Usage Dashboard\n\n${TEXT_OUTPUT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n📍 $(date '+%I:%M %p %Z') · $(date '+%b %d, %Y')"
fi

echo -e "$OUTPUT" > "$CACHE_FILE"
echo -e "$OUTPUT"
