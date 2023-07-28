({

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
            {label: 'Pedido', fieldName: 'ID_de_Pedido__c', type: 'text', sortable: true},
            {label: 'Creación', fieldName: 'FechaCreacion', type: 'text', sortable: true},
            {label: 'Máx Entrega', fieldName: 'FechaMaxEntrega', type: 'text', sortable: true},
            {label: 'Claves', fieldName: 'Total_de_Claves__c', type: 'number', sortable: true},
            {label: 'Piezas', fieldName: 'Total_de_Piezas__c', type: 'number', sortable: true},
            {label: 'Costo', fieldName: 'costoPedido', type: 'currency', typeAttributes: {currencyCode: 'MXN'}, sortable: true},
            {label: 'Orden', type: 'button', initialWidth: 125, typeAttributes: {label: 'Ver Detalles', name: 'view_program', title: 'Click to View Program Details'}}
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
                    this.mostrarDetalles(component, records, false);
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
                // const action = component.get("c.getFilteredOrders");

                const action = component.get("c.getMisPedidos");
                const fechaInicio = component.get("v.fechaInicio");
                const fechaFin = component.get("v.fechaFin");
                action.setParams({ 
                    fechaInicio : new Date(fechaInicio),
                    fechaFin : new Date(fechaFin) 
                }); 
                action.setCallback(this, response => {
                    component.set("v.isLoading", false);
                    const state = response.getState();
                    if (state === "SUCCESS") {
                        const responseVal = response.getReturnValue();
 
                        responseVal.forEach(item => {
                            const { CreatedDate, Fecha_Limite_de_Entrega__c, Order_Line_Items__r = [] } = item;
                            if (!CreatedDate || !Fecha_Limite_de_Entrega__c) return;
                            const fechaCreacion = new Date(CreatedDate);
                            const fechaLimiteEntrega = new Date(Fecha_Limite_de_Entrega__c);
                            item.FechaCreacion = formatDate(fechaCreacion);
                            item.FechaMaxEntrega = formatDate(fechaLimiteEntrega);

                            let costoPedido = 0;
                            Order_Line_Items__r.forEach(oli => costoPedido += oli.Costo_Promedio__c && oli.Cantidad_de_Piezas__c ? oli.Costo_Promedio__c*oli.Cantidad_de_Piezas__c : 0);
                            item.costoPedido = costoPedido;
                        });
                        function formatDate(date) {
                            const day = date.getDate().toString().padStart(2, '0');
                            const month = (date.getMonth() + 1).toString().padStart(2, '0');
                            const year = date.getFullYear().toString();
                            return `${day}/${month}/${year}`;
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
        var sortedBy = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        const allData = component.get('v.allData');
        var cloneData = allData.slice(0);
        cloneData.sort((this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1)));
        
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
 
    clearDataBeforeCodeSearch : function (component, event) {
        component.set('v.clavesSeleccionadas', []);
        component.set('v.umusSeleccionadas', []);
        component.set('v.delegacionesSeleccionadas', []);
        component.set('v.pedidosSeleccionados', []);
        component.set('v.transportesSeleccionados', []);
        component.set('v.tipoDeClaveObj', {});
        component.set('v.tipoDeUMUObj', {});
        component.set('v.tipoDeDelegacionObj', {});
        component.set('v.tipoDePedidoObj', {});
        component.set('v.tipoDeTransporteObj', {});

        var appEvent = $A.get("e.c:limpiarParametrosDeFiltros"); 
        appEvent.setParams({"clearValues" : true}); 
        appEvent.fire();

        let allData = component.get("v.allData");
        component.set("v.filteredData", allData);
        this.preparePagination(component, allData);
    },

    searchRecordsByPedidoNumber : function (component) { 
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

    searchRecordsByDeliveryNumber : function (component) {
        let deliveryNumber = component.get("v.deliveryNumber"); 
        if (!$A.util.isEmpty(deliveryNumber)) {
            let allData = component.get("v.allData");
            let filteredData = allData.filter(function(record){ 
                const {Ordenes__r = []} = record;   
                if(Ordenes__r.length > 0){
                    return Ordenes__r.some((ord) => {
                        const { Folio_de_Entrega__c = null } = ord;
                        if(Folio_de_Entrega__c){
                            const containsFolio = [Folio_de_Entrega__c].includes(deliveryNumber);
                            if(!containsFolio) return containsFolio;
                        } else{ return false; }
                        return true;
                    });
                } 
            }); 
            component.set("v.filteredData", filteredData);
            this.preparePagination(component, filteredData);
        }
    },

    searchRecordsByRemisionNumber : function (component) {
        let remisionNumber = component.get("v.remisionNumber"); 
        if (!$A.util.isEmpty(remisionNumber)) {
            let allData = component.get("v.allData");
            let filteredData = allData.filter(function(record){ 
                const {Ordenes__r = []} = record;   
                if(Ordenes__r.length > 0){
                    return Ordenes__r.some((ord) => {
                        const { Folio_de_Remision__c = null } = ord;
                        if(Folio_de_Remision__c){
                            const containsRemision = Folio_de_Remision__c.includes(remisionNumber);
                            if(!containsRemision) return containsRemision;
                        } else{ return false; }
                        return true;
                    });
                } 
            });
            component.set("v.filteredData", filteredData);
            this.preparePagination(component, filteredData);
        }
    },

    searchRecordsByFilters : function (component) {
        const allData = component.get("v.allData");
        const claves = component.get("v.clavesSeleccionadas");
        const umus = component.get("v.umusSeleccionadas");
        const estados = component.get("v.estadosSeleccionados");
        const pedidos = component.get("v.pedidosSeleccionados");
        const transportes = component.get("v.transportesSeleccionados");

        if (claves.length > 0 || umus.length > 0 || estados.length > 0 || pedidos.length > 0 || transportes.length > 0) {
            const clavesArr = claves.map(obj => obj.Id);
            const umusArr = umus.map(obj => obj.Id);
            const estadosArr = estados.map(obj => obj.Id);
            const pedidosArr = pedidos.map(obj => obj.Id);
            const transportesArr = transportes.map(obj => obj.Id);

            const filteredData = allData.filter((pedido) => {
                const { Ordenes__r = [], Order_Line_Items__r = [], UMU__r = {}, Tipo_de_Pedido__c = null } = pedido;
                const { Clave_Presupuestal__c = null, Estado__c = null } = UMU__r;

                if(umusArr.length > 0){
                    const containsUmus = umusArr.includes(Clave_Presupuestal__c);
                    if(!containsUmus) return containsUmus;
                } 

                if(estadosArr.length > 0){
                    const containsEstados = estadosArr.includes(Estado__c);
                    if(!containsEstados) return containsEstados;
                } 

                if(pedidosArr.length > 0){
                    const containsPedidos = pedidosArr.includes(Tipo_de_Pedido__c);
                    if(!containsPedidos) return containsPedidos;
                }
                
                if(clavesArr.length > 0){
                    if(Order_Line_Items__r.length > 0){
                        return Order_Line_Items__r.some((oli) => {
                            const { Product__r = {} } = oli;
                            const { Product_Code_ID__c = null } = Product__r;
                            const containsClaves = clavesArr.includes(Product_Code_ID__c);
                            if(!containsClaves) return containsClaves;
                        });
                    }
                }

                if(transportesArr.length > 0){
                    if(Ordenes__r.length > 0){
                        return Ordenes__r.some((ord) => {
                            const { Folio_de_Entrega__c = null } = ord;
                            const containsTransportes = transportesArr.includes(Folio_de_Entrega__c);
                            if(!containsTransportes) return containsTransportes; 
                            return true;
                        });
                    } 
                } 

                return true;
            });

            component.set("v.filteredData", filteredData);
            this.preparePagination(component, filteredData);
            this.mostrarDetalles(component, filteredData, false);
            this.mostrarOcultarFiltros(component);
        } else{
            component.set("v.filteredData", allData);
            this.preparePagination(component, allData); 
        }
    },

    mostrarDetalles : function(component, data, selectedRow) { 
        const fechaInicio = component.get('v.fechaInicio');
        const fechaFin = component.get('v.fechaFin');
        const rangoDeFechas = `${fechaInicio} - ${fechaFin}`;

        const appEvent = $A.get("e.c:mostrarDetalles"); 
        appEvent.setParams({ 
            "fechasSeleccionadas" : JSON.stringify(rangoDeFechas),
            "mostrarDetallesGenerales" : selectedRow
        }); 
        appEvent.fire(); 

        // Pfff no me gusta usar application event, pero pueeeeees...  
        if(selectedRow){
            const appRowEvent = $A.get("e.c:mostrarDetallesEspecificos"); 
            appRowEvent.setParams({
                "data" : JSON.stringify(data)
            }); 
            appRowEvent.fire(); 
        } else{
            const appGralEvent = $A.get("e.c:mostrarDetallesGenerales"); 
            appGralEvent.setParams({
                "data" : JSON.stringify(data)
            }); 
            appGralEvent.fire(); 
        } 
    },

    getFilterData : function(component, data) {
        const umus = new Set();
        const claves = new Set();
        const estados = new Set();
        const pedidos = new Set();
        const transportes = new Set();

        data.forEach((orden) => {
            const { Ordenes__r = [], Order_Line_Items__r = [], UMU__r ={}, Tipo_de_Pedido__c = null} = orden;
            const {Clave_Presupuestal__c = null, Estado__c = null} = UMU__r;

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

            // Getting estados
            if (Estado__c) {
                const obj = {
                    Id: Estado__c,
                    Name: Estado__c,
                };
                if (![...estados].some((o) => o.Id === obj.Id)) {
                    estados.add(obj);
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

            Ordenes__r.forEach((ord) => {
                // Getting transportes
                const { Folio_de_Entrega__c = null } = ord;

                if (Folio_de_Entrega__c) {
                    const obj = {
                        Id: Folio_de_Entrega__c,
                        Name: Folio_de_Entrega__c,
                    };
                    if (![...transportes].some((o) => o.Id === obj.Id)) {
                        transportes.add(obj);
                    }
                }
            });

        });

        component.set('v.msClaves', Array.from(claves));
        component.set('v.msUMUs', Array.from(umus)); 
        component.set('v.msEstados', Array.from(estados));
        component.set('v.msPedidos', Array.from(pedidos)); 
        component.set('v.msTransportes', Array.from(transportes)); 
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