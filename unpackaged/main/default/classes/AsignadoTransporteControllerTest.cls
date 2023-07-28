@isTest
public with sharing class AsignadoTransporteControllerTest {
    
    @TestSetup
    static void setup(){ 
        User user = TestDataFactory.initCommunityLoginUser('testuser');
        
        System.runAs(user) {
            Account acc = TestDataFactory.createSingleAccount('Test Account');
            Contact con = TestDataFactory.createSingleContactRelatedToAccount(acc.Id, 'Louise', 'Santana', 'Todas');
            
            Product2 p1 = TestDataFactory.createSingleProduct2('LINAGLIPTINA');
            Product2 p2 = TestDataFactory.createSingleProduct2('JARABE PARA GRIPA');
            
            String jsonToSend = '[{"Idcontacto":"' + con.Id + '" , "esPrograma": false, "IdUmu": "' +
                acc.Id + '","TipoDePedido": "Ordinario","ordenesDetails": [{"insumoId": "' +
                p1.Id + '","CantidadSolicitada": 5},{"insumoId": "' + p2.Id + '","CantidadSolicitada": 5}]}]';
            
            Entrega__c e = TestDataFactory.createSingleDelivery('No Asignado');
            
            Test.startTest();
            List<Order__c> orders = controladorGeneracionPedidos.deserializeOrders(jsonToSend);
            orders[0].Entrega__c = e.Id;
            update orders[0];
            Test.stopTest();
        }
    }
  
    @IsTest
    static void getEntregasTest() {
        Entrega__c entrega = [SELECT Id, Name, Estado__c, Fecha_de_Inicio__c FROM Entrega__c LIMIT 1];
        
        Test.startTest();
        List<Object> objectList = AsignadoTransporteController.getEntregas(entrega.Name);
        Assert.areEqual(1, objectList.size());
        Test.stopTest();
    }
    
    @isTest
    static void updateEntregaAsignarTest() {
        Entrega__c entrega = [SELECT Id, Name, Estado__c, Fecha_de_Inicio__c FROM Entrega__c LIMIT 1];
        User user = [SELECT Id, UserName FROM User LIMIT 1];
        
        Test.startTest();
        AsignadoTransporteController.updateEntregaAsignar(entrega.Name, user.Id);
        Entrega__c entrega2 = [SELECT Id, Name, Estado__c, Fecha_de_Inicio__c FROM Entrega__c LIMIT 1];
        System.assertEquals(entrega2.Estado__c, 'Asignado');
        
        try {
            AsignadoTransporteController.updateEntregaAsignar(entrega.Id, user.Id);
            System.assert(false, 'Se esperaba una excepción pero no se generó');
        } catch (AuraHandledException e) {
            System.assertEquals('Script-thrown exception', e.getMessage(), 'El mensaje de error no coincide');
        }
        Test.stopTest();
    }
    
    @isTest
    static void desasignarEntregaTest() {
        Entrega__c entrega = [SELECT Id, Name, Estado__c, Fecha_de_Inicio__c FROM Entrega__c LIMIT 1];
        User user = [SELECT Id, UserName FROM User LIMIT 1];
        
        Test.startTest();
        AsignadoTransporteController.desasignarEntrega(entrega.Id);
        Entrega__c entrega2 = [SELECT Id, Name, Estado__c, Fecha_de_Inicio__c FROM Entrega__c LIMIT 1];
        System.assertEquals(entrega2.Estado__c, 'No Asignado');
        Test.stopTest();
    }
    
    @isTest
    static void finalizarEntregaTest() {
        Entrega__c entrega = [SELECT Id, Name, Estado__c, Fecha_de_Inicio__c FROM Entrega__c LIMIT 1];
        User user = [SELECT Id, UserName FROM User LIMIT 1];
        
        Test.startTest();
        AsignadoTransporteController.finalizarEntrega(entrega.Id);
        Entrega__c entrega2 = [SELECT Id, Name, Estado__c, Fecha_de_Inicio__c FROM Entrega__c LIMIT 1];
        System.assertEquals(entrega2.Estado__c, 'Entregado');
        Test.stopTest();
    }
}