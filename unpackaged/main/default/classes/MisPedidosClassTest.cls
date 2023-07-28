@isTest
public class MisPedidosClassTest { 

    @TestSetup
	static void createTestData() {
        String uniqueUserName = String.ValueOf(System.Now()).replaceAll('[^a-zA-Z0-9]', '');
        User user = TestDataFactory.initCommunityLoginUser(uniqueUserName);

        List<AccountContactRelation> accountContactList = [
            SELECT AccountId, Account.Name  
            FROM AccountContactRelation 
            WHERE ContactId =: user.ContactId
        ];   

        Account acc = [SELECT Id, Delegaci_n__c FROM Account WHERE Id =: accountContactList[0].AccountId];
        System.debug(acc);

        Pedido__c pedido = new Pedido__c();
        pedido.UMU__c = acc.Id;  
        pedido.Es_Programa__c = false;
        pedido.Autorizado_Por__c = user.ContactId;
        insert pedido;

        Order__c order = new Order__c();
        order.Pedido__c = pedido.Id;
        order.UMU__c = acc.Id;
        order.Contacto__c = user.ContactId;
        order.Tipo_de_Pedido__c = 'Ordinario';
        order.Estatus__c = 'Verificando Disponibilidad';
        insert order;
    }

    @isTest
    static void testGetMisPedidos_Ordinario(){
        Test.startTest();
        Date hoy = Date.today();
        Date fechaInicio = hoy.addDays(-5);
        Date fechaFin = hoy.addDays(5);

        User testUser = [SELECT Id, ContactId FROM User WHERE Alias = 'testUser' LIMIT 1];
        
        System.runAs(testUser) {
            List<Pedido__c> pedidoList = MisPedidosClass.getMisPedidos(fechaInicio, fechaFin); 
            System.assertEquals(1, pedidoList.size(), 'Valor esperado 1');
        }
        Test.stopTest();
    } 

    @isTest
    static void testGetMisPedidos_Programa(){
        Test.startTest();
        Date hoy = Date.today();
        Date fechaInicio = hoy.addDays(-5);
        Date fechaFin = hoy.addDays(5);

        User testUser = [SELECT Id, ContactId FROM User WHERE Alias = 'testUser' LIMIT 1];
        
        Order__c orden = [SELECT Id, Tipo_de_Pedido__c FROM Order__c LIMIT 1];
        orden.Tipo_de_Pedido__c = 'Programa';
        update orden;

        System.runAs(testUser) {
            List<Pedido__c> pedidoList = MisPedidosClass.getMisPedidos(fechaInicio, fechaFin); 
            System.assertEquals(1, pedidoList.size(), 'Valor esperado 1');
        }
        Test.stopTest();
    } 

    @isTest
    static void testGetMisPedidos_Replaneacion(){
        Test.startTest();
        Date hoy = Date.today();
        Date fechaInicio = hoy.addDays(-5);
        Date fechaFin = hoy.addDays(5);

        User testUser = [SELECT Id, ContactId FROM User WHERE Alias = 'testUser' LIMIT 1];
        
        Order__c orden = [SELECT Id, Tipo_de_Pedido__c FROM Order__c LIMIT 1];
        orden.Tipo_de_Pedido__c = 'Replaneación';
        update orden;

        System.runAs(testUser) {
            List<Pedido__c> pedidoList = MisPedidosClass.getMisPedidos(fechaInicio, fechaFin); 
            System.assertEquals(1, pedidoList.size(), 'Valor esperado 1');
        }
        Test.stopTest();
    } 

    @isTest
    static void testGetMisPedidos_EsProgramaExtraordinario_True(){
        Test.startTest();
        Date hoy = Date.today();
        Date fechaInicio = hoy.addDays(-5);
        Date fechaFin = hoy.addDays(5);

        User testUser = [SELECT Id, ContactId FROM User WHERE Alias = 'testUser' LIMIT 1];
        
        Order__c orden = [SELECT Id, Tipo_de_Pedido__c FROM Order__c LIMIT 1];
        orden.Tipo_de_Pedido__c = 'Extraordinario';
        update orden;

        Pedido__c pedido = [SELECT Id, Es_Programa__c FROM Pedido__c LIMIT 1];  
        pedido.Es_Programa__c = true;
        update pedido;

        System.runAs(testUser) {
            List<Pedido__c> pedidoList = MisPedidosClass.getMisPedidos(fechaInicio, fechaFin); 
            System.assertEquals(1, pedidoList.size(), 'Valor esperado 1');
        }
        Test.stopTest();
    } 

    @isTest
    static void testGetMisPedidos_EsProgramaExtraordinario_False(){
        Test.startTest();
        Date hoy = Date.today();
        Date fechaInicio = hoy.addDays(-5);
        Date fechaFin = hoy.addDays(5);

        User testUser = [SELECT Id, ContactId FROM User WHERE Alias = 'testUser' LIMIT 1];

        Order__c orden = [SELECT Id, Tipo_de_Pedido__c FROM Order__c LIMIT 1];
        orden.Tipo_de_Pedido__c = 'Extraordinario';
        update orden;

        System.runAs(testUser) {
            List<Pedido__c> pedidoList = MisPedidosClass.getMisPedidos(fechaInicio, fechaFin); 
            System.assertEquals(1, pedidoList.size(), 'Valor esperado 1');
        }
        Test.stopTest();
    } 

    @isTest
    static void testGetFilteredOrdersAndOlis_OLI_Aprobada(){
        Test.startTest();
        Date hoy = Date.today();
        Date fechaInicio = hoy.addDays(-5);
        Date fechaFin = hoy.addDays(5);

        User testUser = [SELECT Id, ContactId FROM User WHERE Alias = 'testUser' LIMIT 1];

        Pedido__c pedido = [SELECT Id, Estatus__c, Total_de_Claves__c, Total_de_Piezas__c FROM Pedido__c LIMIT 1];  
        pedido.Estatus__c = 'Ver Detalles';
        pedido.Total_de_Claves__c = 0;
        pedido.Total_de_Piezas__c = 0;
        update pedido;

        Order__c orden = [SELECT Id FROM Order__c LIMIT 1];

        Product2 clave = TestDataFactory.createSingleProduct2('Medicina de Prueba'); 

        Order_Line_Item__c orderLineItem = new Order_Line_Item__c();
        orderLineItem.Pedido__c = pedido.Id;
        orderLineItem.Order__c = orden.Id;
        orderLineItem.Product__c = clave.Id;
        insert orderLineItem; 

        List<String> orderIdList = new List<String>{orden.Id}; 
        

        System.runAs(testUser) {
            List<Order__c> pedidoList = MisPedidosClass.getFilteredOrdersAndOlis(orderIdList); 
            System.assertEquals(1, pedidoList.size(), 'Valor esperado 1'); 
        }
        Test.stopTest();
    } 

    @isTest
    static void testGetFilteredOrdersAndOlis_OLI_Rechazada(){
        Test.startTest();
        Date hoy = Date.today();
        Date fechaInicio = hoy.addDays(-5);
        Date fechaFin = hoy.addDays(5);

        User testUser = [SELECT Id, ContactId FROM User WHERE Alias = 'testUser' LIMIT 1];

        Pedido__c pedido = [SELECT Id, Estatus__c, Total_de_Claves__c, Total_de_Piezas__c FROM Pedido__c LIMIT 1];  
        pedido.Estatus__c = 'Ver Detalles';
        pedido.Total_de_Claves__c = 0;
        pedido.Total_de_Piezas__c = 0;
        update pedido;

        Order__c orden = [SELECT Id FROM Order__c LIMIT 1];
        orden.Tipo_de_Pedido__c = 'Extraordinario';
        update orden;

        Product2 clave = TestDataFactory.createSingleProduct2('Medicina de Prueba'); 

        Order_Line_Item__c orderLineItem = new Order_Line_Item__c();
        orderLineItem.Pedido__c = pedido.Id;
        orderLineItem.Order__c = orden.Id;
        orderLineItem.Product__c = clave.Id;
        orderLineItem.Estatus_Autorizaci_n__c = 'Rechazado';
        insert orderLineItem; 

        List<String> orderIdList = new List<String>{orden.Id}; 
        

        System.runAs(testUser) {
            List<Order__c> pedidoList = MisPedidosClass.getFilteredOrdersAndOlis(orderIdList); 
            System.assertEquals(0, pedidoList.size(), 'Valor esperado 0'); 
        }
        Test.stopTest();
    } 

    @isTest
    static void testGetFilteredOrdersAndOlis_OLI_Autorizada(){
        Test.startTest();
        Date hoy = Date.today();
        Date fechaInicio = hoy.addDays(-5);
        Date fechaFin = hoy.addDays(5);

        User testUser = [SELECT Id, ContactId FROM User WHERE Alias = 'testUser' LIMIT 1];

        Pedido__c pedido = [SELECT Id, Estatus__c, Total_de_Claves__c, Total_de_Piezas__c FROM Pedido__c LIMIT 1];  
        pedido.Estatus__c = 'Ver Detalles';
        pedido.Total_de_Claves__c = 0;
        pedido.Total_de_Piezas__c = 0;
        update pedido;

        Order__c orden = [SELECT Id FROM Order__c LIMIT 1];
        orden.Tipo_de_Pedido__c = 'Extraordinario';
        update orden;

        Product2 clave = TestDataFactory.createSingleProduct2('Medicina de Prueba'); 

        Order_Line_Item__c orderLineItem = new Order_Line_Item__c();
        orderLineItem.Pedido__c = pedido.Id;
        orderLineItem.Order__c = orden.Id;
        orderLineItem.Product__c = clave.Id;
        orderLineItem.Estatus_Autorizaci_n__c = 'Autorizado';
        insert orderLineItem; 

        List<String> orderIdList = new List<String>{orden.Id}; 
        

        System.runAs(testUser) {
            List<Order__c> pedidoList = MisPedidosClass.getFilteredOrdersAndOlis(orderIdList); 
            System.assertEquals(1, pedidoList.size(), 'Valor esperado 1'); 
        }
        Test.stopTest();
    } 

    @IsTest
    static void testGetOrderEvidence() {
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

        List<String> orderIdList = new List<String>{orden.Id};

        Map<Id, ContentVersion> result = MisPedidosClass.getOrderEvidence(orderIdList); 
        System.assertEquals(result.size(), 1, 'Map should not be empty');
        Test.stopTest(); 
    }

    @IsTest
    static void testCertificateOrder() {
        Test.startTest(); 
        Order__c orden = [SELECT Id FROM Order__c LIMIT 1]; 
        Order__c result = MisPedidosClass.certificateOrder(String.valueOf(orden.Id)); 
        Assert.isNotNull(result, 'result should not be null');
        Test.stopTest(); 
    }

    @IsTest
    static void testRejectOrder() {
        Test.startTest(); 
        Order__c orden = [SELECT Id FROM Order__c LIMIT 1]; 
        Order__c rejectedOrder = MisPedidosClass.rejectOrder(String.valueOf(orden.Id));
        System.assertNotEquals(null, rejectedOrder);
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

        List<String> result = MisPedidosClass.getFieldIdsList(orden.Id);  
        System.assertNotEquals(null, result);
        Test.stopTest(); 
    }

    @IsTest
    static void testReenviarOrden() {
        Test.startTest(); 
        Order__c orden = [SELECT Id FROM Order__c LIMIT 1];

        MisPedidosClass.reenviarOrden(orden.Id);

        Order__c updatedOrder = [SELECT Id, Estatus__c FROM Order__c WHERE Id =: orden.Id LIMIT 1];
        System.assertEquals('Procesando', updatedOrder.Estatus__c); 
        Test.stopTest(); 
    }
}