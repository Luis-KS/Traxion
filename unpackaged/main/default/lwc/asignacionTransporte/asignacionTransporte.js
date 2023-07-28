import { LightningElement, api, wire } from 'lwc';
import getEntregas from '@salesforce/apex/AsignadoTransporteController.getEntregas';
import updateEntregaAsignar from '@salesforce/apex/AsignadoTransporteController.updateEntregaAsignar';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';


export default class AsignacionTransporte extends LightningElement {
    @api isAsignado = false;
    @api idViaje;
    @api userId;
    datosEntrega;
    entregaASignada = false;


    @wire(getRecord, { recordId: USER_ID, fields: ['User.Id'] }) wiredUser({ data, error }) {
        if (data) {
            this.userId = data.fields.Id.value;
        } else if (error) {
            console.log(error);
        }
    }


    @wire(getEntregas, { idViaje: '$idViaje' }) entregasData({ data, error }) {
        if (data) {
            this.datosEntrega = data;
            console.log(this.datosEntrega, "Aqui esta la entrega");
        } else if (error) {
            console.log(error, "La data no esta llegando");
        }
    };

    handleNumeroViaje(event) {

        this.idViaje = event.target.value;
    }

    handleAsignar() {
        if (this.datosEntrega.length === 0) {
            //Muestra un mensaje de error si no encuentra el numero de viaje
            const toastErrorEvent = new ShowToastEvent({
                title: 'Error de Entrega',
                message: 'El Numero de viaje introducido es incorrecto, por favor verifique de nuevo o consulte con su administrador',
                variant: 'error'
            });
            this.dispatchEvent(toastErrorEvent);

        } else if (this.datosEntrega.length > 0) {
            // this.diasDePedido.forEach((record) => {
            this.datosEntrega.forEach((record) => {
                if (record.Entrega__r.Estado__c === 'No Asignado') {

                    //autorizar asignar la entrega
                    this.entregaASignada = true;


                    console.log(this.idViaje, this.userId, "Aqui estan los datos de user y viaje");
                }


            });

            if (this.entregaASignada) {
                updateEntregaAsignar({ idViaje: this.idViaje, userId: this.userId })
                    .then(result => { console.log(result, "Here is the result of update"); })
                    .catch(error => { console.log(error, 'here is the error') });

                //Muestra un mensaje de error si no encuentra el numero de viaje
                const toastSuccessEvent = new ShowToastEvent({
                    title: 'Entrega Asignada',
                    message: 'Su entrega ha sido asignada correctamente',
                    variant: 'success'
                });
                this.dispatchEvent(toastSuccessEvent);
                const isEntrega = true;
                this.dispatchEvent(new CustomEvent('entrega', { detail: isEntrega }));

            }

            this.isAsignado = true;
            console.log(this.datosEntrega, "aqui esta la data otravez");
        }


    }


}