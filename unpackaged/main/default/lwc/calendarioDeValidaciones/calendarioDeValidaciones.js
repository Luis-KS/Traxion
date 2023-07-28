import { LightningElement, wire } from 'lwc';
import getCalendarioValidaciones from '@salesforce/apex/CalendarioDeValidacionesController.getCalendarioValidaciones';

export default class CalendarioDeValidaciones extends LightningElement {

    diasDePedido;
    value = [];
    isCalendar = false;
    @wire(getCalendarioValidaciones) calendarioValidaciones({ data, error }) {
        if (data) {
            this.diasDePedido = data;

            this.diasDePedido.forEach((record) => {

                const dateString = record.Fecha__c;
                const [year, month, day] = dateString.split('-');
                const formattedDate = `${month}/${day}/${year}`;
                this.value.push(formattedDate);

            });

            console.log(this.diasDePedido, "Aqui vamos pues");
        } else if (error) {
            console.log(error);
        }
    }



    handleSolicitarPedido() {


        this.isCalendar = !this.isCalendar;

        this.value.forEach((record) => {
            console.log(record);
        });
    }






}