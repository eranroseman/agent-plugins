# Plans

How a plan in `docs/superpowers/plans/` marks the text each edit replaces, how those anchors are checked before the edit runs, how a task's diff is reviewed, and how a plan's workspace closes.

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

## Reviewing a task

`Workflow({name: 'task-review', args})` runs `.claude/workflows/task-review.js` on one task's diff. Its args are `brief`, `report`, `base`, `head`, `worktree`, `workspace` and `changed`, the paths `git diff --name-only BASE..HEAD` prints, with `rulings`, `context` and `readme_blocks` optional; set `readme_blocks` to true when the diff touches a fenced `sh` block in the README. It returns `{ lenses, findings, reports }`: findings keyed by lens, each Critical or Important one with its refuter's verdict, and the path of each lens's full report in the workspace.

## Closing the workspace

Before deleting a plan's SDD workspace, run `scripts/sdd-close <workspace>`. It reads `<workspace>/progress.md` and fails on each line that mentions `minor (deferred)`, `parked` or `Ruling` without a home, a completion line's count of parked findings aside: `#<issue>` for one filed, `declined: <reason>` for a recorded decline, or `landed: <sha>` for a ruling or a spec entry that became a commit. Write the home with the line, while the decision is in front of you. The script deletes nothing; once it passes, delete the workspace by hand.

## Why scripts

Plan B's pre-flight found most of its defects in anchors the tree did not hold. Eliminating anchors is not available: a plan describes edits to text that exists. The mechanism is `scripts/plan-anchors`. The only rule left is the block form, which is what the script needs to find an anchor at all, and it refuses to parse around a departure from it: a fence that never closes, an anchor fence that is indented, an `old` block without a path, or a section that says "becomes" and carries no anchor fails rather than passes.

The same holds for the workspace. `AGENTS.md`'s rule that it closes only once every concern has a home broke twice in two executions as prose, and the second time an issue had to be rebuilt from a transcript. `scripts/sdd-close` is its mechanism; the rule left is the three home forms, which are what it reads.
