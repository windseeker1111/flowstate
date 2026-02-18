---
name: flowclaw
description: "Intelligent LLM load balancer. Maximizes the value of your existing LLM subscriptions by never letting credits go to waste. Scores all provider accounts and dynamically optimizes routing."
metadata:
  openclaw:
    emoji: "🧠"
    os:
      - darwin
      - linux
    requires:
      bins:
        - curl
        - python3
---

# FlowClaw — Intelligent LLM Load Balancer

> *Maximize the value of your existing LLM subscriptions by never letting credits go to waste.*

Scores all provider accounts and dynamically routes requests to the optimal account based on remaining quota, reset schedules, and cost.

Uses **Earliest Deadline First** scheduling + **perishable inventory** optimization — accounts resetting soonest are prioritized so unused credits aren't wasted.

## Provider Support

| Tier | Provider | Status | Scoring |
|------|----------|--------|---------|
| 1 | **Google Antigravity** (Claude + Gemini) | ✅ Supported | Free tier → highest priority |
| 2 | **Anthropic Claude Max** (unlimited accounts) | ✅ Supported | Subscription → use-it-or-lose-it |
| 3 | **Ollama** (local models) | ✅ Supported | Always available → quality tradeoff |

## Commands

```bash
# Usage dashboard — all providers at a glance
flowclaw status [--fresh] [--json]

# Scored ranking — which account to use right now
flowclaw score [--json]

# Optimize routing — reorder OpenClaw model priority
flowclaw optimize [--dry-run]

# Auto mode — optimize silently (for cron jobs)
flowclaw auto

# Run scoring engine unit tests
flowclaw test
```

## Setup

### Adding Anthropic Max Accounts

For each account (no limit on number of accounts):
1. `claude login` → sign in with that account
2. `bash {baseDir}/scripts/save-account.sh` → saves token with label

### Antigravity
Requires CodexBar CLI: `brew install --cask steipete/tap/codexbar`

### Ollama (Local Models)
Install and pull a model:
```bash
brew install ollama
ollama pull qwen3:235b    # or any model that fits your RAM
```
FlowClaw auto-detects Ollama if running locally. No additional configuration needed.

### Cron Automation
```bash
# Optimize routing every 30 minutes
clawdbot cron add --name flowclaw \
  --schedule "*/30 * * * *" \
  --command "bash ~/clawd/skills/flowclaw/scripts/flowclaw.sh auto"
```

## Scoring Algorithm

Each account gets an urgency score:

```
score = urgency(0.4) + availability(0.3) + proximity(0.2) + tier_bonus(0.1)

urgency     = remaining_capacity / hours_until_reset
availability = √(remaining_capacity)
proximity   = 1 - (hours_until_reset / window_length)
tier_bonus  = free(0.8) > subscription(0) > metered(-0.5)
```

Hard rules override scoring:
- 100% utilized on any window → score = 0 (blocked)
- Free tier always preferred over paid
- Pay-per-token only used as last resort
