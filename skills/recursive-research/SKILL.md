---
name: recursive-research
description: Deep recursive research to PhD level across any domain — source tiering, WDM + Munger inversion, ketch-first web research, and disk checkpointing that survives context compaction.
license: MIT
metadata:
  version: "2.2.0"
  author: "Joseph Huayhualla (@Anjos2); opencode port"
  repository: "https://github.com/Anjos2/recursive-research"
---

# Skill: Deep Recursive Research (v2.2.0)

Self-regulated research that iterates until it reaches **PhD level** on a research seed (root topic). Works in any domain: formal sciences, natural sciences, social sciences, humanities, arts, technology, business.

## When to use

- You want to go deep on a topic to expert level
- You need to understand a new field to make informed decisions
- You are preparing a technical document, paper, proposal, or study
- You want to identify the state of the art and the knowledge gaps

## Principles

1. **Ask before researching** — the skill asks the user about the seed, mode, and sources BEFORE starting
2. **Trusted sources with transparent tiering** — automatically rejects unreliable sources
3. **WDM + Munger inversion** in every non-trivial autonomous decision
4. **Self-regulating loop** — no fixed iterations; a measurable criterion closes the run
5. **Defensive checkpointing** — writes to disk every cycle; survives context compaction or session end
6. **Preventive pause** — detects proximity to the context limit and suggests pausing before forced closure

---

## Full workflow

### Phase 0 — Initial questions (the skill asks)

Invocation handling comes first: if the invocation text contains `--resume <slug>` or `--list`, handle that before anything else (see the `--resume` and `--list` sections). Do not rely on `$ARGUMENTS` substitution — read the invocation text directly for the flags.

Otherwise, a bare `/recursive-research` (or an automatic trigger via the description) starts Phase 0. If `memory/research/` already holds runs, offer **resume / list / new** before asking the seed question.

Then the skill asks the user, in order:

1. **Research seed**: "What topic do you want to research?" (free text)
2. **Mode**: `web` / `local` / `mixed`
3. **If local is included**: "Which local paths should I investigate?" (comma-separated list of paths)
4. **Prioritized sources** (optional): authors, domains, preferred publications
5. **Excluded sources** (optional)
6. **Hard cycle cap** (default: 20; configurable)

The skill presents a summary and waits for confirmation before starting.

---

### Phase 1 — Workspace preparation

1. Generate a `slug` from the seed (kebab-case, max. 40 characters)
2. Verify / create `memory/research/<slug>/` in the current working directory
   - **If `memory/` does NOT exist, create it**, explaining: *"The `memory/` folder does not exist in the project. I am creating it because the skill needs to consolidate findings to disk each cycle — that is what lets a run resume in a new session."*
3. Create the initial files:
   - `state.md` — metadata, progress, metrics
   - `threads.md` — seed-thread tree + sub-threads
   - `sources-tier-1.md`, `sources-tier-2.md`, `sources-tier-3.md`, `sources-rejected.md`
   - `findings.md` — consolidation

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

**Examples by domain** (NOT code only):

| Domain | Seed | Typical threads |
|---------|---------|---------------|
| Science | Immunotherapy against cancer | Molecular mechanisms / Clinical trials / History and evolution / Controversies and limitations / Commercial landscape |
| Art | Minimalism in 20th-century music | Key composers / Techniques / Historical-cultural context / Criticism and reception / Landmark works |
| Business | B2B SaaS monetization models | Pricing strategies / Financial metrics / Documented cases / Legal framework / B2B purchase psychology |
| Humanities | Modern applied Stoic philosophy | Primary sources (Epictetus, Seneca, Aurelius) / Contemporary interpretations / Practical applications / Philosophical critiques / Empirical psychological evidence |
| Technology | Hexagonal architecture in microservices | Theoretical foundations / Language-specific implementations / Real-world cases / Trade-offs and critiques / Tools |

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
- **Scrape policy** — scrape only the URLs selected as a cycle's sources (≈3-5), never every hit.

Real-browser / JS-rendering MCPs are deprioritized: use them only when the content genuinely requires explicit JS execution (SPAs without SSR, content behind auth). AI-optimized scrapers are 10-50× faster than real browsers and return already-structured text.

---

### Phase 4 — Suggested seed sources

The skill presents the user with a list of seed sources **pre-loaded by domain** so they can **confirm, add, or reject** them:

**General science / papers**:
- arXiv (https://arxiv.org) — preprints in physics, mathematics, CS, biology, economics
- Semantic Scholar (https://www.semanticscholar.org) — citation network
- Google Scholar (https://scholar.google.com)
- Connected Papers (https://www.connectedpapers.com) — visual citation maps
- OpenReview (https://openreview.net) — open reviews in ML

**Medicine / biology**:
- PubMed (https://pubmed.ncbi.nlm.nih.gov)
- Cochrane Library (https://www.cochranelibrary.com) — meta-analyses
- WHO (https://www.who.int)
- ClinicalTrials.gov (https://clinicaltrials.gov)

**Humanities / social sciences**:
- JSTOR (https://www.jstor.org)
- SSRN (https://www.ssrn.com)
- Project MUSE (https://muse.jhu.edu)

**Code / technology**:
- GitHub (https://github.com) — search, topics, expert starred lists
- ketch `docs` for official documentation
- RFCs (https://www.rfc-editor.org)
- W3C specs (https://www.w3.org/TR/)

**Data / statistics**:
- World Bank (https://data.worldbank.org)
- OECD Data (https://data.oecd.org)
- Our World in Data (https://ourworldindata.org)
- Pew Research (https://www.pewresearch.org)
- Eurostat (https://ec.europa.eu/eurostat), INE, and national equivalents

**Art / culture / humanities**:
- Europeana (https://www.europeana.eu)
- Google Arts & Culture (https://artsandculture.google.com)
- Internet Archive (https://archive.org)
- Project Gutenberg (https://www.gutenberg.org)

**General**:
- Wikipedia (https://en.wikipedia.org) — as a STARTING POINT. Always jump to the **references** section to reach Tier 1/2
- Wikidata (https://www.wikidata.org) — structured data

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

4. **Ask the user**:

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

Invocation: `/recursive-research --resume <slug>`

1. Look for `memory/research/<slug>/`
2. If it does not exist → clear error, suggest a plain `/recursive-research`
3. If it exists:
   - Read `state.md` → rebuild the metrics
   - Read the latest `cycle-N.md` → recent context
   - Read `threads.md` → current tree
   - Present: "Resuming from cycle N. Next step: [thread X]. Continue?"
4. Continue the loop from Phase 5

---

## `--list` mode

Invocation: `/recursive-research --list`

List every run saved under `memory/research/` in the current project:
- Slug · Seed · Cycles completed · Status (open / closed) · Last modified

---

## Anti-patterns to actively reject

1. **Flat search** — repeating queries with synonyms without digging into actual results
2. **Ignoring Munger** — picking sources for comfort; the inversion is mandatory
3. **Missing checkpoint** — advancing 5 cycles without dumping to disk
4. **Tier 3 without references** — accepting a blog that does not explicitly cite Tier 1/2
5. **Self-confirming the PhD** — declaring PhD level without the 5 measured criteria; if one is missing, do NOT close
6. **Ignoring gaps** — closing without documenting what is unknown; gaps are part of the deliverable
7. **Intellectual condescension** — hiding controversies or contradictions "so the synthesis stays clean"; intellectual honesty IS the result
8. **Blindly trusting internal knowledge** — the agent's knowledge may be stale; always verify against a source

---

## Final structure of the generated files

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
└── gaps.md                ← what is NOT known, controversies, biases
```

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

Skill: Confirmed.
       Seed: "episodic memory in humans"
       Mode: mixed · Local: [C:/Dropbox/neuroscience-papers]
       Prioritize: [Tulving, Maguire] · Cap: 25 cycles

       Applying WDM + Munger to identify seed threads...
       [shows table]

       Selected threads:
       1. Neuroanatomical foundations (hippocampus, PFC)
       2. Phenomenology and taxonomy (Tulving et al.)
       3. Disorders and dissociations (amnesia, Alzheimer's)
       4. Computational models
       5. Contemporary cognitive neuroscience

       The `memory/` folder does not exist. I am creating it — it is needed
       to consolidate each cycle to disk.

       Path: memory/research/episodic-memory-in-humans/

       Starting cycle 1 (thread with the lowest coverage: 1)...
```

---

## Authorship and license

- **Author:** Joseph Huayhualla ([@Anjos2](https://github.com/Anjos2))
- **License:** MIT — see the repository's `LICENSE` file
- **Repository:** https://github.com/Anjos2/recursive-research

Contributions are welcome. If you find an anti-pattern we missed, a better heuristic, or a more robust PhD criterion, open a PR.
