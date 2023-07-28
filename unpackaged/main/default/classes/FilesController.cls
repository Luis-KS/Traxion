public with sharing class FilesController {

    public class MyFilesException extends Exception {} 

    public class FileInfo {
        public String Filename;
        public Blob VersionData;
    }


    @AuraEnabled
    public static List<Id> uploadFiles(List<Object> filesToInsert, String recordId){

        List<Id> listaContentVersionIds = new List<Id>();
        List<ContentVersion> listaVersionsToInsert = new List<ContentVersion>();

        for (Object file : filesToInsert) {
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

        crearContentLinks(listaContentVersionIds, recordId);
        return listaContentVersionIds;
        
    }

    @testVisible
    private static List<ContentDocumentLink> crearContentLinks(List<Id> contentVersionId, String recordId) {

        if (contentVersionId.size() <= 0 || recordId == null) { return null; }
        List<ContentDocumentLink> ContentDocumentLinkList = new List<ContentDocumentLink>();

        // Obtener los contentDocumentIds
           for(ContentVersion version: [SELECT ContentDocumentId 
                                       FROM ContentVersion
                                       WHERE Id IN :contentVersionId]){

            ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
            contentDocumentLink.contentDocumentId = version.ContentDocumentId;
            contentDocumentLink.LinkedEntityId = recordId;
            contentDocumentLink.ShareType = 'V';
            ContentDocumentLinkList.add(contentDocumentLink);
        }

        insert contentDocumentLinkList;
        return ContentDocumentLinkList;

    }

    @AuraEnabled
    public static String deleteRelatedAttachment(Id contentDocumentId){
        List<ContentDocument> conDocList = [
            SELECT Id 
            FROM ContentDocument 
            WHERE Id =: contentDocumentId 
        ];

        if(conDocList.isEmpty()){
            return 'FAILURE';
        }

        try{
            delete conDocList;
            return 'SUCCESS';
        } catch(Exception e){
            System.debug(e.getMessage());
            return e.getMessage();
        }
    } 
    

    @AuraEnabled
    public static List<DocumentWrapper> getPedidoDocumentsAndRelatedFiles(Id pedidoId){
        Map<Id, Pedido__c> documents = new Map<Id, Pedido__c>([
            SELECT Id, Name, 
                (SELECT Id, Name 
                 FROM Ordenes__r)
            FROM Pedido__c
            WHERE Id =: pedidoId
        ]); 

        Set<Id> newSet = new Set<Id>(); 
        for(Pedido__c pedido : documents.values()){
            newSet.add(pedido.Id); 
            for(Order__c ord : pedido.Ordenes__r){
                newSet.add(ord.Id);
            } 
        }

        System.debug('Set of ids');
        System.debug(newSet);

        if(newSet.size() > 0){
            Map<Id, ContentDocumentLink> contentDocumentLinks = new Map<Id, ContentDocumentLink>([ SELECT Id, LinkedEntityId, ContentDocumentId
                                                                                                   FROM ContentDocumentLink
                                                                                                   WHERE LinkedEntityId IN: newSet]); 

            System.debug('Inside if');                                                                                       
            System.debug(contentDocumentLinks);

            Map<Id, ContentDocument> contentDocuments = new Map<Id, ContentDocument>([ SELECT Id, Title, FileExtension
                                                                                       FROM ContentDocument
                                                                                       WHERE Id IN: getContentDocumentIds(contentDocumentLinks.values()) ]);
            
            System.debug('Flag1');
            System.debug(contentDocuments);
            
            Map<Id, List<ContentDocument>> documentIdToContentDocumentsList = prepareDocumentIdToContentDocumentListMap(contentDocumentLinks.values(), contentDocuments);
            System.debug('Flag2');
            System.debug(documentIdToContentDocumentsList);

            System.debug('Flag3');
            System.debug(preparePedidoDocumentWrapperResponse(documentIdToContentDocumentsList, documents));
            
            return preparePedidoDocumentWrapperResponse(documentIdToContentDocumentsList, documents);    
        } 
        else{
            return new List<DocumentWrapper>();
        }                                            
    }

    @AuraEnabled
    public static List<DocumentWrapper> getAllDocumentsAndRelatedFiles(Id orderId){
        Map<Id, Order__c> documents = new Map<Id, Order__c>([ SELECT Id, Name, Descripcion__c
                                                              FROM Order__c
                                                              WHERE Id =: orderId]); 
        Set<Id> newSet = documents.keySet(); 
        if(newSet.size() > 0){
            Map<Id, ContentDocumentLink> contentDocumentLinks = new Map<Id, ContentDocumentLink>([ SELECT Id, LinkedEntityId, ContentDocumentId
                                                                                                   FROM ContentDocumentLink
                                                                                                   WHERE LinkedEntityId IN: newSet]); 

            Map<Id, ContentDocument> contentDocuments = new Map<Id, ContentDocument>([ SELECT Id, Title, FileExtension
                                                                                       FROM ContentDocument
                                                                                       WHERE Id IN: getContentDocumentIds(contentDocumentLinks.values()) ]);

            Map<Id, List<ContentDocument>> documentIdToContentDocumentsList = prepareDocumentIdToContentDocumentListMap(contentDocumentLinks.values(), contentDocuments);

            return prepareDocumentWrapperResponse(documentIdToContentDocumentsList, documents);    
        } else{
            return new List<DocumentWrapper>();
        }                                            
    }

    @AuraEnabled
    public static ContentDistribution getContentDistributionForFile(Id contentDocumentId){

        ContentVersion contentVersion = [ SELECT Id, ContentDocumentId, IsMajorVersion, IsLatest
                                          FROM ContentVersion 
                                          WHERE ContentDocumentId =: contentDocumentId
                                            AND IsLatest = true 
                                          LIMIT 1 ];

        List<ContentDistribution> contentDistribution = [ SELECT Id, Name, ContentDownloadUrl, ContentVersionId 
                                                          FROM ContentDistribution 
                                                          WHERE ContentVersionId =: contentVersion.Id ];
        if (!contentDistribution.isEmpty()) {
            return contentDistribution[0];
        }
        // else create new contentDistribution
        ContentDistribution newContentDistribution = new ContentDistribution( Name = 'Test',
                                                                              ContentVersionId = contentVersion.Id,
                                                                              PreferencesAllowViewInBrowser = true );
        insert newContentDistribution;

        return  [ SELECT Id, Name, ContentDownloadUrl, ContentDocumentId 
                  FROM ContentDistribution 
                  WHERE Id =: newContentDistribution.Id 
                  LIMIT 1 ];
    }

    @testVisible
    private static List<Id> getContentDocumentIds(List<ContentDocumentLink> contentDocumentsLinks) {
        List<Id> contentDocumentsIds = new List<Id>();
        for (ContentDocumentLink contentDocumentLink : contentDocumentsLinks) {
            contentDocumentsIds.add(contentDocumentLink.ContentDocumentId);
        }
        return contentDocumentsIds;
    }

    @testVisible
    private static Map<Id, List<ContentDocument>> prepareDocumentIdToContentDocumentListMap(List<ContentDocumentLink> contentDocumentsLinks, Map<Id, ContentDocument> contentDocuments) {
        Map<Id, List<ContentDocument>> documentIdToContentDocumentsList = new Map<Id, List<ContentDocument>>();
        for (ContentDocumentLink contentDocumentLink : contentDocumentsLinks) {
            List<ContentDocument> currentContentDocumentList = documentIdToContentDocumentsList.get(contentDocumentLink.LinkedEntityId);
            if (currentContentDocumentList == null) {
                currentContentDocumentList = new List<ContentDocument>();
            } 
            currentContentDocumentList.add(
                contentDocuments.get(contentDocumentLink.ContentDocumentId)
            );
            documentIdToContentDocumentsList.put(contentDocumentLink.LinkedEntityId, currentContentDocumentList);
        }
        return documentIdToContentDocumentsList;
    }

    @testVisible
    private static List<DocumentWrapper> preparePedidoDocumentWrapperResponse(Map<Id, List<ContentDocument>> documentIdToContentDocumentsList, Map<Id, Pedido__c> documents) {
        List<DocumentWrapper> documentsAndFiles = new List<DocumentWrapper>();

        for (Id documentId : documentIdToContentDocumentsList.keySet()) {

            DocumentWrapper documentWrapper = new DocumentWrapper();
            documentWrapper.id = documentId;
            // documentWrapper.name = documents.get(documentId).Name;
            // documentWrapper.description = documents.get(documentId).Descripcion__c;

            documentWrapper.name = 'Test';
            documentWrapper.description = 'Test description';
            documentWrapper.files = new List<DocumentWrapper.FileWrapper>();

            for (ContentDocument contentDocument : documentIdToContentDocumentsList.get(documentId)) {
                DocumentWrapper.FileWrapper fileWrapper = new DocumentWrapper.FileWrapper();
                fileWrapper.id = contentDocument.Id;
                fileWrapper.name = contentDocument.Title;
                fileWrapper.fileExtension = contentDocument.FileExtension;
                documentWrapper.files.add(fileWrapper);
            }

            documentsAndFiles.add(documentWrapper);
        }

        return documentsAndFiles;
    }

    @testVisible
    private static List<DocumentWrapper> prepareDocumentWrapperResponse(Map<Id, List<ContentDocument>> documentIdToContentDocumentsList, Map<Id, Order__c> documents) {
        List<DocumentWrapper> documentsAndFiles = new List<DocumentWrapper>();

        for (Id documentId : documentIdToContentDocumentsList.keySet()) {

            DocumentWrapper documentWrapper = new DocumentWrapper();
            documentWrapper.id = documentId;
            documentWrapper.name = documents.get(documentId).Name;
            documentWrapper.description = documents.get(documentId).Descripcion__c;
            documentWrapper.files = new List<DocumentWrapper.FileWrapper>();

            for (ContentDocument contentDocument : documentIdToContentDocumentsList.get(documentId)) {
                DocumentWrapper.FileWrapper fileWrapper = new DocumentWrapper.FileWrapper();
                fileWrapper.id = contentDocument.Id;
                fileWrapper.name = contentDocument.Title;
                fileWrapper.fileExtension = contentDocument.FileExtension;
                documentWrapper.files.add(fileWrapper);
            }

            documentsAndFiles.add(documentWrapper);
        }

        return documentsAndFiles;
    }

}