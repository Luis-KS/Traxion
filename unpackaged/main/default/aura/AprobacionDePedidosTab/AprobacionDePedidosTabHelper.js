({
    mostrarOcultarFiltros : function(component) {
        const x = document.getElementById("divFiltros");
        if (x.style.display === "none") {
            x.style.display = "block";
        } else {
            x.style.display = "none";
        } 

        const y = document.getElementById("divBtnMuestraFiltros");
        if (y.style.display === "none") {
            y.style.display = "block";
        } else {
            y.style.display = "none";
        } 
    }, 
    
    getDatosDeTabla : function(component, initializeValues, filtrarPorFecha, estatusNoOrdinario) {
        const datosTabla = this.getDatosTablaParameters(component, estatusNoOrdinario);
        const action = component.get("c.getFilteredOrders");
        action.setParams({ 
            jsonString : JSON.stringify(datosTabla)
        }); 
        action.setCallback(this, function(response) {
            const state = response.getState();
            // console.log("PRINTING STATEEEEEE");
            // console.log(state)
            if (state === "SUCCESS") {
                const responseVal = response.getReturnValue(); 
                // console.log(JSON.parse(JSON.stringify(responseVal)));
                this.mostrarDetalles(component, responseVal, true);
                if(!filtrarPorFecha){
                    this.mostrarOcultarFiltros(component); 
                } 
                this.showToast(component, '¡Filtrado Existoso!', 'success', 'Los datos se han actualizdo en la tabla');  
            } else{
                console.log(response.getError());
            }
        });
        $A.enqueueAction(action);
    },

    getDatosTablaParameters : function(component, estatusNoOrdinario) {
        const filtros = {
            clavesSeleccionadas : component.get('v.clavesSeleccionadas'),
            umusSeleccionadas : component.get('v.umusSeleccionadas'),
            estadosSeleccionados : component.get('v.estadosSeleccionados'),
            pedidosSeleccionados : component.get('v.pedidosSeleccionados'),
            transportesSeleccionados : component.get('v.transportesSeleccionados')
        }
        const clavesSeleccionadas = filtros.clavesSeleccionadas.map(clave => clave.Id);
        const estadosSeleccionados = filtros.estadosSeleccionados.map(estado => estado.Id);
        const pedidosSeleccionados = filtros.pedidosSeleccionados.map(pedido => pedido.Id);
        const transportesSeleccionados = filtros.transportesSeleccionados.map(transporte => transporte.Id);
        const umusSeleccionadas = filtros.umusSeleccionadas.map(umus => umus.Id);  
        const filterObj = component.get('v.filterObj') || {};
        const {fechaInicio = null, fechaFin = null} = filterObj;
        if(!fechaInicio || !fechaFin) return;
        const formattedFechaInicio = new Date(fechaInicio).toISOString().split('T')[0];
        const formattedFechaFin = new Date(fechaFin).toISOString().split('T')[0];

        return {
            estatusNoOrdinario,
            clavesSeleccionadas,
            umusSeleccionadas,
            estadosSeleccionados,
            pedidosSeleccionados,
            transportesSeleccionados,
            fechaInicio : formattedFechaInicio,
            fechaFin : formattedFechaFin
        }
    },

    mostrarDetalles : function(component, data, isInit) {

        console.log("INSIDE MOSTRAR DETALLES")
        console.log(JSON.parse(JSON.stringify(data)))

        if(!data) return;   
        const dataWithEstadoTemporal = this.getEstadoTemporalOrderLineItem(component, data);
        console.log(JSON.parse(JSON.stringify(dataWithEstadoTemporal)))

        if (isInit) {
            component.set('v.data', dataWithEstadoTemporal);
        } else {
            const selectedRowInformation = Array.isArray(dataWithEstadoTemporal)
                ? dataWithEstadoTemporal[0]
                : dataWithEstadoTemporal;
            const orderLineItems = selectedRowInformation.Order_Line_Items__r;
            if (!orderLineItems) {
                return;
            }
            component.set('v.selectedRowInformation', selectedRowInformation);
            component.set('v.selectedRowItemsToApprove', orderLineItems);
            this.getDocumentosRelacionados(component, selectedRowInformation);
        }
    },

    getEstadoTemporalOrderLineItem : function(component, data) {
        let oliSize = 0;
        let oliWithStatus = 0;
        // const tabSelectorStatus = component.get('v.tabSelectorStatus');

        for(let i=0; i < data.length; i++) {
            const order = data[i];
            const {Order_Line_Items__r, UMU__r = {}} = order; 
            const {Name = ''} = UMU__r; 
            order.UMUName = Name;
            if(!Order_Line_Items__r) continue;
            oliSize = Order_Line_Items__r.length;
            for(let j=0; j<Order_Line_Items__r.length; j++) {
                const status = Order_Line_Items__r[j];
                const {Estatus_Aprobaci_n__c} = status; 
                switch (Estatus_Aprobaci_n__c) {
                    case 'Pendiente': 
                        oliWithStatus -= 1;
                        delete status.EstadoTemporal;  
                        continue;
                    case 'Aprobado':
                        oliWithStatus += 1;
                        status.EstadoTemporal = {
                            label : 'Aprobado',
                            class : 'slds-theme_success slds-align_absolute-center',
                            icon : 'utility:success',
                            // value : tabSelectorStatus.aprobado
                        }
                        continue;
                    case 'Modificado':
                        oliWithStatus += 1;
                        status.EstadoTemporal = {
                            label : 'Modificado',
                            class : 'slds-badge_inverse slds-align_absolute-center',
                            icon : 'utility:change_record_type',
                            // value : true
                        }  
                        continue;
                    case 'Rechazado':
                        oliWithStatus += 1;
                        status.EstadoTemporal = {
                            label : 'Rechazado',
                            class : 'slds-theme_error slds-align_absolute-center',
                            icon : 'utility:error',
                            // value : tabSelectorStatus.rechazado
                        }
                        continue;
                    default:
                        console.log(`Other`);
                        continue;
                } 
            }
        }
        return data;
    },

    getDocumentosRelacionados : function(component, data) {
        $A.createComponent(
            "c:filesContainer",
            {orderId : data.Id},
            function(newCmp) {
                if (component.isValid()) { 
                    component.set("v.body", newCmp);
                }
            }
        );
    },

    showModal : function(component) {
        $A.util.toggleClass(component.find("detallesOrden"), 'slds-hide');
        $('#detallesOrden').keyup(function(event){
            if (event.keyCode == 27){
                // Close the modal/menu
                $A.util.toggleClass(component.find("detallesOrden"), 'slds-hide');
            }
        });
    },
})