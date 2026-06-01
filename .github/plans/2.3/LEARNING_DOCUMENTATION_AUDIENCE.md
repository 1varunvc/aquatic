# Key Learning: Documentation Audience Separation

## The Problem You Identified

You asked CONTRIBUTING.md to be "actually useful to humans." The merged version (from developer-guide.instructions.md and project_rules.md) was dense, tabular, and reference-oriented — **good for LLMs, terrible for humans.**

## The Solution

**Separate documentation by audience. Never merge them.**

### For Humans (CONTRIBUTING.md)
- Step-by-step workflow (fork → clone → install → run → test → commit → PR)
- Practical code examples (not templates)
- Common pitfalls and how to avoid them
- Friendly tone ("Thank you for contributing!")
- Task-oriented ("I want to add a new command" → here's how)

### For LLMs (.github/instructions/)
- Dense reference tables
- Templates and boilerplate
- Naming conventions as tables, not prose
- Patterns and recipes using arrows/diagrams
- Pointer-based ("see file:line")

## Why This Matters

**Humans get lost in dense reference material.** They need:
- "Do this, then this, then this" (sequential)
- "Here's an example" (concrete)
- "People often forget X" (anticipatory)

**LLMs are great at extracting signal from noise.** They can parse:
- Tables and lists (structured)
- Pointers and cross-references (scalable)
- Templates and patterns (generalizable)

Mixing these makes both audiences unhappy.

## The Architecture

```
CONTRIBUTING.md (Humans)
├─ Quick Start (4 steps)
├─ What We Accept (list)
├─ Development Workflow (6 steps)
├─ Code Style with Examples (not tables)
├─ Common Pitfalls (stories, not rules)
├─ Testing Checklist (to-do items)
└─ FAQ with Links (pointers to detailed docs)

.github/instructions/developer-guide.instructions.md (LLMs)
├─ Quick Reference Card (table)
├─ Templates (boilerplate)
├─ Naming Rules (table)
├─ Error Handling Rules (table)
└─ Things to Never Do (checklist)

project_rules.md (LLMs)
├─ Architecture & Naming (formal requirements)
├─ Header Standard (exact format)
└─ Error Handling & Validation (specification)

.github/copilot-instructions.md (LLMs)
├─ Project Overview
├─ Architecture (diagram-style)
└─ Rules (numbered, enforceable)
```

## Practical Test

**Human using CONTRIBUTING.md:**
- "I want to add a command. What do I do?"
- Reads "Make Your Changes" section
- "Copy from aquatic-mute.sh" — concrete instruction
- Follows "3. Test Your Changes" with exact bash commands
- ✅ Successful

**LLM using developer-guide.instructions.md:**
- "What's the template for a new Bash command?"
- Finds "TEMPLATE: Bash Command" section
- Sees full skeleton with header, validation, main logic
- ✅ Successful

---

## Key Principle

> **Never ask one document to be useful to two different audiences with different cognitive needs.**

If you catch yourself writing both:
- Narrative explanations (for humans)
- Dense reference tables (for LLMs)

...in the same document, split the document.

---

## Files in This Project

| Document | Audience | Don't Mix With |
|----------|----------|----------------|
| CONTRIBUTING.md | Humans | developer-guide.instructions.md |
| README.md | Users | framework.instructions.md |
| SECURITY.md | Maintainers | project_rules.md |
| .github/instructions/developer-guide.instructions.md | LLMs | CONTRIBUTING.md |
| .github/instructions/framework.instructions.md | LLMs | README.md |
| .github/instructions/architecture.instructions.md | LLMs | None (standalone) |
| project_rules.md | LLMs | SECURITY.md |
| .github/copilot-instructions.md | LLMs | CONTRIBUTING.md |

This structure respects cognitive differences. It works.

