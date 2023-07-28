@isTest
public class CalendarioDeValidacionesControllerTest {
  @isTest
  public static void testGetCalendarioValidaciones() {
      Account acc = TestDataFactory.createSingleAccount('Test Account');
      DPN__c dpn = TestDataFactory.createSingleDPN(acc.Id);
      D_a_de_Pedido__c orderDate = TestDataFactory.createSingleOrderDate(dpn.Id);
      
      Test.startTest();
      List<D_a_de_Pedido__c> calendarioVal = CalendarioDeValidacionesController.getCalendarioValidaciones(acc.Id);
      Test.stopTest();
      
      System.assertEquals(1, calendarioVal.size());
      System.assertEquals(orderDate.Id, calendarioVal[0].Id);
  }
}