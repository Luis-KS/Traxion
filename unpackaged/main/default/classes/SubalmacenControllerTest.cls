@isTest
public class SubalmacenControllerTest {

    @IsTest
    static void GetSubalmacenByIdTest() {
        Subalmacen__c subalmacen = TestDataFactory.createSingleSubalmacen('100', 'GENERAL');

        Test.startTest();
        Subalmacen__c result = SubalmacenController.getSubalmacenById(subalmacen.Id);
        Test.stopTest();

        System.assertEquals(subalmacen.Id, result.Id);
        System.assertEquals(subalmacen.Numero_de_Subalmacen__c, result.Numero_de_Subalmacen__c);
        System.assertEquals(subalmacen.Name, result.Name);
    }
    
    @IsTest
    static void GetSubalmacenById_ExceptionTest() {
        Test.startTest();
        try {
            SubalmacenController.getSubalmacenById('InvalidId');
            System.assert(false, 'No se lanzó una excepción esperada');
        } catch (AuraHandledException e) {
            System.assertEquals('Script-thrown exception', e.getMessage());
        }
        Test.stopTest();
    }
}