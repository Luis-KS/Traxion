import { LightningElement, track, wire } from 'lwc';
import getUMUOptions from '@salesforce/apex/TestController.getUMUOptions';
import getDPN from '@salesforce/apex/DPNController.getDPN';

export default class TestLWC extends LightningElement {
    umus;
    prueba = [];
    error;
    message = "All good";
    showMessage = false;

    @track selectedUmus = '';

    handleSelect(event) {
        this.selectedUmus = event.target.value;
        console.log("Selected Option: ", this.selectedUmus);

        if (this.selectedUmus == 'Seleccionar Unidad Medica') {
            this.showMessage = false;
        } else {
            this.showMessage = true;
        }

    }



    // @wire(getUMUOptions)
    // wiredOptions({ error, data }) {
    //         if (data) {
    //             this.umus = data;
    //         } else if (error) {
    //             console.error(error);
    //         }
    //     }
    // connectedCallback() {
    //     getUMUOptions().then(response => {
    //         this.prueba = response;
    //         const elUmu = JSON.parse(response);
    //         this.umus = elUmu.Name;
    //         console.log("Unidad Medica: " + JSON.stringify(this.prueba));
    //     }).catch(error => {
    //         this.error = error;
    //     });
    // }

    ///////////////De aqui va el buscador de DPN
    key;

    theFinder
    @track DPNs;
    placeholder = "Buscar DPN";
    updateKey(event) {
        this.key = event.target.value;


    }


    handleSearch() {
        getDPN({ searchKey: this.key })
            .then(result => {
                this.DPNs = result;

            })
            .catch(error => {
                this.DPNs = null;
            });

    }

    cols = [
        { label: 'Clave', fieldName: 'clave__C', type: 'text' },
        { label: 'Nombre', fieldName: 'Name', type: 'text' },
        { label: 'UMU', fieldName: 'UMU__c', type: 'text' }

    ]
}