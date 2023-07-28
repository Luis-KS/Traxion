import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class AuxiliarRecibirTransferencia extends LightningElement {
    @api cantidadCajas;
    @api estado;
    @api orderNumber;
    @api fechaMaxima;
    @api subalmacen;
    @api umu;
    isAgregado = false;
    isDisabled = false;


    @track itemName;
    // @track itemQuantity = cantidadCajas;
    itemId;
    quantityReceived;


    @track selectedQuantityValue = 0;


    //getters
    get formattedDate() {
        const options = { day: 'numeric', month: 'long', year: 'numeric', locale: 'es-ES' };
        console.log('Fecha en Max. Entrega',new Date(this.fechaMaxima).toLocaleString(undefined, options));
        console.log('La fecha',this.fechaMaxima);
        return new Date(this.fechaMaxima).toLocaleString(undefined, options);
    }

    // connectedCallback() {
    //     this.selectedQuantityValue = this.cantidadCajas;
    // }

    handleInputPiezasFaltantes(event) {
        this.selectedQuantityValue = event.target.value;


    }

    handleAdd() {
        if (this.selectedQuantityValue < this.cantidadCajas) {
            this.selectedQuantityValue++;
        }
        // this.dispatchEvent(new CustomEvent('value', { detail: this.selectedQuantityValue }));
    }

    handleSubstract() {
        if (this.selectedQuantityValue > 0) {
            this.selectedQuantityValue--;
        }


        // this.dispatchEvent(new CustomEvent('value', { detail: this.selectedQuantityValue }));
    }

    handleCheckboxAdd(event) {
        const checkAdd = event.target.value;
        this.isAgregado = !this.isAgregado;
        var datos = { orderId: this.orderNumber, selectedValue: this.selectedQuantityValue, cajas: this.cantidadCajas };
        if (this.isAgregado) {
            if (this.selectedQuantityValue > this.cantidadCajas) {

                this.isAgregado = false;

                const toastWarningTranf = new ShowToastEvent({
                    title: 'Cantidad de Cajas',
                    message: 'La cantidad de cajas recibidas no puede ser mayor al número de cajas enviadas',
                    variant: 'warning'
                });
                this.dispatchEvent(toastWarningTranf);

            } else {

                this.isDisabled = true;
                this.dispatchEvent(new CustomEvent('value', { detail: datos }));
            }

        } else {
            this.isDisabled = false;
            this.dispatchEvent(new CustomEvent('delete', { detail: this.orderNumber }));
        }

    }
}