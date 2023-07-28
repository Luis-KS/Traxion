import { LightningElement, track, api, wire } from 'lwc';
import getEntregas from '@salesforce/apex/AsignadoTransporteController.getEntregas';
import getEntregasAsignadas from '@salesforce/apex/EntreAsignadaController.getEntregasAsignadas';
import updateEntregaAsignar from '@salesforce/apex/AsignadoTransporteController.updateEntregaAsignar';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import LightningConfirm from 'lightning/confirm';
import desasignarEntrega from '@salesforce/apex/AsignadoTransporteController.desasignarEntrega';
import finalizarEntrega from '@salesforce/apex/AsignadoTransporteController.finalizarEntrega';
import { NavigationMixin } from 'lightning/navigation';



export default class AsignacionTransporteMenu extends LightningElement {
    @track tab1Active = true;
    @track tab2Active = false;
    //EntregaAsignada

    entrega;
    orderDataByUMUName = {};
    @api isentrega = false;
    isdisplay = false;
    entregaId;
    @track inputDisabled = false;

    get tab1Classes() {
        return {
            'tab-button': true,
            'active': this.tab1Active,
        };
    }

    get tab2Classes() {
        return {
            'tab-button': true,
            'active': this.tab2Active,
        };
    }

    handleTab1Click() {
        this.tab1Active = true;
        this.tab2Active = false;
    }

    handleTab2Click() {
        this.tab1Active = false;
        this.tab2Active = true;
    }




    ///////AsignacionDeTransporte
    @api isAsignado = false;
    @api idViaje = '';
    @api userId;
    datosEntrega;
    entregaASignada = false;


    @wire(getRecord, { recordId: USER_ID, fields: ['User.Id'] }) wiredUser({ data, error }) {
        if (data) {
            this.userId = data.fields.Id.value;
            this.inputDisabled = true;
        } else if (error) {
            console.log(error);
        }
    }


    // @wire(getEntregas, { idViaje: '$idViaje' }) entregasData({ data, error }) {
    //     if (data) {
    //         this.datosEntrega = data;
    //         this.entrega = data;

    //         if (this.entrega.length > 0) {
    //             this.isentrega = true;
    //         }


    //         console.log(this.datosEntrega, "Aqui esta la entrega");
    //     } else if (error) {
    //         console.log(error, "La data no esta llegando");
    //         this.inputDisabled = false;
    //     } else {
    //         this.inputDisabled = false;
    //     }
    // };

    handleNumeroViaje(event) {

        // this.idViaje = event.target.value;
        if (event.target.value.trim() !== '') {
            this.idViaje = event.target.value;
        } else {
            //Muestra un mensaje de error si no encuentra el numero de viaje
            // const toastEmptyField = new ShowToastEvent({
            //     title: 'Error de Entrega',
            //     message: 'Por favor introduzca un número de viaje',
            //     variant: 'error'
            // });
            // this.dispatchEvent(toastEmptyField);
            this.idViaje = '';
        }
    }


    async handleAsignar() {

        if (this.idViaje.length > 0) {
            getEntregas({ idViaje: this.idViaje })
                .then((result) => {
                    if (result) {
                        this.datosEntrega = result;
                        this.entrega = result;


                        if (this.entrega.length > 0) {
                            this.isentrega = true;
                            console.log("entra aqui con los malos");
                            //llama a hacer el update
                            this.handleDataAsignar();
                        } else {
                            if (this.datosEntrega.length === 0) {
                                //Muestra un mensaje de error si no encuentra el numero de viaje
                                const toastErrorEvent = new ShowToastEvent({
                                    title: 'Error de Entrega',
                                    message: 'El Numero de viaje introducido es incorrecto, por favor verifique de nuevo o consulte con su administrador',
                                    variant: 'error'
                                });
                                this.dispatchEvent(toastErrorEvent);

                            }
                        }
                    }
                })
                .catch((error) => {
                    console.log(error);
                    this.inputDisabled = false;
                    console.log("entra aqui con error");

                });
        } else {
            //Muestra un mensaje de error si no encuentra el numero de viaje
            const toastEmptyField = new ShowToastEvent({
                title: 'Error de Entrega',
                message: 'Por favor introduzca un número de viaje',
                variant: 'error'
            });
            this.dispatchEvent(toastEmptyField);
        }

    }

    handleDataAsignar() {
        if (this.datosEntrega.length > 0) {

            this.datosEntrega.forEach((record) => {

                record.records.forEach((item) => {
                    if (item.Entrega__r.Estado__c === 'No Asignado') {
                        this.entregaASignada = true;

                    }
                });



            });

            if (this.entregaASignada) {
                updateEntregaAsignar({ idViaje: this.idViaje, userId: this.userId })
                    .then(result => {
                        console.log(result, "Here is the result of update");

                        // update the "entrega" property with the newly assigned delivery data
                        getEntregasAsignadas({ userId: this.userId })
                            .then(result => {
                                // this.entrega = result;
                                // handleRefresh();

                                console.log(this.entrega, "Here is the updated delivery data");
                            })
                            .catch(error => {
                                console.log(error);
                            });
                    })
                    .catch(error => { console.log(error, 'here is the error') });

                //Muestra un mensaje de error si no encuentra el numero de viaje
                const toastSuccessEvent = new ShowToastEvent({
                    title: 'Entrega Asignada',
                    message: 'Su entrega ha sido asignada correctamente',
                    variant: 'success'
                });
                this.dispatchEvent(toastSuccessEvent);

                // set the "tab2Active" to true to render the "entrega" on the second tab
                this.tab1Active = false;
                this.tab2Active = true;
                this.isAsignado = true;
                this.inputDisabled = true;

            }



        }
    }


    @wire(getEntregasAsignadas, { userId: '$userId' }) entregas({ data, error }) {
        if (data && data.length > 0) {

            this.entrega = data;
            this.inputDisabled = true;
            console.log(this.entrega, " aqui esta la entrega");
            this.isentrega = true;

            this.tab1Active = false;
            this.tab2Active = true;
            this.isAsignado = true;
            this.inputDisabled = true;

        } else if (error) {
            this.inputDisabled = false;
            console.log(error);
        } else {
            this.isentrega = false;
            this.inputDisabled = false;
        }
    }




    async handleDesasignar() {
        const result = await LightningConfirm.open({
            message: 'Está removiendo su entrega la cual se marcará como no completada. ¿Desea Desasignar?',
            variant: 'headerless',
            label: 'Desasignar',
        });

        if (result) {
            const entregaId = this.entrega[0].records[0].Entrega__c;


            desasignarEntrega({ entregaId: entregaId })
                .then((result) => {

                    this.isentrega = false;
                    this.idViaje = '';

                    const removerEntrega = new ShowToastEvent({
                        title: 'Entrega Removida',
                        message: 'Su entrega ha sido removida correctamente',
                        variant: 'success'
                    });
                    this.dispatchEvent(removerEntrega);
                    this.inputDisabled = false;
                    // set the "tab1Active" to true to render the asignar on the first tab
                    this.tab1Active = true;
                    this.tab2Active = false;

                    location.reload();


                })
                .catch((error) => {
                    console.log(error);
                });


            console.log(entregaId, " Esta recibiendo EL Id de la entrega");
        } else if (!result) {
            console.log("El cancel esta funcionando");
        }


    }



    async handleFinalizarTransporte() {
        const result = await LightningConfirm.open({
            message: 'Por favor, asegurese de haber completado todas sus entregas antes de finalizar. ¿Desea finalizar su entrega?',
            variant: 'headerless',
            label: 'Finalizar Entrega',
        });



        if (result) {



            let finalizar = true;

            this.entrega.forEach((record) => {

                record.records.forEach((item) => {




                    console.log(item.Estatus__c, "El estado");
                    if (item.Estatus__c === 'Enviado' || item.Estatus__c === 'Llegada de Transporte' || item.Estatus__c === 'Preparando Envío') {

                        finalizar = false;

                    }
                });



            });


            if (!finalizar) {
                const noFinalizarEntrega = new ShowToastEvent({
                    title: 'No puede Finalizar',
                    message: 'Tiene entregas pendientes, aun no puede finalizar',
                    variant: 'warning'
                });
                this.dispatchEvent(noFinalizarEntrega);


                return;
            }



            const entregaId = this.entrega[0].records[0].Entrega__c;
            finalizarEntrega({ entregaId: entregaId })
                .then((result) => {

                    this.isentrega = false;
                    this.idViaje = '';

                    const finalizarEntregaToast = new ShowToastEvent({
                        title: 'Entrega Finalizada',
                        message: 'Ha completado sus entregas correctamente',
                        variant: 'success'
                    });
                    this.dispatchEvent(finalizarEntregaToast);
                    this.inputDisabled = false;
                    // set the "tab1Active" to true to render the asignar on the first tab
                    this.tab1Active = true;
                    this.tab2Active = false;

                    location.reload();

                })
                .catch((error) => {
                    console.log(error);
                });

        }


    }

    ////c/asignacionTransporte
    refreshPage() {
        // Refresh the page using the NavigationMixin
        return this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'Home'
            }
        });
    }


}