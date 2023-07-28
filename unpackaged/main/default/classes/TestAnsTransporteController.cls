@isTest
private class TestAnsTransporteController {
    @testSetup static void setup(){
        Account acc = TestDataFactory.createSingleAccount('Test');
        
        Contact con = TestDataFactory.createSingleContactRelatedToAccount(
            acc.Id,
            'Test',
            'UserContactClassTest',
            'Medicina'
        );
        
        Product2 product =  TestDataFactory.createSingleProduct2('test');
        
        List<Product2> listproduct = TestDataFactory.createMultipleProduct2('test2',5);
        
        Order__c ord = TestDataFactory.createSingleOrder();
        
        DPN__c dpn = TestDataFactory.createSingleDPN(acc.Id);
        
        DPN_Line_Item__c dpnLineItem = TestDataFactory.createSingleDPNLineItem(dpn.Id, product.Id); 
        
        Entrega__c entrega = TestDataFactory.createSingleDelivery('No Asignado');
        
        List<Contactos_y_Programas__c> listcontactosProgramas = TestDataFactory.createMultipleContactsAndPrograms(3);
    }
    
    @isTest static void testMethod1() {
        Test.startTest();
        Account account = [SELECT Id FROM Account LIMIT 1];
        User testUser = [SELECT Id FROM User LIMIT 1];
        Order__c order = [SELECT Id,Estatus__c,Seguimiento__c FROM Order__c LIMIT 1];
        System.runAs(testUser) {
            List<AccountContactRelation> listAccountRelation = AnsTransporteController.getUmu(testUser.Id);
            List<Order__c> listOrders = AnsTransporteController.getUmuOrders('test', testUser.Id);
            List<Order_Line_Item__c> listOrderLineItems = AnsTransporteController.getOrderItems();
            List<Order__c> listOrderAns = AnsTransporteController.getOrdersAns(testUser.Id);
            List<Order_Line_Item__c> listProducts = AnsTransporteController.getProductsOrder(testUser.Id);
            List<DPN_Line_Item__c> listorderItem = VerDpnPedidoController.getDpn(account.Id);
            List<Contactos_y_Programas__c> listcontactosProgramas = TestDataFactory.createMultipleContactsAndPrograms(3);
            insert listcontactosProgramas;
            
            insert listOrders;
            insert listOrderLineItems;
        }
        Test.stopTest();
    }
   @isTest static void testMethod2() {
        Test.startTest();
       
        
        User testUser = [SELECT Id, Username FROM User LIMIT 1];
       	Entrega__c entrega = [SELECT Id, Name, Estado__c FROM Entrega__c LIMIT 1];
       
        System.runAs(testUser) {
            List<Object> listEntregas = AsignadoTransporteController.getEntregas(entrega.Name);
            AsignadoTransporteController.updateEntregaAsignar(entrega.Name, testUser.Id);
            AsignadoTransporteController.desasignarEntrega(entrega.Id);
            AsignadoTransporteController.finalizarEntrega(entrega.Id);
            List<Object> listaentrega = EntreAsignadaController.getEntregasAsignadas(testUser.Id);
        }
        Test.stopTest();
    }
    
    @isTest static void testMethod3() {
        Test.startTest();
        User testUser = [SELECT Id, Username FROM User LIMIT 1];
        UserRole portalRole = [Select Id From UserRole Where PortalType = 'CustomerPortal' Limit 1];
        User usr = [Select Id,UserRoleId, Username from User where UserRoleId=:portalRole.Id LIMIT 1];
        Order__c order = [SELECT Id,Estatus__c,Seguimiento__c FROM Order__c LIMIT 1];
        System.RunAs(usr) {
            CustomForgotFormController.forgotPassowrd(usr.Username);
            LightningLoginFormController.getForgotPasswordUrl();
            LightningLoginFormController.setExperienceId('test');
            LightningLoginFormController.getIsSelfRegistrationEnabled();
            LightningLoginFormController.getSelfRegistrationUrl();
            LightningLoginFormController.getIsUsernamePasswordEnabled();
            LightningLoginFormController.login('username','password','test');
            LightningForgotPasswordController.setExperienceId('test');
            LightningForgotPasswordController.forgotPassword('test','test');
        }
        Test.stopTest();
    }
    
   @isTest static void testMethod4() {
        Test.startTest();
        User testUser = [SELECT Id, Username FROM User LIMIT 1];
       	Product2 productSingle = [SELECT Id, productCode FROM Product2 LIMIT 1];
        System.RunAs(testUser) {
            List<Product2> listaproductos = SuppliesController.getSupplies();
            //Product2 product = SuppliesController.getSuppliesByCode(productSingle.productCode);
            Programas__c program = [SELECT Id FROM Programas__c LIMIT 1];
            List<Product2> listaproductosbysearch = SuppliesController.getSuppliesBySearch('test', program.Id);
            List<Product2> listaproductosbyprogram = SuppliesController.getSuppliesByProgram(program.Id);
            String testtext =  SuppliesController.getSuppliesBySearch2('test', program.Id, 5, 5);
        }
        Test.stopTest();
    }
    @isTest static void testMethod5() {
        Test.startTest();
        User testUser = [SELECT Id, Username FROM User LIMIT 1];
       	Order__c order = [SELECT Id,Tipo_de_Pedido__c FROM Order__c LIMIT 1];
        Account account = [SELECT Id FROM Account LIMIT 1];
        System.RunAs(testUser) {
            List<Order_Line_Item__c> listOrderItems = ReplaneacionController.getOrderProduct(order.Id);
            String replaData = ReplaneacionController.getReplaneacionData(testUser.Id);
            String firma = ReplaneacionController.firmarOrden(order.Id);
			List<ContentVersion> listaContent  = new List<ContentVersion>();        
            ContentVersion contentVersion = new ContentVersion(
                Title = 'Penguins',
                PathOnClient = 'Penguins.jpg',
                VersionData = Blob.valueOf('Test Content'),
                IsMajorVersion = true
            );
             
            listaContent.add(contentVersion);
            insert contentVersion; 
            List<ContentDocument> documents = [
                SELECT Id, Title, LatestPublishedVersionId 
                FROM ContentDocument
            ];
            
            List<ContentDocumentLink> contentDoclist = new List<ContentDocumentLink>();
            
            //create ContentDocumentLink  record 
            ContentDocumentLink cdl = New ContentDocumentLink();
            cdl.LinkedEntityId = order.id;
            cdl.ContentDocumentId = documents[0].Id;
            cdl.shareType = 'V';
            
            contentDoclist.add(cdl);
            
            insert cdl;
            
            ContentDocumentLink contentl = ReplaneacionController.getFiles(order.Id);
            
            String test = ImageUploadController.saveImage('Test', 'test', order.Id, false);
            List<DocumentWrapper> listDocuments = RelatedRecordAttachmentsController.getAllDocumentsAndRelatedFiles();
            ContentDistribution contentDist = RelatedRecordAttachmentsController.getContentDistributionForFile(cdl.ContentDocumentId);
        }
        Test.stopTest();
    }
}