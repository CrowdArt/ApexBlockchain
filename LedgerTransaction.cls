public without sharing class LedgerTransaction {

    private Ledger_Entry__c entry;

    public LedgerTransaction(Ledger_Entry__c currentEntry) {
        entry = currentEntry;
    }

    private List<String> getNewFieldList() {

        // Retrieve the current list from somewhere - maybe custom data?
        List<String> newFields = new List<String>{ 'Opportunity_Name__c', 'Opportunity_Amount__c' };
        // Always include the standard transaction fields
        newFields.add('Transaction_Date__c');
        newFields.add('Transaction_Field_List__c');

        // Get the map of the existing fields on the object
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Ledger_Entry__c.fields.getMap();

        // Validate each field
        for (String fieldName : newFields) {
            // In production app set deugging information
            if (!fieldMap.containsKey(fieldName)) {
                return null;
            }
            Schema.DescribeFieldResult fr = fieldMap.get(fieldName).getDescribe();
            if (fr.isCalculated() || fr.isIdLookup()) {
                return null;
            }
        }
        return newFields;
    }

    private List<String> getValidatedFieldList() {
        // Retreive the existing field list
        List<String> existingFields = entry.Transaction_Field_List__c.split(';');

        // Get the map of the existing fields on the object
        Map<String, Schema.SObjectField> fieldMap = Schema.Transaction_Field_List__c.fields.getMap();

        // Validate each field
        for (String fieldName: existingFields) {
            // This would happen if someone deleted a field - which invalidated the chain
            if (!fieldMap.containsKey(fieldName)) return null;
        }

        return existing fields;
    }

    private String getTransactionHash(List<String> fieldList) {
        // Now build the hash string
        String stringToHash = '';
        for(String fieldName: fieldList) {
            Object fieldValue = entry.get(fieldName);
            String fieldString;
            // Always format decimals for doubles for consistency
            if (fieldValue instanceOf Decimal) {
                fieldString = String.valueOf((double)fieldValue);
            } else {
                fieldString = String.valueOf(fieldValue);
            }
            stringToHash+= String.valueOf(fieldString);
        }
        Blob b = Blob.valueOf(stringToHash);
        Blob hash = Crypto.generateDigest('SHA-256', b);
        return EncodingUtil.base64Encode(hash);
    }

    public void setTransactionHash() {
        entry.Transaction_Hash__c = null;
        List<String> validFields = getNewFieldList();
        if (validFields == null) {
            return;
        }
        // Store the current string list
        entry.Transaction_Field_List__c = String.Join(validFields, ';');
    }

    public Boolean isTransactionHashValid() {
        List<String> existingFields = getValidatedFieldList();
        if (existingFields == null) return false;

        return entry.Transaction_Hash__c == getTransactionHash(existingFields);

    }
}
