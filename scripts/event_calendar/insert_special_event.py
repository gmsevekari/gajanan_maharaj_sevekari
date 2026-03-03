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

def add_event_to_db():
    # Define the collection name
    collection_name = 'events'

    seattle_tz = ZoneInfo("America/Los_Angeles")

    date = datetime(2026, 4, 18, 10, 00, 00, tzinfo=seattle_tz)

    # 3. Create the Data Dictionary
    # Note: Python 'datetime' objects are automatically converted to Firestore Timestamps
    event_data = {
        'title_en': 'Gajanan Vijay Grantha - Mukhotgat Parayan',
        'title_mr': 'गजानन विजय ग्रंथ - मुखोद्गत परायण',

        'event_type': 'specialEvent',
        
        'address': '18109 NE 76th St UNIT 108, Redmond, WA 98052',
        
        'date': date,
        'start_time': date,  # Using the same datetime for start_time``
        'end_time': date + timedelta(hours=10),  # Assuming the event lasts 4 hours

        'location_en': 'Saibaba Seattle Temple, Redmond',
        'location_mr': 'साईबाबा सिएटल मंदिर, रेडमंड',
        
        'details_en': '10:00 am: Parayan starts\n1:00 pm: Prasad\n7:30 pm: Gajanan Maharaj Aarti\n8:00 pm: Prasad',
        'details_mr': 'स. १०:००: परायण प्रारंभ\nदु. १:००: प्रसाद\nसायं. ७:३०: गजानन महाराज आरती\nसायं. ८:००: प्रसाद',
    }

    custom_doc_id = event_data['date'].strftime("%Y-%m-%d-%H-%M")
    print(f"Attempting to add special event with custom Document ID: {custom_doc_id}")

    try:
        # 4. Insert into Firestore
        # .add() automatically generates a unique Document ID
        db.collection(collection_name).document(custom_doc_id).set(event_data)
        
        print(f"✅ Success! Document created with ID: {custom_doc_id}")
        print(f"✅ Date: {event_data['date'].strftime('%Y-%m-%d-%H-%M')}")
        print(f"✅ Start date: {event_data['start_time'].strftime('%Y-%m-%d-%H-%M')}")
        print(f"✅ End date: {event_data['end_time'].strftime('%Y-%m-%d-%H-%M')}")
        
    except Exception as e:
        print(f"❌ Error adding event: {e}")

# Run the function
if __name__ == '__main__':
    add_event_to_db()