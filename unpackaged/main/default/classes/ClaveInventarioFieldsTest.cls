@isTest
public with sharing class ClaveInventarioFieldsTest {
    
    @TestSetup
    static void createTestData() {
        String uniqueUserName = String.ValueOf(System.Now()).replaceAll('[^a-zA-Z0-9]', '');
        User user = TestDataFactory.initCommunityLoginUser(uniqueUserName);

        List<Id> accountIdList = new List<Id>(); 

        for(AccountContactRelation accConRel : [ SELECT AccountId, Account.Name FROM AccountContactRelation WHERE ContactId =: user.ContactId LIMIT 1]){
            accountIdList.add(accConRel.AccountId);
        }

        List<Product2> listproduct = TestDataFactory.createMultipleProduct2('Producto', 2);

        Inventario__c inventario = new Inventario__c(); 
        inventario.Clasificacion__c = 'Material de Curación';
        inventario.Tipo_de_Insumo__c = 'Ordinario';
        inventario.UMU__c = accountIdList[0]; 
        insert inventario;

        Clave_de_Inventario__c cveInventario = new Clave_de_Inventario__c(); 
        cveInventario.Producto__c = listproduct[0].Id;
        cveInventario.Inventario__c = inventario.Id;
        cveInventario.Fecha_Inicio_Conteo__c = System.Today();
        cveInventario.Estatus_de_Conteo__c = 'Iniciado';
        insert cveInventario;

        Lote_de_Inventario__c loteInventario = new Lote_de_Inventario__c(); 
        loteInventario.Conteo_Actual__c = 0;
        loteInventario.Conteo_Anterior__c = 0;
        loteInventario.Fecha_de_Caducidad__c = System.Today() + 5;
        loteInventario.Lote__c = 'LOTE01';
        loteInventario.Clave_de_Inventario__c = cveInventario.Id; 
        loteInventario.Estatus_Conteo_Lote__c = 'Contado';
        loteInventario.Fecha_de_Modificaci_n__c = System.Today();
        insert loteInventario;

        Lote_de_Inventario__c loteInventario2 = new Lote_de_Inventario__c(); 
        loteInventario2.Conteo_Actual__c = 0;
        loteInventario2.Conteo_Anterior__c = 0;
        loteInventario2.Fecha_de_Caducidad__c = System.Today() + 5;
        loteInventario2.Lote__c = 'LOTE02';
        loteInventario2.Clave_de_Inventario__c = cveInventario.Id;
        loteInventario2.Estatus_Conteo_Lote__c = 'Contado';
        loteInventario2.Fecha_de_Modificaci_n__c = System.Today();
        insert loteInventario2;

    }

    @IsTest
    static void testConteoClave() {

        Clave_de_Inventario__c cveInv = [SELECT Id, Estatus_de_Conteo__c, Inventario__c FROM Clave_de_Inventario__c LIMIT 1];
                    
        Test.startTest();
            cveInv.Estatus_de_Conteo__c = 'Contado';
            update cveInv;
        Test.stopTest();

        System.assertEquals('Registrado', [SELECT Estatus__c FROM Inventario__c WHERE Id = : cveInv.Inventario__c].Estatus__c, 'Estatus de Inventario diferente a Registrado');
        
    }
}