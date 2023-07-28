public without sharing class CustomLoginFormController {

    @AuraEnabled
    public static String login(String username, String password) {
        
        try {
            String startUrl = System.Label.Community_Url;
            startUrl = startUrl.removeStartIgnoreCase('http://');
            startUrl = startUrl.removeStartIgnoreCase('https://');
            ApexPages.PageReference pageRef = Site.login(username, password, startUrl);
            
            if(pageRef != null) return pageRef.getUrl();
            throw new CalloutException();
        } catch (Exception e) {
            system.debug('e.getMessagelogin' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
}