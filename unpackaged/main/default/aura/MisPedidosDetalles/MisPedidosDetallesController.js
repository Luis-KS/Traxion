({
    handleUpdateDetails : function(component, event, helper) {
        const rangoDeFechas = event.getParam('fechasSeleccionadas');
        component.set('v.rangoDeFechas', JSON.parse(rangoDeFechas));

        const mostrarDetallesGenerales = event.getParam('mostrarDetallesGenerales');
        component.set('v.mostrarDetallesGenerales', mostrarDetallesGenerales);
    }
})