({
    doInit : function(component, event, helper) {
        // Inicializar fechas default (3 meses atras y fecha de hoy)
        helper.inicializarFechas(component); 

        // Inicializar columnas de tabla
        helper.setupDataTable(component);

        // Obtener datos de tabla
        helper.getData(component);

        component.set('v.showHideFiltros', {
            mostrarmas : true,
            mostrarmenos : false
        })
    },

    onNext: function(component, event, helper) {        
        let pageNumber = component.get("v.currentPageNumber");
        component.set("v.currentPageNumber", pageNumber + 1);
        helper.setPageDataAsPerPagination(component);
    },
     
    onPrev: function(component, event, helper) {        
        let pageNumber = component.get("v.currentPageNumber");
        component.set("v.currentPageNumber", pageNumber - 1);
        helper.setPageDataAsPerPagination(component);
    },
     
    onFirst: function(component, event, helper) {        
        component.set("v.currentPageNumber", 1);
        helper.setPageDataAsPerPagination(component);
    },
     
    onLast: function(component, event, helper) {        
        component.set("v.currentPageNumber", component.get("v.totalPages"));
        helper.setPageDataAsPerPagination(component);
    },
 
    onPageSizeChange: function(component, event, helper) {        
        helper.preparePagination(component, component.get('v.filteredData'));
    },
 
    onChangeSearchPhrase : function (component, event, helper) {
        let searchPhrase = component.get("v.searchPhrase");
        let deliveryNumber = component.get("v.deliveryNumber");
        let remisionNumber = component.get("v.remisionNumber");

        if(!$A.util.isEmpty(searchPhrase)){
            component.set('v.deliveryNumber', null);
            component.set('v.remisionNumber', null);
            helper.clearDataBeforeCodeSearch(component, event);
            helper.searchRecordsByPedidoNumber(component);
        } else if(!$A.util.isEmpty(deliveryNumber)){
            component.set('v.searchPhrase', null);
            component.set('v.remisionNumber', null);
            helper.clearDataBeforeCodeSearch(component, event);
            helper.searchRecordsByDeliveryNumber(component);
        } else if(!$A.util.isEmpty(remisionNumber)){
            component.set('v.deliveryNumber', null);
            component.set('v.searchPhrase', null);
            helper.clearDataBeforeCodeSearch(component, event);
            helper.searchRecordsByRemisionNumber(component);
        } else{
            helper.clearDataBeforeCodeSearch(component, event);
        }
    },

    handleFiltrarPorFechas : function(component, event, helper) { 
        helper.getData(component); 
    }, 

    handleClickedRow : function(component, event, helper) { 
        const row = event.getParam('row'); 
        const selectedRow = true;
        helper.mostrarDetalles(component, row, selectedRow);  
    },

    handleShowHideFiltros : function(component, event, helper) {
        const showHideFiltros = component.get('v.showHideFiltros');

        component.set('v.showHideFiltros', {
            mostrarmas : !showHideFiltros.mostrarmas,
            mostrarmenos : !showHideFiltros.mostrarmenos
        });
    },

    limpiarFiltros : function(component, event, helper) {
        component.set('v.clavesSeleccionadas', []);
        component.set('v.umusSeleccionadas', []);
        component.set('v.estadosSeleccionados', []);
        component.set('v.pedidosSeleccionados', []);
        component.set('v.transportesSeleccionados', []);
        component.set('v.tipoDeClaveObj', {});
        component.set('v.tipoDeUMUObj', {});
        component.set('v.tipoDeEstadoObj', {});
        component.set('v.tipoDePedidoObj', {});
        component.set('v.tipoDeTransporteObj', {});
        component.set('v.searchPhrase', '');
        component.set('v.deliveryNumber', '');
        component.set('v.remisionNumber', '');

        const allData = component.get("v.allData");
        component.set("v.filteredData", allData);
        helper.preparePagination(component, allData);
        helper.mostrarDetalles(component, allData, false);

        //call event to clear picklist values 
        var appEvent = $A.get("e.c:limpiarParametrosDeFiltros"); 
        appEvent.setParams({"clearValues" : true}); 
        appEvent.fire();
    },

    obtenerClaves : function(component, event, helper) { 
        const params = event.getParam('arguments') || {};
        if(Object.keys(params).length > 0){
            const {picklistDeClavesSeleccionadas = null} = params;
            const claves = picklistDeClavesSeleccionadas && picklistDeClavesSeleccionadas != 'clearValues' ?
                picklistDeClavesSeleccionadas : [];
            component.set('v.clavesSeleccionadas', claves);

            const tipoDeClaveObj = {};
            if(claves.length > 0) {
                tipoDeClaveObj.show = true;
                tipoDeClaveObj.body = [{
                    type: 'avatar',
                    href: '',
                    label: claves.length > 1 ? `${claves.length} Opciones Seleccionadas  ` : 
                        `${claves.length} Opción Seleccionada  ` , 
                    fallbackIconName: 'standard:all',
                    variant: 'circle',
                    alternativeText: 'User avatar',
                }]
            } else{
                tipoDeClaveObj.show = false;
            }
            component.set('v.tipoDeClaveObj', tipoDeClaveObj);

            helper.searchRecordsByFilters(component);
        } 
    },

    obtenerUMUs : function(component, event, helper) {
        const params = event.getParam('arguments') || {};
        if(Object.keys(params).length > 0){
            const {picklistDeUMUsSeleccionadas = null} = params;
            const umus = picklistDeUMUsSeleccionadas && picklistDeUMUsSeleccionadas != 'clearValues' ? 
                picklistDeUMUsSeleccionadas : [];
            component.set('v.umusSeleccionadas', umus);

            const tipoDeUMUObj = {};
            if(umus.length > 0) {
                tipoDeUMUObj.show = true;
                tipoDeUMUObj.body = [{
                    type: 'avatar',
                    href: '',
                    label: umus.length > 1 ? `${umus.length} Opciones Seleccionadas  ` : 
                        `${umus.length} Opción Seleccionada  ` , 
                    fallbackIconName: 'standard:all',
                    variant: 'circle',
                    alternativeText: 'User avatar',
                }]
            } else{
                tipoDeUMUObj.show = false;
            }
            component.set('v.tipoDeUMUObj', tipoDeUMUObj);
            helper.searchRecordsByFilters(component);
        } 
    },

    obtenerEstados : function(component, event, helper) {
        const params = event.getParam('arguments') || {};
        if(Object.keys(params).length > 0){
            const {picklistDeEstadosSeleccionados = null} = params;
            const estados = picklistDeEstadosSeleccionados && picklistDeEstadosSeleccionados != 'clearValues' ? 
                picklistDeEstadosSeleccionados : [];

            component.set('v.estadosSeleccionados', estados);

            const tipoDeEstadoObj = {};
            if(estados.length > 0) {
                tipoDeEstadoObj.show = true;
                tipoDeEstadoObj.body = [{
                    type: 'avatar',
                    href: '',
                    label: estados.length > 1 ? `${estados.length} Opciones Seleccionadas  ` : 
                        `${estados.length} Opción Seleccionada  ` , 
                    fallbackIconName: 'standard:all',
                    variant: 'circle',
                    alternativeText: 'User avatar',
                }]
            } else{
                tipoDeEstadoObj.show = false;
            }
            component.set('v.tipoDeEstadoObj', tipoDeEstadoObj);
            helper.searchRecordsByFilters(component);
        } 
    },

    obtenerPedidos : function(component, event, helper){ 
        const params = event.getParam('arguments') || {};
        if(Object.keys(params).length > 0){
            const {picklistDePedidosSeleccionados = null} = params;
            const pedidos = picklistDePedidosSeleccionados && picklistDePedidosSeleccionados != 'clearValues' ? 
                picklistDePedidosSeleccionados : [];
            component.set('v.pedidosSeleccionados', pedidos);

            const tipoDePedidoObj = {};
            if(pedidos.length > 0) {
                tipoDePedidoObj.show = true;
                tipoDePedidoObj.body = [{
                    type: 'avatar',
                    href: '',
                    label: pedidos.length > 1 ? `${pedidos.length} Opciones Seleccionadas  ` : 
                        `${pedidos.length} Opción Seleccionada  ` , 
                    fallbackIconName: 'standard:all',
                    variant: 'circle',
                    alternativeText: 'User avatar',
                }]
            } else{
                tipoDePedidoObj.show = false;
            }
            component.set('v.tipoDePedidoObj', tipoDePedidoObj);

            helper.searchRecordsByFilters(component);
        }
    },

    obtenerTransportes : function(component, event, helper) {   
        const params = event.getParam('arguments') || {}; 
        if(Object.keys(params).length > 0){
            const {picklistDeTransportesSeleccionados = null} = params;
            const transportes = picklistDeTransportesSeleccionados && picklistDeTransportesSeleccionados != 'clearValues' ? 
                picklistDeTransportesSeleccionados : [];
            component.set('v.transportesSeleccionados', transportes);

            const tipoDeTransporteObj = {};
            if(transportes.length > 0) {
                tipoDeTransporteObj.show = true;
                tipoDeTransporteObj.body = [{
                    type: 'avatar',
                    href: '',
                    label: transportes.length > 1 ? `${transportes.length} Opciones Seleccionadas  ` : 
                        `${transportes.length} Opción Seleccionada  ` , 
                    fallbackIconName: 'standard:all',
                    variant: 'circle',
                    alternativeText: 'User avatar',
                }]
            } else{
                tipoDeTransporteObj.show = false;
            }
            component.set('v.tipoDeTransporteObj', tipoDeTransporteObj);

            helper.searchRecordsByFilters(component);
        }
    },

    handleSort : function(component, event, helper) {
        helper.handleSort(component, event);
    },
})