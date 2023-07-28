import { LightningElement, track, wire, api } from 'lwc';
import getOrderProduct from '@salesforce/apex/ReplaneacionController.getOrderProduct'

export default class ReplaneacionInsumos extends LightningElement {

    @api orderid;
    @api transporte;
    @track ordenesItems;
    @track selectedProduct;
    keyBuscar = '';
    divClass = 'hidden';
    botonInformacionDeLotesText = 'Mostrar Informacion de Lotes';
    @track filteredProducts = [];

    @wire(getOrderProduct, { orderId: '$orderid' }) getOrdenes({ data, error }) {
        if (data) {
            this.ordenesItems = data;
            console.log(data);
            console.log(JSON.stringify(this.transporte));
            const losDatos = data;
            this.filteredProducts = this.ordenesItems;
            console.log(this.filteredProducts, " Los datos estan aqui");

        } else if (error) {
            console.log(error);
        }
    }


    handleBuscar(event) {

        this.filteredProducts = this.ordenesItems;

        this.keyBuscar = event.target.value.toLowerCase();

        console.log(this.keyBuscar, " el key");
        this.filteredProducts = this.ordenesItems.filter((product) => {
            console.log(product.Product__r.Name);
            product.Product__r.Name.toLowerCase().includes(this.keyBuscar)
            if (product.Product__r.Name.toLowerCase().includes(this.keyBuscar)) {
                return product;
            }
        });

    }

   

    toggleLotes() {
        this.divClass = this.divClass === 'hidden' ? '' : 'hidden';
        if (this.divClass === 'hidden') {
            this.botonInformacionDeLotesText = 'Mostrar Informacion de Lotes'
        } else {
            this.botonInformacionDeLotesText = 'Ocultar Informacion de Lotes'
        }
    }

    get hayLotes() {
        if (selectedProduct.Informacion_De_Lotes__r.lenght > 0) {
            return true;
        }

        return false;
    }


}