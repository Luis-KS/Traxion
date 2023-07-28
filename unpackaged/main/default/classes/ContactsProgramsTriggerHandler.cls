public class ContactsProgramsTriggerHandler {
	public static void ContactsProgramsBeforeInsertHandler(List<Contactos_y_Programas__c> newContactsProgramsList){
    	ContactsProgramsFields.insertRecords(newContactsProgramsList); 
    }
}