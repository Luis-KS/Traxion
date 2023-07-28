@IsTest
public with sharing class DocumentWrapperTest {
    @IsTest
    static void testDocumentWrapper() {
        // Create test data
        DocumentWrapper.FileWrapper file1 = new DocumentWrapper.FileWrapper();
        // Set the necessary fields for file1
        
        DocumentWrapper.FileWrapper file2 = new DocumentWrapper.FileWrapper();
        // Set the necessary fields for file2
        
        List<DocumentWrapper.FileWrapper> files = new List<DocumentWrapper.FileWrapper>();
        files.add(file1);
        files.add(file2);
        
        DocumentWrapper documentWrapper = new DocumentWrapper();
        // Set the necessary fields for documentWrapper
        documentWrapper.name = 'Test Document';
        documentWrapper.description = 'Test Description';
        documentWrapper.files = files;
        
        // Perform assertions to verify the values
        System.assertEquals('Test Document', documentWrapper.name);
        System.assertEquals('Test Description', documentWrapper.description);
        
        List<DocumentWrapper.FileWrapper> actualFiles = documentWrapper.files;
        System.assertEquals(2, actualFiles.size());
        System.assertEquals(file1, actualFiles[0]);
        System.assertEquals(file2, actualFiles[1]);
    }
}