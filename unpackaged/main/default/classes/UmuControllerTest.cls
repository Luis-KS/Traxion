@isTest
public class UmuControllerTest {
    
    @isTest
    static void testGetUmus() {
        User user = TestDataFactory.initCommunityLoginUser('testUser');
        
        System.runAs(user) {
            test.startTest();
            List<Account> result = UmuController.getUmu(user.Id);
            System.assertEquals(1, result.size(), 'Account list size must be 1');
            test.stopTest();
        }
    }

    @isTest
    static void testGetUmuOrders() {
    	Order__c order = TestDataFactory.createSingleOrder();
        
        System.debug(order);
        
       	test.startTest();
        List<Order__c> result = UmuController.getUmuOrders('AGUASCALIENTES');
        System.assertEquals(1, result.size(), 'Order list size must be 1');
        test.stopTest();
    }
    
    @isTest
    static void testGetAllUmus() {
        List<Account> accs = TestDataFactory.createMultipleAccounts(
            'AGUASCALIENTES', 'CE', '001-AGUASCALIENTES', 3);
        
        System.debug(accs);
        
        test.startTest();
        List<Account> result = UmuController.getAllUmus();
        System.assertEquals(3, result.size(), 'Order list size must be 3');
        test.stopTest();
    }
    
    @isTest
    static void testGetUmuByType() {
        TestDataFactory.createMultipleAccounts('AGUASCALIENTES', 'CE', '001-AGUASCALIENTES', 5);
        TestDataFactory.createMultipleAccounts('UMF CALVILLO', 'UMF', '001-AGUASCALIENTES', 3);
        
        List<String> types = new List<String>();
        types.add('CE');
        types.add('UMF');
        
        test.startTest();
        List<Account> resultType = UmuController.getUmuByType(types);
        System.assertEquals(8, resultType.size(), 'Account list size must be 8');
        test.stopTest();
    }
    
    @isTest
    static void testGetUmuByDelegation() {
        TestDataFactory.createMultipleAccounts('AGUASCALIENTES', 'CE', '001-AGUASCALIENTES', 3);
        TestDataFactory.createMultipleAccounts('UMF ZARAGOZA', 'UMF', '021-PUEBLA', 3);
        
        List<String> delegations = new List<String>();
        delegations.add('001-AGUASCALIENTES');
        delegations.add('021-PUEBLA');
        
        test.startTest();
        List<Account> result = UmuController.getUmuByDelegation(delegations);
        System.assertEquals(6, result.size(), 'Account list size must be 6');
        test.stopTest();
    }
    
    @isTest
    static void testGetUmuByTypeAndDelegation() {
        TestDataFactory.createMultipleAccounts('AGUASCALIENTES', 'CE', '001-AGUASCALIENTES', 3);
        TestDataFactory.createMultipleAccounts('UMF ZARAGOZA', 'UMF', '021-PUEBLA', 3);
        
        List<String> types = new List<String>();
        types.add('CE');
        
        List<String> delegations = new List<String>();
        delegations.add('001-AGUASCALIENTES');
        delegations.add('021-PUEBLA');
        
        test.startTest();
        List<Account> result = UmuController.getUmuByTypeAndDelegation(types, delegations);
        System.assertEquals(3, result.size(), 'Account list size must be 3');
        test.stopTest();
    }
    
    @isTest
    static void testGetUmuDelegationByType() {
        TestDataFactory.createMultipleAccounts('AGUASCALIENTES', 'CE', '001-AGUASCALIENTES', 5);
        TestDataFactory.createMultipleAccounts('UMF ZARAGOZA', 'UMF', '021-PUEBLA', 5);
        
        List<String> types = new List<String>();
        types.add('CE');
        types.add('UMF');
        
        test.startTest();
        List<Account> result = UmuController.getUmuDelegationByType(types);
        System.assertEquals(10, result.size(), 'Account list size must be 10');
        test.stopTest();
    }
    
    @isTest
    static void testGetUmusById() {
        List<Account> accountList = TestDataFactory.createMultipleAccounts(
            'AGUASCALIENTES', 'CE', '001-AGUASCALIENTES', 4);
        
        List<String> accountIds = new List<String>();
        for(Account acc : accountList) {
            accountIds.add(acc.Id);
        }
        
        test.startTest();
        List<Account> result = UmuController.getUmusById(accountIds);
        System.assertEquals(4, result.size(), 'Account list size must be 4');
        test.stopTest();
    }
    
    @IsTest
    static void testGetUmuMultiSelectOptions() {
        String objectName = 'Account';
        String fieldName = 'Tipo_UMU__c';
        
        Test.startTest();
        Integer size = UmuController.getUmuMultiSelectOptions(objectName, fieldName).size();
        System.assertEquals(13, size, 'Picklist size must return 13 values');
        Test.stopTest();
        
    }
}