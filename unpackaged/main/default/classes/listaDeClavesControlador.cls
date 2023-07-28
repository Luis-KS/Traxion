public without sharing class listaDeClavesControlador {
    
    public class MyCustomException extends Exception {} 

    @AuraEnabled
    public static List<DPN_Line_Item__c> obtenerListaDeClaves(String Id, Boolean IsAvisoDePrevision, Boolean IsAvisoDeResponsable, Boolean IsLicenciaSanitaria){
        
        List<String> filtrarClavesPorFraccion = new List<String>();

        if(IsAvisoDeResponsable && IsLicenciaSanitaria){
            filtrarClavesPorFraccion.add('Controlado 2');
            filtrarClavesPorFraccion.add('Controlado 3');
        }if(IsAvisoDePrevision){
            filtrarClavesPorFraccion.add('Controlado 1');
        }

        List<DPN_Line_Item__c> dpnLineItems = [SELECT Id, product__r.Name, product__r.Partida_Presupuestal__c,product__r.Fraction__c, Activo__c
                                             FROM DPN_Line_Item__c 
                                             WHERE product__r.Fraction__c
                                             IN: filtrarClavesPorFraccion
                                             AND DPN__r.Account__c =: Id
                                             AND DPN__r.Estatus__c = 'Activo'];
        return dpnLineItems;
    }

    @AuraEnabled
    public static List<DPN_Line_Item__c> mostrarDpnLineItem(List<DPN_Line_Item__c> productList){
       
        try {
            if(productList.size() > 0){
                update productList;
                return  productList;
            }else{
                throw new MyCustomException('List cant be empty.');
            }
            
        } catch (MyCustomException error) {
            throw new MyCustomException('An error has ocurred.', error);
        }
    }

}