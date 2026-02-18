# 🦞 FlowClaw — An OpenClaw Skill

```
  ███████╗██╗      ██████╗ ██╗    ██╗ ██████╗██╗      █████╗ ██╗    ██╗
  ██╔════╝██║     ██╔═══██╗██║    ██║██╔════╝██║     ██╔══██╗██║    ██║
  █████╗  ██║     ██║   ██║██║ █╗ ██║██║     ██║     ███████║██║ █╗ ██║
  ██╔══╝  ██║     ██║   ██║██║███╗██║██║     ██║     ██╔══██║██║███╗██║
  ██║     ███████╗╚██████╔╝╚███╔███╔╝╚██████╗███████╗██║  ██║╚███╔███╔╝
  ╚═╝     ╚══════╝ ╚═════╝  ╚══╝╚══╝  ╚═════╝╚══════╝╚═╝  ╚═╝ ╚══╝╚══╝

  🦞 FlowClaw — An OpenClaw Skill
  Intelligent LLM Load Balancer · Never let your credits go to waste.
```

> **🦞 An [OpenClaw](https://github.com/openclaw/openclaw) skill that maximizes the value of your existing LLM subscriptions by never letting credits go to waste.**

FlowClaw is an intelligent load balancer for [OpenClaw](https://github.com/openclaw/openclaw). It uses **Earliest Deadline First** scheduling and **perishable inventory** optimization to dynamically reorder your OpenClaw model routing, ensuring the account with the most urgent credits is always used first.

---

## 🎯 The Problem

Flat-rate LLM subscriptions like Claude Max and Google Antigravity have **usage windows that reset on a schedule**. If you don't use your credits before the window closes, they're gone. If you have multiple accounts across multiple providers, you're almost certainly leaving money on the table.

**Without FlowClaw:**
```
  ┌─────────────────────────────────────────────────────────┐
  │  Account A     ████████████████████░░░░░  80% used      │  ← Resets in 30min!
  │  Account B     ██░░░░░░░░░░░░░░░░░░░░░░  10% used      │  ← Resets in 11h
  │  Antigravity   ░░░░░░░░░░░░░░░░░░░░░░░░   0% used      │  ← Resets in 12h
  │                                                         │
  │  You're using Account B... wasting 80% of Account A 💸  │
  └─────────────────────────────────────────────────────────┘
```

**With FlowClaw:**
```
  ┌─────────────────────────────────────────────────────────┐
  │  ⚡ SWITCH → Account A  (score: 0.9412, resets in 30m)  │
  │                                                         │
  │  "Use Account A now — 80% remaining credits expire in   │
  │   30 minutes. Account B and Antigravity can wait."      │
  └─────────────────────────────────────────────────────────┘
```

---

## ✨ Features

- 🦞 **Built for OpenClaw** — Directly manages your OpenClaw model routing and profile ordering
- 🧠 **Smart scoring** — EDF urgency algorithm scores accounts by remaining credits, reset proximity, and provider tier
- 🔄 **Automatic switching** — Reorders your OpenClaw model routing when better options are available
- 📊 **Unified dashboard** — See all providers at a glance with live usage bars
- 📈 **Routing history** — Graph of every switchover with provider distribution charts
- 🏠 **Local fallback** — Auto-detects Ollama models as always-available fallback
- ⏱️ **Cron-ready** — `flowclaw auto` runs silently for hands-free optimization

---

## 📊 Dashboard

```bash
$ flowclaw status --fresh
```
```
🦞 LLM Provider Usage Dashboard

━━━ Anthropic Claude Max ━━━━━━━━━━━━━━━━━━━━

  👤 work (work@example.com) — Max 20x
     ⏱️  5h Session:  🔴 ██████████ 100%  ⏳2h 30m
     📅 7d Overall:   🟢 ████░░░░░░ 41%   ⏳6d 12h
     💎 7d Opus:      🟢 ░░░░░░░░░░ 0%
     💬 7d Sonnet:    🟢 █░░░░░░░░░ 18%
     💰 Extra usage:  🔴 $32.39/$20.00

  👤 personal (personal@example.com) — Max 5x
     ⏱️  5h Session:  🟢 ███░░░░░░░ 30%   ⏳4h 10m
     📅 7d Overall:   🟢 █░░░░░░░░░ 12%   ⏳5d 3h

━━━ Google Antigravity ━━━━━━━━━━━━━━━━━━━━━━

  🌐 user@example.com — Pro
     🤖 Claude:      🟢 ░░░░░░░░░░ 0%    ⏳11h 52m
     ♊ Gemini Pro:   🟢 ░░░░░░░░░░ 0%    ⏳12h 56m
     ⚡ Gemini Flash: 🟢 ░░░░░░░░░░ 0%    ⏳12h 56m

━━━ Ollama (Local) ━━━━━━━━━━━━━━━━━━━━━━━━━━

  🖥️  qwen3:235b (60.1GB)  🟢 Always available

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 11:37 AM PST · Feb 18, 2026
```

---

## 🧮 Scoring

```bash
$ flowclaw score
```
```
🧠 FlowClaw Scoring

  #1  ✅ ag-claude        score=0.4143  0% used       ← recommended
  #2  ✅ ag-gemini_pro    score=0.4109  0% used
  #3  ✅ personal         score=0.3812  5h:30% 7d:12%
  #4  🚫 work             score=0.0000  5h session limit
  #5  ✅ local-qwen3      score=0.2700  Local (60.1GB)

  🎯 Recommended: ag-claude (google-antigravity/claude-opus-4-6-thinking)
```

---

## ⚡ Switchover in Action

When FlowClaw detects a better routing option, it swaps your primary model and reorganizes fallbacks:

```bash
$ flowclaw optimize
```
```
🧠 FlowClaw Optimization

  #1  ✅ ag-gemini_pro    score=0.4110  0% used
  #2  ✅ ag-gemini_flash  score=0.4110  0% used
  #3  ✅ ag-claude        score=0.3810  20% used
  #4  🚫 work             score=0.0000  5h session limit (resets in 8h 12m)
  #5  🚫 personal         score=0.0000  5h session limit (resets in 8h 12m)

  🎯 Recommended primary: google-antigravity/gemini-3-pro-high
  📋 Anthropic profile order: anthropic:work anthropic:personal

  ⚙️  Applying...
  ✅ Anthropic profile order updated
  ✅ Primary model set to google-antigravity/gemini-3-pro-high
  ✅ Fallbacks: anthropic/claude-opus-4-6, google-antigravity/claude-opus-4-6-thinking

  ✅ FlowClaw optimized!
```

Later, when the Anthropic session window resets and credits are fresh again:

```bash
$ flowclaw optimize
```
```
🧠 FlowClaw Optimization

  #1  ✅ work             score=0.5200  5h:0% 7d:41%    ← session just reset!
  #2  ✅ personal         score=0.4800  5h:0% 7d:12%
  #3  ✅ ag-claude        score=0.3810  20% used
  #4  ✅ ag-gemini_pro    score=0.3500  15% used

  🎯 Recommended primary: anthropic/claude-opus-4-6

  ⚙️  Applying...
  ✅ Primary model set to anthropic/claude-opus-4-6
  ✅ Fallbacks: google-antigravity/claude-opus-4-6-thinking, google-antigravity/gemini-3-pro-high

  ✅ FlowClaw optimized!
```

---

## 📈 Routing History

```bash
$ flowclaw history
```
```
📊 FlowClaw Routing History

  ┌─── Routing Timeline ───────────────────────────────────────
  │ Feb 18 09:00AM  🔵 anthropic/claude-opus-4-6
  │ Feb 18 10:30AM  🔵 anthropic/claude-opus-4-6
  │  ⚡ SWITCH: anthropic/claude-opus-4-6
  │         → google-antigravity/claude-opus-4-6-thinking
  │ Feb 18 11:00AM  🟢 google-antigravity/claude-opus-4-6-thinking
  │ Feb 18 11:30AM  🟢 google-antigravity/claude-opus-4-6-thinking
  │  ⚡ SWITCH: google-antigravity/claude-opus-4-6-thinking
  │         → google-antigravity/gemini-3-pro-high
  │ Feb 18 12:00PM  🟠 google-antigravity/gemini-3-pro-high
  │  ⚡ SWITCH: google-antigravity/gemini-3-pro-high
  │         → anthropic/claude-opus-4-6
  │ Feb 18 03:30PM  🔵 anthropic/claude-opus-4-6
  │ Feb 18 04:00PM  🔵 anthropic/claude-opus-4-6
  └──────────────────────────────────────────────────────────

  Provider Distribution:
    🔵 claude-opus-4-6            ██████████████████░░░░░░░░░░░░  57.1% (4)
    🟢 claude-opus-4-6-thinking   ████████░░░░░░░░░░░░░░░░░░░░░░  28.6% (2)
    🟠 gemini-3-pro-high          ████░░░░░░░░░░░░░░░░░░░░░░░░░░  14.3% (1)

  Total routing decisions: 7
  Total switchovers: 3
```

---

## 🔬 How the Scoring Algorithm Works

Each account gets an **urgency score** from 0.0 to ~1.0:

```
score = urgency × 0.4  +  availability × 0.3  +  proximity × 0.2  +  tier_bonus × 0.1
```

| Factor | Formula | What it measures |
|--------|---------|-----------------|
| **Urgency** | `remaining / hours_to_reset` | Credits wasting per hour |
| **Availability** | `√(remaining)` | Dampened remaining capacity |
| **Proximity** | `1 - (hours_to_reset / window)` | How close to reset deadline |
| **Tier bonus** | Free=+0.8, Sub=0, Local=-0.3 | Provider cost preference |

### Scoring Examples

| Scenario | Score | Why |
|----------|-------|-----|
| 80% remaining, resets in 30 min | **0.94** | 🔥 Use immediately — credits about to vanish |
| 80% remaining, resets in 6 days | **0.26** | 😴 Plenty of time, save for later |
| 5% remaining, resets in 30 min | **0.35** | 🤷 Almost empty anyway |
| Free tier, 100% remaining, 12h window | **0.41** | 🆓 Free tier bonus kicks in |
| Local model (Ollama) | **0.27** | 🏠 Always available, but quality penalty |

### Hard Rules (Override Scoring)

- **100% utilized** on any window → score = 0 (**blocked**)
- **Free cloud tiers** always preferred over paid subscriptions
- **Local models** are always-available fallback, never score 0

---

## 🏗️ Supported Providers

| Tier | Provider | Reset Windows | Scoring |
|------|----------|---------------|---------|
| 1 | **Google Antigravity** | 12h rolling | Free cloud → highest priority |
| 2 | **Anthropic Claude Max** | 5h session + 7d weekly | Subscription → use-it-or-lose-it |
| 3 | **Ollama** (local) | Never | Always available → quality tradeoff |

---

## 🚀 Installation

### Requirements

- macOS or Linux
- `bash`, `python3`, `curl`
- [OpenClaw](https://github.com/openclaw/openclaw) (for routing optimization)

### Quick Start

```bash
# Clone
git clone https://github.com/windseeker1111/flowclaw.git ~/clawd/skills/flowclaw

# Make executable
chmod +x ~/clawd/skills/flowclaw/scripts/*.sh
chmod +x ~/clawd/skills/flowclaw/scripts/*.py

# Add alias (optional)
echo 'alias flowclaw="bash ~/clawd/skills/flowclaw/scripts/flowclaw.sh"' >> ~/.zshrc
source ~/.zshrc
```

### Adding Anthropic Max Accounts

```bash
# For each Claude Max account (no limit on count):
claude login                                    # Sign in
bash ~/clawd/skills/flowclaw/scripts/save-account.sh  # Save token
```

### Google Antigravity

```bash
brew install --cask steipete/tap/codexbar
```

### Ollama (Local Fallback)

```bash
brew install ollama
ollama pull qwen3:235b    # or any model that fits your RAM
```

FlowClaw auto-detects Ollama when it's running — no configuration needed.

---

## 📋 All Commands

| Command | Description |
|---------|-------------|
| `flowclaw status [--fresh] [--json]` | Usage dashboard across all providers |
| `flowclaw score [--json]` | Scored ranking of all accounts |
| `flowclaw optimize [--dry-run]` | Reorder OpenClaw routing for optimal usage |
| `flowclaw auto` | Silent optimization (for cron) |
| `flowclaw history [N]` | Routing history with switchover graph |
| `flowclaw test` | Run scoring engine unit tests |
| `flowclaw help` | Show help with ASCII banner |

### Cron Automation

```bash
# Re-optimize routing every 30 minutes
crontab -e
# Add: */30 * * * * bash ~/clawd/skills/flowclaw/scripts/flowclaw.sh auto
```

---

## 🏛️ Architecture

```
flowclaw/
├── SKILL.md                      # OpenClaw skill manifest
├── README.md                     # This file
├── LICENSE                       # MIT
├── .gitignore
├── scripts/
│   ├── flowclaw.sh              # Main CLI (banner, commands, routing)
│   ├── provider-usage.sh         # Usage collector (queries all APIs)
│   ├── scoring-engine.py         # EDF urgency scoring algorithm
│   └── save-account.sh           # Account token setup helper
└── config/                       # Auto-generated, gitignored
    ├── flowclaw-state.json      # Current routing state
    └── flowclaw-history.jsonl   # Routing decision log
```

---

## 🔒 Security

- OAuth tokens stored at `~/.openclaw/usage-tokens/` with `600` permissions
- **No tokens or credentials included** in this repository
- Tokens are read-only — FlowClaw never modifies your credentials
- All API calls use HTTPS
- History file contains only routing decisions, never credentials

---

## 🤝 Contributing

PRs welcome! Adding a new provider requires:

1. A collector function in `provider-usage.sh` (query the API)
2. A scoring function in `scoring-engine.py` (compute urgency)

The scoring engine is designed as a pure function: usage JSON in → ranked recommendations out.

---

## 📜 License

MIT — see [LICENSE](LICENSE)

---

<p align="center">
  🦞<br>
  <i>A skill for <a href="https://github.com/openclaw/openclaw">OpenClaw</a> — the open-source AI coding agent</i><br>
  <i>Maximize your subscriptions. Never waste a credit.</i>
</p>
