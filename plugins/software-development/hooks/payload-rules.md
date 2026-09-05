# software-development: working rules

**Worktree cleanup.** `EnterWorktree` places worktrees under `.claude/worktrees/`. `superpowers:finishing-a-development-branch` recognises only `.worktrees/` and `worktrees/` as its own and declines to remove anything else. Once the branch is merged or abandoned, run `git worktree remove <path>` from the main checkout, then `git worktree prune`.

**Task reports.** `superpowers:subagent-driven-development` writes its reports into a git-ignored `.superpowers/sdd/<plan>/` workspace and deletes that workspace at its Finish step, so a report is not a durable home. Name a destination for each Concern as you write it, and close a plan's workspace only once every Concern's disposition has landed there: an issue, a spec or register entry, or a recorded decline.
