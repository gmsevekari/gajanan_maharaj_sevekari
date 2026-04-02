#!/usr/bin/env python3
import argparse
import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

def update_version(platform, version, min_version=None):
    """
    Updates the app_config/version document in Firestore.
    
    Args:
        platform (str): 'android' or 'ios'
        version (str): the latest version string (e.g., '1.0.21')
        min_version (str, optional): the minimum version string. 
                                     If not provided, uses the current latest_version.
    """
    # Use default credentials (GOOGLE_APPLICATION_CREDENTIALS environment variable)
    if not firebase_admin._apps:
        cred = credentials.Certificate('/Users/abhishekkulkarni/gajananmaharajseattle@gmail.com - Google Drive/My Drive/App/Firebase/serviceAccountKey.json') 
        firebase_admin.initialize_app(cred)

    db = firestore.client()
    doc_ref = db.collection('app_config').document('version')
    
    doc = doc_ref.get()
    if not doc.exists:
        print(f"Error: Document app_config/version not found.")
        return

    data = doc.to_dict()
    platform_data = data.get(platform, {})
    
    # Update field values
    platform_data['latest_version'] = version
    if min_version:
        platform_data['min_version'] = min_version
    elif 'min_version' not in platform_data:
        # Fallback if min_version is missing in a new document structure
        platform_data['min_version'] = version
        
    # Update Firestore
    doc_ref.update({
        platform: platform_data
    })
    
    print(f"Successfully updated {platform} version to {version} (min: {platform_data['min_version']})")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Update remote app version in Firestore.')
    parser.add_argument('--platform', required=True, choices=['android', 'ios'], help='Platform to update')
    parser.add_argument('--version', required=True, help='Latest version string (e.g., 1.0.21)')
    parser.add_argument('--min-version', help='Minimum required version string')

    args = parser.parse_args()
    update_version(args.platform, args.version, args.min_version)
