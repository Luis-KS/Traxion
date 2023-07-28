public without sharing class SubalmacenController {
    @AuraEnabled(cacheable=true)
    public static Subalmacen__c getSubalmacenById(String subalmacenId) {
        try {
            return [SELECT Id, Numero_de_Subalmacen__c, Name
                    FROM Subalmacen__c
                    WHERE Id = :subalmacenId
                    LIMIT 1];
        } catch (Exception e) {
            System.debug('Query error: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
}