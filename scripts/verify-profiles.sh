#!/usr/bin/env bash
set -euo pipefail
python3 - <<'PYTHON'
import json
import urllib.request

results = []
for profile, port, scheme, driver in (
    ('dev', 8081, 'jdbc:mysql:', 'com.mysql.cj.jdbc.Driver'),
    ('prod', 8082, 'jdbc:postgresql:', 'org.postgresql.Driver'),
):
    with urllib.request.urlopen(f'http://localhost:8888/patient-service/{profile}') as response:
        config = json.load(response)
    assert config['profiles'] == [profile]
    assert config['version']
    sources = config['propertySources']
    assert sources[0]['name'].endswith(f'patient-service-{profile}.properties')
    # Config Server lists the highest-precedence property source first.
    effective = {}
    for source in reversed(sources):
        effective.update(source['source'])
    assert str(effective['server.port']) == str(port)
    assert effective['spring.datasource.url'].startswith(scheme)
    assert effective['spring.datasource.driver-class-name'] == driver

    payload = {'fullName': f'Profile {profile} Smoke Test', 'address': 'Demo'}
    request = urllib.request.Request(f'http://localhost:{port}/api/v1/patients',
        data=json.dumps(payload).encode(), headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(request) as response:
        assert response.status == 201
        created = json.load(response)
    with urllib.request.urlopen(f"http://localhost:{port}/api/v1/patients/{created['id']}") as response:
        assert response.status == 200
        loaded = json.load(response)
    assert loaded['fullName'] == payload['fullName']
    results.append({'profile': profile, 'port': port, 'database': scheme,
        'configCommit': config['version'], 'patientId': created['id'], 'result': 'PASS'})
print(json.dumps(results, indent=2))
PYTHON
