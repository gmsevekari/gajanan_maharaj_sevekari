"""
Backfills the slots of one sign-up with the new schedule fields.

For every slot in signups/{SIGNUP_ID}/slots that has the old 'date' field
and no 'startAt' / 'endAt' yet, this adds:

    startAt   00:00 on that day, Seattle time   (Timestamp, UTC instant)
    endAt     23:59 on that day, Seattle time   (Timestamp, UTC instant)
    timezone  'America/Los_Angeles'

so the slot reads as an all-day slot on that day. The old 'date' field is
kept unless you pass --delete-date.

It only prints what it would do unless you pass --apply.

Usage:
    python3 backfill_slot_schedule.py SIGNUP_ID              # preview
    python3 backfill_slot_schedule.py SIGNUP_ID --apply      # write
    python3 backfill_slot_schedule.py SIGNUP_ID --apply --delete-date

Run it BEFORE anyone duplicates the sign-up in the app: duplicating copies
only the new fields, so a slot without them loses its date in the copy.
"""
import argparse
from datetime import datetime, timedelta, timezone
from zoneinfo import ZoneInfo

import firebase_admin
from firebase_admin import credentials, firestore

SEATTLE_TZ_NAME = 'America/Los_Angeles'
SEATTLE_TZ = ZoneInfo(SEATTLE_TZ_NAME)

# 1. Initialize Firebase App
# Replace 'serviceAccountKey.json' with the path to your actual file
if not firebase_admin._apps:
    cred = credentials.Certificate('serviceAccountKey.json')
    firebase_admin.initialize_app(cred)

# 2. Get Firestore Client
db = firestore.client()


def seattle_day_bounds(date_value):
    """The UTC instants of 00:00 and 23:59 Seattle time on the Seattle
    calendar day that [date_value] (a datetime from Firestore) falls on."""
    day = date_value.astimezone(SEATTLE_TZ).date()
    start = datetime(day.year, day.month, day.day, 0, 0, tzinfo=SEATTLE_TZ)
    end = datetime(day.year, day.month, day.day, 23, 59, tzinfo=SEATTLE_TZ)
    return start.astimezone(timezone.utc), end.astimezone(timezone.utc)


def backfill_slot_schedule(signup_id, apply=False, delete_date=False):
    signup_ref = db.collection('signups').document(signup_id)
    signup = signup_ref.get()
    if not signup.exists:
        print(f"❌ No sign-up with id '{signup_id}'.")
        return

    title = (signup.to_dict() or {}).get('titleEn', signup_id)
    print(f"Sign-up: {title} ({signup_id})")
    print('Mode:   ' + ('APPLY' if apply else 'PREVIEW (nothing is written)'))
    print()

    updated = skipped = 0
    for slot in signup_ref.collection('slots').stream():
        data = slot.to_dict()
        label = data.get('labelEn') or slot.id

        if data.get('startAt') and data.get('endAt'):
            print(f"  [SKIPPED] {label}: already has startAt / endAt")
            skipped += 1
            continue
        if not data.get('date'):
            print(f"  [SKIPPED] {label}: no 'date' field to convert")
            skipped += 1
            continue

        start, end = seattle_day_bounds(data['date'])
        update = {'startAt': start, 'endAt': end, 'timezone': SEATTLE_TZ_NAME}
        if delete_date:
            update['date'] = firestore.DELETE_FIELD

        print(
            f"  [{'UPDATED' if apply else 'WOULD UPDATE'}] {label}: "
            f"{start:%Y-%m-%d %H:%M}Z -> {end:%Y-%m-%d %H:%M}Z "
            f"({start.astimezone(SEATTLE_TZ):%a %b %d} Seattle)"
        )
        if apply:
            slot.reference.update(update)
        updated += 1

    verb = 'Updated' if apply else 'Would update'
    print(f"\n✅ {verb} {updated} slot(s), skipped {skipped}.")
    if not apply and updated:
        print('Check the dates above, then re-run with --apply.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    parser.add_argument('signup_id', help='Document id of the sign-up')
    parser.add_argument('--apply', action='store_true',
                        help='write the changes (default: preview only)')
    parser.add_argument('--delete-date', action='store_true',
                        help="also remove the old 'date' field")
    args = parser.parse_args()
    backfill_slot_schedule(args.signup_id, args.apply, args.delete_date)
