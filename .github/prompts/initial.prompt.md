## PROMPT 1 OF 3 — ARCHITECTURE DISCOVERY

```
You are a software architect auditing a codebase you've never seen before. You have filesystem access.

GOAL
Produce ARCHITECTURE.md (to be saved as `architecture.instructions.md`) — a dense structural reference capturing the project's topology, stack, and key files.

EXECUTION STEPS

Step 1: Root Scan
List the root directory. Read: the main entry point, any build/config files (package.json, Makefile, Cargo.toml, etc.), README, and any docs/ folder.

Extract:
  PROJECT_ID:
    name: ...
    type: (CLI | web app | library | API | script collection | monorepo | etc.)
    language: ...
    framework: (if any)
    build_tool: (if any)
    dependencies: (list all with one-line purpose)

Step 2: Full Tree
List every directory to leaf level. Produce a FILE MAP:
  directory/ → [files, sub-directories]
For small projects (<50 files), list every file. For larger ones, summarize repetitive groups.

Step 3: Layer Classification
Assign each file or directory a role label. Use whatever fits:
  ENTRY_POINT | CONFIG | CORE_LOGIC | COMMAND | UTILITY | DATA | TEMPLATE | TEST | DOCS | CI_CD | RESOURCE | SCRIPT
Create new labels if needed. Keep it simple.

Step 4: Pattern Sampling
For each role, read the 1-2 most important files. Record a PATTERN TABLE:
  | Role | Pattern | File:Line | Rule |
Don't read everything — read what defines the contract for that role, then extrapolate.

Step 5: Cross-Cutting Concerns
Record anything that spans multiple files:
  | Concern | Mechanism | Key File(s) |
Examples: error handling, config loading, logging, CLI argument parsing, shared utilities.

Step 6: File Priority List
For each role:
  MUST-READ: Files that define the pattern (base class, entry point, canonical example)
  NICE-TO-READ: Supporting files that show secondary patterns
  SKIP: Files that follow an already-documented pattern

OUTPUT FORMAT
Produce ARCHITECTURE.md (saved as `architecture.instructions.md`) with:
1. PROJECT IDENTITY
2. DEPENDENCY LIST
3. FILE MAP
4. ROLE CLASSIFICATION TABLE
5. PATTERN TABLE
6. CROSS-CUTTING CONCERNS TABLE
7. PRIORITIZED FILE LIST PER ROLE

RULES
- Tables over paragraphs. Always.
- File paths are your primary output — point, don't copy.
- If 10 files follow the same pattern, say so and point to one example. Don't list all 10.
- List every directory. File reads can be selective.
- Target: ~1,500-3,000 tokens. Keep it dense.

BEGIN. List the root directory now.
```

---

## PROMPT 2 OF 3 — DEVELOPER GUIDE

```
You are producing the coding standards document for a codebase. You have filesystem access and the architecture.instructions.md from Prompt 1 (provided below or attached).

GOAL
Produce DEVELOPER_GUIDE.md (to be saved as `developer-guide.instructions.md`) — a rulebook an AI agent (or new contributor) uses to write code that fits this project perfectly.

DESIGN PRINCIPLES
1. Rules, not descriptions. ("All scripts MUST start with a header block" not "The project uses header blocks")
2. Templates, not explanations. Show the skeleton for each type of file.
3. Tables, not prose. For anything with 3+ items.
4. Pointer-based examples. Reference file:line instead of copying code.

EXECUTION STEPS

Step 1: Read architecture.instructions.md. Identify all roles and their MUST-READ files.

Step 2: Read every MUST-READ file. For each, extract:
  - Naming convention
  - File structure / sections
  - Error handling pattern
  - Input/output conventions
  - Any repeated boilerplate

Step 3: Read 1-2 NICE-TO-READ files per role only where MUST-READ left ambiguity.

Step 4: Generate developer-guide.instructions.md using the structure below.

OUTPUT STRUCTURE

# developer-guide.instructions.md

## Quick Reference Card
| I need to create a... | Base/Pattern | Location | Name Pattern |
(One row per type of file in the project)

## 1. Project Structure Rules
(Where each type of file lives. What goes where.)

## 2. File Template per Type
(For each file type: the exact skeleton to start from. Use TEMPLATE blocks.)

## 3. Naming Rules
(Files, functions/methods, variables, constants — as a table.)

## 4. Error Handling Rules
(Input validation, exit codes, error messages — with template.)

## 5. Output & Logging Rules
(Message format, prefixes, separators.)

## 6. Dependencies & Imports
(What's allowed, what's not, preferred libraries.)

## 7. Adding a New Command/Feature — Checklist
(Step-by-step: CREATE file → ADD wiring/registration → TEST.)

## 8. Things to Never Do
(Hard rules: no X, never Y. Keep to 5-10 items.)

RULES
- Target 2,000-5,000 tokens.
- Every rule must cite at least one file path as evidence.
- The Quick Reference Card is the most important section.
- Templates > descriptions. Show the skeleton.
- Skip anything obvious about the language itself. Document THIS PROJECT's conventions.

BEGIN. Read the architecture.instructions.md, then start reading MUST-READ files.

[PASTE architecture.instructions.md HERE]
```

---

## PROMPT 3 OF 3 — FRAMEWORK KNOWLEDGE

```
You are producing the operational knowledge base for a codebase. You have filesystem access and the architecture.instructions.md from Prompt 1 (provided below or attached).

GOAL
Produce FRAMEWORK.md (to be saved as `framework.instructions.md`) — a document giving an AI agent (or new contributor) 100% of the knowledge needed to:
- Understand what every component does
- Trace any execution flow end-to-end
- Add any new component by following a precise recipe
- Never be stuck asking "where does this go?"

DESIGN PRINCIPLES
1. Recipes over explanations. Every "how to add X" is: CREATE (what) → WIRE (what existing files to touch) → MODEL (which file to copy from).
2. Flow diagrams over prose. Show execution order with arrows and file:line pointers.
3. Decision trees over lists. For "which X should I use?" questions.
4. Pointer-based cross-references. Point to file:line, don't copy code.

EXECUTION STEPS

Step 1: Read architecture.instructions.md. Identify all roles.

Step 2: Targeted reads only:
  - For execution flow: Read the entry point top-to-bottom, trace into 1-2 sub-components.
  - For "how to add X": Read one canonical example + the wiring/registration point.
  - For data flow: Trace one complete flow from input to output.
  Stop reading once you can answer the question.

Step 3: Generate framework.instructions.md using the structure below.

OUTPUT STRUCTURE

# framework.instructions.md

## System Overview
(3-5 sentences. What this project does, what tech it uses.)

## How It Works — Execution Flow
(Show the flow from entry point through routing/dispatch to sub-components. Use arrow diagrams with file:line pointers.)

## How To Add Anything — Recipes

### Recipe: [Each type of component in the project]
Each recipe has:
  CREATE: what file to make, where, what pattern to follow
  WIRE: what existing file(s) to modify (with approximate location)
  MODEL: which existing file to use as a template
  VERIFY: how to confirm it works

(Include one recipe per component type discovered in architecture.instructions.md)

## Component Reference
(For each major component/module: what it does, key entry points, how it connects to others. Use tables and file pointers.)

## Configuration Reference
(How config works, where values come from, how to add new config. Table format.)

## Key Files Quick Lookup
| When you need to... | Read this file |
(15-20 rows covering the most common tasks)

RULES
- Target 3,000-8,000 tokens.
- RECIPES are the most important section — 80% of agent usage.
- Every recipe must have CREATE, WIRE, MODEL, VERIFY.
- Use decision trees for "which X?" questions.
- Use flow diagrams for execution paths.
- Use tables for reference data.
- Don't explain what the language or framework is. Document THIS PROJECT's usage.

BEGIN. Read the architecture.instructions.md, then start targeted file reads.

[PASTE architecture.instructions.md HERE]
```

---

**Key changes from the enterprise originals:**

| Aspect | Enterprise Version | Personal Version |
|---|---|---|
| Token targets | 3k-5k / 4k-8k / 6k-12k | 1.5k-3k / 2k-5k / 3k-8k |
| Layer taxonomy | 25+ rigid labels (BOOTSTRAP, DI_WIRING, etc.) | ~12 flexible labels, "create new if needed" |
| Assumes | Spring, TestNG, DI, Lombok, Selenium | Nothing — discovers stack from files |
| Output sections | Java/enterprise-specific (annotations, Lombok, screens) | Generic (file templates, naming, error handling) |
| Recipes | Feature-specific (new Screen, new Macro, new DTO) | "One recipe per component type discovered" |
| Priority markers | 🔴🟡🟢 with strict rules | MUST-READ / NICE-TO-READ / SKIP |
| Complexity | Handles 500+ file monorepos | Works for 5-file scripts to medium repos |

These prompts will work on any personal project regardless of language or framework — they discover the structure rather than assuming it.