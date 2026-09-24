# Check log: CI push trigger (#367), 2026-09-24

Lane: `cursor/post366-t7-ci-push-367` · stay 0.9.0 / count 7

## Commands

```sh
python3 - <<'PY'
from pathlib import Path
text = Path('.github/workflows/CI.yml').read_text()
assert 'push:\n    branches: [main, master]' in text
assert "cancel-in-progress: ${{ github.event_name == 'pull_request' }}" in text
# Keep the four-leg matrix on push (do not silently drop Windows).
assert 'os: [ubuntu-latest, windows-latest]' in text
print('push + PR-only cancel-in-progress + full matrix OK')
PY
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/CI.yml')); print('CI.yml parses')"
```

Note: PyYAML 1.1 maps the key `on:` to boolean `True`, so trigger assertions
use the source text, not `doc['on']`.

## Outcome

Both checks pass locally before push. Live CI evidence is the PR run on this
branch, then the first `push` run on `main` after merge.
