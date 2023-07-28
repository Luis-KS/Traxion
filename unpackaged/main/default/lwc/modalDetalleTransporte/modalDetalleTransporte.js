import LightningModal from 'lightning/modal';

export default class ModalDetalleTransporte extends LightningModal {
    handleOkay() {
        this.close('okay');
    }
}