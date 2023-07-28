import { LightningElement, api } from 'lwc';

export default class Clave extends LightningElement {

    @api producto; 

    handleDelete(){
        this.dispatchEvent(new CustomEvent('delete', {
            detail: this.producto
        }));
    }
}