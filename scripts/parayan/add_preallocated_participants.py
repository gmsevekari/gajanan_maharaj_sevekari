import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import json
import os
import re
import sys
from datetime import datetime

# 1. Initialize Firebase App
if not firebase_admin._apps:
    cred = credentials.Certificate('serviceAccountKey.json') 
    firebase_admin.initialize_app(cred)

# 2. Get Firestore Client
db = firestore.client()

def sanitize_phone(phone):
    """Remove non-digit characters from phone number."""
    return re.sub(r'[^\d+]', '', str(phone))

def sanitize_name(name):
    """Replace spaces with underscores for ID creation."""
    return re.sub(r'\s+', '_', str(name))

def add_participants():
    event_id = 'gajanan_gunjan-2026-04-26-threeDay'
    data_file_path = 'preallocated_participants.json'
    
    # Verify event exists
    event_ref = db.collection('parayan_events').document(event_id)
    event_doc = event_ref.get()
    
    if not event_doc.exists:
        print(f"Error: Event {event_id} not found.")
        return

    # Load data
    try:
        with open(data_file_path, 'r', encoding='utf-8') as f:
            participants = json.load(f)
    except Exception as e:
        print(f"Error loading data file: {e}")
        return

    participants_ref = event_ref.collection('participants')
    batch = db.batch()
    count = 0
    total = len(participants)
    
    print(f"Starting upload of {total} participants to event {event_id}...")

    now = datetime.now()

    for p in participants:
        # 1-based index to 0-based globalIndex
        provided_index = p.get('index')
        if provided_index is None:
            print("Error: 'index' is missing for a participant.")
            continue
            
        global_index = provided_index - 1
        group_number = (global_index // 7) + 1
        
        name = p.get('name', 'Unknown')
        phone = sanitize_phone(p.get('phone', ''))
        adhyays = p.get('adhyays', [])

        # Sanitize for doc ID
        sanitized_name = sanitize_name(name)
        # Use timestamp to ensure uniqueness if the same phone joins multiple times
        doc_id = f"ADMIN_{phone}_{sanitized_name}_{int(now.timestamp())}"
        
        member_data = {
            'name': name,
            'memberName': name,
            'phone': phone,
            'deviceId': 'ADMIN_MANUAL',
            'joinedAt': firestore.SERVER_TIMESTAMP,
            'assignedAdhyays': adhyays,
            'completions': {"1": False, "2": False, "3": False},
            'globalIndex': global_index,
            'groupNumber': group_number
        }
        
        doc_ref = participants_ref.document(doc_id)
        batch.set(doc_ref, member_data)
        
        count += 1
        # Firestore batch limit is 500
        if count % 500 == 0:
            batch.commit()
            batch = db.batch()
            print(f"Committed {count}/{total} participants...")

    # Final commit
    if count % 500 != 0:
        batch.commit()
    
    print(f"Finished! Successfully added {count} participants.")

if __name__ == "__main__":
    add_participants()
