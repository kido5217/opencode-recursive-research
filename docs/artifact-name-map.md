# Artifact name map (ES → EN)

The port renames every generated artifact to English. Directory and filenames in the skill body and docs must use the right-hand column.

| Upstream (Spanish) | Port (English) |
| --- | --- |
| `memoria/` | `memory/` |
| `memoria/investigaciones/<slug>/` | `memory/research/<slug>/` |
| `estado.md` | `state.md` |
| `hilos.md` | `threads.md` |
| `hallazgos.md` | `findings.md` |
| `fuentes-tier-1.md` | `sources-tier-1.md` |
| `fuentes-tier-2.md` | `sources-tier-2.md` |
| `fuentes-tier-3.md` | `sources-tier-3.md` |
| `fuentes-rechazadas.md` | `sources-rejected.md` |
| `ciclo-01.md` … `ciclo-N.md` | `cycle-01.md` … `cycle-N.md` |
| `sintesis.md` | `synthesis.md` |
| `acciones.md` | `actions.md` |
| `gaps.md` | `gaps.md` |

`<slug>` is the kebab-case slug of the research seed (max 40 characters), unchanged from upstream.
