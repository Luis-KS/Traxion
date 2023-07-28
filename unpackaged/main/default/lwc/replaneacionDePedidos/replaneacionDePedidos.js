import { LightningElement, wire, api, track } from 'lwc';
import getReplaneacionData from '@salesforce/apex/ReplaneacionController.getReplaneacionData'
import getOrderProduct from '@salesforce/apex/ReplaneacionController.getOrderProduct';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from 'lightning/confirm';
import editarOrdenParaEnviarAFirma from '@salesforce/apex/ReplaneacionController.editarOrdenParaEnviarAFirma';
import firmarOrden from '@salesforce/apex/ReplaneacionController.firmarOrden';
import saveImage from '@salesforce/apex/ImageUploadController.saveImage';
import Id from '@salesforce/user/Id';
export default class ReplaneacionDePedidos extends LightningElement {


    // Array and Object
    @track data;
    @track transporte;
    @track filtroTransporte = [];
    @track actualTransporte = {};
    @track actualTransportista = {};
    @track selectedParcialOption;
    @track filteredProducts = [];
    @track insumosProductos = [];
    @track ordenItemsUpdates = [];
    @track arrayParcialItem = [];
    loteNumber = '';

    isTransporte = false;
    isComment = false;
    activeSectionMessage = '';
    @track isParcial = false;
    isotraDesviacion = false;
    isAgregarMateriales = false;
    isMaterialesAgregados = false;
    estatus = '';
    showEvidencia;
    showInsumos = true;
    showNotas;
    @api userId = Id;
    replaneacionData;
    selectedMotivo;
    notes;
    isNota;



    @track base64Image;
    @track renderKey;
    isCargarImg = false;

    get statusOrderOptions() {
        return [
            { label: 'Todos', value: 'Todos' },
            { label: 'Certificado', value: 'Certificado' },
            { label: 'Recibido Parcial', value: 'RecibidoParcial' }

        ];
    }

    get thereIsData() {
        return this.filtroTransporte.length !== 0;
    }

    @wire(getReplaneacionData, { userId: '$userId' }) getData({ data, error }) {
        if (data) {
            const parsedData = JSON.parse(data);
            console.log(parsedData, "Aqui esta la data");
            //  this.data = parsedData;
            this.data = [...parsedData];
            this.transporte = [...parsedData];
            this.filtroTransporte = this.transporte;

            // this.filtroTransporte = parsedData;

            // console.log(this.transporte);
            // this.replaneacionData = data;
            // console.log(this.replaneacionData, "Aqui estan los datos");
        }

        if (error) {
            console.log(error);
        }
    }

    connectedCallback() {
        // let data = JSON.parse(JSON.stringify(this.data));
        console.log('Transporte', JSON.stringify(this.actualTransporte));
    }




    handleOnChangeTransporte(event) {

        this.handleBuscarTransporte('transporte', event.target.value);

    }

    handleOnChangeDelivery(event) {

        this.handleBuscarTransporte('delivery', event.target.value);
    }


    // handleBuscarTransporte(tipo, Id) {
    //     let transporteUnico = [];
    //     if (tipo === 'transporte') {
    //         transporteUnico = this.transporte.filter(item => item.IdTransporte === Id);
    //     } else {
    //         transporteUnico = this.transporte.filter(item => item.orderId === Id);
    //     }

    //     if (transporteUnico.length === 0) {
    //         this.filtroTransporte = this.transporte;
    //     } else {
    //         this.filtroTransporte = [...transporteUnico];
    //     }
    // }

    // handleBuscarTransporte(tipo, Id) {
    //     var transporteUnico = [];

    //     if (tipo === 'transporte') {
    //         transporteUnico = this.transporte.filter(item => {

    //             console.log(JSON.stringify(item.IdTransporte), " aqui esta el item");
    //             console.log(Id, "El id");
    //             return item.IdTransporte.includes(Id);


    //         })
    //     } else {
    //         transporteUnico = this.transporte.filter(item => {
    //             return item.orderId === Id
    //         })
    //     }

    //     if (transporteUnico.length > 0) {
    //         this.filtroTransporte = [...transporteUnico];

    //     } else {
    //         this.filtroTransporte = this.transporte;
    //     }
    //     // if (this.isObjEmpty(transporteUnico)) {
    //     //     this.filtroTransporte = this.transporte;
    //     // } else 
    //     // {

    //     // }
    // }
    // handleBuscarTransporte(tipo, Id) {
    //     var transporteUnico = [];
    //     const lowercasedId = Id.toLowerCase(); // Convert Id to lowercase

    //     if (tipo === 'transporte') {
    //         transporteUnico = this.transporte.filter(item => {
    //             const lowercasedTransporteId = item.IdTransporte.toLowerCase(); // Convert item's IdTransporte to lowercase
    //             return lowercasedTransporteId.includes(lowercasedId);
    //         });
    //     } else {
    //         transporteUnico = this.transporte.filter(item => {
    //             const lowercasedOrderId = item.orderId.toLowerCase(); // Convert item's orderId to lowercase
    //             return lowercasedOrderId === lowercasedId;
    //         });
    //     }

    //     if (transporteUnico.length > 0) {
    //         this.filtroTransporte = [...transporteUnico];
    //     } else {
    //         this.filtroTransporte = this.transporte;
    //     }
    // }

    handleBuscarTransporte(tipo, Id) {
        const lowercasedId = Id.toLowerCase(); // Convert Id to lowercase

        if (tipo === 'transporte') {
            this.filtroTransporte = this.transporte.filter(item => {
                const lowercasedTransporteId = item.IdTransporte.toLowerCase(); // Convert item's IdTransporte to lowercase
                return lowercasedTransporteId.includes(lowercasedId);
            });
        } else {
            this.filtroTransporte = this.transporte.filter(item => {
                const lowercasedOrderId = item.orderId.toLowerCase(); // Convert item's orderId to lowercase
                return lowercasedOrderId.includes(lowercasedId);
            });
        }

        if (this.filtroTransporte.length === 0) {
            this.filtroTransporte = this.transporte;
        }
    }

    isObjEmpty(obj) {
        return Object.keys(obj).length === 0;
    }

    handleOnChangeStatus(event) {

        this.estatus = 'Todos';

        let transportePorEstatus = [];

        if (this.estatus === 'Todos') {

            this.filtroTransporte = [...this.data];
            return;
        }

        transportePorEstatus = this.transporte.filter(item => {
            return item.Status == this.estatus
        })

        if (!this.isObjEmpty(transportePorEstatus)) {
            this.filtroTransporte = [...transportePorEstatus];
        } else {

        }



    }


    handleSelectedTransporte(event) {
        this.actualTransporte = event.detail;
        
        this.actualTransportista = {
            IdTransportista: this.actualTransporte.informacionDeTransportista.IdTransportista,
            Nombre: this.actualTransporte.informacionDeTransportista.Nombre,
            Telefono: this.actualTransporte.informacionDeTransportista.Telefono,
            Email: this.actualTransporte.informacionDeTransportista.Email,
            orderid: this.actualTransporte.orderId,
            motivo: this.actualTransporte.motivo,
            Evidencia: this.actualTransporte.Evidencia
            // FotoChecking: this.actualTransporte.Transportista.FotoChecking,

        } 

        if (this.actualTransporte.Comentario) {
            this.comentario = this.actualTransporte.Comentario;
        } else {
            this.comentario = 'No Tiene comentarios.';
        }




        // if (this.actualTransporte.Transportista.hasOwnProperty('Comentarios')) {
        //     this.comentarios = this.actualTransporte.Transportista.Comentarios;
        // } else {
        //     console.log('No Tiene comentarios.');
        // }
        this.isTransporte = true;
    }


    handleToggleSection(event) {
        this.activeSectionMessage =
            'Open section name:  ' + event.detail.openSections;
        console.log("Estamos probando insumos");
    }


    // Funciones de editar entrega
    handleEditarEntrega() {

        let orderId = this.actualTransportista.orderid;


        if (orderId) {
            getOrderProduct({ orderId: orderId })
                .then((result) => {
                    console.log(result);
                    this.insumosProductos = result;
                    this.filteredProducts = this.insumosProductos;
                    console.log(this.filteredProducts, "loas products");

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
        this.isParcial = true;
        const dialog = this.template.querySelector('c-avonni-dialog');
        dialog.show();



    }

    handleSelect(event) {
        this.selectedParcialOption = event.target.value;
        console.log("Selected Option: ", this.selectedParcialOption);

        // if (this.selectedParcialOption != 'Seleccionar') {
        //     // this.isOptionSelected = true;
        //     // this.checkAllVariablesForParcialButton();

        // } else if (this.selectedParcialOption === 'Seleccionar') {
        //     // this.isOptionSelected = false;
        //     // this.checkAllVariablesForParcialButton();
        // }

        // if (this.selectedParcialOption === 'Otro( explique )') {
        //     console.log(this.selectedParcialOption, " esta funcionando el select");
        //     this.isotraDesviacion = true;
        //     // this.isOptionSelected = false;
        //     // this.checkAllVariablesForParcialButton();


        // } else {
        //     this.isotraDesviacion = false;
        // }

    }


    options = [{
            label: 'Exceso de suminis., causa descon.',
            value: 'Exceso de suminis., causa descon.'
        },
        {
            label: 'Falta de suminis. causa descon.',
            value: 'Falta de suminis. causa descon.'
        },
        {
            label: 'Falta certificado',
            value: 'Falta certificado'
        },
        {
            label: 'Falta carta garantia de canje',
            value: 'Falta carta garantia de canje'
        },
        {
            label: 'Falta factura, remisión, ord R',
            value: 'Falta factura, remisión, ord R'
        }, {
            label: 'Falta Contrato, Pedito, O.C',
            value: 'Falta Contrato, Pedito, O.C'
        },
        {
            label: 'Falta Carta dustribución',
            value: 'Falta Carta dustribución'
        },
        {
            label: 'Falta otro documento',
            value: 'Falta otro documento'
        },
        {
            label: 'Faltante medicamento',
            value: 'Faltante medicamento'
        },
        {
            label: 'Otro( explique )',
            value: 'Otro( explique )'
        }
    ];

    handleAgregarMateriales() {
        this.isAgregarMateriales = true;
        this.isParcial = false;
    }


    @track selectedProduct;
    @track keyBuscar = '';


    handleBuscarProducto(event) {

        this.filteredProducts = this.insumosProductos;

        this.keyBuscar = event.target.value.toLowerCase();
        console.log(this.keyBuscar, " el key");
        this.filteredProducts = this.insumosProductos.filter((product) => {
            console.log(product.Product__r.Name);
            product.Product__r.Name.toLowerCase().includes(this.keyBuscar)
            if (product.Product__r.Name.toLowerCase().includes(this.keyBuscar)) {
                return product;
            }
        });

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
        console.log(quantityItem, " la cantidad");



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
        const newItem = { id: itemId, name: itemName, cantidadDePiezasFaltantes: quantity };
        let ordenItem = { id: itemId, cantidadDePiezasFaltantes: this.selectedQuantityValue };
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

        this.isAgregarMateriales = false;
        this.isProductParcial = false;
        this.isMaterialesAgregados = true;
        this.selectedQuantityValue = 0;
        // checkAllVariablesForParcialButton();

    }


    // botones de entrega parcial
    handleOptionsParcial(event) {

        const cardToShow = event.target.dataset.card;
        console.log(cardToShow);
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

    handleCancel() {
        const dialog = this.template.querySelector('c-avonni-dialog');
        dialog.hide();
        this.isAgregarMateriales = false;
        this.isParcial = false;

        // TODO: need to clean the arrays and object being used by the modal
        this.filteredProducts = [];
        this.insumosProductos = [];
        this.arrayParcialItem = [];
        this.ordenItemsUpdates = [];
        this.notes = '';
    }

    handleMotivoSelection(event) {
        const motivo = event.target.value;

        this.selectedMotivo = motivo[0];

        console.log(this.selectedMotivo);


        if (this.selectedMotivo === 'Otro( explique )') {
            // console.log(this.selectedParcialOption, " esta funcionando el select");
            this.isotraDesviacion = true;
            // this.isOptionSelected = false;
            // this.checkAllVariablesForParcialButton();


        } else {
            this.isotraDesviacion = false;
        }
    }

    handleNotaMotivoParcial(event) {
        this.selectedMotivo = event.target.value;

    }

    createJSONString() {
        const date = new Date();
        const apexFormattedDate = date.getUTCFullYear() + "-" +("0" + (date.getUTCMonth() + 1)).slice(-2) + "-" +("0" + date.getUTCDate()).slice(-2);
        const apexFormattedTime = ("0" + date.getHours()).slice(-2) + ":" + ("0" + date.getMinutes()).slice(-2) + ":" + ("0" + date.getSeconds()).slice(-2);

        const orderUpdates = {
            descripcion: this.notes,
            rejectionImage: this.base64Image ? this.base64Image : null,
            orderItemsUpdates: this.ordenItemsUpdates,
            desviacion: this.selectedMotivo,
            selectedDate: apexFormattedDate,
            selectedTime: apexFormattedTime
        };

        const jsonString = JSON.stringify(orderUpdates);
        return jsonString;

    }

    async handleGuardarParcial() {
        const result = await LightningConfirm.open({
            message: '¿Está seguro de guardar su entrega como parcial?',
            variant: 'headerless',
            label: 'Entrega Parcial',
        });

        if (result) {
            const orderId = this.actualTransportista.orderid;
            const jsonString = this.createJSONString();
            console.log(jsonString);
            editarOrdenParaEnviarAFirma({ orderId: orderId, ordenParcialJson: jsonString })
                .then((result) => {
                    if (result) {
                        const toastParcialGuardar = new ShowToastEvent({
                            title: 'Entrega Parcial Exitosa',
                            message: 'Su entrega Parcial ha sido guardad con éxito',
                            variant: 'success'
                        });
                        this.dispatchEvent(toastParcialGuardar);
                        console.log(result, "Se hizo el update parcial");
                       // window.location.reload();
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
            this.isRechazar = false;
        }


    }


    handleCapture(event) {
        this.isCargarImg = true;
        const file = event.target.files[0];
        const reader = new FileReader();
        reader.onload = () => {
            this.base64Image = reader.result;
            this.renderKey = Date.now(); // Force re-render with a new unique key
        };
        if (file) {
            reader.readAsDataURL(file);
        }

    }

    isEvidenciaCargada;
    isEvidenciaAgregada;
    ischeckin;

    async handleFirmar() {

        const result = await LightningConfirm.open({
            message: '¿Está seguro de Aprobar y Certificar esta Orden?',
            variant: 'headerless',
            label: 'Aprobar Y Enviar A Firma',
        });

        if (result) {

            const parentId = this.actualTransportista.orderid;
            console.log(this.actualTransportista.orderid);
            if (parentId) {
                console.log('firmando');
                firmarOrden({ orderId: parentId })
                    .then((result) => {
                        console.log(result);
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: 'Firmada correctamente',
                                variant: 'success',
                            }),
                        );

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



        } else if (!result) {
            console.log("No aceptó");
        }


    }




    uploadImage() {
        this.isEvidenciaCargada = true;
        this.isEvidenciaAgregada = true;
        console.log("Funciona");
        const fileName = 'evidencia-image.jpg';
        const base64Data = this.base64Image.split(',')[1];
        const parentId = this.actualTransportista.orderid;
        console.log("La orden foto ", this.actualTransportista.orderid);
        const self = this;
        if (parentId) {

            saveImage({ fileName: fileName, base64Data: base64Data, parentId: parentId, isCheckin : false })
                .then((result) => {
                    console.log(result);

                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Image uploaded successfully',
                            variant: 'success',
                        }),
                    );
                    self.deleteImage();
                    // window.location.reload();
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

    /////////////

    deleteImage() {
        this.isCargarImg = false;


        this.base64Image = null;

    }


   
    handleNota(event) {

        this.notes = event.target.value;
        if (this.notes.trim() != '') {
            this.isNota = true;
            // this.checkAllVariablesForRechazarButton();


        } else {
            this.isNota = false;
            // this.checkAllVariablesForRechazarButton();
        }


    }




}