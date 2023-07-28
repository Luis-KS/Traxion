@IsTest
public with sharing class DPNLIConsumidoUpdateBatchTest {

    @TestSetup
	static void createTestData() {
        String uniqueUserName = String.ValueOf(System.Now()).replaceAll('[^a-zA-Z0-9]', '');
        User user = TestDataFactory.initCommunityLoginUser(uniqueUserName);

        List<Id> accountIdList = new List<Id>();
        List<AccountContactRelation> accountContactList = [
            SELECT AccountId, Account.Name  
            FROM AccountContactRelation 
            WHERE ContactId =: user.ContactId
        ];  
        for(AccountContactRelation accConRel : accountContactList){
            accountIdList.add(accConRel.AccountId);
        }

        DPN__c dpn = TestDataFactory.createSingleDPN(accountIdList[0]);
    }

    @IsTest
    static void testDPNLIConsumidoUpdateBatch() {
        Test.startTest();

        DPN__c dpn = [SELECT Id FROM DPN__c LIMIT 1 FOR UPDATE];

        Product2 clave = TestDataFactory.createSingleProduct2('Medicina de Prueba'); 

        // Create test data
        List<DPN_Line_Item__c> dpnliList = new List<DPN_Line_Item__c>();
        for (Integer i = 0; i < 200; i++) {
            DPN_Line_Item__c dpnli = new DPN_Line_Item__c();
            dpnli.DPN__c = dpn.Id;
            dpnli.Product__c = clave.Id;
            dpnliList.add(dpnli);
        }
        insert dpnliList;
        
        // Create an instance of the batch class
        DPNLIConsumidoUpdateBatch batch = new DPNLIConsumidoUpdateBatch();
        String batchableContext = Database.executeBatch(batch, 200);
        
        // Perform assertions to verify the result
        List<DPN_Line_Item__c> updatedDpnliList = [
            SELECT Id, Activo__c
            FROM DPN_Line_Item__c
            WHERE Id IN :dpnliList
        ];
        for (DPN_Line_Item__c dpnli : updatedDpnliList) {
            System.assertEquals(true, dpnli.Activo__c);
        }
    }
}