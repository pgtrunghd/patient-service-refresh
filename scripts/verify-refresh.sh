#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "${1:-$(dirname "$project_dir")/medical-config-repo}" "${2:?Usage: verify-refresh.sh CONFIG_REPO PATIENT_PID}" <<'PYTHON'
import json
import os
from pathlib import Path
import subprocess
import sys
import urllib.request

repo = Path(sys.argv[1]).resolve()
pid = int(sys.argv[2])
config_file = repo / 'patient-service.properties'
base = 'http://localhost:8081'
old = 'Chào mừng tới BV RikkeiAcademy'
new = 'Chào mừng tới BV RikkeiEducation'

def git(*args):
    return subprocess.check_output(['git', '-C', str(repo), *args], text=True).strip()

def started():
    os.kill(pid, 0)
    return subprocess.check_output(['ps', '-p', str(pid), '-o', 'lstart='], text=True).strip()

def welcome():
    with urllib.request.urlopen(base + '/welcome') as response:
        return response.read().decode('utf-8')

def refresh():
    with urllib.request.urlopen(urllib.request.Request(base + '/actuator/refresh', method='POST')) as response:
        return json.load(response)

def commit_welcome(value):
    escaped = ''.join(c if ord(c) < 128 else '\\u%04x' % ord(c) for c in value)
    lines = config_file.read_text().splitlines()
    assert sum(line.startswith('app.welcome=') for line in lines) == 1
    config_file.write_text('\n'.join('app.welcome=' + escaped if line.startswith('app.welcome=') else line for line in lines) + '\n')
    git('add', 'patient-service.properties')
    if git('diff', '--cached', '--name-only'):
        git('commit', '-m', 'Update welcome message for refresh demonstration', '--only', '--', 'patient-service.properties')

assert git('status', '--porcelain') == '', 'Commit local Git changes before running this script'
start_before = started()
commit_welcome(old)
refresh()
assert welcome() == old
commit_welcome(new)
before_refresh = welcome()
assert before_refresh == old, 'Message must stay cached until POST /actuator/refresh'
changed_keys = refresh()
assert 'app.welcome' in changed_keys
updated = welcome()
assert updated == new
assert started() == start_before, 'Patient Service was restarted'
print(json.dumps({'beforeRefresh': before_refresh, 'afterRefresh': updated,
    'changedKeys': changed_keys, 'pid': pid, 'processStarted': start_before,
    'restartDetected': False, 'result': 'PASS'}, ensure_ascii=False, indent=2))
PYTHON
