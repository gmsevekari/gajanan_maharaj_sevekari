import firebase_admin
from firebase_admin import credentials, firestore
import json

if not firebase_admin._apps:
    cred = credentials.Certificate('serviceAccountKey.json')
    firebase_admin.initialize_app(cred)

db = firestore.client()

# A helper to convert Firestore Datetime objects to strings for JSON saving
class FirestoreEncoder(json.JSONEncoder):
    def default(self, obj):
        try:
            return str(obj)
        except Exception:
            return super().default(obj)

def backup_parayan_events():
    events_ref = db.collection('parayan_events')
    events = events_ref.stream()
    
    backup_data = {}

    for event in events:
        event_dict = event.to_dict()
        event_id = event.id
        
        # Fetch the nested participants subcollection for this specific event
        participants_ref = events_ref.document(event_id).collection('participants')
        participants = participants_ref.stream()
        
        participants_dict = {}
        for participant in participants:
            participants_dict[participant.id] = participant.to_dict()
            
        # Attach participants to the main event dictionary
        event_dict['participants'] = participants_dict
        backup_data[event_id] = event_dict

    # Save to a local JSON file
    with open('parayan_backup.json', 'w', encoding='utf-8') as f:
        json.dump(backup_data, f, cls=FirestoreEncoder, ensure_ascii=False, indent=4)
        
    print("Backup complete! Saved to parayan_backup.json")

if __name__ == "__main__":
    backup_parayan_events()