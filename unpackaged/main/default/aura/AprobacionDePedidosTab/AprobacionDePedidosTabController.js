({
    

    handleAplicarFiltros : function(component, event, helper) { 
        const initializeValues = false;
        const filtrarPorFecha = false;
        const selectedTab = component.get('v.selectedTabId');
        helper.getDatosDeTabla(component, initializeValues, filtrarPorFecha, selectedTab);
    },

    handleClickedRow : function(component, event, helper) { 

        console.log("Inside handle clicked row");

        const selectedTab = component.get('v.selectedTabId');
        const row = event.getParam('row'); 
        const {Id = null} = row;
        if(!Id) return;

        console.log(selectedTab);
        console.log(row);
        console.log(Id);

        const action = component.get("c.getOrderByOLIId");
        action.setParams({
            "orderId": Id,
            'estatusNoOrdinario': selectedTab
        });
        action.setCallback(this, function(response) { 
            const state = response.getState();
            console.log(state);
            if (state === "SUCCESS") {
                const responseVal = response.getReturnValue();

                console.log(JSON.parse(JSON.stringify(responseVal)));

                helper.mostrarDetalles(component, responseVal, false);
                helper.showModal(component);
            } else{
                console.log(response.getError());
            }
        });
        $A.enqueueAction(action);
    }, 

    handleAbrirCerrarFiltros : function(component, event, helper) { 
        helper.mostrarOcultarFiltros(component); 
    },  

    limpiarFiltros : function(component, event, helper) {
        component.set('v.clavesSeleccionadas', []);
        component.set('v.umusSeleccionadas', []);
        component.set('v.estadosSeleccionados', []);
        component.set('v.pedidosSeleccionados', []);
        component.set('v.transportesSeleccionados', []);

        //call event to clear picklist values 
        var appEvent = $A.get("e.c:limpiarParametrosDeFiltros"); 
        appEvent.setParams({"clearValues" : true}); 
        appEvent.fire();

        helper.mostrarOcultarFiltros(component); 
    },

    obtenerClaves : function(component, event) { 
        var params = event.getParam('arguments');
        if(params){
            var clavesSeleccionadas = params.picklistDeClavesSeleccionadas; 
            clavesSeleccionadas != 'clearValues' ? component.set('v.clavesSeleccionadas', JSON.parse(JSON.stringify(clavesSeleccionadas))) : component.set('v.clavesSeleccionadas', []);
        }
    },

    obtenerUMUs : function(component, event) {  
        var params = event.getParam('arguments');
        if(params){
            var umusSeleccionadas = params.picklistDeUMUsSeleccionadas; 
            umusSeleccionadas != 'clearValues' ? component.set('v.umusSeleccionadas', JSON.parse(JSON.stringify(umusSeleccionadas))) : component.set('v.umusSeleccionadas', []);
        }
    },

    obtenerEstados : function(component, event) {  
        var params = event.getParam('arguments');
        if(params){
            var estadosSeleccionados = params.picklistDeEstadosSeleccionados; 
            estadosSeleccionados != 'clearValues' ? component.set('v.estadosSeleccionados', JSON.parse(JSON.stringify(estadosSeleccionados))) : component.set('v.estadosSeleccionados', []);
        }
    },

    obtenerPedidos : function(component, event) {  
        var params = event.getParam('arguments');
        if(params){
            var pedidosSeleccionados = params.picklistDePedidosSeleccionados; 
            pedidosSeleccionados != 'clearValues' ? component.set('v.pedidosSeleccionados', JSON.parse(JSON.stringify(pedidosSeleccionados))) : component.set('v.pedidosSeleccionados', []);
        }
    },

    killModalDetallesOrden : function(component){
        $A.util.toggleClass(component.find("detallesOrden"), 'slds-hide');
        // component.set('v.selectedRowInformation', {});
        // component.set('v.selectedRowItemsToApprove', []);
    },

})