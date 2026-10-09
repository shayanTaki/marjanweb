# Marjan Aram - Psychology Clinic Website

Complete psychology counseling website with:
- Online appointment booking with Jalali calendar
- Zarinpal payment gateway
- Admin dashboard with charts
- Custom Persian admin panel

## Features

- Public pages (home, services, packages, articles)
- User authentication with phone number
- Appointment booking system
- Payment with PDF invoice
- Reviews and ratings
- Custom admin panel (Persian, dark theme)
- Modern responsive design
- 100% offline (no external CDN)

## Installation

Requirements: Python 3.10+, pip, Git

Steps:

1. Clone repository:
   git clone <repo-url>
   cd marjanaram

2. Create virtual environment:
   python -m venv venv
   source venv/bin/activate

3. Install dependencies:
   pip install -r requirements.txt

4. Setup environment:
   cp .env.example .env

5. Run migrations:
   python manage.py migrate

6. Create superuser:
   python manage.py createsuperuser

7. Seed sample data (optional):
   python manage.py seed_data

8. Run server:
   python manage.py runserver

## Default Credentials

- URL: http://127.0.0.1:8000/admin/
- Username: marjan_aram
- Password: Marjan@1404

## Main Pages

- Home: /
- Services: /services/
- Packages: /packages/
- Articles: /articles/
- About: /about/
- Contact: /contact/
- Book appointment: /appointments/book/
- My appointments: /appointments/my/
- Profile: /accounts/profile/
- Dashboard: /dashboard/
- Admin panel: /admin/

## Tech Stack

- Backend: Django 5.0
- Database: SQLite / PostgreSQL
- Frontend: Tailwind CSS, Alpine.js
- Charts: Chart.js
- Font: Vazirmatn
- Icons: Bootstrap Icons
- Payment: Zarinpal
- PDF: ReportLab
- Jalali Date: jdatetime

## License

All rights reserved for Marjan Aram (c) 1404
