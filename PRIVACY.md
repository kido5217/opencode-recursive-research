# Privacy Policy

**Skill:** recursive-research (opencode port)
**Upstream author:** Joseph Huayhualla ([@Anjos2](https://github.com/Anjos2))
**Last updated:** September 2026

## TL;DR

`recursive-research` does **not** collect, store, transmit, or share any user data. It runs entirely within your local opencode instance. The skill authors have no servers, no telemetry, and no visibility into anything you do with the skill.

---

## What the skill does

- Reads local files **you explicitly provide** when you select `local` or `mixed` mode
- Performs web searches using **ketch** (MCP or CLI) when available, and/or tools already configured in your agent
- Writes research checkpoints and artifacts to a local `memory/research/` folder inside your working project
- Operates entirely on your machine — no requests are sent to any server controlled by the skill authors

## What the skill does NOT do

- No telemetry, analytics, crash reports, or usage tracking
- No data sent to the skill authors or any third party controlled by them
- No account, login, API key, or authentication required by the skill itself
- No background processes, no persistent connections, no "call home"
- No automatic updates or version checks initiated by the skill

---

## Third-party tools

When you have **ketch** or other MCPs installed, or use your agent's built-in search/fetch tools, the skill invokes them on your behalf to carry out the research. Queries dispatched to those tools are subject to each tool's own privacy policy:

- **ketch** — see the ketch project's privacy policy
- **opencode built-in web search / fetch** — see the opencode documentation
- **Any other MCP you configure** — see its own terms

The skill does not modify, proxy, intercept, log, or retain those requests. It only requests them based on the search strategy derived from your research seed and the source-tiering scheme.

---

## Local data

All research outputs (`memory/research/<slug>/*.md`) live on your machine, inside your project directory. You are responsible for how you store, back up, share, or delete them. The skill authors have no access to them.

If you use the `local` or `mixed` mode and provide paths to sensitive documents, those documents remain on your machine — the skill reads them to inform the research but does not copy them anywhere off your disk.

---

## Your rights

Since the skill does not collect any personal data, there is nothing for the authors to access, delete, export, or modify on your behalf. You control every file.

If you want to remove the skill and all its outputs:

```
# Remove the installed skill (project scope)
rm -rf .agents/skills/recursive-research
# or via the skills CLI
npx skills remove recursive-research

# Remove research outputs (per project)
rm -rf <your-project>/memory/research
```

---

## Changes to this policy

Any changes to this policy will be committed to this file in the repository. You can inspect the full history with:

```
git log PRIVACY.md
```

---

## Contact

For privacy-related questions or concerns, open a GitHub issue on this repository.
