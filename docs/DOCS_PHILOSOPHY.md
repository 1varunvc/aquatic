# Documentation Philosophy

This document explains how documentation is organized in aquatic-cli and who should read what.

## Three Audiences, Three Sets of Docs

### 1. **Users** — Want to install and use the toolkit
- **README.md** — Installation, commands table, examples
- **SECURITY.md** — Vulnerability reporting, safety guarantees
- **CHANGELOG.md** — What's new in each version

**Characteristics:** Quick answers, task-focused, no jargon.

### 2. **Contributors** — Want to add features or fix bugs
- **CONTRIBUTING.md** — Getting started, development workflow, code style, common pitfalls
- **README.md** — Command reference (to understand what exists)

**Characteristics:** Practical, step-by-step, tells you how to do things. No reference tables. Shows copy-paste examples.

### 3. **AI/LLMs** — Need dense reference info to write code correctly
- **docs/agent/ARCHITECTURE.md** — File map, component roles, patterns, decision trees
- **docs/agent/FRAMEWORK.md** — Execution flow, recipes for adding anything, configuration
- **docs/agent/DEVELOPER_GUIDE.md** — Templates, naming rules, error handling (tabular format)
- **.github/copilot-instructions.md** — Project specification, AI coding guidelines, and standards

**Characteristics:** Dense, tabular, reference-oriented, pointer-based. No prose explanations. Maximum signal-to-noise.

### 4. **GitHub/Release** — Technical governance
- **LICENSE** — Legal terms (AGPL-3.0)
- **.github/workflows/** — CI/CD
- **.editorconfig** — Formatting standards

---

## Where Each Type Goes

| Document | Location | Audience | Format |
|----------|----------|----------|--------|
| User guide | `README.md` | Users | Prose + tables |
| Security policy | `SECURITY.md` | Users/Maintainers | Prose |
| Changelog | `CHANGELOG.md` | Users | List format |
| Contribution guide | `CONTRIBUTING.md` | Contributors | Prose + examples |
| Architecture spec | `docs/agent/ARCHITECTURE.md` | LLMs | Tables + pointers |
| Framework recipes | `docs/agent/FRAMEWORK.md` | LLMs | Recipe format |
| Dev templates | `docs/agent/DEVELOPER_GUIDE.md` | LLMs | Templates + tables |
| Project spec + AI coding rules | `.github/copilot-instructions.md` | LLMs | Prose + rules |

---

## What NOT to Put Where

- **Don't put dense reference tables in CONTRIBUTING.md** — Those go in DEVELOPER_GUIDE.md for LLMs.
- **Don't put step-by-step tutorials in ARCHITECTURE.md** — That goes in FRAMEWORK.md under "Recipes".
- **Don't duplicate rules between files** — One source of truth per rule set.
- **Don't write for both humans and LLMs in the same document** — Create separate versions.

---

## Example: Adding a New Bash Command

A human contributor reads:
1. **CONTRIBUTING.md** § "Making Your Changes" → Copy a template, run tests
2. **README.md** § Commands table → Understand where to add documentation

An LLM writing the implementation reads:
1. **.github/copilot-instructions.md** § "Mandatory File Header" → Exact format
2. **docs/agent/DEVELOPER_GUIDE.md** § "TEMPLATE: Bash Command" → Skeleton
3. **docs/agent/FRAMEWORK.md** § "Recipe: New Bash Command" → Wiring steps
4. **.github/copilot-instructions.md** — Overall rules, patterns, and guardrails

---

## Maintenance

When updating docs:
1. Identify your audience (user / contributor / LLM)
2. Use the right document for that audience
3. If info is useful to multiple audiences, **create separate versions** — don't compromise readability
4. Update the plan if you change the structure


