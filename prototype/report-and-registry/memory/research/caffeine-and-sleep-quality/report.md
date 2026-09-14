# How caffeine affects sleep quality — research report

> **PROTOTYPE SAMPLE.** Illustrative shape only; content is fabricated to show structure.

| | |
|---|---|
| **Seed** | How caffeine affects sleep quality |
| **Slug** | `caffeine-and-sleep-quality` |
| **Mode** | web |
| **Cycles run** | 2 / 20 |
| **Closure** | forced (cycle cap demo) |
| **Started / closed** | 2026-09-14 / 2026-09-14 |

## Table of contents

1. [Executive summary](#1-executive-summary)
2. [Findings by thread](#2-findings-by-thread)
3. [Thread map](#3-thread-map)
4. [Sources](#4-sources)
5. [Fixtures](#5-fixtures)
6. [Controversies & contradictions](#6-controversies--contradictions)
7. [Knowledge gaps](#7-knowledge-gaps)
8. [Actions](#8-actions)
9. [Method & provenance](#9-method--provenance)

---

## 1. Executive summary

Caffeine delays sleep onset and shortens total sleep time in a dose- and
timing-dependent way. The strongest evidence comes from controlled crossover
trials; the effect is still measurable when caffeine is consumed up to six hours
before bedtime. Individual sensitivity varies substantially, and the popular
literature overstates certainty about "half-life" cutoffs. *(Sample text.)*

## 2. Findings by thread

### Thread: sleep-architecture

- 400 mg caffeine 0/3/6 h before bed reduced total sleep time at every interval.
  *Evidence:* [webpage-a1b2c3d4e5f6](fixtures/webpage/webpage-a1b2c3d4e5f6/page.md) (Tier 1).
- Effect size was largest at the shortest interval, but non-trivial at 6 h.
- **Cross-thread:** the 6 h finding constrains the *interventions* thread
  (a fixed "no caffeine after 2 pm" rule is a blunt proxy, not a guarantee).

### Thread: interventions

- Behavioural cutoffs dominate popular guidance despite weak dose-response data.
  *Evidence:* [webpage-9d8c7b6a5f4e](https://example-blog.invalid/caffeine-sleep) (Tier 3, pointer-only).

## 3. Thread map

```
caffeine-and-sleep-quality
├── sleep-architecture        (coverage 80%)
│   └── dose-response timing
└── interventions             (coverage 45%)
    └── behavioural cutoffs
```

## 4. Sources

| Tier | Source | Fixture |
|---|---|---|
| 1 | Drake et al., *Caffeine effects on sleep taken 0, 3, or 6 hours before going to bed* | [webpage-a1b2c3d4e5f6](fixtures/webpage/webpage-a1b2c3d4e5f6/page.md) |
| 3 | "Why caffeine ruins your sleep (and what to do)" — Unknown | [webpage-9d8c7b6a5f4e](https://example-blog.invalid/caffeine-sleep) *(pointer-only)* |

## 5. Fixtures

Grouped by thread; full machine-readable index in
[`fixtures/registry.json`](fixtures/registry.json).

### sleep-architecture

| id | kind | title | tier | status | bytes | link |
|---|---|---|---|---|---|---|
| `webpage-a1b2c3d4e5f6` | webpage | Drake et al. (PubMed) | 1 | captured | 1,842 | [page.md](fixtures/webpage/webpage-a1b2c3d4e5f6/page.md) · [raw.html](fixtures/webpage/webpage-a1b2c3d4e5f6/raw.html) |
| `searchset-0f1e2d3c4b5a` | searchset | "caffeine sleep quality" | — | captured | 3,310 | [results.json](fixtures/searchset/searchset-0f1e2d3c4b5a/results.json) |

### interventions

| id | kind | title | tier | status | bytes | link |
|---|---|---|---|---|---|---|
| `webpage-9d8c7b6a5f4e` | webpage | "Why caffeine ruins your sleep" | 3 | pointer-only | — | (URL only) |

## 6. Controversies & contradictions

- Popular sources assert a universal "6-hour rule"; the trial evidence shows
  substantial inter-individual variation. Not resolved.

## 7. Knowledge gaps

- No Tier-1 source on long-term habituation of the sleep effect.
- Genetics of caffeine metabolism (CYP1A2) not investigated.
- No source on interactions with other sleep-affecting substances.

## 8. Actions

1. **(high)** Retrieve a Tier-1 systematic review to replace the Tier-3 blog.
2. **(medium)** Add a *metabolism* thread (CYP1A2, half-life variation).
3. **(low)** Verify the 6-hour claim against a second independent trial.

## 9. Method & provenance

- **Tools:** `ketch` 0.16.2 (MCP), capture rung `ketch scrape --raw --json` and `ketch search --json`.
- **Capture:** fixtures written at fetch time; `registry.json` atomic-written each cycle.
- **Cycle index:** see [Appendix B](#appendix-b--cycle-audit).

---

## Appendix A — Rejected sources

| Source | Reason |
|---|---|
| `example-seo.invalid/caffeine-secrets` | No identifiable author; data-less marketing. |

## Appendix B — Cycle audit

| Cycle | Thread | New findings | Saturation | Coverage after |
|---|---|---|---|---|
| 1 | sleep-architecture | 6 | — | 80% |
| 2 | interventions | 1 | 14% | 45% |
