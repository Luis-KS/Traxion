import { LightningElement, api, wire, track } from 'lwc';

// import registrarParaFirmaElectronica from '@salesforce/apex/OrderController.registrarParaFirmaElectronica';
import getOrdersAns from '@salesforce/apex/AnsTransporteController.getOrdersAns';
import registrarOrden from '@salesforce/apex/OrderController.registrarOrden';
import login from '@salesforce/apex/CustomLoginFormController.login';
import LightningConfirm from 'lightning/confirm';
import getProductsOrder from "@salesforce/apex/AnsTransporteController.getProductsOrder"
import saveImage from '@salesforce/apex/ImageUploadController.saveImage';
import registrarOrdenParcial from '@salesforce/apex/OrderController.registrarOrdenParcial';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FORM_FACTOR from "@salesforce/client/formFactor";

const columns = [
    // { label: 'Orden ID', fieldName: 'Id' },
    { label: 'Fecha Maxima de Entrega', fieldName: 'Fecha_Maxima_de_Entrega__c', type: 'date' },
    { label: 'Número de Orden', fieldName: 'Order_Number__c' },
    { label: 'Tipo de Orden', fieldName: 'Tipo_de_Pedido__c' },
    { label: 'Total de Piezas', fieldName: 'Total_de_Piezas__c' },
    { label: 'Estado de Pedido', fieldName: 'Estatus__c' },
    { label: 'Numero de Viaje', fieldName: 'Id_de_Viaje__c', type: 'text' },
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


export default class AuxiliarOrdenesUmu extends LightningElement {
    @api umuName;
    @api isOrden;
    @track orders = [];
    showModal = false;
    @track dialog;
    isRecibir = false;
    rowData;
    @api isData = false;
    isEnviadoFirma = false;
    estado;
    isFirmar = false;
    isRechazar = false;
    showDialogRecibirTransf = false;
    @api userId;
    @track columns = columns;
    @track insumosParcial;
    //entrega parcial variables
    isParcial = false;
    isEditar = false;
    @track showInsumos = true;
    @track showEvidencia = false;
    @track showNotas = false;
    @track selectedParcialOption = '';
    @track selectedRechazoOption = '';
    @track notaMotivoRechazo = '';
    @track notaParcial = '';
    @track isotraDesviacion = false;
    @track isotraDesviacionRechazo = false;
    @track base64Image;
    isEvidenciaCargada = false;
    //crear boton parcial
    isOptionSelected = false;
    isEvidenciaAgregada = false;
    isMaterialesAgregados = false;
    isDisplayParcialButton = false;
    isEvidenciaAgregada = false;
    @track isEnviadoParcial = false;
    isDisplayParcialButton = false;
    @track isEnviadoParcial = false;
    selectedDate = new Date().toISOString();
    // selectedTime = new Date().toLocaleTimeString();
    selectedTime  = new Date().toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: false });
    isShowLotes = false;
    isSelectedLoteDisabled = false;
    @track isEnviadoParcial = false;
    // selectedDate;
    // selectedTime;
    ordenItemsUpdates = [];
    listaInsumos = [];
    @track arrayParcialItem = [];
    // loteProduct = [{ label: 'Seleccionar Lote', value: 'Seleccionar Lote' }]; // Recently added
    loteName;    // Recently added
    loteNumber = '';
    inputId = 'file-input'
    isRechazoOptionSelected = false;
    isDisplayRechazarButton = false;
    isNota = false;
    isLotesLoaded = false;
    @track notes = '';

    @track selectedProduct;
    @track keyBuscar = '';
    @track filteredProducts = [];
    @track isCheckinActive = true;

    orderLineItemPerLote = [];
    currentLotes = [{ label: 'Seleccionar Lote', value: 'Seleccionar Lote' }];

    rendered = false;
    deviceDetection = FORM_FACTOR;

    get isMobile(){
        if(this.deviceDetection == 'Small'){
            return true;
        }else{
            return false;
        }
    }

    get optionsDesvicion() {
        return [
            { label: "Exceso de suminis., causa descon.", value: "Exceso de suminis., causa descon." },
            { label: "Falta de suminis. causa descon.", value: "Falta de suminis. causa descon." },
            { label: "Falta certificado", value: "Falta certificado" },
            { label: "Falta carta garantia de canje", value: "Falta carta garantia de canje" },
            { label: "Falta factura, remisión, ord R", value: "Falta factura, remisión, ord R" },
            { label: "Falta Contrato, Pedito, O.C", value: "Falta Contrato, Pedito, O.C" },
            { label: "Falta Carta dustribución", value: "Falta Carta dustribución" },
            { label: "Falta otro documento", value: "Falta otro documento" },
            { label: "Faltante medicamento", value: "Faltante medicamento" },
            { label: "Otro( explique )", value: "Otro( explique )" },
        ];
    }

    renderedCallback() {
        if(this.isData) {
            const badges = this.template.querySelectorAll('lightning-badge');

            if(badges) {
                badges.forEach(element => {
                    const line = this.template.querySelector('div[data-key="' + element.dataset.key + '"]');

                    if(element.label == "Error" || element.label == "Rechazado") {
                        element.classList.add('slds-theme_error');
                        line.classList.add('slds-theme_error');
                    } else if(element.label == "Procesando") {
                        element.classList.add('slds-theme_info');
                        line.classList.add('slds-theme_info');
                    } else if(element.label == "Transferido") {
                        element.classList.add('slds-theme_inverse');
                        line.classList.add('slds-theme_inverse');
                    } else if(element.label == "Preparando Envío" || element.label == "Verificando Disponibilidad") {
                        if(element.label == "Verificando Disponibilidad") element.label = "Verificando";
                        element.classList.add('slds-theme_warning');
                        element.classList.add('slds-text-color_inverse');
                        line.classList.add('slds-theme_warning');
                    } else if(element.label == "Certificado" || element.label == "Certificado Parcial"
                    || element.label == "En Firma" || element.label == "En Firma Parcial") {
                        element.classList.add('slds-theme_transfer');
                        element.classList.add('slds-text-color_inverse');
                        line.classList.add('slds-theme_transfer');
                    } else {
                        element.classList.add('slds-theme_success');
                        line.classList.add('slds-theme_success');
                    }
                });

                this.rendered = true;
            }
        }
    }

    @wire(getOrdersAns, { userId: '$userId' })
    getOrdenes({ data, error }) {
        if (data) {
            console.log(this.userId, "el user");
            console.log(data, "Lo que buscas");

            const filteredData = data.filter((order) => order.UMU__r.Name === this.umuName);

            const ordersData = filteredData.map((order) => {
                return {
                    ...order,
                    displayButtonClass: order.Estatus__c === 'Transferido' ? 'slds-show' : 'slds-hide',
                    showButton: order.Estatus__c === 'Transferido' ? true : false,
                };
            });
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


    get getListaInsumo(){
       if(this.listaInsumos.length > 0){
            this.isListaInsumo = true;
       }
       return this.isListaInsumo;
    }


    handleOpenModal(event) {
        this.isEnviadoFirma = false;
        this.isRecibir = false;

        let action;
        let row;

        if(this.deviceDetection == 'Small') {
            console.log("mobile");
            action = event.target.dataset.name;
            const id = event.target.dataset.id;
            const order = this.orders.filter(order => order.Id == id);
            row = order[0];
        } else {
            console.log("pc");
            action = event.detail.action.name;
            row = event.detail.row;
        }

        console.log('Action ---> ');
        console.log(JSON.stringify(action));
        console.log('row ---> ');
        console.log(JSON.stringify(row));

        if(action === 'view_details') {

            this.rowData = row;

            console.log(this.rowData.Id, "La info de la fila");

            const dialog = this.template.querySelector('c-avonni-dialog');
            dialog.show();
        }

    }
    handleCancel() {
        const dialog = this.template.querySelector('c-avonni-dialog');
        dialog.hide();
        this.isRecibir = false;
        this.isEnviadoFirma = false;
        this.isotraDesviacion = false;
        this.isAgregarMateriales = false;
        this.isProductParcial = false;
        this.isEvidenciaCargada = false;
        this.isFirmar = false;
        this.isParcial = false;
        ///
        this.showInsumos = false;
        this.showEvidencia = false;
        this.showNotas = false;
        this.isEnviadoParcial = false;
        this.isRechazar = false;
        this.isRechazoOptionSelected = false;
        this.isNota = false;
        this.quantityReceived = 0;
        this.listaInsumos = [];
        this.itemId = '';
        this.itemName = '';
        this.loteName = '';
        this.selectedQuantityValue = 0;
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

                const toastEnviarFirma = new ShowToastEvent({
                    title: 'Firma Enviada',
                    message: 'Su firma ha sido enviada exitosamente',
                    variant: 'success'
                });
                this.dispatchEvent(toastEnviarFirma);

                setTimeout(() => {
                    location.reload();
                }, 1000);

            })
            .catch((error) => {
                console.log(error);

                this.isTransferir = false;
            });
    }




    async handleEnviarARechazar() {
        this.isRecibir = true;
        this.isFirmar = false;
        this.isRechazar = true;
        const orderId = this.rowData.Id;
        const dialog = this.template.querySelector('c-avonni-dialog');
        dialog.show();



        getProductsOrder({ orderId: orderId })
            .then((result) => {

                this.insumosParcial = result;
                console.log(this.insumosParcial, "Los insumos a rechazar");
                if (this.insumosParcial.length > 0) {
                    this.isParcial = false;
                    this.isRecibir = true;
                    this.isFirmar = false;
                    this.filteredProducts = this.insumosParcial;
                }

            }).catch((error) => {
                console.log(error);
            });

        // this.isRechazar = true;
        // const result = await LightningConfirm.open({
        //     message: 'Está rechazando esta entrega. ¿Está seguro que desea rechazar?',
        //     variant: 'headerless',
        //     label: 'Rechazar Entrega',
        // });

        // if (result) {
        //     registrarOrden({ orderId: orderId, status: 'Rechazado' })
        //         .then((result) => {
        //             console.log(result, "Probando el codigo");
        //             this.isEnviadoFirma = true;
        //             this.estado = result;
        //             this.isRechazar = false;
        //         })
        //         .catch((error) => {
        //             console.log(error);
        //             // Where is this used?
        //             this.isTransferir = false;
        //         });
        // } else if (!result) {
        //     console.log("El cancel esta funcionando");
        // }


    }

    async handleRechazarEntrega() {
        const orderId = this.rowData.Id;

        //Para la proxima etapa debemos enviar los datos recolectados durante el proceso
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

                    const toastRechazarFirma = new ShowToastEvent({
                        title: 'Firma Rechazada',
                        message: 'Su firma ha sido rechazada exitosamente',
                        variant: 'success'
                    });
                    this.dispatchEvent(toastRechazarFirma);
    
                    setTimeout(() => {
                        location.reload();
                    }, 1000);
                })
                .catch((error) => {
                    console.log(error);
                    // Where is this used?
                    this.isTransferir = false;
                });
        } else if (!result) {
            console.log("El cancel esta funcionando");

        }
    }

    handleParcial() {
        this.currentLotes = [{ label: 'Seleccionar Lote', value: 'Seleccionar Lote' }];
        const orderId = this.rowData.Id;
        getProductsOrder({ orderId: orderId })
            .then((result) => {
                console.log('Resultado',result);
                this.insumosParcial = result;
                if (this.insumosParcial.length > 0) {
                    this.isParcial = true;
                    this.isRecibir = true;
                    this.isFirmar = false;
                    this.filteredProducts = this.insumosParcial;
                }

                // this.loteProduct = this.insumosParcial.map(item => item.Informacion_De_Lotes__r);
                // console.log('Lotes', JSON.stringify(this.loteProduct));
                
                if(!this.isLotesLoaded){
                // const listaLote = [];
                const orderLineItemPerLote = [];

                const resultado = result.map(objeto => {
                    let lotesList = [];
                   const lotes = objeto.Informacion_De_Lotes__r.forEach(item => {
                        let listItem = { label: item.Name, value: item.Id, cantidad: item.Cantidad__c}
                        // listaLote.push(listItem);
                        lotesList.push(listItem);
                    });
                    const orderLineItem = {
                        id: objeto.Id,
                        lotes: lotesList
                    }
                    orderLineItemPerLote.push(orderLineItem);
                  });

                  this.orderLineItemPerLote = orderLineItemPerLote;
                //this.loteProduct = [...this.loteProduct, ...listaLote];
                  this.isLotesLoaded = true;
                }
            }).catch((error) => {
                console.log(error);
            });

    }

    get options() {
        return this.currentLotes;
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

        } else if (this.selectedParcialOption === 'Seleccionar') {
            this.isOptionSelected = false;
            this.checkAllVariablesForParcialButton();
        }

        if (this.selectedParcialOption === 'Otro( explique )') {
            console.log(this.selectedParcialOption, " esta funcionando el select");
            this.isotraDesviacion = true;
            this.isOptionSelected = false;
            this.checkAllVariablesForParcialButton();


        } else {
            this.isotraDesviacion = false;
        }

    }

    handleSelectRechazo(event) {
        this.selectedRechazoOption = event.target.value;


        if (this.selectedRechazoOption != 'Seleccionar') {
            this.isRechazoOptionSelected = true;
            console.log("Funciona");
            this.checkAllVariablesForRechazarButton();

        } else if (this.selectedRechazoOption === 'Seleccionar') {
            this.isRechazoOptionSelected = false;
            console.log("Funciona");
            this.checkAllVariablesForRechazarButton();

        }

        if (this.selectedRechazoOption === 'Otro( explique )') {
            this.isotraDesviacionRechazo = true;
            this.isRechazoOptionSelected = false;
            this.checkAllVariablesForRechazarButton();

        } else {
            this.isotraDesviacionRechazo = false;
        }

    }


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
        this.isOptionSelected = false;
        this.isFirmar = false;
        this.currentLotes = [{ label: 'Seleccionar Lote', value: 'Seleccionar Lote' }];
    }

    @track itemName;
    itemQuantity;
    itemId;
    quantityReceived = 0;
    loteId;
    quantityPorLote;

    @track isProductParcial = false;
    @track selectedQuantityValue = 0;

    handleProductClick(event) {
        let itemId = event.currentTarget.dataset.id;
        let itemName = event.currentTarget.innerText;
        // chekinButtonEntrega 
        let quantityItem = event.currentTarget.dataset.quantity;
        let loteNumber = event.currentTarget.dataset.lote;


        this.quantityReceived = quantityItem;
        this.loteNumber = loteNumber;

        this.quantityPorLote = event.currentTarget.dataset.lotes;
        console.log('LOTES:', JSON.stringify(this.quantityPorLote));

        this.itemName = itemName;
        this.itemQuantity = quantityItem;
        this.itemId = itemId;


        this.isAgregarMateriales = false;
        this.isProductParcial = true;

        console.log('Data', event.currentTarget.dataset.lote);
        console.log(itemId, " el item");
        console.log(itemName, " el nombre");
        // console.log(itemQuantity, " la cantidad");
        // console.log(loteNumber, 'Lote');
        // console.log('Lote: ', JSON.stringify(this.loteProduct));
        console.log('Order Line Item', JSON.stringify(this.orderLineItemPerLote));
        const currentLotes = [];
        const lotes = this.orderLineItemPerLote.find(item => item.id == itemId);
        const getLotes = lotes.lotes.map(item =>{
            currentLotes.push(item);
        })
        console.log('Lotes:', JSON.stringify(currentLotes));
        this.currentLotes = [...this.currentLotes, ...currentLotes];
    }

    handleInputPiezasFaltantes(event) {
        this.selectedQuantityValue = event.target.value;
    }

    handleAdd() {
        //if (this.selectedQuantityValue < this.itemQuantity) {
            this.selectedQuantityValue++;
        //}
    }

    handleSubstract() {
        if (this.selectedQuantityValue > 0) {
            this.selectedQuantityValue--;
        }
    }

    handleAgregarInsumoParcial() {

        console.log('lote Name: ', this.loteName);
        if (this.selectedQuantityValue > this.quantityReceived) {
            const toastErrorEvent = new ShowToastEvent({
                title: 'Error al Agregar Insumo',
                message: 'La cantidad de piezas faltantes no puede ser mayor a la cantidad de piezas enviadas',
                variant: 'error'
            });
            this.dispatchEvent(toastErrorEvent);

            return;
        }
        else if(this.loteName == undefined || this.loteName == 'Seleccionar Lote'){

            const toastErrorEvent = new ShowToastEvent({
                title: 'Error al Agregar Insumo',
                message: 'Debes seleccionar un insumo valido para poder agregarlo.',
                variant: 'error'
            });
            this.dispatchEvent(toastErrorEvent);

            return;
        }
        console.log('loteName',this.loteName);
        const itemId = this.itemId;
        const itemName = this.itemName;
        const quantity = this.selectedQuantityValue;
        const loteId = this.loteId;
        let existeLote = false;

        //? FUNCIONA
        // const lote = this.loteProduct.find(item => item.value === this.loteId);

        // const newItem = { id: itemId, name: itemName, status: "Recibido Parcial", lote: {
        //     id: loteId,
        //     name: lote.label,
        //     cantidadDePiezasFaltantes: quantity
        // }};

         // let ordenItem = { id: itemId, status: "Recibido Parcial", lotes: {
        //     id: loteId,
        //     cantidadDePiezasFaltantes: this.selectedQuantityValue
        // }};

        // let existe = false;
        // let existingObject = this.arrayParcialItem.find(item => item.lote.id === loteId); 
        //   
        // if (existingObject) {       
        //     console.log("Object with ID: " + loteId + " already exists.");       
        //     existe = true;   
        // }

        // if (!existe) {

        //     this.arrayParcialItem.push(newItem);
        //     array para insertar en la db
        //     this.ordenItemsUpdates.push(ordenItem);

        // } else {
        //     const toastErrorEvent = new ShowToastEvent({
        //         title: 'Error al Agregar Insumo',
        //         message: 'El Insumo que intenta agregar ya está agregado',
        //         variant: 'error'
        //     });
        //     this.dispatchEvent(toastErrorEvent);

        //     console.log("Llego despues del toast");

        // }
        //? FUNCIONA

        //! TRABAJANDO EN NUEVA FUNCIONALIDAD

        // buscar producto para ver si existe, si existe, crear un nuevo objeto y colocarlo en la lista
        let existeInsumo = false;
        let producto = this.listaInsumos.find(item => item.id === itemId);
        let indiceProducto = this.listaInsumos.findIndex(item => item.id === itemId);
        // const loteSeleccionado = this.loteProduct.find(item => item.value === this.loteId);
        const loteSeleccionado = this.currentLotes.find(item => item.value === this.loteId);
        let lote;
        if(this.isEditar){
            let indiceLote = this.listaInsumos[indiceProducto].lotes.findIndex(item => item.id === loteId);
            if (indiceLote !== -1) {
                this.listaInsumos[indiceProducto].lotes[indiceLote].cantidadDePiezasFaltantes = quantity;
                this.isEditar = false;
                this.isSelectedLoteDisabled = false;
            }
        }else{
            if(producto){
                existeInsumo = true;
                lote = producto.lotes.find(item => item.id === loteId);
                if(lote){
                   existeLote = true;
                }
       
            }
    
            if(existeLote){
            const toastErrorEvent = new ShowToastEvent({
                title: 'Error al Agregar Insumo',
                message: 'El Insumo que intenta agregar ya está agregado',
                variant: 'error'
            });
            this.dispatchEvent(toastErrorEvent);
                return;
            }
    
            if(!existeInsumo){
                console.log('Entro aqui, no existe insumo.');
                const nuevoInsumo = {
                    id: itemId,
                    name: itemName,
                    lotes: [
                        {id: loteId, name: loteSeleccionado.label, cantidadDePiezasFaltantes: quantity}
                    ] 
                }
    
                this.listaInsumos.push(nuevoInsumo);
                this.selectedQuantityValue = 0;

            }else{
                console.log('Entro aqui, existe insumo.');
                producto.lotes.push({id: loteId, name: loteSeleccionado.label, cantidadDePiezasFaltantes: quantity});
            }

        }


        this.isParcial = true;
        this.isRecibir = true;
        this.isFirmar = false;
        this.isAgregarMateriales = false;
        this.isProductParcial = false;
        this.isMaterialesAgregados = true;
        this.selectedQuantityValue = 0;
        checkAllVariablesForParcialButton();
    }

    handleCapture(event) {
        const file = event.target.files[0];
        const reader = new FileReader();
        reader.onload = () => {
            this.isCheckinActive = false;
            this.base64Image = reader.result;
            this.renderKey = Date.now(); // Force re-render with a new unique key
        };
        if (file) {
            reader.readAsDataURL(file);
        }

    }

    //Subir evidencia
    uploadImage() {
        this.isEvidenciaCargada = true;
        this.isEvidenciaAgregada = true;
        console.log("Funciona");
        //check parcial
        this.checkAllVariablesForParcialButton();
        //check rechazar
        this.checkAllVariablesForRechazarButton();
        const fileName = 'captured-image.jpg';
        const base64Data = this.base64Image.split(',')[1];
        // const parentId = 'a0J3K00000CEKQaUAP';
        // const parentId = this.orderId;
        const self = this;
        const parentId = this.parentId;


        if (parentId) {
            saveImage({ fileName: fileName, base64Data: base64Data, parentId: parentId , isCheckin : false})
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


    deleteImage() {
        this.isCheckinActive = true;
        this.base64Image = null;
    }



    handleNota(event) {

        this.notes = event.target.value;
        if (this.notes.trim() != '') {
            this.isNota = true;
            this.checkAllVariablesForRechazarButton();


        } else {
            this.isNota = false;
            this.checkAllVariablesForRechazarButton();
        }
    }


    handleDateParcial(event){
        this.selectedDate = event.target.value;
    }

    handleTimeParcial(event){
        this.selectedTime = event.target.value;
    }

    handleDesviacionChanges(event) {
        this.notaMotivoRechazo = event.target.value;
        if (this.notaMotivoRechazo.trim() != '') {
            this.isRechazoOptionSelected = true;
            this.checkAllVariablesForRechazarButton();
        } else {
            this.isRechazoOptionSelected = false;
            this.checkAllVariablesForRechazarButton();

        }
    }

    handleNotaMotivoParcial(event) {
        this.notaParcial = event.target.value;
        if (this.notaParcial.trim() != '') {
            this.isOptionSelected = true;
        } else {
            this.isOptionSelected = false;
        }

        this.checkAllVariablesForParcialButton();
    }

    checkAllVariablesForParcialButton() {
        if (this.isMaterialesAgregados && this.isEvidenciaAgregada && this.isOptionSelected) {
            this.isDisplayParcialButton = true;
        } else {
            this.isDisplayParcialButton = false;
        }
    }

    checkAllVariablesForRechazarButton() {
        if (this.isRechazoOptionSelected && this.isEvidenciaAgregada && this.isNota) {
            this.isDisplayRechazarButton = true;
        } else {
            this.isDisplayRechazarButton = false;
        }
    }

    handleRegistrarEntregaParcial() {
        this.isEnviadoParcial = true;
        this.isParcial = false;
        this.resetData();
    }

    resetData(){
       
        this.arrayParcialItem = [];
        //array para insertar en la db
        this.ordenItemsUpdates = [];
        this.isShowLotes = false;
    }



    createJSONString() {

        const date = new Date(this.selectedDate);
        const apexFormattedDate = date.getUTCFullYear() + "-" +("0" + (date.getUTCMonth() + 1)).slice(-2) + "-" +("0" + date.getUTCDate()).slice(-2);
        const timeString = this.selectedTime;
        const dateTime = new Date("1970-01-01 " + timeString);
        const apexFormattedTime = ("0" + dateTime.getHours()).slice(-2) + ":" +("0" + dateTime.getMinutes()).slice(-2) + ":" +("0" + dateTime.getSeconds()).slice(-2);

        const orderUpdates = {
            descripcion: this.notas,
            rejectionImage: this.base64Image,
            orderItemsUpdates: this.listaInsumos,
            selectedDate: apexFormattedDate,
            selectedTime: apexFormattedTime
        };
        console.log(orderUpdates);
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


            setTimeout(() => {
                location.reload();
            }, 500);


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
            this.isRechazar = false;
        }


    }

    handleChange(event){
        if(event.detail.value == 'Select Progress'){
            this.loteName = event.detail.value;
            console.log("🚀 ~ file: auxiliarOrdenesUmu.js:895 ~ AuxiliarOrdenesUmu ~ handleChange ~  this.loteName:",  this.loteName)
            
            return;
        }
        this.loteName = event.detail.value;
        this.loteId = event.detail.value;

        const lote = this.currentLotes.find(Item => Item.value == this.loteId);
        console.log("🚀 ~ file: auxiliarOrdenesUmu.js:901 ~ AuxiliarOrdenesUmu ~ handleChange ~ lote:", JSON.stringify(lote));
        this.quantityReceived = lote.cantidad;
        
    }

    handleShowLotes(){
        this.isShowLotes = !this.isShowLotes;
    }

    handleSectionToggle(event){
        console.log(event.detail.openSections);
        this.isShowLotes = true;
    }

    handleEdit(event){
        this.isEditar = true;
        this.isSelectedLoteDisabled = true;
        this.isParcial = false;
        this.isRecibir = true;
        this.isFirmar = false;
        this.isAgregarMateriales = false;
        this.isProductParcial = true;
        this.loteName = event.detail.Id;
        this.selectedQuantityValue = event.detail.cantidadPiezas;
        this.itemId = event.detail.insumo;
        this.loteId = event.detail.Id;
        this.isOptionSelected = false; 

        this.checkAllVariablesForParcialButton();
    }


}