({

    setDetallesDeAprobacionAutorizacion : function(component) {
        const traxionUrl = window.location.href;
        const splittedUrl = traxionUrl.split('/');
        const urlDirection = splittedUrl[splittedUrl.length - 1]; 
        const isAprobacion = urlDirection === 'aprobacion-de-pedidos'; 
        component.set('v.isAprobacion', isAprobacion);

        const urlData = {};
        urlData.cardTitle = isAprobacion ? 'APROBACIÓN DE PEDIDOS' : 'AUTORIZACIÓN DE PEDIDOS';
        urlData.cardIcon = isAprobacion ? 'standard:approval' : 'standard:checkout'; 
        urlData.pendingApprovalTab = isAprobacion ? 'POR APROBAR' : 'POR AUTORIZAR';
        urlData.approvalTab = isAprobacion ? {label : 'APROBADOS', id : 'Aprobado'} : {label : 'AUTORIZADOS', id : 'Autorizado'};  
        urlData.approveAuthorize = isAprobacion ? 'Aprobar' : 'Autorizar'; 
        component.set('v.urlData', urlData);
    },

    inicializarFechas : function(component) {
        const fechaActual = new Date();
        const anioActual = fechaActual.getFullYear();
        const mesActual = fechaActual.getMonth() + 1;
        const diaActual = fechaActual.getDate(); 
        component.set('v.fechaFin', `${anioActual}-${mesActual}-${diaActual}`);

        let fechaHaceTresMeses = new Date(fechaActual);
        fechaHaceTresMeses.setMonth(fechaHaceTresMeses.getMonth() - 3);
        const anioPasado = fechaHaceTresMeses.getFullYear();
        const mesPasado = fechaHaceTresMeses.getMonth() + 1;
        const diaPasado = fechaHaceTresMeses.getDate(); 
        component.set('v.fechaInicio', `${anioPasado}-${mesPasado}-${diaPasado}`);
    }, 

    setupDataTable: function (component) {
        component.set('v.columns', [
            {label: 'Tipo', fieldName: 'Tipo_de_Pedido__c', type: 'text', sortable: true},
            {label: 'Folio Solicitud', fieldName: 'ID_de_Pedido__c', type: 'text', sortable: true},
            {label: 'Unidad Médica', fieldName: 'UMUName', type: 'text', sortable: true}, 
            {label: 'Oficio', fieldName: 'Numero_de_Oficio__c', type: 'text'},
            {label: 'Fecha de Solicitud', fieldName: 'FechaCreacion', type: 'text', sortable: true}, 
            {label: 'Detalles', type: 'button', initialWidth: 125, typeAttributes: {label: 'Ver Detalles', name: 'view_program', title: 'Click to View Program Details'}}
        ]);
    },

    setNonApprovalReasons : function(component) {
        component.set('v.nonApprovalReasons', [
            {'label': 'SIN EXISTENCIAS SUFICIENTES EN CENADI PARA OTORGARLE LA CANTIDAD SOLICITADA', 'value': 'SIN EXISTENCIAS SUFICIENTES EN CENADI PARA OTORGARLE LA CANTIDAD SOLICITADA'},
            {'label': 'ANEXAR GT1', 'value': 'ANEXAR GT1'},
            {'label': 'ANEXAR GT1 Y CONTRAREFERENCIA', 'value': 'ANEXAR GT1 Y CONTRAREFERENCIA'},
            {'label': 'SE ATENDERÁ POR GUÍA', 'value': 'SE ATENDERÁ POR GUÍA'},
            {'label': 'ANEXAR CENSO DE PACIENTES', 'value': 'ANEXAR CENSO DE PACIENTES'},
            {'label': 'ANEXAR CONTRAREFERENCIA', 'value': 'ANEXAR CONTRAREFERENCIA'},
            {'label': 'ENVIAR CENSO ACTUALIZADO CON DOSIS Y TIEMPO DE APLICACIÓN', 'value': 'ENVIAR CENSO ACTUALIZADO CON DOSIS Y TIEMPO DE APLICACIÓN'},
            {'label': 'SE SURTIRÁ UN MES DE SU DPN', 'value': 'SE SURTIRÁ UN MES DE SU DPN'},
            {'label': 'SIN EXISTENCIAS EN CENADI', 'value': 'SIN EXISTENCIAS EN CENADI'},
            {'label': 'VALIDAR EN TIEMPO Y FORMA SU DPN ASIGNADA', 'value': 'VALIDAR EN TIEMPO Y FORMA SU DPN ASIGNADA'},
            {'label': 'EXISTENCIAS SUFICIENTES EN LA UNIDAD MÉDICA', 'value': 'EXISTENCIAS SUFICIENTES EN LA UNIDAD MÉDICA'},
            {'label': 'PEDIDO DUPLICADO', 'value': 'PEDIDO DUPLICADO'},
            {'label': 'OTRO', 'value': 'OTRO'}
        ]);
    }, 

    getData: function (component) {
        return this.callAction(component)
            .then(
                $A.getCallback(records => {
                    component.set('v.allData', records);
                    component.set('v.filteredData', records);
                    this.getFilterData(component, records);
                    this.preparePagination(component, records);
                })
            )
            .catch(
                $A.getCallback(errors => {
                    if (errors && errors.length > 0) {
                        $A.get("e.force:showToast")
                            .setParams({
                                message: errors[0].message != null ? errors[0].message : errors[0],
                                type: "error"
                            })
                            .fire();
                    }
                })
            );
    },

    callAction: function (component) {
        component.set("v.isLoading", true);
        return new Promise(
            $A.getCallback((resolve, reject) => {
                const fechaInicio = component.get("v.fechaInicio");
                const fechaFin = component.get("v.fechaFin");
                const pedidoJSON = {
                    fechaInicio : fechaInicio,
                    fechaFin : fechaFin,
                    esAprobacion : component.get('v.isAprobacion'),
                    estatusNoOrdinario : component.get('v.selTabId')
                } 

                const action = component.get("c.getFilteredPedidos"); 
                action.setParams({ 
                    pedidoJSON : JSON.stringify(pedidoJSON)
                }); 

                action.setCallback(this, response => {
                    component.set("v.isLoading", false);

                    const state = response.getState();
                    console.log(state); 
                    if (state === "SUCCESS") {
                        const responseVal = response.getReturnValue();
                        console.log(responseVal);

                        function formatDate(date) {
                            const day = date.getDate().toString().padStart(2, '0');
                            const month = (date.getMonth() + 1).toString().padStart(2, '0');
                            const year = date.getFullYear().toString();
                            // return `${day}/${month}/${year}`;
                            return `${year}-${month}-${day}`;
                        }

                        for(let i=0; i < responseVal.length; i++) {
                            const order = responseVal[i];
                            const {CreatedDate, Order_Line_Items__r, UMU__r = {}} = order; 
                            const {Name = ''} = UMU__r; 
                            order.UMUName = Name;

                            const fechaCreacion = new Date(CreatedDate);
                            const formattedFechaCreacion = formatDate(fechaCreacion);
                            order.FechaCreacion = formattedFechaCreacion;
                        }
                        return resolve(responseVal);

                    } else if (state === "ERROR") {
                        return reject(response.getError());
                    }
                    return null;
                });
                $A.enqueueAction(action);
            })
        );
    },

    sortBy: function(field, reverse, primer) {
        var key = primer
            ? function(x) {
                  return primer(x[field]);
              }
            : function(x) {
                  return x[field];
              };

        return function(a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    },

    handleSort: function(component, event) {
        console.log("Inside handleSort");
        var sortedBy = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');

        console.log(sortedBy);
        console.log(sortDirection);

        const allData = component.get('v.allData');
        var cloneData = allData.slice(0);
        cloneData.sort((this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1)));

        console.log(JSON.parse(JSON.stringify(cloneData)))
        
        // component.set('v.tableData', cloneData);
        component.set('v.sortDirection', sortDirection);
        component.set('v.sortedBy', sortedBy);
        component.set('v.filteredData', cloneData);
        
        this.preparePagination(component, cloneData);
    },
 
    preparePagination: function (component, imagesRecords) {
        let countTotalPage = Math.ceil(imagesRecords.length/component.get("v.pageSize"));
        let totalPage = countTotalPage > 0 ? countTotalPage : 1;
        component.set("v.totalPages", totalPage);
        component.set("v.currentPageNumber", 1);
        this.setPageDataAsPerPagination(component);
    },
 
    setPageDataAsPerPagination: function(component) {
        let data = [];
        let pageNumber = component.get("v.currentPageNumber");
        let pageSize = component.get("v.pageSize");
        let filteredData = component.get('v.filteredData');
        let x = (pageNumber - 1) * pageSize;
        for (; x < (pageNumber) * pageSize; x++){
            if (filteredData[x]) {
                data.push(filteredData[x]);
            }
        }
        component.set("v.tableData", data);
    },

    searchRecordsBySearchPhrase : function (component) { 
        let searchPhrase = component.get("v.searchPhrase"); 
        if (!$A.util.isEmpty(searchPhrase)) {
            let allData = component.get("v.allData");
            let filteredData = allData.filter(function(record){ 
                const {ID_de_Pedido__c = null} = record;  
                if(ID_de_Pedido__c){ 
                    return ID_de_Pedido__c.includes(searchPhrase);
                } 
            });
            component.set("v.filteredData", filteredData);
            this.preparePagination(component, filteredData);
        }
    },

    searchOLIByClaveOrProduct : function (component) {
        console.log("INSIDE SEARCH OLI BY CLAVE OR PRODUCT");
        const searchClaveInsumoPhrase = component.get("v.searchClaveInsumoPhrase");
        console.log(searchClaveInsumoPhrase);

        if (!$A.util.isEmpty(searchClaveInsumoPhrase)) {
            let allOlis = component.get("v.sortedDataTable");

            console.log(JSON.parse(JSON.stringify(allOlis)));
            // let filteredData = allData.filter(record => [record.Order_Line_Items__r.Folio_del_Pedido__c].includes(searchClaveInsumoPhrase));

            const filteredData = allOlis.filter((oli) => {
                const { Product__r = {} } = oli;
                const { Product_Code_ID__c = null, Name = null } = Product__r;
                console.log(JSON.parse(JSON.stringify(Product__r)));
                console.log(Product_Code_ID__c);
                if(Name || Product_Code_ID__c){
                    console.log(!Product_Code_ID__c.includes(searchClaveInsumoPhrase) || !Name.includes(searchClaveInsumoPhrase));
                    if(!Product_Code_ID__c.includes(searchClaveInsumoPhrase) && !Name.includes(searchClaveInsumoPhrase)) return false;
                } 
                return true;
            });
            console.log(JSON.parse(JSON.stringify(filteredData)));

            component.set('v.oliData', filteredData);
        } 
    },

    searchOLIBySelection : function (component, pedido) { 

        console.log("Inside handle search by selection");
        console.log(JSON.parse(JSON.stringify(pedido)));

        const {Folio_de_Pedido__c=null, ID_de_Pedido__c=null, Mostrar_Envio_a_Autorizacion__c=null, Mostrar_Autorizacion__c=null} = pedido;
        const headerOrdenSeleccionada = Folio_de_Pedido__c && ID_de_Pedido__c ? `${Folio_de_Pedido__c} | ${ID_de_Pedido__c}` : 
            Folio_de_Pedido__c ? `${Folio_de_Pedido__c}` : 
            ID_de_Pedido__c ? `${ID_de_Pedido__c}` : '';
        component.set('v.headerOrdenSeleccionada', headerOrdenSeleccionada);
        component.set('v.showHideAprobacion', !Mostrar_Envio_a_Autorizacion__c);
        component.set('v.showHideAutorizacion', !Mostrar_Autorizacion__c);

        console.log("flag1");

        this.renderTitulo(component, pedido);
        this.renderInformacionGeneral(component, pedido);
        this.renderJustificacionDocumentos(component, pedido);
        this.showModal(component); 
        this.getDPNliInformation(component, pedido);
    },

    getDPNliInformation : function(component, pedido) {
        component.set('v.isLoading', true);

        const { UMU__c = null, Order_Line_Items__r = [] } = pedido;
        const productIds = Order_Line_Items__r.map(oli => oli.Product__c);
        const action = component.get("c.oliProductInformation");
        action.setParams({
            umuId : UMU__c,
            productIds
        });
        action.setCallback(this, function(response) { 
            const state = response.getState();
            console.log(state);
            if (state === "SUCCESS") {
                const responseVal = response.getReturnValue();
                const parsedAvailability = JSON.parse(responseVal);
                Order_Line_Items__r.forEach(function(oli) {
                    parsedAvailability.forEach(function(dpnli){
                        if (oli.Product__c == dpnli.productid) {
                            oli.DPNAvailability = dpnli.dpn;
                            oli.DPNValidado = dpnli.validado;
                            oli.DPNDisponible = dpnli.piezassolicitadas;
                            oli.CENADIDisponible = dpnli.existenciacenadi;
                        } else {
                            oli.DPNAvailability = 'N/A';
                            oli.DPNValidado = 'N/A';
                            oli.DPNDisponible = 'N/A';
                        }
                    });
                });
                this.renderDataTable(component, pedido);
                component.set('v.isLoading', false);  
            } else{
                console.log(response.getError());
                component.set('v.isLoading', false);
            }
        });
        $A.enqueueAction(action);
    },

    renderTitulo : function(component, pedido) {
        const {Tipo_de_Pedido__c = null, ID_de_Pedido__c = null, UMUName = null, Creado_Por__r = {}} = pedido; 
        const {Name = null} = Creado_Por__r;
        const rowTitulo = {
            tipo : Tipo_de_Pedido__c,
            detalle : ID_de_Pedido__c && UMUName ? `${ID_de_Pedido__c} | ${UMUName}` : null,
            nombre : Name
        } 
        component.set('v.rowTitulo', rowTitulo);
        component.set('v.tipoDeOrden', Tipo_de_Pedido__c);
    },

    renderInformacionGeneral : function(component, rowData) {
        const {UMU__r = {}, CreatedDate = null } = rowData; 
        const {Clave_Presupuestal__c = null, Name = null, Delegacion__c = null, Tipo_UMU__c = null, UMU__c = null} = UMU__r;
        const informacionGralArr = [];
        function populateArr(field, label){
            if(field){
                informacionGralArr.push({
                    label : label,
                    value : field
                })
            }
        }
        populateArr(Clave_Presupuestal__c, 'Clave Presupuestal:');
        populateArr(Name, 'Nombre de UMU:');
        populateArr(Delegacion__c, 'Delegación:');
        populateArr(Tipo_UMU__c, 'Tipo de Unidad Médica:');
        populateArr(UMU__c, 'Numero de UMU:');
        populateArr(CreatedDate, 'Fecha de Solicitud:');
        component.set('v.informacionGralArr', informacionGralArr);
    },

    renderJustificacionDocumentos : function(component, rowData) {
        const {Id = null} = rowData; 
        $A.createComponent(
            "c:filesContainer",
            {orderId : Id},
            function(newCmp) {
                if (component.isValid()) { 
                    component.set('v.justificacionyDocumentos', newCmp);
                }
            }
        );
    },

    searchRecordsByFilters : function (component) {
        const allData = component.get("v.allData");
        const claves = component.get("v.clavesSeleccionadas");
        const umus = component.get("v.umusSeleccionadas");
        const delegaciones = component.get("v.delegacionesSeleccionadas");
        const pedidos = component.get("v.pedidosSeleccionados");

        if (claves.length > 0 || umus.length > 0 || delegaciones.length > 0 || pedidos.length > 0) {
            const clavesArr = claves.map(obj => obj.Id);
            const delegacionesArr = delegaciones.map(obj => obj.Id);
            const umusArr = umus.map(obj => obj.Id);
            const pedidosArr = pedidos.map(obj => obj.Id);

            const filteredData = allData.filter((orden) => {
                const { Tipo_de_Pedido__c = null, Order_Line_Items__r = [], UMU__r = {} } = orden;
                const { Clave_Presupuestal__c = null, Delegacion__c = null } = UMU__r;

                if(umusArr.length > 0){
                    const containsUmus = umusArr.includes(Clave_Presupuestal__c);
                    if(!containsUmus) return containsUmus;
                } 

                if(delegacionesArr.length > 0){
                    const containsDelegaciones = delegacionesArr.includes(Delegacion__c);
                    if(!containsDelegaciones) return containsDelegaciones;
                } 

                if(pedidosArr.length > 0){
                    const containsPedidos = pedidosArr.includes(Tipo_de_Pedido__c);
                    if(!containsPedidos) return containsPedidos;
                } 

                if(Order_Line_Items__r.length > 0){
                    return Order_Line_Items__r.some((oli) => {
                        const { Product__r = {} } = oli;
                        const { Product_Code_ID__c = null } = Product__r;
                        if(clavesArr.length > 0){
                            const containsClaves = clavesArr.includes(Product_Code_ID__c);
                            if(!containsClaves) return containsClaves;
                        } 
                        return true;
                    });
                }
                return true;
            });

            component.set("v.filteredData", filteredData);
            this.preparePagination(component, filteredData);
            this.showToast(component, 'Filtro(s) aplicados', 'success', 'Los filtros han sido aplicados correctamente');
        } else{
            component.set("v.filteredData", allData);
            this.preparePagination(component, allData); 
        }
    },

    renderDataTable : function(component, pedido) {
        const sortedDataTable = [];
        const isAprobacion = component.get('v.isAprobacion');
        const selectedTab = component.get('v.selTabId');
        const { Order_Line_Items__r = [] } = pedido;

        function filterArrayOfObj(estatus){
            Order_Line_Items__r.forEach(function(oli){
                if(isAprobacion){
                    if(oli.Estatus_Aprobaci_n__c === selectedTab){
                        oli.EstatusActivo = true;
                    }
                    if(oli.Estatus_Aprobaci_n__c === estatus){
                        oli[estatus] = true;
                        sortedDataTable.push(oli);
                    }
                } else{
                    if(oli.Estatus_Autorizaci_n__c === selectedTab){
                        oli.EstatusActivo = true;
                    }
                    if(oli.Estatus_Autorizaci_n__c === estatus){
                        oli[estatus] = true;
                        sortedDataTable.push(oli);
                    }
                } 
            });
        }
        
        switch (selectedTab) {
            case 'Pendiente':
                filterArrayOfObj('Pendiente');
                isAprobacion ? filterArrayOfObj('Aprobado') : filterArrayOfObj('Autorizado');
                filterArrayOfObj('Modificado');
                filterArrayOfObj('Rechazado');
                break;
            case 'Aprobado':
                filterArrayOfObj('Aprobado');
                filterArrayOfObj('Modificado');
                filterArrayOfObj('Pendiente');
                filterArrayOfObj('Rechazado');
                break;
            case 'Autorizado':
                filterArrayOfObj('Autorizado');
                filterArrayOfObj('Modificado');
                filterArrayOfObj('Pendiente');
                filterArrayOfObj('Rechazado');
                break;
            case 'Rechazado':
                filterArrayOfObj('Rechazado');
                filterArrayOfObj('Modificado');
                isAprobacion ? filterArrayOfObj('Aprobado') : filterArrayOfObj('Autorizado');
                filterArrayOfObj('Pendiente');
                break;
        }
        
        console.log("INSIDE MOSTRAR SORTED TABLE");
        console.log(JSON.parse(JSON.stringify(sortedDataTable)));

        component.set("v.sortedDataTable", sortedDataTable); 
        component.set("v.oliData", sortedDataTable); 
    },

    showModal : function(component) {
        const showModal = component.get("v.showModal");
        const mainCmp = component.find('maincmp');
        !showModal ? $A.util.addClass(mainCmp, 'blur-main-cmp') : $A.util.removeClass(mainCmp, 'blur-main-cmp');
        component.set('v.showResumen', false);
        component.set("v.showModal", true);
    },

    getFilterData : function(component, data) {
        const umus = new Set();
        const claves = new Set();
        const delegaciones = new Set();
        const pedidos = new Set();

        data.forEach((orden) => {
            const { Order_Line_Items__r = [], UMU__r ={}, Tipo_de_Pedido__c = null} = orden;
            const {Clave_Presupuestal__c = null, Delegacion__c = null} = UMU__r;

            // Getting umus
            if (Clave_Presupuestal__c && UMU__r.Name) {
                const obj = {
                    Id: Clave_Presupuestal__c,
                    Name: `${Clave_Presupuestal__c} - ${UMU__r.Name}`,
                };
                if (![...umus].some((o) => o.Id === obj.Id)) {
                    umus.add(obj);
                }
            }


            // Getting delegaciones
            if (Delegacion__c) {
                const obj = {
                    Id: Delegacion__c,
                    Name: Delegacion__c,
                };
                if (![...delegaciones].some((o) => o.Id === obj.Id)) {
                    delegaciones.add(obj);
                }
            }

            // Getting pedidos
            if (Tipo_de_Pedido__c) {
                const obj = {
                    Id: Tipo_de_Pedido__c,
                    Name: Tipo_de_Pedido__c,
                };
                if (![...pedidos].some((o) => o.Id === obj.Id)) {
                    pedidos.add(obj);
                }
            }

            Order_Line_Items__r.forEach((oli) => {
                const { Product__r = {} } = oli;

                // Getting claves
                const { Product_Code_ID__c = null, Name = null} = Product__r;
                if (Product_Code_ID__c && Name) {
                    const obj = {
                        Id: Product_Code_ID__c,
                        Name: `${Product_Code_ID__c} - ${Name}`,
                    };
                    if (![...claves].some((o) => o.Id === obj.Id)) {
                        claves.add(obj);
                    }
                }
            });
        });

        component.set('v.msClaves', Array.from(claves));
        component.set('v.msUMUs', Array.from(umus)); 
        component.set('v.msDelegaciones', Array.from(delegaciones));
        component.set('v.msPedidos', Array.from(pedidos)); 
    },

    handleApprove : function(component, approvedRow) {
        const { Id = null, Cantidad_Solicitada__c = 0 } = approvedRow;
        if(!Id) return;
        const message = '';
        const actionType = 'Aprobado';
        const approvedQty = Cantidad_Solicitada__c; 
        this.updateOLI(component, Id, actionType, approvedQty, message);
    },

    handleAuthorize : function(component, authorizedRow) { 
        const { Id = null, Cantidad_Aprobada__c = 0 } = authorizedRow;
        if(!Id) return;
        const message = '';
        const actionType = 'Autorizado';
        const authorizedQty = Cantidad_Aprobada__c;
        this.updateOLI(component, Id, actionType, authorizedQty, message);
    },

    handleDisplayModifyModal : function(component, oliToModify) {  
        component.set("v.isLoading", false);
        const detailCmp = component.find('detailcmp');
        $A.util.addClass(detailCmp, 'blur-detail-cmp'); 
        component.set('v.oliToModify', oliToModify); 
        component.set('v.showModificationModal', true);  
    },

    handleModify : function(component, modifiedRow) {
        const { Id = null } = modifiedRow; 
        const amountToModify = component.get('v.amountToModify');
        if(!Id || !amountToModify) return;
        const selectedModification = component.get('v.selectedModificationReason');
        const message = selectedModification === 'OTRO' ? component.get('v.selectedModificationReasonOther') : selectedModification; 
        const actionType = 'Modificado';
        const approvedQty = amountToModify;
        this.updateOLI(component, Id, actionType, approvedQty, message);
    },

    handleDisplayRejectModal : function(component, oliToReject) {
        component.set("v.isLoading", false);

        component.set('v.oliToReject', oliToReject); 
        component.set('v.showRejectionModal', true);

        const detailCmp = component.find('detailcmp');
        $A.util.addClass(detailCmp, 'blur-detail-cmp');
    },

    handleReject : function(component, rejectedRow) {
        const { Id = null } = rejectedRow; 
        if(!Id) return; 
        const selectedRejection = component.get('v.selectedRejection');
        const message = selectedRejection === 'OTRO' ? component.get('v.selectedRejectionOther') : selectedRejection; 
        const actionType = 'Rechazado';
        const approvedQty = 0;
        this.updateOLI(component, Id, actionType, approvedQty, message);
    },

    updateOLI : function(component, oliId, actionType, quantity, message) {
        console.log("Inside update oli")

        const isAprobacion = component.get('v.isAprobacion');

        const action = component.get("c.updateOrderLineItem");
        action.setParams({
            "orderLineId": oliId, 
            "actionType" : actionType,
            "quantity" : quantity,
            "message" : message,
            "esAprobacion" : isAprobacion
        });
        action.setCallback(this, function(response) { 
            const state = response.getState();
            console.log(state);
            if (state === "SUCCESS") {
                const responseVal = response.getReturnValue();
                console.log(JSON.parse(JSON.stringify(responseVal)));
                
                isAprobacion ? component.set('v.showHideAprobacion', !responseVal[0].Mostrar_Envio_a_Autorizacion__c)
                    : component.set('v.showHideAutorizacion', !responseVal[0].Mostrar_Autorizacion__c); 

                this.renderDataTable(component, responseVal[0]);

                this.getDPNliInformation(component, responseVal[0]);

                component.set("v.isLoading", false);
                this.showToast(component, 'Actualización exitosa', 'success', `El registro ha sido ${actionType} exitosamente`);

                this.getData(component); 
            } else{
                console.log(response.getError());
                component.set("v.isLoading", false);
            }
        });
        $A.enqueueAction(action);
    },

    changeTipoDePedido : function(component, tipoDePedido, clickedPedidoId) {
        const action = component.get("c.updateTipoDePedido");
        action.setParams({
            "pedidoId": clickedPedidoId, 
            "tipoDePedido" : tipoDePedido
        });
        action.setCallback(this, function(response) { 
            const state = response.getState();
            console.log(state);
            if (state === "SUCCESS") {
                const responseVal = response.getReturnValue();
                console.log(JSON.parse(JSON.stringify(responseVal)));

                const order = responseVal;
                const {UMU__r = {}} = order; 
                const {Name = ''} = UMU__r; 
                order.UMUName = Name;
                this.searchOLIBySelection(component, order);
                this.getData(component);

                const mainCmp = component.find('maincmp');
                $A.util.addClass(mainCmp, 'blur-main-cmp'); 

                component.set("v.isLoading", false);
                this.showToast(component, 'Actualización exitosa', 'success', `El registro ha sido modificado exitosamente`);
            } else{
                component.set("v.isLoading", false);
                console.log(response.getError());
            }
        });
        $A.enqueueAction(action);
    },

    approveOrder : function(component) {
        
        console.log("Inside approve order");
        console.log(component.get('v.isAprobacion'));
        console.log(component.get('v.clickedPedidoId'));


        const action = component.get("c.updateIdDePedido");
        action.setParams({
            pedidoId : component.get('v.clickedPedidoId'),
            esAprobacion : component.get('v.isAprobacion')
        });
        action.setCallback(this, function(response) { 
            const state = response.getState();
            console.log(state);
            if (state === "SUCCESS") {
                const responseVal = response.getReturnValue();
                const isAprobacion = component.get('v.isAprobacion'); 
                component.set('v.pedidosArr', responseVal);
                
                console.log("***Inside responseval***");
                console.log(JSON.parse(JSON.stringify(responseVal)));


                if(isAprobacion){
                    if(responseVal.length === 1){ 
                        const {ID_de_Pedido__c = null} = responseVal[0]; 
                        component.set('v.approvedLabel', `EL PEDIDO ${ID_de_Pedido__c} HA SIDO ENVIADO A AUTORIZACIÓN`); 
                        this.sendEmailAprobacionAutorizacion(component, responseVal[0]);
                        this.mostrarResumen(component); 
                    } else if(responseVal.length === 2){  
                        const {ID_de_Pedido__c = null} = responseVal[1]; 
                        component.set('v.approvedLabel', `EL PEDIDO ${ID_de_Pedido__c} HA SIDO GENERADO Y ENVIADO A AUTORIZACIÓN`);
                        this.sendEmailAprobacionAutorizacion(component, responseVal[1]);
                        this.mostrarResumen(component); 
                    } else{
                        console.log("Error: Invalid response"); 
                        component.set("v.isLoading", false);
                        this.showToast(component, 'Error en la actualización', 'error', `Hubo un error. Inténtalo de nuevo o contacta a un administrador`);
                    } 
                } else{
                    if(responseVal.length === 1){ 
                        const {ID_de_Pedido__c = null} = responseVal[0];
                        component.set('v.approvedLabel', `EL PEDIDO ${ID_de_Pedido__c} HA SIDO AUTORIZADO`); 
                        this.generatePedidoInWMS(component, responseVal[0]); 
                    } else if(responseVal.length === 2){  
                        const {ID_de_Pedido__c = null} = responseVal[1]; 
                        component.set('v.approvedLabel', `EL PEDIDO ${ID_de_Pedido__c} HA SIDO GENERADO Y AUTORIZADO`);
                        this.generatePedidoInWMS(component, responseVal[1]);
                    } else{
                        console.log("Error: Invalid response");
                        component.set("v.isLoading", false);
                        this.showToast(component, 'Error en la actualización', 'error', `Hubo un error. Inténtalo de nuevo o contacta a un administrador`);
                    }
                } 
            } else{
                console.log(response.getError());
                component.set("v.isLoading", false);
            }
        });
        $A.enqueueAction(action);
    },

    generatePedidoInWMS : function(component, pedido) {
        console.log("Inside generate pedido");
        console.log(JSON.parse(JSON.stringify(pedido)));

        const {Id=null} = pedido;

        const action = component.get("c.generatePedidoInWMS");
        action.setParams({
            pedidoId : Id
        });
        action.setCallback(this, function(response) { 
            const state = response.getState();
            console.log(state);
            if (state === "SUCCESS") {
                const responseVal = response.getReturnValue();
                console.log(responseVal);

                this.sendEmailAprobacionAutorizacion(component, pedido);
                this.mostrarResumen(component); 
            } else{
                console.log(response.getError());
                component.set("v.isLoading", false);
            }
        });
        $A.enqueueAction(action);
    },

    sendEmailAprobacionAutorizacion : function(component, pedido) {

        console.log("Inside send email aprobacion autorizacion");
        console.log(JSON.parse(JSON.stringify(pedido)));

        const isAprobacion = component.get('v.isAprobacion');
        const {Id=null, Creado_Por__c, Creado_Por__r={} } = pedido;
        const {Email=null} = Creado_Por__r;

        const action = component.get("c.sendEmailAprobacionAutorizacion");
        action.setParams({
            isAutorizacion : !isAprobacion,
            pedidoId : Id,
            contactId : Creado_Por__c,
            contactEmail : [Email],
            emailTemplate : isAprobacion ? 'Respuesta_Pre_Autorizacion' : 'Respuesta_Autorizacion'
        });
        action.setCallback(this, function(response) { 
            const state = response.getState();
            console.log(state);
            if (state === "SUCCESS") {
                console.log('Emails were successfully sent');
            } else{
                console.log(response.getError());
                component.set("v.isLoading", false);
            }
        });
        $A.enqueueAction(action); 
    },

    mostrarResumen : function(component) {
        // Mostrar resumen 
        component.set('v.showResumen', true); 

        const mainCmp = component.find('maincmp');
        $A.util.addClass(mainCmp, 'blur-main-cmp'); 

        this.getData(component);

        component.set("v.isLoading", false);
        this.showToast(component, 'Actualización exitosa', 'success', `El registro ha sido enviado a autorización exitosamente`);
    },

    showToast : function(component, title, type, message) {
        const toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "type" : type,
            "message": message
        });
        toastEvent.fire();
    }
})