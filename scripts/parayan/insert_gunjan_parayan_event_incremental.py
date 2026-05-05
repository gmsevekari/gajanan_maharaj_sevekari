import firebase_admin
import uuid
from firebase_admin import credentials, firestore
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

# 1. Initialize Firebase App
# NOTE: Ensure serviceAccountKey.json is in the same directory where you run this script, 
# or update the path below.
if not firebase_admin._apps:
    try:
        cred = credentials.Certificate("serviceAccountKey.json")
        firebase_admin.initialize_app(cred)
    except Exception as e:
        print(f"Error initializing Firebase: {e}")
        print("Please ensure 'serviceAccountKey.json' is present in the current directory.")
        exit(1)

# 2. Get Firestore Client
db = firestore.client()

def get_next_adhyays(current_adhyays):
    """
    Given a list of 3 adhyays, return the next 3 adhyays in sequence (1-21 cyclic).
    Example: [1, 2, 3] -> [4, 5, 6]
    Example: [20, 21, 1] -> [2, 3, 4]
    """
    if not current_adhyays:
        return [1, 2, 3]
    
    # Logic: find the value v in current_adhyays such that its cyclic successor is NOT in the list.
    # That v is the 'end' of the current sequence.
    end_val = None
    for v in current_adhyays:
        next_v = (v % 21) + 1
        if next_v not in current_adhyays:
            end_val = v
            break
    
    if end_val is None:
        end_val = max(current_adhyays)
        
    next_start = (end_val % 21) + 1
    return [(next_start + i - 1) % 21 + 1 for i in range(3)]

def insert_incremental_event():
    # --- CONFIGURATION ---
    # Update these values for each new event creation
    LAST_EVENT_ID = "gajanan_gunjan-2026-04-26-threeDay"  # The ID of the previous parayan
    NEW_START_DATE_STR = "2026-05-24" # YYYY-MM-DD
    # ---------------------

    collection_name = "parayan_events"
    india_tz = ZoneInfo("Asia/Kolkata")
    
    # Parse new start date
    try:
        y, m, d = map(int, NEW_START_DATE_STR.split('-'))
        start_dt = datetime(y, m, d, 0, 0, 0, tzinfo=india_tz)
    except ValueError:
        print(f"Invalid date format: {NEW_START_DATE_STR}. Use YYYY-MM-DD.")
        return

    groupId = "gajanan_gunjan"
    event_type = "threeDay"

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
        "groupId": groupId,
        "timezone": "Asia/Kolkata" # Requested modification
    }

    # Custom Doc ID using groupId, startDate and type
    custom_doc_id = f"{groupId}-{start_dt.strftime('%Y-%m-%d')}-{event_type}"

    # 1. Fetch participants from last event
    print(f"Fetching participants from {LAST_EVENT_ID}...")
    old_event_ref = db.collection(collection_name).document(LAST_EVENT_ID)
    if not old_event_ref.get().exists:
        print(f"Error: Last event {LAST_EVENT_ID} not found.")
        return

    old_participants = old_event_ref.collection('participants').stream()
    
    new_participants_data = []
    for doc in old_participants:
        p = doc.to_dict()
        old_adhyays = p.get('assignedAdhyays', [])
        next_adhyays = get_next_adhyays(old_adhyays)
        
        # Construct new participant data
        new_p = {
            'name': p.get('name', 'Unknown'),
            'memberName': p.get('memberName', p.get('name', 'Unknown')),
            'phone': p.get('phone', ''),
            'deviceId': p.get('deviceId', 'ADMIN_MANUAL'), # Preserve deviceId
            'joinedAt': firestore.SERVER_TIMESTAMP,
            'assignedAdhyays': next_adhyays,
            'completions': {"1": False, "2": False, "3": False},
            'globalIndex': p.get('globalIndex', 0),
            'groupNumber': p.get('groupNumber', 1)
        }
        new_participants_data.append(new_p)

    if not new_participants_data:
        print("No participants found in the previous event. Proceeding with event creation only.")
    else:
        print(f"Found {len(new_participants_data)} participants to carry over with incremented adhyays.")

    # 2. Insert new event
    print(f"Inserting new event with ID: {custom_doc_id}...")
    db.collection(collection_name).document(custom_doc_id).set(event)
    
    # 3. Batch insert new participants
    if new_participants_data:
        new_participants_ref = db.collection(collection_name).document(custom_doc_id).collection('participants')
        batch = db.batch()
        count = 0
        total = len(new_participants_data)
        
        now_ts = int(datetime.now().timestamp())
        
        for p_data in new_participants_data:
            # Create a unique doc ID for the participant
            sanitized_name = p_data['name'].replace(" ", "_")
            doc_id = f"AUTO_{p_data['phone']}_{sanitized_name}_{now_ts}"
            
            doc_ref = new_participants_ref.document(doc_id)
            batch.set(doc_ref, p_data)
            
            count += 1
            if count % 500 == 0:
                batch.commit()
                batch = db.batch()
                print(f"Committed {count}/{total} participants...")

        if count % 500 != 0:
            batch.commit()
        
        print(f"Successfully added {count} participants to {custom_doc_id}.")
    
    print("All tasks completed successfully!")

if __name__ == "__main__":
    try:
        insert_incremental_event()
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
