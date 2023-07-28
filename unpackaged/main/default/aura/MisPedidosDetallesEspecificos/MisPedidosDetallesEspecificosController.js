({
    handleUpdateDetails : function(component, event, helper) {  
        const data = event.getParam('data');
        if (!data) return; 

        component.set('v.isLoading', true);

        helper.getAllDetails(component, event, data);
    },

    handleClick : function(component) {
        $A.util.toggleClass(component.find("detallesOrden"), 'slds-hide');
        $('#detallesOrden').keyup(function(event){
            if (event.keyCode == 27){
                // Close the modal/menu
                $A.util.toggleClass(component.find("detallesOrden"), 'slds-hide');
            }
        });
    },

    killDetallesModal : function(component, event, helper){
        component.set('v.displayDatosTransporte', false);
        component.set('v.displayFirmarRecibirEntrega', false);
        component.set('v.displayFirmarLlegadaTransporte', true); 
        $A.util.toggleClass(component.find("detallesOrden"), 'slds-hide');
    },

    handleDisplayLlegada : function(component, event, helper){ 

        const title = event.getSource().get('v.title');  
        const selectedOliObj = event.getSource().get('v.value'); 
        const filteredOrderLineItemDetails = component.get('v.filteredOrderLineItemDetails'); 
        const subData = selectedOliObj.datosDelSubalmacen.buttonDisplayment;

        if(title === 'firmaMain'){ 
            subData.displayFirmarLlegadaTransporte = false; 
            subData.displayDatosTransporte = true;
            subData.displayFirmarRecibirEntrega = false; 
        } else if(title === 'firmaCancelar'){
            subData.displayFirmarLlegadaTransporte = true; 
            subData.displayDatosTransporte = false;
            subData.displayFirmarRecibirEntrega = false; 
        } else if(title === 'firmaContinuar'){
            subData.displayFirmarLlegadaTransporte = false; 
            subData.displayDatosTransporte = false;
            subData.displayFirmarRecibirEntrega = true;  
        } 

        const updatedOrderLineItemDetails = filteredOrderLineItemDetails.map(item => {
            if (item.datoDeOrderId === selectedOliObj.datoDeOrderId) { 
                Object.assign(item, selectedOliObj.datosDelSubalmacen.buttonDisplayment);
            }
            return item;
        });
        component.set('v.filteredOrderLineItemDetails', updatedOrderLineItemDetails);
    },

    handleCertificarEntrega : function(component, event, helper){
        component.set('v.isModalLoading', true);    
        
        const selectedOLI = event.getSource().get('v.value');   
        helper.certificarEntrega(component, selectedOLI);  
    },

    handleRechazarEntrega : function(component, event, helper){
        component.set("v.isModalLoading", true);

        const selectedOLI = event.getSource().get('v.value');   
        helper.rechazarEntrega(component, selectedOLI); 
    },

    handleReenviarOrden : function(component, event, helper){
        component.set("v.isModalLoading", true);

        const orderId = event.getSource().get('v.value');  
        helper.reenviarOrden(component, orderId); 
    }  
})