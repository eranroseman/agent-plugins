---
name: rethink-audit
description: >
  Clean-slate redesign audit of an existing module, service, or feature —
  design and architecture only, applying no changes. Use when the user asks for
  a clean-slate redesign or a design audit of one.
---

Design from first principles: the requirements tell you what "right" is, and the
code that exists tells you only what the migration costs.

## Method

Work the rungs in order, proposal last. A short section of output per tag.

1. `requires:` — What the design must do, for whom, under what constraints, and
   how you'll know it worked. Dispatch the `prior-art:` reading now, so it runs
   while you reconstruct. For an existing subsystem, reconstruct this from its
   boundary — signatures, call sites, tests, docs — and leave the internals for
   `gap:`. Where the repository keeps ADRs, read them too: a recorded decision
   is a constraint until someone reopens it. Tag each requirement with the
   evidence behind it: `caller`, `tests`, `docs`, `adr`, or `assumed`.
   One requirement per line, each with a stable ID (R1, R2, …) — diffable and
   citable, never a single run-on paragraph.
   **Done when** every caller is accounted for — what it depends on this
   subsystem for, with user-facing entry points standing in where no code calls
   it — and the sweep names what it could not reach, such as dynamic dispatch
   or consumers outside the repository.
2. `prior-art:` — How is this class of problem solved well elsewhere? Run the
   `research` skill, if available: it works the question against primary
   sources in a background agent. **Done when** every pattern named carries
   where it is used and why it fits *these* requirements; every caveat in the
   sourced reading travels into the summary — the summary is never stronger
   than its source, and a citation not checked against its primary is marked
   unverified; and a requirement with no anchor is named unanchored, never
   stretched onto a near-miss.
3. `design:` — The clean-slate structure derived from 1 and 2: real entities,
   seams, invariants. Run the `codebase-design` skill, if available, and name
   the structure in its vocabulary, taking domain terms from the project's
   glossary. Prefer the
   design that is simplest for the requirements as stated — clean-slate means
   unconstrained by the old shape. Where the target contradicts an `adr`
   requirement, make the case for reopening that decision rather than presenting
   the target as new. **Done when** every requirement in `requires:` is answered
   by something in the target.
4. `gap:` — Read the current implementation only now. Where does it diverge
   from the target, and why — accident, dead constraint, or a real constraint
   you missed? Fold real ones back into `requires:`: compliance, a fixed
   external API, a shipped data format. **Done when** every requirement in
   `requires:` has its accounting — what meets it, what diverges from it, or
   what the code leaves unaddressed — and every gap has been re-checked against
   the current tree and tracker at write time: a gap is a claim about current
   state, and it dates from the hour the report ships.
5. `migrate:` — The sequence from here to the target. Smallest safe steps,
   ordered; migration cost never deforms the target. **Done when** every
   divergence named in `gap:` is closed by a step.
6. `trade-offs:` — What the target design gives up. **Done when** each one
   names the constraint that would flip the recommendation.

On a fresh design question there is no implementation: run through `design:`,
then `trade-offs:`.

If the current implementation already *is* the first-principles answer, say
`Already sound. Keep.` and stop; a redesign invented to justify the audit is the
failure this stop prevents.

## After the report

Offer to save it: a chat report dies with the session, and the target is the
part worth re-reading. Put it where the repository already keeps such notes and
match that convention; skip the offer on `Already sound. Keep.`

`migrate:` is the input `superpowers:writing-plans` wants — handed to it as
requirements rather than as tasks, since its Task Right-Sizing rule cuts
coarser than the smallest safe steps `migrate:` names.

## Boundaries

- Correctness bugs, security holes, and performance regressions route to a
  normal review pass.
- When the requirements are themselves still open — a new idea rather than a
  known job — `superpowers:brainstorming` elicits them in dialogue first, and
  its spec becomes this method's `requires:`.
- A scoped tactical question ("why is this function slow", "rename this") gets
  a direct answer, not a re-derivation. Flag it when the honest answer is "the
  current shape is the wrong question; here's the clean-slate version."
- Lists findings, applies nothing. One-shot.
