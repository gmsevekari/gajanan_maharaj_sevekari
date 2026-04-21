import firebase_admin
from firebase_admin import credentials, firestore

# 1. Initialize Firebase App
# Replace 'serviceAccountKey.json' with the path to your actual file
if not firebase_admin._apps:
    cred = credentials.Certificate('serviceAccountKey.json') 
    firebase_admin.initialize_app(cred)

# 2. Get Firestore Client
db = firestore.client()

def backfill_parayan_groups(default_group_id='gajanan_maharaj_seattle'):
    """
    Adds a mandatory 'groupId' field to all existing documents 
    in the 'parayan_events' collection.
    """
    events_ref = db.collection('parayan_events')
    docs = events_ref.stream()
    
    count = 0
    for doc in docs:
        data = doc.to_dict()
        # Check if groupId is already present
        if 'groupId' not in data or not data['groupId']:
            print(f"Updating Event: {data.get('title_en', doc.id)} ...")
            events_ref.document(doc.id).update({
                'groupId': default_group_id
            })
            count += 1
            
    print(f"\n✅ Migration complete. Updated {count} documents.")

if __name__ == "__main__":
    # You can change the default_group_id to something else if needed
    backfill_parayan_groups(default_group_id='gajanan_maharaj_seattle')
