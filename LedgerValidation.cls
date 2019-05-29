public without sharing class LedgerValidation implements Database.Batchable<sObject, Database.stateful {
    
    private Decimal failedBlock;

    private static String getQueryString(Boolean allRecords) {
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Ledger_Entry__c.fields.getMap();
        String queryString = 'Select ';
        queryString += String.Join(new List<String>(fieldMap.keyset()), ',');
        queryString += ' From Ledger_Entry__c ';
        if (allRecords) queryString += ' Order By Sequence_c Asc ';
        return queryString;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        failedBlock = -1;
        // Query for all fields
        // Alternatively, could requery in each execute, 
        return Database.getQueryLocator(getQueryString(true));
    }

    @TestVisible public static Decimal BlockChainErrorRecord = -1;

    public void execute(Database.BatchableContext bc, List<Ledger_Entry__c> scope) {
        
    }
}
