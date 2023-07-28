@isTest
public class ClassToDeleteTest {
    @isTest
    public static void getFilteredOrdersTest() {
        User user = TestDataFactory.initCommunityLoginUser('testuser');

        Contact con = [
            SELECT Id, AccountId FROM Contact
            WHERE Id = :user.ContactId
        ];
        
        Entrega__c e = TestDataFactory.createSingleDelivery('Asignado');
        
        Product2 p1 = TestDataFactory.createSingleProduct2('LINAGLIPTINA');
        Product2 p2 = TestDataFactory.createSingleProduct2('JARABE PARA GRIPA');
        
        String jsonToSend = '[{"Idcontacto":"' + con.Id + '" , "esPrograma": false, "IdUmu": "' +
            con.AccountId + '","TipoDePedido": "Soporte de Vida","ordenesDetails": [{"insumoId": "' +
            p1.Id + '","CantidadSolicitada": 5},{"insumoId": "' +
            p2.Id + '","CantidadSolicitada": 5}]}]';
        
        System.runAs(user) {
            Test.startTest();
            List<Order__c> orders = controladorGeneracionPedidos.deserializeOrders(jsonToSend);
            
            orders[0].Entrega__c = e.Id;
            update orders[0];
            
            List<Order__c> orderList = [
                SELECT Id, UMU__c, Tipo_de_Pedido__c, UMU__r.Clave_Presupuestal__c, UMU__r.Estado__c, Entrega__c
                FROM Order__c 
                WHERE Id = :orders[0].Id
            ];
            
            List<String> codes = new List<String>{p1.Product_Code_ID__c, p2.Product_Code_ID__c};
                List<String> umus = new List<String>();
            List<String> states = new List<String>();
            List<String> orderTypes = new List<String>();
            List<String> deliveries = new List<String>();
            
            for(Order__c order : orderList) {
                umus.add(order.UMU__r.Clave_Presupuestal__c);
                states.add(order.UMU__r.Estado__c);
                orderTypes.add(order.Tipo_de_Pedido__c);
                deliveries.add(order.Entrega__c);
            }
            
            Date startDate = Date.today();
            Date endDate =  startDate.addDays(3);
            
            
            List<Order__c> result = ClassToDelete_RetrieveAccounts.getFilteredOrders(codes, umus, states, orderTypes, deliveries, startDate, endDate);
            System.assertEquals(1, result.size(), 'The order list size must be 1');
            Test.stopTest(); 
        }
    }
    
    @isTest
    public static void getOrderLineItemsTest() {
        User user = TestDataFactory.initCommunityLoginUser('testuser');

        Contact con = [
            SELECT Id, AccountId FROM Contact
            WHERE Id = :user.ContactId
        ];
        
        Entrega__c e = TestDataFactory.createSingleDelivery('Asignado');
        
        Product2 p1 = TestDataFactory.createSingleProduct2('LINAGLIPTINA');
        Product2 p2 = TestDataFactory.createSingleProduct2('JARABE PARA GRIPA');
        
        String jsonToSend = '[{"Idcontacto":"' + con.Id + '" , "esPrograma": false, "IdUmu": "' +
            con.AccountId + '","TipoDePedido": "Soporte de Vida","ordenesDetails": [{"insumoId": "' +
            p1.Id + '","CantidadSolicitada": 5},{"insumoId": "' +
            p2.Id + '","CantidadSolicitada": 5}]}]';
        
        System.runAs(user) {
            Test.startTest();
            List<Order__c> orders = controladorGeneracionPedidos.deserializeOrders(jsonToSend);
            List<Id> orderIds = new List<Id>{orders[0].Id};
            List<Order_Line_Item__c> result = ClassToDelete_RetrieveAccounts.getOrderLineItems(orderIds);
            System.assertEquals(2, result.size(), 'The oli list size must be 2');
            Test.stopTest();
        }
    }
}