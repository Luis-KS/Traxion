@IsTest
public with sharing class DPNControllerTest {

    // CONSIDERAR HACER MODIFICACIONES EN LA CLASE, VER NOTAS EN CADA MÉTODO

    @TestSetup
	static void createTestData() {
  
        Account account = TestDataFactory.createSingleAccount('AGUASCALIENTESTEST');
        Product2 product = TestDataFactory.createSingleProduct2('Acetaminofen');
        DPN__c dpn = TestDataFactory.createSingleDPN(account.Id);
        DPN_Line_Item__c dpnLineItem = TestDataFactory.createSingleDPNLineItem(dpn.Id, product.Id);
        List<Contact> contactList = TestDataFactory.createMultipleContactRelatedToAccount(account.Id, 'Tester', 'Class', 2);
    }

  	@isTest
    static void getDPNTest(){
        
        Test.startTest();
        	List<Account> accountList = DPNController.getDPN('AGUAS');
        Test.stopTest();
        
        Assert.areEqual(1, accountList.size());
        
    }
    
    @isTest
    static void getDpnListTest(){
        DPN__c dpn = [SELECT Id FROM DPN__c LIMIT 1];
        
        Test.startTest();
        	List<DPN_Line_Item__c> dpnLineItemTest = DPNController.getDpnList(dpn.Id);
        Test.stopTest();
        
        Assert.isNotNull(dpnLineItemTest);
    }
    
    @isTest
    static void getDataFromContactTest(){
        
        
        Test.startTest();
        	List<Contact> contactList = DPNController.getDataFromContact();
        Test.stopTest();
        
        Assert.isNotNull(contactList);
    }
  
}