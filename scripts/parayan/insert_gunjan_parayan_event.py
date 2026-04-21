import firebase_admin
import uuid
from firebase_admin import credentials, firestore
from datetime import datetime, timedelta, time
from zoneinfo import ZoneInfo

# 1. Initialize Firebase App
# Replace 'serviceAccountKey.json' with the path to your actual file
if not firebase_admin._apps:
    cred = credentials.Certificate('serviceAccountKey.json') 
    firebase_admin.initialize_app(cred)

# 2. Get Firestore Client
db = firestore.client()

def insert_parayan_event():
    # Define the collection name
    collection_name = 'parayan_events'

    india_tz = ZoneInfo("Asia/Kolkata")
    start_dt = datetime(2026, 4, 26, 0, 0, 0, tzinfo=india_tz)
    

    groupId = "gajanan_gunjan"
    event_type="threeDay"
    
    title_en = "Dashami Ekadashi and Dwadashi Parayan"
    title_mr = "दशमी एकादशी आणि द्वादशी पारायण"
    
    desc_en = "Parayan of Gajanan Vijay Granth on the occasion of Dashami Ekadashi and Dwadashi"
    desc_mr = "दशमी एकादशी आणि द्वादशीच्या प्रसंगी गजानन विजय ग्रंथाचे पारायण"

    end_dt = start_dt + timedelta(days=2)
    end_dt = end_dt.replace(hour=23, minute=59, second=59)

    join_code = str(uuid.uuid4())[:6].upper()

    event = {
        "title_en": title_en,
        "title_mr": title_mr,
        "description_en": desc_en,
        "description_mr": desc_mr,
        "type": event_type,
        "startDate": start_dt,
        "endDate": end_dt,
        "status": "upcoming",
        "reminderTimes": ["13:00", "16:00", "19:00"],
        "createdAt": datetime.now(india_tz),
        "joinCode": join_code,
        "groupId": groupId
    }

    # 3. Custom Doc ID using groupId, startDate and type
    # Example: gajanan_gunjan-2026-03-20-threeDay
    custom_doc_id = f"{groupId}-{start_dt.strftime('%Y-%m-%d')}-{event_type}"

    print(f"Inserting {event_type} event with ID: {custom_doc_id}...")
    db.collection(collection_name).document(custom_doc_id).set(event)
    print("Insertion complete!")

if __name__ == "__main__":
    try:
        insert_parayan_event()
    except Exception as e:
        print(f"Error inserting events: {e}")