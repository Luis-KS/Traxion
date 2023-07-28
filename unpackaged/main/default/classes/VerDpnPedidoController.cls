public with sharing class VerDpnPedidoController {
  

    @AuraEnabled(cacheable=true)
    public static List<DPN_Line_Item__c> getDpn(String accId){
        try {
            String estado = 'Activo';
            List<DPN_Line_Item__c> dpns = [SELECT DPN__r.Clave_Presupuestal__c, Product__r.Name, DPN__r.Delegacion__c, DPN__r.Tipo_de_Umu__c
            FROM DPN_Line_Item__c 
            WHERE DPN__r.Account__c =: accId and DPN__r.Estatus__c=: estado
            WITH SECURITY_ENFORCED];

            return dpns;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}