import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

# 1. Initialize Firebase App
# Replace 'serviceAccountKey.json' with the path to your actual file
if not firebase_admin._apps:
    cred = credentials.Certificate('serviceAccountKey.json') 
    firebase_admin.initialize_app(cred)

# 2. Get Firestore Client
db = firestore.client()

def update_event_field():
    """
    Fetches a document, adds/updates a field in its data dictionary, 
    and saves it back to Firestore.
    """
    doc_id = '2026-12-23-16-00'
    new_key = 'event_type'
    new_value = 'specialEvent'

    doc_ref = db.collection('events').document(doc_id)
    doc = doc_ref.get()

    if doc.exists:
        try:
            # 1. Fetch the data as a dictionary
            event_data = doc.to_dict()
            
            # 2. Add or modify the field
            event_data[new_key] = new_value
            
            # 3. Save it back
            # .update() is safer as it only changes the specified fields
            # and leaves the rest of the document untouched.
            doc_ref.update({new_key: new_value})
            
            print(f"✅ Successfully updated {doc_id}. Set '{new_key}' to '{new_value}'.")
            
        except Exception as e:
            print(f"❌ Error updating document: {e}")
    else:
        print(f"❌ Document with ID '{doc_id}' does not exist.")

# Run the function
if __name__ == '__main__':
    update_event_field()