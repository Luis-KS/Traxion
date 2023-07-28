@isTest
private class TestBatchDPNLineItemProcessor{

	@testSetup static void setup(){

        Account acc = TestDataFactory.createSingleAccount(
            'Test UMU - UserContactClassTest'
        );
        
        Contact con = TestDataFactory.createSingleContactRelatedToAccount(
            acc.Id,
            'Test',
            'UserContactClassTest',
            'Medicina'
        );
        
        String uniqueUserName = String.ValueOf(System.Now())
            .replaceAll('[^a-zA-Z0-9]', '');
        User user = TestDataFactory.initCommunityLoginUser(uniqueUserName);
        
        Product2 clave = new Product2();
        clave.Name = 'Medicamento de Prueba';
        clave.Simple_Classification__c = 'MEDICINE';
        clave.Fraction__c = 'Controlado 1';
        insert clave;
        
        DPN__c dpn = new DPN__c();
        dpn.Account__c = acc.Id;
        dpn.Estatus__c = 'Activo';
        insert dpn;
        
        DPN_Line_Item__c dpnLineItem = new DPN_Line_Item__c();
        dpnLineItem.DPN__c = dpn.Id;
        dpnLineItem.Product__c = clave.Id;
        dpnLineItem.Consumido__c = 1.1;
        insert dpnLineItem;
		 
	}

	@isTest static void testMethod1() {
		Test.startTest();
        BatchDPNLineItemProcessor ba= new BatchDPNLineItemProcessor();
        Id jobid= Database.executeBatch(ba,5);
        Test.stopTest();
	}
}