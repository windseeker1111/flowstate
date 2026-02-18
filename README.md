# 🦞 FlowClaw — LLM Subscription Load Balancer for OpenClaw

> Never let your credits go to waste.

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

An [OpenClaw](https://github.com/openclaw/openclaw) skill that gives you a unified view of all your LLM subscriptions and auto-balances routing to maximize every credit.

**Supported Providers:**

| Provider | Auth Method | What You Get |
|----------|------------|--------------|
| **Anthropic** | Claude Max OAuth | Claude Opus, Sonnet |
| **Google** | Gemini CLI | Claude (via Google), Gemini Pro, Gemini Flash |
| **OpenAI** | API key | GPT-5.2, GPT-5-mini |
| **Ollama** | Local | Any downloaded model |

---

## 🎯 The Problem

Flat-rate LLM subscriptions like Claude Max and Google Gemini CLI have **usage windows that reset on a schedule**. If you don't use your credits before the window closes, they're gone. If you have multiple accounts across multiple providers, you're almost certainly leaving money on the table.

**Without FlowClaw:**
```
  ┌─────────────────────────────────────────────────────────┐
  │  Anthropic A   ████████████████████░░░░░  80% used      │  ← Resets in 30min!
  │  Anthropic B   ██░░░░░░░░░░░░░░░░░░░░░░  10% used      │  ← Resets in 11h
  │  Google        ░░░░░░░░░░░░░░░░░░░░░░░░   0% used      │  ← Resets in 12h
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

- 🦞 **Unified dashboard** — See all Anthropic, Google, OpenAI, and Ollama accounts in one view
- 📈 **Live usage bars** — Real-time usage with reset timers for every subscription window
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

━━━ Google (Claude + Gemini) ━━━━━━━━━━━━━━━━━

  🌐 user@example.com — Pro
     🤖 Claude:      🟢 ░░░░░░░░░░ 0%    ⏳11h 52m
     ♊ Gemini Pro:   🟢 ░░░░░░░░░░ 0%    ⏳12h 56m
     ⚡ Gemini Flash: 🟢 ░░░░░░░░░░ 0%    ⏳12h 56m

━━━ OpenAI ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  🤖 OpenAI API
     📊 Today's tokens: 50K
     🟢 Status: Active

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

Each account gets an **urgency score** from 0.0 to ~1.0:

```
score = urgency × 0.4 + availability × 0.3 + proximity × 0.2 + tier_bonus × 0.1
```

| Factor | Formula | What it measures |
|--------|---------|-----------------|
| **Urgency** | `remaining / hours_to_reset` | Credits wasting per hour |
| **Availability** | `√(remaining)` | Dampened remaining capacity |
| **Proximity** | `1 - (hours_to_reset / window)` | How close to reset deadline |
| **Tier bonus** | Free=+0.8, Paid=0, Local=-0.3 | Provider cost preference |

### Hard Rules

- **100% utilized** on any window → score = 0 (blocked)
- **Free cloud tiers** (Google) always preferred over paid subscriptions
- **Family-aware** — only swaps within same capability class (Opus↔Opus, Gemini↔Gemini)
- **Local models** are always available, never score 0

---

## 🏗️ Provider Details

| Provider | Reset Windows | Free Tier | Notes |
|----------|---------------|-----------|-------|
| **Anthropic** | 5h session + 7d weekly | ❌ Subscription | Multiple Max accounts supported |
| **Google** | 12h rolling | ✅ Free with Gemini CLI | Claude + Gemini Pro + Gemini Flash |
| **OpenAI** | Pay-per-token | ❌ API billing | Always available if key is valid |
| **Ollama** | Never | ✅ Free (local) | Quality tradeoff, always-on fallback |

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

**Anthropic (Claude Max):**
```bash
claude login
bash ~/clawd/skills/flowclaw/scripts/save-account.sh
```

**Google (Gemini CLI):**
```bash
npm i -g @google/gemini-cli
gemini    # authenticates via browser
```

**OpenAI:**
```bash
export OPENAI_API_KEY="sk-..."
```

**Ollama (Local):**
```bash
brew install ollama
ollama pull qwen3:235b    # or any model
# FlowClaw auto-detects Ollama — no configuration needed
```

---

## 📋 All Commands

| Command | Description |
|---------|-------------|
| `flowclaw status [--fresh] [--json]` | Provider usage dashboard |
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
│   ├── provider-usage.sh        # Usage collector (Anthropic, Google, OpenAI, Ollama)
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

PRs welcome! Adding a new provider requires:

1. A collector function in `provider-usage.sh` (query the API)
2. A scoring function in `scoring-engine.py` (compute urgency)

The scoring engine is a pure function: usage JSON in → ranked recommendations out.

---

## 📜 License

MIT — see [LICENSE](LICENSE)

---

<p align="center">
  🦞<br>
  <i>A skill for <a href="https://github.com/openclaw/openclaw">OpenClaw</a></i><br>
  <i>Maximize your subscriptions. Never waste a credit.</i>
</p>
