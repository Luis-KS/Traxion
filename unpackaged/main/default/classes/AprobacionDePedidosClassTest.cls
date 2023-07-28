@isTest
public with sharing class AprobacionDePedidosClassTest {

    public class DataPedido{
        public Date fechaInicio;
        public Date fechaFin;
        public Boolean esAprobacion;
        public String estatusNoOrdinario;
    }

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

        Pedido__c pedido = new Pedido__c();
        pedido.UMU__c = accountIdList[0];  
        pedido.Es_Programa__c = false;
        pedido.Autorizado_Por__c = user.ContactId;
        insert pedido;

        Order__c order = new Order__c();
        order.Pedido__c = pedido.Id;
        order.UMU__c = accountIdList[0];
        order.Contacto__c = user.ContactId;
        order.Tipo_de_Pedido__c = 'Ordinario';
        order.Estatus__c = 'Verificando Disponibilidad';
        insert order;
    }

    @IsTest
    static void testGetFilteredPedidos_Aprobado_Pendiente() {
        Test.startTest();

        // Create test data
        User testUser = [SELECT Id, ContactId FROM User WHERE Alias = 'testUser' LIMIT 1];
        
        Date hoy = Date.today();
        DataPedido dataPedido = new DataPedido();
        dataPedido.fechaInicio = hoy.addDays(-5);
        dataPedido.fechaFin = hoy.addDays(5);
        dataPedido.esAprobacion = true;
        dataPedido.estatusNoOrdinario = 'Pendiente';

        Pedido__c pedido = [SELECT Id FROM Pedido__c LIMIT 1];

        AccountContactRelation accContactRlt = [
            SELECT AccountId, Account.Name  
            FROM AccountContactRelation 
            WHERE ContactId =: testUser.ContactId
            LIMIT 1
        ];  

        Order__c order = [SELECT Id FROM Order__c LIMIT 1];

        // Create and insert test Order_Line_Item__c records
        List<Order_Line_Item__c> oliList = new List<Order_Line_Item__c>();
        for (Integer i = 0; i < 5; i++) {
            Order_Line_Item__c oli = new Order_Line_Item__c(
                Order__c = order.Id,
                UMU__c = accContactRlt.AccountId,
                Pedido__c = pedido.Id,
                Estatus_Aprobaci_n__c = 'Pendiente'
            );
            oliList.add(oli);
        }
        insert oliList;

        System.runAs(testUser){
            // Call the method being tested
            List<Pedido__c> result = AprobacionDePedidosClass.getFilteredPedidos(JSON.serialize(dataPedido));
        
            // Assertions
            System.assertEquals(1, result.size()); 
        }  
        Test.stopTest();
    }

    @IsTest
    static void testGetFilteredPedidos_Autorizado_Pendiente() {
        Test.startTest();

        // Create test data
        User testUser = [SELECT Id, ContactId FROM User WHERE Alias = 'testUser' LIMIT 1];
        
        Date hoy = Date.today();
        DataPedido dataPedido = new DataPedido();
        dataPedido.fechaInicio = hoy.addDays(-5);
        dataPedido.fechaFin = hoy.addDays(5);
        dataPedido.esAprobacion = false;
        dataPedido.estatusNoOrdinario = 'Pendiente';

        Pedido__c pedido = [SELECT Id FROM Pedido__c LIMIT 1];

        AccountContactRelation accContactRlt = [
            SELECT AccountId, Account.Name  
            FROM AccountContactRelation 
            WHERE ContactId =: testUser.ContactId
            LIMIT 1
        ];  

        Order__c order = [SELECT Id FROM Order__c LIMIT 1];

        // Create and insert test Order_Line_Item__c records
        List<Order_Line_Item__c> oliList = new List<Order_Line_Item__c>();
        for (Integer i = 0; i < 5; i++) {
            Order_Line_Item__c oli = new Order_Line_Item__c(
                Order__c = order.Id,
                UMU__c = accContactRlt.AccountId,
                Pedido__c = pedido.Id,
                Estatus_Aprobaci_n__c = 'Aprobado'
            );
            oliList.add(oli);
        }
        insert oliList;

        System.runAs(testUser){
            // Call the method being tested
            List<Pedido__c> result = AprobacionDePedidosClass.getFilteredPedidos(JSON.serialize(dataPedido));
        
            // Assertions
            System.assertEquals(1, result.size()); 
        }  
        Test.stopTest();
    } 

    @IsTest
    static void testUpdateOrderLineItem_Aprobacion_Aprobado() {
        Test.startTest();

        // Create test data
        User testUser = [SELECT Id, ContactId FROM User WHERE Alias = 'testUser' LIMIT 1];

        Pedido__c pedido = [SELECT Id FROM Pedido__c LIMIT 1];

        AccountContactRelation accContactRlt = [
            SELECT AccountId, Account.Name  
            FROM AccountContactRelation 
            WHERE ContactId =: testUser.ContactId
            LIMIT 1
        ];  

        Order__c order = [SELECT Id FROM Order__c LIMIT 1];

        Order_Line_Item__c oli = new Order_Line_Item__c(
            Order__c = order.Id,
            UMU__c = accContactRlt.AccountId,
            Pedido__c = pedido.Id,
            Cantidad_Solicitada__c = 5
        );
        insert oli;

        System.runAs(testUser){
            // Call the method being tested
            List<Pedido__c> result = AprobacionDePedidosClass.updateOrderLineItem(oli.Id, 'Aprobado', 5, '', true);
            // Assertions
            System.assertNotEquals(null, result); // Ensure the result is not null
        }
        Test.stopTest();
    }

    @IsTest
    static void testUpdateOrderLineItem_Aprobacion_Rechazado() {
        Test.startTest();

        // Create test data
        User testUser = [SELECT Id, ContactId FROM User WHERE Alias = 'testUser' LIMIT 1];

        Pedido__c pedido = [SELECT Id FROM Pedido__c LIMIT 1];

        AccountContactRelation accContactRlt = [
            SELECT AccountId, Account.Name  
            FROM AccountContactRelation 
            WHERE ContactId =: testUser.ContactId
            LIMIT 1
        ];  

        Order__c order = [SELECT Id FROM Order__c LIMIT 1];

        Order_Line_Item__c oli = new Order_Line_Item__c(
            Order__c = order.Id,
            UMU__c = accContactRlt.AccountId,
            Pedido__c = pedido.Id,
            Cantidad_Solicitada__c = 5
        );
        insert oli;

        System.runAs(testUser){
            // Call the method being tested
            List<Pedido__c> result = AprobacionDePedidosClass.updateOrderLineItem(oli.Id, 'Rechazado', 0, '', true);
            // Assertions
            System.assertNotEquals(null, result); // Ensure the result is not null
        }
        Test.stopTest();
    }

    @IsTest
    static void testUpdateOrderLineItem_Autorizacion_Autorizado() {
        Test.startTest();

        // Create test data
        User testUser = [SELECT Id, ContactId FROM User WHERE Alias = 'testUser' LIMIT 1];

        Pedido__c pedido = [SELECT Id FROM Pedido__c LIMIT 1];

        AccountContactRelation accContactRlt = [
            SELECT AccountId, Account.Name  
            FROM AccountContactRelation 
            WHERE ContactId =: testUser.ContactId
            LIMIT 1
        ];  

        Order__c order = [SELECT Id FROM Order__c LIMIT 1];

        Order_Line_Item__c oli = new Order_Line_Item__c(
            Order__c = order.Id,
            UMU__c = accContactRlt.AccountId,
            Pedido__c = pedido.Id,
            Estatus_Aprobaci_n__c = 'Aprobado',
            Cantidad_Solicitada__c = 5
        );
        insert oli;

        System.runAs(testUser){
            // Call the method being tested
            List<Pedido__c> result = AprobacionDePedidosClass.updateOrderLineItem(oli.Id, 'Autorizado', 5, '', false);
            // Assertions
            System.assertNotEquals(null, result); // Ensure the result is not null
        }
        Test.stopTest();
    }
    

    @IsTest
    static void testUpdateIdDePedido_Aprobacion() {
        Test.startTest();

        // Create test data
        User testUser = [SELECT Id, ContactId FROM User WHERE Alias = 'testUser' LIMIT 1];

        Pedido__c pedido = [SELECT Id FROM Pedido__c LIMIT 1];

        Order__c order = [SELECT Id FROM Order__c LIMIT 1];

        AccountContactRelation accContactRlt = [
            SELECT AccountId, Account.Name  
            FROM AccountContactRelation 
            WHERE ContactId =: testUser.ContactId
            LIMIT 1
        ];  

        Order_Line_Item__c oli = new Order_Line_Item__c(
            UMU__c = accContactRlt.AccountId,
            Pedido__c = pedido.Id,
            Order__c = order.Id,
            Estatus_Aprobaci_n__c = 'Aprobado',
            Cantidad_Solicitada__c = 5
        );
        insert oli;

        System.runAs(testUser){
            // Call the method being tested 
            List<Pedido__c> updatedPedidos = AprobacionDePedidosClass.updateIdDePedido(pedido.Id, true);
            // Assertions
            System.assertNotEquals(null, updatedPedidos); // Ensure the result is not null
        }
        Test.stopTest();
    }

    @IsTest
    static void testUpdateIdDePedido_Aprobacion_Continuacion() {
        Test.startTest();

        // Create test data
        User testUser = [SELECT Id, ContactId FROM User WHERE Alias = 'testUser' LIMIT 1];

        Pedido__c pedido = [SELECT Id FROM Pedido__c LIMIT 1];

        Order__c order = [SELECT Id FROM Order__c LIMIT 1];

        AccountContactRelation accContactRlt = [
            SELECT AccountId, Account.Name  
            FROM AccountContactRelation 
            WHERE ContactId =: testUser.ContactId
            LIMIT 1
        ];  

        List<Order_Line_Item__c> oliList = new List<Order_Line_Item__c>();
        for (Integer i = 0; i < 5; i++) {
            Order_Line_Item__c oli = new Order_Line_Item__c(
                UMU__c = accContactRlt.AccountId,
                Pedido__c = pedido.Id,
                Order__c = order.Id,
                Estatus_Aprobaci_n__c = 'Pendiente'
            );
            oliList.add(oli);
        }
        insert oliList;

        oliList[0].Estatus_Aprobaci_n__c = 'Aprobado';
        update oliList;

        System.runAs(testUser){
            // Call the method being tested 
            List<Pedido__c> updatedPedidos = AprobacionDePedidosClass.updateIdDePedido(pedido.Id, true);
            // Assertions
            System.assertNotEquals(null, updatedPedidos); // Ensure the result is not null
        }
        Test.stopTest();
    }


    @IsTest
    static void testUpdateIdDePedido_Autorizacion() {
        Test.startTest();

        // Create test data
        User testUser = [SELECT Id, ContactId FROM User WHERE Alias = 'testUser' LIMIT 1];

        Pedido__c pedido = [SELECT Id FROM Pedido__c LIMIT 1];

        Order__c order = [SELECT Id FROM Order__c LIMIT 1];

        AccountContactRelation accContactRlt = [
            SELECT AccountId, Account.Name  
            FROM AccountContactRelation 
            WHERE ContactId =: testUser.ContactId
            LIMIT 1
        ];  

        Order_Line_Item__c oli = new Order_Line_Item__c(
            UMU__c = accContactRlt.AccountId,
            Pedido__c = pedido.Id,
            Order__c = order.Id,
            Cantidad_Solicitada__c = 5,
            Estatus_Aprobaci_n__c = 'Aprobado',
            Cantidad_Aprobada__c = 5,
            Estatus_Autorizaci_n__c = 'Autorizado'
        );
        insert oli;

        System.runAs(testUser){
            // Call the method being tested 
            List<Pedido__c> updatedPedidos = AprobacionDePedidosClass.updateIdDePedido(pedido.Id, false);
            // Assertions
            System.assertNotEquals(null, updatedPedidos); // Ensure the result is not null
        }
        Test.stopTest();
    }

    @IsTest
    static void testUpdateIdDePedido_Autorizacion_Continuacion() {
        Test.startTest();

        // Create test data
        User testUser = [SELECT Id, ContactId FROM User WHERE Alias = 'testUser' LIMIT 1];

        Pedido__c pedido = [SELECT Id FROM Pedido__c LIMIT 1];

        Order__c order = [SELECT Id FROM Order__c LIMIT 1];

        AccountContactRelation accContactRlt = [
            SELECT AccountId, Account.Name  
            FROM AccountContactRelation 
            WHERE ContactId =: testUser.ContactId
            LIMIT 1
        ];  

        List<Order_Line_Item__c> oliList = new List<Order_Line_Item__c>();
        for (Integer i = 0; i < 5; i++) {
            Order_Line_Item__c oli = new Order_Line_Item__c(
                UMU__c = accContactRlt.AccountId,
                Pedido__c = pedido.Id,
                Order__c = order.Id,
                Cantidad_Solicitada__c = 5,
                Estatus_Aprobaci_n__c = 'Aprobado',
                Cantidad_Aprobada__c = 5,
                Estatus_Autorizaci_n__c = 'Pendiente'
            );
            oliList.add(oli);
        }
        insert oliList;

        oliList[0].Estatus_Autorizaci_n__c = 'Autorizado';
        update oliList;

        System.runAs(testUser){
            // Call the method being tested 
            List<Pedido__c> updatedPedidos = AprobacionDePedidosClass.updateIdDePedido(pedido.Id, false);
            // Assertions
            System.assertNotEquals(null, updatedPedidos); // Ensure the result is not null
        }
        Test.stopTest();
    }

    @IsTest
    static void testGeneratePedidoInWMS() {
        Test.startTest();

        // Create test data
        User testUser = [SELECT Id, ContactId FROM User WHERE Alias = 'testUser' LIMIT 1];

        Pedido__c pedido = [SELECT Id FROM Pedido__c LIMIT 1];

        Order__c order = [SELECT Id FROM Order__c LIMIT 1];

        AccountContactRelation accContactRlt = [
            SELECT AccountId, Account.Name  
            FROM AccountContactRelation 
            WHERE ContactId =: testUser.ContactId
            LIMIT 1
        ];  

        List<Order_Line_Item__c> oliList = new List<Order_Line_Item__c>();
        for (Integer i = 0; i < 5; i++) {
            Order_Line_Item__c oli = new Order_Line_Item__c(
                UMU__c = accContactRlt.AccountId,
                Pedido__c = pedido.Id,
                Order__c = order.Id,
                Cantidad_Solicitada__c = 5,
                Estatus_Aprobaci_n__c = 'Aprobado',
                Cantidad_Aprobada__c = 5,
                Estatus_Autorizaci_n__c = 'Autorizado',
                Cantidad_Autorizada__c = 5
            );
            oliList.add(oli);
        }
        insert oliList;

        System.runAs(testUser){
            // Call the method being tested 
            String response = AprobacionDePedidosClass.generatePedidoInWMS(pedido.Id);
            // Assertions
            System.assertEquals('Success', response); // Ensure the result is not null
        }
        Test.stopTest();
    }

    @IsTest
    static void testGeneratePedidoInWMS_Empty() {
        Test.startTest();

        // Create test data
        User testUser = [SELECT Id, ContactId FROM User WHERE Alias = 'testUser' LIMIT 1];

        Pedido__c pedido = [SELECT Id FROM Pedido__c LIMIT 1];

        Order__c order = [SELECT Id FROM Order__c LIMIT 1];

        AccountContactRelation accContactRlt = [
            SELECT AccountId, Account.Name  
            FROM AccountContactRelation 
            WHERE ContactId =: testUser.ContactId
            LIMIT 1
        ];  

        List<Order_Line_Item__c> oliList = new List<Order_Line_Item__c>();
        for (Integer i = 0; i < 5; i++) {
            Order_Line_Item__c oli = new Order_Line_Item__c(
                UMU__c = accContactRlt.AccountId,
                Pedido__c = pedido.Id,
                Order__c = order.Id,
                Cantidad_Solicitada__c = 5,
                Estatus_Aprobaci_n__c = 'Aprobado',
                Cantidad_Aprobada__c = 5,
                Estatus_Autorizaci_n__c = 'Rechazado',
                Cantidad_Autorizada__c = 5
            );
            oliList.add(oli);
        }
        insert oliList;

        System.runAs(testUser){
            // Call the method being tested 
            String response = AprobacionDePedidosClass.generatePedidoInWMS(pedido.Id);
            // Assertions
            System.assertEquals('No go to WMS', response); // Ensure the result is not null
        }
        Test.stopTest();
    }

    @IsTest
    static void testSendEmailAprobacionAutorizacion_Aprobacion() {
        Test.startTest();

        // Create test data
        User testUser = [SELECT Id, ContactId FROM User WHERE Alias = 'testUser' LIMIT 1];

        Contact contact = [SELECT Id, Email FROM Contact WHERE Id =: testUser.ContactId LIMIT 1];

        Pedido__c pedido = [SELECT Id FROM Pedido__c LIMIT 1];
        pedido.ID_de_Pedido__c = '000001';
        update pedido;

        Order__c order = [SELECT Id FROM Order__c LIMIT 1];

        AccountContactRelation accContactRlt = [
            SELECT AccountId, Account.Name  
            FROM AccountContactRelation 
            WHERE ContactId =: testUser.ContactId
            LIMIT 1
        ];  

        Product2 clave = TestDataFactory.createSingleProduct2('Medicina de Prueba'); 

        Order_Line_Item__c oli = new Order_Line_Item__c(
            UMU__c = accContactRlt.AccountId,
            Pedido__c = pedido.Id,
            Order__c = order.Id,
            Product__c = clave.Id
        );
        insert oli;
 
        List<String> contactEmailList = new List<String>{contact.Email};

        AprobacionDePedidosClass.sendEmailAprobacionAutorizacion(false, pedido.Id, contact.Id, contactEmailList, 'Respuesta_Pre_Autorizacion');
        Test.stopTest();
    }

    @IsTest
    static void testSendEmailAprobacionAutorizacion_Autorizacion() {
        Test.startTest();

        // Create test data
        User testUser = [SELECT Id, ContactId FROM User WHERE Alias = 'testUser' LIMIT 1];

        Contact contact = [SELECT Id, Email FROM Contact WHERE Id =: testUser.ContactId LIMIT 1];

        Pedido__c pedido = [SELECT Id FROM Pedido__c LIMIT 1];
        pedido.ID_de_Pedido__c = '000001';
        update pedido;

        Order__c order = [SELECT Id FROM Order__c LIMIT 1];

        AccountContactRelation accContactRlt = [
            SELECT AccountId, Account.Name  
            FROM AccountContactRelation 
            WHERE ContactId =: testUser.ContactId
            LIMIT 1
        ];  

        Product2 clave = TestDataFactory.createSingleProduct2('Medicina de Prueba'); 

        Order_Line_Item__c oli = new Order_Line_Item__c(
            UMU__c = accContactRlt.AccountId,
            Pedido__c = pedido.Id,
            Order__c = order.Id,
            Product__c = clave.Id
        );
        insert oli;
 
        List<String> contactEmailList = new List<String>{contact.Email};

        AprobacionDePedidosClass.sendEmailAprobacionAutorizacion(true, pedido.Id, contact.Id, contactEmailList, 'Respuesta_Pre_Autorizacion');
        Test.stopTest();
    }

    @IsTest
    static void testGetFieldIdsList() {
        Test.startTest(); 
        Order__c orden = [SELECT Id FROM Order__c LIMIT 1];

        ContentVersion cv = new ContentVersion(
            Title = 'Evidencia',
            PathOnClient = 'Evidencia.jpg',
            VersionData = EncodingUtil.base64Decode('AA=='),
            IsMajorVersion = true
        );
        insert cv;

        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = orden.Id,
            ContentDocumentId = documents[0].Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;

        List<String> result = AprobacionDePedidosClass.getFieldIdsList(orden.Id);  
        System.assertNotEquals(null, result);
        Test.stopTest(); 
    }

    @IsTest
    static void testOliProductInformation() {
        Test.startTest(); 

        // Create test data
        User testUser = [SELECT Id, ContactId FROM User WHERE Alias = 'testUser' LIMIT 1];

        Contact contact = [SELECT Id, Email FROM Contact WHERE Id =: testUser.ContactId LIMIT 1];

        Pedido__c pedido = [SELECT Id FROM Pedido__c LIMIT 1];
        pedido.ID_de_Pedido__c = '000001';
        update pedido;

        Order__c order = [SELECT Id FROM Order__c LIMIT 1];
        order.Estatus__c = 'Enviado';
        update order;

        AccountContactRelation accContactRlt = [
            SELECT AccountId, Account.Name  
            FROM AccountContactRelation 
            WHERE ContactId =: testUser.ContactId
            LIMIT 1
        ]; 

        Account umu = [SELECT Id FROM Account WHERE Id =: accContactRlt.AccountId LIMIT 1];

        Product2 clave = TestDataFactory.createSingleProduct2('Medicina de Prueba'); 

        List<String> productIds = new List<String>{clave.Id};

        Order_Line_Item__c oli = new Order_Line_Item__c(
            UMU__c = umu.Id,
            Pedido__c = pedido.Id,
            Order__c = order.Id,
            Product__c = clave.Id,
            Cantidad_de_Piezas__c = 20
        );
        insert oli;

        DPN__c dpn = new DPN__c(
            Account__c = umu.Id,
            Estatus__c = 'Activo'
        );
        insert dpn;

        DPN_Line_Item__c dpnli = new DPN_Line_Item__c(
            DPN__c = dpn.Id,
            Product__c = clave.Id,
            L_mite_Mensual__c = 120231,
            Consumido__c = 24
        );
        insert dpnli;

        String result = AprobacionDePedidosClass.oliProductInformation(umu.Id, productIds);
        System.assertNotEquals(null, result);
        Test.stopTest(); 
    }

    @IsTest
    static void testUpdateTipoDePedido() {
        Test.startTest(); 

        // Create test data
        User testUser = [SELECT Id, ContactId FROM User WHERE Alias = 'testUser' LIMIT 1];

        Pedido__c pedido = [SELECT Id FROM Pedido__c LIMIT 1];

        Pedido__c result = AprobacionDePedidosClass.updateTipoDePedido(pedido.Id, 'Extraordinario');
        System.assertNotEquals(null, result);
        Test.stopTest(); 
    }
    
    
    @isTest
    static void getEntregasTryCatchTest(){
        
        String IdViaje = null;
        
        Test.startTest();
            try{
                AsignadoTransporteController.getEntregas(IdViaje);
            }catch(AuraHandledException e){
                
            }
        Test.stopTest();
    }

}