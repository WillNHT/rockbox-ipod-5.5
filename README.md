# Rockbox for the iPod Video (5G / 5.5G)

A Rockbox fork for the 5th and 5.5th generation iPod (iPod Video: 30, 60 and
80GB), built on top of [upstream Rockbox](https://www.rockbox.org/) master and
kept in step with it.

## Added in this fork

Nothing yet - this is the starting point. Fork features will be listed here as
they land.

## Installing

Ready-to-install files are on the
[Releases page](https://github.com/WillNHT/rockbox-ipod-5.5/releases). Each
release carries `rockbox-ipodvideo-vX.Y.Z-full.zip` (firmware and fonts in one
archive: unzip over the root of the iPod's disk), the same parts as separate
zips, and `bootloader-ipodvideo.ipod`.

The iPod must be FAT32 (formatted by iTunes for Windows). Install the Rockbox
bootloader once with [Rockbox Utility](https://www.rockbox.org/wiki/RockboxUtility)
or `ipodpatcher`; after that, upgrading is unzipping a new release over the
disk root.

## Development builds

Every merge to `master` is released as the next semantic version, worked out
from Conventional Commit PR titles (`feat:` bumps minor, `fix:`/anything else
bumps patch, `type!:` or a `BREAKING CHANGE:` footer bumps major; see
[`tools/release/next-version.sh`](tools/release/next-version.sh)), and the
version is shown in Rockbox Info. A specific version can be released by
pushing a tag: `git tag v1.0.0 && git push origin v1.0.0`.

Per-commit test builds come from the
[build workflow](https://github.com/WillNHT/rockbox-ipod-5.5/actions/workflows/build.yml):
open the most recent successful run and download the build from "Artifacts".
The artifact is double-zipped.

Upstream Rockbox master is merged in weekly by
[`upstream-sync.yml`](.github/workflows/upstream-sync.yml).

## Contributing

[CLAUDE.md](CLAUDE.md) is the house style - where our code lives, what not to
touch, how to build and test, and the commit conventions. It applies to people
and to agents alike.

PR titles are Conventional Commits and are checked by CI, because the merge
commit is what versions the release. Issues are labelled from
[`.github/labels.yml`](.github/labels.yml); new ones are triaged automatically,
and mentioning **@claude** in an issue or PR comment puts Claude to work on it.

Upstream Rockbox's own documentation is in [`docs/`](docs/).
