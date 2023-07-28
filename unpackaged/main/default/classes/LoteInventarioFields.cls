public with sharing class LoteInventarioFields {

    public static void updateInsertFechaModif( List<Lote_de_Inventario__c> loteInvList ){
        for( Lote_de_Inventario__c loteInv : loteInvList ){
            loteInv.Fecha_de_Modificaci_n__c = System.today();
            System.debug('loteInv.Fecha_de_Modificaci_n__c 1: ' + loteInv.Fecha_de_Modificaci_n__c);
        }
    }

    public static void updateInsertCveInventario( List<Lote_de_Inventario__c> loteInvList ){

        Set<Id> cveInvIdSet = New Set<Id>();
        Set<Id> cveInvIdFutureSet = New Set<Id>();
        Map<Id, Clave_de_Inventario__c> claveInvMap = new Map<Id, Clave_de_Inventario__c>();
        Map<Id, Clave_de_Inventario__c> claveInvToUpdMap = new Map<Id, Clave_de_Inventario__c>();

        for( Lote_de_Inventario__c loteInv : loteInvList ){
            cveInvIdSet.add(loteInv.Clave_de_Inventario__c);
        }

        claveInvMap = new Map<Id, Clave_de_Inventario__c>([SELECT Id, Estatus_de_Conteo__c, Fecha_Inicio_Conteo__c 
                                                           FROM Clave_de_Inventario__c 
                                                           WHERE ID IN :cveInvIdSet]); 

        for( Lote_de_Inventario__c loteInve : loteInvList ){
            System.debug( 'fecha inve : ' + loteInve.Fecha_Inicio_Inventario__c );
            if( loteInve.Estatus_Inventario__c != 'En Firma' || ( loteInve.Estatus_Inventario__c == 'En Firma' && loteInve.Fecha_Inicio_Inventario__c != System.Today() ) ){
                if( loteInve.Estatus_Conteo_Lote__c != null ){
                    Clave_de_Inventario__c cveInv = claveInvMap.get(loteInve.Clave_de_Inventario__c);

                    System.debug('cveInv.Estatus_de_Conteo__c: ' + cveInv.Estatus_de_Conteo__c);
                    
                    if(( cveInv.Estatus_de_Conteo__c == 'Iniciado' || cveInv.Estatus_de_Conteo__c == 'Contado' || cveInv.Estatus_de_Conteo__c == null ) && cveInv.Fecha_Inicio_Conteo__c != loteInve.Fecha_de_Modificaci_n__c ){
                        cveInv.Estatus_de_Conteo__c = cveInv.Estatus_de_Conteo__c != 'Iniciado' ? 'Iniciado' : cveInv.Estatus_de_Conteo__c;
                        cveInv.Fecha_Inicio_Conteo__c = loteInve.Fecha_de_Modificaci_n__c;
                        //cveInvToUpdateList.add(cveInv);
                        if ( !claveInvToUpdMap.containsKey( loteInve.Clave_de_Inventario__c )){
                            claveInvToUpdMap.put(loteInve.Clave_de_Inventario__c, cveInv);
                        }
                        System.debug('claveInvToUpdMap 1: ' + claveInvToUpdMap.values());
                    } else if( cveInv.Estatus_de_Conteo__c == 'Iniciado' && cveInv.Fecha_Inicio_Conteo__c == loteInve.Fecha_de_Modificaci_n__c ){
                        if ( !claveInvToUpdMap.containsKey( loteInve.Clave_de_Inventario__c )){
                            claveInvToUpdMap.put(loteInve.Clave_de_Inventario__c, cveInv);
                        }
                        System.debug('claveInvToUpdMap 2: ' + claveInvToUpdMap.values());
                    } else if( ( cveInv.Estatus_de_Conteo__c == 'Contado' ) && cveInv.Fecha_Inicio_Conteo__c == loteInve.Fecha_de_Modificaci_n__c ){
                        String errorMessage = 'No se puede iniciar un nuevo conteo el mismo dia. Estatus del Conteo: ' + cveInv.Estatus_de_Conteo__c ;
                        loteInve.addError(errorMessage);
                    }
                }
            } else {
                String errorMessage = 'No se puede iniciar un conteo para un Inventario que se encuentra En Firma';
                loteInve.addError(errorMessage);
            }
        }

        if(claveInvToUpdMap.values().size() > 0){
            System.debug('claveInvToUpdMap 3: ' + claveInvToUpdMap.values());
            update claveInvToUpdMap.values();
        }  
    }

    public static void deleteCurrentLote( List<Lote_de_Inventario__c> oldLoteList ){
        for( Lote_de_Inventario__c lotInventario : oldLoteList ){
            System.debug('Fecha: ' + lotInventario.CreatedDate.Date() + ' | ' + lotInventario.Fecha_de_Modificaci_n__c);
            System.debug('User: ' + UserInfo.getUserId()  + ' | ' + lotInventario.CreatedById);
            if( lotInventario.CreatedDate.Date() != System.Today() || lotInventario.Estatus_Inventario__c == 'En Firma' ){
                String errorMessage = 'Solo se permite borrar un Lote que haya sido creado el dia del conteo y que no se encuentre En Firma';
                lotInventario.addError(errorMessage);
            }
        }
    }
}