import { api, LightningElement, wire } from 'lwc';
import getUmu from '@salesforce/apex/UmuController.getUmu';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import { publish, subscribe, MessageContext } from 'lightning/messageService';
import umuRecordSelected from '@salesforce/messageChannel/umu_record_selected__c';
import orderType from '@salesforce/messageChannel/order_type__c';

export default class ListaUnidadMedica extends LightningElement {

    @wire(MessageContext)
    messageContext;

    @api userId;
    umuOptions;
    selectedUmus = '';
    payload = [];
    showMessage = false;
    isNoOrdinario = false;
    persistentData = null;

    @wire(getRecord, {
        recordId: USER_ID,
        fields: ['User.Id', 'User.ContactId']
    }) wiredUser({ error, data }) {

        if (data) {
            this.userId = data.fields.Id.value;
            //console.log('Contact Data: ' + JSON.stringify(data.fields.ContactId.value));
            this.dispatchEvent(new CustomEvent('userid', {
                detail: data.fields.ContactId.value
            }));
        } else if (error) {
            console.log(error);
        }
    }

    @wire(getUmu, { userId: '$userId' }) umuAssigned({ data, error }) {
        if (data) {
            this.umuOptions = data;
            this.dispatchEvent(new CustomEvent('umudata', {
                detail: data
              }));
        } else if (error) {
            console.log(error, "tenemos errores");
        }
    };

    publishMessage(){
        const payload = {
            selectedUmu: this.selectedUmus
        };
        publish(this.messageContext, umuRecordSelected, payload);
    }

    handleSelect(event) {
        this.selectedUmus = event.target.value;
        //this.publishMessage();
        if (this.selectedUmus == 'Seleccionar Unidad Médica') {
            this.showMessage = false;
            this.dispatchEvent(new CustomEvent('display', { detail: this.showMessage }));
        } else {
            this.showMessage = true;
            this.dispatchEvent(new CustomEvent('accountid', { detail: this.selectedUmus }));
            this.handleSaveProgress();
        }
        const payload = {
            selectedUmu: this.selectedUmus
        };
        console.log('payload: ' + JSON.stringify(payload));
        publish(this.messageContext, umuRecordSelected, payload);

        const payload2 = {
            isNoOrdinario: this.isNoOrdinario
        };
        console.log('payload 0: ' +  payload.isNoOrdinario);
        publish(this.messageContext, orderType, payload2);
    }

    connectedCallback() {
        console.log(localStorage.getItem('3'));
        if(localStorage.getItem('3') != null){
            this.persistentData = localStorage.getItem('3');
            const parsedData = JSON.parse(localStorage.getItem('3'));
            this.selectedUmus = parsedData.selectedUmus;
        } else {
            this.selectedUmus = 'Seleccionar Unidad Médica';
        }
    }

    rendered = 0;

    renderedCallback() {
        if(this.rendered <= 1) {
            const selectElement = this.template.querySelector('select');
            if (selectElement && this.selectedUmus !== 'Seleccionar Unidad Médica') {
                const options = selectElement.querySelectorAll('option');
    
                options.forEach(option => {
                    if (option.value === this.selectedUmus) {
                        option.selected = true;
                        this.handleSelect({target: option});
                    }
                });
            }
            console.log('select element: ' + this.rendered);
            this.rendered += 1;
        }
    }

    handleSaveProgress() {
        if(this.selectedUmus != 'Seleccionar Unidad Médica') {
            const dataToLoad = {
                selectedUmus: this.selectedUmus
            }

            localStorage.setItem('3', JSON.stringify(dataToLoad));
            this.persistentData = localStorage.getItem('3');
            console.log('persistent data: ' + this.persistentData);
        }
    }
}