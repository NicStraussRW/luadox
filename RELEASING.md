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
* runs `make release`, producing `build/luadox-<version>.zip` and `.tar.gz`;
* attaches both to a GitHub Release named for the tag.

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
automated here: see the internal release runbook for the destination and layout.

## If the build fails

The most common cause is step 1 — the tag does not match `version.py`. Fix the version on
`master`, delete and re-push the tag:

```bash
git tag -d v1.4.0
git push origin :refs/tags/v1.4.0
```
