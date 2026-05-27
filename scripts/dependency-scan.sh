#!/bin/bash

echo "================================"
echo "Dynamic Dependency Scan"
echo "================================"

rm -f changedFiles.txt
touch changedFiles.txt

TARGET_BRANCH="${GITHUB_BASE_REF}"

if [ -z "$TARGET_BRANCH" ]
then
TARGET_BRANCH="develop"
fi

echo ""
echo "Target Branch : $TARGET_BRANCH"

git fetch origin $TARGET_BRANCH

echo ""
echo "Reading changed files"

git diff --name-only origin/$TARGET_BRANCH HEAD \
> changedFiles.txt

sort -u changedFiles.txt -o changedFiles.txt

echo ""
echo "Detected changed files"

cat changedFiles.txt

echo ""
echo "================================"
echo "Dependency information"
echo "================================"

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

if [[ "$FILE" == *.js ]]
then

echo "LWC/JS file detected"

grep "@salesforce/apex" "$FILE" || true

fi


if [[ "$FILE" == *.cls ]]
then

echo "Apex file detected"

grep "@isTest" "$FILE" || true

fi

done < changedFiles.txt


echo ""
echo "================================"
echo "Dependency scan completed"
echo "================================"

exit 0