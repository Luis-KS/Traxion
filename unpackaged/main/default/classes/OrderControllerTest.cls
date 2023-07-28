@isTest
public class OrderControllerTest {

    @TestSetup
    static void setup() {
        // TODO: Create any required records and insert them
        // This could include Products, if required
    }
    
    @isTest
    static void testCreateOrder() {
        Account umuTest = TestDataFactory.createSingleAccount('Hospital UMU');
        Contact contactTest = TestDataFactory.createSingleContactRelatedToAccount(umuTest.Id,'contact Test FirstName', 'contact Test LastName', 'Todas');
        Product2 claveTest = TestDataFactory.createSingleProduct('Aspirina', 'MEDICINE');
        
        OrderController.OrderWrapper testOrderWrapper = new OrderController.OrderWrapper();
        testOrderWrapper.umu = umuTest.Id;
        testOrderWrapper.tipoDePedido = 'Ordinario';
        testOrderWrapper.totalDePiezas = 5;
        testOrderWrapper.status = 'Procesando';
        testOrderWrapper.contactId = contactTest.Id;
        testOrderWrapper.orderItems = new List<OrderController.OrderItemWrapper>();
        
        OrderController.OrderItemWrapper testOrderItem = new OrderController.OrderItemWrapper();
        testOrderItem.productId = claveTest.Id; // TODO: replace with a real product Id
        testOrderItem.cantidadSolicitada = 5;
        testOrderItem.umu = umuTest.Id;
        
        testOrderWrapper.orderItems.add(testOrderItem);

        String jsonData = JSON.serialize(testOrderWrapper);
        
        Test.startTest();
        String result = OrderController.createOrder(jsonData);
        Test.stopTest();
        
        // Assertions to check the result and also to check if an Order__c record got created
        System.assertEquals('Order created successfully!', result);
    }

    @isTest
    static void testRegistrarOrden() {
        Entrega__c delivery = TestDataFactory.createSingleDelivery('Asignado');
        Account acc = TestDataFactory.createSingleAccount('AGUASCALIENTES');
        Contact contact = TestDataFactory.createSingleContactRelatedToAccount(acc.Id, 'Louise', 'Santana', 'Todas');
        Datetime limitDate = Datetime.newInstanceGMT(2023, 6, 30, 0, 0, 0);
        
        Order__c newOrder = new Order__c(
            Fecha_Limite_de_Entrega__c = limitDate,
            Tipo_de_Pedido__c = 'Ordinario',
            Total_de_Piezas__c = 0,
            Estatus__c = 'Procesando',
            Contacto__c = contact.Id,
            UMU__c = acc.Id,
            Entrega__c = delivery.Id
        );

        insert newOrder;

        Test.startTest();
        String result = OrderController.registrarOrden(newOrder.Id, 'En Firma');
        Test.stopTest();
        
        // Assertions to check the result and also to check if the Order__c record got updated
        System.assertEquals('Enviado correctamente.', result);
    }



    @isTest
    static void testRegistrarOrdenParcial() {
        Entrega__c delivery = TestDataFactory.createSingleDelivery('Asignado');
        Account acc = TestDataFactory.createSingleAccount('AGUASCALIENTES');
        Contact contact = TestDataFactory.createSingleContactRelatedToAccount(acc.Id, 'Louise', 'Santana', 'Todas');
        Datetime limitDate = Datetime.newInstanceGMT(2023, 6, 30, 0, 0, 0);
        
        Order__c newOrder = new Order__c(
            Fecha_Limite_de_Entrega__c = limitDate,
            Tipo_de_Pedido__c = 'Ordinario',
            Total_de_Piezas__c = 0,
            Estatus__c = 'Procesando',
            Contacto__c = contact.Id,
            UMU__c = acc.Id,
            Entrega__c = delivery.Id
        );

        insert newOrder;
        
        // create order line item
        
        Order_Line_Item__c orderLineItem = new Order_Line_Item__c(
        	Order__c = newOrder.Id
        );
        
        insert orderLineItem;
        
        // crear lote
        Informacion_De_Lote__c loteTest = new Informacion_De_Lote__c(
            Name = 'LOTE-001',
            Order_Line_Item__c = orderLineItem.Id
        );
        
        insert loteTest;
        

        // Create OrderUpdates test data
        OrderController.OrderUpdates testUpdates = new OrderController.OrderUpdates();
        testUpdates.desviacion = '';
        testUpdates.descripcion = '';
        testUpdates.rejectionImage = '';
        testUpdates.orderItemsUpdates = new List<OrderController.OrderItemUpdate>();
        
        OrderController.OrderItemUpdate testOrderItemUpdate = new OrderController.OrderItemUpdate();
        testOrderItemUpdate.name = '';
        testOrderItemUpdate.id = orderLineItem.Id; // TODO: replace with a real id
        testOrderItemUpdate.lotes = new List<OrderController.Lote>();
        
        OrderController.Lote lote = new OrderController.Lote();
        lote.id = loteTest.Id;
        lote.cantidadDePiezasFaltantes = 2;
        testOrderItemUpdate.lotes.add(lote);
        
        testUpdates.orderItemsUpdates.add(testOrderItemUpdate);

        String ordenParcialJson = JSON.serialize(testUpdates);

        Test.startTest();
        	String result = OrderController.registrarOrdenParcial(newOrder.Id, 'Recibido Parcial', ordenParcialJson);
        Test.stopTest();

        // Assertions to check the result and also to check if the Order__c record got updated
        System.assertEquals('Enviado correctamente.', result);
    }
    
    
    
}