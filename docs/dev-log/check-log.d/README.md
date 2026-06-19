# check-log.d — per-file check evidence

As of 2026-06-19 the check log is **per-file** to avoid merge conflicts when
parallel slices land (pattern adopted from DRM.jl). Each slice adds a new file
`YYYY-MM-DD-<slice>.md` here instead of editing a shared table.

- One file per slice; never edit another slice's file.
- The frozen historical log is `../check-log.md` (do not append to it).
- Each entry records: goal, commands run, results (tests/docs/CI), and the
  claim boundary.
