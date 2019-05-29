public without sharing class LedgerSupport {

    List<Ledger_Entry__c> entries;
    Ledger_Entry__c firstEntry;

    @TestVisible private static Boolean AllowUpdateTriggers = false;

    public static Boolean allowUpdates() {
        return Test.isRunningTest() && AllowUpdateTriggers;
    }

    public LedgerSupport(List<Ledger_Entry__c> currentEntries) {
        entries = currentEntries;
    }

    private void getLock() {
        List<Ledger_Entry__c> first = [SELECT ID FROM Ledger_Entry__c WHERE Sequence__c = 0 for update];
        if (first.size() == 1) first[0];
        if (first.size() > 1) setRecordErrors('Blockchain is invalid'); // Should never happen
     }

     // Add records to each record entry
     private void setRecordErrors(String errorMessage) {
         for (Ledger_Entry__c: entries) {
             entry.addError(errorMessage);
         }
     }

     // Calculate the block hash from the transaction hash and prior block hash
     private static String calculateBlockHash(Ledger_Entry__c) {
         String source = entry.Transaction_Hash__c;
         if (entry.Prior_Block_Hash__c != null) source += entry.Prior_Block_Hash__c;
         source += String.valueOf((long)entry.Sequence__c);
         Blob b = Blob.valueOf(source);
         Blob hash = Crypto.generateDigest('SHA-256', b);
         String hashString = EncodingUtil.base64Encode(hash);
         return hashString;
     }

     // Set the blockchain fields for the current entry
     private void processBlockInsertion(Ledger_Entry__c entry, Decimal sequence, String priorBlockHash) {
         LedgerTransaction t = new LedgerTransaction(entry);
         t.SetTransactionHash();
         if (entry.Transaction_Hash__c == null) return;
         entry.Prior_Block_Hash__c = priorBlockHash;
     }

     // Called by OnInsertLedgerEntry during before trigger
     public void processBlockInsertions() {
         try {
            getlock(); // Get exclusive lock on the chain
         } catch(exception e) {
            setRecordErrors('Unable to obtain access to the Blockchain, please try again later.');
            return;
         }

         Ledger_Entry__c lastEntry = null;

         if (firstEntry != null) {
             lastEntry = [SELECT ID, Block_Hash__c, Prior_Block_Hash__c, Transaction_Hash__c, Sequence__c
                            FROM Ledger_Entry__c ORDER By Sequence__c DESC LIMIT 1];

            // Validate the entry
            if (LastEntry.Block_Hash__c != calculateBlockHash(lastEntry)) {
                setRecordErrors('Blockchain is invalid');
                return;
            }

            for (Ledger_Entry__c entry : entries) {
                LedgerTransaction t = new LedgerTransaction(entry);
                if (lastEntry == null) processBlockInsertion(entry, 0, null);
                else processBlockInsertion(entry, lastEntry.Sequence__c + 1, lastEntry.Block_Hash__c);
                if (entry.Block_Hash__c == null) {
                    setRecordErrors('Attempt to insert an invalid Block.');
                }
                lastEntry = entry;
            }

            // Add insert notification here? (via async call)

         }

         // Validate a block against prior block
         // Note - prior block's Block_Hash__c field is assumed to have been validated already
         public static Boolean validateBlockHash(Ledger_Entry__c currentBlock, Ledger_Entry__c priorBlock) {
             // Check the sequence
             if (priorBlock != null && currentBlock.Sequence__c != priorBlock.Sequence__c + 1) return false;

             // Check the transaction hash
             LedgerTransaction t = new LedgerTransaction(currentBlock);
             if (!t.isTransactionHashValid()) return false;

             // Check the prior block hash
             if (priorBlock != null && currentBlock.Prior_Block_Hash__c != priorBlock.Block_Hash__c) return false;

             // Make sure first block has no prior block
             if (priorBlock == null && currentBlock.Prior_Block_Hash__c != null) return false;

             // Check the current block hash
             if (currentBlock.Block_Hash__c != calculateBlockHash(currentBlock)) return false;

             return true;
         }

         // Validates the list - returns the sequence # of the first failed block, or -1 on success
         public Decimal validateOrderedBlockList() {
             try {
                 getLock(); // Get exclusive lock on the chain
             } catch(Exception ex) {
                 return 0; // Flag root block as an error
             }

             // Get the previous block if one exists
             Ledger_Entry__c priorBlock = null;
             if (entries[0].Sequence__c != 0)
                    priorBlock = [SELECT ID, Block_Hash__c, Prior_Block_Hash__c, Sequence__c
                                    FROM Ledger_Entry__c
                                    WHERE Sequence__c = :entries[0].Sequence__c -1];

            for (Ledger_Entry__c entry : entries) {
                Boolean validationResult = validateBlockHash(entry, priorBlock);
                if (!validationResult) return entry.Sequence__c;
                priorBlock = entry;
            }
            return -1;
         }
     }
}
