public with sharing class UmuController {
    
    @AuraEnabled(cacheable=true)
    public static List<Account> getUmu(String userId){
        List<Account> userRelatedAccountList = new List<Account>();
        try {
            userRelatedAccountList = UserContactClass.getAccountListFromUser();
            return userRelatedAccountList;
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            return userRelatedAccountList;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Order__c> getUmuOrders(String umuName) {
        try {
            List<Order__c> ordList = [
                SELECT
                Id,
                Fecha_Limite_de_Entrega__c,
                Tipo_de_Pedido__c,
                Total_de_Piezas__c,
                UMU__r.Name,
                Entrega__r.Estado__c
                FROM Order__c
                WHERE UMU__r.Name = :umuName 
                AND Entrega__r.Estado__c = 'Asignado'
                // WITH SECURITY_ENFORCED
            ];
            
            return ordList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Account> getAllUmus(){
        List<Account> accountsList = new List<Account>();
        try {
            return [SELECT Id, Name, Tipo_UMU__c, Delegaci_n__c
                    FROM ACCOUNT
                    WHERE UMU_Cerrada__c = false];
        } catch (Exception e) {
            System.debug('Query error: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Account> getUmuByType(List<String> umuTypes){
        List<Account> accountsList = new List<Account>();
        try {
            return [SELECT Id, Name, Tipo_UMU__c, Delegaci_n__c
                    FROM ACCOUNT
                    WHERE Tipo_UMU__c IN :umuTypes
                    AND UMU_Cerrada__c = false];
        } catch (Exception e) {
            System.debug('Query error: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Account> getUmuByTypeAndDelegation(List<String> umuTypes, List<String> umuDelegations){
        List<Account> accountsList = new List<Account>();
        try {
            return [SELECT Id, Name, Tipo_UMU__c, Delegaci_n__c
                    FROM ACCOUNT
                    WHERE Tipo_UMU__c IN :umuTypes
                    AND Delegaci_n__c IN :umuDelegations
                    AND UMU_Cerrada__c = false];
        } catch (Exception e) {
            System.debug('Query error: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Account> getUmuByDelegation(List<String> umuDelegations){
        List<Account> accountsList = new List<Account>();
        try {
            return [SELECT Id, Name, Tipo_UMU__c, Delegaci_n__c
                    FROM ACCOUNT
                    WHERE Delegaci_n__c IN :umuDelegations
                    AND UMU_Cerrada__c = false];
        } catch (Exception e) {
            System.debug('Query error: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Account> getUmuDelegationByType(List<String> umuTypes){
        List<Account> accountsList = new List<Account>();
        try {
            return [SELECT Id, Name, Tipo_UMU__c, Delegaci_n__c
                    FROM ACCOUNT
                    WHERE Tipo_UMU__c IN :umuTypes
                    AND UMU_Cerrada__c = false
                    ORDER BY Delegaci_n__c ASC];
        } catch (Exception e) {
            System.debug('Query error: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Account> getUmusById(List<String> umuIds){
        try {
            return [SELECT Id, Name, Tipo_UMU__c, Delegaci_n__c, Clave_Presupuestal__c, UMU__c
                    FROM ACCOUNT
                    WHERE Id IN :umuIds
                    AND UMU_Cerrada__c = false
                    ORDER BY Delegaci_n__c ASC];
        } catch (Exception e) {
            System.debug('Query error: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<SelectOptionWrapper> getUmuMultiSelectOptions(String objectName, String fieldName) {
        List<SelectOptionWrapper> options = new List<SelectOptionWrapper>();
        Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe()
            .get(objectName).getDescribe().fields.getMap().get(fieldName).getDescribe();
        
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        
        for(Schema.PicklistEntry entry : picklistValues) {
            options.add(new SelectOptionWrapper(entry.getValue(), entry.getLabel()));
        }
        return options;
    }
    
    public class SelectOptionWrapper {
        @AuraEnabled
        public String value { get; set; }
        @AuraEnabled
        public String label { get; set; }
        
        public SelectOptionWrapper(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }
    
    //   @AuraEnabled(cacheable=true)
    //   public static List<AccountContactRelation> getUmu(String userId) {
    //     try {
    //       List<Id> accId = new List<Id>();
    //       List<User> activeUser = [
    //         SELECT ContactId
    //         FROM User
    //         WHERE Id = :userId
    //         WITH SECURITY_ENFORCED
    //       ];
    
    //       Id contactId = activeUser[0].ContactId;
    //       List<Contact> conList = [
    //         SELECT AccountId
    //         FROM Contact
    //         WHERE id = :contactId
    //         WITH SECURITY_ENFORCED
    //       ];
    
    //       for (Contact con : conList) {
    //         accId.add(con.AccountId);
    //       }
    
    //       return [
    //         SELECT AccountId, Account.Name
    //         FROM AccountContactRelation
    //         WHERE ContactId = :contactId
    //         WITH SECURITY_ENFORCED
    //       ];
    //     } catch (Exception e) {
    //       throw new AuraHandledException(e.getMessage());
    //     }
    //   }
}