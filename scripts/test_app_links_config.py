import xml.etree.ElementTree as ET
import sys
import os

def test_manifest_autoverify():
    manifest_path = 'android/app/src/main/AndroidManifest.xml'
    if not os.path.exists(manifest_path):
        print(f"Error: {manifest_path} not found")
        sys.exit(1)

    # XML namespaces
    ns = {'android': 'http://schemas.android.com/apk/res/android'}
    ET.register_namespace('android', ns['android'])
    
    tree = ET.parse(manifest_path)
    root = tree.getroot()
    
    # Find all intent-filters with autoVerify="true"
    autoverify_filters = []
    for activity in root.findall('.//activity', ns):
        for intent_filter in activity.findall('intent-filter', ns):
            autoverify = intent_filter.get('{http://schemas.android.com/apk/res/android}autoVerify')
            if autoverify == 'true':
                autoverify_filters.append(intent_filter)
    
    if not autoverify_filters:
        print("FAIL: No intent-filter found with android:autoVerify=\"true\"")
        sys.exit(1)
        
    # Check if the filters cover the required hosts
    required_hosts = ['gajananmaharajsevekari.org', 'www.gajananmaharajsevekari.org']
    found_hosts = []
    
    for f in autoverify_filters:
        for data in f.findall('data', ns):
            host = data.get('{http://schemas.android.com/apk/res/android}host')
            if host in required_hosts:
                found_hosts.append(host)
                
    missing_hosts = set(required_hosts) - set(found_hosts)
    if missing_hosts:
        print(f"FAIL: Missing autoVerify for hosts: {missing_hosts}")
        sys.exit(1)
        
    print("PASS: Manifest configuration for App Links is correct.")
    sys.exit(0)

if __name__ == "__main__":
    test_manifest_autoverify()
