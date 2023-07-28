public with sharing class ClaveInventarioFields {
    public static void updateEstatusConteo(List<Clave_de_Inventario__c> claveInvList, Map<Id, Clave_de_Inventario__c> oldClaveMap){
        
        Set<Id> cveInvIdSet = New Set<Id>();
        Set<Id> invToUpdateSet = New Set<Id>();

        Map<Id, Clave_de_Inventario__c> cveInvToLoteInvMap = New Map<Id, Clave_de_Inventario__c>(); 
        Map<Id, Date> cveInvFechaMap = New Map<Id, Date>();
        Map<Id, Decimal> cveInvNumLotesMap = New Map<Id, Decimal>();

        List<Lote_de_Inventario__c> loteInvList = New List<Lote_de_Inventario__c>();
        List<Inventario__c> invToUpdList = New List<Inventario__c>();

        for( Clave_de_Inventario__c claveInv : claveInvList ){
            System.debug('claveInv.InvnetarioStatus- ' + claveInv.Inventario__r.Estatus__c);
            if( claveInv.Estatus_de_Conteo__c == 'Contado' && claveInv.Estatus_de_Conteo__c != oldClaveMap.get(claveInv.Id).Estatus_de_Conteo__c ){
                cveInvIdSet.add( claveInv.Id );
                cveInvFechaMap.put( claveInv.Id, claveInv.Fecha_Inicio_Conteo__c );
                System.debug('cveInvFechaMap- ' + cveInvFechaMap);
            }
        }

        if ( cveInvIdSet.size() > 0 ){
            cveInvToLoteInvMap = new  Map<Id, Clave_de_Inventario__c>([ SELECT Fecha_Inicio_Conteo__c, (SELECT Clave_de_Inventario__c, Fecha_de_Modificaci_n__c, Estatus_Conteo_Lote__c FROM Lotes_de_Inventario__r)
                                                                        FROM Clave_de_Inventario__c
                                                                        WHERE Id IN : cveInvIdSet ]);

            for(Clave_de_Inventario__c ci:cveInvToLoteInvMap.values()){          
                for(Lote_de_Inventario__c li : ci.Lotes_de_Inventario__r){                  
                    if(ci.id == li.Clave_de_Inventario__c && cveInvFechaMap.get(ci.Id) == li.Fecha_de_Modificaci_n__c ){
                        loteInvList.add(li);
                    }
                }
                cveInvNumLotesMap.put(ci.id, loteInvList.size());
                System.debug('loteInvList- ' + loteInvList);
            }
            System.debug('cveInvNumLotesMap- ' + cveInvNumLotesMap);
            for( Clave_de_Inventario__c claInv : claveInvList ){
                for( Lote_de_Inventario__c loteInv : loteInvList ){
                    if( loteInv.Estatus_Conteo_Lote__c != 'Contado' || claInv.Numero_Total_de_Lotes__c != loteInvList.size() ){ 
                        String errorMessage = 'Aun tiene Lotes sin actualizar o en estatus diferente a Contado el día de hoy';
                        claInv.addError(errorMessage);
                    }
                }
            }
        }
        
        if( loteInvList.size() > 0 ) {   
            for( Clave_de_Inventario__c claveInv : claveInvList ){
                System.debug('claveInv.Numero_Total_de_Lotes__c ' + claveInv.Numero_Total_de_Lotes__c);
                System.debug('cveInvNumLotesMap.get(claveInv.Id) ' + cveInvNumLotesMap.get(claveInv.Id));
                if( claveInv.Numero_Total_de_Lotes__c == cveInvNumLotesMap.get(claveInv.Id) ){
                    System.debug('Result: ' + claveInv.Numero_Total_de_Lotes__c +' | '+ cveInvNumLotesMap.get(claveInv.Id));
                    //claveInv.Estatus_de_Conteo__c = 'Contado';
                    invToUpdateSet.add(claveInv.Inventario__c);
                }
            }
        }  
        
        for(Inventario__c inv : [SELECT Estatus__c FROM Inventario__c WHERE Id IN : invToUpdateSet] ){
            inv.Estatus__c = 'Registrado';
            inv.Fecha_Inicio__c = System.Today();
            invToUpdList.add(inv);
        }
    
        if(invToUpdList.size() > 0){
            update invToUpdList;
        } 
        
    }

    public static void clearEstatusLote(List<Clave_de_Inventario__c> claveInvList, Map<Id, Clave_de_Inventario__c> oldClaveMap){
        
        Set<Id> cveInvIdSet = New Set<Id>();
        Set<Id> invToUpdateSet = New Set<Id>();

        List<Lote_de_Inventario__c> loteClearStList = New List<Lote_de_Inventario__c>();

        for( Clave_de_Inventario__c claveInv : claveInvList ){
            System.debug('H0000: ' + claveInv.Inventario__r.Estatus__c);
            if( claveInv.Estatus_de_Conteo__c == 'Contado' && claveInv.Estatus_de_Conteo__c != oldClaveMap.get(claveInv.Id).Estatus_de_Conteo__c ){
                cveInvIdSet.add( claveInv.Id );
            }
        }

        if ( cveInvIdSet.size() > 0 ){
            for(List<Lote_de_Inventario__c> loteList : [SELECT Clave_de_Inventario__c, Estatus_Conteo_Lote__c 
                                                        FROM Lote_de_Inventario__c
                                                        WHERE Clave_de_Inventario__c in : cveInvIdSet]){  
                for( Lote_de_Inventario__c lote : loteList ){
                    lote.Estatus_Conteo_Lote__c = null;
                    loteClearStList.add(lote);
                }                
            }
        }
    
        if(loteClearStList.size() > 0){
            update loteClearStList;
        } 
        
    }
}