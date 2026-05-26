#!/bin/bash

echo "================================"
echo "Starting Dependency Validation"
echo "================================"

FAILED=false

TARGET_BRANCH="${GITHUB_BASE_REF}"

if [ -z "$TARGET_BRANCH" ]
then
echo "GitHub branch not found"
echo "Using develop as local target branch"
TARGET_BRANCH="develop"
fi

echo "Target Branch:$TARGET_BRANCH"

git fetch origin $TARGET_BRANCH

git diff --name-only origin/$TARGET_BRANCH HEAD > changedFiles.txt

git diff --name-only >> changedFiles.txt

sort -u changedFiles.txt -o changedFiles.txt



cat changedFiles.txt

while read FILE
do

echo "Checking file: $FILE"

if [[ "$FILE" == *".js" ]]
then

grep "@salesforce/apex" "$FILE" > imports.txt || true

while read LINE
do

CLASS=$(echo "$LINE" | sed 's/.*\/\(.*\)\..*/\1/')

if [ -n "$CLASS" ]
then

echo "Detected Apex Class: $CLASS"

if [ ! -f "force-app/main/default/classes/$CLASS.cls" ]
then

echo "ERROR Missing Apex Class: $CLASS"

FAILED=true
fi


if [ ! -f "force-app/main/default/classes/${CLASS}Test.cls" ]
then

echo "ERROR Missing Test Class: ${CLASS}Test"

FAILED=true
fi

fi

done < imports.txt

fi

done < changedFiles.txt

echo ""
echo "================================"
echo "Manual Components"
echo "================================"

if [ -f "manual-components.txt" ]
then

while read MANUALFILE
do

MANUALFILE=$(echo "$MANUALFILE" | xargs)

if [[ -z "$MANUALFILE" ]]
then
continue
fi

if [[ "$MANUALFILE" == \#* ]]
then
continue
fi

echo "Manual Component Found: $MANUALFILE"

if [ ! -f "$MANUALFILE" ]
then

echo "ERROR Missing Manual Component: $MANUALFILE"

FAILED=true

fi

done < manual-components.txt

fi

if [ "$FAILED" = true ]
then

echo "Dependency validation failed"

exit 1
fi

echo "Dependency validation passed"