public class ImageUploadController {

    @AuraEnabled
    public static String saveImage(String fileName, String base64Data, String parentId, Boolean isCheckin) {
        try {
            // Extract only base64 part of the string by removing data type prefix (if exists)
            String base64Prefix = 'base64,';
            Integer indexOfBase64Start = base64Data.indexOf(base64Prefix);

            if (indexOfBase64Start != -1) {
                base64Data = base64Data.substring(indexOfBase64Start + base64Prefix.length());
            }

            Blob imageBlob = EncodingUtil.base64Decode(base64Data);

            ContentVersion contentVersion = new ContentVersion();
            contentVersion.Title = ' Evidencia ' + fileName;
            contentVersion.PathOnClient = fileName;
            contentVersion.VersionData = imageBlob;

            insert contentVersion;

            ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
            contentDocumentLink.ContentDocumentId = 
                [SELECT Id, ContentDocumentId 
                 FROM ContentVersion 
                 WHERE Id = :contentVersion.Id WITH SECURITY_ENFORCED].ContentDocumentId;

            contentDocumentLink.LinkedEntityId = parentId;
            contentDocumentLink.ShareType = 'V'; // V – Viewer permission. C – Collaborator permission. I – Inferred permission.

            insert contentDocumentLink;

            List<Order__c> OrderImg = [
                SELECT id, ImageId__c, Estatus__c
                FROM Order__c
                WHERE Id = :parentId
            ];
            List<Order__c> orderUpdate = new List<Order__c>();

            if (OrderImg.size() > 0) {
                for (Order__c orden : OrderImg) {
                    orden.ImageId__c = true;
                    orderUpdate.add(orden);

                    if (isCheckin == true) {
                        orden.Estatus__c = 'Llegada de Transporte';
                    }
                }
                update orderUpdate;
            }

            return contentVersion.Id;
        } catch (Exception e) {
            System.debug('Exception occurred: ' + e.getMessage());
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }
}