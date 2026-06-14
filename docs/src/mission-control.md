# Mission Control

This page is the HSquared.jl engine dashboard for the `hsquared` / `HSquared.jl`
twin project. It is designed to be read like a live operating board, but it is
still a static, repo-versioned Documenter page: the check log, tests, CI, and
status tables remain the source of truth.

```@raw html
<style>
.hs-mission {
  --ink: #172026;
  --muted: #5a6670;
  --line: #d7dde2;
  --panel: #f8fafb;
  --blue: #245b73;
  --green: #2f6f5e;
  --amber: #8b641d;
  --red: #9d3f3f;
  --violet: #5d568f;
  color: var(--ink);
}
.hs-mission * { box-sizing: border-box; }
.hs-hero {
  border: 1px solid var(--line);
  border-radius: 8px;
  padding: 22px;
  margin: 16px 0 20px;
  background: linear-gradient(135deg, #f8fbfc 0%, #eef5f1 54%, #f7f7fb 100%);
}
.hs-kicker {
  margin: 0 0 8px;
  color: var(--muted);
  font-size: 0.86rem;
  font-weight: 700;
  letter-spacing: 0.04em;
  text-transform: uppercase;
}
.hs-hero h2 {
  margin: 0;
  font-size: 1.75rem;
  line-height: 1.12;
  letter-spacing: 0;
}
.hs-hero p {
  max-width: 78ch;
  margin: 10px 0 0;
  color: var(--muted);
}
.hs-grid {
  display: grid;
  gap: 12px;
}
.hs-grid.metrics {
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  margin: 0 0 18px;
}
.hs-grid.two {
  grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
}
.hs-card {
  border: 1px solid var(--line);
  border-radius: 8px;
  background: #fff;
  padding: 14px;
}
.hs-card h3 {
  margin: 0 0 8px;
  font-size: 1rem;
  letter-spacing: 0;
}
.hs-metric {
  min-height: 106px;
}
.hs-metric strong {
  display: block;
  font-size: 1.45rem;
  line-height: 1;
  margin-bottom: 7px;
}
.hs-metric span,
.hs-card p,
.hs-card li {
  color: var(--muted);
}
.hs-tagrow {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin-top: 10px;
}
.hs-tag {
  display: inline-flex;
  align-items: center;
  border: 1px solid var(--line);
  border-radius: 999px;
  padding: 3px 8px;
  font-size: 0.78rem;
  background: var(--panel);
}
.hs-tag.done { border-color: #a7c8bb; color: var(--green); background: #eff8f5; }
.hs-tag.partial { border-color: #d9c491; color: var(--amber); background: #fff8e8; }
.hs-tag.plan { border-color: #c5c3dd; color: var(--violet); background: #f5f4fb; }
.hs-tag.block { border-color: #dfb3b3; color: var(--red); background: #fff1f1; }
.hs-road {
  display: grid;
  gap: 8px;
  margin-top: 8px;
}
.hs-phase {
  display: grid;
  grid-template-columns: minmax(78px, 112px) 1fr;
  gap: 10px;
  padding: 10px;
  border: 1px solid var(--line);
  border-radius: 8px;
  background: var(--panel);
}
.hs-phase b {
  color: var(--blue);
}
.hs-phase span {
  color: var(--muted);
}
.hs-table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 8px;
}
.hs-table th,
.hs-table td {
  border-bottom: 1px solid var(--line);
  padding: 8px 6px;
  text-align: left;
  vertical-align: top;
}
.hs-table th {
  color: var(--muted);
  font-size: 0.82rem;
}
.hs-list {
  margin: 8px 0 0;
  padding-left: 18px;
}
.hs-lenses {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 8px;
  margin-top: 8px;
}
.hs-lens {
  border: 1px solid var(--line);
  border-radius: 8px;
  padding: 9px;
  background: var(--panel);
}
.hs-lens b { display: block; }
.hs-lens span { color: var(--muted); font-size: 0.88rem; }
@media (max-width: 620px) {
  .hs-hero { padding: 16px; }
  .hs-hero h2 { font-size: 1.35rem; }
  .hs-phase { grid-template-columns: 1fr; }
}
</style>
<div class="hs-mission">
  <section class="hs-hero" aria-labelledby="hs-mission-title">
    <p class="hs-kicker">hsquared / HSquared.jl mission control</p>
    <h2 id="hs-mission-title">One public R language, one Julia engine, one evidence gate.</h2>
    <p>
      This board tracks the Julia lane. It separates engine utilities that exist,
      validation-scale paths that are experimental, and roadmap capabilities that
      are deliberately still planned.
    </p>
    <div class="hs-tagrow" aria-label="current status tags">
      <span class="hs-tag done">Phase 0 scaffold complete</span>
      <span class="hs-tag partial">Phase 1 validation engine active</span>
      <span class="hs-tag partial">R bridge opt-in and tiny/local</span>
      <span class="hs-tag block">No production fitting claim</span>
    </div>
  </section>
  <section class="hs-grid metrics" aria-label="top metrics">
    <article class="hs-card hs-metric">
      <strong>1</strong>
      <span>shared public grammar currently parsed by R: <code>animal(1 | id, pedigree = ped)</code></span>
    </article>
    <article class="hs-card hs-metric">
      <strong>8</strong>
      <span>roadmap phases visible from scaffold through HPC scaling</span>
    </article>
    <article class="hs-card hs-metric">
      <strong>6</strong>
      <span>planned backend vocabulary rows: CPU, threads, CUDA, AMDGPU, Metal, oneAPI</span>
    </article>
    <article class="hs-card hs-metric">
      <strong>0</strong>
      <span>production GPU, QTL/eQTL, GLLVM, or broad production-fitting claims</span>
    </article>
  </section>
  <section class="hs-grid two" aria-label="lane status">
    <article class="hs-card">
      <h3>Julia Engine Lane</h3>
      <p>Current focus: Phase 1 Gaussian animal-model engine groundwork.</p>
      <ul class="hs-list">
        <li>Implemented: pedigree normalization, sparse Ainv, low-level spec validation, sparse CSC marshalling.</li>
        <li>Experimental: dense ML/REML validation path, sparse supplied-variance REML identity, sparse REML validation optimizer, Henderson MME solve, EBV/BLUP/fitted-value/PEV/reliability/accuracy extractors.</li>
        <li>Diagnostics: <code>validation_status()</code>, <code>formula_status()</code>, <code>backend_info()</code>, <code>data_status()</code>, and <code>fit_diagnostics()</code>.</li>
      </ul>
    </article>
    <article class="hs-card">
      <h3>R Twin Boundary</h3>
      <p>The R package owns public formula ergonomics and user-facing fit objects.</p>
      <ul class="hs-list">
        <li>R may preview bridge payloads with <code>model_spec()</code>.</li>
        <li>R may opt into tiny/local Julia execution for validation paths.</li>
        <li>Julia field names, result shapes, and bridge targets must stay coordinated before public widening.</li>
      </ul>
    </article>
  </section>
  <section class="hs-card" aria-label="phase board">
    <h3>Phase Board</h3>
    <div class="hs-road">
      <div class="hs-phase"><b>Phase -1</b><span>Ecosystem learning from drmTMB, DRM.jl, gllvmTMB, GLLVM.jl, and the shared agent-kit patterns.</span></div>
      <div class="hs-phase"><b>Phase 0</b><span>Public twin scaffold, team rules, roadmap, Documenter, CI, honest placeholder surface.</span></div>
      <div class="hs-phase"><b>Phase 1</b><span>Univariate Gaussian animal model: Ainv, likelihoods, MME, EBVs, h2, validation fixtures, bridge payload parity.</span></div>
      <div class="hs-phase"><b>Phase 2</b><span>Repeatability, permanent environment, maternal/paternal, common environment, sire, dominance, and custom kernels.</span></div>
      <div class="hs-phase"><b>Phase 3</b><span>Multivariate Gaussian animal models, G/R/P matrices, missing trait records, genetic correlations.</span></div>
      <div class="hs-phase"><b>Phase 4</b><span>Factor-analytic G matrices: <code>diag()</code>, <code>lowrank(K)</code>, <code>fa(K)</code>, latent breeding values, evolvability.</span></div>
      <div class="hs-phase"><b>Phase 5</b><span>GBLUP, SNP-BLUP, single-step, APY, marker effects, QTL/GWAS/eQTL scans.</span></div>
      <div class="hs-phase"><b>Phase 6</b><span>GLLVM-style high-dimensional animal models, non-Gaussian responses, omics, ordination.</span></div>
      <div class="hs-phase"><b>Phase 7</b><span>Accelerator-aware computation: CPU default, optional GPU backends, backend agreement tests, and benchmark evidence.</span></div>
      <div class="hs-phase"><b>Phase 8</b><span>HPC and production scaling: checkpointing, disk-backed data, streaming scans, distributed simulation, and national-computer benchmarks.</span></div>
    </div>
  </section>
  <section class="hs-grid two" aria-label="evidence and gates">
    <article class="hs-card">
      <h3>Evidence Now</h3>
      <table class="hs-table">
        <thead><tr><th>Surface</th><th>Status</th><th>Evidence</th></tr></thead>
        <tbody>
          <tr><td>Pedigree Ainv</td><td><span class="hs-tag done">implemented</span></td><td>hand fixtures plus R-side nadiv/Mrode9 pedigree comparator.</td></tr>
          <tr><td>Henderson MME</td><td><span class="hs-tag partial">experimental</span></td><td>supplied-variance fixtures with fixed effects, EBVs, fitted values, h2, PEV, reliability.</td></tr>
          <tr><td>Dense REML/ML</td><td><span class="hs-tag partial">experimental</span></td><td>tiny validation optimizer, guarded by <code>max_dense_cells</code>.</td></tr>
          <tr><td>Sparse REML / AI-REML</td><td><span class="hs-tag partial">experimental</span></td><td>Gaussian validation-scale estimators; not production sparse fitting.</td></tr>
          <tr><td>Genomic utilities</td><td><span class="hs-tag partial">experimental</span></td><td>VanRaden G, GBLUP, SNP-BLUP, supplied H-inverse, and genomic REML; no public genomic model-spec default.</td></tr>
          <tr><td>Marker screening</td><td><span class="hs-tag partial">experimental</span></td><td>direct fixed-effect, supplied-variance mixed, dense LOCO precision construction, and supplied LOCO marker-scan helpers plus row-aligned scan-table, effect-summary, marker-variance contribution, Manhattan/regional-window/QQ/lambda_GC diagnostic data; no formula-driven GWAS/QTL, calibrated p-values, calibrated PVE/model R², gwas_table/qtl_table activation, regional_plot/fine-mapping activation, or R formula activation.</td></tr>
          <tr><td>Multivariate G</td><td><span class="hs-tag partial">experimental</span></td><td>dense validation-scale multi-trait REML plus diag/lowrank/fa structured covariance; no comparator parity.</td></tr>
          <tr><td>HSData diagnostics</td><td><span class="hs-tag done">implemented</span></td><td>component, ID, pedigree, genotype, marker, expression, annotation, and environment metadata checks.</td></tr>
          <tr><td>Backends</td><td><span class="hs-tag plan">planned</span></td><td>typed vocabulary and status diagnostics only; no runtime dispatch.</td></tr>
        </tbody>
      </table>
    </article>
    <article class="hs-card">
      <h3>Blocked Claims</h3>
      <ul class="hs-list">
        <li>No production sparse REML/ML/AI-REML fitting claim.</li>
        <li>No production sparse PEV/reliability claim.</li>
        <li>No public R-facing genomic model-spec, mixed-model marker scan, QTL/eQTL, or GLLVM fitting claim.</li>
        <li>No calibrated mixed-model p-values, calibrated PVE/model R² claims, interval-mapping or mixed-model LOD workflows, public LOCO workflow defaults, plotting backend, advanced/correlated-marker multiple-testing workflow, or comparator-parity claim for marker scans.</li>
        <li>No GPU execution, backend benchmarking, or CPU/GPU agreement claim.</li>
        <li>No ASReml, BLUPF90, DMU, WOMBAT, sommer, JWAS, or GLLVM superiority claim.</li>
      </ul>
    </article>
  </section>
  <section class="hs-card" aria-label="team lenses">
    <h3>Review Lenses</h3>
    <p>These are review perspectives, not automatically running agents.</p>
    <div class="hs-lenses">
      <div class="hs-lens"><b>Ada</b><span>orchestration</span></div>
      <div class="hs-lens"><b>Shannon</b><span>coordination</span></div>
      <div class="hs-lens"><b>Hopper</b><span>R-Julia bridge</span></div>
      <div class="hs-lens"><b>Henderson</b><span>MME and BLUPs</span></div>
      <div class="hs-lens"><b>Gauss</b><span>numerics</span></div>
      <div class="hs-lens"><b>Karpinski</b><span>Julia performance</span></div>
      <div class="hs-lens"><b>Fisher</b><span>inference</span></div>
      <div class="hs-lens"><b>Curie</b><span>fixtures and edge cases</span></div>
      <div class="hs-lens"><b>Jason</b><span>package scouting</span></div>
      <div class="hs-lens"><b>Pat</b><span>user clarity</span></div>
      <div class="hs-lens"><b>Grace</b><span>CI and docs</span></div>
      <div class="hs-lens"><b>Rose</b><span>claim audit</span></div>
    </div>
  </section>
</div>
```

## Operating Links

- [Get started](quickstart.md)
- [Model spec grammar](model-spec-grammar.md)
- [Validation status](validation-status.md)
- [Data containers](data.md)
- [Backend and algorithm roadmap](backend-algorithm-roadmap.md)
- [Roadmap](roadmap.md)
- [Reference](api.md)
