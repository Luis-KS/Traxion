@IsTest
public class CheckRecursionTest {

    @IsTest
    static void testRunOnce() {
        // Test the initial run
        Test.startTest();
        Boolean result1 = CheckRecursion.runOnce();
        System.assertEquals(true, result1); // Ensure the initial run returns true

        // Test subsequent runs
        Boolean result2 = CheckRecursion.runOnce();
        System.assertEquals(false, result2); // Ensure subsequent runs return false
        Test.stopTest();
    }

}