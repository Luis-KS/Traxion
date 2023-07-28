({
    handleUpdateDetails : function(component, event, helper) {
        const data = event.getParam('data');
        const parsedData = JSON.parse(data); 
        component.set('v.data', parsedData); 
        
        let cantidadTotalPiezas = 0;
        let costoTotalPiezas = 0;

        // TODO: Obtener las piezas certificadas
        let cantidadTotalPiezasCertificadas = 0;
        let costoTotalPiezasCertificadas = 0;

        let piezasVerificandoDisponibilidad = 0;
        let costoVerificandoDisponibilidad = 0;

        let piezasPreparandoEnvio = 0;
        let costoPreparandoEnvio = 0;

        let piezasEnviadas = 0;
        let costoEnviadas = 0;

        let piezasEnFirma = 0;
        let costoEnFirma = 0;


        parsedData.forEach(function(pedido) {

            const {Total_de_Piezas__c = 0, Total_de_Claves__c=0} = pedido;
            cantidadTotalPiezas += Total_de_Piezas__c; 

            // cantidadTotalPiezas += order.Total_de_Piezas__c ? order.Total_de_Piezas__c : 0;
            // costoTotalPiezas += order.Costo_Total__c ? order.Costo_Total__c : 0;

            // // TODO: Obtener las piezas certificadas 
            // const orderLineItems = order.Order_Line_Items__r;
            // if(orderLineItems){
            //     orderLineItems.forEach(function(oli) {
            //         switch (oli.Estatus__c) {
            //             case 'Verificando Disponibilidad':
            //                 piezasVerificandoDisponibilidad += oli.Cantidad_Solicitada__c;
            //                 costoVerificandoDisponibilidad += 25;
            //                 break;
            //             case 'Preparando Envío':
            //                 piezasPreparandoEnvío += oli.Cantidad_Aprobada__c;
            //                 costoPreparandoEnvío = 15;
            //                 break;
            //             case 'Enviado':
            //                 piezasEnviadas += oli.Cantidad_Aprobada__c;
            //                 costoEnviadas = 10;
            //                 break;
            //             case 'En Firma':
            //                 piezasEnFirma += oli.Cantidad_Aprobada__c;
            //                 costoEnFirma = 10;
            //                 break;
            //             default:
            //                 break;
            //           } 
            //     }); 
            // }  
        });  
        component.set('v.cantidadTotalPiezas', `${cantidadTotalPiezas} Piezas`);
        component.set('v.costoTotalPiezas', `$ ${costoTotalPiezas}`);  

        // TODO: Obtener las piezas certificadas
        component.set('v.cantidadTotalPiezasCertificadas', `${cantidadTotalPiezas} Piezas`);
        component.set('v.costoTotalPiezasCertificadas', `$ ${costoTotalPiezas}`);  

        const catDisponibilidad = {
            icon : 'action:new_task',
            titulo : 'Verificando Disponibilidad',
            piezas : `Piezas: ${piezasVerificandoDisponibilidad}`,
            costo : `Costo: ${costoVerificandoDisponibilidad}`
        };

        const catPreparando = {
            icon : 'action:new_note',
            titulo : 'Preparando Envío',
            piezas : `Piezas: ${piezasPreparandoEnvio}`,
            costo : `Costo: ${costoPreparandoEnvio}`
        };

        const catEnviado = {
            icon : 'action:update_status',
            titulo : 'Enviado',
            piezas : `Piezas: ${piezasEnviadas}`,
            costo : `Costo: ${costoEnviadas}`
        };

        const catFirma = {
            icon : 'action:submit_for_approval',
            titulo : 'En Firma',
            piezas : `Piezas: ${piezasEnFirma}`,
            costo : `Costo: ${costoEnFirma}`
        };  
        component.set('v.detallesPorCategoria', [catDisponibilidad, catPreparando, catEnviado, catFirma]); 
    }
})