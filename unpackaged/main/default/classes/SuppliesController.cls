public without sharing class SuppliesController {
    @AuraEnabled(cacheable=true)
    public static List<Product2> getSupplies(){
        List<Product2> suppliesList = new List<Product2>();
        List<Id> programsIdList = new List<Id>();
        try {
            suppliesList = [SELECT Id, Product_Code_ID__c, Name, Partida_Presupuestal__c, 
                            BP_Product_Code__c, Programa__c, Sicora_Classification__c, 
                            Simple_Classification__c, Subalmacen__c, Package_Capacity__c,
                            Description__c, Fraction__c, Enable__c
                            FROM Product2 
                            WHERE Programa__c IN :programsIdList
                            LIMIT 50];
            return suppliesList;
        } catch (Exception e) {
            System.debug('Query error: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Product2 getSuppliesByCode(String productCode){
        try {
            return [SELECT Id, Product_Code_ID__c, Name, Partida_Presupuestal__c,
                            BP_Product_Code__c, Programa__c, Sicora_Classification__c,
                            Simple_Classification__c, Subalmacen__c, Package_Capacity__c,
                            Description__c, Fraction__c, Enable__c
                            FROM Product2
                            WHERE Product_Code_ID__c = :productCode
                            LIMIT 1];
        } catch (Exception e) {
            System.debug('Query error: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Product2> getSuppliesBySearch(String search, String programId) {

        List<Product2> suppliesList = new List<Product2>();
        String searchTerm = '%' + String.escapeSingleQuotes(search.trim()) + '%';

        try {
            suppliesList = [SELECT Id, Product_Code_ID__c, Name, Partida_Presupuestal__c,
                            BP_Product_Code__c, Programa__c, Sicora_Classification__c,
                            Simple_Classification__c, Subalmacen__c, Package_Capacity__c,
                            Description__c, Fraction__c, Enable__c
                            FROM Product2
                            WHERE Programa__c = :programId
                            AND (Name LIKE :searchTerm
                            OR Product_Code_ID__c LIKE :searchTerm)];
            return suppliesList;
        } catch (Exception e) {
            System.debug('Query error: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Product2> getSuppliesByProgram(String programId) {

        List<Product2> suppliesList = new List<Product2>();
        try {
            suppliesList = [SELECT Id, Product_Code_ID__c, Name, Partida_Presupuestal__c,
                            BP_Product_Code__c, Programa__r.Programa_ID__c, Sicora_Classification__c,
                            Simple_Classification__c, Subalmacen__c, Package_Capacity__c,
                            Description__c, Fraction__c, Enable__c
                            FROM Product2
                            WHERE Programa__r.Programa_ID__c = :programId];
            return suppliesList;
        } catch (Exception e) {
            System.debug('Query error: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class ProductsWrapper {
        public Integer pageSize {get;set;}
        public Integer pageNumber {get;set;}
        public Integer totalRecords {get;set;}
        public Integer recordStart {get;set;}
        public Integer recordEnd {get;set;}
        public List<Product2> products {get;set;}
    }

    @AuraEnabled(cacheable=true)
    public static String getSuppliesBySearch2(String search, String programId, Integer pageSize, Integer pageNumber) {
        String suppliesList = '';
        String searchTerm = '%' + String.escapeSingleQuotes(search.trim()) + '%';
                                                        
        //Offset for SOQL
        Integer offset = (pageNumber - 1) * pageSize;
         
        //Total Records
        Integer totalRecords = [SELECT COUNT() FROM Product2
                            	WHERE Programa__c = :programId];
        Integer recordEnd = pageSize * pageNumber;
                                                        
        ProductsWrapper objDT =  new ProductsWrapper();  
        objDT.pageSize = pageSize;
        objDT.pageNumber = pageNumber;
        objDT.recordStart = offset + 1;
        objDT.recordEnd = totalRecords >= recordEnd ? recordEnd : totalRecords;
        objDT.totalRecords = totalRecords;
        objDT.products = [SELECT Id, Product_Code_ID__c, Name, Partida_Presupuestal__c,
                          BP_Product_Code__c, Programa__c, Sicora_Classification__c,
                          Simple_Classification__c, Subalmacen__c, Package_Capacity__c,
                          Description__c, Fraction__c, Enable__c
                          FROM Product2
                          WHERE Programa__c = :programId
                          AND (Name LIKE :searchTerm
                          OR Product_Code_ID__c LIKE :searchTerm)
                          LIMIT :pageSize OFFSET :offset];
        suppliesList = JSON.serialize(objDT);                       
        try {
            return suppliesList;
        } catch (Exception e) {
            System.debug('Query error: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
}