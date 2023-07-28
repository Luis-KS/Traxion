import { LightningElement, api } from 'lwc';

export default class AuxiliarOrdenesLotesItem extends LightningElement {
    @api
    lotes;
    @api
    insumo;

    handleEdit(event){
        const loteId = event.target.dataset.id;
        const cantidad = event.target.dataset.cantidad;
        
        this.dispatchEvent(new CustomEvent('edit', {
            detail: {
                Id: loteId,
                cantidadPiezas: cantidad,
                insumo: this.insumo
            }
        }));
    }
}