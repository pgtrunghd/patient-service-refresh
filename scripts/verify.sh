#!/usr/bin/env bash
set -euo pipefail
python3 - <<'PYTHON'
import json
import urllib.request

with urllib.request.urlopen('http://localhost:8888/patient-service/default') as r:
    config = json.load(r)
source = config['propertySources'][0]['source']
assert source['spring.datasource.url'] == 'jdbc:postgresql://localhost:${PATIENT_DB_PORT:5432}/patient_db'
assert source['spring.datasource.username'] == 'postgres'
assert source['spring.jpa.hibernate.ddl-auto'] == 'update'
assert config['version'], 'Configuration must come from a Git commit'

payload = {'fullName': 'Config Client Smoke Test', 'address': 'Demo'}
request = urllib.request.Request('http://localhost:8081/api/v1/patients',
    data=json.dumps(payload).encode(), headers={'Content-Type': 'application/json'})
with urllib.request.urlopen(request) as r:
    assert r.status == 201
    created = json.load(r)
with urllib.request.urlopen(f"http://localhost:8081/api/v1/patients/{created['id']}") as r:
    loaded = json.load(r)
assert loaded['id'] == created['id']
assert loaded['fullName'] == payload['fullName']
print(json.dumps({'configCommit': config['version'], 'database': source['spring.datasource.url'],
    'createStatus': 201, 'readStatus': 200, 'patientId': created['id'], 'result': 'PASS'}, indent=2))
PYTHON
