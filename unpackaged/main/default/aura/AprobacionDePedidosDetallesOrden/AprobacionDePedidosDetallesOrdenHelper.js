({
    
    renderAllRowData : function(component, rowData) {
        this.renderTitulo(component, rowData);
        this.renderInformacionGeneral(component, rowData);
        this.renderJustificacionDocumentos(component, rowData);
    },
    
    renderTitulo : function(component, rowData) {
        const {Tipo_de_Pedido__c = null, Folio_Control__c = null, ID_de_Pedido__c = null, UMUName = null, Contacto__r = {}} = rowData; 
        const {Name = null} = Contacto__r;
        const rowTitulo = {
            tipo : Tipo_de_Pedido__c,
            detalle : Folio_Control__c && ID_de_Pedido__c && UMUName ? `${Folio_Control__c} | ${ID_de_Pedido__c} | ${UMUName}`
                    : ID_de_Pedido__c && UMUName ? `${ID_de_Pedido__c} | ${UMUName}` : null,
            nombre : Name
        } 
        component.set('v.rowTitulo', rowTitulo);
    },

    renderInformacionGeneral : function(component, rowData) {
        const {UMU__r = {}, Fecha_de_Creacion__c = null} = rowData; 
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
        populateArr(Fecha_de_Creacion__c, 'Fecha de Solicitud:');
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

    renderDataTable : function(component, rowItems) {

        console.log("PRINTING ROW ITEMS");
        console.log(rowItems);

        const sortedDataTable = [];
        const selectedTab = component.get('v.selTab');

        function filterArrayOfObj(estatus){
            rowItems.forEach(function(oli){
                if(oli.Estatus_Aprobaci_n__c === selectedTab){
                    oli.EstatusActivo = true;
                }
                if(oli.Estatus_Aprobaci_n__c === estatus){
                    sortedDataTable.push(oli);
                }
            });
        }
        
        switch (selectedTab) {
            case 'Pendiente':
                filterArrayOfObj('Pendiente');
                filterArrayOfObj('Aprobado');
                filterArrayOfObj('Rechazado');
                break;
            case 'Aprobado':
                filterArrayOfObj('Aprobado');
                filterArrayOfObj('Pendiente');
                filterArrayOfObj('Rechazado');
                break;
            case 'Rechazado':
                filterArrayOfObj('Rechazado');
                filterArrayOfObj('Aprobado');
                filterArrayOfObj('Pendiente');
                break;
        }

        console.log(selectedTab);
        console.log(JSON.parse(JSON.stringify(sortedDataTable)));
        component.set('v.sortedDataTable', sortedDataTable);
        component.set('v.hasBeenRendered', true);
    }


})