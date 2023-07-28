public with sharing class ContactsProgramsFields {
    public static void insertRecords(List<Contactos_y_Programas__c> newContactsProgramsList) {
        if(Trigger.isInsert){
            Map<String, Contactos_y_Programas__c> contactProgMap = New Map<String, Contactos_y_Programas__c>();
            
            for (List<Contactos_y_Programas__c> cpl : [SELECT Id, Contact__c, Contact__r.Name, Programa__c, Programa__r.Name
                                                       FROM Contactos_y_Programas__c]){
                for(Contactos_y_Programas__c cp : cpl)  {
                    contactProgMap.put(cp.Contact__c+''+cp.Programa__c, cp);
                }
            }

            for(Contactos_y_Programas__c contactProg : newContactsProgramsList) {
                if(contactProgMap.containsKey(contactProg.Contact__c+''+contactProg.Programa__c)){
                    Contactos_y_Programas__c existingCP = contactProgMap.get(contactProg.Contact__c+''+contactProg.Programa__c);
                    String errorMessage = 'El contacto ' + existingCP.Contact__r.Name + ' ya tiene asociado el programa ' + existingCP.Programa__r.Name;
                    contactProg.addError(errorMessage);
                }
            }
        }
    }
}