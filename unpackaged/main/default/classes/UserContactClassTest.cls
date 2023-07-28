@isTest
public class UserContactClassTest {
    @TestSetup
    static void createTestData() {
        Account acc = TestDataFactory.createSingleAccount(
            'Test UMU - UserContactClassTest'
        );
        
        Contact con = TestDataFactory.createSingleContactRelatedToAccount(
            acc.Id,
            'Test',
            'UserContactClassTest',
            'Medicina'
        );
        
        String uniqueUserName = String.ValueOf(System.Now())
            .replaceAll('[^a-zA-Z0-9]', '');
        User user = TestDataFactory.initCommunityLoginUser('usertestcontactclass');
        System.debug(user);
        
        Product2 clave = TestDataFactory.createSingleProduct2('Product');
        List<Product2> listproduct = TestDataFactory.createMultipleProduct2('Product2',5);
        Order__c ord = TestDataFactory.createSingleOrder();
        
        DPN__c dpn = TestDataFactory.createSingleDPN(acc.Id);
        DPN__c dpn2 = TestDataFactory.createSingleDPN2(acc.Id);
        
        DPN_Line_Item__c dpnLineItem = TestDataFactory.createSingleDPNLineItem(dpn.Id, clave.Id);  
        DPN_Line_Item__c dpnLineItem2 = TestDataFactory.createSingleDPNLineItem2(dpn2.Id, clave.Id);  
        
        Entrega__c entrega = TestDataFactory.createSingleDelivery('No Asignado');
        
        List<Contactos_y_Programas__c> listcontactosProgramas = TestDataFactory.createMultipleContactsAndPrograms(3);
    }
    
    @isTest
    static void testGetUserId_Positive() {
        Test.startTest();
        User testUser = [SELECT Id FROM User LIMIT 1];
        System.runAs(testUser) {
            Id currentUserId = UserContactClass.getUserId();
            System.assertEquals(testUser.Id, currentUserId, 'User Ids do not match');
        }
        Test.stopTest();
    }
    
    @isTest
    static void getContactIdFromUser_Positive() {
        Test.startTest();
        User testUser = [SELECT Id, ContactId FROM User LIMIT 1];
        System.runAs(testUser) {
            Id currentUserContactId = UserContactClass.getContactIdFromUser();
            System.assertEquals(
                testUser.ContactId,
                currentUserContactId,
                'User Contact Ids do not match'
            );
        }
        Test.stopTest();
    }
    
    @isTest
    static void checkIfUserIsResponsableDeFarmaciaAlmacen_Positive() {
        Test.startTest();
        User testUser = [SELECT Id, ContactId FROM User LIMIT 1];
        
        PermissionSet ps = new PermissionSet();
        List<PermissionSet> psList = [
            SELECT Id
            FROM PermissionSet
            WHERE Name = 'Responsable_de_Farmacia_y_o_Almac_n'
            LIMIT 1
        ];
        if (psList.size() == 1) {
            ps = psList[0];
        } else {
            ps.Label = 'Responsable de Farmacia y o Almacen';
            ps.Name = 'Responsable_de_Farmacia_y_o_Almac_n';
            insert ps;
        }
        
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = testUser.Id;
        psa.PermissionSetId = ps.Id;
        insert psa;
        
        System.runAs(testUser) {
            Boolean isResponsableDeFarmacia = UserContactClass.checkIfUserIsResponsableDeFarmaciaAlmacen();
            System.assertEquals(
                true,
                isResponsableDeFarmacia,
                'User is Responsable De Farmacia'
            );
        }
        Test.stopTest();
    }
    
    @isTest
    static void getAccountIdsFromUser_Positive() {
        Test.startTest();
        User testUser = [SELECT Id, ContactId FROM User LIMIT 1];
        List<Id> userAccountIds = new List<Id>();
        for (Contact con : [
            SELECT AccountId
            FROM Contact
            WHERE Id = :testUser.ContactId
        ]) {
            userAccountIds.add(con.AccountId);
        }
        System.runAs(testUser) {
            List<Id> accountIdsFromUser = UserContactClass.getAccountIdsFromUser();
            System.assertEquals(
                userAccountIds.size(),
                accountIdsFromUser.size(),
                'Account Ids should be equal to 1'
            );
        }
        Test.stopTest();
    }
    
    @isTest
    static void getAccountListFromUser_Positive() {
        Test.startTest();
        User testUser = [SELECT Id, ContactId FROM User LIMIT 1];
        List<Id> userAccountIds = new List<Id>();
        for (Contact con : [
            SELECT AccountId
            FROM Contact
            WHERE Id = :testUser.ContactId
        ]) {
            userAccountIds.add(con.AccountId);
        }
        List<Account> userAccountList = [
            SELECT Id
            FROM Account
            WHERE Id IN :userAccountIds
        ];
        System.runAs(testUser) {
            List<Account> accountListFromUser = UserContactClass.getAccountListFromUser();
            System.assertEquals(
                userAccountList.size(),
                accountListFromUser.size(),
                'Account List size should be equal to 1'
            );
        }
        Test.stopTest();
    }
    
    @isTest
    static void getActiveDPNListFromUser() {
        Test.startTest();
        User testUser = [SELECT Id, UserName, ContactId FROM User WHERE UserName = 'usertestcontactclass@test.com' LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PermissionSet ps = new PermissionSet();
        List<PermissionSet> psList = [
            SELECT Id
            FROM PermissionSet
            WHERE Name = 'Responsable_de_Farmacia_y_o_Almac_n'
            LIMIT 1
        ];
        
        if (psList.size() == 1) {
            ps = psList[0];
        } else {
            ps.Label = 'Responsable de Farmacia y o Almacen';
            ps.Name = 'Responsable_de_Farmacia_y_o_Almac_n';
            insert ps;
        }
        
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = testUser.Id;
        psa.PermissionSetId = ps.Id;
        insert psa; 
        System.runAs(testUser) {
            UserContactClass.getActiveDPNListFromUser(acc.Id);
            UserContactClass.getProgramIdsByContact();
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void getDpnNoOrdinary() {
        Test.startTest();
        Account acc = [SELECT Id FROM Account LIMIT 1];
        User testUser = [SELECT Id, UserName, ContactId FROM User WHERE UserName = 'usertestcontactclass@test.com' LIMIT 1];
        PermissionSet ps = new PermissionSet();
        List<PermissionSet> psList = [
            SELECT Id
            FROM PermissionSet
            WHERE Name = 'Responsable_de_Farmacia_y_o_Almac_n'
            LIMIT 1
        ];
        if (psList.size() == 1) {
            ps = psList[0];
        } else {
            ps.Label = 'Responsable de Farmacia y o Almacen';
            ps.Name = 'Responsable_de_Farmacia_y_o_Almac_n';
            insert ps;
        }
        
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = testUser.Id;
        psa.PermissionSetId = ps.Id;
        insert psa; 
        System.runAs(testUser) {
            UserContactClass.getDpnNoOrdinary();
            
        }
        
        Test.stopTest();
    }
    
    // @isTest
    // static void getActiveDPNListFromUser_Positive_Medicina(){
    //     Test.startTest();
    //     User testUser = [SELECT Id, ContactId FROM User LIMIT 1];
    //     Contact contact = [SELECT Id, AccountId, Acceso_a_claves_por_clasificaci_n__c FROM Contact WHERE Id =: testUser.ContactId LIMIT 1];
    
    //     PermissionSet ps = new PermissionSet();
    //     List<PermissionSet> psList = [SELECT Id FROM PermissionSet WHERE Name = 'Responsable_de_Farmacia_y_o_Almac_n' LIMIT 1];
    //     if (psList.size() == 1) {
    //         ps = psList[0];
    //     } else {
    //         ps.Label  = 'Responsable de Farmacia y o Almacen';
    //         ps.Name = 'Responsable_de_Farmacia_y_o_Almac_n';
    //         insert ps;
    //     }
    
    //     PermissionSetAssignment psa = new PermissionSetAssignment();
    //     psa.AssigneeId = testUser.Id;
    //     psa.PermissionSetId = ps.Id;
    //     insert psa;
    
    //     System.runAs(testUser) {
    //         List<DPN_Line_Item__c> dpnLineItemList = UserContactClass.getActiveDPNListFromUser(contact.AccountId);
    //         System.assertEquals(1, dpnLineItemList.size(), 'DPN Line Item size should be equals to 1');
    //     }
    //     Test.stopTest();
    // }
    
    @isTest
    static void getDisponibilidadTest() {
        // Arrange
        Test.setMock(HttpCalloutMock.class, new IntegrationHttpCalloutMock(false));
        String jsonData = '["sku1", "sku2"]';
        
        String jsonReceived =
            '[{"skus": [' +
            '{"sku": "sku1", "packages_details":[{"quantity_pieces_package":2,"availability":100}],"package_key":"true", "availability": 100},' +
            '{"sku": "sku2", "packages_details":[{"quantity_pieces_package":1,"availability":200}],"package_key":"false", "availability": 200}' +
            ']}]';
        
        List<ServicioPaqueteo.SkuDisponibilidad> expectedResponse = new List<ServicioPaqueteo.SkuDisponibilidad>();
        List<ServicioPaqueteo.SkuDisponibilidad> skus = new List<ServicioPaqueteo.SkuDisponibilidad>();
        
        ServicioPaqueteo.Packages_details pd = new ServicioPaqueteo.Packages_details();
        pd.quantity_pieces_package = 1;
        pd.availability = 2;
        
        List<ServicioPaqueteo.Packages_details> pdList = new List<ServicioPaqueteo.Packages_details>();
        pdList.add(pd);
        
        ServicioPaqueteo.SkuDisponibilidad sku1 = new ServicioPaqueteo.SkuDisponibilidad();
        sku1.sku = 'sku1';
        sku1.package_key = 'package1';
        sku1.availability = 10;
        sku1.packages_details = pdList;
        skus.add(sku1);
            
        expectedResponse = skus;
        
        Test.startTest();
        String actualResponse = UserContactClass.getDisponibilidadSkus(jsonData);
        Test.stopTest();
        
        System.debug('actualResponse --> ' + actualResponse);
        String output = actualResponse.substring(1, actualResponse.length() - 1);
        
        List<ServicioPaqueteo.SkuDisponibilidad> laPrueba = (List<ServicioPaqueteo.SkuDisponibilidad>) JSON.deserialize(
            actualResponse,
            List<ServicioPaqueteo.SkuDisponibilidad>.class
        );
        
        System.debug('laPrueba --> ' + laPrueba);
        
        List<ServicioPaqueteo.SkuDisponibilidad> expectedData = (List<ServicioPaqueteo.SkuDisponibilidad>) JSON.deserialize(
            jsonReceived,
            List<ServicioPaqueteo.SkuDisponibilidad>.class
        );
        
        System.debug('expectedData --> ' + expectedData);
        
        //Eliminar comentario para propositos de prueba
        // System.debug(expectedResponse);
        // System.debug(laPrueba);
        
        // String expected = 'DisponibilidadRespuesta:[skus=(SkuDisponibilidad:[availability=10, package_key=true, quantity_pieces_package=(1, 2), sku=sku1], SkuDisponibilidad:[availability=20, package_key=false, quantity_pieces_package=(1), sku=sku2])]';
        // String actual = 'DisponibilidadRespuesta:[skus=(SkuDisponibilidad:[availability=10, package_key=true, quantity_pieces_package=(1, 2), sku=sku1], SkuDisponibilidad:[availability=20, package_key=false, quantity_pieces_package=(1), sku=sku2])]';
        
        // // Remove all whitespace characters from both strings
        // expected = expected.replaceAll('\\s+', '');
        // actual = actual.replaceAll('\\s+', '');
        // System.assertEquals(expected, actual);
        
        System.assertEquals(
            JSON.serialize(expectedResponse),
            JSON.serialize(laPrueba)
        );
    }
    
    public class TestHttpCalloutMock implements HttpCalloutMock {
        public Boolean failResponse { get; set; }
        
        public TestHttpCalloutMock(Boolean failResponse) {
            this.failResponse = failResponse;
        }
        
        MuleSoft_Integration_Settings__mdt settings =  [SELECT Api_Base_Url__c, AccessToken_Url__c 
                                                            FROM  MuleSoft_Integration_Settings__mdt
                                                            WHERE DeveloperName = 'Traxion'];
        
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            if (
                req.getEndpoint()
                .contains(settings.Api_Base_Url__c)
            ) {
                if (failResponse) {
                    res.setStatusCode(400);
                    res.setStatus('Bad Request');
                    res.setBody('{"error": "Failed to get availability."}');
                } else {
                    res.setStatusCode(200);
                    res.setBody(
                        '{"skus": [{"sku": "sku1", "availability": 10, "package_key": true, "quantity_pieces_package": [1, 2]}, {"sku": "sku2", "availability": 20, "package_key": false, "quantity_pieces_package": [1]}]}'
                    );
                }
            } else if (
                req.getEndpoint()
                .contains(settings.AccessToken_Url__c)
            ) {
                res.setStatusCode(200);
                res.setBody(
                    '{"access_token": "YOUR_ACCESS_TOKEN", "token_type": "Bearer", "expires_in": 3600}'
                );
            } else {
                res.setStatusCode(404);
            }
            return res;
        }
    }
}