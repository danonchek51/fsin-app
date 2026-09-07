<!-- bmad:context -->

# BMAD starter workspace

This repository uses BMAD as its planning and delivery system. Planning and implementation artifacts live in `_bmad-output/`; durable human-maintained domain knowledge belongs in `docs/`. BMAD skills are available in `.agents/skills/`.

## Workflow routing

- Inspect the request, relevant code or configuration, and existing `_bmad-output/` artifacts first; choose the smallest sufficient BMAD path without asking the user to select a skill.
- Use `bmad-help` only when the task and current artifacts do not establish a clear route.
- For a new product or material capability, use the BMad Method in order: product brief or PRFAQ, PRD, UX when the experience is material, architecture, epics and stories, sprint planning, then build.
- For a bounded change without accepted requirements or acceptance criteria, create or update a `bmad-spec` before implementation. Use an accepted spec or ready story as the basis for `bmad-build`.
- For a feature, bug, or meaningful change, follow Research → Plan → Implement → Verify: investigate only the unknowns that matter, make a concrete plan, implement, and run proportionate verification. Skip ceremony for obvious low-risk mechanical edits.
- Use `bmad-deep-recon` when an important decision needs current external evidence. Use Game Dev Studio only for game work, Test Architecture Enterprise only when test architecture is needed, and Builder only for creating or changing skills.
- Do not use `bmad-loop-*` or `bmad-build-auto` unless the user explicitly requests them.

## Source of truth and maintenance

- Treat accepted BMAD artifacts as the source of truth. Do not duplicate their requirements, specs, or plans under `docs/`.
- Keep `docs/` for long-lived domain knowledge, external constraints, and human-maintained references that are not BMAD planning artifacts.
- Do not hand-edit installer-managed `_bmad/config.toml`; put durable project-wide overrides in `_bmad/custom/`.
- Once application code, scripts, or CI exist, run `bmad-project-context` to refresh this file with verified commands, conventions, and observed pitfalls. Do not add guessed commands or a technology inventory.

<!-- /bmad:context -->
