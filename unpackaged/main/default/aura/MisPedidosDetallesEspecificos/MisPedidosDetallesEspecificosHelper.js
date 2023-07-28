({
    getAllDetails : function(component, event, data) {  
        // Set data 
        const parsedData = JSON.parse(data); 
        component.set('v.data', parsedData);   

        // Set labels de detalles especificos 
        this.setLabelsDetallesEspecificos(component, event, parsedData); 

        // Set detalles de pedido 
        this.setDetallesDePedido(component, event, parsedData); 

        // Get evidencia de transporte 
        this.getEvidenciaTransporte(component, event, parsedData).then(
            $A.getCallback(ordenesTransporte => {  
                // Get Order Line Item details
                this.getOrderLineItem(component, event, parsedData, ordenesTransporte);    
            })
        ).catch(
            $A.getCallback(errors => {
                if (errors && errors.length > 0) {
                    component.set("v.isLoading", false);
                    $A.get("e.force:showToast").setParams({
                        message: errors[0].message != null ? errors[0].message : errors[0],
                        type: "error"
                    }).fire();
                }
            })
        );
    },

    getEvidenciaTransporte : function(component, event, data) {
        return new Promise(
            $A.getCallback((resolve, reject) => { 
                const { Ordenes__r = [] } = data; 
                const orderIdList = Ordenes__r.map(ord => ord.Id);
                console.log(JSON.parse(JSON.stringify(orderIdList)));  
                if(orderIdList.length === 0){ return; }

                const action = component.get("c.getOrderEvidence");
                action.setParams({
                    orderIdList
                });
                action.setCallback(this, function(response) { 
                    const state = response.getState();
                    console.log(state);
                    if (state === "SUCCESS") {
                        const responseVal = response.getReturnValue();
                        return resolve(responseVal); 
                    } else{
                        return reject(response.getError());
                    }
                });
                $A.enqueueAction(action);
            })
        );
    },

    setLabelsDetallesEspecificos : function(component, event, data) { 
        const {ID_de_Pedido__c = null, UMU__r = {}} = data;
        const { Name = null, Estado__c = null } = UMU__r;
        const nombreDireccion = ID_de_Pedido__c && Estado__c ? `${ID_de_Pedido__c} | ${UMU__r.Estado__c}` : ID_de_Pedido__c; 
        component.set('v.nombreDireccion', nombreDireccion); 
        component.set('v.nombreUMU', Name); 
    },

    setDetallesDePedido : function(component, event, data) {
        const {Total_de_Piezas__c = 0, Costo_Total__c = 0, FechaCreacion = null, FechaMaxEntrega = null, UMU__r = {}} = data;
        const {Clave_Presupuestal__c = null, Delegacion__c = null} = UMU__r

        const piezasSolicitadas = {
            mostrar : Total_de_Piezas__c,
            titulo : 'Piezas Solicitadas:',
            valor : Total_de_Piezas__c
        }; 
        const piezasPrecio = {
            mostrar : Costo_Total__c,
            titulo : 'Precio:',
            valor : Costo_Total__c
        }; 
        const fechaCreacion = {
            mostrar : FechaCreacion,
            titulo : 'Fecha de Creación:',
            valor : FechaCreacion
        }; 
        const fechaMaxEntrega = {
            mostrar : FechaMaxEntrega,
            titulo : 'Fecha Máx Entrega:',
            valor : FechaMaxEntrega
        }; 
        const destino = {
            mostrar : Clave_Presupuestal__c && Delegacion__c,
            titulo : 'Destino:',
            valor : `${Clave_Presupuestal__c} / ${Delegacion__c}`
        }; 
        const detallesDePedido = [piezasSolicitadas, piezasPrecio, fechaCreacion, fechaMaxEntrega, destino];
        component.set('v.detallesDePedido', detallesDePedido); 
    },

    getOrderLineItem : function(component, event, data, ordenTransporte) {  

        console.log("Inside get order line item");
        console.log(JSON.parse(JSON.stringify(data)));

        const self = this;
        const {Ordenes__r = []} = data; 
        const orderIdList = Ordenes__r.map( ord => ord.Id); 
        if(orderIdList.length === 0) return; 

        component.set('v.pedidoId', data.Id);

        console.log("flag2")
        console.log(orderIdList);

        const action = component.get("c.getFilteredOrdersAndOlis");
        action.setParams({
            orderIdList
        });
        action.setCallback(this, function(response) { 
            const state = response.getState();
            console.log(state);
            if (state === "SUCCESS") {
                const statusSet = new Set();
                const allOrderLineItemDetails = [];
                const filteredOrderLineItemDetails = [];
                const responseVal = response.getReturnValue();

                console.log(JSON.parse(JSON.stringify(responseVal)));

                responseVal.forEach(function(ord) {  
                    const {
                        Id = null, Order_Line_Items__r = [], Order_Number__c = null, Seguimiento__c = null, 
                        Estatus__c = null, Firmado_Por__r = null, Certificado_Por__r = null, Pedido__c = null
                    } = ord;  
                    const firmadoPor = Firmado_Por__r ? Firmado_Por__r.Name : null;
                    const certificadoPor = Certificado_Por__r ? Certificado_Por__r.Name : null;

                    if(!Order_Number__c) return;

                    statusSet.add(Estatus__c);

                    console.log("flaga");

                    const subalmacenName = self.getSubalmacenName(Order_Number__c);

                    console.log("flagb");

                    const orderLineItemDetails = self.getOrderLineItemDetails(Order_Line_Items__r);
                    allOrderLineItemDetails.push(...orderLineItemDetails);

                    console.log("flagc");

                    const seguimientoObj = self.getArrayDeSeguimiento(Seguimiento__c, firmadoPor, certificadoPor); 

                    console.log("flagd");

                    const {arrayDeSeguimiento = [], formattedArrivalDateTime = null} = seguimientoObj;  
                    arrayDeSeguimiento.sort((a, b) => a.value - b.value);

                    console.log("flage");

                    const evidenciaTransporte = ordenTransporte.hasOwnProperty(ord.Id) ? ordenTransporte[ord.Id].Id : null;

                    console.log("flagf");

                    const subalmacenObj = {
                        subalmacenName,
                        evidenciaTransporte,
                        fechaDeLlegadaTransporte : formattedArrivalDateTime, 
                        buttonDisplayment : {
                            displayFirmarLlegadaTransporte : Estatus__c === 'En Firma' || Estatus__c === 'En Firma Parcial',
                            displayDatosTransporte : false,
                            displayFirmarRecibirEntrega : false
                        } 
                    }   

                    filteredOrderLineItemDetails.push({  
                        datoDeOrderId : Id,
                        datoError : Estatus__c === 'Error',
                        datosDeOLI : orderLineItemDetails,
                        datosDelSubalmacen : subalmacenObj,
                        datosDeSeguimiento : arrayDeSeguimiento
                    });
                }); 

                filteredOrderLineItemDetails.sort((a, b) => {
                    const subalmacenA = parseInt(a.datosDelSubalmacen.subalmacenName.split("-")[0]);
                    const subalmacenB = parseInt(b.datosDelSubalmacen.subalmacenName.split("-")[0]);
                    return subalmacenA - subalmacenB;
                });

                console.log("Flag3")

                const estatusOrdenObj = self.getStatusOrden(statusSet);

                console.log("Flag4")

                component.set('v.estatusOrden', estatusOrdenObj);
                component.set('v.orderLineItemDetails', allOrderLineItemDetails); 
                component.set('v.filteredOrderLineItemDetails', filteredOrderLineItemDetails); 
                component.set('v.activeSections', ['A']); 
                component.set("v.isLoading", false);
            } else{
                console.log(response.getError());
                component.set("v.isLoading", false);
            }
        });
        $A.enqueueAction(action);
    }, 

    getSubalmacenName: function(order) { 
        let subalmacenName = null;
        const subalmacen = order.split("-")[0];
        switch (subalmacen) {
            case '101':
                subalmacenName = order + ' - MEDICAMENTO AG';
                break;
            case '102':
                subalmacenName = order + ' - MATERIAL CURACIÓN AG';
                break;
            case '301':
                subalmacenName = order + ' - MEDICAMENTO AE';
                break;
            case '302':
                subalmacenName = order + ' - MATERIAL DE CURACIÓN AE';
                break;    
            case '401':
                subalmacenName = order + ' - MEDICAMENTO CONTROLADO';
                break;
            case '501':
                subalmacenName = order + ' - MEDICAMENTO REFRIGERADO';
                break; 
            case '502':
                subalmacenName = order + ' - MATERIAL DE CURACIÓN REFRIGERADO';
                break; 
            case '503':
                subalmacenName = order + ' - MEDICAMENTO CONTROLADO REFRIGERADO';
                break; 
            case '601':
                subalmacenName = order + ' - MEDICAMENTO CONGELADO';
                break; 
            default:
                subalmacenName = order + ' - NO ASIGNADO';


            // case '100':
            //     subalmacenName = order + ' - GENERAL';
            //     break;
            // case '200':
            //     subalmacenName = order + ' - MATERIAL DE CURACIÓN';
            //     break; 
            // case '300':
            //     subalmacenName = order + ' - ALTA ESPECIALIDAD';
            //     break;
            // case '400':
            //     subalmacenName = order + ' - RED FRÍA';
            //     break;
            // case '500':
            //     subalmacenName = order + ' - CONTROLADO';
            //     break; 
            // default:
            //     subalmacenName = order + ' - NO ASIGNADO';
        }
        return subalmacenName;
    },

    getOrderLineItemDetails : function(orderLineItems) {
        return orderLineItems.map(function(oli) {
            const { Cantidad_Aprobada__c = null, Cantidad_Solicitada__c = null, Costo__c = null, 
                Cantidad_de_Piezas__c = null, Cantidad_Surtida__c = null, Costo_Promedio__c = null, Product__r = {} } = oli;
            const { Name = null, Product_Code_ID__c = null } = Product__r;
            return {
                itemId : Product_Code_ID__c,
                itemNombre : Name,
                piezasSolicitadas : Cantidad_Solicitada__c ? Cantidad_Solicitada__c : 0, 
                piezasEnviadas : Cantidad_de_Piezas__c ? Cantidad_de_Piezas__c : 'N/A', 
                piezasEntregadas : Cantidad_Surtida__c ? Cantidad_Surtida__c : 'N/A',
                costoPromedio : Costo_Promedio__c ? Costo_Promedio__c : 'N/A',
                costoPromedioTotal : Costo_Promedio__c && Cantidad_Surtida__c ? Costo_Promedio__c * Cantidad_Surtida__c : 'N/A'
            }
        });
    },

    getArrayDeSeguimiento : function(seguimiento, firmadoPor, certificadoPor) {
        const seguimientoObj = {};
        const arrayDeSeguimiento = [];
        let formattedArrivalDateTime = null;
        const parsedSeguimiento = JSON.parse(seguimiento);
        const popoverKeys = ['En Firma', 'En Firma Parcial', 'Certificado', 'Certificado Parcial'];

        console.log(parsedSeguimiento);

        for (const key in parsedSeguimiento) {
            if (parsedSeguimiento.hasOwnProperty(key)) {
                const value = parsedSeguimiento[key];
                const timestamp = value.split(";")[0].split(":")[1];
                const minuto = value.split(";")[0].split(":")[2];
                const [fecha, hora] = timestamp.split(" ");
                const firma = value.split(";")[1];
                let posicion = null;
                let utility = null;
              
                switch (key) { 
                    case 'Error':
                        posicion = '0';
                        utility = 'utility:clear';
                        break; 
                    case 'Procesando':
                        posicion = '0';
                        utility = 'utility:clock';
                        break; 
                    case 'Verificando Disponibilidad':
                        posicion = '1';
                        utility = 'utility:record_lookup';
                        break;
                    case 'Preparando Envío':
                        posicion = '2';
                        utility = 'utility:task';
                        break;
                    case 'Enviado':
                        posicion = '3';
                        utility = 'utility:travel_and_places';
                        break; 
                    case 'Llegada de Transporte':
                        posicion = '4';
                        utility = 'utility:checkin';
                        break; 
                    case 'Transferido':
                        posicion = '5';
                        utility = 'utility:text_template';
                        break;
                    case 'Recibido':
                        posicion = '6';
                        utility = 'utility:fulfillment_order';
                        break;
                    case 'Recibido Parcial':
                        posicion = '6';
                        utility = 'utility:fulfillment_order';
                        break;
                    case 'Rechazado':
                        posicion = '6';
                        utility = 'utility:warning';
                        break;
                    case 'En Firma':
                        posicion = '7';
                        utility = 'utility:touch_action';
                        break;
                    case 'En Firma Parcial':
                        posicion = '7';
                        utility = 'utility:touch_action';
                        break; 
                    case 'Firma Rechazada':
                        posicion = '7';
                        utility = 'utility:warning';
                        break; 
                    case 'Certificado':
                        posicion = '8';
                        utility = 'utility:approval';
                        break; 
                    case 'Certificado Parcial': 
                        posicion = '8';
                        utility = 'utility:approval';
                        break;
                    default:
                        console.log('No valido');
                } 

                const isPopoverVisible = popoverKeys.includes(key) && (firmadoPor || certificadoPor);
                const newObject = {
                    value: posicion,
                    label: key === 'Verificando Disponibilidad' ? 'Verificando' : key,
                    labelPosition: 'bottom',
                    description: `${fecha} | ${hora}:${minuto}`,
                    descriptionPosition: 'bottom',
                    popoverIconName: isPopoverVisible ? null : utility,
                    popoverSize: isPopoverVisible ? 'large' : 'small',
                    popoverDescription: (key === 'En Firma'|| key === 'En Firma Parcial') && firmadoPor 
                        ? `Firma: ${firmadoPor}`: key === 'Certificado'|| key === 'Certificado Parcial' && certificadoPor 
                        ? `Certifica: ${certificadoPor}` : null,
                    popoverVariant: 'button'
                };
                arrayDeSeguimiento.push(newObject); 

                if(key === 'En Firma'){
                    formattedArrivalDateTime = `${fecha} | ${hora}:${minuto}`
                } 
            } 
        }

        seguimientoObj.arrayDeSeguimiento = arrayDeSeguimiento;
        seguimientoObj.formattedArrivalDateTime = formattedArrivalDateTime;

        // console.log(JSON.parse(JSON.stringify(seguimientoObj)))
        // return arrayDeSeguimiento;

        return seguimientoObj;
    },

    getStatusOrden : function(statusSet) {

        console.log("Inside get status set");
        console.log(JSON.parse(JSON.stringify(statusSet)));

        const statusArray = [...statusSet];
        console.log(JSON.parse(JSON.stringify(statusArray)));

        const hasErrors = statusArray.includes('Error');
        if(hasErrors){
            return {label:'Error de Sistema', icon:'utility:clear', theme:'slds-theme_error'}
        }

        const estatusOrden = statusArray.length > 1 ? 'Ver Detalles' : statusArray[0];
        let label = null;
        let icon = null;
        let theme = null;
        switch (estatusOrden) {
            case 'Verificando Disponibilidad':
                label = estatusOrden;
                icon = 'utility:record_lookup';
                theme = 'slds-theme_info';
                break;
            case 'Preparando Envío':
                label = estatusOrden;
                icon = 'utility:task';
                theme = 'slds-theme_info'; 
                break;
            case 'Enviado':
                label = estatusOrden;
                icon = 'utility:travel_and_places';
                theme = 'slds-theme_info';  
                break;
            case 'En Firma':
                label = estatusOrden;
                icon = 'utility:approval';
                theme = 'slds-theme_info';
                break;
            case 'Transferido':
                label = estatusOrden;
                icon = 'utility:text_template';
                theme = 'slds-theme_info'; 
                break;
            case 'Recibido':
                label = estatusOrden;
                icon = 'utility:retail_execution';
                theme = 'slds-theme_success';
                break;
            case 'Rechazado':
                label = estatusOrden;
                icon = 'utility:record_delete';
                theme = 'slds-theme_error';
                break; 
            case 'Ver Detalles':
                label = estatusOrden;
                icon = 'utility:table';
                theme = 'slds-theme_info';
                break;  
            default: 
                console.log('No valido');
        } 
        return {label, icon, theme}
    },

    getFilteredOrderLineItemDetails : function(component, event, data, detallesOLI) { 
        const {Product__c = null, Product__r = {}, Cantidad_Aprobada__c = 0, Cantidad_Solicitada__c = 0, Costo__c = 0} = data; 
        const {Subalmacen__r = {}, Product_Code_ID__c = ''} = Product__r; 
        const {Name, Numero_de_Subalmacen__c} = Subalmacen__r;  
        const nombreDeSubAlmacen = Name;
        const numeroDeSubAlmacen = Numero_de_Subalmacen__c;  
        if(!Product__c) return detallesOLI; 

        if(!detallesOLI.hasOwnProperty(numeroDeSubAlmacen)){ 
            detallesOLI[numeroDeSubAlmacen] = {
                datosDelSubalmacen: `${numeroDeSubAlmacen} - ${nombreDeSubAlmacen}`,
                datosDeOLI: []
            }; 
        }    
        detallesOLI[numeroDeSubAlmacen].datosDeOLI.push(
            {
                itemId : Product_Code_ID__c,
                itemNombre : Product__r.Name || '',
                piezasEnviadas : Cantidad_Aprobada__c, 
                piezasEntregadas : Cantidad_Solicitada__c,
                costoPromedio : Costo__c,
                costoPromedioTotal : Costo__c
            }
        ); 
        return detallesOLI;
    },

    reenviarOrden : function(component, orderId){
        const action = component.get("c.reenviarOrden"); 
        action.setParams({
            orderId
        });
        action.setCallback(this, function(response){ 
            const state = response.getState();
            console.log(state);
            if (state === "SUCCESS") {
                const responseVal = response.getReturnValue();
                console.log(JSON.parse(JSON.stringify(responseVal))); 

                this.showToast(component, 'Orden enviada a sistema con éxito', 'info', 'La orden ha sido enviada al sistema, te sugerimos refrescar la página dentro de un par de minutos para ver la actualización.');

                component.set('v.displayDatosTransporte', false);
                component.set('v.displayFirmarRecibirEntrega', false);
                component.set('v.displayFirmarLlegadaTransporte', true); 
                $A.util.toggleClass(component.find("detallesOrden"), 'slds-hide');

                component.set("v.isModalLoading", false);  
            }else{
                console.log(response.getError());
                component.set("v.isModalLoading", false);
            }
        });
        $A.enqueueAction(action); 
    },

    certificarEntrega : function(component, selectedOLI){
        console.log("Inside handle certficar entrega"); 
        const {datoDeOrderId = null} = selectedOLI;
        console.log(datoDeOrderId); 
        if(!datoDeOrderId){ return; }

        const action = component.get("c.certificateOrder"); 
        action.setParams({
            selectedOrderId : datoDeOrderId
        });
        action.setCallback(this, function(response) { 
            const state = response.getState();
            console.log(state);
            if (state === "SUCCESS") {
                const responseVal = response.getReturnValue();
                const {Seguimiento__c = null} = responseVal;
        
                selectedOLI.datosDelSubalmacen.buttonDisplayment.displayFirmarLlegadaTransporte = false; 
                selectedOLI.datosDelSubalmacen.buttonDisplayment.displayDatosTransporte = false;
                selectedOLI.datosDelSubalmacen.buttonDisplayment.displayFirmarRecibirEntrega = false; 

                const seguimientoObj = this.getArrayDeSeguimiento(Seguimiento__c); 
                const {arrayDeSeguimiento = []} = seguimientoObj;  
                arrayDeSeguimiento.sort((a, b) => a.value - b.value);
                selectedOLI.datosDeSeguimiento = arrayDeSeguimiento; 

                const filteredOrderLineItemDetails = component.get('v.filteredOrderLineItemDetails'); 
                const updatedOrderLineItemDetails = filteredOrderLineItemDetails.map(item => {
                    if (item.datoDeOrderId === datoDeOrderId) { 
                        Object.assign(item, selectedOLI);
                    }
                    return item;
                });  
                component.set('v.filteredOrderLineItemDetails', updatedOrderLineItemDetails);

                this.showToast(component, 'La order ha sido certificada', 'success', 'La certificación de la orden ha sido generada y el estatus ha sido actualizado a Certificado.');

                component.set("v.isModalLoading", false);  
            }else{
                console.log(response.getError());
                component.set("v.isModalLoading", false); 
            }
        });
        $A.enqueueAction(action); 
    },

    rechazarEntrega : function(component, selectedOLI){
        const {datoDeOrderId = null} = selectedOLI;  

        const action = component.get("c.rejectOrder"); 
        action.setParams({
            selectedOrderId : datoDeOrderId
        });
        action.setCallback(this, function(response) { 
            const state = response.getState();
            console.log(state);
            if (state === "SUCCESS") {
                const responseVal = response.getReturnValue();
                const {Seguimiento__c = null} = responseVal;
        
                selectedOLI.datosDelSubalmacen.buttonDisplayment.displayFirmarLlegadaTransporte = false; 
                selectedOLI.datosDelSubalmacen.buttonDisplayment.displayDatosTransporte = false;
                selectedOLI.datosDelSubalmacen.buttonDisplayment.displayFirmarRecibirEntrega = false; 

                const seguimientoObj = this.getArrayDeSeguimiento(Seguimiento__c); 
                const {arrayDeSeguimiento = []} = seguimientoObj;  
                arrayDeSeguimiento.sort((a, b) => a.value - b.value);
                selectedOLI.datosDeSeguimiento = arrayDeSeguimiento; 

                const filteredOrderLineItemDetails = component.get('v.filteredOrderLineItemDetails'); 
                const updatedOrderLineItemDetails = filteredOrderLineItemDetails.map(item => {
                    if (item.datoDeOrderId === datoDeOrderId) { 
                        Object.assign(item, selectedOLI);
                    }
                    return item;
                });  
                component.set('v.filteredOrderLineItemDetails', updatedOrderLineItemDetails);

                this.showToast(component, 'La order ha sido rechazada', 'info', 'La certificación de la orden ha sido rechazada y el estatus ha sido actualizado a Enviado.');

                component.set("v.isModalLoading", false); 
            }else{
                console.log(response.getError());
                component.set("v.isLoading", false);
            }
        });
        $A.enqueueAction(action); 
    },

    showToast : function(component, title, type, message) {
        const toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "type" : type,
            "message": message
        });
        toastEvent.fire();
    },

    // getDocumentosRelacionados : function(component, event, data) {
    //     $A.createComponent(
    //         "c:filesContainer",
    //         {orderId : data.Id},
    //         function(newCmp) {
    //             if (component.isValid()) { 
    //                 component.set("v.body", newCmp);
    //             }
    //         }
    //     );
    // }
})