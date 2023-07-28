@isTest
public with sharing class listaDeClavesControladorTest {
    
    @TestSetup
    static void makeData(){

        // Crear Account 

        Account account = new Account(
            Name = 'AGUASCALIENTESTEST',
            Delegaci_n__c = '001-AGUASCALIENTES',
            Clave_Presupuestal__c = '00412452'
        );

        insert account;

        // Crear DPN
        
        DPN__c dpn = new DPN__c(
            Account__c = account.Id,
            Estatus__c = 'Activo'
        );

        insert dpn;

        // Crear productos
        List<Product2> productList = new List<Product2>();
        List<DPN_Line_Item__c> dpnLineItemList = new List<DPN_Line_Item__c>();

        for(Integer x = 1; x <= 3; x++){
            Product2 product = new Product2(
                Name = 'Omeprazol ' + x,
                Fraction__c = 'Controlado ' + x
            );

            productList.add(product);
        }

        insert productList;

        // Crear DPN line items
        for (Product2 product: productList){
            DPN_Line_Item__c dpnLineItem = new DPN_Line_Item__c(
                Consumido__c = 2,
                L_mite_Mensual__c = 100,
                Product__c = product.Id,
                Activo__c = true,
                DPN__c = dpn.Id
            );
            dpnLineItemList.add(dpnLineItem);
        }

        insert dpnLineItemList;
    }

    @isTest
    static void obtenerListaDeClavesControlado23Test(){

        Account account = [SELECT Id FROM Account WHERE Name = 'AGUASCALIENTESTEST' LIMIT 1];
        DPN__c dpn = [SELECT Id, Estatus__c, Account__c FROM DPN__c];
        List<Product2> productList = [SELECT Id, Fraction__c FROM Product2];
        List<DPN_Line_Item__c> dpnLineItem = [SELECT Id FROM DPN_Line_Item__c];

        Test.startTest();
            List<DPN_Line_Item__c> dpnLineItemTest = listaDeClavesControlador.obtenerListaDeClaves(account.Id, false, true, true);
        Test.stopTest();

        System.assertEquals(2, dpnLineItemTest.size(), 'El resultado debe de ser 2.');
    }

    @isTest
    static void obtenerListaDeClavesControlado1Test(){

        Account account = [SELECT Id FROM Account WHERE Name = 'AGUASCALIENTESTEST' LIMIT 1];
        DPN__c dpn = [SELECT Id, Estatus__c, Account__c FROM DPN__c];
        List<Product2> productList = [SELECT Id, Fraction__c FROM Product2];
        List<DPN_Line_Item__c> dpnLineItem = [SELECT Id FROM DPN_Line_Item__c];

        Test.startTest();
            List<DPN_Line_Item__c> dpnLineItemTest = listaDeClavesControlador.obtenerListaDeClaves(account.Id, true, false, false);
        Test.stopTest();

        System.assertEquals(1, dpnLineItemTest.size(), 'El resultado debe de ser 1.');
    }


    @isTest
    static void mostrarDpnLineItemTest(){
        
        List<DPN_Line_Item__c> dpnLineItem = [SELECT Id, Activo__c FROM DPN_Line_Item__c];
        List<DPN_Line_Item__c> dpnLineItemToUpdate = new List<DPN_Line_Item__c>();

        for(DPN_Line_Item__c dpnLine: dpnLineItem){
            dpnLine.Activo__c = false;
            dpnLineItemToUpdate.add(dpnLine);
        }
        
        Test.startTest();
         List<DPN_Line_Item__c> dpnLineItemUpdate = listaDeClavesControlador.mostrarDpnLineItem(dpnLineItemToUpdate);
        Test.stopTest();

        for(DPN_Line_Item__c dpnLineItemCheck: dpnLineItemUpdate){
            system.assert(dpnLineItemCheck.Activo__c == false);
        }
    }

    @isTest
    static void mostrarDpnLineItemTryCatchTest(){
        
        List<DPN_Line_Item__c> dpnLineItemToUpdate = new List<DPN_Line_Item__c>();
        
        try {
            Test.startTest();
                List<DPN_Line_Item__c> dpnLineItemUpdate = listaDeClavesControlador.mostrarDpnLineItem(dpnLineItemToUpdate);
            Test.stopTest();
        } catch (listaDeClavesControlador.MyCustomException e) {
            System.assertEquals('An error has ocurred.', e.getMessage());
        }

    }

}