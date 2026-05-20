# Scenario-First Development

*Read this in [한국어](README.ko.md).*

> ### We build from how you want to use it.

The barrier to building software is gone — anyone can vibe-code now. So what *is* "development" to a **normal person** (*who was never taught computational thinking*)? Not a dry, academic definition. **"Make it work the way I want to use it."** — that's the development they actually want.

This system reflects exactly that need.

**Throw the way you want to use it.** A structured pipeline catches that scenario and turns it into a working thing. You don't need to know *anything* about what happens inside — just check one thing: when you try that same scenario, does the result behave the way you meant?

<details>
<summary>Still curious what happens inside?</summary>

1. It **unfolds** that scenario into the smallest MVP that can stand on its own.
2. It **locks** that into a concrete spec — and makes it a promise.
3. It **writes code until your scenario passes.**
4. Now **press the button** — is this what you wanted?

</details>

This repo is a **GitHub template**. Click "Use this template" and the 6 skills + meta-agent are already in your clone — no external install, no marketplace, no trust dialog.

---

## Quick start

```
1. GitHub → "Use this template" → new repo → clone
2. Open Claude Code and just run:  /scenario-first-throw "<first scenario>"
```

That's it. Flow straight through `throw`(1) → `expand`(2) → `spec`(3).
**The E2E framework is asked once, the first time you run `/scenario-first-goal`(4)** — no need to decide up front.

> A fresh clone carries a little of SFD's own residue (unsubstituted placeholders, this README). If it bothers you, `/scenario-first-init` clears it in one shot — optional and idempotent. (See [clone cleanup](#clone-cleanup) below.)

---

> **That's all you need to know.** Everything below is for people who want to build it themselves — or are just curious what happens inside.

## The 5-stage flow

```
your usage intent
     │ "this is how I want to use it"
     ▼
┌────────────┐  Job Story (When / I want to / so I can)
│ 1. throw   │──────────► scenarios/throws/NNN-*.md
└────────────┘
     │
     ▼
┌────────────┐  USM backbone + walking skeleton
│ 2. expand  │  + Example Mapping (Rule/Example/Question/Story)
│            │  + meta-interview → GWT scenarios
└────────────┘──────────► scenarios/expanded/NNN-*.md
     │
     ▼
┌────────────┐  PRD + ARCHITECTURE + NONFUNC + OPS
│ 3. spec    │  (4 fixed slots)
└────────────┘──────────► scenarios/specs/NNN/{PRD,ARCH,NONFUNC,OPS}.md
     │
     ▼
┌────────────┐  GWT → auto-convert to E2E → run gate
│ 4. goal    │  (cumulative scenario pool + LLM judge fallback)
│            │  (3 progress signals for stuck detection)
└────────────┘──────────► tests/e2e/scenario-NNN/, GOAL.md or STUCK.md
     │
     ▼
┌────────────┐  you use it yourself + checklist
│ 5. review  │  on failure: 5 Whys → route (1)/(2)/(3)
└────────────┘──────────► REVIEW.md
     │
     ├─ pass → next backbone slice (new throw)
     └─ fail → (1) revise throw / (2) re-run spec / (3) resume goal
```

**One direction. No back-sync. One cycle (NNN) at a time.**

---

## Design philosophy — 4 pillars

### 1. The answer isn't code or spec — it's "how I want to use it"

Code gets rewritten; specs get deprecated. But *"this is how I want to use it"* stays relatively stable. So the Source of Truth lives in that **usage scenario**, externalized into `scenarios/`.

Why **Job Story**, not User Story:

| User Story's weakness | How Job Story fixes it |
|---|---|
| Persona assumption ("a developer…") — wrong answer if that persona isn't you | Drop the persona; keep only the **situation** |
| Rationalized motive ("to improve efficiency") — misses the real in-the-moment motive | Pin the motive to the moment |
| Missing trigger — "when is this needed?" left out | Make the trigger explicit with **When** |

→ `When <situation>, I want to <motive>, so I can <outcome>`

### 2. No improvised decomposition — same procedure every time

If the *way* you get from Job Story to gate changes each time, so does the quality. So the same 4 tools run in the same order:

1. **USM** (Jeff Patton) — backbone (large steps in time order) + walking skeleton (one minimal action per step)
2. **Example Mapping** (Matt Wynne) — 🟦 Rule / 🟩 Example / 🟥 Question / 🟨 Story cards
3. **Meta-interview** — ask Question cards one at a time, narrowing ambiguity to a point you can decide
4. **GWT** (Dan North) — Example cards → `Given/When/Then`, 1:1

Determinism removes the variance in outcomes.

### 3. The gate is the answer — no human asking "is this right?"

The GWT scenario itself defines correctness.

- **Primary gate**: GWT → auto-converted E2E (Playwright / Cypress / Cucumber / pytest-bdd / behave)
- **Fallback**: only un-convertible cases go to an LLM judge (quoting the Then verbatim)
- Manual checks aren't in the gate — that's review's (stage 5) job

The gate is **this scenario + every accumulated prior scenario**. Regression isn't a separate gate; it's absorbed into this cumulative pool.

Thrashing is stopped by **3 progress signals** — measuring progress itself, not cost: `STUCK_RETRIES` (same failure hash repeats) · `NO_PROGRESS` (PASS count frozen) · `MAX_ITERATIONS` (iteration cap).

### 4. If you don't use it yourself, the system dies

Passing every automatic gate is a *fake* pass if you never use the thing — the **"periodic auto-MVP" trap**, where validated-looking-but-useless output piles up.

Review (stage 5) is the last line against this trap:

- The checklist = the Job Story's `so I can…` + the walking-skeleton line (written by you)
- **Claude must not simulate** — it stops until *you* actually use it
- On failure, 5 Whys routes to (1) scenario / (2) spec / (3) implementation
- There is no 4th "just leave it" option

Skip this stage and stages 1–4 become meaningless.

---

## When to use / when not

**Good fit** — single-developer mode where you build, use, and evaluate yourself. Tools/apps where "how I want to use it" is relatively stable. When you already have one core usage scenario and want to validate a thin MVP quickly. Evolutionary development filling backbone slices cycle by cycle.

**Poor fit**:

| Doesn't fit | Why |
|---|---|
| Tiny one-off scripts | 5 stages are overhead |
| When the user isn't you (client/delivery work) | Review's "use it yourself" mandate breaks |
| When you must validate the scenario itself fast | Use a spike etc. — this method is the *post-decision* stage |
| Team collaboration as the norm | "Personal cycle lock" creates friction — needs adapting |
| Non-deterministic output (generative AI / ML) | Hard to express in GWT's deterministic Then |

---

## Operating layer — 9 rules the 5 skills don't know

Each skill knows only its own stage — not the whole cycle, cross-session state, the cumulative-gate policy, or harness self-evolution. `.harness/` owns this meta layer.

| # | Rule | Where |
|---|---|---|
| 1 | **Cumulative-gate entry** — only `review_status: passed` NNN enter the pool | `REGRESSION-POLICY.md` |
| 2 | **Unified rerun backups** — `.harness/.backups/<NNN>/<ISO8601>/` | (gitignore) |
| 3 | **STATUS.md update duty** — each skill appends one line when done | `STATUS.md` |
| 4 | **Cycle lock** — one NNN at a time, single `IN_PROGRESS` | `STATUS.md` |
| 5 | **Routing NNN reuse** — (1)/(2)/(3) reuse the NNN; a new backbone gets a new NNN | AGENTS.md 3.5 |
| 6 | **Story / parking pool** — Example Mapping Story cards + ARCH deferred decisions | `backlog.md` |
| 7 | **codex/cursor trigger** — `[SCENARIO:throw] …` for slash-less agents | AGENTS.md 3.7 |
| 8 | **Jargon policy** — USM / walking skeleton / GWT etc. assumed learned | AGENTS.md 3.8 |
| 9 | **Harness-change channel** — change the harness via `/sfd-architect` review; record in the commit message | AGENTS.md 3.9 |

<details>
<summary>Directory structure</summary>

```
my-project/
├── AGENTS.md            # entry point — start (6 steps) + 9 rules + end (5 steps)
├── CLAUDE.md            # points to AGENTS.md
├── init.sh              # bootstrap / verify / start
├── .env.scenario        # 3 progress signals + E2E command (gitignore)
├── .gitmessage          # walking-skeleton commit convention
│
├── scenarios/                       ← SoT (scenario bodies, visible)
│   ├── throws/NNN-*.md
│   ├── expanded/NNN-*.md
│   └── specs/NNN/{PRD,ARCHITECTURE,NONFUNC,OPS}.md
│                        + GOAL.md|STUCK.md (goal result) · REVIEW.md (review result)
│
├── .harness/                        ← operating layer (meta, hidden)
│   ├── STATUS.md · SESSION-LOG.md · HANDOFF.md
│   ├── REGRESSION-POLICY.md · backlog.md · judge-rubric.md
│   ├── rules.json                   # machine-readable rules (harness_change_via_architect, …)
│   ├── templates/{REVIEW.md, gitignore-additions}
│   └── .backups/<NNN>/<ts>/         # rerun backups (gitignore)
│
├── tests/e2e/scenario-NNN/          # auto-generated by goal
│
└── .claude/                         ← Claude Code project-local
    ├── skills/scenario-first-{init,throw,expand,spec,goal,review}/
    └── agents/sfd-architect.md      # harness-change review channel
```

**Separation of duties**: `scenarios/` = SoT (the user's usage intent, stage by stage; appended each stage). `.harness/` = operating meta (state, policy, logs).

</details>

<details id="clone-cleanup">
<summary>(optional) clone cleanup — <code>/scenario-first-init</code></summary>

A fresh clone mixes **assets you keep** with **SFD's own residue**:

| Keep (yours) | SFD residue (to clean) |
|---|---|
| `.claude/skills/` 6 skills + `agents/sfd-architect` | placeholders in `AGENTS.md` (`{{PROJECT_NAME}}`, …) |
| `.harness/` · empty `scenarios/` · `tests/e2e/` | `.env.scenario` not yet created (only `.example`) |
| `init.sh` · `.gitmessage` · `rules.json` | this `README.md` (= SFD's methodology doc, not yours) |

> SFD's record of evolving this template lives **only in commit messages**. "Use this template" does not carry git history (your clone starts as a single fresh commit), so that record never follows you downstream.

`/scenario-first-init` (no args, idempotent) clears the right column:
1. Substitute placeholders (`{{PROJECT_NAME}}`→repo name, E2E values, date)
2. Create `.env.scenario` + decide the E2E framework
3. Remove SFD's methodology `README.md` (your own README is separate)
4. Register git `commit.template`

**You don't have to run it** — `throw`~`spec` work as-is and `goal` asks about E2E itself. Skipping it just leaves cosmetic residue.

</details>

---

## Changing the harness — sfd-architect

Sometimes, while building with this template, you want to change not your *project code* but the **harness itself** (the 5 skills, operating rules, init behavior, `.env` schema). Don't touch it directly — use the safe channel:

```
/sfd-architect "<what you want to change>"
```

`sfd-architect` only **reviews** (it can't touch code) — impact grep + protection-rule check + justification, then a review report and a draft commit message. You confirm, the main agent applies, and **the record is the commit message**. (No separate ADR file — git history is authoritative and never leaks into clones.)

---

## Influences

| Source | What it contributed |
|---|---|
| JTBD (Clayton Christensen) | "motive + outcome" as the narrative SoT |
| Job Story (Paul Adams, Alan Klement) | reject persona + make the trigger explicit |
| USM (Jeff Patton, 2014) | backbone + walking skeleton = MVP slice |
| Example Mapping (Matt Wynne, 2015) | 4-color cards for deterministic decomposition |
| BDD GWT (Dan North, 2006) | the automatic-gate unit |
| Spec Kit | preserve determinism — but fix the *SoT location*, not the structure |
| Toyota 5 Whys | review-failure routing |
| Walking Skeleton (Alistair Cockburn) | the gate unit |
| Harness Engineering | `.harness/` as a closed-loop work system for the agent |

---

## License

MIT © 2026 chanshin0 — see [LICENSE](LICENSE).
