# OSTEP Homework (C)

Layout:
  <chapter>/            e.g. 05_interlude_process_api/
    file.c              many .c files per chapter
  include/               shared headers
  bin/                   generated binaries (gitignored)
  Makefile

Build:
  make          # builds all exercises
  make single CH=5 Q=1

Run a single exercise:
  make run CH=5 Q=1

Dev:
  make sanitized    # build with sanitizers
  make valgrind CH=... Q=...

Notes:
- Put shared headers in `include/`.
- Binaries go to `bin/` and are ignored by git.
