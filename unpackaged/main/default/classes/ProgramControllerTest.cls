@isTest
public class ProgramControllerTest {

    @isTest
    static void testGetProgramById() {
        Programas__c program = TestDataFactory.createSingleProgram(
            'Programa de Prueba', 'S035', 'Ordinario');
        
        Test.startTest();
        // Caso 1: ID válido
        Programas__c result = ProgramController.getProgramById(program.Id);
        System.assertEquals(program.Programa_ID__c, result.Programa_ID__c);
        System.assertEquals(program.Name, result.Name);
        System.assertEquals(program.Inventario__c, result.Inventario__c);
        
        // Caso 2: ID inválido
        try {
            result = ProgramController.getProgramById('invalid');
            System.assert(false, 'Se esperaba una excepción pero no se generó');
        } catch (AuraHandledException e) {
            System.assertEquals('Script-thrown exception', e.getMessage(), 'El mensaje de error no coincide');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetProgramsByContact() {
        Test.startTest();
        List<Programas__c> result = ProgramController.getProgramsByContact();
        Test.stopTest();
        
        System.assertEquals(0, result.size());
    }
}