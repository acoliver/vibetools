#!/usr/bin/env python3
import collections
import json
import re
import subprocess

COHORT = [
    ('vybestack/llxprt-code', 2462, '66b27be6d45d96fdc18e972cbbba64748c90e22a'),
    ('vybestack/llxprt-code', 2547, '4a50e2b7a25746c93a349fcc65b61cde633f09d1'),
    ('vybestack/llxprt-jefe', 181, 'f2409b7fca9dd4e52f85473e6d162b1e17763b20'),
    ('vybestack/llxprt-jefe', 288, '4e4a43c08bef2d9f55e50b48d18145cf001b75d9'),
    ('vybestack/llxprt-luther', 110, 'af9922e648900e2b557c93fe80ae47fa59d9c98b'),
    ('vybestack/llxprt-luther', 133, '2b7d7576c057f955d92aa21cd02c2a34e8c04db0'),
]
REPOS = [
    ('vybestack/llxprt-code', 'llxprt-code-ocr-inline', 'ocr-review.yml', '2026-07-07T06:11:36Z'),
    ('vybestack/llxprt-jefe', 'jefe-ocr-inline', 'ocr-review.yml', '2026-07-08T16:37:39Z'),
    ('vybestack/llxprt-luther', 'luther-ocr-inline', 'ocr-pr-review.yml', '2026-07-13T04:07:12Z'),
]

def gh_json(*args):
    return json.loads(subprocess.check_output(['gh', *args]))

def flatten(value):
    if value and isinstance(value[0], list):
        return sum(value, [])
    return value

def norm_body(body):
    body = re.sub(r'<!--[\s\S]*?ocr-inline[\s\S]*?-->', '', body or '')
    return ' '.join(body.split())

print('COHORT')
for repo, pr, sha in COHORT:
    comments = flatten(gh_json('api', '--paginate', f'repos/{repo}/pulls/{pr}/comments?per_page=100'))
    comments = [c for c in comments if not c.get('in_reply_to_id') and c['user']['login'] == 'github-actions[bot]' and 'ocr-inline' in c.get('body', '') and c.get('original_commit_id') == sha]
    groups = collections.defaultdict(list)
    for comment in comments:
        groups[norm_body(comment.get('body'))].append(comment)
    print(repo, pr, 'n', len(comments), 'reviews', len({c.get('pull_request_review_id') for c in comments}), 'window', min(c['created_at'] for c in comments), max(c['created_at'] for c in comments))
    for body, items in groups.items():
        if len(items) > 1:
            print(' EXACT', len(items), 'review_ids', sorted({str(c.get('pull_request_review_id')) for c in items}), 'ids', [c['id'] for c in items], 'paths', [c['path'] for c in items], body[:200])

print('RUNS')
for repo, marker, workflow, cutoff in REPOS:
    runs = gh_json('run', 'list', '-R', repo, '--workflow', workflow, '--limit', '500', '--json', 'databaseId,createdAt,event,headSha,headBranch,conclusion,url')
    groups = collections.defaultdict(list)
    for run in runs:
        groups[(run['headBranch'], run['headSha'])].append(run)
    repeated = [items for items in groups.values() if len(items) > 1]
    print(repo, 'runs', len(runs), 'head_identities', len(groups), 'same_head_extra_runs', sum(len(items) - 1 for items in repeated), 'identities_repeated', len(repeated))
    for items in sorted(repeated, key=lambda value: min(r['createdAt'] for r in value))[-15:]:
        print(' ', items[0]['headBranch'], items[0]['headSha'][:10], len(items), ','.join(sorted(r['event'] + ':' + str(r['conclusion']) for r in items)))

print('REPOSITORY_EXACT')
for repo, marker, workflow, cutoff in REPOS:
    comments = flatten(gh_json('api', '--paginate', f'repos/{repo}/pulls/comments?per_page=100'))
    comments = [c for c in comments if not c.get('in_reply_to_id') and c['user']['login'] == 'github-actions[bot]' and marker in c.get('body', '')]
    print(repo, 'all_roots', len(comments))
    for label, selected in [('before', [c for c in comments if c['created_at'] < cutoff]), ('after', [c for c in comments if c['created_at'] >= cutoff])]:
        groups = collections.defaultdict(list)
        for comment in selected:
            key = (comment['pull_request_url'], comment.get('original_commit_id'), comment['path'], comment.get('line') or comment.get('original_line'), norm_body(comment.get('body')))
            groups[key].append(comment)
        exact = sum(len(items) - 1 for items in groups.values())
        cross = sum(len(items) - 1 for items in groups.values() if len({c.get('pull_request_review_id') for c in items}) > 1)
        print(' ', label, 'n', len(selected), 'exact_dups', exact, 'rate', round(100 * exact / len(selected), 1) if selected else None, 'within_batch', exact - cross, 'cross_batch', cross)
