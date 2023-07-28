@isTest
public with sharing class ControladorGeneracionPedidosTest {
    
    @TestSetup
    static void setup() {
        Account acc = TestDataFactory.createSingleAccount('Test Account');
        Account acc2 = TestDataFactory.createSingleAccount('Test Account 2');
        Contact con = TestDataFactory.createSingleContactRelatedToAccount(acc.Id, 'Louise', 'Santana', 'Todas');

        Product2 p1 = TestDataFactory.createSingleProduct2('LINAGLIPTINA');
        Product2 p2 = TestDataFactory.createSingleProduct2('JARABE PARA GRIPA');
        
        String jsonToSend = '[{"Idcontacto":"' + con.Id + '" , "esPrograma": false, "IdUmu": "' +
            acc.Id + '","TipoDePedido": "Ordinario","ordenesDetails": [{"insumoId": "' +
            p1.Id + '","CantidadSolicitada": 5},{"insumoId": "' + p2.Id + '","CantidadSolicitada": 5}]}]'; 
        String jsonToSend2 = '[{"Idcontacto":"' + con.Id + '" , "esPrograma": true, "IdUmu": "' +
            acc2.Id + '","TipoDePedido": "Programa","ordenesDetails": [{"insumoId": "' +
            p1.Id + '","CantidadSolicitada": 5},{"insumoId": "' + p2.Id + '","CantidadSolicitada": 5}]}]';
        String jsonToSend3 = '[{"Idcontacto":"' + con.Id + '" , "esPrograma": true, "IdUmu": "' +
            acc2.Id + '","TipoDePedido": "Emergencia Sanitaria","ordenesDetails": [{"insumoId": "' +
            p1.Id + '","CantidadSolicitada": 5},{"insumoId": "' + p2.Id + '","CantidadSolicitada": 5}]}]';
        String jsonToSend4 = '[{"Idcontacto":"' + con.Id + '" , "esPrograma": false, "IdUmu": "' +
            acc2.Id + '","TipoDePedido": "Urgencia Médica","ordenesDetails": [{"insumoId": "' +
            p1.Id + '","CantidadSolicitada": 5},{"insumoId": "' + p2.Id + '","CantidadSolicitada": 5}]}]';
        String jsonToSend5 = '[{"Idcontacto":"' + con.Id + '" , "esPrograma": false, "IdUmu": "' +
            acc.Id + '","TipoDePedido": "Extraordinario","ordenesDetails": [{"insumoId": "' +
            p1.Id + '","CantidadSolicitada": 5},{"insumoId": "' +
            p2.Id + '","CantidadSolicitada": 5}]}]';
        String jsonToSend6 = '[{"Idcontacto":"' + con.Id + '" , "esPrograma": false, "IdUmu": "' +
            acc.Id + '","TipoDePedido": "Soporte de Vida","ordenesDetails": [{"insumoId": "' +
            p1.Id + '","CantidadSolicitada": 5},{"insumoId": "' +
            p2.Id + '","CantidadSolicitada": 5}]}]';
        
        Test.startTest();
        controladorGeneracionPedidos.deserializeOrders(jsonToSend);
        controladorGeneracionPedidos.deserializeOrders(jsonToSend2);
        controladorGeneracionPedidos.deserializeOrders(jsonToSend3);
        controladorGeneracionPedidos.deserializeOrders(jsonToSend4);
        controladorGeneracionPedidos.deserializeOrders(jsonToSend5);
        controladorGeneracionPedidos.deserializeOrders(jsonToSend6);
        Test.stopTest();
    }
    
    @isTest
    public static void orderTest() { 
        Test.startTest();
        List<Order__c> orders = [
            SELECT Id, UMU__c, Tipo_de_Pedido__c, Total_de_Piezas__c
            FROM Order__c];
        System.assertEquals(6, orders.size(), 'Expected 6 Order__c record to be created.');
        
        List<Order_Line_Item__c> orderItems = [
            SELECT Id, Product__c, Cantidad_Solicitada__c, Order__c
            FROM Order_Line_Item__c
        ];
        System.assertEquals(12, orderItems.size(),'Expected 12 order_Line_Item__c record to be created.');
        
        System.assertEquals(orders[0].Id, orderItems[0].Order__c, 
                            'Order_Line_Item__c record does not reference the correct Order__c record.');
        System.assertEquals(5, orderItems[0].Cantidad_Solicitada__c,
                            'Order_Line_Item__c record does not have the expected Cantidad_Solicitada__c value.');
        Test.stopTest();
    }
    
    @isTest
    public static void createCSVTest() {
        String title, versionData, pathOnClient, programName, summary;
        title = 'Documento General.csv';
        pathOnClient = 'DocumentoGeneral.csv';
        programName = 'Claves DPN';
        summary = '{"numItems":2,"numCantidadUmus":2,"sumCantidadAutorizada":40}';
        versionData = 'REVMRUdBQ0lPTixVTVUsQ0xBVkUgUFJFU1VQVUVTVEFMLE5PTUJSRSBVTVUsVElQTyBERSBQRURJR'
            + 'E8sRkVDSEEgREUgU09MSUNJVFVELEZPTElPIERFTCBQRURJRE8sQ0xBVkUsREVTQ1JJUENJT04gQ0xBVkUsQ0F'
            + 'OVElEQUQgQVVUT1JJWkFEQSxDQU5USURBRCBDT0xPQ0FEQSBFTiBTQVAsRVNUQVRVUyxGRUNIQSBMSU1JVEUgR'
            + 'EUgRU5UUkVHQSxJRCBERSBQUk9HUkFNQSxQUk9HUkFNQQowMDEtQUdVQVNDQUxJRU5URVMsMDAxLCcwMDEyMDQw'
            + 'MCxIRyBBR1VBU0NBTElFTlRFUyxQcm9ncmFtYSwyMDIzLTA2LTMwLCcwMDA3NzksJzAxMDAwMDU3NDMwMCxMSV'
            + 'JBR0xVVElERS4gU09MVUNJw5NOIElOWUVDVEFCTEUgQ0FEQSBNSUxJTElUUk8gQ09OVElFTkU6IExJUkFHTFVUS'
            + 'URFIChBRE4gUkVDT01CSU5BTlRFKSA2IE1HIEVOVkFTRSBDT04gMiBQTFVNQVMgQ09OIENBUlRVQ0hPIERFIDMg'
            + 'TUwsMTAsMTAsQVVUT1JJWkFETywyMDIzLTA3LTAzLFMyNyxDbGF2ZXMgRFBOCjAwMS1BR1VBU0NBTElFTlRFUyw'
            + 'wMDEsJzAwMTIwNDAwLEhHIEFHVUFTQ0FMSUVOVEVTLFByb2dyYW1hLDIwMjMtMDYtMzAsJzAwMDc3OSwnMDEwMD'
            + 'AwNTg0NTAwLFNJTERFTkFGSUwuIFRBQkxFVEEgQ0FEQSBUQUJMRVRBIENPTlRJRU5FOiBDSVRSQVRPIERFIFNJT'
            + 'ERFTkFGSUwgRVFVSVZBTEVOVEUgQSAyMCBNRyBERSBTSUxERU5BRklMIEVOVkFTRSBDT04gOTAgVEFCTEVUQVMs'
            + 'MTAsMTAsQVVUT1JJWkFETywyMDIzLTA3LTAzLFMyNyxDbGF2ZXMgRFBOCjAwMS1BR1VBU0NBTElFTlRFUywwMDI'
            + 'sJzAwMTIwNTAxLFVNRiBDQUxWSUxMTyxQcm9ncmFtYSwyMDIzLTA2LTMwLCcwMDA3ODAsJzAxMDAwMDU3NDMwMC'
            + 'xMSVJBR0xVVElERS4gU09MVUNJw5NOIElOWUVDVEFCTEUgQ0FEQSBNSUxJTElUUk8gQ09OVElFTkU6IExJUkFHT'
            + 'FVUSURFIChBRE4gUkVDT01CSU5BTlRFKSA2IE1HIEVOVkFTRSBDT04gMiBQTFVNQVMgQ09OIENBUlRVQ0hPIERF'
            + 'IDMgTUwsMTAsMTAsQVVUT1JJWkFETywyMDIzLTA3LTAzLFMyNyxDbGF2ZXMgRFBOCjAwMS1BR1VBU0NBTElFTlR'
            + 'FUywwMDIsJzAwMTIwNTAxLFVNRiBDQUxWSUxMTyxQcm9ncmFtYSwyMDIzLTA2LTMwLCcwMDA3ODAsJzAxMDAwMD'
            + 'U4NDUwMCxTSUxERU5BRklMLiBUQUJMRVRBIENBREEgVEFCTEVUQSBDT05USUVORTogQ0lUUkFUTyBERSBTSUxERU'
            + '5BRklMIEVRVUlWQUxFTlRFIEEgMjAgTUcgREUgU0lMREVOQUZJTCBFTlZBU0UgQ09OIDkwIFRBQkxFVEFTLDEwLD'
            + 'EwLEFVVE9SSVpBRE8sMjAyMy0wNy0wMyxTMjcsQ2xhdmVzIERQTgo=';
        
        Test.startTest();
        Order__c order = [
            SELECT Id, UMU__c, Tipo_de_Pedido__c, Total_de_Piezas__c, Pedido__r.ID_de_Pedido__c
            FROM Order__c 
            WHERE Tipo_de_Pedido__c = 'Extraordinario' LIMIT 1
        ];
        
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        
        ContentVersion result = controladorGeneracionPedidos.createContentVersion(
            title, versionData, pathOnClient, con.Id, order.Id, programName, summary);
        System.debug('result---> ' + result);
        System.assertEquals('Documento General.csv', result.Title, 'The title not match');
        Test.stopTest();
    }
    
    @isTest
    public static void createCSVFilesTest() {
        Test.startTest();
        Order__c order = [
            SELECT Id, UMU__c, Tipo_de_Pedido__c, Total_de_Piezas__c, Pedido__r.ID_de_Pedido__c
            FROM Order__c 
            WHERE Tipo_de_Pedido__c = 'Soporte de Vida' LIMIT 1
        ];
        
        List<Order_Line_Item__c> oliList = [
            SELECT Id, Product__r.Name
            FROM Order_Line_Item__c WHERE Order__c = :order.Id
        ];
        
        List<String> productList = new List<String>();
        for(Order_Line_Item__c oli : oliList) {
            if(!productList.contains(oli.Id)) {
                 productList.add(oli.Id);
            }
        }
        
        ContentVersion result = controladorGeneracionPedidos.createCSVFiles(productList, true);
        String contentDocumentTitle = order.Pedido__r.ID_de_Pedido__c + '.csv';
        System.assertEquals(contentDocumentTitle, result.Title, 'The title not match');
        Test.stopTest();
    }
    
    @isTest
    public static void getInfoClavesDPNActivaTest() {
        Account acc = TestDataFactory.createSingleAccount('Test Account');
        Product2 p = TestDataFactory.createSingleProduct2('LINAGLIPTINA');
        DPN__c dpn = TestDataFactory.createSingleDPN(acc.Id);
        DPN_Line_Item__c lineItem = TestDataFactory.createSingleDPNLineItem(dpn.Id, p.Id);
        
        test.startTest();
        Integer result = controladorGeneracionPedidos.getInfoClavesDPNActiva(acc.Id, p.Id, true);
        System.assertEquals(50, result, 'The quantity returned is incorrect');
        test.stopTest();
    }
    
    @isTest
    public static void getUltimaFechaActivaDPNTest() {
        Account acc = TestDataFactory.createSingleAccount('Test Account');
        Product2 p = TestDataFactory.createSingleProduct2('LINAGLIPTINA');
        DPN__c dpn = TestDataFactory.createSingleDPN(acc.Id);
        D_a_de_Pedido__c orderDate = TestDataFactory.createSingleOrderDate(dpn.Id);
        DPN_Line_Item__c lineItem = TestDataFactory.createSingleDPNLineItem(dpn.Id, p.Id);
        
        test.startTest();
        Date result = controladorGeneracionPedidos.getUltimaFechaActivaDPN(acc.Id, true);
        System.assertEquals(orderDate.Fecha__c, result, 'The date returned is incorrect');
        test.stopTest();
    }
    
    @isTest
    public static void getOrderIdTest() {
        Test.startTest();
        List<Order__c> orders = [
            SELECT Id, UMU__c, Tipo_de_Pedido__c, Total_de_Piezas__c, Pedido__r.ID_de_Pedido__c
            FROM Order__c 
        ];
        
        Set<Id> result = controladorGeneracionPedidos.getOrderId(orders);
        List<Id> idList = new List<Id>(result);
        System.assertEquals(orders.size(), idList.size(), 'The order list size musb be 6');
        Test.stopTest();
    }
    
    @isTest
    public static void getSubalmacenFilterTest() {
        Test.startTest();
        Order__c order = [
            SELECT Id, UMU__c, Tipo_de_Pedido__c, Total_de_Piezas__c, Pedido__r.ID_de_Pedido__c
            FROM Order__c 
            WHERE Tipo_de_Pedido__c = 'Soporte de Vida' LIMIT 1
        ];
        
        List<Order_Line_Item__c> oliList = [
            SELECT Id, Name, Order__c, UMU__c, Pedido__c, Numero_de_Subalmacen__c, Order_Line_Item_Classification__c, Product__c 
            FROM Order_Line_Item__c 
            WHERE Order__c = :order.Id
        ];
        
        Map<Id, List<Order_Line_Item__c>> oliMap = new Map<Id, List<Order_Line_Item__c>>();
        for(Order_Line_Item__c oli : oliList) {
            if(!oliMap.containsKey(oli.Order__c)){
                oliMap.put(oli.Order__c, new List<Order_Line_Item__c>());
            }
            oliMap.get(oli.Order__c).add(oli);
               
        }
        
        Map<Decimal, List<Id>> result = controladorGeneracionPedidos.GetSubalmacenFilter(String.valueOf(order.Id), oliMap);
        System.assertEquals(1, result.size(), 'The map size must be 1'); 
    }
    
    /*@isTest
    public static void sendEmailSolicitudNoOrdTest() {
        Account acc = TestDataFactory.createSingleAccount('Test Account');
        Contact con = TestDataFactory.createSingleContactRelatedToAccount(acc.Id, 'Louise', 'Santana', 'Todas');
        
        Product2 p1 = TestDataFactory.createSingleProduct2('LINAGLIPTINA');
        Product2 p2 = TestDataFactory.createSingleProduct2('JARABE PARA GRIPA');
        
        String jsonToSend = '[{"Idcontacto":"' + con.Id + '" , "esPrograma": false, "IdUmu": "' +
            acc.Id + '","TipoDePedido": "Extraordinario","ordenesDetails": [{"insumoId": "' +
            p1.Id + '","CantidadSolicitada": 5},{"insumoId": "' +
            p2.Id + '","CantidadSolicitada": 5}]}]';
        
        User user = TestDataFactory.initCommunityLoginUser('testuser');
        
        System.runAs(user) {
            test.startTest();
            List<Order__c> orders = controladorGeneracionPedidos.deserializeOrders(jsonToSend);
            
            Order__c order = [
                SELECT Id, UMU__c, Tipo_de_Pedido__c, Total_de_Piezas__c, Pedido__r.ID_de_Pedido__c
                FROM Order__c 
                WHERE Id = :orders.get(0).Id LIMIT 1
            ];
            
            List<String> orderIds = new List<String>();
            orderIds.add(order.Id);
            
            controladorGeneracionPedidos.sendEmailSolicitudNoOrd(orderIds);
            
            //System.assertEquals(true, result, 'The result was false');
            test.stopTest();   
        }
    }*/
}