### Rules for Modifying or Adding Code in This Repository

1. Plan first, then implement. Understand every line before writing it.
2. Simple > clever. No abstract classes, no over-engineering, no showing off. Use parameters instead of overrides. Use concrete classes with shared helpers instead of abstract hooks.
3. Meet 100% of requirements. Don't deviate from architecture, formatting, logging, or error-handling patterns.
4. Minimal, review-friendly changes. Preserve existing functionality.
5. No redundant code. Reuse via inheritance, composition, and parameterized helpers — but keep it simple. If the "reuse" adds more complexity than duplication, just duplicate.
6. No unnecessary comments or emojis. Comments must earn their place.
7. Split test classes for parallel execution when 3+ independent flow types share the same scenario set and each takes >5s. Don't split for 1-2 types or sub-second tests.
8. When shared test logic exists, put it in a concrete common class with parameterized `run*()` methods. Subclasses pass their specific params — no abstract methods, no overrides. If a flow is fundamentally different (e.g., payment plan vs. payment session), it writes its own test methods using shared helpers.
9. Capture session knowledge in `TECHNICAL_NOTES.md` per `KNOWLEDGE_ACCUMULATOR.md`.
10. Append proven Tier 3 commands to **Verified Commands** below.

