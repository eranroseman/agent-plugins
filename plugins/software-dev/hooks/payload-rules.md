# software-dev: working rules

**Worktree cleanup.** `EnterWorktree` places worktrees under `.claude/worktrees/`. `superpowers:finishing-a-development-branch` recognises only `.worktrees/` and `worktrees/` as its own and declines to remove anything else. Once the branch is merged or abandoned, run `git worktree remove <path>` from the main checkout, then `git worktree prune`.
