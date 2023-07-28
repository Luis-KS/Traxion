import { LightningElement, track } from 'lwc';


export default class PedidoOrdinario extends LightningElement {

    //Aqui vamos a crear las funciones validando con el calendario, donde se daran las opciones de mostrar texto y habilitar el boton para solicitar pedido ordinario
    pedido = "NO HAY PEDIDOS GENERADOS AÚN";
    fechaApertura = "Próxima Fecha de Apertura";
    fecha = "18 de abril del 2023 de 7:00 a 16:00";

    // @track showDatePicker = false;
    // @track selectedDate;

    // handleCalendario() {
    //     this.showDatePicker = true;
    // }

    // handleDateChange(event) {
    //     this.selectedDate = event.target.value;
    //     this.showDatePicker = false;
    // }

    @track selectedDate;

    handleCalendario(event) {
        this.selectedDate = event.detail.value;
    }



}