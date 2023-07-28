import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class MyModal extends LightningModal {
    @api guardarData = {};
    isDataLoading = false;

    handleOkay() {
        localStorage.removeItem("Data");

        localStorage.setItem("Data", JSON.stringify(this.guardarData));
        this.close('okay');      
    }

    handleCancel(){
        this.close('cancel');
    }

}