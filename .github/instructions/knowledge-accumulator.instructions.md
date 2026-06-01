[SCOPE]: <One sentence describing what this chat session covered — e.g., "Investigated why local reruns stopped pushing results to BSR after the async optimization commit.">

You have just completed a working session on this codebase. Before this conversation ends, capture ALL useful, accurate, and verified knowledge gathered during this chat into the project's markdown files.

---

## WHICH FILES TO UPDATE

This project maintains four markdown files. Each has a distinct purpose. Route information to the correct file — never duplicate across files.

| File | Purpose | What Goes Here | What Does NOT Go Here |
|---|---|---|---|
| `framework.instructions.md` | How the framework works — behavioral reference | Lifecycle flows, component behavior, external library internals (decompiled), API contracts, config system mechanics, non-obvious side effects, integration points between subsystems | Structural layout, code recipes, investigation narratives |
| `architecture.instructions.md` | What the codebase looks like — structural audit | Package hierarchy, dependency table, layer classification, pattern table with file:line references, prioritized file lists per layer | Behavioral details, how-to recipes, bug investigations |
| `developer-guide.instructions.md` | How to write code in this framework — developer guide | Recipes, templates, naming rules, annotation reference, test writing rules, import/formatting conventions, class design rules | Runtime behavior, debugging findings, structural audits |
| `INVESTIGATION_LOG.md` | What was discovered through debugging — accumulated investigation knowledge | Bug root causes, verified behavioral findings, diagnostic techniques, files explored with non-obvious details, dead code identified, commands run and what they proved | General framework docs, code recipes, structural layout |

**Decision tree:**
- "How does X work at runtime?" → `framework.instructions.md`
- "Where is X in the codebase?" → `architecture.instructions.md`
- "How do I create/add X?" → `developer-guide.instructions.md`
- "What did we learn by investigating X?" → `INVESTIGATION_LOG.md`

If a finding is BOTH a general framework fact AND an investigation result, put the reusable fact in `framework.instructions.md` and the investigation-specific narrative (symptom → root cause → fix) in `INVESTIGATION_LOG.md`. Cross-reference, don't duplicate.

---

## WHAT TO CAPTURE

### From every session, extract and document:

1. **Verified facts** — Statements confirmed by reading source code, decompiling jars, or running tests. NOT assumptions or theories that were disproven.
    - Bean scopes and their runtime implications
    - Lifecycle ordering (confirmed by decompilation or testing)
    - API contracts (request/response shapes, required fields, error codes)
    - Side effects of method calls (e.g., a setter that also writes to TestNG attributes)
    - Classloader behavior, threading behavior, singleton patterns
    - External library internals that required decompilation to understand

2. **Bug investigations** — For each bug found and fixed:
    - Exact symptom observed (error message, missing data, wrong behavior)
    - Root cause — technically precise, traceable to specific code paths
    - The exact code change or commit that introduced the bug (if identified)
    - The fix applied and WHY it works (not just what was changed)
    - How it was verified (which test, what output confirmed the fix)

3. **Files explored** — Every source file read, decompiled, or analyzed that revealed something non-obvious:
    - Full path and line count
    - What it does (1-2 sentences)
    - Key details discovered (hidden behavior, gotchas, non-obvious coupling)
    - Only include files where you learned something not obvious from the filename alone

4. **External library internals** — Anything discovered by decompiling jars:
    - Which class from which library
    - What was discovered (method signatures, attribute key constants, internal flow)
    - Why it matters for this project

5. **Commands run and diagnostic conclusions** — Key terminal commands that proved something:
    - The command (or its essence — not verbose flags)
    - What the output conclusively proved
    - Only include commands whose output changed your understanding

6. **Dead code identified** — Files or methods confirmed to have zero references:
    - File path
    - How confirmed (grep results, no imports)
    - Whether safe to delete

7. **Diagnostic techniques used** — Reusable debugging approaches that worked:
    - What technique (e.g., identity hash logging to prove different instances)
    - When to use it (what symptom suggests this technique)
    - Concrete code snippet or command

---

## WHAT NOT TO CAPTURE

- Speculative theories that were disproven during the session
- Intermediate debug logging that was added then removed
- Verbose log dumps or full command output
- Information already well-documented in the existing markdowns (check first!)
- Obvious facts that any developer would know from reading the code
- Bloat for the sake of completeness — every sentence must earn its place

---

## QUALITY PARAMETERS

All information added must satisfy ALL of these:

| Parameter | Requirement |
|---|---|
| **Useful** | Would help an LLM or developer working on this codebase in the future. If it wouldn't change how someone approaches a task, don't add it. |
| **Accurate** | Confirmed by source code, decompilation, or test execution. Never from memory or assumption. |
| **Verified** | You saw the evidence yourself — log output, code, test results. State how it was verified. |
| **Credible** | Technically precise. Include method names, class names, line numbers, exact behavior. Vague statements are worthless. |
| **Concise** | Not too much information that an LLM loses track, not too little that it's not useful. One finding = one focused section. No filler prose. |
| **Non-redundant** | Check existing content in all four markdowns before adding. If it's already there, don't repeat it. Add only the delta. |
| **Technically detailed** | Include code paths, method signatures, attribute keys, error codes. "It didn't work" is useless; "startTestWithToken returned 400 because sessionId was null on the prototype instance" is useful. |

---

## FORMATTING RULES

- **Match the existing style** in each markdown. Read the file before editing. Follow the same heading levels, bullet patterns, code block usage, and tone.
- **Headers, bullets, and short code snippets** — not paragraphs of prose. Keep code snippets to the relevant 1-5 lines, not entire methods.
- **Use tables** for structured reference data (attribute keys, API contracts, file catalogs).
- **Use code blocks** for exact code, commands, and flows. Use inline `backticks` for class/method names in prose.
- **Cross-reference other markdowns** instead of duplicating: "See `framework.instructions.md → Reporting System → Local Rerun Flow`"
- **INVESTIGATION_LOG.md entries** must follow the numbered entry format already established in that file. Increment the entry number. Use the Area tags from `architecture.instructions.md` layer classification.
- **Design for appendability** — structure so future sessions can add new sections in the same format without restructuring.

---

## PROCESS

1. **Read all four markdowns first** to understand what's already documented and the current style.
2. **Inventory what you learned** in this session — list every verified fact, bug fix, file explored, command run.
3. **Deduplicate** — remove anything already captured in the existing docs.
4. **Route** each piece of information to the correct markdown using the decision tree above.
5. **Write** the additions, matching existing style and following quality parameters.
6. **Verify** — re-read what you wrote. Would a developer or LLM reading ONLY this file, with no other context, understand the finding well enough to act on it? If not, add the missing detail.
