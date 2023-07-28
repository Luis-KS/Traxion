public without sharing class CustomForgotFormController {
    @AuraEnabled
    public static String forgotPassowrd(String username) {
        try {
            User user = [SELECT Id, Username FROM User WHERE Username = :username];
            if (Site.isValidUsername(user.Username)) {
                Site.forgotPassword(user.Username);
                ApexPages.PageReference pageRef = new PageReference(System.Label.Community_Url);
                return pageRef.getURL() + '/s/login/CheckPasswordResetEmail';
            }
            throw new CalloutException();
        } catch (Exception e) {
            system.debug('e.getMessageForgot' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
}