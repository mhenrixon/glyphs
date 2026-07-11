---
model: opus
description: "Benchmark the current branch against main and report a same-machine before/after. Use when a change touches a hot path (SVG render/resolution, the per-process svg cache, or the source scanner) or when asked to measure performance."
argument-hint: "optional: a specific hot path or bench name (e.g. render, scan)"
---

# Performance Command

Measure, don't guess. This command produces a **same-machine before/after** so
any performance claim is backed by numbers. glyphs has two paths worth
measuring: the per-render SVG resolution (`Glyphs.svg_for` → `render_svg`, hot
because it runs on every icon and is memoized behind the `cache_svgs` toggle),
and the source scanner (`SourceScanner`, the Prism-AST-plus-template pass that
dominates `glyphs:prune_icons` on a real app tree).

## The non-negotiable rule

**Measure BEFORE you change.** A delta you didn't baseline is not a delta. If a
change already landed without a baseline, reconstruct one from `main` in a
worktree (below) — never report a number against a baseline from another machine
or another day.

## Workflow

### 1. Baseline `main` (before)

Capture pristine `main` with the SAME bench script you'll run on the branch, in
an isolated worktree (so `lib/` is pristine but the harness is present):

```bash
git worktree add --detach /tmp/pr-baseline main
# Copy the harness AND Gemfile — main may predate the bench script.
cp -r benchmark /tmp/pr-baseline/ && cp Gemfile Gemfile.lock /tmp/pr-baseline/
(cd /tmp/pr-baseline && bundle install && ruby benchmark/micro/render.rb) > /tmp/before.txt
```

glyphs ships no `benchmark/` dir yet — the first perf PR adds one. A bench is a
plain script (`benchmark/micro/render.rb`) using `benchmark-ips` +
`benchmark-memory`; keep it self-contained so it runs against a bare `lib/`.
If the branch added a bench that calls a method absent on `main` (e.g. a new
`reset_cache!`), write a baseline-safe script that only calls methods present on
`main`, and run that script in BOTH trees.

### 2. Measure the branch (after)

```bash
ruby benchmark/micro/render.rb > /tmp/after.txt
ruby benchmark/micro/scan.rb          # scanner pass over a fixture app tree
diff /tmp/before.txt /tmp/after.txt
git worktree remove --force /tmp/pr-baseline
```

For a single isolated change, prefer an in-place toggle over the worktree — it
removes worktree variance entirely. The render path already has one: flip
`Glyphs.configure { |c| c.cache_svgs = false }` (or run the same bench with it
on) to isolate the memoization win from the raw `Icons::Icon#svg` cost.

### 3. Report HONESTLY

- Give throughput (i/s, μs/i) AND allocations (obj/call, retained). Retained > 0
  per cached render after warm-up is a leak in `@svg_cache` — call it out.
- **Distinguish a cache-hit win from a cold-render win.** With `cache_svgs` on,
  the second render of the same `[library, variant, name, attributes]` key is a
  hash lookup; the real work is the cold `Icons::Icon#svg` read+parse. Say which
  number you're quoting — a "10× faster render" that's only the warm cache path
  is meaningless for first paint.
- If a number is within run-to-run noise (`benchmark-ips` shows ±%), say "within
  noise" — don't dress it up.
- If you only measured *after* (no clean baseline), say so explicitly.

### 4. Keep perf continuous (every PR that touches a hot path)

- [ ] A bench exists for the changed hot path (`benchmark/micro/<name>.rb`). Add
      one if missing.
- [ ] The before/after numbers are in the PR body.
- [ ] CHANGELOG notes the perf change (`perf:` scope).
- [ ] The mutex-guarded `@svg_cache` still round-trips: `reset_cache!` clears it
      and a warm hit returns the same string. Run `bundle exec rspec` — a perf
      tweak to `svg_for`/`render_svg` must not change output.

## The hot paths to watch

| Path | Bench | Note |
|------|-------|------|
| `Glyphs.svg_for` (cache hit) | `benchmark/micro/render.rb` | Runs every icon; the memoized hash lookup + key construction is what we trim. |
| `render_svg` / `Icons::Icon#svg` (cold) | `benchmark/micro/render.rb` (cache off) | The real cost — reading and parsing the SVG off disk. Dominates first paint. |
| `SourceScanner#call` | `benchmark/micro/scan.rb` | Prism parse of every `.rb` + regex scan of every template; dominates `glyphs:prune_icons`. Bench against a fixture app tree, not one file. |

Argument (`$ARGUMENTS`): if a specific path/bench is named (e.g. `render`,
`scan`), focus the measurement on that script; otherwise run every
`benchmark/micro/*.rb`.
