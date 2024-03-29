import { LightningElement, wire, track, api } from 'lwc';
import { subscribe, MessageContext } from 'lightning/messageService';
import SET_GENERAR_PEDIDOS_MENU from '@salesforce/messageChannel/set_generar_pedidos_menu__c';
import umuRecordSelected from '@salesforce/messageChannel/umu_record_selected__c';
import getCarritoData from '@salesforce/messageChannel/get_carrito_pedido__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import modalConfirmation from 'c/programConfirmationModal';

export default class UnidadMedicaView extends LightningElement {

    @wire(MessageContext)
    messageContext;

    isUnidadMedica = false;
    isGuardarClicked = false;
    isOrdenCreada = false;
    isSolicitarPedidos = false;
    error;
    unidadMedica = {};

    accountSelected = '';
    umuData = [];
    carrito = {};
    isPedidos = false;
    isUltimaVentantaOrdinario = false;
    userId;

    clavePresupuestal;
    tipoUmu;
    name;
    umu;
    @api
    tipoDePedido = '';
    numeroOficio = '';
    justificacion = '';
    delegacion;

    fileData = {};
    fileName = '';
    @track pdfFiles = [];

    @api firstName;

    // @wire(getRecord, {recordId: '$userId', fields: 'Contact.Name' })
    // firstName;

    get mostrarModalDetalles(){
        if(this.isOrdenCreada){
            return true;
        }else{
            return false;
        }
    }

    susbcribeToMessageChannel(){
        subscribe(
            this.messageContext,
            SET_GENERAR_PEDIDOS_MENU,
            (message) => this.handleMessage(message)
        );
    }

    handleMessage(message){
        this.isSolicitarPedidos = message.isSolicitarPedidos;
        if(message.isSolicitarPedidos){
            this.isUnidadMedica = true;
            this.isPedidos = false;
            this.isUltimaVentantaOrdinario = false;
        }else if(message.isPedidos){
            this.isUnidadMedica = true;
            this.isPedidos = this.tipoDePedido !== 'Ordinario';
            this.isUltimaVentantaOrdinario = this.tipoDePedido === 'Ordinario';
        }else{
            this.isUnidadMedica = false;
            this.isPedidos = false; 
        }
    }

    connectedCallback(){
        this.susbcribeToMessageChannel();
        this.susbcribeToMessageChannelUmu();
        this.susbcribeToMessageChannelCarrito();
    }

    handlePedidoNoOrdinario(){
        this.tipoDePedido = 'No Ordinario';
        this.dispatchEvent(new CustomEvent('nordinario'));
    }

    handlePedidoEspeciales(){
        this.tipoDePedido = 'Especiales';
        this.dispatchEvent(new CustomEvent('especiales'));
    }

    handlePedidoOrdinario(){
        this.tipoDePedido = 'Ordinario';
        this.dispatchEvent(new CustomEvent('ordinario', {
            detail: this.tipoDePedido
        }));
    }

    handleUmuData(event){
        this.umuData = event.detail;
    }

    handleMessageUmu(message){

        console.log("Inside handle message umu");
        console.log(JSON.parse(JSON.stringify(message.selectedUmu)));

        if(message.selectedUmu === 'Seleccionar Unidad Medica'){
            this.accountSelected = null;
        } else{
            this.unidadMedica = this.umuData.filter(item => message.selectedUmu.includes(item.Id));
            this.unidadMedica.forEach(item => {
                this.clavePresupuestal = item.Clave_Presupuestal__c;
                this.tipoUmu = item.Tipo_UMU__c;
                this.name = item.Name;
                this.umu = item.UMU__c;
                this.delegacion = item.Delegacion__c;
            });
        }
    }

    susbcribeToMessageChannelUmu(){
        subscribe(
            this.messageContext,
            umuRecordSelected,
            (message) => this.handleMessageUmu(message)
        );
    }

    handleSelectedAccountId(event){
        this.accountSelected = event.detail;
        console.log('Umu: ' + this.accountSelected);
    }

    handleUserId(event){
        this.userId = event.detail;
        console.log('Contact: ' + this.userId);
    }

    handleCreateOrdenData(message){
        let items = [];
        message.Carrito.forEach(element => {
            let item = {
                insumoId: element.Id,
                CantidadSolicitada: element.Cantidad
            };
            items.push(item);
        })

        this.carrito.Idcontacto = this.userId;
        this.carrito.IdUmu = this.accountSelected;
        this.carrito.TipoDePedido = this.tipoDePedido;
        this.carrito.ordenesDetails = items;
        console.log('Tipo de pedido: ' + this.tipoDePedido);
    }

    susbcribeToMessageChannelCarrito(){
        subscribe(
            this.messageContext,
            getCarritoData,
            (message) => this.handleCreateOrdenData(message)
        );
    }

    handleOnChange(event){
        this.numeroOficio = event.target.value;
    }

    handleTextAreaChange(event){
        this.justificacion = event.target.value;
    }

    acceptedFormats(){
        return ['.pdf'];
    }

    isObjEmpty(obj) {
        return Object.keys(obj).length === 0;
    }

    handleCancelar(){
        this.isGuardarClicked = !this.isGuardarClicked;
    }

    isInputValidate = true;

    validateInputs(elements) {
        let errorMessage = '';

        const fileElement = this.template.querySelector('lightning-input[data-name="uploadFile"]');
        this.isObjEmpty(this.pdfFiles) ? errorMessage = 'Este campo es obligatorio' : errorMessage = '';
        fileElement.setCustomValidity(errorMessage);
        fileElement.reportValidity();

        elements.forEach(element => {
            element.value == '' || element.value == null ? errorMessage = 'Este campo es obligatorio' : errorMessage = '';
            console.log('error: ' + (element.value == '' || element.value == null)  );
            console.log('error message: ' + errorMessage);
            element.setCustomValidity(errorMessage);
            element.reportValidity();
        });

        if(errorMessage == '') {
            if(this.isObjEmpty(this.carrito)) {
                errorMessage = 'Debes añadir al menos un insumo para procesar el pedido'
                this.showToast('Carrito vacío', errorMessage, 'error', 'pester');
            } else if(this.tipoDePedido == 'No Ordinario') {
                errorMessage = 'Debes seleccionar un tipo de pedido'
                this.showToast('Tipo de pedido', errorMessage, 'error', 'pester');
            }
        }

        // console.log('error message: ' + errorMessage);
        console.log('this.isInputValidate before: ' + this.isInputValidate);
        this.isInputValidate = (errorMessage === '' && !this.isObjEmpty(this.pdfFiles) 
        && elements[0].value && elements[1].value);
        console.log('this.isInputValidate after: ' + this.isInputValidate);
    }

    extraData;

    async handleGuardar(){
        // console.log("Inside handle guardar");
        // console.log('Numero oficio: ' + this.numeroOficio);
        // console.log('Tipo pedido: ' + this.tipoDePedido);

        if(this.tipoDePedido != 'Ordinario') {
            const inputs = this.template.querySelectorAll('.noOrdinaryField');
            console.log('inputs:  ' + inputs.length)
            this.validateInputs(inputs);

            if(!this.isInputValidate) return;
        }
        console.log(JSON.parse(JSON.stringify(this.carrito)));

        let isNoOrdinario = this.tipoDePedido != 'No Ordinario' ? true: false;
        this.carrito.TipoDePedido = this.tipoDePedido;
        this.carrito.numeroOficio = this.numeroOficio;
        this.carrito.justificacion = this.justificacion;

        // if(isNoOrdinario || this.tipoDePedido == 'Ordinario'){ 
        //     console.log('Tamo aquiiii ' + this.isOrdenCreada + this.isGuardarClicked);
            // const order = await crearOrden({payload: JSON.stringify([this.carrito])}).then(result =>{
            //     return result;
            // }).catch(error =>{
            //     console.log('An error has occured: ' + error.getMessage());
            // });
            // const orderIds = [];
            // order.forEach((ord) => {
            //     orderIds.push(ord.Id);
            // });

            // generarPdf({orderIds: orderIds}).then(result => {
            //     console.log('Se ha generado exitosamente: ');
            //     console.log(JSON.parse(JSON.stringify(result)));
            // }).catch(error =>{
            //     console.log('An error has occured: ' + error.getMessage());
            // });

            // if(!this.isObjEmpty(this.fileData)){
            //     this.fileData.recordId = order[0].Id;
            //     const {filename, base64, recordId} = this.fileData;
            //     await uploadFile({base64: base64, filename: filename, recordId: recordId});
            // }

            // if(this.tipoDePedido == 'Ordinario'){
            //     console.log('Inside pedido ordinario');
            //     const isCreated = await this.handleGeneracionDePedido(order);
            //     console.log(isCreated);
            //     if(!isCreated){ return;}
            // }
            // this.isGuardarClicked = false;
            // this.showToast('Success', 'Orden ha sido creada.', 'Success', 'pester');
            
            // setTimeout(() => {
            //     location.reload();
            // }, 200);
        // }else{
            // let isTipoDePedido = this.tipoDePedido == 'No Ordinario' ? '- Debes seleccionar un tipo de pedido.': ''; 
            // button.disabled = false;
            // console.log("Error Tipo pedido");
            // LightningAlert.open({
            //     message: isTipoDePedido,
            //     theme: 'error',
            //     label: 'Error!',
            // });
        // }
        
        this.extraData = {
            orderType: 'Ordinario/NoOrdinario',
            fileData: this.pdfFiles
        };

        const modal = this.template.querySelector("c-program-confirmation-modal");
        modal.show();
        //this.openConfirmationModal(this.carrito, extraData);
    }

    // async openConfirmationModal(carrito, extraData) {
    //     try {
    //       const result = await modalConfirmation.open({
    //         size: 'small',
    //         carrito: carrito,
    //         extraData: extraData
    //       });
    //       console.log(result);
    //     } catch (error) {
    //       console.error('Error opening modal:', error);
    //     }
    // }

    showToast(title, message, variant, mode) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(event);
    }

    readFile(fileSource) {
      return new Promise((resolve, reject) => {
        const fileReader = new FileReader();
        const Filename = fileSource.name;
        fileReader.onerror = () => reject(fileReader.error);
        fileReader.onload = () => resolve({ Filename, VersionData  : fileReader.result.split(',')[1]});
        fileReader.readAsDataURL(fileSource);
      });
    }

    async handleUploadFinished(event) {
      this.pdfFiles = await Promise.all(
        [...event.target.files].map(file => this.readFile(file))
      );
    }

    handleDeletePdf(event){
        console.log("file name to del: ", this.pdfFiles[event.target.dataset.index].Filename);
        console.log("# files before: ", this.pdfFiles.length);

        this.pdfFiles.splice(event.target.dataset.index,1);

        console.log("# pdfFiles: ", this.pdfFiles.length);
    }

    // handleUploadFinished(event) {
    //     let files = event.target.files;

    //     if (files.length > 0) {
    //         let filesName = '';

    //         for (let i = 0; i < files.length; i++) {
    //             let file = files[i];

    //             filesName = filesName + file.name + ',';

    //             let freader = new FileReader();
    //             freader.onload = f => {
    //                 let base64 = 'base64,';
    //                 let content = freader.result.indexOf(base64) + base64.length;
    //                 let fileContents = freader.result.substring(content);
    //                 this.pdfFiles.push({
    //                     Filename: file.name,
    //                     VersionData: fileContents
    //                 });
    //             };
    //             freader.readAsDataURL(file);
    //         }

    //         this.fileNames = filesName.slice(0, -1);
    // }
}