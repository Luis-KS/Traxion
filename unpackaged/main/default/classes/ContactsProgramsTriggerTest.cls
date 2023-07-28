@isTest
public class ContactsProgramsTriggerTest {
	@isTest
    public static void testBeforeInsertTrigger() {
        List<Contactos_y_Programas__c> cpList = TestDataFactory.createMultipleContactsAndPrograms(3);
        
        Test.startTest();
        Database.SaveResult[] result = Database.insert(cpList);
        System.assertEquals(3, result.size(), 'SaveResult list size must be 3');
        
        Contactos_y_Programas__c cp = [
            SELECT Id, Contact__c, Programa__c
            FROM Contactos_y_Programas__c LIMIT 1
        ];
        
        Contactos_y_Programas__c conProg = new Contactos_y_Programas__c(
            Contact__c = cp.Contact__c,
            Programa__c = cp.Programa__c
        );
        
        try {
            Database.SaveResult resultInvalid = Database.insert(conProg);
            System.assertEquals(false, resultInvalid.isSuccess(), 'SaveResult was no success');
        } catch (Exception e) {
            system.debug(e.getMessage());
        }
        
        Test.stopTest();
    }
}