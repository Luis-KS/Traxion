public class PedidoFields {
    private static Integer contadorDeUmus = 1;
    private static final String DEFAULT_ID_ORDINARIO = '000001';
    private static final String DEFAULT_ID_PROGRAMA = '00001';
    private static final String DEFAULT_ID_NO_ORDINARIO_HR_CMN = '-01';

    private static final List<String> UMUS_PRIORIDAD = new List<String>{
        'HR', 'CMN'
    };

    private static final List<String> TIPOS_DE_PEDIDO = new List<String>{
        'Ordinario', 'Extraordinario', 'Urgencia Médica', 'Soporte de Vida', 'Emergencia Sanitaria'
    };

    private static final List<String> TIPOS_DE_PEDIDO_PROGRAMA = new List<String>{
        'Programa', 'Urgencia Médica', 'Soporte de Vida', 'Emergencia Sanitaria'
    };
    
	public static void insertIdDePedido(List<Pedido__c> pedidoList){ 

        List<Pedido__c> lastPedidoIdList = [
            SELECT ID_de_Pedido__c, Es_Programa__c, Tipo_de_Pedido__c, UMU__c, UMU__r.Tipo_UMU__c
            FROM Pedido__c 
            WHERE Tipo_de_Pedido__c IN: TIPOS_DE_PEDIDO
                AND ID_de_Pedido__c != null
                AND Es_Programa__c = false
                AND Pedido_Original__c = null
            ORDER BY Name DESC 
            LIMIT 1
        ]; 

        String lastPedidoId = null;
        if (!lastPedidoIdList.isEmpty()){ 
            lastPedidoId = lastPedidoIdList[0].ID_de_Pedido__c;
        } 
        System.debug(lastPedidoId);

        List<Pedido__c> lastPedidoIdProgramaList = [
            SELECT ID_de_Pedido__c, Tipo_de_Pedido__c
            FROM Pedido__c 
            WHERE Tipo_de_Pedido__c IN: TIPOS_DE_PEDIDO_PROGRAMA
                AND ID_de_Pedido__c != null
                AND Es_Programa__c = true
                AND Pedido_Original__c = null
            ORDER BY Name DESC 
            LIMIT 1
        ];

        String lastPedidoIdPrograma = null;
        if (!lastPedidoIdProgramaList.isEmpty()){ 
            lastPedidoIdPrograma = lastPedidoIdProgramaList[0].ID_de_Pedido__c;
        } 
        System.debug(lastPedidoIdPrograma);
       

        Set<Id> umuIdSet = new Set<Id>();
        for (Pedido__c pedido : pedidoList){
            if (pedido.UMU__c != null){
                umuIdSet.add(pedido.UMU__c);
            }
        }
        System.debug(umuIdSet);
        Map<Id, Account> umuMap = new Map<Id, Account>([
            SELECT Id, Name, UMU__c
            FROM Account 
            WHERE Id IN: umuIdSet 
                AND UMU__c IN: UMUS_PRIORIDAD
        ]);
        System.debug(umuMap);

        if(Trigger.isBefore && Trigger.isInsert){
            contadorDeUmus = 1;
        } 

        for (Pedido__c pedido : pedidoList) { 
            if(String.isBlank(pedido.ID_de_Pedido__c)){
                if(!pedido.Es_Programa__c){
                    switch on pedido.Tipo_de_Pedido__c {
                        when 'Ordinario', 'Extraordinario', 'Urgencia Médica', 'Soporte de Vida', 'Emergencia Sanitaria'{ 
                            if(lastPedidoId != null){ 
                                String firstSixCharsStrId = lastPedidoId.substring(0, 6);
                                Integer newPedidoId = Integer.valueOf(firstSixCharsStrId) + 1;
                                String pedidoIdSuffix = '';
                                if(pedido.Tipo_de_Pedido__c != 'Ordinario' && pedido.UMU__c != null && umuMap.containsKey(pedido.UMU__c)){
                                    pedidoIdSuffix = DEFAULT_ID_NO_ORDINARIO_HR_CMN;
                                } 
                                pedido.ID_de_Pedido__c = String.valueOf(newPedidoId).leftPad(6, '0') + pedidoIdSuffix; 
                                lastPedidoId = String.valueOf(newPedidoId).leftPad(6, '0') + pedidoIdSuffix;
                            } else{ 
                                String pedidoIdSuffix = '';
                                if(pedido.Tipo_de_Pedido__c != 'Ordinario' && pedido.UMU__c != null && umuMap.containsKey(pedido.UMU__c)){
                                    pedidoIdSuffix = DEFAULT_ID_NO_ORDINARIO_HR_CMN;
                                } 
                                pedido.ID_de_Pedido__c = DEFAULT_ID_ORDINARIO + pedidoIdSuffix;  
                                lastPedidoId = DEFAULT_ID_ORDINARIO + pedidoIdSuffix;
                            } 
                        } 
                    }
                } else{
                    switch on pedido.Tipo_de_Pedido__c {
                        when 'Programa', 'Urgencia Médica', 'Soporte de Vida', 'Emergencia Sanitaria'{
                            if(lastPedidoIdPrograma != null){ 
                                String firstFiveCharsStrId = lastPedidoIdPrograma.substring(0, 5);
                                Integer newPedidoId = Integer.valueOf(firstFiveCharsStrId) + 1;
                                String pedidoIdSuffix = String.valueOf(contadorDeUmus).leftPad(4, '0');
                                String idString = String.valueOf(newPedidoId).leftPad(5, '0') + '-' + pedidoIdSuffix;
                                pedido.ID_de_Pedido__c = idString; 
                                contadorDeUmus ++;
                            } else{
                                String idString = DEFAULT_ID_PROGRAMA + '-' + String.valueOf(contadorDeUmus).leftPad(4, '0');
                                pedido.ID_de_Pedido__c = idString;
                                contadorDeUmus ++;
                            } 
                        }
                    }
                }
            } 
        }   
    }
    
}