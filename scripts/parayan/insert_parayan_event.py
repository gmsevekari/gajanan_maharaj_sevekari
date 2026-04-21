import firebase_admin
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

    timezone = ZoneInfo("America/Los_Angeles")

    # 1. Set Start Date
    start_dt = datetime(2026, 3, 31, 0, 0, 0, tzinfo=timezone)
    event_type="threeDay"
    title_en = "3-day Parayan Test"
    title_mr = "3-दिवसीय पारायण टेस्ट"
    desc_en = "3-day Parayan Test"
    desc_mr = "3-दिवसीय पारायण टेस्ट"

    #event_type="oneDay"
    #title_en = "Hanuman Jayanti Parayan"
    #title_mr = "हनुमान जयंती पारायण"
    #desc_en = "1-Day Parayan of Gajanan Vijay Granth on the auspicious occasion of Hanuman Jayanti"
    #desc_mr = "हनुमान जयंतीच्या शुभ प्रसंगी गजानन विजय ग्रंथाचे 1-दिवसीय पारायण"

    #event_type="guruPushya"
    #title_en = "Guru Pushyamrut Yog Parayan"
    #title_mr = "गुरुपुष्यामृत योग पारायण"
    #desc_en = "1-Day Parayan of Gajanan Vijay Granth on the auspicious occasion of Guru Pushyamrut Yog"
    #desc_mr = "गुरुपुष्यामृत योगाच्या शुभ प्रसंगी गजानन विजय ग्रंथाचे 1-दिवसीय पारायण"

    # 2. Logic to set End Date based on type
    if event_type == "threeDay":
        # For 3-day, end is the 3rd day at 23:59:59
        # (Start + 2 days = 3rd day)
        end_dt = start_dt + timedelta(days=2)
        end_dt = end_dt.replace(hour=23, minute=59, second=59)
    elif event_type == "oneDay":
        end_dt = start_dt.replace(hour=23, minute=59, second=59)
    elif event_type == "guruPushya":
        # Manually set it
        end_dt = datetime(2026, 5, 21, 14, 18, 0, tzinfo=timezone)
        #end_dt = datetime(2026, 4, 24, 6, 3, 0, tzinfo=timezone)

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
        "createdAt": datetime.now(timezone)
    }

    # 3. Custom Doc ID using startDate and type
    # Example: 2026-03-20-oneDay
    custom_doc_id = f"{start_dt.strftime('%Y-%m-%d')}-{event_type}"

    print(f"Inserting {event_type} event with ID: {custom_doc_id}...")
    db.collection(collection_name).document(custom_doc_id).set(event)
    print("Insertion complete!")

if __name__ == "__main__":
    try:
        insert_parayan_event()
    except Exception as e:
        print(f"Error inserting events: {e}")