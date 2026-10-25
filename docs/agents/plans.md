# Plans

How a plan in `docs/superpowers/plans/` marks the text each edit replaces, and how those anchors are checked before the edit runs.

## Anchors

An edit's anchor is a fenced block whose info string is `old` and the path of the file the edit changes, relative to the repository root. The block holds the file's exact current text, one or more lines, and that text occurs in the file once. A `new` block may follow with the replacement; nothing reads it.

````markdown
```old GLOSSARY.md
A condition that must hold before the next thing runs.
```

```new
A condition that must hold before the next thing starts.
```
````

The anchor's fence starts at column 0. A fence closes only on a bare fence of its own character at least as long as the one that opened it, so a plan that quotes a step whole in a four-backtick fence can carry anchors inside it, and they are still read.

## Checking them

`scripts/plan-anchors PLAN TASK` checks the anchors in the plan's `Task TASK` section against the working tree that holds the plan: each path tracked, each text found exactly once. It lists every failure, with its plan line where there is one. A section with no anchor fails too when its prose says "becomes" or "as it stands", which is an edit described without one.

Run it at Task 1's hand-off and again at the start of each later task. A later task's anchor may quote text an earlier task writes, so it cannot pass before that task has run, and an edit made since the plan was written can move an anchor out from under it.

TASK matches exactly: `7` does not select `### Task 7b:`. Superpowers' `task-brief` does, since it accepts any non-digit after the number. Until that is fixed upstream, a plan avoids letter-suffixed task numbers, or gives every task in the series its full suffix (7a and 7b, never 7 beside 7b).

## Why a script

Plan B's pre-flight found most of its defects in anchors the tree did not hold. Eliminating anchors is not available: a plan describes edits to text that exists. The mechanism is `scripts/plan-anchors`. The only rule left is the block form, which is what the script needs to find an anchor at all, and it refuses to parse around a departure from it: a fence that never closes, an anchor fence that is indented, an `old` block without a path, or a section that says "becomes" and carries no anchor fails rather than passes.
