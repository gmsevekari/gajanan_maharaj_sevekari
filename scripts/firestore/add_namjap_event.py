import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime, timezone, timedelta
from zoneinfo import ZoneInfo
import random
import string
import sys
import os

# 1. Initialize Firebase App
# Replace 'serviceAccountKey.json' with the path to your actual file
if not firebase_admin._apps:
    cred = credentials.Certificate("serviceAccountKey.json")
    firebase_admin.initialize_app(cred)

# 2. Get Firestore Client
db = firestore.client()


def generate_join_code(length=6):
    """Generate a random 6-character alphanumeric join code."""
    return "".join(random.choices(string.ascii_uppercase + string.digits, k=length))


def add_namjap_event():
    # Change timezone, start_dt and end_dt as needed
    timezone = ZoneInfo("America/Los_Angeles")
    start_dt = datetime(2026, 4, 22, 0, 0, 0, tzinfo=timezone)

    # Sample Event Data
    event_data = {
        "name_en": "Test Namjap",
        "name_mr": "टेस्ट नामजप",
        "sankalp_en": "Test Namjap: Completion of 108 chants to Gan Gan Ganat Bote",
        "sankalp_mr": "टेस्ट नामजप: गण गण गणात बोते चा १०८ वेळा नामजप",
        "targetCount": 108,
        "totalCount": 0,
        "mantra": "गण गण गणात बोते",
        "joinCode": generate_join_code(),
        "status": "upcoming",  # 'upcoming', 'ongoing', 'completed'
        "groupId": "gajanan_maharaj_seattle",
        "startDate": start_dt,
        "endDate": start_dt + timedelta(days=7),
        "createdAt": datetime.now(timezone),
    }

    # Create custom document ID: groupId + startDate + targetCount
    date_str = start_dt.strftime("%Y%m%d")
    doc_id = f"{event_data['groupId']}_{date_str}_{event_data['targetCount']}"

    print(f"Adding Namjap Event with ID: {doc_id}...")

    # Add to Firestore collection
    doc_ref = db.collection("group_namjap_events").document(doc_id)
    doc_ref.set(event_data)

    print(f"✅ Successfully added Namjap event!")
    print(f"   Document ID: {doc_ref.id}")
    print(f"   Join Code: {event_data['joinCode']}")
    print(f"   Status: {event_data['status']}")
    print(f"   Mantra: {event_data['mantra']}")


if __name__ == "__main__":
    add_namjap_event()
