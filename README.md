# 🦞 FlowClaw — LLM Usage Monitor & Load Balancer for OpenClaw

> LLM subscription usage monitoring and load balancing for OpenClaw.

```
 ███████╗██╗      ██████╗ ██╗    ██╗
 ██╔════╝██║     ██╔═══██╗██║    ██║
 █████╗  ██║     ██║   ██║██║ █╗ ██║
 ██╔══╝  ██║     ██║   ██║██║███╗██║
 ██║     ███████╗╚██████╔╝╚███╔███╔╝
 ╚═╝     ╚══════╝ ╚═════╝  ╚══╝╚══╝
      ██████╗██╗      █████╗ ██╗    ██╗
     ██╔════╝██║     ██╔══██╗██║    ██║
     ██║     ██║     ███████║██║ █╗ ██║
     ██║     ██║     ██╔══██║██║███╗██║
     ╚██████╗███████╗██║  ██║╚███╔███╔╝
      ╚═════╝╚══════╝╚═╝  ╚═╝ ╚══╝╚══╝
```

An [OpenClaw](https://github.com/openclaw/openclaw) skill that gives you a unified view of all your LLM subscriptions and optionally auto-balances routing to maximize every credit.

**Supported Providers:**

| Provider | Auth Method | What You Get |
|----------|------------|--------------|
| **Anthropic Claude Max** | OAuth (unlimited accounts) | 5h session + 7d windows, Opus/Sonnet breakdown |
| **Google Gemini CLI** | OAuth via OpenClaw | Pro + Flash quota (24h rolling) |
| **Google Antigravity** | codexbar | Claude, Gemini Pro/Flash per-model (12h rolling) |
| **OpenAI Codex** | OAuth via OpenClaw | 3h + daily windows, plan type, credits |
| **GitHub Copilot** | OAuth via OpenClaw | Premium + Chat quota |
| **Ollama** | Local (auto-detected) | Any downloaded model |

---

## 🎯 The Problem

Flat-rate LLM subscriptions like Claude Max and Google Gemini CLI have **usage windows that reset on a schedule**. If you don't use your credits before the window closes, they're gone. If you have multiple accounts across multiple providers, you're almost certainly leaving money on the table.

**Without FlowClaw:**
```
  ┌─────────────────────────────────────────────────────────┐
  │  Anthropic A   ████████████████████░░░░░  80% used      │  ← Resets in 30min!
  │  Anthropic B   ██░░░░░░░░░░░░░░░░░░░░░░  10% used      │  ← Resets in 11h
  │  Gemini CLI    ░░░░░░░░░░░░░░░░░░░░░░░░   0% used      │  ← Wide open
  │  Antigravity   ████░░░░░░░░░░░░░░░░░░░░  40% used      │  ← Resets in 5h
  │  Codex         ░░░░░░░░░░░░░░░░░░░░░░░░   0% used      │  ← Fresh
  │                                                         │
  │  You're using Account B... wasting 80% of Account A 💸  │
  └─────────────────────────────────────────────────────────┘
```

**With FlowClaw:**
```
  ┌─────────────────────────────────────────────────────────┐
  │  ⚡ SWITCH → Anthropic A  (score: 0.94, resets in 30m)  │
  │                                                         │
  │  "Use Account A now — 80% remaining credits expire in   │
  │   30 minutes. Account B and Google can wait."            │
  └─────────────────────────────────────────────────────────┘
```

---

## ✨ Features

- 🦞 **6 providers** — Anthropic, Gemini CLI, Antigravity, OpenAI Codex, GitHub Copilot, Ollama
- 📈 **Source API data** — Real usage from provider APIs, not calculated estimates
- 👥 **Multi-account** — Unlimited Anthropic accounts, all others via OpenClaw
- 🧠 **EDF scoring** — Earliest Deadline First algorithm scores accounts by urgency
- 🔄 **Auto switching** — Reorders your OpenClaw model routing when better options are available
- 🏠 **Local fallback** — Auto-detects Ollama as always-available fallback
- 📊 **Family-aware** — Only swaps within same capability class (Opus↔Opus, not Opus↔Gemini)
- ⏱️ **Cron-ready** — `flowclaw auto` runs silently for hands-free optimization

---

## 📊 Dashboard

```bash
$ flowclaw status --fresh
```
```
🦞 FlowClaw — LLM Provider Dashboard

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

━━━ Google Gemini CLI ━━━━━━━━━━━━━━━━━━━━━━━

  ♊
     ♊ Pro                🟢 ░░░░░░░░░░ 0%
     ⚡ Flash              🟢 ░░░░░░░░░░ 0%

━━━ Google Antigravity ━━━━━━━━━━━━━━━━━━━━━━━

  🌐 (Antigravity)
     🤖 claude-opus-4-6    🟢 ████░░░░░░ 40%  ⏳1h 27m
     🤖 claude-sonnet-4-6  🟢 ████░░░░░░ 40%  ⏳1h 27m
     ♊ gemini-3-pro-high  🟢 ░░░░░░░░░░ 0%   ⏳5h 0m
     ⚡ gemini-3-flash     🟢 ░░░░░░░░░░ 0%   ⏳5h 0m

━━━ OpenAI Codex ━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  🤖 (Pro)
     🤖 3h                 🟡 ██████░░░░ 60%  ⏳1h 15m
     🤖 Day                🟢 ██░░░░░░░░ 20%  ⏳18h

━━━ Ollama (Local) ━━━━━━━━━━━━━━━━━━━━━━━━━━

  🖥️  qwen3:235b (60.1GB)  🟢 Always available

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 02:02 PM PST · Feb 18, 2026
```

---

## 🧮 Scoring

```bash
$ flowclaw score
```
```
🧠 FlowClaw Scoring

  #1  ✅ google-claude    [opus]         score=0.4143  0% used       ← recommended
  #2  ✅ google-gemini    [gemini-pro]   score=0.4109  0% used
  #3  ✅ personal         [opus]         score=0.3812  5h:30% 7d:12%
  #4  ✅ openai-api       [gpt5]         score=0.5000  API (50K today)
  #5  🚫 work             [opus]         score=0.0000  5h session limit
  #6  ✅ local-qwen3      [local]        score=0.2700  Local (60.1GB)

  🎯 Recommended: google-claude (google-gemini-cli/claude-opus-4-6-thinking)
```

---

## ⚡ Auto-Optimization

```bash
$ flowclaw optimize
```

FlowClaw detects the best routing option, swaps your primary model, and reorganizes fallbacks:

```
🧠 FlowClaw Optimization

  🎯 Recommended primary: google-gemini-cli/claude-opus-4-6-thinking
  📋 Anthropic profile order: anthropic:work anthropic:personal

  ⚙️  Applying...
  ✅ Anthropic profile order updated
  ✅ Primary model set to google-gemini-cli/claude-opus-4-6-thinking
  ✅ Fallbacks: anthropic/claude-opus-4-6, openai/gpt-5.2

  ✅ FlowClaw optimized!
```

---

## 🔬 How the Scoring Algorithm Works

Each account gets an **urgency score** from 0.0 to ~1.5:

```
score = urgency × 0.30 + availability × 0.25 + proximity × 0.15
      + weekly_headroom × 0.20 + tier_bonus × 0.10
```

| Factor | Formula | What it measures |
|--------|---------|-----------------|
| **Urgency** | `remaining / hours_to_reset` | Credits wasting per hour |
| **Availability** | `√(remaining)` | Dampened remaining capacity |
| **Proximity** | `1 - (hours_to_reset / window)` | How close to reset deadline |
| **Weekly headroom** | `(100 - weekly_pct) / 100` | 7-day capacity remaining |
| **Tier bonus** | Free=+0.8, Paid=0, Local=-0.3 | Provider cost preference |

### Perishable Inventory Rules

Both 5h session and 7d weekly windows are treated as perishable inventory:

- **Normal**: Account at 96% weekly → deprioritized (save remaining credits)
- **≤12h to weekly reset**: Penalty fades linearly (credits becoming perishable)
- **≤6h to weekly reset**: Full burn mode — weekly penalty ignored entirely
- **100% utilized** on any window → score = 0 (blocked)
- **Free cloud tiers** (Google/Antigravity) always preferred over paid subscriptions
- **Family-aware** — only swaps within same capability class (Opus↔Opus, Gemini↔Gemini)
- **Local models** are always available, never score 0

---

## 🏗️ Provider Details

| Provider | Reset Windows | Data Source | Notes |
|----------|---------------|-------------|-------|
| **Anthropic Claude Max** | 5h session + 7d weekly | `api.anthropic.com/api/oauth/usage` | Unlimited accounts via FlowClaw tokens |
| **Google Gemini CLI** | 24h rolling | `cloudcode-pa.googleapis.com` | Pro + Flash request quota |
| **Google Antigravity** | 12h rolling | codexbar | Per-model: Claude, Gemini Pro, Flash |
| **OpenAI Codex** | 3h + daily | `chatgpt.com/backend-api/wham/usage` | Plan type + credit balance |
| **GitHub Copilot** | Monthly | `api.github.com/copilot_internal/user` | Premium + Chat quota |
| **Ollama** | Never | `localhost:11434/api/tags` | Auto-detected, always available |

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

### Adding Providers

**Anthropic (Claude Max)** — unlimited accounts:
```bash
claude login                                     # Sign in with each account
bash ~/clawd/skills/flowclaw/scripts/save-account.sh  # Save token with label
# Repeat for each Anthropic account
```

**Google Gemini CLI:**
```bash
openclaw models auth login --provider google-gemini-cli
```

**Google Antigravity:**
```bash
openclaw models auth login --provider google-antigravity
brew install --cask steipete/tap/codexbar         # Required for usage metrics
```

**OpenAI Codex:**
```bash
openclaw models auth login --provider openai-codex
```

**GitHub Copilot:**
```bash
openclaw models auth login-github-copilot
```

**Ollama (Local):**
```bash
brew install ollama && ollama pull qwen3:235b
# Auto-detected — no configuration needed
```

---

## 📋 All Commands

| Command | Description |
|---------|-------------|
| `flowclaw status [--fresh] [--json]` | Full provider usage dashboard |
| `flowclaw monitor [--json] [--cached]` | Clean usage report (no scoring) |
| `flowclaw score [--json]` | Scored ranking of all accounts |
| `flowclaw optimize [--dry-run]` | Reorder OpenClaw routing |
| `flowclaw auto` | Silent optimization (for cron) |
| `flowclaw history [N]` | Routing history with timeline |
| `flowclaw test` | Run scoring engine unit tests |
| `flowclaw help` | Show help |

### Cron Automation

```bash
# Re-optimize routing every 30 minutes
*/30 * * * * bash ~/clawd/skills/flowclaw/scripts/flowclaw.sh auto
```

---

## 🏛️ Architecture

```
flowclaw/
├── SKILL.md                     # OpenClaw skill manifest
├── README.md                    # This file
├── LICENSE                      # MIT
├── scripts/
│   ├── flowclaw.sh             # Main CLI
│   ├── provider-usage.sh        # Usage collector (Anthropic direct + OpenClaw for rest)
│   ├── scoring-engine.py        # EDF urgency scoring algorithm
│   └── save-account.sh          # Anthropic account setup helper
└── config/                      # Auto-generated, gitignored
    ├── flowclaw-state.json     # Current routing state
    └── flowclaw-history.jsonl  # Routing decision log
```

---

## 🔒 Security

- OAuth tokens stored at `~/.openclaw/usage-tokens/` with `600` permissions
- No tokens or credentials in this repository
- Tokens are read-only — FlowClaw never modifies your credentials
- All API calls use HTTPS

---

## 🤝 Contributing

PRs welcome! Adding a new provider:

1. If OpenClaw already supports the provider, it's automatic — FlowClaw picks it up via `openclaw status --usage --json`
2. For custom providers, add a collector in `provider-usage.sh` and scorer in `scoring-engine.py`

The scoring engine is a pure function: usage JSON in → ranked recommendations out.

---

## 📜 License

MIT — see [LICENSE](LICENSE)

---

<p align="center">
  🦞<br>
  <i>A skill for <a href="https://github.com/openclaw/openclaw">OpenClaw</a></i><br>
  <i>LLM subscription usage monitoring and load balancing.</i>
</p>
