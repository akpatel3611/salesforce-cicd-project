#!/bin/bash

echo "================================"
echo "Dynamic Dependency Validation"
echo "================================"

FAILED=false

rm -f changedFiles.txt
rm -f imports.txt
rm -f dependency-list.txt
rm -f objects.txt
rm -f coverage.txt

touch changedFiles.txt
touch dependency-list.txt
touch objects.txt
touch coverage.txt

TARGET_BRANCH="${GITHUB_BASE_REF}"

if [ -z "$TARGET_BRANCH" ]
then
echo "GitHub branch not found"
echo "Using develop branch"
TARGET_BRANCH="develop"
fi

echo ""
echo "Target Branch : $TARGET_BRANCH"

git fetch origin $TARGET_BRANCH

echo ""
echo "Reading changed files"

if [ -f "delta-package/package/package.xml" ]
then

echo "Using Delta Package"

grep "<members>" delta-package/package/package.xml \
| sed 's/<members>//g' \
| sed 's/<\/members>//g' \
> changedFiles.txt

else

echo "Using Git Difference"

git diff --name-only origin/$TARGET_BRANCH HEAD > changedFiles.txt

git diff --name-only >> changedFiles.txt

fi

sort -u changedFiles.txt -o changedFiles.txt

echo ""
echo "Detected Files"

cat changedFiles.txt


while read FILE
do

FILE=$(echo "$FILE"|xargs)

if [[ -z "$FILE" ]]
then
continue
fi

if [ ! -f "$FILE" ]
then
continue
fi

echo ""
echo "Checking : $FILE"


#################################################
# JS → Apex
#################################################

if [[ "$FILE" == *.js ]]
then

grep "@salesforce/apex" "$FILE" > imports.txt || true

while read LINE
do

CLASS=$(echo "$LINE" | sed 's/.*\/\(.*\)\..*/\1/')

if [[ -z "$CLASS" ]]
then
continue
fi

echo ""
echo "Detected Apex Class : $CLASS"

echo "$CLASS" >> dependency-list.txt


#################################################
# Apex exists
#################################################

if [ ! -f "force-app/main/default/classes/$CLASS.cls" ]
then

echo "ERROR Missing Apex Class : $CLASS"

FAILED=true

fi


#################################################
# Apex in commit/package
#################################################

grep "$CLASS" changedFiles.txt > /dev/null

if [ $? -ne 0 ]
then

echo "ERROR Apex exists but not included in PR : $CLASS"

FAILED=true

fi


#################################################
# Test class check
#################################################

TESTCLASS="${CLASS}Test"

if [ ! -f "force-app/main/default/classes/${TESTCLASS}.cls" ]
then

echo "ERROR Missing Test Class : $TESTCLASS"

FAILED=true

fi


grep "$TESTCLASS" changedFiles.txt > /dev/null

if [ $? -ne 0 ]
then

echo "ERROR Test Class exists but not included in PR : $TESTCLASS"

FAILED=true

fi


#################################################
# Coverage
#################################################

echo ""
echo "Checking Coverage : $CLASS"

sf data query \
-q "SELECT ApexClassOrTrigger.Name,Coverage FROM ApexCodeCoverageAggregate WHERE ApexClassOrTrigger.Name='$CLASS'" \
-r csv > coverage.txt 2>/dev/null


COVERAGE=$(tail -n +2 coverage.txt | awk -F',' '{print $2}' | tr -d '%')

if [[ ! -z "$COVERAGE" ]]
then

echo "Coverage : $COVERAGE %"

if [ "$COVERAGE" -lt 75 ]
then

echo "ERROR Coverage below 75%"

FAILED=true

fi

fi

done < imports.txt

fi


#################################################
# Apex → Object
#################################################

if [[ "$FILE" == *.cls ]]
then

grep -o "[A-Za-z0-9_]*__c" "$FILE" >> objects.txt || true

sort -u objects.txt -o objects.txt

while read OBJECT
do

OBJECT=$(echo "$OBJECT"|xargs)

if [[ -z "$OBJECT" ]]
then
continue
fi

echo ""
echo "Detected Object : $OBJECT"

if [ ! -d "force-app/main/default/objects/$OBJECT" ]
then

echo "ERROR Missing Object : $OBJECT"

FAILED=true

fi

done < objects.txt

fi

done < changedFiles.txt


#################################################
# Manual Components
#################################################

echo ""
echo "================================"
echo "Manual Components"
echo "================================"

if [ -f "manual-components.txt" ]
then

while read MANUALFILE
do

MANUALFILE=$(echo "$MANUALFILE"|xargs)

[[ -z "$MANUALFILE" ]] && continue
[[ "$MANUALFILE" == \#* ]] && continue

echo "Manual Component : $MANUALFILE"

if [ ! -f "$MANUALFILE" ]
then

echo "ERROR Missing Manual Component : $MANUALFILE"

FAILED=true

fi

done < manual-components.txt

fi


echo ""
echo "================================"
echo "Detected Dependencies"
echo "================================"

sort -u dependency-list.txt -o dependency-list.txt

cat dependency-list.txt


if [ "$FAILED" = true ]
then

echo ""
echo "Dependency validation failed"

exit 1

fi

echo ""
echo "Dependency validation passed"