import { LightningElement, track, api, wire } from 'lwc';
import saveImage from '@salesforce/apex/ImageUploadController.saveImage';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import createTransferInformation from '@salesforce/apex/TransferInformationService.createTransferInformation';
import createTransferInformation from '@salesforce/apex/TransferInformationService.createTransferInformation';
import registrarOrden from '@salesforce/apex/OrderController.registrarOrden';
import getUmuOrders from '@salesforce/apex/AnsTransporteController.getUmuOrders';
import LightningConfirm from 'lightning/confirm';
import getProductsOrder from "@salesforce/apex/AnsTransporteController.getProductsOrder"
import registrarOrdenParcial from '@salesforce/apex/OrderController.registrarOrdenParcial';


const columns = [
    // { label: 'Orden ID', fieldName: 'Id' },
    { label: 'Fecha Maxima de Entrega', fieldName: 'Fecha_Maxima_de_Entrega__c', type: 'date' },
    { label: 'Tipo de Orden', fieldName: 'Tipo_de_Pedido__c' },
    { label: 'Total de Piezas', fieldName: 'Total_de_Piezas__c' },
    { label: 'Estado de Pedido', fieldName: 'Estatus__c' },
    {
        label: 'Recibir Orden',
        type: 'button',
        initialWidth: 135,
        typeAttributes: {
            label: 'Recibir Orden',
            title: 'recibir',
            name: 'view_details',
            variant: 'brand',
            class: 'slds-m-left_x-small',
            disabled: false
        },
        cellAttributes: {
            class: { fieldName: 'displayButtonClass' }
        }
    }
];

export default class ChekinButtonEntrega extends LightningElement {
    cameraInitialized = false;
    showSpinner = false;
    showError = false;
    errorMessage = '';
    codigoTransfer;

    @api userId;
    @track base64Image;
    @track renderKey;
    @api parentId;
    @api ischeckin;
    @api orderId;
    @api entregaName;
    @api umuname;
    @api recordIds; // = 'a0J3K00000CELfxUAH,a0J3K00000CEKQaUAP';
    @api umuId; // = "0013K00000y6NnxQAE";
    @track isTransferir = false;
    @track isCheckinActive = true;
    @track isCheckinActiveParcial = true;
    isEntregar = false;
    isFirmar = false;
    isRechazar = false;
    isRecibir = false;
    isOpenTransferir = false;
    isConfirmarEntrega = false;
    isEnviadoFirma = false;
    @track insumosParcial;
    //entrega parcial variables
    isParcial = false;
    @track showInsumos = true;
    @track showEvidencia = false;
    @track showNotas = false;
    @track selectedParcialOption = '';
    @track isotraDesviacion = false;
    @track base64Image;
    isEvidenciaCargada = false;
    //crear boton parcial
    isOptionSelected = false;
    isMaterialesAgregados = false;
    isEvidenciaAgregada = false;
    isDisplayParcialButton = false;
    @track isEnviadoParcial = false;
    selectedDate;
    selectedTime;
    ordenItemsUpdates = [];
    @track arrayParcialItem = [];
    loteNumber = '';
    rowData;
    inputId = 'file-input';
    @api usuarioAns;
    @track isOptionsActive = false;
    @track isDetallesActive = false;


    handleCapture(event) {

        const file = event.target.files[0];

        const reader = new FileReader();

        reader.onload = () => {
            this.base64Image = reader.result;
            this.isCheckinActive = false;
            console.log(this.isCheckinActive, " en el handleCapture");
            this.renderKey = Date.now(); // Force re-render with a new unique key
        };
        if (file) {
            reader.readAsDataURL(file);
        }

    }

    handleCaptureParcial(event) {

        const file = event.target.files[0];

        const reader = new FileReader();

        reader.onload = () => {
            this.isCheckinActiveParcial = false;
            this.base64Image = reader.result;
            this.isCheckinActive = false;
            console.log(this.isCheckinActive, " en el handleCapture");
            this.renderKey = Date.now(); // Force re-render with a new unique key
        };
        if (file) {
            reader.readAsDataURL(file);
        }

    }




    @wire(getUmuOrders, { umuName: '$umuname', userId: '$userId' })
    getOrdenes({ data, error }) {
        if (data) {
            console.log(this.userId, "el user");
            console.log(data, "Lo que buscas");
            console.log(this.usuarioAns, "Aqui esta el parametro");
            if (this.usuarioAns) {
                this.isOptionsActive = false;
                this.isDetallesActive = true;

            } else if (this.ischeckin) {
                this.isOptionsActive = true;
                this.isDetallesActive = false;
            }
            //const ordersData = data.map((order) => ({...order, displayButtonClass: order.isRecibida__c ? 'slds-hide' : 'slds-show' }));
            const ordersData = data.map((order) => ({...order, displayButtonClass: order.Estatus__c === 'Enviado' ? 'slds-show' : 'slds-hide' }));
            this.orders = ordersData;




            if (this.orders.length > 0) {
                this.isData = true;
            }

            //addTheButton

        } else if (error) {
            console.log(error);
            this.isData = false;
        } else {
            this.isData = false;
        }
    }

    @track columns = columns;

    uploadImage() {
        // this.isCheckinActive = true;
        const fileName = 'captured-image.jpg';
        const base64Data = this.base64Image.split(',')[1];
        const parentId = this.orderId;
        const self = this;

        if (parentId) {
            // Checkin
            console.log('Checking');
            saveImage({ fileName: fileName, base64Data: base64Data, parentId: parentId, isCheckin : true })
                .then((result) => {
                    console.log(result);
                    this.ischeckin = true;
                    this.isCheckinActive = false;

                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Image uploaded successfully',
                            variant: 'success',
                        }),
                    );
                    self.deleteImage();


                    window.location.reload();

                    // setTimeout(() => {

                    //     
                    // }, 3000)

                })
                .catch((error) => {
                    console.log(error);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: error.body.message,
                            variant: 'error',
                        }),
                    );
                });
        }
    }

    deleteImage() {
        this.isCheckinActive = true;


        this.base64Image = null;

    }

    deleteImageParcial() {
        this.isCheckinActiveParcial = true;


        this.base64Image = null;
    }



    handleTransferir() {
        console.log(this.recordIds, " aqui estan los records");
        console.log(this.umuId, " aqui esta el umuId");
        // const recordIds = this.recordIds;
        // const umuId = this.umuId;


        this.isOpenTransferir = true;
        // const dialog = this.template.querySelector('c-avonni-dialog');
        // dialog.show();

    }

    handleGenerarCodigo() {
        this.isTransferir = true;

        createTransferInformation({ recordIds: this.recordIds, UmuId: this.umuId })
            .then((result) => {
                console.log(result, "Probando el codigo");
                this.codigoTransfer = result;

            })
            .catch((error) => {
                console.log(error);

                this.isTransferir = false;
            });
    }


    handleEntregar() {
        // const action = event.detail.action;
        // const row = event.detail.row;
        this.isEntregar = true;

        // if (action.name === 'view_details') {


        //     this.rowData = row;

        //     console.log(this.rowData.Id, "La info de la fila");



        //     // const dialog = this.template.querySelector('c-avonni-dialog');
        //     // dialog.show();
        // }



    }
    handleCloseO() {
        this.isTransferir = false;

    }

    handleCancel() {
        const dialog = this.template.querySelector('c-avonni-dialog');
        dialog.hide();
        this.isTransferir = false;
        this.isEntregar = false;
        this.isOpenTransferir = false;
        this.isConfirmarEntrega = false;
        this.isEnviadoFirma = false;
        this.isFirmar = false;

        /////Variables copiadas
        this.isRecibir = false;
        this.isEnviadoFirma = false;
        this.isotraDesviacion = false;
        this.isAgregarMateriales = false;
        this.isProductParcial = false;
        this.isEvidenciaCargada = false;
        ///
        this.showInsumos = true;
        this.showEvidencia = false;
        this.showNotas = false;
        this.isEnviadoParcial = false;
        this.isRechazar = false;
    }

    handleEnviarFirma() {

        this.isRecibir = true;
        this.isFirmar = true;
        this.isRechazar = false;
    }

    handleFirmar() {
        const orderId = this.rowData.Id;
        console.log(orderId, "Aqui el orderId a Firmar");
        registrarOrden({ orderId: orderId, status: 'En Firma' })
            .then((result) => {
                console.log(result, "Probando el codigo");
                this.isEnviadoFirma = true;
                this.estado = result;
                this.isFirmar = false;

            })
            .catch((error) => {
                console.log(error);

                this.isTransferir = false;
            });
    }

    handleOpenModal(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        this.isEntregar = false;

        if (action.name === 'view_details') {


            this.rowData = row;

            console.log(this.rowData.Id, "La info de la fila");


            this.isConfirmarEntrega = true;

            // const dialog = this.template.querySelector('c-avonni-dialog');
            // dialog.show();
        }
    }

    /* De aqui para abajo es entrega parcial */

    handleParcial() {

        const orderId = this.rowData.Id;
        getProductsOrder({ orderId: orderId })
            .then((result) => {
                console.log(result);
                this.insumosParcial = result;
                if (this.insumosParcial.length > 0) {
                    this.isParcial = true;
                    this.isRecibir = true;
                    this.isFirmar = false;
                    this.filteredProducts = this.insumosParcial;
                }

            }).catch((error) => {
                console.log(error);
            });

    }

    handleParcial() {

        const orderId = this.rowData.Id;
        getProductsOrder({ orderId: orderId })
            .then((result) => {
                console.log(result);
                this.insumosParcial = result;
                if (this.insumosParcial.length > 0) {
                    this.isParcial = true;
                    this.isRecibir = true;
                    this.isFirmar = false;
                    this.filteredProducts = this.insumosParcial;
                }

            }).catch((error) => {
                console.log(error);
            });

    }


    // botones de entrega parcial
    handleOptionsParcial(event) {

        const cardToShow = event.target.dataset.card;
        if (cardToShow === 'insumos') {
            this.showInsumos = true;
            this.showEvidencia = false;
            this.showNotas = false;
        } else if (cardToShow === 'evidencia') {
            this.showInsumos = false;
            this.showEvidencia = true;
            this.showNotas = false;
        } else if (cardToShow === 'notas') {
            this.showInsumos = false;
            this.showEvidencia = false;
            this.showNotas = true;
        }
    }



    handleSelect(event) {
        this.selectedParcialOption = event.target.value;
        console.log("Selected Option: ", this.selectedParcialOption);

        if (this.selectedParcialOption != 'Seleccionar') {
            this.isOptionSelected = true;
            this.checkAllVariablesForParcialButton();

        }

        if (this.selectedParcialOption === 'Otro( explique )') {
            console.log(this.selectedParcialOption, " esta funcionando el select");
            this.isotraDesviacion = true;


        } else {
            this.isotraDesviacion = false;
        }

    }

    @track selectedProduct;
    @track keyBuscar = '';
    @track filteredProducts = [];

    handleBuscar(event) {

        this.filteredProducts = this.insumosParcial;

        this.keyBuscar = event.target.value.toLowerCase();
        console.log(this.keyBuscar, " el key");
        this.filteredProducts = this.insumosParcial.filter((product) => {
            console.log(product.Product__r.Name);
            product.Product__r.Name.toLowerCase().includes(this.keyBuscar)
            if (product.Product__r.Name.toLowerCase().includes(this.keyBuscar)) {
                return product;
            }
        });

    }

    handleSearchChange(event) {
        this.searchKeyword = event.target.value.toLowerCase();

        this.filteredProducts = this.products.filter((product) =>
            product.Name.toLowerCase().includes(this.searchKeyword)
        );
    }

    handleAgregarMateriales() {
        this.isAgregarMateriales = true;
        this.isParcial = false;
        this.isRecibir = true;
        this.isFirmar = false;
    }

    @track itemName;
    itemQuantity;
    itemId;
    quantityReceived;

    @track isProductParcial = false;
    @track selectedQuantityValue = 0;

    handleProductClick(event) {


        let itemId = event.currentTarget.dataset.id;
        let itemName = event.currentTarget.innerText;
        let quantityItem = event.currentTarget.dataset.quantity;
        let loteNumber = event.currentTarget.dataset.lote;


        this.quantityReceived = quantityItem;
        this.loteNumber = loteNumber;



        this.itemName = itemName;
        this.itemQuantity = quantityItem;
        this.itemId = itemId;


        this.isAgregarMateriales = false;
        this.isProductParcial = true;

        console.log(itemId, " el item");
        console.log(itemName, " el nombre");
        console.log(itemQuantity, " la cantidad");



    }

    handleInputPiezasFaltantes(event) {
        this.selectedQuantityValue = event.target.value;

    }

    handleAdd() {
        if (this.selectedQuantityValue < this.itemQuantity) {
            this.selectedQuantityValue++;
        }
    }

    handleSubstract() {
        if (this.selectedQuantityValue > 0) {
            this.selectedQuantityValue--;
        }
    }

    handleAgregarInsumoParcial() {


        if (this.selectedQuantityValue > this.quantityReceived) {
            const toastErrorEvent = new ShowToastEvent({
                title: 'Error al Agregar Insumo',
                message: 'La cantidad de piezas faltantes no puede ser mayor a la cantidad de piezas enviadas',
                variant: 'error'
            });
            this.dispatchEvent(toastErrorEvent);

            return;
        }

        const itemId = this.itemId;
        const itemName = this.itemName;
        const quantity = this.selectedQuantityValue;
        const newItem = { id: itemId, name: itemName, status: "Recibido Parcial", catidadRecibida: quantity };
        let ordenItem = { id: itemId, status: "Recibido Parcial", cantidadRecibida: this.selectedQuantityValue };
        let existe = false;


        let existingObject = this.arrayParcialItem.find(o => o.id === itemId);    
        if (existingObject) {       
            console.log("Object with ID: " + itemId + " already exists.");       
            existe = true;   
        }    



        if (!existe) {

            this.arrayParcialItem.push(newItem);
            //array para insertar en la db
            this.ordenItemsUpdates.push(ordenItem);

        } else {
            const toastErrorEvent = new ShowToastEvent({
                title: 'Error al Agregar Insumo',
                message: 'El Insumo que intenta agregar ya está agregado',
                variant: 'error'
            });
            this.dispatchEvent(toastErrorEvent);

            console.log("Llego despues del toast");

        }


        console.log(this.arrayParcialItem);
        this.isParcial = true;
        this.isRecibir = true;
        this.isFirmar = false;
        this.isAgregarMateriales = false;
        this.isProductParcial = false;
        this.isMaterialesAgregados = true;
        this.selectedQuantityValue = 1;
        checkAllVariablesForParcialButton();

    }

    // handleCapture(event) {
    //     const file = event.target.files[0];
    //     const reader = new FileReader();
    //     reader.onload = () => {
    //         this.base64Image = reader.result;
    //         this.renderKey = Date.now(); // Force re-render with a new unique key
    //     };
    //     if (file) {
    //         reader.readAsDataURL(file);
    //     }

    // }

    //Subir evidencia
    cargarImage() {
        this.isEvidenciaCargada = true;
        this.isEvidenciaAgregada = true;
        this.checkAllVariablesForParcialButton();
        const fileName = 'captured-image.jpg';
        const base64Data = this.base64Image.split(',')[1];
        const self = this;
        const parentId = this.parentId;

        if (parentId) {
            saveImage({ fileName: fileName, base64Data: base64Data, parentId: parentId, isCheckin, isCheckin : false})
                .then((result) => {
                    console.log(result);
                    this.ischeckin = true;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Image uploaded successfully',
                            variant: 'success',
                        }),
                    );
                    self.deleteImage();
                    window.location.reload();
                })
                .catch((error) => {
                    console.log(error);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: error.body.message,
                            variant: 'error',
                        }),
                    );
                });
        }
    }


    // deleteImage() {
    //     this.base64Image = null;
    // }

    notas;
    handleNota(event) {
        const nota = event.target.value;
        this.notas = nota;
        console.log(nota);

    }

    checkAllVariablesForParcialButton() {
        if (this.isMaterialesAgregados && this.isEvidenciaAgregada && this.isOptionSelected) {
            this.isDisplayParcialButton = true;
        } else {
            this.isDisplayParcialButton = false;
        }
    }

    handleRegistrarEntregaParcial() {
        this.isEnviadoParcial = true;
        this.isParcial = false;
    }



    createJSONString() {

        const date = new Date(this.selectedDate);
        const apexFormattedDate = date.getUTCFullYear() + "-" +("0" + (date.getUTCMonth() + 1)).slice(-2) + "-" +("0" + date.getUTCDate()).slice(-2);
        const timeString = this.selectedTime;
        const dateTime = new Date("1970-01-01 " + timeString);
        const apexFormattedTime = ("0" + dateTime.getHours()).slice(-2) + ":" +("0" + dateTime.getMinutes()).slice(-2) + ":" +("0" + dateTime.getSeconds()).slice(-2);

        // const orderItemsUpdate = JSON.stringify(this.ordenItemsUpdates);
        const orderUpdates = {
            descripcion: this.notas,
            rejectionImage: this.base64Image,
            orderItemsUpdates: this.ordenItemsUpdates,
            selectedDate: apexFormattedDate,
            selectedTime: apexFormattedTime
        };

        const jsonString = JSON.stringify(orderUpdates);
        console.log(jsonString); // Display the JSON string in the browser console or use it as needed
        return jsonString;

    }



    async handleGuardarParcial() {
        const result = await LightningConfirm.open({
            message: '¿Está seguro de guardar su entrega como parcial?',
            variant: 'headerless',
            label: 'Entrega Parcial',
        });

        if (result) {
            const orderId = this.rowData.Id;
            const jsonString = this.createJSONString();
            registrarOrdenParcial({ orderId: orderId, status: 'Recibido Parcial', ordenParcialJson: jsonString })
                .then((result) => {
                    if (result) {
                        const toastParcialGuardar = new ShowToastEvent({
                            title: 'Entrega Parcial Exitosa',
                            message: 'Su entrega Parcial ha sido guardad con éxito',
                            variant: 'success'
                        });
                        this.dispatchEvent(toastParcialGuardar);
                        console.log(result, "Se hizo el update parcial");
                    }
                }).catch((error) => {
                    console.log(error);
                });

            const dialog = this.template.querySelector('c-avonni-dialog');
            dialog.hide();
            this.isRecibir = false;
            this.isEnviadoFirma = false;
            this.isotraDesviacion = false;
            this.isAgregarMateriales = false;
            this.isProductParcial = false;
            this.isEvidenciaCargada = false;
            ///
            this.showInsumos = true;
            this.showEvidencia = false;
            this.showNotas = false;
            this.isEnviadoParcial = false;





        } else if (!result) {
            console.log("El cancel esta funcionando");
            const dialog = this.template.querySelector('c-avonni-dialog');
            dialog.hide();
            this.isRecibir = false;
            this.isEnviadoFirma = false;
            this.isotraDesviacion = false;
            this.isAgregarMateriales = false;
            this.isProductParcial = false;
            this.isEvidenciaCargada = false;
            ///
            this.showInsumos = true;
            this.showEvidencia = false;
            this.showNotas = false;
            this.isEnviadoParcial = false;
        }


    }

    //Rechazar
    async handleEnviarARechazar() {
        this.isRecibir = true;
        this.isFirmar = false;
        const orderId = this.rowData.Id;
        const dialog = this.template.querySelector('c-avonni-dialog');
        dialog.hide();
        // this.isRechazar = true;
        const result = await LightningConfirm.open({
            message: 'Está rechazando esta entrega. ¿Está seguro que desea rechazar?',
            variant: 'headerless',
            label: 'Rechazar Entrega',
        });

        if (result) {
            registrarOrden({ orderId: orderId, status: 'Rechazado' })
                .then((result) => {
                    console.log(result, "Probando el codigo");
                    this.isEnviadoFirma = true;
                    this.estado = result;
                    this.isRechazar = false;
                })
                .catch((error) => {
                    console.log(error);
                    // Where is this used?
                    this.isTransferir = false;
                });
        } else if (!result) {
            console.log("El cancel esta funcionando");
            this.handleCancel();
        }


    }




}