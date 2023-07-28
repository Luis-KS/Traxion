({


    onRender : function(component, event, helper) { 
        const hasBeenRendered = component.get('v.hasBeenRendered');
        if(!hasBeenRendered){
            console.log("INSIDE ON RENDER");
            
            const rowData = component.get('v.rowData');
            if(!rowData) return;
            helper.renderAllRowData(component, rowData);

            const rowItems = component.get('v.rowItems');
            if(!rowItems) return;
            helper.renderDataTable(component, rowItems);

            component.set('v.hasBeenRendered', true);
        }
    }

})