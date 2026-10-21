"""Turn a Checkov scan into compliance evidence and a CI gate.

    checkov -d . --framework terraform -o json --quiet --compact > compliance/checkov.json
    python compliance/iac_evidence.py compliance/checkov.json

Every failed check must either be fixed or covered by a reviewed, unexpired exception in
compliance/exceptions.yaml. Results are mapped to NIST SP 800-53 Rev. 5 and the CIS AWS
Foundations Benchmark v3.0.0 (compliance/iac_controls.yaml) and written as:

    compliance/report.md                  human-readable evidence, findings and exceptions
    compliance/assessment-results.json    OSCAL 1.1.2 assessment results

Exit code 1 when any failed check has no valid exception, so new misconfigurations fail CI.
"""
import datetime
import hashlib
import json
import os
import pathlib
import sys
import uuid

import yaml

HERE = pathlib.Path(__file__).resolve().parent
NS = uuid.uuid5(uuid.NAMESPACE_URL, 'https://github.com/Mihirajmera/iac-evidence')


def today():
    epoch = os.environ.get('SOURCE_DATE_EPOCH')
    if epoch:
        return datetime.datetime.fromtimestamp(int(epoch), datetime.timezone.utc)
    return datetime.datetime.now(datetime.timezone.utc)


def load_scan(path):
    raw = pathlib.Path(path).read_bytes()
    data = json.loads(raw)
    runs = data if isinstance(data, list) else [data]
    passed, failed, version = [], [], ''
    for run in runs:
        if run.get('check_type') not in (None, 'terraform'):
            continue
        res = run.get('results', {})
        passed += res.get('passed_checks', [])
        failed += res.get('failed_checks', [])
        version = run.get('summary', {}).get('checkov_version', version)
    return passed, failed, version, hashlib.sha256(raw).hexdigest()


def matching_exception(check, exceptions, now):
    for e in exceptions:
        if e['check'] != check['check_id']:
            continue
        resources = e.get('resources', ['*'])
        if '*' in resources or check['resource'] in resources:
            expired = datetime.date.fromisoformat(str(e['expires'])) < now.date()
            return e, expired
    return None, False


def main(scan_path):
    controls = yaml.safe_load((HERE / 'iac_controls.yaml').read_text(encoding='utf-8'))['checks']
    policy = yaml.safe_load((HERE / 'exceptions.yaml').read_text(encoding='utf-8'))
    exceptions = policy.get('exceptions', [])
    passed, failed, version, scan_sha = load_scan(scan_path)
    now = today()

    open_findings, excepted = [], []
    for f in failed:
        exc, expired = matching_exception(f, exceptions, now)
        (excepted if exc and not expired else open_findings).append((f, exc, expired))

    def mapped(check_id, key):
        return ', '.join(controls.get(check_id, {}).get(key, [])) or '–'

    def where(f):
        lines = f.get('file_line_range') or [0, 0]
        return f"`{f['file_path'].lstrip('/').lstrip(chr(92))}:{lines[0]}`"

    repo = policy.get('system', HERE.parent.name)
    L = [f'# IaC compliance evidence: {repo}', '',
         f"Checkov {version} scanned the Terraform on {now:%Y-%m-%d}. Scan output SHA-256: `{scan_sha[:16]}…`.", '',
         f'| Passed | Failed, open | Failed, exception | Unique checks |', '|---:|---:|---:|---:|',
         f"| {len(passed)} | **{len(open_findings)}** | {len(excepted)} | "
         f"{len({c['check_id'] for c in passed + failed})} |", '',
         '**Gate:** CI fails if any failed check lacks a reviewed, unexpired exception.' if not open_findings else
         f'**Gate: failing.** {len(open_findings)} failed check(s) need a fix or a reviewed exception.', '']
    if open_findings:
        L += ['## Open findings', '', '| Check | Resource | Where | NIST 800-53 | CIS AWS v3.0 | Note |', '|---|---|---|---|---|---|']
        for f, exc, expired in open_findings:
            note = f"exception expired {exc['expires']}" if expired else ''
            L.append(f"| {f['check_id']} {f['check_name']} | `{f['resource']}` | {where(f)} | "
                     f"{mapped(f['check_id'], 'nist_800_53')} | {mapped(f['check_id'], 'cis_aws')} | {note} |")
        L.append('')
    L += ['## Exceptions', '',
          f"Reviewed {policy.get('reviewed')} by {policy.get('owner', 'the repository owner')}. "
          'Each one is a decision with a reason and an expiry, not a suppression.', '',
          '| Check | Resource | Decision | Reason | Expires | NIST 800-53 |', '|---|---|---|---|---|---|']
    for f, exc, _ in sorted(excepted, key=lambda t: (t[0]['check_id'], t[0]['resource'])):
        L.append(f"| {f['check_id']} {f['check_name']} | `{f['resource']}` | {exc['decision']} | {exc['reason']} | "
                 f"{exc['expires']} | {mapped(f['check_id'], 'nist_800_53')} |")
    L += ['', '## Passed checks by NIST 800-53 control', '']
    by_control = {}
    for c in passed:
        for ctl in controls.get(c['check_id'], {}).get('nist_800_53', ['unmapped']):
            by_control[ctl] = by_control.get(ctl, 0) + 1
    L += ['| Control | Passed checks |', '|---|---:|'] + [f'| {k} | {v} |' for k, v in sorted(by_control.items())]
    L += ['', 'Mappings to NIST 800-53 and CIS are my own judgment ([`iac_controls.yaml`](iac_controls.yaml)); '
          'checks without a mapping are counted as *unmapped*.']
    (HERE / 'report.md').write_text('\n'.join(L) + '\n', encoding='utf-8', newline='\n')

    def uid(*p):
        return str(uuid.uuid5(NS, '|'.join(map(str, p))))
    observations, findings = [], []
    for c, state, remark in ([(c, 'satisfied', '') for c in passed]
                             + [(f, 'not-satisfied', f"exception: {e['decision']}, expires {e['expires']}") for f, e, _ in excepted]
                             + [(f, 'not-satisfied', 'open') for f, _, _ in open_findings]):
        obs = uid('obs', c['check_id'], c['resource'], state)
        observations.append({'uuid': obs, 'title': f"{c['check_id']} {c['resource']}", 'description': c['check_name'],
                             'methods': ['TEST'], 'collected': now.isoformat(),
                             'props': [{'name': 'result', 'value': state}] + ([{'name': 'remark', 'value': remark}] if remark else [])})
        for ctl in controls.get(c['check_id'], {}).get('nist_800_53', []):
            oscal_id = ctl.lower().replace('(', '.').replace(')', '')
            findings.append({'uuid': uid('finding', c['check_id'], c['resource'], ctl), 'title': f"{c['check_id']} -> {ctl}",
                             'description': c['check_name'],
                             'target': {'type': 'objective-id', 'target-id': f'{oscal_id}_obj', 'status': {'state': state}},
                             'related-observations': [{'observation-uuid': obs}]})
    doc = {'assessment-results': {
        'uuid': uid('ar', scan_sha), 'metadata': {'title': f'IaC compliance evidence: {repo}', 'last-modified': now.isoformat(),
                                                  'version': '1.0', 'oscal-version': '1.1.2'},
        'import-ap': {'href': '#'},
        'results': [{'uuid': uid('result', scan_sha), 'title': f'Checkov {version}', 'start': now.isoformat(),
                     'description': f'Scan output sha256 {scan_sha}', 'observations': observations, 'findings': findings}]}}
    (HERE / 'assessment-results.json').write_text(json.dumps(doc, indent=2) + '\n', encoding='utf-8', newline='\n')

    print(f'{len(passed)} passed, {len(excepted)} failed with exceptions, {len(open_findings)} open')
    for f, exc, expired in open_findings:
        print(f"OPEN {f['check_id']} {f['resource']} ({f['file_path']}){' - exception expired' if expired else ''}")
    return 1 if open_findings else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1]))
