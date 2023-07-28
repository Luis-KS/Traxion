import { LightningElement, wire } from 'lwc';
import getDpn from '@salesforce/apex/VerDpnPedidoController.getDpn';

export default class PedidoNoOrdinario extends LightningElement {

    dpns;
    pedido = "NO HAY PEDIDOS GENERADOS AÚN";
    @wire(getDpn) wiredDpn({ data, error }) {
        if (data) {
            this.dpns = data;

        } else if (error) {
            console.log(error);
        }
    }

    handleNoOrdinario() {
        console.log(this.dpns, "Aqui estan las dpns");
    }


}