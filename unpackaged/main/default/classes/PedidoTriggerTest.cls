@isTest
public with sharing class PedidoTriggerTest {

    @TestSetup
	static void createTestData() {
        String uniqueUserName = String.ValueOf(System.Now()).replaceAll('[^a-zA-Z0-9]', '');
        User user = TestDataFactory.initCommunityLoginUser(uniqueUserName);
    }

    @isTest 
    static void testBeforeInsertPedido_Ordinario_Juntos_HR() {
        User user = [SELECT Id, ContactId FROM User WHERE Alias = 'testUser' LIMIT 1];

        List<Id> accountIdList = new List<Id>();
        List<AccountContactRelation> accountContactList = [
            SELECT AccountId, Account.Name  
            FROM AccountContactRelation 
            WHERE ContactId =: user.ContactId
        ];  
        for(AccountContactRelation accConRel : accountContactList){
            accountIdList.add(accConRel.AccountId);
        }

        Account acc = [SELECT Id, UMU__c FROM Account WHERE Id =: accountIdList[0]];
        acc.UMU__c = 'HR';
        update acc; 

        List<Pedido__c> pedidoList = new List<Pedido__c>();
        for (Integer i = 0; i < 2; i++) {
            Pedido__c pedido = new Pedido__c();
            pedido.UMU__c = acc.Id;  
            pedido.Es_Programa__c = false;
            pedido.Autorizado_Por__c = user.ContactId;
            pedido.Tipo_de_Pedido__c = 'Ordinario';
            pedidoList.add(pedido);
        }
        insert pedidoList;

        Test.startTest();
        Pedido__c updatedPedido1 = [SELECT Id, ID_de_Pedido__c FROM Pedido__c WHERE ID_de_Pedido__c = '000001'];
        System.assertEquals(updatedPedido1.ID_de_Pedido__c, '000001');

        Pedido__c updatedPedido2 = [SELECT Id, ID_de_Pedido__c FROM Pedido__c WHERE ID_de_Pedido__c = '000002'];
        System.assertEquals(updatedPedido2.ID_de_Pedido__c, '000002');

        Test.stopTest();
    }

    @isTest 
    static void testBeforeInsertPedido_Ordinario_Separados() {
        User user = [SELECT Id, ContactId FROM User WHERE Alias = 'testUser' LIMIT 1];

        List<Id> accountIdList = new List<Id>();
        List<AccountContactRelation> accountContactList = [
            SELECT AccountId, Account.Name  
            FROM AccountContactRelation 
            WHERE ContactId =: user.ContactId
        ];  
        for(AccountContactRelation accConRel : accountContactList){
            accountIdList.add(accConRel.AccountId);
        }

        Pedido__c pedido1 = new Pedido__c();
        pedido1.UMU__c = accountIdList[0];  
        pedido1.Es_Programa__c = false;
        pedido1.Autorizado_Por__c = user.ContactId;
        pedido1.Tipo_de_Pedido__c = 'Ordinario';
        insert pedido1;

        Pedido__c pedido2 = new Pedido__c();
        pedido2.UMU__c = accountIdList[0];  
        pedido2.Es_Programa__c = false;
        pedido2.Autorizado_Por__c = user.ContactId;
        pedido2.Tipo_de_Pedido__c = 'Ordinario';
        insert pedido2;

        Test.startTest();
        Pedido__c updatedPedido1 = [SELECT Id, ID_de_Pedido__c FROM Pedido__c WHERE Id =: pedido1.Id];
        System.assertEquals(updatedPedido1.ID_de_Pedido__c, '000001');

        Pedido__c updatedPedido2 = [SELECT Id, ID_de_Pedido__c FROM Pedido__c WHERE Id =: pedido2.Id];
        System.assertEquals(updatedPedido2.ID_de_Pedido__c, '000002');

        Test.stopTest();
    }


    @isTest 
    static void testBeforeInsertPedido_Extraordinario_HR() {
        User user = [SELECT Id, ContactId FROM User WHERE Alias = 'testUser' LIMIT 1];

        List<Id> accountIdList = new List<Id>();
        List<AccountContactRelation> accountContactList = [
            SELECT AccountId, Account.Name  
            FROM AccountContactRelation 
            WHERE ContactId =: user.ContactId
        ];  
        for(AccountContactRelation accConRel : accountContactList){
            accountIdList.add(accConRel.AccountId);
        }

        Account acc = [SELECT Id, UMU__c FROM Account WHERE Id =: accountIdList[0]];
        acc.UMU__c = 'HR';
        update acc; 

        Pedido__c pedido1 = new Pedido__c();
        pedido1.UMU__c = accountIdList[0];  
        pedido1.Es_Programa__c = false;
        pedido1.Autorizado_Por__c = user.ContactId;
        pedido1.Tipo_de_Pedido__c = 'Extraordinario';
        insert pedido1;

        Test.startTest();
        Pedido__c updatedPedido1 = [SELECT Id, ID_de_Pedido__c FROM Pedido__c WHERE Id =: pedido1.Id];
        System.assertEquals(updatedPedido1.ID_de_Pedido__c, '000001-01');

        Test.stopTest();
    }
    
    @isTest 
    static void testBeforeInsertPedido_Extraordinario_Juntos() {
        User user = [SELECT Id, ContactId FROM User WHERE Alias = 'testUser' LIMIT 1];

        List<Id> accountIdList = new List<Id>();
        List<AccountContactRelation> accountContactList = [
            SELECT AccountId, Account.Name  
            FROM AccountContactRelation 
            WHERE ContactId =: user.ContactId
        ];  
        for(AccountContactRelation accConRel : accountContactList){
            accountIdList.add(accConRel.AccountId);
        }

        Account acc = [SELECT Id, UMU__c FROM Account WHERE Id =: accountIdList[0]];
        acc.UMU__c = 'HR';
        update acc; 

        List<Pedido__c> pedidoList = new List<Pedido__c>();
        for (Integer i = 0; i < 100; i++) {
            Pedido__c pedido = new Pedido__c();
            pedido.UMU__c = acc.Id;  
            pedido.Es_Programa__c = false;
            pedido.Autorizado_Por__c = user.ContactId;
            pedido.Tipo_de_Pedido__c = 'Extraordinario';
            pedidoList.add(pedido);
        }
        insert pedidoList;

        Test.startTest(); 

        Pedido__c updatedPedido1 = [SELECT Id, ID_de_Pedido__c FROM Pedido__c WHERE ID_de_Pedido__c = '000001-01'];
        System.assertEquals(updatedPedido1.ID_de_Pedido__c, '000001-01');

        Pedido__c updatedPedido2 = [SELECT Id, ID_de_Pedido__c FROM Pedido__c WHERE ID_de_Pedido__c = '000002-01'];
        System.assertEquals(updatedPedido2.ID_de_Pedido__c, '000002-01');

        Pedido__c updatedPedido99 = [SELECT Id, ID_de_Pedido__c FROM Pedido__c WHERE ID_de_Pedido__c = '000099-01'];
        System.assertEquals(updatedPedido99.ID_de_Pedido__c, '000099-01');

        Test.stopTest();
    }

    @isTest 
    static void testBeforeInsertPedido_Programa() {
        User user = [SELECT Id, ContactId FROM User WHERE Alias = 'testUser' LIMIT 1];
        
        List<Id> accountIdList = new List<Id>();
        List<AccountContactRelation> accountContactList = [
            SELECT AccountId, Account.Name  
            FROM AccountContactRelation 
            WHERE ContactId =: user.ContactId
        ];  
        for(AccountContactRelation accConRel : accountContactList){
            accountIdList.add(accConRel.AccountId);
        }

        Account acc = [SELECT Id, UMU__c FROM Account WHERE Id =: accountIdList[0]];
        acc.UMU__c = 'HR';
        update acc; 

        List<Pedido__c> pedidoList = new List<Pedido__c>();
        for (Integer i = 0; i < 100; i++) {
            Pedido__c pedido = new Pedido__c();
            pedido.UMU__c = acc.Id;  
            pedido.Es_Programa__c = true;
            pedido.Autorizado_Por__c = user.ContactId;
            pedido.Tipo_de_Pedido__c = 'Programa';
            pedidoList.add(pedido);
        }
        insert pedidoList;

        Test.startTest(); 
        Pedido__c updatedPedido1 = [SELECT Id, ID_de_Pedido__c FROM Pedido__c WHERE ID_de_Pedido__c = '00001-0001'];
        System.assertEquals(updatedPedido1.ID_de_Pedido__c, '00001-0001');

        Pedido__c updatedPedido2 = [SELECT Id, ID_de_Pedido__c FROM Pedido__c WHERE ID_de_Pedido__c = '00001-0002'];
        System.assertEquals(updatedPedido2.ID_de_Pedido__c, '00001-0002');

        Pedido__c updatedPedido99 = [SELECT Id, ID_de_Pedido__c FROM Pedido__c WHERE ID_de_Pedido__c = '00001-0099'];
        System.assertEquals(updatedPedido99.ID_de_Pedido__c, '00001-0099');
        
        Test.stopTest();
    }

    @isTest 
    static void testBeforeInsertPedido_Programa_Doble_Insercion() {

        Test.startTest(); 

        User user = [SELECT Id, ContactId FROM User WHERE Alias = 'testUser' LIMIT 1];

        List<Id> accountIdList = new List<Id>();
        List<AccountContactRelation> accountContactList = [
            SELECT AccountId, Account.Name  
            FROM AccountContactRelation 
            WHERE ContactId =: user.ContactId
        ];  
        for(AccountContactRelation accConRel : accountContactList){
            accountIdList.add(accConRel.AccountId);
        }

        Account acc = [SELECT Id, UMU__c FROM Account WHERE Id =: accountIdList[0]];
        acc.UMU__c = 'HR';
        update acc; 

        List<Pedido__c> pedidoList = new List<Pedido__c>();
        for (Integer i = 0; i < 99; i++) {
            Pedido__c pedido = new Pedido__c();
            pedido.UMU__c = acc.Id;  
            pedido.Es_Programa__c = true;
            pedido.Autorizado_Por__c = user.ContactId;
            pedido.Tipo_de_Pedido__c = 'Programa';
            pedidoList.add(pedido);
        }
        insert pedidoList;

        Pedido__c pedido2 = new Pedido__c();
        pedido2.UMU__c = acc.Id;  
        pedido2.Es_Programa__c = true;
        pedido2.Autorizado_Por__c = user.ContactId;
        pedido2.Tipo_de_Pedido__c = 'Urgencia Médica';
        insert pedido2;

        List<Pedido__c> pedidoList3 = new List<Pedido__c>();
        for (Integer i = 0; i < 99; i++) {
            Pedido__c pedido = new Pedido__c();
            pedido.UMU__c = acc.Id;  
            pedido.Es_Programa__c = true;
            pedido.Autorizado_Por__c = user.ContactId;
            pedido.Tipo_de_Pedido__c = 'Programa';
            pedidoList3.add(pedido);
        }
        insert pedidoList3;

        

        Pedido__c updatedPedido1 = [SELECT Id, ID_de_Pedido__c FROM Pedido__c WHERE ID_de_Pedido__c = '00001-0001'];
        System.assertEquals(updatedPedido1.ID_de_Pedido__c, '00001-0001');

        Pedido__c updatedPedido99 = [SELECT Id, ID_de_Pedido__c FROM Pedido__c WHERE ID_de_Pedido__c = '00001-0099'];
        System.assertEquals(updatedPedido99.ID_de_Pedido__c, '00001-0099');

        Pedido__c updatedPedido2 = [SELECT Id, ID_de_Pedido__c FROM Pedido__c WHERE ID_de_Pedido__c LIKE: '00002-0001'];
        System.assertEquals(updatedPedido2.ID_de_Pedido__c, '00002-0001');

       Pedido__c updatedPedido3_1 = [SELECT Id, ID_de_Pedido__c FROM Pedido__c WHERE ID_de_Pedido__c = '00003-0001'];
        System.assertEquals(updatedPedido3_1.ID_de_Pedido__c, '00003-0001');

        Pedido__c updatedPedido3_99 = [SELECT Id, ID_de_Pedido__c FROM Pedido__c WHERE ID_de_Pedido__c = '00003-0099'];
        System.assertEquals(updatedPedido3_99.ID_de_Pedido__c, '00003-0099');

        Test.stopTest();
    }

}