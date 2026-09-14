# recursive-research

> An **opencode skill** for recursive research up to PhD level on any topic — science, tech, business, arts, humanities. Source tiering, a self-regulating loop, disk checkpointing, and WDM + Munger inversion for autonomous decisions.

**Port of:** [Anjos2/recursive-research](https://github.com/Anjos2/recursive-research) v2.2.0 (MIT) · **License:** [MIT](LICENSE)

---

## What it does

You give it a **research seed** (a topic) and the skill:

1. Asks for mode (`web` / `local` / `mixed`), local paths if applicable, priority/excluded sources, and a cycle cap.
2. Identifies **3-5 seed threads** applying [WDM (Weighted Decision Matrix) + Munger inversion](#wdm--munger-inversion).
3. Detects the available research capabilities and prefers **ketch** (MCP, then CLI), falling back to built-in web search/fetch.
4. **Iterates in self-regulating cycles** — each cycle picks the least-covered thread, selects sources, investigates, and consolidates.
5. Tiers every source into **Tier 1 / 2 / 3 / Rejected** with transparent criteria.
6. Saves **disk checkpoints** every cycle — survives context compaction.
7. Closes when the **5-criteria PhD fitness function** is met, or upon hitting the cycle cap.
8. Asks if you want to keep going. **Research can be infinite.**

---

## Why it's different

| Feature | How it solves it |
|---|---|
| Works across **any domain** | Generic source tiering (papers, academic books, official archives, raw data), not code-only |
| **Rejects garbage sources** automatically | Explicit criteria: no author, data-less marketing, SEO spam, unsupervised AI content |
| **Survives context limits** | Per-cycle disk checkpoint + `--resume` mode for new sessions |
| **Self-critical** | Munger inversion applied to the consolidated knowledge: what do I not know? what bias do my sources share? what's missing? |
| **Asks before assuming** | Full Phase 0 interrogation of the user |
| **Transparent** | Every non-trivial autonomous decision runs WDM + Munger and shows the reasoning |

---

## Installation

### Via the skills CLI (recommended)

```bash
# Project scope — installs to .agents/skills/
npx skills add kido5217/opencode-recursive-research -a opencode

# Global scope — installs to ~/.config/opencode/skills/
npx skills add kido5217/opencode-recursive-research -a opencode -g

# List the skills in the repo without installing
npx skills add kido5217/opencode-recursive-research --list
```

opencode discovers skills under `.agents/skills/` (project), `~/.config/opencode/skills/` (global), and `.opencode/skills/`. The `skills` CLI installs to the first of those for OpenCode.

### Manual

```bash
git clone https://github.com/kido5217/opencode-recursive-research.git
mkdir -p .agents/skills/recursive-research
cp opencode-recursive-research/skills/recursive-research/SKILL.md .agents/skills/recursive-research/
```

Invoke with `/recursive-research`, or let it auto-trigger from its description.

---

## Usage

```
/recursive-research                    # start a run (Phase 0 asks for the seed)
/recursive-research --resume <slug>    # resume a paused run
/recursive-research --list             # list saved runs
```

The skill guides you interactively. Answer in natural language. `<slug>` is the kebab-case name of the topic (e.g. `episodic-memory-in-humans`).

On opencode v2 the skill is deliberately **not** registered as a slash command (`metadata.opencode/slash: false` in the frontmatter). v2's skill-command path drops the trailing arguments, so a slash-invoked `/recursive-research --resume <slug>` would lose the slug and fall back to the run menu. Typing the line as a normal message — or letting the description auto-trigger the skill — keeps the arguments, exactly as on opencode v1.

### Usage examples by domain

| Domain | Suggested seed |
|---|---|
| Neuroscience | "Mechanisms of episodic memory in humans" |
| Philosophy | "Modern application of Stoic philosophy" |
| Music | "Minimalism in 20th-century music" |
| Business | "B2B SaaS monetization models in 2025" |
| History | "Fall of the Western Roman Empire: economic causes" |
| Biology | "CAR-T cell immunotherapy against cancer" |
| Technology | "Hexagonal architecture in microservices" |
| Law | "European AI Act and its extraterritorial impact" |

---

## "PhD level" criterion

The skill only declares PhD when **all 5 criteria** are met:

1. **Coverage ≥80%** across all seed threads
2. **≥3 Tier-1 sources per thread**
3. **New-finding saturation ≤5%** for 3 consecutive cycles
4. **Munger inversion applied** to the knowledge (what I don't know, what sources contradict, what biases exist)
5. **≥3 explicit cross-thread connections** between different threads

If any criterion fails, it **does not declare PhD** and keeps iterating — or asks for confirmation upon hitting the cycle cap (default 20, configurable).

---

## Source tiering

| Tier | Qualifies | WDM weight |
|---|---|---|
| **1** | Peer-reviewed papers · academic books · official standards (W3C, RFC, ISO, WHO) · primary archives · official datasets | 5 |
| **2** | Official repos · blogs from citable authors · recorded conferences · Wikipedia with references · reports with methodology | 3 |
| **3** | Blogs with citations to T1/T2 · high-voted forum answers with sources · recorded interviews with identifiable experts | 2 |
| **Reject** | No author · data-less marketing · SEO spam · tutorials without sources · unsupervised AI content | 0 |

Every consulted source is logged in a per-tier file for later audit.

---

## Research tools

The skill detects what your environment exposes and uses the first available rung:

1. **ketch research tools** (MCP) — `search`, `code`, `docs`, `scrape`, `crawl`
2. **ketch CLI** — `ketch search`, `ketch scrape`, `ketch crawl`, …
3. **Built-in web search / fetch** — universal fallback
4. **Other research MCPs** — any you have configured

For general web search it calls ketch search **both** with `multi: ["all"]` (federated across backends) and with the default backend, then merges and dedupes the two result sets before tiering. It scrapes only the URLs selected as a cycle's sources, not every hit.

Real-browser / JS-rendering MCPs are deprioritized: use them only when content genuinely requires JS execution (SPAs without SSR, content behind auth).

---

## Pre-loaded seed sources

The skill auto-suggests reliable sources by domain. Examples:

- **Science**: arXiv, Semantic Scholar, Google Scholar, Connected Papers, OpenReview
- **Medicine**: PubMed, Cochrane Library, WHO, ClinicalTrials.gov
- **Humanities**: JSTOR, SSRN, Project MUSE
- **Code**: GitHub, RFCs, W3C specs
- **Data**: World Bank, OECD Data, Our World in Data, Pew Research
- **Art/culture**: Europeana, Google Arts & Culture, Internet Archive, Project Gutenberg

The user can add or reject any before starting.

---

## WDM + Munger inversion

Decision frameworks applied at each non-trivial autonomous step:

- **WDM (Weighted Decision Matrix)** — enumerate 3+ viable alternatives, criteria with weights, 1-5 scoring, compared totals.
- **Munger inversion** (Charlie Munger via Jacobi) — ask inverted about the winning option: *"how would it fail? what bias does it have? what am I ignoring?"*

The skill applies both to:
- Select seed threads
- Select sources per cycle
- Decide when to close the research
- Validate the consolidated knowledge at the end

Reference: [Charlie Munger's essay on mental inversion](https://fs.blog/inversion/).

---

## Generated files

In `memory/research/<slug>/` of the active project:

- `state.md` · `threads.md` · `findings.md`
- `sources-tier-1.md` · `sources-tier-2.md` · `sources-tier-3.md` · `sources-rejected.md`
- `cycle-01.md`, `cycle-02.md`, ..., `cycle-N.md` (checkpoints)
- `synthesis.md` · `actions.md` · `gaps.md` (upon closing)

**If `memory/` doesn't exist in the project, the skill creates it** (notifying the user) — it's an explicit dependency.

---

## Repository structure

```
opencode-recursive-research/
├── skills/
│   └── recursive-research/
│       ├── SKILL.md                    ← the skill
│       └── reference/
│           └── domains.md              ← per-domain threads + seed sources
├── CONTEXT.md                          ← EN/ES glossary
├── docs/
│   ├── artifact-name-map.md            ← ES→EN artifact names
│   ├── research/                       ← research notes
│   └── agents/                         ← tracker / triage / domain config
├── README.md
├── PRIVACY.md
└── LICENSE
```

---

## Contributing

Issues and PRs are welcome — if you improve a criterion, add a tier, or find a new anti-pattern.

---

## Attribution

This project is an **opencode port** of [recursive-research](https://github.com/Anjos2/recursive-research) by Joseph Huayhualla ([@Anjos2](https://github.com/Anjos2)), used under the MIT License. The ported `skills/recursive-research/SKILL.md` is a derivative work.

Upstream copyright notice:

> Copyright (c) 2026 Joseph Huayhualla (@Anjos2)

## License

[MIT](LICENSE) — use, modify, distribute freely. Just keep the copyright notice.

## Acknowledgments

- **Charlie Munger** — for "Invert, always invert" (via Carl Jacobi)
- **Joseph Huayhualla ([@Anjos2](https://github.com/Anjos2))** — for the original recursive-research skill
- **The opencode team** — for the skill format
