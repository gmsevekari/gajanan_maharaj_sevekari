import xml.etree.ElementTree as ET
import sys
import os
import json

def test_manifest_autoverify():
    manifest_path = 'android/app/src/main/AndroidManifest.xml'
    if not os.path.exists(manifest_path):
        print(f"Error: {manifest_path} not found")
        return False

    ns = {'android': 'http://schemas.android.com/apk/res/android'}
    ET.register_namespace('android', ns['android'])
    
    tree = ET.parse(manifest_path)
    root = tree.getroot()
    
    autoverify_filters = []
    for activity in root.findall('.//activity', ns):
        for intent_filter in activity.findall('intent-filter', ns):
            autoverify = intent_filter.get('{http://schemas.android.com/apk/res/android}autoVerify')
            if autoverify == 'true':
                autoverify_filters.append(intent_filter)
    
    if not autoverify_filters:
        print("FAIL: No intent-filter found with android:autoVerify=\"true\"")
        return False
        
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
        return False
        
    print("PASS: Manifest configuration is correct.")
    return True

def test_assetlinks_json():
    path = 'web/.well-known/assetlinks.json'
    if not os.path.exists(path):
        print(f"FAIL: {path} not found")
        return False
        
    try:
        with open(path, 'r') as f:
            data = json.load(f)
            
        if not isinstance(data, list) or len(data) == 0:
            print(f"FAIL: {path} is not a valid list")
            return False
            
        entry = data[0]
        target = entry.get('target', {})
        
        expected_package = "com.gajanan.maharaj.sevekari"
        if target.get('package_name') != expected_package:
            print(f"FAIL: Expected package {expected_package}, found {target.get('package_name')}")
            return False
            
        fingerprints = target.get('sha256_cert_fingerprints', [])
        if len(fingerprints) < 2:
            print(f"FAIL: Expected at least 2 fingerprints (Release + Debug), found {len(fingerprints)}")
            return False
            
        print("PASS: assetlinks.json structure and package name are correct.")
        return True
        
    except Exception as e:
        print(f"FAIL: Error parsing {path}: {e}")
        return False

if __name__ == "__main__":
    m_pass = test_manifest_autoverify()
    a_pass = test_assetlinks_json()
    
    if m_pass and a_pass:
        print("\nALL TESTS PASSED")
        sys.exit(0)
    else:
        print("\nSOME TESTS FAILED")
        sys.exit(1)
