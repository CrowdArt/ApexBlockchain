# ApexBlockchain
* I want deal data to be secured.
* I want to know about tampering right away.
* I want to be able to prove to outsiders that our data is reliable.
* I want our data to be kept private.
* I want to be able to prove that individual transactions have not been modified over time - but without granting access to our systems.
## Blockchaing Review
* Blockchains are not inherently immutable - it is always possible to recalculate hash values.
* One path to immutability is to make it hard to create or modify blocks.
## Distributed vs. Read-only Distributed
### Distributed Blockchain
* Anyone participating in the blockchain can add blocks
* Requires a way to make blocks hard to create and to resolve conflicts
* Everyone has a full copy of the entire ledger and adds blocks to their copy
### Read-only Distributed
* Only your internal applications can add blocks
* Use database security to control access to creating blocks.  One source of truth at time of block creation.
* Everyone has access to a copy of the ledger from the database.

# Architecture
## Data Model
Each block and its transaction will be stored in a custom object called Ledger_Entry__c.  The name field is defined as Auto Number field. 

## Creating and Validating Transactions (Setting and validating the transaction data)
The solution is built with three classes.  One to handle the transction data, one to handle the ledger block and one to handle validation of blocks and the entire Blockchain.  

All of the classes will be defined as without sharing. The blockchain code must have full access to all of the fields and records in order to be able to correctly calculate hash values, maintain Blockchain integrity, and validate the entire Blockchain.  

I am using Saleforce object and field level security to prevent users from accessing records.  Organizations should use sharing rules to restrict who can view transactions.  This is called Delegated Security - Blockchain code has greater permission to access data than user account invoking code.  The Apex classes intentionally ignore object and field level security.

The `LedgerTransaction.cls` has a single constructor that takes the ledger entry object.  It can be a new object, in which case the class will be used to calculate the transaction hash, or an existing object, in which case the class will be used to validate the data against the transaction hash.  In each case, the class will need a list of the fields that are part of the transaction that are included in calculating the transaction hash.  For new records, the list of fields to use can be defined in a variety of ways.  One way is to have it hardcoded in the `getNewFieldList` function.  It can also be stored in custom metadata or in custom settings.

The transaction field list and transaction date are considered transaction data.  

Next, we validate the field list.  Every field is checked to see if it is a valid field.  It is also tested to make sure that it is an accepted data type.  For this example, any data type other than Lookup or Formula.  If any of the field are not valid, we return null.  For existing fields the `getValidatedFieldList()` function, pulls the list from the storage transaction field list.  

`getTransactionHash()` is used for both new and existing records.  It takes a specified field list and builds a string by concatanating all of the transaction data fields.  Decimal fields are cast into a double to avoid false validation errors if the number of trailing zeros  after the decimal point varies.  

`setTransactionHash()` method is called for new records. If the field list returned from `getNewFieldList` is valid, it stores it in `Transaction_Field_List__c`, stores the current DateTime in the `Transaction_Date` field and sets the `Transaction_Hash` field to the hash value calculated by `getTransactionHash()`.

`isTransactionHashValid()` - is used to verify an existing transaction.  If the `getValidatedFieldList()` function returns a valid list of fields, it calculated their hash value and compares them to the stored transaction hash field, returning true if they match.  

## Adding Block to the Blockchain (Setting and validating the entire block)
The LedgerSupport class manages individual ledger entree records; handling both insertion and validation of the blockchain fields.  As with the LedgerTransaction class, it has a single constructor that accepts and stores a list of ledger entry records.  These may be new records being inserted or existing records that can be validated.  

##
* [Gemini API](https://docs.gemini.com/rest-api/#introduction)
* [CoinGecko](https://www.coingecko.com/en)
* [Etherscan API](https://etherscan.io/apis)
* https://developer.salesforce.com/forums/?id=9060G000000MSBLQA4
* https://developer.salesforce.com/forums/?id=906F0000000D9AUIA0
