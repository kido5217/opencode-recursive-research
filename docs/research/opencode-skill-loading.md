# opencode v1/v2 skill loading + non-interactive verification

Research ticket: [#3](https://github.com/kido5217/opencode-recursive-research/issues/3) (part of [#2](https://github.com/kido5217/opencode-recursive-research/issues/2)).

Scope: confirm, for opencode **1.18.30** (`opencode`) and **2.0.2** (`opencode2`), where skills are discovered, how to prove discovery non-interactively, the v2 config/frontmatter/tooling gotchas, and whether `npx skills` works against this repo's `skills/` layout.

## Environment

| | v1 | v2 |
|---|---|---|
| binary | `opencode` | `opencode2` |
| `--version` | `1.18.30+3104c14` | `opencode v2.0.2` |
| nix store | `/nix/store/j2b8b3gis1d7bsqa8hl7qq4zgzh9j7x0-opencode-1.18.30+3104c14` | `/nix/store/mszp3y3i0nma4wlmp8020yvzbbdscdcs-opencode2-2.0.2` |
| source commit | `3104c1428ec91f809e5ab86631300de41eb6952e` (`release: v1.18.30`) | tag `v2.0.2` → `ea5ae2329569e4fbf063be451480b58e29de6816` |
| source repo | `anomalyco/opencode` (the `sst/opencode` name redirects here; default branch `dev`) | same |
| docs | https://opencode.ai/docs/skills | https://opencode.ai/v2/docs/skills |

Host: `node v26.8.2`, `npx 11.19.1`.

Every claim below is either **(a)** observed by running the binary on this host, or **(b)** read from the tagged source/docs, or explicitly marked **unverified**.

---

## Q1. Compat-path discovery — `.agents/skills/<name>/SKILL.md` and `~/.config/opencode/skills/<name>/SKILL.md`

**Answer: yes for both versions, on both the project and global compat paths.** Verified empirically and in source.

### v1 (1.18.30)

Source: [`packages/opencode/src/skill/index.ts`](https://github.com/anomalyco/opencode/blob/3104c1428ec91f809e5ab86631300de41eb6952e/packages/opencode/src/skill/index.ts) — `discoverSkills()`.

```ts
const CLAUDE_EXTERNAL_DIR = ".claude"
const AGENTS_EXTERNAL_DIR = ".agents"
const EXTERNAL_SKILL_PATTERN = "skills/**/SKILL.md"
const OPENCODE_SKILL_PATTERN = "{skill,skills}/**/SKILL.md"
...
// global external dirs
const root = path.join(global.home, dir)          // ~/.claude, ~/.agents
yield* scan(state, root, EXTERNAL_SKILL_PATTERN, { dot: true, scope: "global" })
// project external dirs, walking cwd up to the git worktree
const upDirs = yield* fsys.up({ targets: externalDirs, start: directory, stop: worktree })
// global/project opencode config dirs
const configDirs = yield* config.directories()    // includes ~/.config/opencode
yield* scan(state, dir, OPENCODE_SKILL_PATTERN)
// explicit config
for (const item of cfg.skills?.paths ?? []) { ... }
for (const url of cfg.skills?.urls ?? []) { ... }
```

So v1 roots are:
- global `~/.agents/skills/**/SKILL.md`, `~/.claude/skills/**/SKILL.md`
- project `.agents/skills/**/SKILL.md`, `.claude/skills/**/SKILL.md` at every level from cwd up to the git worktree
- `~/.config/opencode/{skill,skills}/**/SKILL.md` (via `config.directories()` + `OPENCODE_SKILL_PATTERN`)
- plus `skills.paths` / `skills.urls` config

Empirical (v1):

```console
$ mkdir -p /tmp/opencode/v1proj/.agents/skills/zz-v1-agents
$ mkdir -p /tmp/opencode/v1proj/.opencode/skills/zz-v1-opencode
$ mkdir -p /tmp/opencode/v1proj/.claude/skills/zz-v1-claude
# each with valid frontmatter
$ cd /tmp/opencode/v1proj && opencode debug skill
# entries: 43
# zz-v1-claude    <= /tmp/opencode/v1proj/.claude/skills/zz-v1-claude/SKILL.md
# zz-v1-agents    <= /tmp/opencode/v1proj/.agents/skills/zz-v1-agents/SKILL.md
# zz-v1-opencode  <= /tmp/opencode/v1proj/.opencode/skills/zz-v1-opencode/SKILL.md
```

```console
# temp HOME with ~/.config/opencode/skills, ~/.agents/skills, ~/.claude/skills
$ HOME=/tmp/opencode/tmphome opencode debug skill
# entries: 4
# zz-v1-claudeglobal  <= /tmp/opencode/tmphome/.claude/skills/zz-v1-claudeglobal/SKILL.md
# zz-v1-agentsglobal  <= /tmp/opencode/tmphome/.agents/skills/zz-v1-agentsglobal/SKILL.md
# zz-v1-cfgglobal     <= /tmp/opencode/tmphome/.config/opencode/skills/zz-v1-cfgglobal/SKILL.md
```

Also observed with the real HOME: `opencode debug skill` reported 40 entries, 39 of them under `/home/kido/.agents/skills` plus 1 `<built-in>` (`customize-opencode`).

### v2 (2.0.2)

Source: [`packages/core/src/config/plugin/skill.ts`](https://github.com/anomalyco/opencode/blob/ea5ae2329569e4fbf063be451480b58e29de6816/packages/core/src/config/plugin/skill.ts) (`opencode.config.skill` transform).

```ts
const claude = loaded.entries.flatMap((entry) => (entry.type === "claude" ? [entry.path] : []))
const agents = loaded.entries.flatMap((entry) => (entry.type === "agents" ? [entry.path] : []))
const directories = loaded.entries.flatMap((entry) => (entry.type === "directory" ? [entry.path] : []))
const items = loaded.entries.flatMap((entry) => (entry.type === "document" ? (entry.info.skills ?? []) : []))
for (const directory of [...claude, ...agents]) {
  add(DirectorySource({ path: path.join(directory, "skills") }))
}
for (const directory of directories) {
  add(DirectorySource({ path: path.join(directory, "skill") }))
  add(DirectorySource({ path: path.join(directory, "skills") }))
}
// scan pattern per source:
fs.scan("{*.md,**/SKILL.md}", { cwd: directory, absolute: true, include: "file", symlink: true, dot: true })
```

`opencode2 debug config` shows the registered config sources on this host:

```
claude     => /home/kido/.claude
agents     => /home/kido/.agents
document   => /home/kido/.config/opencode/opencode.jsonc
directory  => /home/kido/.config/opencode
```

So v2 roots are:
- global `~/.agents/skills`, `~/.claude/skills` (the `agents`/`claude` entries)
- global `~/.config/opencode/{skill,skills}` (the `directory` entry for the config dir)
- project `.agents/skills`, `.claude/skills`, `.opencode/{skill,skills}` (project entries, searched from cwd up to the project root)
- plus the `skills` array in `opencode.json(c)`

v2 also accepts **flat markdown** at a source root (`<source>/review.md` → id `review`) and nested `SKILL.md` at any depth; v1's docs describe only `<name>/SKILL.md` directories (v1's glob is `skills/**/SKILL.md`).

Empirical (v2) — `opencode2 run` asks the model to echo its `<available_skills>` block, which proves advertisement:

```console
$ cd /tmp/opencode/v2proj && opencode2 run --standalone --model deepseek/deepseek-v4-flash \
    "Reply with EXACTLY the text between <available_skills> and </available_skills> in your system prompt, verbatim."
# 44 <id> entries; among them:
#   <id>zz-v2-agents</id>   <name>zz-v2-agents</name>   <description>test v2 agents path</description>
#   <id>zz-v2-claude</id>   ...
#   <id>zz-v2-opencode</id> ...
```

Global paths, temp skills temporarily placed in the real global dirs (since a temp HOME has no model credentials), then removed:

```console
$ cd /tmp/opencode/emptyproj && opencode2 run --standalone --model deepseek/deepseek-v4-flash "<echo available_skills>"
#   <id>zz-v2-agentsglobal</id>   <= from ~/.agents/skills
#   <id>zz-v2-cfgglobal</id>      <= from ~/.config/opencode/skills
#   <id>zz-v2-claudeglobal</id>   <= from ~/.claude/skills
```

v2 `run --print-logs --log-level debug` additionally logs the roots it registers/watches (deterministic, no model prompt needed once a run starts):

```
watcher subscribe path=/home/kido/.claude/skills type=directory
watcher subscribe path=/home/kido/.agents/skills type=directory
watcher subscribe path=/home/kido/.config/opencode/skills type=directory
watcher subscribe path=/tmp/opencode/v2proj/.claude/skills type=directory
watcher subscribe path=/tmp/opencode/v2proj/.agents/skills type=directory
watcher subscribe path=/tmp/opencode/v2proj/.opencode/skills type=directory
```

**Caveat for the port:** the `skills` CLI's OpenCode target on this host is `.agents/skills/<name>` (project) and `~/.agents/skills/<name>` (global) — see Q4. Both versions discover those. The ticket's stated global path `~/.config/opencode/skills/<name>` is also discovered by both versions, but the CLI did not write there in our test.

---

## Q2. Non-interactive verification

### v1 — `opencode debug skill` (deterministic, no model)

Source: [`packages/opencode/src/cli/cmd/debug/skill.ts`](https://github.com/anomalyco/opencode/blob/3104c1428ec91f809e5ab86631300de41eb6952e/packages/opencode/src/cli/cmd/debug/skill.ts)

```ts
export const SkillCommand = effectCmd({
  command: "skill",
  describe: "list all available skills",
  handler: ... const skills = yield* skill.all(); process.stdout.write(JSON.stringify(skills, null, 2) + EOL)
})
```

```console
$ opencode debug --help
Commands:
  ...
  opencode debug skill         list all available skills

$ opencode debug skill
[
  { "name": "customize-opencode", "description": "...", "location": "<built-in>", "content": "..." },
  { "name": "brainstorming", "description": "...", "location": "/home/kido/.agents/skills/brainstorming/SKILL.md", "content": "..." },
  ...
]
# 40 entries on this host (JSON array; fields: name, description, location, content)
```

This is the exact v1 proof: parse the JSON array and check for the skill `name`/`location`.

### v2 — no `debug skill`; use `run`

`opencode2 debug --help` exposes only `agents`, `config`, `paths`. There is no `skill` subcommand (and `opencode2 skill` / `opencode2 tools` print the generic CLI help). Verified:

```console
$ opencode2 debug --help
SUBCOMMANDS
  agents    List all agents
  config    List configuration sources
  paths     Show global paths (data, config, cache, state)
```

Two working v2 proofs:

1. **Direct advertisement** (model-dependent but exact):

```console
$ opencode2 run --standalone --model <provider/model> \
  "Reply with EXACTLY the text between <available_skills> and </available_skills> in your system prompt, verbatim. If there is no such block, reply NONE."
# → prints the <available_skills> block with <id>/<name>/<description> per skill
```

2. **Discovery-root logs** (deterministic; a run is still required to boot the location):

```console
$ opencode2 run --standalone --print-logs --log-level debug --model <provider/model> "hi" 2>&1 \
  | grep 'watcher subscribe.*skills'
# → path=<root>/skills lines for each discovered root
```

**v2 HTTP API — exists but unreliable in 2.0.2.** The v2 server defines an experimental route:

```
wt("skill.list","/api/skill",{query:e,success:sr(E(_v))}).annotateMerge(te({identifier:"v2.skill.list",summary:"List skills",description:"Retrieve currently registered skills."}))
```

```console
$ opencode2 api --standalone v2.skill.list
{"location":{...},"data":[]}
$ opencode2 api --standalone GET /api/skill
{"location":{...},"data":[]}
```

`data` was `[]` even from a project (and a global HOME) where `opencode2 run` advertised 44 skills, and even when the config plugin had clearly run (the debug log showed the skill watchers). Treat `v2.skill.list` as **not a reliable discovery proof in 2.0.2**; use `run`.

---

## Q3. v2 gotchas

### `skills` config key: v2 array vs v1 `skills.paths`/`skills.urls`

- **v1 docs/schema** define `skills` as an object `{ paths: string[], urls: string[] }` (`share/opencode/schema.json` in the nix store; https://opencode.ai/docs/skills does not document it but the schema does).
- **v2 docs** define `skills` as an **array** of paths/URLs: `"skills": ["./team-skills", "~/shared/opencode-skills", "/opt/company-skills", "https://example.com/opencode/skills/"]`.
- **Compatibility (empirical, both directions on 1.18.30 / 2.0.2):**
  - v1.18.30 accepts the v2 array and normalizes it. Fixture [`packages/opencode/test/config/fixtures/v2-compat/read/skills-input.jsonc`](https://github.com/anomalyco/opencode/blob/3104c1428ec91f809e5ab86631300de41eb6952e/packages/opencode/test/config/fixtures/v2-compat/read/skills-input.jsonc):
    ```jsonc
    { "skills": ["./skills", "https://example.com/skills", "/opt/skills", "http://localhost:8080/skills"] }
    ```
    normalizes to `{"paths":["./skills","/opt/skills"],"urls":["https://example.com/skills","http://localhost:8080/skills"]}`. Reproduced locally: a project with `{"skills":["./extraskills"]}` made `opencode debug skill` find a skill in `./extraskills`, and `opencode debug config` printed `"skills":{"paths":["./extraskills"],"urls":[]}`.
  - v2.0.2 accepts the v1 `{"skills":{"paths":["./extraskills"]}}` object: a v2 run found the skill placed there.

  So a single `"skills": ["./team-skills"]` array is read by **both** versions on this host. (Docs still describe the two shapes differently; the object form may be dropped in future v2 releases.)

### Frontmatter

| field | v1 1.18.30 | v2 2.0.2 |
|---|---|---|
| `name` | required (1–64 chars, `^[a-z0-9]+(-[a-z0-9]+)*$`, must equal the directory name) | optional; display label only, defaults to path-derived id |
| `description` | required (1–1024 chars) | optional; a skill without one is **not advertised** |
| `license`, `compatibility`, `metadata` | accepted; unknown fields ignored | accepted; `license`/`compatibility` parsed but not interpreted |
| `slash` | ignored | `false` hides the skill from interactive command catalogs |
| `metadata.opencode/slash` | ignored | boolean or `"true"`/`"false"`; overrides `slash` |
| `metadata.opencode/autoinvoke` | ignored | `false` omits the skill from the model's available list (still loadable by id) |

v2 parse source: [`packages/core/src/config/plugin/skill-file.ts`](https://github.com/anomalyco/opencode/blob/ea5ae2329569e4fbf063be451480b58e29de6816/packages/core/src/config/plugin/skill-file.ts).

Empirical:
- v1 ignores `metadata.opencode/autoinvoke: false`: the skill still appears in `opencode debug skill`.
- v2 hides it: a project with `zz-v2-noinvoke` (`opencode/autoinvoke: false`) and `zz-v2-normal` advertised only `zz-v2-normal` in `<available_skills>`.

The v1 skill tool takes `skill({ name: "..." })`; the v2 tool takes `skill({ id: "..." })` (v1 docs vs v2 docs, and the v2 available-list uses `<id>`).

### Path-derived skill id (v2)

v2 `parse()`:

```ts
const id =
  path.dirname(filepath) === directory && path.basename(filepath) !== "SKILL.md"
    ? path.basename(filepath, ".md")   // flat file at a source root
    : path.basename(path.dirname(filepath))  // <name>/SKILL.md
```

| file | id |
|---|---|
| `<source>/git-release.md` | `git-release` |
| `<source>/git-release/SKILL.md` | `git-release` |
| `<source>/teams/release/SKILL.md` | `release` |

Empirical: `.opencode/skills/zz-v2-iddir/SKILL.md` with frontmatter `name: Totally Different Name` advertised as `<id>zz-v2-iddir</id>` / `<name>Totally Different Name</name>`. Docs also note a root-level `SKILL.md` currently gets the literal id `SKILL`. v2 does not enforce the v1 name/directory-match rule or length limits.

### Code Mode tool grouping: `tools.<server>.<tool>`

**Confirmed: in v2 the model sees MCP tools as `tools.<server>.<tool>` (dotted), not `<server>_<tool>`.**

Empirical — `opencode2 run` asked to list its tools printed, among others:

```
tools.ketch.search
tools.ketch.code
tools.ketch.crawl
tools.ketch.docs
tools.ketch.scrape
tools.forgejo.add_issue_labels
tools.github.create_pull_request
tools.playwright.browser_click
tools.nixos.nix
tools["sequential-thinking"].sequentialthinking
```

v1 (this session) exposes the same server's tools as flat `ketch_search`, `forgejo_add_issue_labels`, etc.

The v2 Code Mode model is documented at https://opencode.ai/v2/docs/tools: `execute` runs JavaScript "so the agent can call and combine tools from the catalog"; inside `execute` the callable names come from the Code Mode catalog. v2 plugin docs describe namespacing (`editor.namespace({name:"acme"})`, `options:{codemode:true}`) and state tool effective names use `_` (e.g. `acme_greeting`), while MCP **permission** actions are `<server>_<tool>` with resource `*`.

Implications for porting `recursive-research`:
- Skill instructions that name `ketch_search` / `ketch_code` (the v1 names) are wrong for v2, where the catalog names are `tools.ketch.search` / `tools.ketch.code`. Inside an `execute` block the callable form is the Code Mode catalog's name; the CLI/binary strings show the catalog rendered as `tools.<namespace>.<tool>`.
- Permission rules for MCP tools remain `<server>_<tool>` in both (v2 docs: "Their permission action is `<server>_<tool>` with resource `*`").
- Prefer writing skills to describe the capability ("search the web", "grep public repos") rather than hard-coding a tool symbol, or branch on version.

---

## Q4. `npx skills` against `skills/recursive-research/SKILL.md`

**Confirmed.** `node v26.8.2` / `npx 11.19.1`, `skills` CLI from `vercel-labs/skills` (run via `npx`).

Throwaway repo `/tmp/opencode/skillrepo` with `skills/recursive-research/SKILL.md`:

```console
$ npx --yes skills add ./ --list

┌   skills
│
◇  Source: /tmp/opencode/skillrepo
◇  Local path validated
◇  Found 1 skill
│
◇  Available Skills
│    recursive-research
│      Test skill for npx skills discovery
└  Use --skill <name> to install specific skills
# exit 0
```

Note: `--list` cannot be combined with `--json` (`The --json flag cannot be combined with --list.`); use the plain output or `--skill '*'` with `--yes`.

Install target for OpenCode (project), confirmed:

```console
$ npx --yes skills add ./ --skill recursive-research --agent opencode --copy --yes
◇  Installation Summary
│  ./.agents/skills/recursive-research
│    copy → OpenCode
◇  Installed 1 skill
# resulting tree:
# /tmp/opencode/skillrepo/.agents/skills/recursive-research/SKILL.md
# /tmp/opencode/skillrepo/skills-lock.json
```

Global install (`--global`, temp HOME to avoid touching real config) writes to `~/.agents/skills/recursive-research/SKILL.md`, **not** `~/.config/opencode/skills/`. Both versions discover `~/.agents/skills`, so the port works either way.

---

## Unverified / caveats

- **v2 `v2.skill.list` API**: present in the 2.0.2 binary but returned `data: []` in every non-interactive invocation tried (project with skills, real global HOME with 40 skills, config plugin demonstrably loaded). Root cause not established; marked unreliable rather than proven broken.
- **v2 `slash: false`**: behavior is documented but not exercised (only `autoinvoke: false` was tested). Interactive command catalog not inspected non-interactively.
- **v1 `skills[]` array acceptance**: observed and backed by a test fixture in the v1.18.30 tree, but not documented in the v1 skills doc; behavior in other v1 patch releases is unverified.
- **v2 warm `serve` + `/api/skill`**: a quick attempt to start `opencode2 serve` and curl `/api/skill` did not respond (the `serve` subcommand rejects `--standalone`; server-log plumbing for `serve` was not resolved). Not pursued; the `run`-based proofs above are sufficient.
- **`npx skills` version**: `npx skills` resolves to the latest published `skills` package at run time; the exact package version was not pinned.

## Command appendix

```console
# v1 discovery
opencode debug skill
opencode debug config
# v2 discovery / verification
opencode2 debug config
opencode2 run --standalone --print-logs --log-level debug --model <m> "hi" 2>&1 | grep 'watcher subscribe.*skills'
opencode2 run --standalone --model <m> "Reply with EXACTLY the text between <available_skills> and </available_skills> in your system prompt, verbatim."
opencode2 api --standalone v2.skill.list          # returns [] in 2.0.2
# npx skills
npx --yes skills add ./ --list
npx --yes skills add ./ --skill <name> --agent opencode --copy --yes
```
