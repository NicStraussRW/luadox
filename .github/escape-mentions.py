#!/usr/bin/env python3
"""Stop generated release notes from mentioning accounts that did not contribute.

Pull request titles in this project carry LuaDox doc tags -- @enum, @since, @deprecated
and friends -- and GitHub renders any @name in a release body as a mention. Those names
belong to real, unrelated accounts, which are then linked from the release and notified.

Rewrite every @name that is not a contributor to this release as a code span, which GitHub
does not linkify. The contributor set is read out of the generated notes themselves rather
than hardcoded, so it stays correct as contributors come and go.
"""

import re
import sys

# "* Title by @author in <url>" and "* @author made their first contribution in <url>",
# the two shapes GitHub's generated notes use to name a real contributor.
_BY_AUTHOR = re.compile(r'by @([A-Za-z0-9-]+) in')
_FIRST_CONTRIBUTION = re.compile(r'^\* @([A-Za-z0-9-]+) made their first', re.M)
# Skip a name already in a code span, and anything following a word character, so an
# address like name@example.com is left alone.
_MENTION = re.compile(r'(?<![`\w])@([A-Za-z0-9_-]+)')


def escape_mentions(notes):
    contributors = set(_BY_AUTHOR.findall(notes)) | set(_FIRST_CONTRIBUTION.findall(notes))

    def replace(match):
        if match.group(1) in contributors:
            return match.group(0)
        return '`@{}`'.format(match.group(1))

    return _MENTION.sub(replace, notes)


def main(path):
    # newline='' both ways: read and write the bytes as they are, so the file's line
    # endings survive a run on any platform.
    with open(path, encoding='utf-8', newline='') as notes_file:
        notes = notes_file.read()
    escaped = escape_mentions(notes)
    if escaped != notes:
        with open(path, 'w', encoding='utf-8', newline='') as notes_file:
            notes_file.write(escaped)
    changed = sum(1 for before, after in zip(notes.split('\n'), escaped.split('\n'))
                  if before != after)
    print('escaped stray mentions on {} line(s) of {}'.format(changed, path))


if __name__ == '__main__':
    main(sys.argv[1])
