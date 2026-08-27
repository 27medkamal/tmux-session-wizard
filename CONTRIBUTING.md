# Contributing

Thanks for wanting to improve tmux-session-wizard! A few principles guide
every decision in this repo — reading them first will save you a review
round-trip.

## Design principles

1. **One prefix key.** The whole point of the plugin is doing everything
   through a single popup. PRs that add new tmux keybindings users must
   memorise will be declined. New interactions belong inside the existing
   popup (fzf bindings, like `ctrl-x` to kill) or behind hooks.
2. **No friction in the core flow.** "Press key → pick → land in a session"
   must never gain an extra prompt, confirmation, or selection step. If your
   workflow needs one, implement it as a hook (see below).
3. **Backwards compatible, always.** Any behaviour change ships behind a tmux
   option that defaults to the current behaviour.
4. **Hooks over features.** Workflow-specific behaviour (naming schemes,
   collision handling, session layouts) belongs in
   `@session-wizard-pre-create-session-hook` /
   `@session-wizard-post-create-session-hook` plus, ideally, an example
   script in `examples/` — not hard-coded into the plugin.
5. **Portability.** Code must work on stock macOS (BSD grep/sed/sort, old
   bash) and Linux (GNU userland), and across fzf versions — feature-gate
   new fzf flags (see `__fzf_version_at_least`). Don't rely on `$SHELL` in
   fzf bind strings; route through `t --internal-mode` flags instead.
6. **Safe shell.** Never let values that originate from the filesystem or
   zoxide be re-parsed by the shell (directory names are attacker-influenced
   via e.g. `git clone`). See `create_session` for the quoting pattern.

## Tests

Nothing lands without tests. The suite uses
[bats](https://github.com/bats-core/bats-core) with `bats-support` and
`bats-assert`:

```bash
bats -r ./tests                       # everything
bats --filter-tags unit -r ./tests    # unit only
./scripts/run-tests.sh -c             # inside Docker (no local deps needed)
```

Integration tests run tmux on an isolated socket, so they're safe to run on
your machine, even from inside tmux. Unit tests stub `tmux`/`zoxide`/`fzf` as
shell functions — see `tests/helpers.bats` for the pattern.

Run `shellcheck` on any shell file you touch. CI runs the suite on Linux and
macOS for every PR.

## Pull requests

- Explain the **problem** you're solving, not just the patch — the accepted
  solution often ends up shaped differently from the first proposal, and
  that's a normal, welcome part of review here.
- Keep diffs focused; typo fixes are welcome but separate from features.
- Update `README.md` for any new option or visible behaviour.
