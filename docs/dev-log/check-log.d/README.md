# check-log.d — per-file check evidence

As of 2026-06-19 the check log is **per-file** to avoid merge conflicts when
parallel slices land (pattern adopted from DRM.jl). Each slice adds a new file
`YYYY-MM-DD-<slice>.md` here instead of editing a shared table.

- One file per slice; never edit another slice's file.
- The frozen historical log is `../check-log.md` (do not append to it).
- Each entry records: goal, commands run, results (tests/docs/CI), and the
  claim boundary.

## Viewing the combined log

`check-log.md` is historical. To see it plus an index of every shard in this
directory, in filename (≈ date) order:

```
bash tools/build_check_log.sh            # frozen log + shard index to stdout
bash tools/build_check_log.sh --check    # exit 1 if any shard is malformed
```

The builder never rewrites `check-log.md`. DRM.jl shards are one Markdown table
row each; HSquared.jl shards are prose (same shape as hsquared). `--check`
validates that shape: dated filename, ATX heading, at least one body line.
It does not rewrite files and is not wired into CI.
