# Releasing

A release is cut by pushing a tag. The build runs in GitHub Actions
(`.github/workflows/release.yml`) rather than on a maintainer's machine, so the artifact
does not depend on who built it or what their environment happened to resolve.

## Steps

1. **Bump the version.** Set `__version__` in `luadox/version.py` to the release version,
   with no `v` prefix:

   ```python
   __version__ = "1.4.0"
   ```

   The `Makefile` reads this to name the archive (`ARCHIVE := luadox-$(VER)`), so the
   version and the filename cannot drift apart.

2. **Commit it**, on `master`.

3. **Tag and push:**

   ```bash
   git tag v1.4.0
   git push origin v1.4.0
   ```

That is the whole procedure. The workflow then:

* checks `version.py` matches the tag, and **fails the build if it does not** — so a tag
  pushed without the bump is caught rather than producing a mislabelled artifact;
* runs `make release`, producing the archives below;
* checks each one exists and that the `-tooldir` zip carries the nested layout;
* attaches them to a GitHub Release named for the tag.

## The archives

Two zips, holding the same binary in different layouts:

| | Contains | For |
|---|---|---|
| `luadox-<version>.zip` | `luadox` | Downloading and running the tool directly |
| `luadox-<version>-tooldir.zip` | `luadox/luadox` | Unpacking into a directory that holds several tools side by side |

The second exists because a consumer that extracts into a shared tools directory needs the
binary in its own subdirectory. Without it, that archive has to be repacked by hand after
every release, which also means the published checksums no longer match what was built.

`luadox-<version>.tar.gz` is the first layout as a tarball.

## What is in the artifact

The bundle contains a `BUILD-INFO` file recording the version, the commit it was built
from, the build time, and the versions of the bundled dependencies:

```
luadox 1.4.0
commit 27c1d3dca1fb093937f50e6f9b997e36cb8f4754
built 2026-10-15T09:19:46Z

bundled dependencies:
PyYAML-6.0.3
commonmark-0.9.1
commonmarkextensions-0.0.6
```

Dependencies are pinned exactly in `requirements.txt`, so two builds of the same commit
bundle the same versions.

## Publishing elsewhere

Downstream consumers may fetch the release from their own package repository rather than
from GitHub. Uploading it there is a separate, manual step and is deliberately not
automated here: see the internal release runbook for the destination.

Upload `luadox-<version>-tooldir.zip`, **renamed to `luadox-<version>.zip`**. A consumer
builds the filename it fetches from the tool name and the version it pins, so the
`-tooldir` suffix only tells the two archives apart on the release page and must not
survive the upload.

Rename it; do not rebuild or repack it. A rename leaves the bytes untouched, so the
published copy keeps the same sha256 as the release asset and the two can be compared
directly. Repacking changes them, and provenance then has to be established by unpacking
both archives and comparing the binary inside.

## If the build fails

The most common cause is step 1 — the tag does not match `version.py`. Fix the version on
`master`, delete and re-push the tag:

```bash
git tag -d v1.4.0
git push origin :refs/tags/v1.4.0
```
