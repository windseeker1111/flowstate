---
name: flowclaw
description: "LLM load balancer for OpenClaw. Track usage across Anthropic, Google, OpenAI, and Ollama in one dashboard. Auto-balance routing to maximize every credit."
metadata:
  openclaw:
    emoji: "🦞"
    os:
      - darwin
      - linux
    requires:
      bins:
        - curl
        - python3
---

# FlowClaw — LLM Load Balancer

> *Track usage. Balance routing. Never waste a credit.*

Unified dashboard + auto-routing for all your LLM subscriptions. Uses **Earliest Deadline First** scheduling — accounts resetting soonest are prioritized so unused credits aren't wasted.

## Supported Providers

| Provider | Auth | Scoring |
|----------|------|---------|
| **Anthropic** | Claude Max OAuth (unlimited accounts) | Subscription → use-it-or-lose-it |
| **Google** | Gemini CLI (`npm i -g @google/gemini-cli`) | Free tier → highest priority |
| **OpenAI** | API key (`OPENAI_API_KEY`) | Pay-per-token → always available |
| **Ollama** | Local (auto-detected) | Free → quality tradeoff |

## Commands

```bash
# Dashboard — all providers at a glance
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

### Anthropic (Claude Max)
```bash
claude login
bash {baseDir}/scripts/save-account.sh
```

### Google (Gemini CLI)
```bash
npm i -g @google/gemini-cli
gemini    # login via browser
```

### OpenAI
```bash
export OPENAI_API_KEY="sk-..."
```

### Ollama
```bash
brew install ollama && ollama pull qwen3:235b
# Auto-detected — no config needed
```

### Cron Automation
```bash
# Optimize routing every 30 minutes
*/30 * * * * bash ~/clawd/skills/flowclaw/scripts/flowclaw.sh auto
```

## Scoring Algorithm

```
score = urgency(0.4) + availability(0.3) + proximity(0.2) + tier_bonus(0.1)
```

| Factor | Formula | Measures |
|--------|---------|----------|
| Urgency | `remaining / hours_to_reset` | Credits wasting per hour |
| Availability | `√(remaining)` | Dampened capacity |
| Proximity | `1 - (hours / window)` | Deadline pressure |
| Tier bonus | Free=+0.8, Sub=0, Local=-0.3 | Cost preference |

**Family-aware:** Only swaps within same capability class (Opus↔Opus, not Opus↔Gemini).
