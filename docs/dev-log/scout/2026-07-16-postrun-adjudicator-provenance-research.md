# Scout — Post-run adjudicator provenance & write-once receipt research

- **Date:** 2026-07-16
- **Author:** Ranganathan (NotebookLM librarian), commissioned by Shinichi
- **Purpose:** Feed the SEVENTH retry of the v0.7 genomic public-activation arc with
  grounded, citation-backed engineering patterns, so the re-architecture of the
  post-run adjudicator/receipt stage is research-informed rather than another blind patch.
- **Boundary:** Research + distilled note only. This scout does **NOT** edit any
  engine/statistical code, does **NOT** touch carried-over/quarantined Retry-6 state,
  and does **NOT** run any fit or campaign. It is a design input, not a decision.
- **NotebookLM:** notebook `335c52d6-a3a1-415b-9612-8021c4672d47`
  ("HSquared postrun adjudicator — provenance & write-once receipts"), 72 auto-imported
  sources over two Deep Research passes (web). Personal Google account, `notebooklm` CLI
  (the shared MCP server was `not_configured`; CLI auth was live).

## The recurring defect class (what we are designing against)

Six consecutive retries of genomic public-activation have failed. **The science closes
cleanly every time** (Retry 6: 576 official R fits, 576 independent base-R recomputations,
576 exact Julia replays, all three summaries mutually agree). **The failure is always in
the post-run receipt/adjudication plumbing at the very last step:**

- Retry 4: one-ULP float representation mismatch at an interval endpoint.
- Retry 5: runtime tree-validation blocker.
- Retry 6: `UNADJUDICATED_POSTRUN_ADJUDICATOR_ROUTE_BLOCKER` — Julia rows were correctly
  admitted as `julia_profile_replay`, then a summary-reconstruction helper **re-admitted**
  them under `ordinary_auto_genomic`. The route/provenance binding was silently lost during
  summary aggregation; zero malformed evidence rows; the adjudicator refused to write a receipt.

**Generalised class:** *a post-run adjudicator / write-once "receipt" stage in a multi-route
reproducible-computation pipeline loses or rebinds each evidence row's route/provenance tag
during summary reconstruction/aggregation, and fails closed.*

## Provenance and trust of this note

This is a **triage synthesis of an unofficial tool**, not validated truth. NotebookLM was
fed public web sources; auto-imported sources are UNVERIFIED until spot-checked. Citation
URLs below were pulled with `notebooklm source get` and eyeballed for plausibility.

**Two "sources" were self-generated and are excluded from evidence** (`type: markdown`,
`url: null` — the Deep-Research agent's own synthesis re-imported as a source, i.e. the tool
talking to itself): *"Engineering Formal Integrity: Algebraic Data Types, Provenance
Conservation…"* and *"Architectural Integrity and Provenance Preservation in Reproducible
Computational Pipelines."* Some of the more ornate prescriptions the model returned
(BLAKE2b WORM logs, "structural compression", "eliminate mutable status fields") lean on
these plus a handful of unvetted personal blogs / defensive-publication dumps
(dev.to `p0rt`, tdcommons, arXiv 2606.10270) — treated as **leads, LOW confidence**, not canon.

**Verified canonical foundations** (real, well-known URLs — trustworthy for what they state):

- W3C **PROV-DM** — <https://www.w3.org/TR/prov-dm/>
- Amsterdamer, Deutch & Tannen, **"Provenance for Aggregate Queries"** (PODS 2011) —
  <http://www.cs.tau.ac.il/~danielde/publications/pods2011a.pdf> (+ `pods2011b.pdf`)
- Green & Tannen, **semiring framework for database provenance** (provenance polynomials).
- Alexis King, **"Parse, Don't Validate"** (2019).
- Scott Wlaschin, **"Designing with types: making illegal states unrepresentable"** (F# for
  fun and profit).
- Hillel Wayne, **metamorphic testing**; Wikipedia, *Metamorphic testing*.
- Anthropic, **"Finding bugs with property-based testing."**
- Idempotency / exactly-once / outbox: fluidata, rustycloud training material (secondary).

## Synthesis (answers to the 5 research questions)

### Q1 — Preserve a provenance tag through aggregation

Two established mechanisms:

1. **Semiring / provenance-polynomial annotation (database-provenance theory).** Every tuple
   carries a tag from a semiring. Aggregation does **not** collapse to a raw reduce; it
   computes an *annotated* aggregate (join `⊗`, union/aggregate `⊕`), so the summary row
   inherits a compound tag that **explicitly names every contributing input identifier**. A
   tag mathematically cannot be dropped because it is a function of its inputs
   (Green/Tannen; Amsterdamer-Deutch-Tannen PODS 2011).
2. **W3C PROV causal edges.** Model each result `Entity` as `wasGeneratedBy` an `Activity`
   `wasAssociatedWith` a `SoftwareAgent` (here: the R engine vs the Julia replay). The origin
   is a first-class graph edge, not a mutable string field, so re-summarizing cannot detach it.

### Q2 — Write-once, idempotent, exactly-once receipt

- **Deterministic idempotency key.** Bind the receipt to a stable natural key derived from
  inputs + activity id, e.g. `hash(inputs ‖ route ‖ activityId)`. A retry recomputes the same
  key; the store rejects the duplicate. This gives *emit exactly once*, not zero, not twice.
- **Outbox / intent-log.** Write the intent before the side effect; on retry, check the intent
  log and return the cached receipt instead of re-executing.
- **Append-only ledger, derived status.** Do not carry a mutable `status = "adjudicated"`
  field. Derive committed-ness by checking whether a valid receipt exists in the immutable
  store (removes the "flagged complete but not actually executed" failure). *(Content-addressed
  WORM / cryptographic-hash variants are a LOW-confidence embellishment from unvetted sources —
  the append-only + derived-status idea is the load-bearing part.)*
- **Fail-closed is correct, but must be scoped.** A compliance gate should halt when it cannot
  prove the invariant — which is what Retry 4/5/6 did. The bug is not that it failed closed;
  it is that the invariant was checked **against a tag the pipeline had already corrupted one
  step earlier.** Fail-closed on corrupt input is the symptom, not the cure.

### Q3 — Make the illegal state unrepresentable (the core recommendation)

Runtime string tags (`route = "julia_profile_replay"`) + defensive `if route == …` checks are
**soft constraints**: one `fold`/`map` that forgets to carry the field silently rebinds the
category — exactly Retry 6. Type-level design makes "treat a Julia row as an ordinary row" a
**compile error**, not a runtime hope:

- **Sum type / tagged union**, not a string: `Route = JuliaProfileReplay | OrdinaryAutoGenomic`.
- **Parse, don't validate at the boundary.** Convert the raw route string into the typed row
  **once**, at admission. Downstream summary code receives `Row{JuliaProfileReplay}` and gets
  the provenance guarantee "for free" — it never sees, and cannot fabricate, a raw string.
- **Smart constructors + unexported fields.** The only way to build a `Row{Route}` is the
  admission factory; no downstream helper can forge or overwrite the tag.
- **Set-once / immutable.** No setter on the route. A row parsed as Julia keeps that identity
  through every grouping and summarization step.

In Julia terms: a parametric row type `EvidenceRow{R<:Route}` (or a `@sumtype`/`Union` route
field constructed only via a checked constructor), with `summarise` written so its return type
is parameterised by the same `R`. A helper that tried to re-admit a `JuliaProfileReplay` row as
`OrdinaryAutoGenomic` would fail to typecheck / dispatch — the Retry-6 bug becomes impossible to
express, not merely asserted-against.

### Q4 — Cheapest test gate that catches route-rebinding BEFORE a 576-fit campaign

NotebookLM ranked **metamorphic shuffle-invariance** `f(x) == f(shuffle(x))` as cheapest
(zero oracle, reuse existing data). **Caveat — read carefully:** shuffle-invariance only
catches *order-dependent* rebinding. The Retry-6 helper rebound **every** Julia row to ordinary
**deterministically**, independent of order — a shuffle test would pass while the bug persists.

**The correct cheapest gate for THIS bug is a tag-conservation property on the summary
boundary:** assert that the **multiset of route tags is invariant across summary
reconstruction** —

```
multiset(route(r) for r in input_rows) == multiset(route(r) for r in summary_rows)
```

or the stronger per-route count invariant
`count(input, julia_profile_replay) == count(summary, julia_profile_replay)` (and likewise for
`ordinary_auto_genomic`). This is one property test, runs in milliseconds on a handful of
synthetic rows, needs no oracle and no fit, and fails instantly the moment a
reconstruction helper rebinds a route. Add shuffle-invariance as a cheap second property.
A **contract test** on the summary function's input/output route schema is a fast third layer
but is shallow (it checks shape, not that the *right* rows kept the *right* tags).

**Ranked, cheapest-first:** (1) multiset/per-route **tag-conservation property test** on the
summary boundary — *the one gate that catches Retry-6*; (2) shuffle-invariance metamorphic test;
(3) contract/schema test on the reconstruction boundary. All three are pre-campaign, oracle-free,
and sub-second — none require a fit.

### Q5 — Multi-engine parity / reproducible-audit tooling

Data-lineage workflow engines attach an engine/origin tag to each artifact and could serve as
architecture comparators: **Pachyderm** (content-addressed, immutable data-versioned pipelines),
**Nextflow native data lineage + `nf-prov`** (Lineage IDs → Workflow-Run **RO-Crate** /
BioCompute Objects), **RO-Crate / LifeMonitor** for external parity monitoring. All ultimately
map to W3C PROV: the engine is a `SoftwareAgent`, the run an `Activity`, the result an `Entity`
linked by `wasGeneratedBy`/`wasAssociatedWith`. For HSquared this is a *pattern to borrow*
(engine tag = PROV SoftwareAgent, carried structurally), **not** a dependency to adopt.

## Ranked architectural recommendations for the re-architecture

1. **Represent the route as a type, not a string (illegal-states-unrepresentable).** A sum type
   `Route = JuliaProfileReplay | OrdinaryAutoGenomic` and a row type parameterised by it. This
   is the highest-leverage change: it turns the entire Retry-4-through-6 defect *class* from a
   runtime hazard into a compile/dispatch error. **Do this first.**
2. **Parse-don't-validate at admission; set-once + immutable thereafter.** Convert the raw route
   exactly once at the boundary via a smart constructor with unexported fields. No summary helper
   can forge, mutate, or re-admit a route. Summary functions must *thread* the row's route type,
   never re-derive it.
3. **Tag-conservation invariant on the summary-reconstruction boundary.** Even with types,
   assert `multiset(input routes) == multiset(output routes)` as a property test **and** as a
   cheap in-pipeline runtime check guarding the receipt write — belt and suspenders.
4. **Idempotent write-once receipt.** Deterministic idempotency key = `hash(inputs ‖ route ‖
   activity)`; outbox/intent-log so a retry returns the existing receipt; derive
   "adjudicated" from receipt existence in an append-only store rather than a mutable status flag.
5. **Keep fail-closed, but move the check upstream of the corruption.** Fail-closed is right; the
   fix is to make the invariant it checks (the route binding) impossible to violate before the
   check runs (items 1–3), so the adjudicator never again halts on input its own pipeline spoiled.
6. **(Borrow, don't adopt) map the audit trail to W3C PROV** — engine = `SoftwareAgent`,
   replay = `Activity`, evidence row = `Entity` `wasGeneratedBy` — for a durable, standard
   parity audit format if/when an external record is wanted.

## Single cheapest test gate that catches route-rebinding pre-campaign

A **property test asserting per-route tag-count conservation across the summary-reconstruction
function** on a few synthetic rows:
`count(summary, julia_profile_replay) == count(input, julia_profile_replay)` (and for
`ordinary_auto_genomic`). Oracle-free, sub-second, no fit, no campaign — and it fails the exact
instant a reconstruction helper rebinds a Julia row, which is precisely the Retry-6 blocker.
(Shuffle-invariance alone does **not** catch it, because the rebinding was order-independent.)

## Repo-truth caveats

- This note is a **design input** from an unofficial tool; `docs/design/capability-status.md`,
  the ROADMAP, and repo state outrank it whenever they differ.
- `public_covered_count` remains **5** (only the supplied-`Ginv` estimator covered); nothing here
  activates, adjudicates, or repairs Retry-6. Any adoption must go through the normal
  implementation → tests → capability-status → validation-debt → Rose-audit path.

## Sources (verified URLs; full corpus in the notebook)

- W3C PROV-DM — <https://www.w3.org/TR/prov-dm/>
- Amsterdamer, Deutch & Tannen, "Provenance for Aggregate Queries" (PODS 2011) —
  <http://www.cs.tau.ac.il/~danielde/publications/pods2011a.pdf>, `…/pods2011b.pdf`
- Green & Tannen, "The Semiring Framework for Database Provenance" (ResearchGate).
- Alexis King, "Parse, Don't Validate" (2019) — HN discussion
  <https://news.ycombinator.com/item?id=41031585>
- Scott Wlaschin, "Designing with types: making illegal states unrepresentable" —
  <https://fsharpforfunandprofit.com/posts/designing-with-types-making-illegal-states-unrepresentable/>
- Hillel Wayne, "Metamorphic Testing" — <https://www.hillelwayne.com/post/metamorphic-testing/>
- Wikipedia, "Metamorphic testing" — <https://en.wikipedia.org/wiki/Metamorphic_testing>
- Anthropic, "Finding bugs with property-based testing" —
  <https://www.anthropic.com/research/property-based-testing>
- Idempotency/exactly-once (secondary): fluidata "Building Idempotent Data Pipelines";
  rustycloud "Exactly-Once & Idempotency".
- LOW-confidence leads (real URLs, unvetted): dev.to/p0rt "Your Provenance Vector Dies at the
  Storage Boundary"; tdcommons "Tamper-Evident Status Derivation…"; arXiv 2606.10270
  "Determination Provenance: From Ambiguity to Algebra."
- **Excluded (tool self-synthesis, `url: null`):** "Engineering Formal Integrity…",
  "Architectural Integrity and Provenance Preservation in Reproducible Computational Pipelines."
