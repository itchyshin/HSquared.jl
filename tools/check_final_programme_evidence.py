"""Re-attest frozen local programme evidence; this does not run fits or assert CI."""
import argparse
import hashlib
import json
import math
from datetime import datetime
from pathlib import Path


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load(path):
    return json.loads(path.read_text())


def require(condition, message):
    if not condition:
        raise ValueError(message)


def check_files(root, files):
    require(bool(files), 'Empty file inventory')
    for name, expected in files.items():
        relative = Path(name)
        require(not relative.is_absolute() and '..' not in relative.parts, 'Unsafe inventory path')
        require(digest(root / relative) == expected, 'File differs from checked bytes: ' + name)


def check_result(evidence, name, artifacts):
    require(name in artifacts, 'Result is not pinned: ' + name)
    result = load(evidence / name)
    require(type(result.get('exit_status')) is int and result['exit_status'] == 0, 'Unsuccessful result: ' + name)
    require(result.get('over_estimate') is False, 'Missing or exceeded estimate: ' + name)
    elapsed = result.get('elapsed_seconds')
    require(type(elapsed) in (int, float) and math.isfinite(elapsed) and elapsed > 0, 'Invalid elapsed time: ' + name)
    datetime.fromisoformat(result['start_utc'])
    return result


def check_rendered(evidence, manifest, language):
    entries = [e for e in manifest['rendered_pages'] if e['language'] == language]
    required = {'validation-status', 'multivariate-models'} if language == 'julia' else {'current-limits', 'multivariate', 'genetic-gllvm'}
    require(required <= {e['name'] for e in entries}, 'Incomplete rendered surface inventory')
    for entry in entries:
        require(entry['artifact'] in manifest['artifacts'], 'Rendered page is not pinned')
        terms = entry['required_terms']
        require(isinstance(terms, list) and bool(terms) and all(isinstance(t, str) and bool(t.strip()) for t in terms), 'Empty rendered caveat terms')
        text = (evidence / entry['artifact']).read_text()
        require(all(term in text for term in terms), 'Rendered caveat missing: ' + entry['artifact'])


def verify(root, evidence, scope, r_root=None):
    manifest = load(evidence / 'final-acceptance-manifest.json')
    artifacts = manifest['artifacts']
    check_files(evidence, artifacts)
    require('source-test-freeze-final.json' in artifacts, 'Source freeze is not pinned')
    # Every mode binds the currently integrated numerical source to this check batch.
    freeze = load(evidence / 'source-test-freeze-final.json')['files']
    check_files(root, freeze)
    for directory in ('src', 'test'):
        found = {str(f.relative_to(root)) for f in (root / directory).rglob('*.jl')}
        named = {name for name in freeze if name.startswith(directory + '/') and name.endswith('.jl')}
        require(bool(found) and named == found, 'Incomplete ' + directory + ' code inventory')
    require({'Project.toml', 'Manifest.toml', 'test/runtests.jl'} <= set(freeze), 'Missing runtime/runner pins')
    if scope == 'julia':
        result = check_result(evidence, 'julia-package-final-result.json', artifacts)
        require('julia-package-final.log' in artifacts, 'Package log is not pinned')
        started = datetime.fromisoformat(result['start_utc'])
        frozen = datetime.fromisoformat(load(evidence / 'source-test-freeze-final.json')['utc'])
        require(started >= frozen, 'Package result predates its source freeze')
        require(result['command'][1:] == ['--startup-file=no', '--project=.', '-e', 'using Pkg; Pkg.test(;julia_args=["--threads=1"])'], 'Package command differs')
        require(Path(result['command'][0]).name == 'julia', 'Package executable differs')
        require(result.get('julia_threads') == 1 and result.get('blas_threads') == 1, 'Package thread evidence differs')
        require('Testing HSquared tests passed' in (evidence / 'julia-package-final.log').read_text(), 'Package success marker missing')
        token = 'HSQ_FINAL_JULIA_PASS'
    elif scope == 'docs':
        check_result(evidence, 'docs-result.json', artifacts)
        require({'docs.log', 'docs-Project.toml', 'docs-Manifest.toml'} <= set(artifacts), 'Docs build/environment is not pinned')
        check_files(root, manifest['julia_documentation_files'])
        expected = {str(f.relative_to(root)) for f in (root / 'docs/src').rglob('*') if f.is_file()} | {'docs/make.jl'}
        require(expected == set(manifest['julia_documentation_files']), 'Incomplete documentation inventory')
        check_files(root, manifest['julia_documentation_environment_files'])
        require({'docs/Project.toml', 'docs/Manifest.toml'} == set(manifest['julia_documentation_environment_files']), 'Documentation environment inventory differs')
        check_rendered(evidence, manifest, 'julia')
        token = 'HSQ_FINAL_DOCS_PASS'
    else:
        require(r_root is not None, 'R candidate root required')
        check_files(r_root, manifest['r_files'])
        expected = {str(f.relative_to(r_root)) for directory in ('R', 'tests', 'man', 'vignettes') for f in (r_root / directory).rglob('*') if f.is_file()} | {'DESCRIPTION', 'NAMESPACE'}
        require(expected <= set(manifest['r_files']), 'Incomplete R code/test/manual/article inventory')
        check_result(evidence, 'R-result.json', artifacts)
        require({'R.log', 'R-00check.log', 'hsquared_0.9.0.tar.gz'} <= set(artifacts), 'R package proof is not pinned')
        require('Status: OK' in (evidence / 'R-00check.log').read_text(), 'R check status not OK')
        live = check_result(evidence, 'live-bridge-result.json', artifacts)
        require('live-bridge.log' in artifacts, 'Bridge log is not pinned')
        require(Path(live['project']).resolve() == root.resolve(), 'Bridge project differs')
        require(Path(live['command'][0]).name == 'Rscript' and live['command'][1:] == ['-e', 'devtools::test(filter = "fa-optin|gllvm-optin", stop_on_failure=TRUE)'], 'Bridge command differs')
        require(live.get('julia_threads') == 1 and live.get('blas_threads') == 1, 'Bridge thread evidence differs')
        require(live.get('require_bridge') is True, 'Bridge was optional')
        require('[ FAIL 0 | WARN 0 | SKIP 0 | PASS 213 ]' in (evidence / 'live-bridge.log').read_text(), 'Bounded live bridge summary differs')
        check_result(evidence, 'R-site-result.json', artifacts)
        require('R-site.log' in artifacts, 'R site log is not pinned')
        check_rendered(evidence, manifest, 'R')
        token = 'HSQ_FINAL_R_BRIDGE_DOCS_PASS'
    print(token)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('scope', choices=['julia', 'docs', 'R'])
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--evidence', type=Path)
    parser.add_argument('--r-root', type=Path)
    args = parser.parse_args()
    evidence = args.evidence or args.root / 'docs/dev-log/check-log.d/2026-09-30-final-integrated'
    verify(args.root, evidence, args.scope, args.r_root)


if __name__ == '__main__':
    main()
