#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Git Commit & Push - Marjan Aram Project
Run: python push.py
"""
import os
import sys
import subprocess
import datetime


# ============================================================
#  Helpers
# ============================================================
def run(cmd, capture=False):
    if capture:
        result = subprocess.run(
            cmd, shell=True, capture_output=True, text=True,
            encoding='utf-8', errors='replace'
        )
        return result.stdout.strip()
    return subprocess.run(cmd, shell=True)


def write_file(path, lines):
    """Write list of lines to file (UTF-8, LF)"""
    with open(path, 'w', encoding='utf-8', newline='\n') as f:
        f.write('\n'.join(lines))


def step(num, total, msg):
    print('[{}/{}] {}'.format(num, total, msg))


# ============================================================
#  Check location
# ============================================================
if not os.path.exists('manage.py'):
    print('ERROR: run this script in project root (where manage.py is)')
    sys.exit(1)

print('')
print('=' * 55)
print('  Git Commit & Push - Marjan Aram')
print('=' * 55)

TOTAL = 7


# ============================================================
#  STEP 1: .gitignore
# ============================================================
print('')
step(1, TOTAL, 'Creating .gitignore...')

gitignore_lines = [
    '# Python',
    '__pycache__/',
    '*.py[cod]',
    '*$py.class',
    '*.so',
    '*.egg-info/',
    '.installed.cfg',
    '*.egg',
    '',
    '# Django',
    '*.log',
    'local_settings.py',
    'db.sqlite3',
    'db.sqlite3-journal',
    'media/',
    'staticfiles/',
    '',
    '# Environment',
    '.env',
    '.env.*',
    '!.env.example',
    'venv/',
    'env/',
    'ENV/',
    '',
    '# IDE',
    '.idea/',
    '.vscode/',
    '*.swp',
    '*.swo',
    '*~',
    '',
    '# OS',
    '.DS_Store',
    'Thumbs.db',
    'desktop.ini',
    '',
    '# Node',
    'node_modules/',
    '',
    '# Testing',
    '.coverage',
    'htmlcov/',
    '.pytest_cache/',
    '',
    '# Backups',
    '*.bak',
    '*.backup',
    'db.sqlite3.bak*',
    '',
]

write_file('.gitignore', gitignore_lines)
print('  OK .gitignore created')


# ============================================================
#  STEP 2: .env.example
# ============================================================
print('')
step(2, TOTAL, 'Creating .env.example...')

env_lines = [
    '# Django',
    'SECRET_KEY=django-insecure-change-me-in-production',
    'DEBUG=True',
    'ALLOWED_HOSTS=localhost,127.0.0.1',
    '',
    '# Zarinpal',
    'ZARINPAL_MERCHANT_ID=your-merchant-id-here',
    'ZARINPAL_SANDBOX=True',
    '',
    '# SMS',
    'SMS_API_KEY=your-api-key',
    'SMS_SENDER=10008663',
]

if not os.path.exists('.env.example'):
    write_file('.env.example', env_lines)
    print('  OK .env.example created')
else:
    print('  OK .env.example already exists')


# ============================================================
#  STEP 3: README.md (using simple concatenation)
# ============================================================
print('')
step(3, TOTAL, 'Creating README.md...')

readme_lines = [
    '# Marjan Aram - Psychology Clinic Website',
    '',
    'Complete psychology counseling website with:',
    '- Online appointment booking with Jalali calendar',
    '- Zarinpal payment gateway',
    '- Admin dashboard with charts',
    '- Custom Persian admin panel',
    '',
    '## Features',
    '',
    '- Public pages (home, services, packages, articles)',
    '- User authentication with phone number',
    '- Appointment booking system',
    '- Payment with PDF invoice',
    '- Reviews and ratings',
    '- Custom admin panel (Persian, dark theme)',
    '- Modern responsive design',
    '- 100% offline (no external CDN)',
    '',
    '## Installation',
    '',
    'Requirements: Python 3.10+, pip, Git',
    '',
    'Steps:',
    '',
    '1. Clone repository:',
    '   git clone <repo-url>',
    '   cd marjanaram',
    '',
    '2. Create virtual environment:',
    '   python -m venv venv',
    '   source venv/bin/activate',
    '',
    '3. Install dependencies:',
    '   pip install -r requirements.txt',
    '',
    '4. Setup environment:',
    '   cp .env.example .env',
    '',
    '5. Run migrations:',
    '   python manage.py migrate',
    '',
    '6. Create superuser:',
    '   python manage.py createsuperuser',
    '',
    '7. Seed sample data (optional):',
    '   python manage.py seed_data',
    '',
    '8. Run server:',
    '   python manage.py runserver',
    '',
    '## Default Credentials',
    '',
    '- URL: http://127.0.0.1:8000/admin/',
    '- Username: marjan_aram',
    '- Password: Marjan@1404',
    '',
    '## Main Pages',
    '',
    '- Home: /',
    '- Services: /services/',
    '- Packages: /packages/',
    '- Articles: /articles/',
    '- About: /about/',
    '- Contact: /contact/',
    '- Book appointment: /appointments/book/',
    '- My appointments: /appointments/my/',
    '- Profile: /accounts/profile/',
    '- Dashboard: /dashboard/',
    '- Admin panel: /admin/',
    '',
    '## Tech Stack',
    '',
    '- Backend: Django 5.0',
    '- Database: SQLite / PostgreSQL',
    '- Frontend: Tailwind CSS, Alpine.js',
    '- Charts: Chart.js',
    '- Font: Vazirmatn',
    '- Icons: Bootstrap Icons',
    '- Payment: Zarinpal',
    '- PDF: ReportLab',
    '- Jalali Date: jdatetime',
    '',
    '## License',
    '',
    'All rights reserved for Marjan Aram (c) 1404',
    '',
]

write_file('README.md', readme_lines)
print('  OK README.md created')


# ============================================================
#  STEP 4: Git init
# ============================================================
print('')
step(4, TOTAL, 'Checking git repository...')

if not os.path.isdir('.git'):
    print('  -> Initializing new git repository...')
    run('git init')
    run('git branch -M main')

    print('')
    print('  Enter Git remote URL (optional)')
    print('  Example: https://github.com/user/repo.git')
    print('  Press Enter to skip')
    print('')

    try:
        remote_url = input('  Remote URL: ').strip()
    except (KeyboardInterrupt, EOFError):
        remote_url = ''

    if remote_url:
        run('git remote add origin "{}"'.format(remote_url))
        print('  OK Remote added: {}'.format(remote_url))
    else:
        print('  WARN No remote set (add later: git remote add origin <url>)')
else:
    print('  OK Already a git repository')
    remotes = run('git remote -v', capture=True)
    if remotes:
        print('')
        print('  Current remotes:')
        for line in remotes.split('\n')[:4]:
            print('    {}'.format(line))


# ============================================================
#  STEP 5: Stage
# ============================================================
print('')
step(5, TOTAL, 'Staging files...')

run('git add -A')

staged = run('git diff --cached --name-only', capture=True)
staged_count = len([l for l in staged.split('\n') if l.strip()])
print('  OK Total staged files: {}'.format(staged_count))

if staged_count > 0:
    print('')
    print('  First 15 staged files:')
    for line in staged.split('\n')[:15]:
        if line.strip():
            print('    - {}'.format(line))


# ============================================================
#  STEP 6: Commit
# ============================================================
print('')
step(6, TOTAL, 'Committing...')

has_changes = run('git diff --cached --quiet; echo $?', capture=True).strip() != '0'

if not has_changes:
    print('  WARN Nothing new to commit')
    latest = run('git log -1 --oneline', capture=True)
    if latest:
        print('  Latest commit: {}'.format(latest))
    print('')
    print('=' * 55)
    print('  Script finished (nothing to push)')
    print('=' * 55)
    sys.exit(0)

timestamp = datetime.datetime.now().strftime('%Y-%m-%d %H:%M')

default_msg_lines = [
    'feat: full project setup - {}'.format(timestamp),
    '',
    'Complete Django project - Marjan Aram psychology clinic',
    '',
    'Backend:',
    '- Custom user model with phone auth and roles',
    '- Appointment system with Jalali calendar',
    '- Service, package, article management',
    '- Zarinpal payment gateway',
    '- PDF invoice generation',
    '- Doctor dashboard',
    '',
    'Frontend:',
    '- Dark theme (Tailwind CSS)',
    '- Custom Persian admin panel',
    '- Mobile responsive',
    '- 100% offline (local CDN resources)',
    '',
    'Co-authored-by: Marjan Aram',
]

default_msg = '\n'.join(default_msg_lines)

print('')
print('  Default commit message:')
print('  ' + '-' * 40)
for line in default_msg_lines[:4]:
    print('  {}'.format(line))
print('  ...')
print('  ' + '-' * 40)
print('')
print('  Press Enter to use default, or type custom message:')

try:
    custom_msg = input('  > ').strip()
except (KeyboardInterrupt, EOFError):
    custom_msg = ''

commit_msg = custom_msg if custom_msg else default_msg

# Save to temp file
with open('.git_commit_msg.tmp', 'w', encoding='utf-8', newline='\n') as f:
    f.write(commit_msg)

result = run('git commit -F .git_commit_msg.tmp')

if os.path.exists('.git_commit_msg.tmp'):
    os.remove('.git_commit_msg.tmp')

if result.returncode != 0:
    print('')
    print('  WARN Commit failed')
    sys.exit(1)

print('  OK Committed successfully')


# ============================================================
#  STEP 7: Push
# ============================================================
print('')
step(7, TOTAL, 'Pushing to remote...')

remote = run('git remote get-url origin', capture=True)

if not remote:
    print('  WARN No remote configured')
    print('')
    print('  To add remote and push:')
    print('    git remote add origin <YOUR_REPO_URL>')
    print('    git push -u origin main')
else:
    branch = run('git branch --show-current', capture=True).strip() or 'main'
    print('  Branch: {}'.format(branch))
    print('  Remote: {}'.format(remote))
    print('')
    print('  Pushing...')

    push_result = run('git push -u origin {}'.format(branch))

    if push_result.returncode == 0:
        print('  OK Pushed successfully!')
    else:
        print('')
        print('  WARN Push failed. Trying pull --rebase...')
        pull_result = run('git pull --rebase origin {}'.format(branch))
        if pull_result.returncode == 0:
            push_retry = run('git push origin {}'.format(branch))
            if push_retry.returncode == 0:
                print('  OK Pushed after rebase!')
            else:
                print('  FAIL Push still failed.')
                print('    git pull --rebase origin {}'.format(branch))
                print('    git push origin {}'.format(branch))


# ============================================================
#  Summary
# ============================================================
print('')
print('=' * 55)
print('  Git Operations Complete!')
print('=' * 55)
print('')

last_commit = run(
    'git log -1 --pretty=format:"%h|%an|%ad|%s" --date=format:"%Y-%m-%d %H:%M"',
    capture=True
)

if last_commit and '|' in last_commit:
    parts = last_commit.split('|')
    if len(parts) >= 4:
        print('  Commit:  {}'.format(parts[0]))
        print('  Author:  {}'.format(parts[1]))
        print('  Date:    {}'.format(parts[2]))
        print('  Message: {}'.format(parts[3]))

print('')
print('  Useful commands:')
print('    git log --oneline -10')
print('    git remote -v')
print('    git status')
print('')