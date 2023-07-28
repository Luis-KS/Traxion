import { LightningElement, wire, api, track } from 'lwc';
import getUmu from '@salesforce/apex/AnsTransporteController.getUmu';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import transferOwnership from '@salesforce/apex/TransferInformationService.transferOwnership';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOrdersBeforeTransfer from '@salesforce/apex/TransferInformationService.getOrdersBeforeTransfer'

export default class AuxiliarRecibir extends LightningElement {

    @api userId; // = '0053K000003CVi6QAG';
    @track umuAsignada;
    isOrden = false;
    showDialogRecibirTransf = false;
    codigo;
    datosRecibo;
    isTransferido = false;



    //Uncoment and remove userId for production
    @wire(getRecord, { recordId: USER_ID, fields: ['User.Id'] }) wiredUser({ data, error }) {
        if (data) {
            this.userId = data.fields.Id.value;
        } else if (error) {
            console.log(error);
        }
    }

    @wire(getUmu, { userId: '$userId' }) wiredUmu({ data, error }) {
        if (data) {

            this.umuAsignada = data.map(item => ({...item, showOrden: false }));

        } else if (error) {
            console.log(error, "UMU auxiliar having error");
        }
    }

    handleUmu(event) {
        const title = event.currentTarget.dataset.title;
        const item = this.umuAsignada.find(
            item => item.Account.Name === title
        );
        item.showOrden = !item.showOrden;



    }

    handleRecibirtransferencia() {
        const dialog = this.template.querySelector('c-avonni-dialog');
        dialog.show();
    }

    handleCancel() {
        const dialog = this.template.querySelector('c-avonni-dialog');
        dialog.hide();
    }

    handleRecibirtransferencia() {

        this.showDialogRecibirTransf = true;
    }

    handleCerrarRecibirTransf() {
        this.showDialogRecibirTransf = false;
        this.isTransferido = false;
    }

    //Asigna transferencia


    handleOrdenesAntesTransferencia() {

        getOrdersBeforeTransfer({ uniqueCode: this.codigo })
            .then((result) => {
                const datos = JSON.parse(result);
                this.datosRecibo = datos;
                console.log('A ver si ta la fecha',JSON.stringify(datos));
                // this.itemQuantity = datos[0].Cantidad_de_Cajas_en_la_Orden__c;
                console.log(this.datosRecibo, "Lo que llego")
                this.isTransferido = true;


            }).catch((error) => {
                console.log(error);
            });

    }


    handleAsignar() {


        if (this.receivedValues.length !== this.datosRecibo.length) {

            const toastWarningTranf = new ShowToastEvent({
                title: 'Totalidad de Ordenes',
                message: 'Por favor valide todas las deliveries que está recibiendo',
                variant: 'warning'
            });
            this.dispatchEvent(toastWarningTranf);
            return;
        }



        const cajasData = this.receivedValues.reduce((result, { orderId, selected }) => {
            result.orders[orderId] = selected;
            return result;
        }, { orders: {} });




        const cajasJsonData = JSON.stringify(cajasData);

        console.log("Entramos al button");

        //Uncomment from here
        transferOwnership({ uniqueCode: this.codigo, newOwnerId: this.userId, ordenCantidadDeCajasFaltantesJSON: cajasJsonData })
            .then((result) => {
                const recibo = result;

                const toastTransferido = new ShowToastEvent({
                    title: 'Resultado De transferencia',
                    message: recibo,
                    variant: 'success'
                });
                this.dispatchEvent(toastTransferido);


            }).catch((error) => {
                const recibo = error;

                console.log(error);
                const toasterrorTranf = new ShowToastEvent({
                    title: 'Resultado De transferencia',
                    message: recibo.body.message,
                    variant: 'error'
                });
                this.dispatchEvent(toasterrorTranf);
            });

        //espera 2 seg para recargar
        setTimeout(() => {
            window.location.reload();
        }, 2000);
    }

    handleValorCodigoTranf(event) {
        this.codigo = event.target.value;
    }


    //////////c/asignacionTransporte
    //////////////c/asignacionTransporte

    @track receivedValues = [];

    handleItemQuantity(event) {
        const { orderId, selectedValue, cajas } = event.detail;
        const receivedData = { orderId: orderId, selected: selectedValue, cajas: cajas };

        const list = [...this.receivedValues];
        list.push(receivedData);
        this.receivedValues = list;

        console.log('DATA:' + JSON.stringify(this.receivedValues));

        // this.receivedValues.push(receivedData);
    }

    handleDeleteItemQuantity(event) {
        const orderId = event.detail;
        console.log('Order id: ', orderId);
        const nuevaLista = [...this.receivedValues];
        // buscar item la lista
        const item = this.receivedValues.find(element => element.orderId == orderId);
        nuevaLista.pop(item);

        //actualizar lista original
        this.receivedValues = nuevaLista;







    }


}