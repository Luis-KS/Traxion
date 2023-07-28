@isTest
public class FilesControllerTest {
    
        public class FileInfo {
            public String Filename;
            public Blob VersionData;
        }
    
    	@TestSetup
        static void data(){
            
           // Crear Account 

            Account account = TestDataFactory.createSingleAccount('AGUASCALIENTESTEST');
            Contact contact = TestDataFactory.createSingleContactRelatedToAccount(account.Id, 'Roberto', 'Sanchez', 'Todas');
            
            Pedido__c pedido = new Pedido__c(
                UMU__c = account.Id
            );
    
            insert pedido;

            Order__c orden = new Order__c(
                UMU__c = account.Id,
                Tipo_de_Pedido__c = 'Extraordinario',
                Estatus__c = 'Procesando',
                Contacto__c = contact.Id,
                Pedido__c = pedido.Id
            );
            
            insert orden;

        }

        @isTest
        static void uploadFilesTest() {
            
        List<FileInfo> filesList = new List<FileInfo>();
        
        // Crear objetos FileInfo y agregarlos a la lista
        FileInfo fileInfo1 = new FileInfo();
        fileInfo1.Filename = 'Archivo1.txt';
        fileInfo1.VersionData = Blob.valueOf('Contenido del archivo 1');
        filesList.add(fileInfo1);
        
        FileInfo fileInfo2 = new FileInfo();
        fileInfo2.Filename = 'Archivo2.txt';
        fileInfo2.VersionData = Blob.valueOf('Contenido del archivo 2');
        filesList.add(fileInfo2);
            
        Order__c orden = [SELECT Id FROM Order__c LIMIT 1];
		Test.startTest();
            	 List<Id> Ids = FilesController.uploadFiles(filesList, orden.Id);
        Test.stopTest();
            
        System.assert(Ids.size() > 0);
 
    }

    @isTest
    static void crearContentLinksTest() {

        Account account = TestDataFactory.createSingleAccount('AGUASCALIENTESTESTT');
        Contact contact = TestDataFactory.createSingleContactRelatedToAccount(account.Id, 'Rodrigo', 'Sanchez', 'Todas');
        
        List<Id> listaContentVersionIds = new List<Id>();
        List<ContentVersion> listaVersionsToInsert = new List<ContentVersion>();

        Order__c orden = new Order__c(
            UMU__c = account.Id,
            Tipo_de_Pedido__c = 'Extraordinario',
            Estatus__c = 'Procesando',
            Contacto__c = contact.Id
        );
        
        insert orden;

        List<FileInfo> filesList = new List<FileInfo>();
        
        // Crear objetos FileInfo y agregarlos a la lista
        FileInfo fileInfo1 = new FileInfo();
        fileInfo1.Filename = 'Archivo3.txt';
        fileInfo1.VersionData = Blob.valueOf('Contenido del archivo 1232');
        filesList.add(fileInfo1);
        
        for (Object file : filesList) {
            FileInfo fileData = (FileInfo)JSON.deserialize(JSON.serialize(file), FileInfo.class);
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.PathOnClient = fileData.Filename;
            contentVersion.Title = fileData.Filename;
            contentVersion.VersionData = fileData.VersionData;
            listaVersionsToInsert.add(contentVersion);

        }

        list<Database.saveResult> res = Database.insert(listaVersionsToInsert);

        for (Database.SaveResult saveResult : res) {
            if(saveResult.isSuccess()) {
                listaContentVersionIds.add(saveResult.getId());
            }
        }

        Test.startTest();
            List<ContentDocumentLink> contentDocumentListTest = FilesController.crearContentLinks(listaContentVersionIds, orden.Id);
        Test.stopTest();

        Assert.areEqual(1, contentDocumentListTest.size());
    }

    @isTest
    static void deleteRelatedAttachmentTestSuccess(){
      
        Account account = TestDataFactory.createSingleAccount('AGUASCALIENTESTESTT');
        Contact contact = TestDataFactory.createSingleContactRelatedToAccount(account.Id, 'Rodrigo', 'Sanchez', 'Todas');
        
        List<Id> listaContentVersionIds = new List<Id>();
        List<ContentVersion> listaVersionsToInsert = new List<ContentVersion>();

        Order__c orden = new Order__c(
            UMU__c = account.Id,
            Tipo_de_Pedido__c = 'Extraordinario',
            Estatus__c = 'Procesando',
            Contacto__c = contact.Id
        );
        
        insert orden;

        List<FileInfo> filesList = new List<FileInfo>();
        
        // Crear objetos FileInfo y agregarlos a la lista
        FileInfo fileInfo1 = new FileInfo();
        fileInfo1.Filename = 'Archivo3.txt';
        fileInfo1.VersionData = Blob.valueOf('Contenido del archivo 1232');
        filesList.add(fileInfo1);
        
        for (Object file : filesList) {
            FileInfo fileData = (FileInfo)JSON.deserialize(JSON.serialize(file), FileInfo.class);
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.PathOnClient = fileData.Filename;
            contentVersion.Title = fileData.Filename;
            contentVersion.VersionData = fileData.VersionData;
            listaVersionsToInsert.add(contentVersion);

        }

        list<Database.saveResult> res = Database.insert(listaVersionsToInsert);

        for (Database.SaveResult saveResult : res) {
            if(saveResult.isSuccess()) {
                listaContentVersionIds.add(saveResult.getId());
            }
        }

        List<ContentDocumentLink> contentDocumentListTest = FilesController.crearContentLinks(listaContentVersionIds, orden.Id);

        ContentDocument contentDocument = [SELECT Id FROM ContentDocument LIMIT 1];
        System.debug('contentDocument' + contentDocument);

        Test.startTest();
            String result = FilesController.deleteRelatedAttachment(contentDocument.Id);
        Test.stopTest();

        Assert.areEqual('SUCCESS', result);

    }

    @isTest
    static void deleteRelatedAttachmentTestFailure(){
      
        Account account = TestDataFactory.createSingleAccount('AGUASCALIENTESTESTT');
        Contact contact = TestDataFactory.createSingleContactRelatedToAccount(account.Id, 'Rodrigo', 'Sanchez', 'Todas');
        
        List<Id> listaContentVersionIds = new List<Id>();
        List<ContentVersion> listaVersionsToInsert = new List<ContentVersion>();

        Order__c orden = new Order__c(
            UMU__c = account.Id,
            Tipo_de_Pedido__c = 'Extraordinario',
            Estatus__c = 'Procesando',
            Contacto__c = contact.Id
        );
        
        insert orden;

        List<FileInfo> filesList = new List<FileInfo>();
        
        // Crear objetos FileInfo y agregarlos a la lista
        FileInfo fileInfo1 = new FileInfo();
        fileInfo1.Filename = 'Archivo3.txt';
        fileInfo1.VersionData = Blob.valueOf('Contenido del archivo 1232');
        filesList.add(fileInfo1);
        
        for (Object file : filesList) {
            FileInfo fileData = (FileInfo)JSON.deserialize(JSON.serialize(file), FileInfo.class);
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.PathOnClient = fileData.Filename;
            contentVersion.Title = fileData.Filename;
            contentVersion.VersionData = fileData.VersionData;
            listaVersionsToInsert.add(contentVersion);

        }

        list<Database.saveResult> res = Database.insert(listaVersionsToInsert);

        for (Database.SaveResult saveResult : res) {
            if(saveResult.isSuccess()) {
                listaContentVersionIds.add(saveResult.getId());
            }
        }

        List<ContentDocumentLink> contentDocumentListTest = FilesController.crearContentLinks(listaContentVersionIds, orden.Id);

        Id contentDocumentId = contentDocumentListTest[0].Id;

        Test.startTest();
            String result = FilesController.deleteRelatedAttachment(contentDocumentId);
        Test.stopTest();

        Assert.areEqual('FAILURE', result);
    }
 


    @isTest
    static void getContentDocumentIdsTest(){

        Account account = TestDataFactory.createSingleAccount('AGUASCALIENTESTESTT');
        Contact contact = TestDataFactory.createSingleContactRelatedToAccount(account.Id, 'Rodrigo', 'Sanchez', 'Todas');
        
        List<Id> listaContentVersionIds = new List<Id>();
        List<ContentVersion> listaVersionsToInsert = new List<ContentVersion>();

        Order__c orden = new Order__c(
            UMU__c = account.Id,
            Tipo_de_Pedido__c = 'Extraordinario',
            Estatus__c = 'Procesando',
            Contacto__c = contact.Id
        );
        
        insert orden;

        List<FileInfo> filesList = new List<FileInfo>();
        
        // Crear objetos FileInfo y agregarlos a la lista
        FileInfo fileInfo1 = new FileInfo();
        fileInfo1.Filename = 'Archivo3.txt';
        fileInfo1.VersionData = Blob.valueOf('Contenido del archivo 1232');
        filesList.add(fileInfo1);
        
        for (Object file : filesList) {
            FileInfo fileData = (FileInfo)JSON.deserialize(JSON.serialize(file), FileInfo.class);
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.PathOnClient = fileData.Filename;
            contentVersion.Title = fileData.Filename;
            contentVersion.VersionData = fileData.VersionData;
            listaVersionsToInsert.add(contentVersion);

        }

        list<Database.saveResult> res = Database.insert(listaVersionsToInsert);

        for (Database.SaveResult saveResult : res) {
            if(saveResult.isSuccess()) {
                listaContentVersionIds.add(saveResult.getId());
            }
        }

        List<ContentDocumentLink> contentDocumentListTest = FilesController.crearContentLinks(listaContentVersionIds, orden.Id);

        Test.startTest();
            List<Id> contentDocumentsIds = FilesController.getContentDocumentIds(contentDocumentListTest);
        Test.stopTest();

        Assert.isTrue(contentDocumentsIds.size() > 0, 'La lista debe contener al menos 1 item.');       

    }


    @isTest
    static void getContentDistributionForFileTest(){
      
        Account account = TestDataFactory.createSingleAccount('AGUASCALIENTESTESTT');
        Contact contact = TestDataFactory.createSingleContactRelatedToAccount(account.Id, 'Rodrigo', 'Sanchez', 'Todas');
        
        List<Id> listaContentVersionIds = new List<Id>();
        List<ContentVersion> listaVersionsToInsert = new List<ContentVersion>();

        Order__c orden = new Order__c(
            UMU__c = account.Id,
            Tipo_de_Pedido__c = 'Extraordinario',
            Estatus__c = 'Procesando',
            Contacto__c = contact.Id
        );
        
        insert orden;

        List<FileInfo> filesList = new List<FileInfo>();
        
        // Crear objetos FileInfo y agregarlos a la lista
        FileInfo fileInfo1 = new FileInfo();
        fileInfo1.Filename = 'Archivo3.txt';
        fileInfo1.VersionData = Blob.valueOf('Contenido del archivo 1232');
        filesList.add(fileInfo1);
        
        for (Object file : filesList) {
            FileInfo fileData = (FileInfo)JSON.deserialize(JSON.serialize(file), FileInfo.class);
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.PathOnClient = fileData.Filename;
            contentVersion.Title = fileData.Filename;
            contentVersion.VersionData = fileData.VersionData;
            listaVersionsToInsert.add(contentVersion);

        }

        list<Database.saveResult> res = Database.insert(listaVersionsToInsert);

        for (Database.SaveResult saveResult : res) {
            if(saveResult.isSuccess()) {
                listaContentVersionIds.add(saveResult.getId());
            }
        }

        List<ContentDocumentLink> contentDocumentListTest = FilesController.crearContentLinks(listaContentVersionIds, orden.Id);
        List<Id> contentDocumentsIds = FilesController.getContentDocumentIds(contentDocumentListTest);

        Id documentId = contentDocumentsIds[0];
        Test.startTest();
            ContentDistribution contentDistribution = FilesController.getContentDistributionForFile(documentId);
        Test.stopTest();

        Assert.isTrue(contentDistribution != null, 'Debe de ser diferente de null');
    }


    @IsTest
    static void prepareDocumentIdToContentDocumentListMapTest() {
        
        Account account = TestDataFactory.createSingleAccount('AGUASCALIENTESTESTT');
        Contact contact = TestDataFactory.createSingleContactRelatedToAccount(account.Id, 'Rodrigo', 'Sanchez', 'Todas');
        
        List<Id> listaContentVersionIds = new List<Id>();
        List<ContentVersion> listaVersionsToInsert = new List<ContentVersion>();

        Order__c orden = new Order__c(
            UMU__c = account.Id,
            Tipo_de_Pedido__c = 'Extraordinario',
            Estatus__c = 'Procesando',
            Contacto__c = contact.Id
        );
        
        insert orden;

        List<FileInfo> filesList = new List<FileInfo>();
        
        // Crear objetos FileInfo y agregarlos a la lista
        FileInfo fileInfo1 = new FileInfo();
        fileInfo1.Filename = 'Archivo3.txt';
        fileInfo1.VersionData = Blob.valueOf('Contenido del archivo 1232');
        filesList.add(fileInfo1);
        
        for (Object file : filesList) {
            FileInfo fileData = (FileInfo)JSON.deserialize(JSON.serialize(file), FileInfo.class);
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.PathOnClient = fileData.Filename;
            contentVersion.Title = fileData.Filename;
            contentVersion.VersionData = fileData.VersionData;
            listaVersionsToInsert.add(contentVersion);

        }

        list<Database.saveResult> res = Database.insert(listaVersionsToInsert);

        for (Database.SaveResult saveResult : res) {
            if(saveResult.isSuccess()) {
                listaContentVersionIds.add(saveResult.getId());
            }
        }

        List<ContentDocumentLink> contentDocumentListTest = FilesController.crearContentLinks(listaContentVersionIds, orden.Id);
        List<Id> contentDocumentsIds = FilesController.getContentDocumentIds(contentDocumentListTest);

        Map<Id, ContentDocument> contentDocuments = new Map<Id, ContentDocument>([ SELECT Id, Title, FileExtension
                                                                                       FROM ContentDocument
                                                                                       WHERE Id IN: contentDocumentsIds ]);

        Test.startTest();
        Map<Id, List<ContentDocument>> documentIdToContentDocumentsList = FilesController.prepareDocumentIdToContentDocumentListMap(contentDocumentListTest, contentDocuments);
        Test.stopTest();

       for(Id id: documentIdToContentDocumentsList.keySet()){
            Assert.isTrue(documentIdToContentDocumentsList.get(id).size() > 0,'Se espera que el resultado sea mayor o igual a 1.');
       }

    }
 
    @IsTest
    static void preparePedidoDocumentWrapperResponseTest() {
        
        Account account = TestDataFactory.createSingleAccount('AGUASCALIENTESTESTT');
        Contact contact = TestDataFactory.createSingleContactRelatedToAccount(account.Id, 'Rodrigo', 'Sanchez', 'Todas');
        
        List<Id> listaContentVersionIds = new List<Id>();
        List<ContentVersion> listaVersionsToInsert = new List<ContentVersion>();       

        Pedido__c pedido = new Pedido__c(
            UMU__c = account.Id
        );

        insert pedido;
        
        Order__c orden = new Order__c(
            UMU__c = account.Id,
            Tipo_de_Pedido__c = 'Extraordinario',
            Estatus__c = 'Procesando',
            Contacto__c = contact.Id,
            Pedido__c = pedido.Id
        );
        
        insert orden;

        List<FileInfo> filesList = new List<FileInfo>();
        
        // Crear objetos FileInfo y agregarlos a la lista
        FileInfo fileInfo1 = new FileInfo();
        fileInfo1.Filename = 'Archivo3.txt';
        fileInfo1.VersionData = Blob.valueOf('Contenido del archivo 1232');
        filesList.add(fileInfo1);
        
        for (Object file : filesList) {
            FileInfo fileData = (FileInfo)JSON.deserialize(JSON.serialize(file), FileInfo.class);
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.PathOnClient = fileData.Filename;
            contentVersion.Title = fileData.Filename;
            contentVersion.VersionData = fileData.VersionData;
            listaVersionsToInsert.add(contentVersion);

        }

        list<Database.saveResult> res = Database.insert(listaVersionsToInsert);

        for (Database.SaveResult saveResult : res) {
            if(saveResult.isSuccess()) {
                listaContentVersionIds.add(saveResult.getId());
            }
        }

        List<ContentDocumentLink> contentDocumentListTest = FilesController.crearContentLinks(listaContentVersionIds, orden.Id);
        List<Id> contentDocumentsIds = FilesController.getContentDocumentIds(contentDocumentListTest);

        Map<Id, ContentDocument> contentDocuments = new Map<Id, ContentDocument>([ SELECT Id, Title, FileExtension
                                                                                       FROM ContentDocument
                                                                                       WHERE Id IN: contentDocumentsIds ]);

        Map<Id, List<ContentDocument>> documentIdToContentDocumentsList = FilesController.prepareDocumentIdToContentDocumentListMap(contentDocumentListTest, contentDocuments);

        Map<Id, Pedido__c> documents = new Map<Id, Pedido__c>([
            SELECT Id, Name, 
                (SELECT Id, Name 
                 FROM Ordenes__r)
            FROM Pedido__c
            WHERE Id =: pedido.Id
        ]); 

        Test.startTest();
            List<DocumentWrapper> documentWrapper = FilesController.preparePedidoDocumentWrapperResponse(documentIdToContentDocumentsList, documents);
        Test.stopTest();

        Assert.areEqual(1, documentWrapper.size(),'Se espera que el resultado sea 1.');

    }


    @IsTest
    static void prepareDocumentWrapperResponseTest() {
        
        Account account = TestDataFactory.createSingleAccount('AGUASCALIENTESTESTT');
        Contact contact = TestDataFactory.createSingleContactRelatedToAccount(account.Id, 'Rodrigo', 'Sanchez', 'Todas');
        
        List<Id> listaContentVersionIds = new List<Id>();
        List<ContentVersion> listaVersionsToInsert = new List<ContentVersion>();       

        Pedido__c pedido = new Pedido__c(
            UMU__c = account.Id
        );

        insert pedido;
        
        Order__c orden = new Order__c(
            UMU__c = account.Id,
            Tipo_de_Pedido__c = 'Extraordinario',
            Estatus__c = 'Procesando',
            Contacto__c = contact.Id,
            Pedido__c = pedido.Id
        );
        
        insert orden;

        List<FileInfo> filesList = new List<FileInfo>();
        
        // Crear objetos FileInfo y agregarlos a la lista
        FileInfo fileInfo1 = new FileInfo();
        fileInfo1.Filename = 'Archivo3.txt';
        fileInfo1.VersionData = Blob.valueOf('Contenido del archivo 1232');
        filesList.add(fileInfo1);
        
        for (Object file : filesList) {
            FileInfo fileData = (FileInfo)JSON.deserialize(JSON.serialize(file), FileInfo.class);
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.PathOnClient = fileData.Filename;
            contentVersion.Title = fileData.Filename;
            contentVersion.VersionData = fileData.VersionData;
            listaVersionsToInsert.add(contentVersion);

        }

        list<Database.saveResult> res = Database.insert(listaVersionsToInsert);

        for (Database.SaveResult saveResult : res) {
            if(saveResult.isSuccess()) {
                listaContentVersionIds.add(saveResult.getId());
            }
        }

        List<ContentDocumentLink> contentDocumentListTest = FilesController.crearContentLinks(listaContentVersionIds, orden.Id);
        List<Id> contentDocumentsIds = FilesController.getContentDocumentIds(contentDocumentListTest);

        Map<Id, ContentDocument> contentDocuments = new Map<Id, ContentDocument>([ SELECT Id, Title, FileExtension
                                                                                       FROM ContentDocument
                                                                                       WHERE Id IN: contentDocumentsIds ]);

        Map<Id, List<ContentDocument>> documentIdToContentDocumentsList = FilesController.prepareDocumentIdToContentDocumentListMap(contentDocumentListTest, contentDocuments);

        Map<Id, Order__c> documents = new Map<Id, Order__c>([ SELECT Id, Name, Descripcion__c
        FROM Order__c
        WHERE Id =: orden.Id]); 

        Test.startTest();
            List<DocumentWrapper> documentWrapper = FilesController.prepareDocumentWrapperResponse(documentIdToContentDocumentsList,documents);
        Test.stopTest();

        Assert.areEqual(1, documentWrapper.size(), 'Se espera que el resultado sea 1.');
    }


    @IsTest
    static void getAllDocumentsAndRelatedFilesTest() {
        

        Account account = TestDataFactory.createSingleAccount('AGUASCALIENTESTESTT');
        Contact contact = TestDataFactory.createSingleContactRelatedToAccount(account.Id, 'Rodrigo', 'Sanchez', 'Todas');
        
        List<Id> listaContentVersionIds = new List<Id>();
        List<ContentVersion> listaVersionsToInsert = new List<ContentVersion>();       

        Pedido__c pedido = new Pedido__c(
            UMU__c = account.Id
        );

        insert pedido;
        
        Order__c orden = new Order__c(
            UMU__c = account.Id,
            Tipo_de_Pedido__c = 'Extraordinario',
            Estatus__c = 'Procesando',
            Contacto__c = contact.Id,
            Pedido__c = pedido.Id
        );
        
        insert orden;

        List<FileInfo> filesList = new List<FileInfo>();
        
        // Crear objetos FileInfo y agregarlos a la lista
        FileInfo fileInfo1 = new FileInfo();
        fileInfo1.Filename = 'Archivo3.txt';
        fileInfo1.VersionData = Blob.valueOf('Contenido del archivo 1232');
        filesList.add(fileInfo1);
        
        for (Object file : filesList) {
            FileInfo fileData = (FileInfo)JSON.deserialize(JSON.serialize(file), FileInfo.class);
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.PathOnClient = fileData.Filename;
            contentVersion.Title = fileData.Filename;
            contentVersion.VersionData = fileData.VersionData;
            listaVersionsToInsert.add(contentVersion);

        }

        list<Database.saveResult> res = Database.insert(listaVersionsToInsert);

        for (Database.SaveResult saveResult : res) {
            if(saveResult.isSuccess()) {
                listaContentVersionIds.add(saveResult.getId());
            }
        }

        List<ContentDocumentLink> contentDocumentListTest = FilesController.crearContentLinks(listaContentVersionIds, orden.Id);
        List<Id> contentDocumentsIds = FilesController.getContentDocumentIds(contentDocumentListTest);

        Test.startTest();
          List<DocumentWrapper> documentWrapper = FilesController.getAllDocumentsAndRelatedFiles(orden.Id);
        Test.stopTest();

        Assert.areEqual(1, documentWrapper.size(), 'Se espera que el resultado sea 1.');
    }



    @IsTest
    static void getPedidoDocumentsAndRelatedFilesTest() {
        
    
        Account account = TestDataFactory.createSingleAccount('AGUASCALIENTESTESTT');
        Contact contact = TestDataFactory.createSingleContactRelatedToAccount(account.Id, 'Rodrigo', 'Sanchez', 'Todas');
        
        List<Id> listaContentVersionIds = new List<Id>();
        List<ContentVersion> listaVersionsToInsert = new List<ContentVersion>();       

        Pedido__c pedido = [SELECT Id FROM Pedido__c LIMIT 1];
        Order__c orden = [SELECT Id FROM Order__c WHERE Pedido__c =: pedido.Id];
        List<FileInfo> filesList = new List<FileInfo>();
        
        // Crear objetos FileInfo y agregarlos a la lista
        FileInfo fileInfo1 = new FileInfo();
        fileInfo1.Filename = 'Archivo3.txt';
        fileInfo1.VersionData = Blob.valueOf('Contenido del archivo 1232');
        filesList.add(fileInfo1);
        
        for (Object file : filesList) {
            FileInfo fileData = (FileInfo)JSON.deserialize(JSON.serialize(file), FileInfo.class);
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.PathOnClient = fileData.Filename;
            contentVersion.Title = fileData.Filename;
            contentVersion.VersionData = fileData.VersionData;
            listaVersionsToInsert.add(contentVersion);

        }

        list<Database.saveResult> res = Database.insert(listaVersionsToInsert);

        for (Database.SaveResult saveResult : res) {
            if(saveResult.isSuccess()) {
                listaContentVersionIds.add(saveResult.getId());
            }
        }

        List<ContentDocumentLink> contentDocumentListTest = FilesController.crearContentLinks(listaContentVersionIds, orden.Id);

        Test.startTest();
            List<DocumentWrapper> documentWrapper = FilesController.getPedidoDocumentsAndRelatedFiles(pedido.Id);
        Test.stopTest();

        Assert.areEqual(1, documentWrapper.size());
    }
}