public without sharing class ProgramController {
	@AuraEnabled(cacheable=true)
    public static Programas__c getProgramById(String programId) {
        try {
            return [SELECT Id, Programa_ID__c, Name, Inventario__c 
                    FROM Programas__c
                    WHERE Id = :programId
                    LIMIT 1];
        } catch (Exception e) {
            System.debug('Query error: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Programas__c> getProgramsByContact() {
    	List<Id> programsIdList = new List<Id>();
        try {
            programsIdList = UserContactClass.getProgramIdsByContact();
            return [SELECT Id, Programa_ID__c, Name 
                    FROM Programas__c
                    WHERE Id IN :programsIdList];
        } catch (Exception e) {
            System.debug('Query error: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
}