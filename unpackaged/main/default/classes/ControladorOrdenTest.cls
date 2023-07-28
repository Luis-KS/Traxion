@IsTest
public with sharing class ControladorOrdenTest {

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
    static void testControladorOrden() { 

        Test.startTest();

        User testUser = [SELECT Id, ContactId FROM User WHERE Alias = 'testUser' LIMIT 1];

        Pedido__c pedido = [SELECT Id, Estatus__c, Total_de_Claves__c, Total_de_Piezas__c FROM Pedido__c LIMIT 1 FOR UPDATE];  
        pedido.ID_de_Pedido__c = '000001';
        update pedido;

        Order__c orden = [SELECT Id FROM Order__c LIMIT 1 FOR UPDATE];

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
        orderLineItem.Cantidad_de_Piezas__c = 10;
        insert orderLineItem; 

        List<String> productIds = new List<String>{clave.Id}; 

        String idsParameters = String.join(productIds, ',');
        
        System.runAs(testUser) {
            Pagereference pageRef = new Pagereference('/apex/ConfirmacionDePedido?id=' + orden.Id); 
            Test.setCurrentPage(pageRef);
            controladorOrden ordenData = new controladorOrden();
            System.assertNotEquals(null, ordenData);
        } 
        Test.stopTest(); 

    }
}