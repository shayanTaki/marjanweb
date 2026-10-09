# -*- coding: utf-8 -*-
r"""
Seed data for Marjan Aram Clinic.
Persian text is written as unicode escapes for cross-platform safety.
"""
import sys
from datetime import time
from django.core.management.base import BaseCommand
from django.db import transaction

from accounts.models import CustomUser
from services.models import ServiceCategory, Service, Package
from appointments.models import Staff, WorkingHours


# ============================================================
#  Persian strings (unicode escapes - single backslash)
# ============================================================

# Names
F_MARJAN     = "\u0645\u0631\u062c\u0627\u0646"
L_ARAM       = "\u0622\u0631\u0627\u0645"

# Category names
CAT_FAMILY   = "\u0645\u0634\u0627\u0648\u0631\u0647 \u062e\u0627\u0646\u0648\u0627\u062f\u0647"
CAT_INDIV    = "\u0645\u0634\u0627\u0648\u0631\u0647 \u0641\u0631\u062f\u06cc"
CAT_PRE      = "\u0645\u0634\u0627\u0648\u0631\u0647 \u0642\u0628\u0644 \u0627\u0632 \u0627\u0632\u062f\u0648\u0627\u062c"
CAT_CHILD    = "\u0645\u0634\u0627\u0648\u0631\u0647 \u06a9\u0648\u062f\u06a9 \u0648 \u0646\u0648\u062c\u0648\u0627\u0646"
CAT_CRISIS   = "\u0645\u0634\u0627\u0648\u0631\u0647 \u0628\u062d\u0631\u0627\u0646 \u0648 \u0633\u0648\u06af"

# Category descriptions
D_FAMILY     = "\u0645\u0634\u0627\u0648\u0631\u0647 \u062a\u062e\u0635\u0635\u06cc \u0628\u0631\u0627\u06cc \u0632\u0648\u062c\u06cc\u0646 \u0648 \u0631\u0648\u0627\u0628\u0637 \u062e\u0627\u0646\u0648\u0627\u062f\u06af\u06cc"
D_INDIV      = "\u062f\u0631\u0645\u0627\u0646 \u0627\u0641\u0633\u0631\u062f\u06af\u06cc\u060c \u0627\u0636\u0637\u0631\u0627\u0628 \u0648 \u0648\u0633\u0648\u0627\u0633"
D_PRE        = "\u0622\u0645\u0627\u062f\u0647\u200c\u0633\u0627\u0632\u06cc \u0648 \u0627\u0631\u0632\u06cc\u0627\u0628\u06cc \u0628\u0631\u0627\u06cc \u0632\u0646\u062f\u06af\u06cc \u0645\u0634\u062a\u0631\u06a9"
D_CHILD      = "\u062f\u0631\u0645\u0627\u0646 \u0628\u06cc\u0634\u200c\u0641\u0639\u0627\u0644\u06cc\u060c \u0627\u0648\u062a\u06cc\u0633\u0645 \u0648 \u0645\u0634\u06a9\u0644\u0627\u062a \u062a\u062d\u0635\u06cc\u0644\u06cc"
D_CRISIS     = "\u0645\u062f\u06cc\u0631\u06cc\u062a \u0628\u062d\u0631\u0627\u0646\u200c\u0647\u0627\u06cc \u0632\u0646\u062f\u06af\u06cc\u060c \u0633\u0648\u06af \u0648 \u0627\u0632 \u062f\u0633\u062a \u062f\u0627\u062f\u0646"

# Service names
S_COUPLES    = "\u0645\u0634\u0627\u0648\u0631\u0647 \u0632\u0648\u062c\u06cc\u0646"
S_DIVORCE    = "\u0645\u0634\u0627\u0648\u0631\u0647 \u0637\u0644\u0627\u0642"
S_DEPRESS    = "\u062f\u0631\u0645\u0627\u0646 \u0627\u0641\u0633\u0631\u062f\u06af\u06cc"
S_ANXIETY    = "\u062f\u0631\u0645\u0627\u0646 \u0627\u0636\u0637\u0631\u0627\u0628"
S_OCD        = "\u062f\u0631\u0645\u0627\u0646 \u0648\u0633\u0648\u0627\u0633"
S_PRE        = "\u0645\u0634\u0627\u0648\u0631\u0647 \u067e\u06cc\u0634 \u0627\u0632 \u0627\u0632\u062f\u0648\u0627\u062c"
S_CHILD      = "\u0645\u0634\u0627\u0648\u0631\u0647 \u06a9\u0648\u062f\u06a9 \u0648 \u0646\u0648\u062c\u0648\u0627\u0646"
S_ACADEMIC   = "\u0645\u0634\u0627\u0648\u0631\u0647 \u062a\u062d\u0635\u06cc\u0644\u06cc"
S_GRIEF      = "\u0645\u0634\u0627\u0648\u0631\u0647 \u0628\u062d\u0631\u0627\u0646 \u0648 \u0633\u0648\u06af"

# Short descriptions
SH_COUPLES   = "\u062d\u0644 \u062a\u0639\u0627\u0631\u0636\u0627\u062a \u0632\u0646\u0627\u0634\u0648\u06cc\u06cc \u0648 \u0628\u0647\u0628\u0648\u062f \u0631\u0627\u0628\u0637\u0647 \u0639\u0627\u0637\u0641\u06cc"
SH_DIVORCE   = "\u0645\u0634\u0627\u0648\u0631\u0647 \u062a\u062e\u0635\u0635\u06cc \u0628\u0631\u0627\u06cc \u0632\u0648\u062c\u06cc\u0646 \u062f\u0631 \u0622\u0633\u062a\u0627\u0646\u0647 \u0637\u0644\u0627\u0642"
SH_DEPRESS   = "\u062f\u0631\u0645\u0627\u0646 \u062a\u062e\u0635\u0635\u06cc \u0627\u0641\u0633\u0631\u062f\u06af\u06cc \u0628\u0627 \u0631\u0648\u06cc\u06a9\u0631\u062f \u0639\u0644\u0645\u06cc"
SH_ANXIETY   = "\u063a\u0644\u0628\u0647 \u0628\u0631 \u0627\u0636\u0637\u0631\u0627\u0628\u060c \u0627\u0633\u062a\u0631\u0633 \u0648 \u062d\u0645\u0644\u0627\u062a \u067e\u0627\u0646\u06cc\u06a9"
SH_OCD       = "\u062f\u0631\u0645\u0627\u0646 \u0627\u062e\u062a\u0644\u0627\u0644 \u0648\u0633\u0648\u0627\u0633 \u0641\u06a9\u0631\u06cc \u0648 \u0639\u0645\u0644\u06cc"
SH_PRE       = "\u0627\u0631\u0632\u06cc\u0627\u0628\u06cc \u0648 \u0622\u0645\u0627\u062f\u0647\u200c\u0633\u0627\u0632\u06cc \u0628\u0631\u0627\u06cc \u0627\u0632\u062f\u0648\u0627\u062c"
SH_CHILD     = "\u062f\u0631\u0645\u0627\u0646 \u0645\u0634\u06a9\u0644\u0627\u062a \u0631\u0641\u062a\u0627\u0631\u06cc \u06a9\u0648\u062f\u06a9\u0627\u0646 \u0648 \u0646\u0648\u062c\u0648\u0627\u0646\u0627\u0646"
SH_ACADEMIC  = "\u0647\u062f\u0627\u06cc\u062a \u062a\u062d\u0635\u06cc\u0644\u06cc \u0648 \u0631\u0641\u0639 \u0645\u0634\u06a9\u0644\u0627\u062a \u06cc\u0627\u062f\u06af\u06cc\u0631\u06cc"
SH_GRIEF     = "\u0647\u0645\u0631\u0627\u0647\u06cc \u062f\u0631 \u0645\u0648\u0627\u062c\u0647\u0647 \u0628\u0627 \u0628\u062d\u0631\u0627\u0646\u200c\u0647\u0627 \u0648 \u0641\u0642\u062f\u0627\u0646"

# Full descriptions (short version)
FD_COUPLES   = "\u062c\u0644\u0633\u0627\u062a \u0645\u0634\u0627\u0648\u0631\u0647 \u0632\u0648\u062c\u06cc\u0646 \u0628\u0627 \u0631\u0648\u06cc\u06a9\u0631\u062f \u0634\u0646\u0627\u062e\u062a\u06cc-\u0631\u0641\u062a\u0627\u0631\u06cc \u0628\u0631\u0627\u06cc \u062d\u0644 \u062a\u0639\u0627\u0631\u0636\u0627\u062a \u0648 \u0627\u0641\u0632\u0627\u06cc\u0634 \u0635\u0645\u06cc\u0645\u06cc\u062a."
FD_DIVORCE   = "\u0645\u0634\u0627\u0648\u0631\u0647 \u062a\u062e\u0635\u0635\u06cc \u0628\u0631\u0627\u06cc \u0632\u0648\u062c\u06cc\u0646\u06cc \u06a9\u0647 \u062f\u0631 \u0622\u0633\u062a\u0627\u0646\u0647 \u062c\u062f\u0627\u06cc\u06cc \u0647\u0633\u062a\u0646\u062f."
FD_DEPRESS   = "\u062f\u0631\u0645\u0627\u0646 \u0627\u0641\u0633\u0631\u062f\u06af\u06cc \u0628\u0627 \u0631\u0648\u06cc\u06a9\u0631\u062f \u0634\u0646\u0627\u062e\u062a\u06cc-\u0631\u0641\u062a\u0627\u0631\u06cc \u0648 \u0637\u0631\u062d\u0648\u0627\u0631\u0647 \u062f\u0631\u0645\u0627\u0646\u06cc."
FD_ANXIETY   = "\u062f\u0631\u0645\u0627\u0646 \u0627\u062e\u062a\u0644\u0627\u0644\u0627\u062a \u0627\u0636\u0637\u0631\u0627\u0628\u06cc \u0634\u0627\u0645\u0644 \u0627\u0636\u0637\u0631\u0627\u0628 \u0641\u0631\u0627\u06af\u06cc\u0631 \u0648 \u062d\u0645\u0644\u0627\u062a \u067e\u0627\u0646\u06cc\u06a9."
FD_OCD       = "\u062f\u0631\u0645\u0627\u0646 \u062a\u062e\u0635\u0635\u06cc \u0648\u0633\u0648\u0627\u0633 \u0628\u0627 \u0631\u0648\u06cc\u06a9\u0631\u062f \u0645\u0648\u0627\u062c\u0647\u0647 \u0648 \u062c\u0644\u0648\u06af\u06cc\u0631\u06cc \u0627\u0632 \u067e\u0627\u0633\u062e."
FD_PRE       = "\u0627\u0631\u0632\u06cc\u0627\u0628\u06cc \u0631\u0648\u0627\u0646\u0634\u0646\u0627\u062e\u062a\u06cc \u0648 \u0622\u0645\u0627\u062f\u0647\u200c\u0633\u0627\u0632\u06cc \u0628\u0631\u0627\u06cc \u0632\u0646\u062f\u06af\u06cc \u0645\u0634\u062a\u0631\u06a9."
FD_CHILD     = "\u0645\u0634\u0627\u0648\u0631\u0647 \u062a\u062e\u0635\u0635\u06cc \u0628\u0631\u0627\u06cc \u06a9\u0648\u062f\u06a9\u0627\u0646 \u0648 \u0646\u0648\u062c\u0648\u0627\u0646\u0627\u0646 \u0628\u0627 \u0645\u0634\u06a9\u0644\u0627\u062a \u0631\u0641\u062a\u0627\u0631\u06cc."
FD_ACADEMIC  = "\u0645\u0634\u0627\u0648\u0631\u0647 \u062a\u062d\u0635\u06cc\u0644\u06cc \u0634\u0627\u0645\u0644 \u0627\u0646\u062a\u062e\u0627\u0628 \u0631\u0634\u062a\u0647 \u0648 \u0628\u0631\u0646\u0627\u0645\u0647\u200c\u0631\u06cc\u0632\u06cc \u062f\u0631\u0633\u06cc."
FD_GRIEF     = "\u0645\u0634\u0627\u0648\u0631\u0647 \u062a\u062e\u0635\u0635\u06cc \u0628\u0631\u0627\u06cc \u0627\u0641\u0631\u0627\u062f\u06cc \u06a9\u0647 \u0628\u0627 \u0628\u062d\u0631\u0627\u0646\u200c\u0647\u0627\u06cc \u0632\u0646\u062f\u06af\u06cc \u0645\u0648\u0627\u062c\u0647 \u0634\u062f\u0647\u200c\u0627\u0646\u062f."

# Bio
BIO = ("\u06a9\u0627\u0631\u0634\u0646\u0627\u0633 \u0627\u0631\u0634\u062f \u0631\u0648\u0627\u0646\u0634\u0646\u0627\u0633\u06cc \u0628\u0627\u0644\u06cc\u0646\u06cc\u060c "
       "\u0631\u0648\u0627\u0646\u0634\u0646\u0627\u0633 \u062f\u0627\u062f\u06af\u0627\u0647 \u0627\u0637\u0641\u0627\u0644 \u0648 \u0645\u0631\u06a9\u0632 \u0637\u0644\u0627\u0642 \u062f\u0627\u062f\u06af\u0633\u062a\u0631\u06cc. "
       "\u062f\u0631\u0645\u0627\u0646 \u0627\u062e\u062a\u0644\u0627\u0644\u0627\u062a \u0627\u0641\u0633\u0631\u062f\u06af\u06cc\u060c \u0627\u0636\u0637\u0631\u0627\u0628\u060c "
       "\u0645\u0634\u0627\u0648\u0631\u0647 \u062a\u062d\u0635\u06cc\u0644\u06cc\u060c \u067e\u06cc\u0634 \u0627\u0632 \u0627\u0632\u062f\u0648\u0627\u062c\u060c \u0632\u0648\u062c \u0648 \u0646\u0648\u062c\u0648\u0627\u0646.")

# Package names
PKG_INDIV    = "\u0628\u0633\u062a\u0647 \u06f4 \u062c\u0644\u0633\u0647 \u0645\u0634\u0627\u0648\u0631\u0647 \u0641\u0631\u062f\u06cc"
PKG_COUPLES  = "\u0628\u0633\u062a\u0647 \u06f4 \u062c\u0644\u0633\u0647 \u0645\u0634\u0627\u0648\u0631\u0647 \u0632\u0648\u062c\u06cc\u0646"
PKG_PRE      = "\u0628\u0633\u062a\u0647 \u0645\u0634\u0627\u0648\u0631\u0647 \u067e\u06cc\u0634 \u0627\u0632 \u0627\u0632\u062f\u0648\u0627\u062c"

PKG_INDIV_D  = "\u06f4 \u062c\u0644\u0633\u0647 \u0645\u0634\u0627\u0648\u0631\u0647 \u0641\u0631\u062f\u06cc \u0628\u0627 \u06f1\u06f5\u066a \u062a\u062e\u0641\u06cc\u0641"
PKG_COUP_D   = "\u06f4 \u062c\u0644\u0633\u0647 \u0645\u0634\u0627\u0648\u0631\u0647 \u0632\u0648\u062c\u06cc\u0646 \u0628\u0627 \u06f2\u06f0\u066a \u062a\u062e\u0641\u06cc\u0641"
PKG_PRE_D    = "\u06f3 \u062c\u0644\u0633\u0647 \u0627\u0631\u0632\u06cc\u0627\u0628\u06cc \u0628\u0627 \u06f1\u06f0\u066a \u062a\u062e\u0641\u06cc\u0641"

# Weekday names
WD = [
    "\u0634\u0646\u0628\u0647",
    "\u06cc\u06a9\u0634\u0646\u0628\u0647",
    "\u062f\u0648\u0634\u0646\u0628\u0647",
    "\u0633\u0647\u200c\u0634\u0646\u0628\u0647",
    "\u0686\u0647\u0627\u0631\u0634\u0646\u0628\u0647",
    "\u067e\u0646\u062c\u200c\u0634\u0646\u0628\u0647",
    "\u062c\u0645\u0639\u0647",
]


# ============================================================
#  Command
# ============================================================

class Command(BaseCommand):
    help = 'Seed data for Marjan Aram Clinic'

    def handle(self, *args, **options):
        self.stdout.write('=' * 55)
        self.stdout.write('  Seed Data - Marjan Aram')
        self.stdout.write('=' * 55)

        with transaction.atomic():
            user = self._create_doctor()
            staff = self._create_staff(user)
            self._create_working_hours(staff)
            cats = self._create_categories()
            self._create_services(cats)
            self._create_packages()

        self.stdout.write('')
        self.stdout.write('=' * 55)
        self.stdout.write('  [OK] Done!')
        self.stdout.write('=' * 55)
        self.stdout.write(f'  Categories: {ServiceCategory.objects.count()}')
        self.stdout.write(f'  Services:   {Service.objects.count()}')
        self.stdout.write(f'  Packages:   {Package.objects.count()}')
        self.stdout.write('=' * 55)
        self.stdout.write('  Login: marjan_aram / Marjan@1404')

    # --------------------------------------------------------
    def _create_doctor(self):
        self.stdout.write('\n[1/6] Doctor user...')
        user, created = CustomUser.objects.get_or_create(
            username='marjan_aram',
            defaults={
                'first_name': F_MARJAN,
                'last_name': L_ARAM,
                'phone_number': '09016828512',
                'email': 'info@marjanaram.ir',
                'is_doctor': True,
                'is_staff': True,
            }
        )
        user.first_name = F_MARJAN
        user.last_name = L_ARAM
        user.is_doctor = True
        if created:
            user.set_password('Marjan@1404')
        user.save()
        self.stdout.write(f'  [OK] {user.username}')
        return user

    def _create_staff(self, user):
        self.stdout.write('\n[2/6] Staff profile...')
        staff, _ = Staff.objects.get_or_create(
            user=user,
            defaults={'bio': BIO, 'experience_years': 15, 'is_available': True, 'order': 1}
        )
        staff.bio = BIO
        staff.experience_years = 15
        staff.is_available = True
        staff.save()
        self.stdout.write('  [OK]')
        return staff

    def _create_working_hours(self, staff):
        self.stdout.write('\n[3/6] Working hours (10:00-19:00)...')
        start = time(10, 0)
        end = time(19, 0)
        for code in range(7):
            wh, created = WorkingHours.objects.get_or_create(
                staff=staff, weekday=code,
                defaults={'start_time': start, 'end_time': end, 'is_active': True}
            )
            wh.start_time = start
            wh.end_time = end
            wh.is_active = True
            wh.save()
        self.stdout.write(f'  [OK] 7 days')

    def _create_categories(self):
        self.stdout.write('\n[4/6] Categories...')
        data = [
            {'name': CAT_FAMILY, 'slug': 'family-counseling',
             'icon': 'bi-people-fill', 'description': D_FAMILY, 'order': 1},
            {'name': CAT_INDIV,  'slug': 'individual-counseling',
             'icon': 'bi-person-heart', 'description': D_INDIV, 'order': 2},
            {'name': CAT_PRE,    'slug': 'premarital-counseling',
             'icon': 'bi-heart-fill', 'description': D_PRE, 'order': 3},
            {'name': CAT_CHILD,  'slug': 'child-counseling',
             'icon': 'bi-emoji-smile', 'description': D_CHILD, 'order': 4},
            {'name': CAT_CRISIS, 'slug': 'crisis-counseling',
             'icon': 'bi-shield-heart', 'description': D_CRISIS, 'order': 5},
        ]
        cats = []
        for item in data:
            cat, _ = ServiceCategory.objects.update_or_create(
                slug=item['slug'], defaults=item
            )
            cats.append(cat)
            self.stdout.write(f'  [OK] {cat.slug}')
        return cats

    def _create_services(self, cats):
        self.stdout.write('\n[5/6] Services...')
        data = [
            {'category': cats[0], 'name': S_COUPLES, 'slug': 'couples-counseling',
             'short_description': SH_COUPLES, 'description': FD_COUPLES,
             'duration': 60, 'price': 500000, 'is_featured': True, 'order': 1},
            {'category': cats[0], 'name': S_DIVORCE, 'slug': 'divorce-counseling',
             'short_description': SH_DIVORCE, 'description': FD_DIVORCE,
             'duration': 60, 'price': 550000, 'is_featured': True, 'order': 2},
            {'category': cats[1], 'name': S_DEPRESS, 'slug': 'depression-treatment',
             'short_description': SH_DEPRESS, 'description': FD_DEPRESS,
             'duration': 45, 'price': 450000, 'is_featured': True, 'order': 3},
            {'category': cats[1], 'name': S_ANXIETY, 'slug': 'anxiety-treatment',
             'short_description': SH_ANXIETY, 'description': FD_ANXIETY,
             'duration': 45, 'price': 450000, 'is_featured': False, 'order': 4},
            {'category': cats[1], 'name': S_OCD, 'slug': 'ocd-treatment',
             'short_description': SH_OCD, 'description': FD_OCD,
             'duration': 50, 'price': 480000, 'is_featured': False, 'order': 5},
            {'category': cats[2], 'name': S_PRE, 'slug': 'premarital-counseling',
             'short_description': SH_PRE, 'description': FD_PRE,
             'duration': 60, 'price': 500000, 'is_featured': True, 'order': 6},
            {'category': cats[3], 'name': S_CHILD, 'slug': 'child-adolescent-counseling',
             'short_description': SH_CHILD, 'description': FD_CHILD,
             'duration': 45, 'price': 450000, 'is_featured': True, 'order': 7},
            {'category': cats[3], 'name': S_ACADEMIC, 'slug': 'academic-counseling',
             'short_description': SH_ACADEMIC, 'description': FD_ACADEMIC,
             'duration': 45, 'price': 400000, 'is_featured': False, 'order': 8},
            {'category': cats[4], 'name': S_GRIEF, 'slug': 'grief-counseling',
             'short_description': SH_GRIEF, 'description': FD_GRIEF,
             'duration': 60, 'price': 550000, 'is_featured': False, 'order': 9},
        ]
        for item in data:
            svc, _ = Service.objects.update_or_create(slug=item['slug'], defaults=item)
            self.stdout.write(f'  [OK] {svc.slug} - {svc.price:,} T')

    def _create_packages(self):
        self.stdout.write('\n[6/6] Packages...')
        data = [
            {'name': PKG_INDIV, 'slug': 'individual-4-sessions',
             'short_description': PKG_INDIV_D,
             'description': PKG_INDIV_D, 'features': '',
             'price': 1530000, 'old_price': 1800000, 'duration_days': 60,
             'is_featured': True, 'order': 1},
            {'name': PKG_COUPLES, 'slug': 'couples-4-sessions',
             'short_description': PKG_COUP_D,
             'description': PKG_COUP_D, 'features': '',
             'price': 1600000, 'old_price': 2000000, 'duration_days': 60,
             'is_featured': True, 'order': 2},
            {'name': PKG_PRE, 'slug': 'premarital-package',
             'short_description': PKG_PRE_D,
             'description': PKG_PRE_D, 'features': '',
             'price': 1350000, 'old_price': 1500000, 'duration_days': 45,
             'is_featured': False, 'order': 3},
        ]
        for item in data:
            pkg, _ = Package.objects.update_or_create(slug=item['slug'], defaults=item)
            self.stdout.write(f'  [OK] {pkg.slug} - {pkg.price:,} T')
