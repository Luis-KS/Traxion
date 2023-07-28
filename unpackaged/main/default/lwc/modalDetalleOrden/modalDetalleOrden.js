import { LightningElement, api } from 'lwc';
import LightningModal from 'lightning/modal';
import { NavigationMixin } from 'lightning/navigation';
import getUmusById from '@salesforce/apex/UmuController.getUmusById';
import CONTACT_NAME_FIELD from '@salesforce/schema/Contact.FirstName';
import { getRecord } from 'lightning/uiRecordApi';

export default class ModalDetalleOrden extends NavigationMixin(LightningElement) {
    @api carrito;
    @api programa;
    @api esPrograma;

    folio = null;
    title = null;
    owner = null;
    umu = null;
    delegation = null;
    orderType = null;
    showModal = false;
    isDataLoading = true;

    @api show() {
      this.showModal = true;
    }

    renderedCallback() {

        console.log('SUMMARY MODAL');
        if(this.showModal) {
            console.log('carrito: ');
            console.log(JSON.stringify(this.carrito));
            console.log('programs: ');
            console.log(this.programa);
            console.log('isPrograms: ');
            console.log(this.esPrograma);

            if(this.esPrograma) {
                this.title = `Gracias, has cargado satisfactoriamente el programa ${this.programa}`;
                let unformattedFolio = this.carrito[0].Pedido__r.ID_de_Pedido__c;
                console.log(unformattedFolio);
                this.folio = unformattedFolio.substring(0, 5);
                this.isDataLoading = false;
            } else {
                this.title = 'GRACIAS, has realizado tu solicitud de pedido con éxito';
                this.folio = this.carrito[0].Pedido__r.ID_de_Pedido__c;
                this.orderType = this.carrito[0].Tipo_de_Pedido__c;
                this.getUmusById();
            }

            this.owner = this.carrito[0].Contacto__r.Name;
        }
    }

    getUmusById() {
        const umuId = [];
        umuId.push(this.carrito[0].UMU__c);

        getUmusById({ umuIds: umuId })
        .then(result => {
            if(result) {
                this.umu = result[0].Clave_Presupuestal__c + ' - ' + result[0].Name;
                this.delegation = result[0].Delegaci_n__c;
            }
            this.isDataLoading = false;
        }).catch(error => {
            console.log(JSON.stringify(error));
        })
    }

    get fechaFormateada() {
        const months = [
            'ENE',
            'FEB',
            'MAR',
            'ABR',
            'MAY',
            'JUN',
            'JUL',
            'AGO',
            'SEP',
            'OCT',
            'NOV',
            'DEC'
        ];

        const date = new Date();
        const fechaCompleta = date.getDate() + '/' + months[date.getMonth()] + '/' + date.getFullYear();

        return fechaCompleta;
    }

    handleRegresar(){
        //this.showModal = false;
        setTimeout(() => {
            location.reload();
        }, 200);
    }
}