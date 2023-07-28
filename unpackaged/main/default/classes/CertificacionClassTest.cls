@IsTest
public with sharing class CertificacionClassTest {

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
    static void testCertificacionClass_Recibido() { 
        Test.startTest();

        User testUser = [SELECT Id, ContactId FROM User WHERE Alias = 'testUser' LIMIT 1];

        Pedido__c pedido = [SELECT Id, Estatus__c, Total_de_Claves__c, Total_de_Piezas__c FROM Pedido__c LIMIT 1];  
        pedido.ID_de_Pedido__c = '000001';
        update pedido;

        Order__c orden = [SELECT Id FROM Order__c LIMIT 1];
        orden.Seguimiento__c = '{"En Firma":"Fecha:2023-07-02 12:06:51","Transferido":"Fecha:2023-07-02 12:06:37", ' +
            '"Enviado":"Fecha:2023-07-02 12:06:27","Verificando Disponibilidad":"Fecha:2023-07-02 12:06:18","Procesando":"Fecha:2023-07-01 15:38:19", ' +
            '"Preparando Envío":"Fecha:2023-07-02 12:06:23","Llegada de Transporte":"Fecha:2023-07-02 12:06:32","Recibido":"Fecha:2023-07-02 12:06:42"}';
        update orden;

        Product2 clave = TestDataFactory.createSingleProduct2('Medicina de Prueba'); 

        Order_Line_Item__c orderLineItem = new Order_Line_Item__c();
        orderLineItem.Pedido__c = pedido.Id;
        orderLineItem.Order__c = orden.Id;
        orderLineItem.Product__c = clave.Id;
        orderLineItem.Cantidad_Solicitada__c = 10;
        orderLineItem.Cantidad_Aprobada__c = 10;
        orderLineItem.Estatus_Aprobaci_n__c = 'Aprobado';
        orderLineItem.Cantidad_Autorizada__c = 10;
        orderLineItem.Estatus_Autorizaci_n__c = 'Autorizado'; 
        orderLineItem.Costo_Promedio__c = 25; 
        orderLineItem.Piezas_Faltantes__c = 1; 
        insert orderLineItem; 

        Informacion_De_Lote__c infoLoteList = new Informacion_De_Lote__c();
        infoLoteList.Name = 'abc123';
        infoLoteList.Numero_de_Lote__c = 'abc123';
        infoLoteList.Cantidad__c = 10;
        infoLoteList.Fecha_de_Expiracion__c = Date.today().addDays(150);
        infoLoteList.Order_Line_Item__c = orderLineItem.Id;
        insert infoLoteList;

        List<String> productIds = new List<String>{clave.Id}; 

        String idsParameters = String.join(productIds, ',');
        
        System.runAs(testUser) {
            PageReference pageRef = new PageReference('/apex/CertificaciónDeOrden?id=' + orden.Id + '&listaProductos=' + idsParameters
                                                     + '&firmadoPor=' + testUser.ContactId);
            Test.setCurrentPage(pageRef);
            CertificacionClass certificationData = new CertificacionClass();
            System.assertNotEquals(null, certificationData);
        } 
        Test.stopTest(); 
    }

    @IsTest
    static void testCertificacionClass_Recibido_Parcial() { 
        Test.startTest();

        User testUser = [SELECT Id, ContactId FROM User WHERE Alias = 'testUser' LIMIT 1];

        Pedido__c pedido = [SELECT Id, Estatus__c, Total_de_Claves__c, Total_de_Piezas__c FROM Pedido__c LIMIT 1];  
        pedido.ID_de_Pedido__c = '000001';
        update pedido;

        Order__c orden = [SELECT Id FROM Order__c LIMIT 1];
        orden.Seguimiento__c = '{"En Firma":"Fecha:2023-07-02 12:06:51","Transferido":"Fecha:2023-07-02 12:06:37", ' +
            '"Enviado":"Fecha:2023-07-02 12:06:27","Verificando Disponibilidad":"Fecha:2023-07-02 12:06:18","Procesando":"Fecha:2023-07-01 15:38:19", ' +
            '"Preparando Envío":"Fecha:2023-07-02 12:06:23","Llegada de Transporte":"Fecha:2023-07-02 12:06:32","Recibido Parcial":"Fecha:2023-07-02 12:06:42"}';
        update orden;

        Product2 clave = TestDataFactory.createSingleProduct2('Medicina de Prueba'); 

        Order_Line_Item__c orderLineItem = new Order_Line_Item__c();
        orderLineItem.Pedido__c = pedido.Id;
        orderLineItem.Order__c = orden.Id;
        orderLineItem.Product__c = clave.Id;
        orderLineItem.Cantidad_Solicitada__c = 10;
        orderLineItem.Cantidad_Aprobada__c = 10;
        orderLineItem.Estatus_Aprobaci_n__c = 'Aprobado';
        orderLineItem.Cantidad_Autorizada__c = 10;
        orderLineItem.Estatus_Autorizaci_n__c = 'Autorizado'; 
        orderLineItem.Costo_Promedio__c = 25; 
        orderLineItem.Piezas_Faltantes__c = 1; 
        insert orderLineItem; 

        List<String> productIds = new List<String>{clave.Id}; 

        String idsParameters = String.join(productIds, ',');
        
        System.runAs(testUser) {
            PageReference pageRef = new PageReference('/apex/CertificaciónDeOrden?id=' + orden.Id + '&listaProductos=' + idsParameters
                                                     + '&firmadoPor=' + testUser.ContactId);
            Test.setCurrentPage(pageRef);
            CertificacionClass certificationData = new CertificacionClass();
            System.assertNotEquals(null, certificationData);
        } 
        Test.stopTest(); 
    }
}