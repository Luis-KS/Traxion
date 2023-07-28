import { LightningElement, track } from 'lwc';
import getDisponibilidadSkus from '@salesforce/apex/UserContactClass.getDisponibilidadSkus';

export default class ProbarDisponibilidad extends LightningElement {


    @track result;

    handleButtonClick() {
        const skus = ["12345asdas", "12344asdas"];
        const jsonBody = JSON.stringify(skus);

        getDisponibilidadSkus({ jsonData: jsonBody })
            .then(result => {
                this.result = JSON.stringify(result, null, 2);
                console.log(this.result);
            })
            .catch(error => {
                console.error(error);
            });
    }

}