#!/usr/bin/env python3
"""FlowClaw Scoring Engine — EDF-based urgency scoring for LLM account routing.

Reads usage JSON from stdin (produced by usage collector), computes urgency
scores for each account, and outputs a ranked list with recommended routing.

Scoring based on Earliest Deadline First + perishable inventory management:
  score = urgency * 0.4 + availability * 0.3 + proximity * 0.2 + tier_bonus * 0.1
"""

import json
import sys
from datetime import datetime, timezone
from dataclasses import dataclass

# ── Provider tier bonuses (cost optimization) ─────────────────────────
TIER_BONUS = {
    "antigravity": 0.8,   # Free tier, prefer strongly
    "anthropic": 0.0,     # Subscription baseline
    "ollama": -0.3,       # Quality penalty, but always available
}

TIER_EXTRA_PENALTY = -1.0  # Heavy penalty when burning extra usage $$$

@dataclass
class ScoredAccount:
    provider: str
    account: str
    email: str
    profile_id: str       # OpenClaw profile ID (e.g., "anthropic:work")
    model: str            # OpenClaw model string
    score: float
    available: bool
    reason: str
    utilization: float
    resets_in: str

def parse_reset_hours(resets_in: str) -> float:
    """Parse human-readable reset string to hours. Returns 999 if unknown."""
    if not resets_in or resets_in in ("—", "unknown", ""):
        return 999.0
    hours = 0.0
    parts = resets_in.split()
    for part in parts:
        if part.endswith("d"):
            hours += float(part[:-1]) * 24
        elif part.endswith("h"):
            hours += float(part[:-1])
        elif part.endswith("m"):
            hours += float(part[:-1]) / 60
    return max(hours, 0.01)  # avoid division by zero

def score_anthropic(account: dict) -> list[ScoredAccount]:
    """Score an Anthropic Max account. Returns one ScoredAccount."""
    email = account.get("email", "?")
    name = account.get("account", "?")
    profile_id = f"anthropic:{name}"
    model = "anthropic/claude-opus-4-6"

    session = account.get("session", {})
    weekly = account.get("weekly", {})
    opus = account.get("opus", {})
    sonnet = account.get("sonnet", {})
    extra = account.get("extra", {})

    s_util = session.get("utilization", 0)
    w_util = weekly.get("utilization", 0)
    s_reset_h = parse_reset_hours(session.get("resets_in", ""))
    w_reset_h = parse_reset_hours(weekly.get("resets_in", ""))

    # Hard block: if ANY constraint is at 100%
    if s_util >= 100:
        return [ScoredAccount(
            provider="anthropic", account=name, email=email,
            profile_id=profile_id, model=model,
            score=0.0, available=False,
            reason=f"5h session limit (resets in {session.get('resets_in', '?')})",
            utilization=s_util, resets_in=session.get("resets_in", "?")
        )]
    if w_util >= 100:
        return [ScoredAccount(
            provider="anthropic", account=name, email=email,
            profile_id=profile_id, model=model,
            score=0.0, available=False,
            reason=f"7d weekly limit (resets in {weekly.get('resets_in', '?')})",
            utilization=w_util, resets_in=weekly.get("resets_in", "?")
        )]

    # Use tightest constraint (whichever window is closest to exhaustion)
    s_remaining = (100 - s_util) / 100
    w_remaining = (100 - w_util) / 100
    s_pressure = s_util / max(s_reset_h, 0.01)
    w_pressure = w_util / max(w_reset_h, 0.01)

    if s_pressure > w_pressure:
        util = s_util
        remaining = s_remaining
        reset_h = s_reset_h
        window_h = 5.0
        resets_in = session.get("resets_in", "?")
    else:
        util = w_util
        remaining = w_remaining
        reset_h = w_reset_h
        window_h = 168.0
        resets_in = weekly.get("resets_in", "?")

    # Urgency: how much capacity is wasting per hour
    urgency = remaining / reset_h if reset_h > 0 else 0

    # Availability: sqrt-dampened remaining capacity
    availability = remaining ** 0.5

    # Proximity: bonus for resets happening soon (use-it-or-lose-it)
    proximity = max(0, 1 - reset_h / window_h)

    # Tier bonus
    tier = TIER_BONUS.get("anthropic", 0)

    # Extra usage penalty
    if extra.get("enabled") and extra.get("utilization", 0) >= 100:
        tier += TIER_EXTRA_PENALTY * 0.3  # moderate penalty

    score = (urgency * 0.4) + (availability * 0.3) + (proximity * 0.2) + (tier * 0.1)

    return [ScoredAccount(
        provider="anthropic", account=name, email=email,
        profile_id=profile_id, model=model,
        score=round(score, 4), available=True,
        reason=f"5h:{s_util}% 7d:{w_util}%",
        utilization=util, resets_in=resets_in
    )]

def score_antigravity(account: dict) -> list[ScoredAccount]:
    """Score Antigravity account. Returns one ScoredAccount per model type."""
    email = account.get("email", "?")
    results = []

    models = [
        ("claude", "google-antigravity/claude-opus-4-6-thinking", "🤖"),
        ("gemini_pro", "google-antigravity/gemini-3-pro-high", "♊"),
        ("gemini_flash", "google-antigravity/gemini-3-flash", "⚡"),
    ]

    for key, model, emoji in models:
        data = account.get(key, {})
        util = data.get("used_pct", 0)
        resets_in = data.get("resets_in", "?")
        reset_h = parse_reset_hours(resets_in)

        if util >= 100:
            results.append(ScoredAccount(
                provider="antigravity", account=f"ag-{key}", email=email,
                profile_id=f"google-antigravity:{email}", model=model,
                score=0.0, available=False,
                reason=f"Limit reached (resets in {resets_in})",
                utilization=util, resets_in=resets_in
            ))
            continue

        remaining = (100 - util) / 100
        urgency = remaining / reset_h if reset_h > 0 else 0
        availability = remaining ** 0.5
        proximity = max(0, 1 - reset_h / 12.0)  # 12h window
        tier = TIER_BONUS.get("antigravity", 0)

        score = (urgency * 0.4) + (availability * 0.3) + (proximity * 0.2) + (tier * 0.1)

        results.append(ScoredAccount(
            provider="antigravity", account=f"ag-{key}", email=email,
            profile_id=f"google-antigravity:{email}", model=model,
            score=round(score, 4), available=True,
            reason=f"{util}% used",
            utilization=util, resets_in=resets_in
        ))

    return results

def score_ollama(account: dict) -> list[ScoredAccount]:
    """Score Ollama local model. Always available, quality penalty."""
    model = account.get("model", "unknown")
    size = account.get("size", "?")
    # Ollama is always available — never rate-limited
    tier = TIER_BONUS.get("ollama", -0.3)
    # Base score: availability=1.0, urgency=0 (no reset), proximity=0
    score = (0.0 * 0.4) + (1.0 * 0.3) + (0.0 * 0.2) + (tier * 0.1)
    return [ScoredAccount(
        provider="ollama", account=f"local-{model}", email="localhost",
        profile_id=f"ollama:{model}", model=f"ollama/{model}",
        score=round(score, 4), available=True,
        reason=f"Local ({size})",
        utilization=0, resets_in="never"
    )]

def model_family(model: str) -> str:
    """Classify a model into a capability family for fair comparison.
    Only models in the same family should compete for the same routing slot."""
    m = model.lower()
    if "opus" in m or "claude-opus" in m:
        return "opus"
    elif "sonnet" in m or "claude-sonnet" in m:
        return "sonnet"
    elif "gemini-3-pro" in m or "gemini-pro" in m:
        return "gemini-pro"
    elif "gemini-3-flash" in m or "gemini-flash" in m:
        return "gemini-flash"
    elif "ollama" in m:
        return "local"
    return "other"

def score_all(data: dict) -> list[ScoredAccount]:
    """Score all accounts from usage JSON."""
    scored = []
    for entry in data.get("providers", []):
        provider = entry.get("provider", "")
        if provider == "anthropic":
            scored.extend(score_anthropic(entry))
        elif provider == "antigravity":
            scored.extend(score_antigravity(entry))
        elif provider == "ollama":
            scored.extend(score_ollama(entry))
    # Tag each with family for downstream filtering
    for s in scored:
        s.family = model_family(s.model)
    return sorted(scored, key=lambda s: s.score, reverse=True)

def best_per_family(scored: list[ScoredAccount]) -> dict[str, ScoredAccount]:
    """Return the best available account for each model family."""
    best = {}
    for s in scored:
        fam = model_family(s.model)
        if fam not in best and s.available:
            best[fam] = s
    return best

def run_tests():
    """Built-in unit tests."""
    print("Running scoring engine tests...\n")

    # Test 1: 100% session → blocked
    result = score_anthropic({"account": "test", "email": "t@t.com",
        "session": {"utilization": 100, "resets_in": "2h 30m"},
        "weekly": {"utilization": 41, "resets_in": "6d 12h"},
        "extra": {"enabled": True, "utilization": 100}})
    assert not result[0].available, "100% session should be blocked"
    assert result[0].score == 0.0, "Blocked should score 0"
    print("  ✅ Test 1: 100% session → blocked (score=0)")

    # Test 2: 50% used, resets in 10min → high urgency
    result = score_anthropic({"account": "soon", "email": "t@t.com",
        "session": {"utilization": 50, "resets_in": "10m"},
        "weekly": {"utilization": 20, "resets_in": "5d"},
        "extra": {"enabled": False}})
    soon_score = result[0].score
    print(f"  ✅ Test 2: 50% used, resets in 10m → score={soon_score:.4f} (should be high)")

    # Test 3: 50% used, resets in 6 days → low urgency
    result = score_anthropic({"account": "late", "email": "t@t.com",
        "session": {"utilization": 50, "resets_in": "4h 50m"},
        "weekly": {"utilization": 50, "resets_in": "6d"},
        "extra": {"enabled": False}})
    late_score = result[0].score
    assert soon_score > late_score, "Sooner reset should score higher"
    print(f"  ✅ Test 3: 50% used, resets in 6d → score={late_score:.4f} (should be lower)")

    # Test 4: Antigravity at 0% → gets free-tier bonus
    result = score_antigravity({"email": "t@t.com",
        "claude": {"used_pct": 0, "resets_in": "12h"},
        "gemini_pro": {"used_pct": 0, "resets_in": "12h"},
        "gemini_flash": {"used_pct": 0, "resets_in": "12h"}})
    assert all(r.available for r in result), "0% should be available"
    assert all(r.score > 0 for r in result), "0% with tier bonus should score > 0"
    print(f"  ✅ Test 4: Antigravity 0% → scores={[r.score for r in result]} (all positive)")

    # Test 5: Antigravity at 100% → blocked
    result = score_antigravity({"email": "t@t.com",
        "claude": {"used_pct": 100, "resets_in": "3h"},
        "gemini_pro": {"used_pct": 50, "resets_in": "6h"},
        "gemini_flash": {"used_pct": 0, "resets_in": "12h"}})
    assert not result[0].available, "100% Claude should be blocked"
    assert result[1].available, "50% Gemini Pro should be available"
    print(f"  ✅ Test 5: Mixed Antigravity → Claude blocked, Gemini available")

    print("\n✅ All tests passed!")

def main():
    if "--test" in sys.argv:
        run_tests()
        return

    # Read usage JSON from stdin or file
    if "--file" in sys.argv:
        idx = sys.argv.index("--file") + 1
        data = json.load(open(sys.argv[idx]))
    else:
        data = json.load(sys.stdin)

    scored = score_all(data)

    output_format = "json" if "--json" in sys.argv else "text"

    if output_format == "json":
        family_best = best_per_family(scored)
        result = {
            "ranked": [{
                "rank": i + 1,
                "provider": s.provider,
                "account": s.account,
                "email": s.email,
                "profile_id": s.profile_id,
                "model": s.model,
                "family": model_family(s.model),
                "score": s.score,
                "available": s.available,
                "reason": s.reason,
                "utilization": s.utilization,
                "resets_in": s.resets_in,
            } for i, s in enumerate(scored)],
            "recommended_primary": next((s.model for s in scored if s.available), None),
            "recommended_per_family": {fam: s.model for fam, s in family_best.items()},
            "recommended_anthropic_order": [s.profile_id for s in scored if s.provider == "anthropic"],
        }
        print(json.dumps(result, indent=2))
    else:
        print("🧠 FlowClaw Scoring\n")
        for i, s in enumerate(scored):
            status = "✅" if s.available else "🚫"
            print(f"  #{i+1}  {status} {s.account:15s}  score={s.score:.4f}  {s.reason}")
            print(f"       model: {s.model}")
            print(f"       profile: {s.profile_id}  resets: {s.resets_in}")
            print()

        best = next((s for s in scored if s.available), None)
        if best:
            print(f"  🎯 Recommended: {best.account} ({best.model})")
        else:
            print("  ⚠️  All accounts exhausted!")

if __name__ == "__main__":
    main()
