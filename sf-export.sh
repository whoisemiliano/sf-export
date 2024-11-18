#!/bin/bash

# Check if username parameter is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <username or alias> [sObject1 sObject2 ...]"
    exit 1
fi

# Assign the username to a variable
USERNAME=$1
shift

if [ $# -gt 0 ]; then
    # If sObjects are passed, use them
    OBJECTS="$@"
    echo "🤓 Using provided list of sObjects: $OBJECTS"
else
    # Get a list of all objects in the Salesforce org
    echo "☁️ Retrieving object list for org: $USERNAME"
    OBJECTS=$(sf sobject list --sobject all --target-org "$USERNAME")
    
    # Check if the object list retrieval was successful
    if [ $? -ne 0 ]; then
        echo "❌ Failed to retrieve the object list. Please check your username and connection."
        exit 1
    fi
fi

mkdir -p ./exports

# Iterate through each object and export the data
echo "Exporting data for each object..."
for OBJECT in $OBJECTS; do
    # Replace colons in object names (if any) for valid file names
    SAFE_OBJECT_NAME=$(echo "$OBJECT" | tr ':' '_')
    
    echo "☁️ Retrieving field information for object: $OBJECT"
    OBJECT_DESCRIPTION=$(sf sobject describe --sobject "$OBJECT" --target-org "$USERNAME" --json)
    
    # Check if the describe call was successful
    if [ $? -ne 0 ] || [ -z "$OBJECT_DESCRIPTION" ]; then
        echo "❌ Failed to retrieve field information for $OBJECT. Skipping..."
        continue
    fi
    
    # Get a list of unique compoundFieldName values (non-null) using jq from the saved result
    COMPOUND_FIELDS=$(echo "$OBJECT_DESCRIPTION" | jq -r '.result.fields[] | select(.compoundFieldName != null) | .compoundFieldName' | sort | uniq)
    
    # Get all fields of the object, excluding those on the compound field list
    FIELDS=$(echo "$OBJECT_DESCRIPTION" | jq -r --argjson compoundFields "$(echo "$COMPOUND_FIELDS" | jq -Rsc 'split("\n") | map(select(. != ""))')" \
        '.result.fields[] | select(.compoundFieldName == null and (.name as $name | $compoundFields | index($name) | not)) | .name' | \
    tr '\n' ',' | sed 's/,$//')
    
    if [ -z "$FIELDS" ]; then
        echo "❌ No fields found for $OBJECT or failed to retrieve fields. Skipping..."
        continue
    fi
    
    # Execute the data export command for each object
    echo "📊 Exporting data for object: $OBJECT"
    sf data query --query "SELECT $FIELDS FROM $OBJECT" --target-org "$USERNAME" --bulk --wait 9999 --result-format csv >  ./exports/${SAFE_OBJECT_NAME}.csv
    
    # Check if export was successful
    if [ $? -eq 0 ]; then
        echo "💾 Data exported successfully for $OBJECT."
    else
        echo "❌ Failed to export data for $OBJECT. Skipping..."
    fi
done

echo "🎉 Data export completed."
