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

    date = datetime(2026, 4, 26, 10, 30, 00, tzinfo=seattle_tz)

    # 3. Create the Data Dictionary
    # Note: Python 'datetime' objects are automatically converted to Firestore Timestamps
    event_data = {
        'title_en': 'Weekly Abhishek, Pooja and Prasad',
        'title_mr': 'साप्ताहिक अभिषेक, पूजा आणि प्रसाद',

        'event_type': 'weeklyPooja',
        
        'address': '18109 NE 76th St UNIT 108, Redmond, WA 98052',
        
        'date': date,
        'start_time': date,  # Using the same datetime for start_time``
        'end_time': date + timedelta(hours=4),  # Assuming the event lasts 4 hours
        
        'location_en': 'Saibaba Seattle Temple, Redmond',
        'location_mr': 'साईबाबा सिएटल मंदिर, रेडमंड',
        
        'details_en': '10:30 am: Abhishek\n11:30 am: Vastralankar\n12:00 pm: Saibaba madhyan aarti\n12.30 pm: Gajanan maharaj madhyan aarti\n01:00 am: Prasad',
        #'details_en': '4:00 pm: Abhishek\n5:00 pm: Vastralankar\n6:30 pm: Saibaba dhoop aarti\n7.00 pm: Gajanan maharaj dhoop aarti\n07:30 am: Prasad',
        'details_mr': 'स. १०:३०: अभिषेक\nस. ११:३०: वस्त्रालंकार\nदु. १२:००: साईबाबा मध्यान आरती\nदु. १२:३०: गजानन महाराज मध्यान आरती\nदु. ०१:००: प्रसाद',
        #'details_mr': 'दु. ४:००: अभिषेक\nदु. ५:००: वस्त्रालंकार\nसायं. ६:३०: साईबाबा धूप आरती\nसायं. ७:००: गजानन महाराज धूप आरती\nसायं. ७:३०: प्रसाद',
    }

    custom_doc_id = event_data['date'].strftime("%Y-%m-%d-%H-%M")
    print(f"Attempting to add event with custom Document ID: {custom_doc_id}")

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