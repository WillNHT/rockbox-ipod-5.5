# Working on this repo

Rockbox fork for the iPod Video (5th and 5.5th generation), on top of upstream
Rockbox master. C89-ish C, a huge upstream tree, and a small set of files that
are actually ours. Read `README.md` for what the fork adds.

## Where our code lives

The fork is new: so far only the process files are ours. Add a row here as
each area gains fork code.

| Area | Files |
| --- | --- |
| Device | `firmware/target/arm/ipod/video/`, `firmware/target/arm/ipod/` |
| Keymap | `apps/keymaps/keymap-ipod.c` |
| Build/release | `.github/workflows/`, `tools/release/` |

Everything else is upstream Rockbox. Do not reformat, "clean up" or refactor
upstream files. Touch them only where the feature needs it, in the style of the
surrounding code - every line we change is a line that can conflict with the
weekly upstream merge.

## Upstream

[Rockbox/rockbox](https://github.com/Rockbox/rockbox) master (mirror of
git.rockbox.org) is a real git upstream: it merges straight in.
`.github/workflows/upstream-sync.yml` opens a `chore(upstream): merge Rockbox
master` PR weekly, or an issue when the merge conflicts. Resolve conflicts in
favour of upstream unless a fork feature depends on the change. A fix that is
not iPod-specific belongs upstream (gerrit.rockbox.org) as well as here.

## Rules

* **Match the neighbours.** Comment density, naming, brace style and error
  handling come from the file you are editing, not from your own preferences.
* **Smallest change that works.** No new abstraction, config option, helper
  layer or dependency unless the feature cannot land without it. When a stdlib
  or existing Rockbox helper does the job, use it. See the `ponytail` skill.
* **No speculative work.** No "while I was in here" edits, no unrequested
  refactors, no new settings nobody asked for.
* **Never touch the bootloader or the click wheel driver** unless the task is
  about them. A broken bootloader means a disk-mode recovery for the human.
* **Settings** need the whole chain: `settings_list.c`, `settings.h`, lang
  strings in `apps/lang/english.lang`, and a config.cfg round trip.
* **Memory.** The iPod Video has 32MB (30GB models) or 64MB (60/80GB) of RAM
  and one build serves both: the 64MB is reduced at runtime. Test anything
  memory-hungry against 32MB. No per-frame malloc, no unbounded buffers.

## Build and test

```sh
mkdir -p sim && cd sim && ../tools/configure --target=ipodvideo --type=S && make -j && make install
mkdir -p build && cd build && ../tools/configure --target=ipodvideo   # needs the arm-elf-eabi toolchain
```

The simulator is the fast local check. A full device build is CI's job
(`.github/workflows/build.yml`); do not burn tokens waiting on one locally
unless the task is about the build itself.

## Issues and PRs

Every issue you pick up gets a PR, and every PR points back at its issue:

* **One batch, one PR.** When a session is handed several issues, they all land
  in a single PR against `master`, one commit per issue, with a `Closes #<n>`
  line per issue it finishes and `Refs #<n>` for one it only advances. One PR
  means one build for the human to flash and test. Only open a second PR when a
  change genuinely cannot share a branch with the rest.
* **Label the issue** from `.github/labels.yml` before you start: one `type:`,
  one `area:`, one `severity:`, plus `needs:`/`blocked`/`upstream` where they
  apply, and drop `needs: triage` once it is sorted.
* **Comment the outcome on the issue** when the PR is up: what was done, the PR
  link, anything still open.
* **Agent opens, human approves.** `WillNHT` goes on an agent PR as reviewer.
  Nobody merges their own work, so never approve or merge a PR you opened - the
  review is the human's.

## Device test loop

**Hard rule.** Device testing is manual: the human copies the build to the
iPod and reports back, often hours later. Carrying a session across those gaps
is the biggest cost in this repo. The loop is fixed:

* **The issue is the memory, not the session.** Goal and acceptance criteria
  live in the issue body. Everything learned since lives in one **state
  comment** on the issue, edited in place - never a new comment per round:

  ```
  <!-- state -->
  **Hypothesis:** what we currently think is wrong, and why
  **Tried:** round 1: X - failed, saw Y. round 2: ...
  **Build:** PR #n @ <sha>, CI run <link>
  **Test this round:**
  1. <action> - expect <result>
  2. ...
  ```

* **Resume from the issue.** The first call of a session on an issue is
  `gh issue view <n> --comments`. Never ask the human to re-explain the goal or
  the history; if the state comment is missing something, fix the comment.
* **One flash, one session.** When a build goes out for device testing: wait
  for CI green, update the state comment with a numbered checklist (an action
  and the expected result per item), then stop. Tell the human the round is
  done and to start a fresh session with the results.
* **Results come back per checklist item**, one line each ("1 ok, 2 fail:
  skips after 3s"). Prefer logs over prose.
* **Make each flash count.** When more than one fix is plausible, ship the
  candidates in one build behind a debug toggle, and remove the toggle before
  the PR is marked ready. Anything the simulator can show is checked there
  first - the device is for hardware behaviour.
* **Keep the session small.** CI failures through
  `gh run view <id> --log-failed | tail -80`, never the full log.

## Proof

A claim is not evidence. Anything user-visible ships with a screenshot in the
PR description (simulator, or a photo of the iPod). Before/after pairs for
anything that changes existing behaviour. Non-visual work proves itself with
pasted command output.

## CI

A PR is not done until **every** check is green. Push, watch the run, fix what
it reports, push again - never hand over a PR with a red or pending check. If a
failure is genuinely unrelated to the change, say so on the PR and quote the
log line that shows it.

## Commits and PRs

Conventional Commits, enforced on the **PR title** by
`.github/workflows/pr-title.yml` - the merge commit's body becomes the release
version bump (`tools/release/next-version.sh`).

```
feat(wps): show the album year
fix(playback): gapless no longer drops the first frame
```

Types: `build chore ci docs feat fix perf refactor revert style test theme`.
Subject under ~50 chars, imperative, no trailing period. A body only when the
*why* is not obvious from the diff. Breaking change: `feat!:`.

PR description: what changed, why, how it was tested, the screenshot, and
`Closes #<n>`.

## Being cost-effective

* **Grep before reading.** This tree is enormous. `Grep`/`Glob` to find the
  handful of relevant files; never read a large upstream file end to end.
* **Answer from what you already have.** Do not re-read a file you just edited,
  and do not re-derive facts already established in the session.
* **One sweep, not a crawl.** Batch independent searches and reads.
* **Delegate fan-out, not focus.** A broad search is worth a subagent; a
  two-file edit is not.
* **Say less.** Terse output; code and commit messages stay written normally.
* **Keep caveman and ponytail on.** If either skill is not installed, ask the
  user to install it instead of working without it.
