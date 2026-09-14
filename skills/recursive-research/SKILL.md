---
name: recursive-research
description: Deep recursive research to PhD level on any topic. Use when you want to go deep on a topic to expert level, understand a new field to make informed decisions, prepare a technical document, paper, or proposal, or map the state of the art and its knowledge gaps. Runs self-regulating research cycles with source tiering, WDM + Munger inversion, and disk checkpoints that survive context compaction.
license: MIT
metadata:
  version: "2.2.0"
  author: "Joseph Huayhualla (@Anjos2); opencode port"
  repository: "https://github.com/Anjos2/recursive-research"
  opencode/slash: "false"
---

# Skill: Deep Recursive Research

Self-regulated research that iterates until it reaches **PhD level** on a research seed (root topic). Works in any domain: formal sciences, natural sciences, social sciences, humanities, arts, technology, business.

## Principles

1. **Ask before researching** — the skill asks the user about the seed, mode, and sources BEFORE starting
2. **Trusted sources with transparent tiering** — automatically rejects unreliable sources
3. **WDM + Munger inversion** in every non-trivial autonomous decision
4. **Self-regulating loop** — no fixed iterations; a measurable criterion closes the run
5. **Defensive checkpointing** — writes to disk every cycle; survives context compaction or session end
6. **Preventive pause** — detects proximity to the context limit and suggests pausing before forced closure

---

## Full workflow

### Phase 0 — Invocation handling, then initial questions (the skill asks)

Read the invocation text — the user's message that triggered this skill, e.g. `/recursive-research --resume <slug>` — for a flag, **before doing anything else**:

- **`--resume <slug>` present** → go straight to **`--resume` mode** and stop. The slug names the run: never enumerate runs or ask which one. If the slug is missing or matches no run, say so and show the available runs.
- **`--list` present** → go straight to **`--list` mode** and stop.
- **Neither present** → continue Phase 0. If `memory/research/` already holds runs, offer **resume / list / new** before asking the seed question.

Then the skill asks the user, in order:

1. **Research seed**: "What topic do you want to research?" (free text)
2. **Mode**: `web` / `local` / `mixed`
3. **If local is included**: "Which local paths should I investigate?" (comma-separated list of paths)
4. **Prioritized sources** (optional): authors, domains, preferred publications
5. **Excluded sources** (optional)
6. **Hard cycle cap** (default: 20; configurable)
7. **Fixture retention** (optional): size threshold above which binary fixtures are gitignored (default: 5 MB)

The skill presents a summary and waits for confirmation before starting.

---

### Phase 1 — Workspace preparation

1. Generate a `slug` from the seed (kebab-case, max. 40 characters)
2. Verify / create `memory/research/<slug>/` in the current working directory
   - **If `memory/` does NOT exist, create it**, explaining: *"The `memory/` folder does not exist in the project. I am creating it because the skill needs to consolidate findings to disk each cycle — that is what lets a run resume in a new session."*
3. Create the initial files (see §Generated files for the full layout and what each holds):
   `state.md`, `threads.md`, `findings.md`, `sources-tier-1.md`, `sources-tier-2.md`, `sources-tier-3.md`, `sources-rejected.md`
4. Create the fixture store (see §Fixture registry):
   `fixtures/registry.schema.json` (the committed schema), `fixtures/registry.json` (with an empty `fixtures` array), and `fixtures/.gitignore` (nested — never the project-root `.gitignore`).

---

### Phase 2 — Identify seed threads

Generate **3-5 seed threads** (distinct angles on the topic).

**Apply WDM to thread selection**:

| Criterion | Weight | What it evaluates |
|---|---|---|
| Conceptual coverage | 4 | Does it cover a distinct dimension of the topic? |
| Diversity of perspectives | 3 | Does it bring in distinct voices / schools? |
| Source accessibility | 3 | Do Tier 1/2 sources exist for this thread? |
| Relevance to the user | 4 | Does it align with the goal that motivated the run? |

Evaluate 5-8 candidate threads, select the top 3-5.

**Munger inversion on the selected threads**:
- What important thread am I ignoring?
- What missing perspective would make my research one-sided?
- What school / dissenting voice is absent?

If the inversion reveals a critically missing thread, add it and re-run WDM.

**Examples by domain**: see `reference/domains.md` (sibling to this file) for typical seed threads per domain.

---

### Phase 3 — Detect available research tools (capability ladder)

Before the first cycle, detect which research capabilities the environment exposes and use the first rung that is available:

1. **ketch research tools (MCP)** — if your environment exposes them, use them.
2. **`ketch` on `PATH` (CLI)** — otherwise, if `ketch` is on `PATH`, use the CLI.
3. **Built-in web search / fetch** — otherwise use the agent's built-in web search and fetch.
4. **Other research MCPs** — otherwise fall back to any other research MCPs.

**Detection note (one line):** check whether the ketch MCP tools are present in your tool list, else run `which ketch`; record which rung you landed on before the first cycle.

**Routing (when ketch is available, MCP or CLI):**
- **General web search** → ketch `search`; call it **twice** — once with `multi: ["all"]` and once with the default backend — then merge and dedupe the two result sets by normalized URL, keeping both sets for tiering.
- **Repo / code-example questions** → ketch `code`.
- **Library / framework documentation** → ketch `docs` (replacing the previous docs-MCP path).
- **URLs already in hand** → ketch `scrape`.
- **Multi-page sources** → ketch `crawl`, only when one page is not enough.
- **Scrape policy** — scrape only the URLs selected as a cycle's sources (≈3-5).

Real-browser / JS-rendering MCPs are deprioritized: use them only when the content genuinely requires explicit JS execution (SPAs without SSR, content behind auth). AI-optimized scrapers are 10-50× faster than real browsers and return already-structured text.

**Raw capture (fixtures).** Persist each selected source as a *fixture* under `memory/research/<slug>/fixtures/` and index it in `fixtures/registry.json` (see §Fixture registry). Capture at the fetch that produced the content; if the tool is absent or the fetch fails, record a `pointer-only` fixture (URL + metadata, no bytes) — never silently skip.

- **Webpage** → `ketch scrape --raw --json <url>` yields `markdown`, `raw_html`, and `source` in one fetch; write `page.md` + `raw.html`.
- **Search-result set** → `ketch search --json` (both passes merged and deduped); write `results.json`.
- **Document (PDF)** → text-layer PDF via `ketch scrape --json` → `doc.md`; a scanned PDF (ketch reports no text layer) → download bytes with `curl`/`wget` → `doc.pdf`.
- **Document (OOXML/office)** → download bytes with `curl`/`wget` → `doc.<ext>`; additionally attempt `python3` stdlib `zipfile` XML extraction → `doc.txt` (docx/xlsx/pptx are zip + XML). A failed extraction is recorded in `notes`, never silent.
- **Media (audio/video)** → `yt-dlp --write-info-json` for streaming sites, or `curl`/`wget` for direct URLs → the media file + `info.json`; `ffmpeg` is used **only on demand** (transcode/remux/extract), never by default.
- **Git repo** → full `git clone` (**no `--depth 1`**) into `fixtures/git/<id>/repo/`; the registry records the remote URL and the `HEAD` SHA. Use `--recurse-submodules`, and `git lfs pull` when the repo uses LFS and `git-lfs` is present. A clone failure or timeout → `pointer-only` (remote URL, plus the commit SHA when resolvable).

---

### Phase 4 — Suggested seed sources

The skill presents the user with a list of seed sources **pre-loaded by domain** so they can **confirm, add, or reject** them: see `reference/domains.md` (sibling to this file) for the per-domain catalogue.

**Local sources** (if the user provided paths):
- List the folder structure
- Prioritize `.md`, `.pdf`, `.txt`, `.doc/.docx`, `.html`, `.epub`
- Use the agent's built-in file-reading and search tools

---

### Phase 5 — Research cycle (self-regulating LOOP)

Each cycle runs the following sub-steps.

#### 5.1. Choose the thread with the lowest coverage

Compute each thread's current coverage (`findings_recorded / expected_findings_proxy`). Choose the one with the lowest %.

#### 5.2. WDM + Munger on the sources to use in THIS cycle

**WDM per candidate source**:

| Criterion | Weight | Scale |
|----------|------|--------|
| Authority (Tier) | 5 | Tier 1 = 5 · Tier 2 = 3 · Tier 3 = 2 · Rejected = 0 |
| Relevance to the current thread | 5 | 1-5 by semantic match |
| Accessibility | 3 | 5 = open full text · 3 = abstract + paywall · 1 = blocked |
| Recency appropriate to the field | 2 | Code: recent > old · Classical philosophy: old = relevant |
| Absence of conflict of interest | 3 | 5 = independent · 1 = funded by an interested party |

Select the top 3-5.

**Munger inversion on the selected sources**:
- What source am I NOT using that I should be? (dissenters, critical schools, silenced voices)
- What bias do all the selected sources share? (Anglophone only, one era only, one school only)
- What documented contrary opinion exists? → Add at least 1 contradictory source if one exists

#### 5.3. Run searches / reads

- Use the research capabilities in the order detected in Phase 3 (ketch tools → ketch CLI → built-in → other MCPs)
- For general web search, run the two-pass ketch search and merge/dedupe as described in Phase 3
- Extract: concrete facts, numerical data, verbatim quotes with attribution, names of new people/works/concepts
- Record them in the cycle's working notes

#### 5.3b. Capture the cycle's fixtures

For each source selected in 5.2 and fetched in 5.3:

1. Compute the fixture `id`: `<kind>-<sha256(normalized url|query)[:12]>`.
2. If the `id` is already in `fixtures/registry.json`, do not re-fetch; update in place only when freshness was requested (`--no-cache`).
3. Write the representations under `fixtures/<kind>/<id>/` and build the registry entry (fields in §Fixture registry), recording `captured_at`, `tool`, and per-file `bytes` and `sha256`.
4. Write the cycle's merged search-result set as one `searchset` fixture.
5. Merge the entries into `fixtures/registry.json` with an **atomic write** (temp file + rename).

#### 5.4. Apply tiering to every source consulted

**Tier 1 — Maximum confidence**:
- Peer-reviewed papers in indexed journals (Scopus, Web of Science, PubMed, ACM, IEEE)
- Books from academic publishers (MIT Press, Oxford UP, Cambridge UP, Springer)
- Official standards documentation (W3C, IETF/RFC, ISO, IEEE, WHO, FDA, BIS)
- Verifiable primary sources (national museums, university libraries, state archives)
- Raw data from official statistical agencies

**Tier 2 — High confidence**:
- Official repositories of active, recognized projects
- Blogs / publications by citable authors (researchers, professionals with a verifiable track record)
- Talks at recognized conferences (with video and paper)
- Wikipedia *WITH* references to Tier 1/2 (treat as a reference aggregator)
- Reports from think tanks / consultancies with published methodology (Pew, Gartner, McKinsey Institute)

**Tier 3 — Useful with caution**:
- Blogs with internal citations to Tier 1/2
- Stack Overflow / high-vote forums plus citations
- Recorded interviews with identifiable experts
- Industry publications with clear authorship

**Automatic rejection**:
- No identifiable author
- Marketing without empirical data
- Spam / SEO aggregators
- Tutorials without cited sources
- Social media without verifiable context
- AI-generated content without documented human oversight

Every source consulted is recorded in the matching tier file with: title, URL, author, date, assigned tier, justification.

#### 5.5. Consolidate the checkpoint

Save at the end of the cycle: `memory/research/<slug>/cycle-N.md` with:
- Thread worked on
- Sources consulted (with tier)
- New findings
- Connections to previous threads
- Open questions for upcoming cycles

#### 5.6. Update `state.md`

- Increment the cycle counter
- Recalculate coverage per thread
- Record the saturation metric: `saturation = new_findings_this_cycle / total_findings_accumulated`
- Update the estimate of tool calls and output tokens consumed

#### 5.7. Evaluate the closure criteria — the "PhD-level" fitness function

All 5 criteria MUST hold:

1. **Coverage ≥80%** on all seed threads
2. **≥3 Tier-1 sources per thread** (or Tier 1+2 combined if the field has few Tier 1 sources)
3. **Saturation ≤5%** for 3 consecutive cycles
4. **Munger inversion applied to the state of knowledge**: documented what I do NOT know, what the sources contradict, and what biases I detected
5. **Cross-thread synthesis**: ≥3 explicit connections between different threads recorded

**Decision**:
- All met → Phase 6 (natural closure)
- Cycle cap reached → Phase 6 (forced closure with a warning)
- Otherwise → continue to step 5.8

#### 5.8. Preventive pause (context check)

Thresholds:
- `tool_calls_in_session ≥ 150`
- **OR** `approx_output_tokens ≥ 80000`

If either is crossed:

1. Write a full checkpoint (5.5 + 5.6)
2. Emit this message:

```
[PREVENTIVE PAUSE RECOMMENDED]

Current state:
- Cycles completed: N
- Tool calls in session: X (near the limit)
- Approx. output tokens: Y

Reason: I am approaching the context limit. If I continue, I may lose coherence
when the session is compacted.

The research is saved in:
  memory/research/<slug>/

To resume in a new session:
  /recursive-research --resume <slug>

Pause here, or continue for 1-2 more cycles? (continue / pause)
```

3. Wait for the response. If `continue`, keep going. If `pause`, jump to Phase 6 (documented partial closure).

If neither threshold is crossed → return to 5.1 for the next cycle.

---

### Phase 6 — Closure

Whether closure is natural (5 criteria met), forced (cycle cap), or partial (manual pause):

1. **`synthesis.md`** — executive synthesis:
   - Plain-language summary (3-5 paragraphs)
   - Findings per thread with cross-references
   - Controversies and contradictions detected
   - Knowledge gaps (what was NOT investigated / what remains open)
   - Map of the threads followed (tree)

2. **`actions.md`** — checklist of actionable items, prioritized by impact

3. **Final Munger inversion on the state of knowledge** (record in `gaps.md`):
   - What do I still not know?
   - Which sources contradicted each other and I did not resolve?
   - What bias does my set of sources have?
   - What question should a critical reviewer ask me that I cannot answer?

4. **`report.md`** — the single consolidated report. Build it from the artifacts above in this fixed order: title + run metadata; table of contents; executive summary (from `synthesis.md`); findings by thread with cross-references; thread map; sources (T1–T3 table with tier + fixture link); fixtures (registry table, grouped by thread); controversies & contradictions; knowledge gaps; actions; method & provenance. Inline everything **except fixture bodies**, which are linked by relative path from the fixtures table. Append a rejected-sources appendix and a per-cycle audit appendix.

5. **Ask the user**:

```
[RESEARCH COMPLETE — status: natural / forced / paused]

Seed: <topic>
Cycles executed: N / <cap>
Sources consulted: X total (T1: A · T2: B · T3: C · Rejected: D)
PhD status: reached / NOT reached (reasons: ...)

Gaps identified:
  1. ...
  2. ...
  3. ...

Options:
  1. Close here
  2. Go deeper on a specific gap (say which)
  3. Add a new thread and continue
  4. Change mode (web → mixed, etc.)

What do you prefer?
```

**A run can be infinite** — it closes only by the user's decision.

---

## `--resume` mode

Invocation: `/recursive-research --resume <slug>` — `<slug>` is the run's folder name under `memory/research/`.

1. Look for `memory/research/<slug>/`
2. If no exact folder matches, look for a run whose slug or seed matches `<slug>` case-insensitively before giving up.
3. If still nothing matches → say clearly that no run matches `<slug>`, list the available runs, and stop. Do not silently fall back to the resume/list/new menu.
4. If it exists:
   - Read `state.md` → rebuild the metrics
   - Read the latest `cycle-N.md` → recent context
   - Read `threads.md` → current tree
   - Present: "Resuming from cycle N. Next step: [thread X]. Continue?"
5. Continue the loop from Phase 5

---

## `--list` mode

Invocation: `/recursive-research --list`

List every run saved under `memory/research/` in the current project:
- Slug · Seed · Cycles completed · Status (open / closed) · Last modified

---

## Quality bar

Hold every cycle, and the closure, to these targets:

1. **Dig past the first page** — open the actual results and follow their references, rather than re-querying synonyms.
2. **Run Munger inversion on every source set** — pick against comfort, and add at least one contradictory source wherever one exists.
3. **Checkpoint every cycle** — dump state to disk at the end of each cycle, before advancing.
4. **Tier every source with its justification** — a Tier 3 source stands only when it explicitly cites Tier 1/2.
5. **Earn the PhD claim with the 5 measured criteria** — declare PhD level only when all five hold; when one is missing, keep iterating.
6. **Document the gaps** — record what remains unknown; gaps are part of the deliverable.
7. **Keep the controversies visible** — surface contradictions and disagreements; intellectual honesty is the result.
8. **Verify internal knowledge against a source** — the agent's knowledge may be stale.
9. **Capture a fixture for every selected source** — persist the raw evidence and index it in `fixtures/registry.json`; a source without a fixture is not auditable.
10. **Close with one report** — `report.md` is the deliverable; a run is not complete until it exists.

---

## Generated files

```
memory/research/<slug>/
├── state.md               ← progress, metrics, metadata
├── threads.md             ← thread and sub-thread tree with status
├── sources-tier-1.md      ← most reliable sources consulted
├── sources-tier-2.md      ← high-confidence sources
├── sources-tier-3.md      ← sources to use with caution
├── sources-rejected.md    ← sources evaluated and discarded (with the reason)
├── findings.md            ← consolidated discoveries
├── cycle-01.md            ← cycle 1 checkpoint
├── cycle-02.md
├── cycle-N.md
├── synthesis.md           ← executive synthesis (Phase 6)
├── actions.md             ← checklist of actionable items
├── gaps.md                ← what is NOT known, controversies, biases
├── report.md              ← single consolidated report (Phase 6)
└── fixtures/              ← raw captures + machine-readable index
    ├── registry.json      ← the fixture registry (always tracked)
    ├── registry.schema.json
    ├── .gitignore         ← nested; binaries over the threshold, git/*/repo/
    └── <kind>/<id>/       ← one directory per fixture (page.md, raw.html, …)
```

---

## Fixture registry

Every consulted source selected for a cycle is persisted as a **fixture** under `fixtures/` and indexed in `fixtures/registry.json`:

```json
{
  "$schema": "./registry.schema.json",
  "schema_version": "1.0.0",
  "run": { "slug": "<slug>", "seed": "<seed>" },
  "fixtures": [
    {
      "id": "webpage-<12 hex>",
      "revision": 1,
      "kind": "webpage",
      "url": "https://…",
      "fetched_url": "https://…",
      "title": "…",
      "author": "…",
      "tier": 1,
      "cycle": 1,
      "thread": "…",
      "captured_at": "2026-01-01T00:00:00Z",
      "tool": "ketch scrape --raw --json",
      "status": "captured",
      "media_type": "text/markdown",
      "bytes": 1842,
      "sha256": "<64 hex>",
      "local_path": "fixtures/webpage/webpage-<12 hex>",
      "license": "…",
      "notes": "…",
      "files": [
        { "role": "page", "path": "page.md", "media_type": "text/markdown", "bytes": 1842, "sha256": "<64 hex>" },
        { "role": "raw_html", "path": "raw.html", "media_type": "text/html", "bytes": 41233, "sha256": "<64 hex>" }
      ]
    }
  ]
}
```

- **Kinds:** `webpage | searchset | document | media | git | other`. Raw HTML is a file `role`, not a kind.
- **id:** `<kind>-<sha256(normalized url|query|remote)[:12]>` — stable across cycles and `--resume`.
- **status:** `captured | pointer-only | failed`.
- **Required fields:** `id, kind, captured_at, tool, status`; everything else is optional.
- **Retention:** `registry.json`, `registry.schema.json`, and text fixtures are tracked; binaries above the size threshold (default 5 MB, set in Phase 0) are gitignored via the nested `fixtures/.gitignore`; `fixtures/git/<id>/repo/` is always ignored. When `git-lfs` is installed and the project already uses LFS (or the user opts in), **ask first**, naming the tradeoffs — repo/remote size growth, LFS storage quota, extra setup, a `.gitattributes` change, and that non-LFS clones receive pointers — then run `git lfs track "fixtures/**"` only on agreement. Never run `git lfs install` or edit `.gitattributes` without agreement.
- **Validation:** JSON-parse plus required-field checks (`jq` / `python3`); `fixtures/registry.schema.json` is the committed JSON Schema 2020-12.

---

## Invocation example

```
User: /recursive-research

Skill: What topic do you want to research?
User: Mechanisms of episodic memory in humans

Skill: Mode? (web / local / mixed)
User: mixed

Skill: Local paths?
User: C:/Dropbox/neuroscience-papers

Skill: Prioritized sources / authors? (optional)
User: Endel Tulving, Eleanor Maguire

Skill: Excluded sources? (optional)
User: -

Skill: Cycle cap? (default 20)
User: 25

Skill: Confirmed. Seed: "episodic memory in humans" · Mode: mixed · Local: [C:/Dropbox/neuroscience-papers]
       Prioritize: [Tulving, Maguire] · Cap: 25 cycles

       The `memory/` folder does not exist. I am creating it — it is needed
       to consolidate each cycle to disk.

       Applying WDM + Munger to identify seed threads... Selected 5:
       neuroanatomical foundations · phenomenology and taxonomy · disorders
       and dissociations · computational models · contemporary cognitive neuroscience

       Path: memory/research/episodic-memory-in-humans/
       Starting cycle 1 (lowest-coverage thread: 1)...
```

---

## Authorship and license

- **Author:** Joseph Huayhualla ([@Anjos2](https://github.com/Anjos2))
- **License:** MIT — see the repository's `LICENSE` file
- **Repository:** https://github.com/Anjos2/recursive-research

Contributions are welcome. If you find a quality-bar gap, a better heuristic, or a more robust PhD criterion, open a PR.
