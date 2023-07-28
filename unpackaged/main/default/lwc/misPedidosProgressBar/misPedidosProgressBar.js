import { LightningElement, api } from 'lwc';

export default class MisPedidosProgressBar extends LightningElement {
    errorSteps = [];
    warningSteps = []; 
    disabledSteps = [];
    @api datosDeSeguimiento;

    get completedSteps() {  
        const completdSteps = [];
        for (let i = 0; i < this.datosDeSeguimiento.length; i++) {
            completdSteps.push(JSON.stringify(i));
        }
        return completdSteps; 
    }
}