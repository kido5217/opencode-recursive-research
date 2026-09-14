# recursive-research (opencode port)

A port of the Claude Code skill `Anjos2/recursive-research` to opencode. The vocabulary below is the canonical English used by the ported `SKILL.md` and its generated artifacts; the upstream Spanish term is given for traceability.

## Language

### Research structure

**Research seed**:
The root topic a run investigates.
(ES: *semilla de investigación*)
_Avoid_: topic, subject, query

**Thread**:
One distinct angle of the seed that a run pursues.
(ES: *hilo*)
_Avoid_: branch, strand, subtopic

**Seed thread**:
A top-level thread chosen during planning (three to five per run).
(ES: *hilo semilla*)
_Avoid_: main thread, root thread

**Sub-thread**:
A narrower thread that hangs off another thread.
(ES: *sub-hilo*)
_Avoid_: child thread, branch

**Thread map**:
The tree of a run's threads and sub-threads.
(ES: *mapa de hilos* / *árbol de hilos*)
_Avoid_: outline

### Sources and trust

**Source**:
A reference consulted during a cycle.
(ES: *fuente*)

**Source tiering**:
Assigning every consulted source a trust tier.
(ES: *tiering de fuentes*)
_Avoid_: rating, ranking

**Tier 1 / Tier 2 / Tier 3**:
The trust bands a source is assigned: highest confidence, high confidence, useful-with-caution.
(ES: *Tier 1 / Tier 2 / Tier 3*)
_Avoid_: level 1/2/3

**Rejected source**:
A source excluded by the rejection criteria (no identifiable author, data-less marketing, SEO spam, unsourced tutorials, unsupervised AI content).
(ES: *fuente rechazada*)
_Avoid_: blacklisted source, banned source

**Coverage**:
The share of a thread's expected findings that have been recorded.
(ES: *cobertura*)
_Avoid_: completeness

**Saturation**:
The ratio of a cycle's new findings to all findings accumulated so far.
(ES: *saturación*)
_Avoid_: decay, plateau

### Decisions

**WDM (Weighted Decision Matrix)**:
A decision method that scores alternatives against weighted criteria.
(ES: *WDM / Matriz de Decisión Ponderada*)
_Avoid_: scoring matrix, decision table

**Munger inversion**:
Inverting a decision to ask how it would fail, what it ignores, and what it omits.
(ES: *inversión Munger*)
_Avoid_: devil's advocate, red team

### Cycles and closure

**Cycle**:
One iteration of the research loop.
(ES: *ciclo*)
_Avoid_: round, pass, iteration

**Cycle cap**:
The hard maximum number of cycles for a run.
(ES: *tope de ciclos*)
_Avoid_: limit, budget

**Checkpoint**:
The per-cycle record written to disk so a run survives context compaction or session end.
(ES: *checkpoint*)
_Avoid_: save, snapshot

**Fitness function**:
The five PhD-level criteria that must all hold before a run closes naturally.
(ES: *función de fitness*)
_Avoid_: score, rubric

**Closure**:
Ending a run — naturally (criteria met), forcibly (cycle cap reached), or partially (preventive pause).
(ES: *cierre*)
_Avoid_: finish, termination

**Preventive pause**:
Stopping a run before the context limit is reached, so a checkpoint lands first.
(ES: *pausa preventiva*)
_Avoid_: timeout, abort

### Generated artifacts

**State**:
The file tracking a run's metadata, progress, and metrics.
(ES: *estado*)

**Findings**:
The consolidated discoveries of a run.
(ES: *hallazgos*)
_Avoid_: results, notes

**Gap**:
A documented unknown, unresolved contradiction, or bias in a run's sources.
(ES: *gap*)
_Avoid_: hole, TODO

**Synthesis**:
The executive summary produced at closure.
(ES: *síntesis*)
_Avoid_: report, summary

**Actions**:
The prioritized, actionable checklist produced at closure.
(ES: *acciones*)
_Avoid_: todos, next steps

### Fixtures and the report

**Fixture**:
A verbatim capture of one source's content, persisted to disk under a run's `fixtures/` folder and indexed in the fixture registry.
_Avoid_: snapshot, capture, artifact, source file

**Fixture kind**:
The source class a fixture belongs to: `webpage`, `searchset`, `document`, `media`, `git`, or `other`.
_Avoid_: type, category

**Representation**:
One file within a fixture — its role, path, media type, byte size, and content hash.
_Avoid_: file, asset, variant

**Fixture registry**:
The machine-readable index of a run's fixtures, `fixtures/registry.json`, validated by `fixtures/registry.schema.json`.
_Avoid_: index, manifest, catalog

**Report**:
The single consolidated Markdown file produced at closure that holds all of a run's research, referencing fixtures rather than embedding them.
_Avoid_: final report, output, summary
