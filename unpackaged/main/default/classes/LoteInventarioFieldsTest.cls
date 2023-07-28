@isTest
public with sharing class LoteInventarioFieldsTest {
    
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
        insert cveInventario;

        Clave_de_Inventario__c cveInventario2 = new Clave_de_Inventario__c(); 
        cveInventario2.Producto__c = listproduct[1].Id;
        cveInventario2.Inventario__c = inventario.Id; 
        insert cveInventario2;

        Lote_de_Inventario__c loteInventario = new Lote_de_Inventario__c(); 
        loteInventario.Conteo_Actual__c = 0;
        loteInventario.Conteo_Anterior__c = 0;
        loteInventario.Fecha_de_Caducidad__c = System.Today() + 5;
        loteInventario.Lote__c = 'LOTE01';
        loteInventario.Clave_de_Inventario__c = cveInventario.Id; 
        insert loteInventario;

        Lote_de_Inventario__c loteInventario2 = new Lote_de_Inventario__c(); 
        loteInventario2.Conteo_Actual__c = 0;
        loteInventario2.Conteo_Anterior__c = 0;
        loteInventario2.Fecha_de_Caducidad__c = System.Today() + 5;
        loteInventario2.Lote__c = 'LOTE02';
        loteInventario2.Clave_de_Inventario__c = cveInventario.Id; 
        insert loteInventario2;

        Lote_de_Inventario__c loteInventario3 = new Lote_de_Inventario__c(); 
        loteInventario3.Conteo_Actual__c = 0;
        loteInventario3.Conteo_Anterior__c = 0;
        loteInventario3.Fecha_de_Caducidad__c = System.Today() + 5;
        loteInventario3.Lote__c = 'LOTE01';
        loteInventario3.Clave_de_Inventario__c = cveInventario2.Id; 
        insert loteInventario3;

        Inventario__c invEnFirma = new Inventario__c(); 
        invEnFirma.Clasificacion__c = 'Material de Curación';
        invEnFirma.Tipo_de_Insumo__c = 'Compra Local';
        invEnFirma.UMU__c = accountIdList[0]; 
        invEnFirma.Fecha_Registrado__c = System.Now() - 1;
        invEnFirma.Estatus__c = null;
        insert invEnFirma;

        Clave_de_Inventario__c cveInvFirma = new Clave_de_Inventario__c(); 
        cveInvFirma.Producto__c = listproduct[0].Id;
        cveInvFirma.Inventario__c = invEnFirma.Id; 
        insert cveInvFirma;

        Lote_de_Inventario__c loteInvFirma = new Lote_de_Inventario__c(); 
        loteInvFirma.Conteo_Actual__c = 0;
        loteInvFirma.Conteo_Anterior__c = 0;
        loteInvFirma.Fecha_de_Caducidad__c = System.Today() + 5;
        loteInvFirma.Lote__c = 'LOTE01';
        loteInvFirma.Clave_de_Inventario__c = cveInvFirma.Id; 
        insert loteInvFirma;

        loteInvFirma.Estatus_Conteo_Lote__c = 'Contado';
        update loteInvFirma;

        cveInvFirma.Estatus_de_Conteo__c = 'Contado';
        update cveInvFirma;

        invEnFirma.Estatus__c = 'En Firma';
        update invEnFirma;
    }

    @IsTest
    static void testConteoLoteInicial() {

        List<Lote_de_Inventario__c> loteInvUpd = New List<Lote_de_Inventario__c>();
        List<Clave_de_Inventario__c > cveInvList = [SELECT Id, Inventario__c 
                                                    FROM Clave_de_Inventario__c 
                                                    LIMIT 1];

        List<Lote_de_Inventario__c> loteList = [SELECT Conteo_Actual__c, Clave_de_Inventario__c, Conteo_Anterior__c, Fecha_de_Caducidad__c, Lote__c, Estatus_Conteo_Lote__c
                                                FROM Lote_de_Inventario__c 
                                                WHERE Clave_de_Inventario__c = :cveInvList[0].Id];
                    
        for(Lote_de_Inventario__c lote : loteList ){
            lote.Conteo_Actual__c = 10;
            lote.Conteo_Anterior__c = 5;
            lote.Estatus_Conteo_Lote__c = 'Contado';
            loteInvUpd.add(lote);
        }
        Test.startTest();
            update loteInvUpd;
        Test.stopTest();

        Id claveInventario;
        for(Lote_de_Inventario__c lot : loteInvUpd ){
            claveInventario = lot.Clave_de_Inventario__c;
            break;
        }

        System.assertEquals('Iniciado', [SELECT Estatus_de_Conteo__c FROM Clave_de_Inventario__c WHERE Id = : claveInventario].Estatus_de_Conteo__c, 'Estatus de Clave de Inventario diferente a Iniciado');
    }

    @IsTest
    static void testConteoLoteInvEnFirma() {

        List<Lote_de_Inventario__c> loteInvUpdList = New List<Lote_de_Inventario__c>();
        List<Inventario__c> invUpdList = New List<Inventario__c>();

        List<Clave_de_Inventario__c > cveInvList = [SELECT Id, Inventario__c FROM Clave_de_Inventario__c WHERE Inventario__r.Tipo_de_Insumo__c = 'Compra Local' LIMIT 1];

        
        List<Lote_de_Inventario__c> loteList = [SELECT Conteo_Actual__c, Conteo_Anterior__c, Fecha_de_Caducidad__c, Lote__c, Estatus_Conteo_Lote__c
                                                FROM Lote_de_Inventario__c 
                                                WHERE Clave_de_Inventario__c = :cveInvList[0].Id];
                    
        for(Lote_de_Inventario__c lote : loteList ){
            lote.Conteo_Actual__c = 8;
            lote.Conteo_Anterior__c = 8;
            lote.Estatus_Conteo_Lote__c = 'Contado';
            loteInvUpdList.add(lote);
        }
        Test.startTest();
            try {
                update loteInvUpdList;
            } catch (Exception e){
                System.debug('Update Error Message: ' + e.getMessage());
            }
            try {
                delete loteInvUpdList;
            } catch (Exception e){
                System.debug('Delete Error Message: ' + e.getMessage());
            }
        Test.stopTest();

        //System.debug('loteList.Size: ' + loteList.Size());
        System.assertEquals(loteInvUpdList.Size(), [SELECT Count() 
                                                    FROM Lote_de_Inventario__c 
                                                    WHERE Clave_de_Inventario__c = :cveInvList[0].Id], 'Se elimino el lote de un inventario En Firma');
    
    }
}