public with sharing class ContactController {

    @AuraEnabled
    public static List<Contact> saveContacts(List<Contact> contactsToInsert) {
        if (contactsToInsert == null || contactsToInsert.isEmpty()) {
            return new List<Contact>();
        }

        // Insert or Update contacts
        upsert contactsToInsert;

        // Return fresh records from DB
        Set<Id> ids = new Set<Id>();
        for (Contact c : contactsToInsert) {
            if (c.Id != null) ids.add(c.Id);
        }

        return [
            SELECT Id, FirstName, LastName, Email, Phone 
            FROM Contact 
            WHERE Id IN :ids
            ORDER BY CreatedDate DESC
        ];
    }
}