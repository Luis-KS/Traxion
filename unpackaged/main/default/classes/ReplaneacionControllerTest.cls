@isTest
public class ReplaneacionControllerTest {
    
    @TestSetup
    static void setup(){
        User user = TestDataFactory.initCommunityLoginUser('testuserreplaneacion');
        
        System.debug('user ---> ' + user);
        AccountContactRelation acr = [
                SELECT AccountId, Account.Name  
                FROM AccountContactRelation 
                WHERE ContactId =: user.ContactId];
        System.debug('acr ---> ' + acr);
        
        System.runAs(user) {
            Account acc = TestDataFactory.createSingleAccount('Test Account');
            Contact con = TestDataFactory.createSingleContactRelatedToAccount(acc.Id, 'Louise', 'Santana', 'Todas');
            
            Product2 p1 = TestDataFactory.createSingleProduct2('LINAGLIPTINA');
            Product2 p2 = TestDataFactory.createSingleProduct2('JARABE PARA GRIPA');
            
            String jsonToSend = '[{"Idcontacto":"' + con.Id + '" , "esPrograma": false, "IdUmu": "' +
                acr.AccountId + '","TipoDePedido": "Ordinario","ordenesDetails": [{"insumoId": "' +
                p1.Id + '","CantidadSolicitada": 5},{"insumoId": "' + p2.Id + '","CantidadSolicitada": 5}]}]';
            Entrega__c e = TestDataFactory.createSingleDelivery('Asignado');
            
            Test.startTest();
            List<Order__c> orders = controladorGeneracionPedidos.deserializeOrders(jsonToSend);
            orders[0].Estatus__c = 'Recibido Parcial'; 
            orders[0].Entrega__c = e.Id;
            update orders[0];
            Test.stopTest();
        }
    }
    
    @isTest
    static void getOrderProductTest() {
        User user = [
            SELECT Id, UserName 
            FROM User 
            WHERE UserName = 'testuserreplaneacion@test.com'
            LIMIT 1
        ];
        
        System.runAs(user) {
            Test.startTest();
            Order__c order = [
                SELECT Id, UMU__c, Tipo_de_Pedido__c, Total_de_Piezas__c
                FROM Order__c LIMIT 1
            ];
            
            List<Order_Line_Item__c> result = ReplaneacionController.getOrderProduct(order.Id);
            System.assertEquals(2, result.size(), 'Expected 1 Order_Line_Item__c records to be created.');
            Test.stopTest();
        }

    }
    
    @isTest
    static void getReplaneacionDataTest() {
        User user = [
            SELECT Id, UserName 
            FROM User 
            WHERE UserName = 'testuserreplaneacion@test.com'
            LIMIT 1
        ];
        
        System.runAs(user) {
            Test.startTest();
            String result = ReplaneacionController.getReplaneacionData(user.Id);
            System.assertNotEquals(null, result, 'The value returned is null');
            Test.stopTest();
        }
    }
    
    @isTest
    static void firmarOrdenTest() { 
        Order__c order = [
            SELECT Id, UMU__c, Tipo_de_Pedido__c, Total_de_Piezas__c
            FROM Order__c LIMIT 1
        ];
        
        Test.startTest();
        String result = ReplaneacionController.firmarOrden(order.Id);
        System.assertEquals('Firmada correctamente', result, 'The returned string is incorrect');
        Test.stopTest();
    }
    
    @isTest
    static void editarOrdenParaEnviarAFirmaTest() { 
        Order__c order = [
            SELECT Id, UMU__c, Tipo_de_Pedido__c, Total_de_Piezas__c
            FROM Order__c LIMIT 1
        ];
        
        DateTime currentDateTime = System.now();
        String currentTimeString = currentDateTime.format('HH:mm:ss');
        
        String json = '{"descripcion":"","rejectionImage":null,"orderItemsUpdates":'
            + '[{"id":"' + order.Id + '","cantidadDePiezasFaltantes":10}],'
            + '"desviacion":"","selectedDate":"' + String.valueOf(System.Today()) + '","selectedTime":"' + currentTimeString + '"}';
        
        String result = ReplaneacionController.editarOrdenParaEnviarAFirma(order.Id, json);
        System.assertNotEquals(null, result, 'The value returned is null');  
    }
    
    @isTest
    static void getFilesTest() { 
        Order__c order = [
            SELECT Id, UMU__c, Tipo_de_Pedido__c, Total_de_Piezas__c
            FROM Order__c LIMIT 1
        ];
        
        Test.startTest();
        try {
            ContentDocumentLink result = ReplaneacionController.getFiles(order.Id);
            System.debug(result);
            System.assert(false, 'Se esperaba una excepción pero no se generó');
        } catch (AuraHandledException e) {
            System.assertEquals('Script-thrown exception', e.getMessage(), 'El mensaje de error no coincide');
        }
        Test.stopTest();
    }
}