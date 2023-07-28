import { LightningElement, wire, api } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import getEntregasAsignadas from '@salesforce/apex/EntreAsignadaController.getEntregasAsignadas';

export default class EntregaAsignada extends LightningElement {
    @api datosEntrega;
    @api isentrega = false;
    @api userId;


    @wire(getRecord, { recordId: USER_ID, fields: ['User.Id'] }) wiredUser({ data, error }) {
        if (data) {
            this.userId = data.fields.Id.value;
        } else if (error) {
            console.log(error);
        }
    }

    @wire(getEntregasAsignadas, { userId: '$userId' }) entregas({ data, error }) {
        if (data && data.length > 0) {
            this.datosEntrega = data;
            this.isentrega = true;
            console.log(this.datosEntrega, "Aqui estamos en el componente entrega Asignada");
            console.log(this.userId, "aqui esta el user");
        } else if (error) {
            console.log(error);
        }
    }


}