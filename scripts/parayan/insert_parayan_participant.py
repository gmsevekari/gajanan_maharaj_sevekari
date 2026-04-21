import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
from datetime import datetime

# 1. Initialize Firebase App
# Replace 'serviceAccountKey.json' with the path to your actual file
if not firebase_admin._apps:
    cred = credentials.Certificate('serviceAccountKey.json') 
    firebase_admin.initialize_app(cred)

# 2. Get Firestore Client
db = firestore.client()

seattle_tz = ZoneInfo("America/Los_Angeles")
allocated_at_dt = datetime(2026, 3, 31, 0, 0, 0, tzinfo=seattle_tz)
joined_at_dt = datetime(2026, 3, 31, 0, 0, 0, tzinfo=seattle_tz)

# 3. Define the document attributes
device_id = "b575bceb5e3991ba"
member_name = "राजन"

data = {
    "allocatedAt": allocated_at_dt,
    "assignedAdhyays": 19, # Note: if your app expects a list, change this to [19]
    "completions": {
        "1": False
    },
    "deviceId": device_id,
    "globalIndex": 39,
    "groupNumber": 2,
    "joinedAt": joined_at_dt,
    "memberName": member_name,
    "name": member_name,
    "phone": "+1 4255293440"
}

# 4. Generate the specific Document ID
# Formats memberName by replacing spaces with underscores, then combines with deviceId
formatted_member_name = member_name.replace(" ", "_")
doc_id = f"{device_id}_{formatted_member_name}"

# 5. Write to Firestore
# IMPORTANT: Replace 'parayan_participants' with your actual collection name
collection_name = "parayan_participants" 

try:
    db.collection(collection_name).document(doc_id).set(data)
    print(f"Successfully created document with ID: {doc_id}")
    print(f"Data payload:\n{data}")
except Exception as e:
    print(f"Error creating document: {e}")