import firebase_admin
from firebase_admin import credentials, firestore
import uuid
import sys

# 1. Initialize Firebase App
# Replace 'serviceAccountKey.json' with the path to your actual file
if not firebase_admin._apps:
    cred = credentials.Certificate('serviceAccountKey.json') 
    firebase_admin.initialize_app(cred)

# 2. Get Firestore Client
db = firestore.client()

def main():
    print("Initializing Firebase Admin SDK...")

    events_ref = db.collection('parayan_events')
    docs = events_ref.stream()

    updated_count = 0
    print("\nScanning 'parayan_events' collection for missing join codes...")

    for doc in docs:
        event_dict = doc.to_dict()
        if 'joinCode' not in event_dict or not event_dict['joinCode']:
            # Generate a 6-character uppercase alphanumeric code
            new_code = str(uuid.uuid4()).split('-')[0][:6].upper()
            events_ref.document(doc.id).update({'joinCode': new_code})
            print(f"  [UPDATED] Event '{doc.id}' -> New Join Code: {new_code}")
            updated_count += 1
        else:
            print(f"  [SKIPPED] Event '{doc.id}' already has a Join Code: {event_dict['joinCode']}")

    print(f"\nDone! Successfully generated and backfilled join codes for {updated_count} parayan events.")

if __name__ == '__main__':
    main()
