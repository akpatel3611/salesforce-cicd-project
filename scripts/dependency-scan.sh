#!/bin/bash

echo "Starting dependency validation"

FAILED=false

git diff --name-only origin/develop...HEAD > changedFiles.txt


while read FILE
do

echo "Checking file: $FILE"


if [[ "$FILE" == *".js" ]]
then

grep "@salesforce/apex" "$FILE" > imports.txt || true


while read LINE
do

CLASS=$(echo "$LINE" | sed 's/.*\/\(.*\)\..*/\1/')


echo "Detected Apex: $CLASS"


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


done < imports.txt


fi

done < changedFiles.txt


if [ "$FAILED" = true ]
then

echo "Dependency validation failed"

exit 1

fi


echo "Dependency validation successful"