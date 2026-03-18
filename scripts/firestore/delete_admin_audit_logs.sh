#!/bin/bash

# Configuration
PROJECT_ID="app-event-calendar"
COLLECTION_PATH="admin_audit_logs"

# Check if firebase is installed
if ! command -v firebase &> /dev/null; then
  echo "Firebase CLI not found. Please install it using: npm install -g firebase-tools"
  exit 1
fi

echo "Deleting all documents in collection: $COLLECTION_PATH from project: $PROJECT_ID..."

# Delete the collection recursively
firebase firestore:delete --project "$PROJECT_ID" --recursive "$COLLECTION_PATH"

if [ $? -eq 0 ]; then
  echo "Successfully deleted all documents in $COLLECTION_PATH."
else
  echo "Failed to delete documents. Please ensure you are logged in (firebase login) and have correct permissions."
  exit 1
fi
