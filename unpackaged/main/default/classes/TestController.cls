public with sharing class TestController {
    
    @AuraEnabled(cacheable=true)
    public static List<Account> getUMUOptions(){


    //  List<SelectOption> options = new List<SelectOption>();
     List<Account> umus = [Select Id, Name from Account WITH SECURITY_ENFORCED ] ;
    //  for (UMU__c umSelector : umus) {
    //      options.add(new SelectOption(umSelector.Id, umSelector.Name));
         
    //  }
     return umus;


    }
}