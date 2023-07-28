import { LightningElement, wire, track} from 'lwc';
import { subscribe, MessageContext, publish } from 'lightning/messageService';
import SET_GENERAR_PEDIDOS_MENU from '@salesforce/messageChannel/set_generar_pedidos_menu__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {exportCSVFile} from 'c/utils';
import umuRecordSelected from '@salesforce/messageChannel/umu_record_selected__c';
import getCarritoData from '@salesforce/messageChannel/get_carrito_pedido__c';
import getActiveDpn from '@salesforce/apex/UserContactClass.getActiveDPNListFromUser';
import getDpnNoOrdinary from '@salesforce/apex/UserContactClass.getDpnNoOrdinary';
import getDisponibilidadData from '@salesforce/apex/UserContactClass.getDisponibilidadSkus';
import getSuppliesByProgram from '@salesforce/apex/SuppliesController.getSuppliesByProgram';
import orderType from '@salesforce/messageChannel/order_type__c';
import USER_ID from '@salesforce/user/Id';
import MyModal from 'c/insumosGuardarModal';

const columns = [
    {label: 'Clave', fieldName: 'Clave', type: 'text'},
    {label: 'Descripción', fieldName: 'Descripcion', type: 'text'},
    {label: 'DPN', fieldName: 'DPN', type: 'text'},
    {label: 'Validado', fieldName: 'Validado', type: 'text'},
    {label: 'Disponible En DPN', fieldName: 'DisponibleEnDpn', type: 'text'},
    {label: 'Disponible en CENADI', fieldName: 'DisponibleASolicitar', type: 'text'},
    //{label: 'Existencia De Unidad', fieldName: 'ExistenciaDeUnidad', type: 'text'},
    //{label: 'Disponible En Cenadi', fieldName: 'DisponibleEnCenadi', type: 'text'},
    {label: 'En Tránsito', fieldName: 'EnTransito', type: 'text'},
    {label: 'Cantidad', fieldName: 'Cantidad', type: 'text', editable: true },
    {label: 'Acción', fieldName: 'Action', type: 'text'},
];

const columnsNoOrdinary = [
    {label: 'Clave', fieldName: 'Clave', type: 'text'},
    {label: 'Descripción', fieldName: 'Descripcion', type: 'text'},
    {label: 'Disponible En DPN', fieldName: 'DisponibleEnDpn', type: 'text'},
    {label: 'Disponible en CENADI', fieldName: 'DisponibleASolicitar', type: 'text'},
    {label: 'En Tránsito', fieldName: 'EnTransito', type: 'text'},
    {label: 'Cantidad', fieldName: 'Cantidad', type: 'text', editable: true },
    {label: 'Acción', fieldName: 'Action', type: 'text'},
];

const pedidosCol = [
    {label: 'Clave', fieldName: 'Clave', type: 'text'},
    {label: 'Insumos', fieldName: 'Insumos', type: 'text'},
    {label: 'DPN', fieldName: 'Dpn', type: 'text'},
    {label: 'Cantidad Validada Acumulada', fieldName: 'CantidadValidadaAcumulada', type: 'text'},
    {label: 'Disponible En DPN', fieldName: 'DisponibleEnDpn', type: 'text'}
];

// Descripion, DPN , Validado, Disponible, Existencia de unidad, Disponible en Cenadi, en transito, Piezas(cantidad)
export default class InsumosTableList extends LightningElement {

    @wire(MessageContext)
    messageContext;

    // Boolean
    isUnidadMedica = true;
    isPedidos = false;
    isGenerarPedido = true;
    isShowDpnError = false;
    isLoading = false;
    isInputValidate = false;
    isMultiplo = true;
    isSecondStep = false;
    noOrdinary = false;
    isUmuSeleccionada = false;
    isDataLoading = true;
    isRendered = false;
    isCargar = false;
    isProgressDisabled = false;
    isLocalStorage = true;
    isFirstTime = false;

    // Input Table Value
    pedidosCol = pedidosCol;
    columns = columns;
    columnsNoOrdinary = columnsNoOrdinary;

    // Array of object
    listaNuevosPedidos = [];
    dpnList = [];
    dpnSolicitarList = [];
    dpnCarrito = [];
    List = [];
    localStorageData;

    //obj
    error;

    // Text
    titleForSearch = 'Consultar DPN';
    search = '';
    accountId = '';
    userId;

    // Number
    totalInsumos = 0;
    totalPiezas = 0;
    cantidad;

    //prueba
    claves = ['010000574x`100'];

    get tamañoValidoDeDPN(){
        return this.initialRecords.length > 0;
    }

    get mostrarOcultarTabla(){
        return this.isUmuSeleccionada;
    }

    get showTitleForSearch(){
        if(this.isGenerarPedido){
            return 'Consultar DPN'
        }else{
            return 'Insumos'
        }
    }

    containsObject(obj, list) {
        var i;
        for (i = 0; i < list.length; i++) {
            if (list[i] === obj) {
                return true;
            }
        }
        return false;
    }

    validateInput(element, insumo){
        console.log("Inside validate input");
        console.log(JSON.parse(JSON.stringify(insumo)));

        var errorMessage = '';
        let isMultiplo = false;

        if(insumo.PiezaPorPaquete != 0) isMultiplo = this.validateMultiplo(insumo.PiezaPorPaquete, element.value);

        if(element.value > insumo.DisponibleEnDpn && !this.noOrdinary){
            errorMessage = 'La cantidad de la DPN ha sido excedida';
        } else if(element.value > insumo.DisponibleASolicitar){
            errorMessage = 'La cantidad disponible a solicitar ha sido excedida';
        } else if(!isMultiplo && insumo.PiezaPorPaquete && insumo.PiezaPorPaquete != undefined){
            errorMessage = `Este insumo solo puede solicitarse en múltiplos de ${insumo.PiezaPorPaquete}`;
        } else if(element.value <= 0 || element.value == null){
            errorMessage = 'La cantidad mínima a ingresar es 1';
        } else if(!Number.isInteger(Number(element.value))) {
            errorMessage = 'Ingrese números enteros, no decimales';
        }

        element.setCustomValidity(errorMessage);
        this.isInputValidate = (errorMessage === '');
        element.reportValidity();
    }

    validateMultiplo(multiplo, value) {
        const arrayMultiplo = multiplo.split(",");
        console.log('multiplo: ' + multiplo + ' | array Multiplo: ' + arrayMultiplo)
        if (arrayMultiplo.length > 1) {
          return arrayMultiplo.some((element) => value % element === 0);
        } else {
          return value % arrayMultiplo[0] === 0;
        }
    }

    handleOnChange(event){
        //this.cantidad = event.detail.value;
    }

    handleShowDescripcion(event){
        const clave = event.target.dataset.id;
        const nombreBoton = event.target.dataset.name;
        if(nombreBoton === "Mostrar"){
            this.displayedItems = this.displayedItems.map(item =>
                item.Clave === clave
                  ? { ...item, mostrarDescripcion: true }
                  : item
              );
        } else {
            console.log('Ocultar');
            this.displayedItems = this.displayedItems.map(item =>
                item.Clave === clave
                  ? { ...item, mostrarDescripcion: false }
                  : item
              );
        }
    }

    handleRemovePedidos(event){

        const clave = event.target.dataset.id;
        const removerProducto = this.dpnList.find(item => item.Clave == clave);

        removerProducto.mostrarBoton = true;
        removerProducto.inputDisabled = false;
        
        this.totalPiezas = this.totalPiezas - removerProducto.Cantidad;
        this.totalInsumos -= 1;

        removerProducto.Cantidad = '';

        this.displayedItems = this.displayedItems.map(item =>
                    item.Clave === clave
                      ? { ...item, mostrarBoton: true, inputDisabled: false, Cantidad: ''}
                      : item
        );
        
        let indice = this.dpnCarrito.findIndex(item => item.Id === removerProducto.Id);
        this.dpnCarrito.splice(indice, 1);
        
        // delete this.dpnCarrito[indice];

        this.updateDisplayedItems();
        
    }

    susbcribeToMessageChannel(){
        subscribe(
            this.messageContext,
            SET_GENERAR_PEDIDOS_MENU,
            (message) => this.handleMessage(message)
        );
    }

    showToast(title, message, variant, mode) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(event);
    }

    handleMessage(message){
        if(message.isSolicitarPedidos){
            this.isUnidadMedica = true;
            this.isPedidos = false;
            this.isGenerarPedido = false
            this.isSecondStep = true;
            console.log('Es No Ordinario: ', this.noOrdinary);
            this.localStorageData = JSON.parse(localStorage.getItem("Data"));
            this.resetPagination();
            this.updateDisplayedItems();
        }else if(message.isPedidos){
            this.isUnidadMedica = true;
            this.isPedidos = true;
            this.isGenerarPedido = false;
            this.isSecondStep = false;
            this.resetPagination();
            this.updateDisplayedItems();
        }else if(message.isGenerarPedidos){
            this.isGenerarPedido = true;
            this.isPedidos = false;
            this.isSecondStep = false;
            this.resetValues();
        }
        else{
            this.isUnidadMedica = false;
            this.isPedidos = false;
            this.isGenerarPedido = false;
        }
        console.log(message.isSolicitarPedidos);
        console.log(message.isPedidos);
        console.log(message.isGenerarPedidos);
        console.log(this.isPedidos);
    }

    resetValues(){
        this.search = '';
        this.dpnList = [];
        this.List = [];
        this.dpnSolicitarList = this.List;
        this.dpnCarrito = [];
        this.totalInsumos = 0;
        this.totalPiezas = 0;
        this.isUmuSeleccionada = false;
    }

    loadData() {
        subscribe(
            this.messageContext,
            umuRecordSelected,
            (message) => this.handleAccount(message)
        );
    }
    connectedCallback(){
        const localStorageData = localStorage.getItem("Data");
        this.localStorageData = JSON.parse(localStorageData);
    }

    handleAccount(message) {
        this.accountId = message.selectedUmu;
        this.loadOrderType();
       // this.checkGuardarData();
    }

    checkGuardarData(){
        const storedData = this.localStorageData;

        if(storedData){
            let checkAccountLocalStorage = (storedData.userId != USER_ID) || (this.accountId != storedData.accountId) || (this.noOrdinary != storedData.isNoOrdinary) ? true: false;
            this.isProgressDisabled = checkAccountLocalStorage;
        }else{
            this.isProgressDisabled = true;
        }
    }

    get mostrarBotonrefresh(){
        if(this.isProgressDisabled){
            return true;
        }else{
            return false;
        }
    }

    loadOrderType() {
        return new Promise((resolve) => {
          subscribe(
            this.messageContext,
            orderType,
            (message) => {
              this.handleOrderType(message);
              resolve(); // Resuelve la promesa después de llamar a handleOrderType
            }
          );
        });
    }

    handleOrderType(message) {
        this.isDataLoading = true;
        this.noOrdinary = message.isNoOrdinario ? message.isNoOrdinario : false;
        console.log('Is ordinary: ' + this.noOrdinary);
        this.checkGuardarData();
        this.handleLoadData();
    }

    columnHeader = ['CLAVE', 'INSUMO', 'DPN', 'CANTIDAD VALIDADA',
    'DISPONIBLE EN DPN', 'DISPONIBLE A SOLICITAR'];

    downloadCSVFile(){
        let doc;
        this.columnHeader.forEach(element => {
          if(doc) {
            doc += element + ',';
          } else {
            doc = element + ',';
          }
        });
        this.dpnList.forEach(record => {
          doc += '\n';
          doc += record.Clave + ',';
          doc += record.Descripcion + ',';
          doc += record.DPN + ',';
          doc += record.CantidadValidadaAcumulada + ',';
          doc += record.DisponibleEnDpn + ',';
          doc += record.DisponibleASolicitar + ',';
        });
        let downloadElement = document.createElement('a');
        downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURIComponent(doc);
        downloadElement.target = '_self';
        downloadElement.download = 'Productos DPN.csv';
        document.body.appendChild(downloadElement);
        downloadElement.click();
    }

    initialRecords = [];
    isFirstTime = true;
    totalRecords = 0;
    currentPage = 1;
    actualRecords = 0;
    totalPages = 0;
    displayedItems = [];
    displayedItemsRecord = [];
    isFirstPage = true;
    isLastPage = false;
    pageSize = 30;

    @track persistentData = null;
    @track parsedData = null;
    @track persistentOldData = null;
    @track parsedOldData = null;
    allInputs = [];
    rendered = 0;

    renderedCallback() {
        if(!this.isRendered) {
            console.log('rendered table');
            this.susbcribeToMessageChannel();
            this.loadData();
            this.isRendered = true;
        }
    }

    handleAgregarInsumo(event){
        const clave = event.target.dataset.id;
        const nombreBoton = event.target.dataset.name;
        const nuevoInsumo = this.List.find(ele => ele.Clave === clave);
        const input = this.template.querySelector(`lightning-input[data-id="${clave}"][data-element="input-field"]`);

        console.log(nombreBoton);
        // console.log(JSON.parse(JSON.stringify(input)));

        this.cantidad = input.value;

        if(nombreBoton === "Add") {
            this.validateInput(input, nuevoInsumo);
            if(this.isInputValidate){
                nuevoInsumo.inputDisabled = true;
                nuevoInsumo.Cantidad = this.cantidad;
                nuevoInsumo.mostrarBoton = false;
                // Testing

                this.displayedItems = this.displayedItems.map(item =>
                    item.Clave === clave
                      ? { ...item, mostrarBoton: false, inputDisabled: true, Cantidad: this.cantidad}
                      : item
                  );
                const hasKey = this.dpnCarrito.some(item => item.Clave === nuevoInsumo.Clave);

                // Codigo agregado para evitar agregar un insumo que tenga el valor como null o vacio.
                let isDpnCarritoCantida = (nuevoInsumo.Cantidad != undefined) && (nuevoInsumo.Cantidad != '') ? true: false;
                // 
                if(!hasKey && isDpnCarritoCantida){
                    this.dpnCarrito.push(nuevoInsumo);

                    console.log('carro: ', JSON.stringify(this.dpnCarrito));

                    this.totalInsumos += 1;
                    this.totalPiezas += parseInt(nuevoInsumo.Cantidad);
                    this.showToast('Success', 'Producto agregado correctamente', 'success', 'pester');
                    const payload = {
                        Carrito: this.dpnCarrito
                    }
                    publish(this.messageContext, getCarritoData, payload);
                }
            }
        } else{
            nuevoInsumo.inputDisabled = false;
            nuevoInsumo.mostrarBoton = true;

            this.displayedItems = this.displayedItems.map(item =>
                item.Clave === clave
                  ? { ...item, mostrarBoton: true, inputDisabled: false}
                  : item
              );

            const hasKey = this.dpnCarrito.some(item => item.Clave === nuevoInsumo.Clave);

            if(hasKey){
                this.dpnCarrito = this.dpnCarrito.filter(item => item.Clave !== nuevoInsumo.Clave);

                console.log('carro: ', JSON.stringify(this.dpnCarrito));

                this.totalInsumos -= 1;
                this.totalPiezas -= parseInt(nuevoInsumo.Cantidad);
                this.showToast('Success', 'Producto removido correctamente', 'success', 'pester');
                const payload = {
                    Carrito: this.dpnCarrito
                }
                publish(this.messageContext, getCarritoData, payload);
            }
        }

        this.List = [...this.List];
    }


    async handleClick() {
        const carrito = [...this.dpnCarrito];
        const result = await MyModal.open({
            // `label` is not included here in this example.
            // it is set on lightning-modal-header instead
            size: 'small',
            description: 'Accessible description of modal\'s purpose',
            guardarData: {
                accountId: this.accountId,
                isNoOrdinary: this.noOrdinary,
                userId: USER_ID,
                totalInsumos: this.totalInsumos,
                totalPiezas: this.totalPiezas,
                carrito: carrito
            }
        });
        if(result === 'okay'){
            this.isProgressDisabled = true;
            this.showToast('Success', 'Data guardada excitosamente', 'success', 'pester');
        }
    }

    handleSelectEvent(event){
        this.isProgressDisabled = event;
    }

    handleSaveProgress(){
        let isLocalStorage = localStorage.getItem("Data") ? true: false;

        if(isLocalStorage && this.dpnCarrito.length !== 0){
            this.handleClick();
        }else if(this.dpnCarrito.length !== 0){
            const carrito = [...this.dpnCarrito];
            const data = {
                accountId: this.accountId,
                carrito: carrito,
                isNoOrdinary: this.noOrdinary,
                userId: USER_ID,
                totalInsumos: this.totalInsumos,
                totalPiezas: this.totalPiezas
            }
            localStorage.setItem("Data", JSON.stringify(data));
            this.showToast('Success', 'Data guardada excitosamente', 'success', 'pester');
        }else{
            console.log('Carrito vacio');
        }
        
    }

    handleResetProgress(){
        localStorage.removeItem("Data");
        this.localStorageData = [];
        this.isProgressDisabled = true;
    }

    handleGetProgress(){
        // if(this.isCargar) return;
        // Recuperar los datos almacenados en localStorage
        var storedData = localStorage.getItem("Data");

        // Verificar si se encontraron datos
        if (storedData) {
            // Convertir los datos de cadena JSON a un objeto JavaScript
            const Data = JSON.parse(storedData);

            let isDataMatch = (Data.accountId == this.accountId) && (Data.isNoOrdinary == this.noOrdinary) && (Data.userId == USER_ID) ? true: false;
            
            const carritoGuardado = [];

            if(isDataMatch){
                this.showToast('Success', 'Insumos cargados excitosamente.', 'success', 'pester');
                // this.isCargar = true;
                let nuevaListaObjetos = Data.carrito.map(objeto => {
                    var indice = this.dpnList.findIndex(item => item.Id === objeto.Id);
                    const producto = this.dpnList.find(item => item.Id == objeto.Id);
                    producto.Cantidad = objeto.Cantidad;
                    producto.inputDisabled = objeto.inputDisabled;
                    producto.mostrarBoton = objeto.mostrarBoton;
                    
                    // Verificar si se encontró el objeto
                    if (indice !== -1) {
                        carritoGuardado.push(producto);
                    }
                });

                this.dpnCarrito = carritoGuardado;
                this.totalPiezas = Data.totalPiezas;
                this.totalInsumos = Data.totalInsumos;
                this.handleResetProgress();

                const payload = {
                    Carrito: this.dpnCarrito
                }
                publish(this.messageContext, getCarritoData, payload);
            }
        }

     
    }
   

    resetPagination() {
        this.currentPage = 1;
        this.actualRecords = 0;
        this.isFirstTime = true;
    }

    async handleLoadData(message){
        this.resetPagination();
        var payload = [];
        var productKeys = [];

        if(this.accountId == 'Seleccionar Unidad Medica'){
            this.resetValues();
            return;
        }

        this.isUmuSeleccionada = true;
        const getDpnData = this.noOrdinary ? getDpnNoOrdinary() : getActiveDpn({ accountId: this.accountId });
        try {
            const result = await getDpnData;(
            result.forEach(item => {
                const { Product__r } = item;
                let consumido = item.Consumido__c > 0 && item.Consumido__c != null ? item.Consumido__c : 0;
                let disponible = item.L_mite_Mensual__c - consumido;
                let row = {
                    Id: Product__r.Id,
                    Clave: Product__r.Product_Code_ID__c,
                    Descripcion: Product__r.Description__c,
                    Nombre: Product__r.Name,
                    DPN: item.L_mite_Mensual__c,
                    Cantidad: '',
                    CantidadValidadaAcumulada: consumido,
                    DisponibleEnDpn: disponible,
                    DisponibleASolicitar: 0,
                    //MostrarPiezasPorPaquete: false,
                    mostrarBoton: true,
                    mostrarDescripcion: false,
                };
                // console.log('Item: ', JSON.stringify(row));
                productKeys.push(Product__r.Product_Code_ID__c);
                payload.push(row);
            }));

            this.List = [...payload];
            this.handleDisponibilidad(productKeys);
            this.dpnList = this.List;
            this.initialRecords = this.List;
            this.updateDisplayedItems();
        } catch (e) {
            console.log('An error has occurred ' + error.message);
            this.resetValues();
        }
    }

    handleDisponibilidad(idProducto){

        console.log("***Inside handle disponibilidad***");

        //productKeys
        let idProductos = JSON.stringify(idProducto);
        getDisponibilidadData({jsonData: idProductos}).then(result =>{
            const data = JSON.parse(result);
            const copiarLista = this.List.slice();

            console.log(data);
            console.log(JSON.parse(JSON.stringify(copiarLista)));

            //const updatedClaveList = [];
            copiarLista.forEach(element =>{ 
                data.forEach(record =>{ 
                    if(element.Clave == record.sku){
                        element.DisponibleASolicitar = record.availability;
                        //element.PiezaPorPaquete =  record.packages_details.length > 0 ? record.packages_details.map(piece => piece.quantity_pieces_package).join(", ") : 0;
                        element.PiezaPorPaquete =  record.packages_details.length > 0 ? record.packages_details
                        .map(piece => piece.quantity_pieces_package)
                        .filter(quantity => quantity !== 1)
                        .join(", ") : 0;
                        // element.MostrarPiezasPorPaquete = false; 
                        // const foundQtyPiecesPckg = record.packages_details.find(piece => piece.quantity_pieces_package > 1);
                        //console.log('Disponible En Cenadi: ', JSON.stringify(element));
                        // console.log(JSON.stringify(foundQtyPiecesPckg));
                        // if(foundQtyPiecesPckg && foundQtyPiecesPckg.length > 0){
                        //     element.MostrarPiezasPorPaquete = true;
                        // } 
                        // updatedClaveList.push(element.Clave);
                        // return;
                    } 
                    // else if (!updatedClaveList.includes(element.Clave)){
                    //     element.DisponibleASolicitar = 0;
                    //     element.MostrarPiezasPorPaquete = false;                 
                    // }
                })
            }); // Holis! :) Holi!waos, impresionada // Hahaha, pues nada. A fix esto pues. Le dimos xd

            // validar el field de disponibleASolicitar
            const listaActualizada = copiarLista.map(item => {
                if (item.DisponibleASolicitar > 0) {
                  return { ...item, inputDisabled: false };
                } else {
                  return { ...item, inputDisabled: true };
                }
            });

            this.List = listaActualizada;
            this.dpnList = listaActualizada;
            this.initialRecords = listaActualizada;
            this.dpnSolicitarList = listaActualizada;

            this.updateDisplayedItems();
            this.isDataLoading = false;
        }).catch(error =>{
            console.log('An error has occured: ' + error.message());
        })
    }

    updateDisplayedItems() {
        if(this.isFirstTime) {
            if(this.isPedidos) {
                this.totalPages = Math.ceil(this.dpnCarrito.length / this.pageSize);
                this.totalRecords = this.dpnCarrito.length;
            } else {
                this.totalPages = Math.ceil(this.dpnList.length / this.pageSize);
                this.totalRecords = this.dpnList.length;
            }
        }
        const startIndex = (this.currentPage - 1) * this.pageSize;
        const endIndex = this.currentPage * this.pageSize; 
        this.displayedItems = this.isPedidos ? this.dpnCarrito.slice(startIndex, endIndex) : this.dpnList.slice(startIndex, endIndex);

        this.isFirstPage = this.currentPage === 1;
        this.isLastPage = this.currentPage === this.totalPages;

        if(this.isFirstTime) {
          this.actualRecords += this.displayedItems.length;
          this.isFirstTime = false;
        }
    }

    handleNext(){
        if (this.currentPage < this.totalPages) {
          this.currentPage++;
          this.updateDisplayedItems();
          this.actualRecords += this.displayedItems.length;
        }
    }

    handlePrev(){
        if (this.currentPage > 1) {
          this.currentPage--;
          this.actualRecords -= this.displayedItems.length;
          this.updateDisplayedItems();
        }
    }

    getDpnBySearch(searchText){
        // verificar si el search value esta vacio, si es asi, retornar toda la lista.
        if(!searchText) {
            this.dpnList = this.List;
            this.dpnSolicitarList = this.List;
            return null;
        }

        let nuevaLista = this.dpnList.filter(element => {
             if (element.Clave == this.search) return element;
             else if(element.Descripcion.toLowerCase().includes(searchText))return element;
        })

        if(nuevaLista) this.dpnList = nuevaLista;
        if(nuevaLista && this.isUnidadMedica) this.dpnSolicitarList = nuevaLista;
    }

    // handleOnSearch(event){
    //     this.isLoading = true;
    //     this.search = event.target.value;
    //     const count = this.search.split("");
    //     let isCount = count.length >= 3 ? true: false;

    //     if(isCount || count.length == 0) this.getDpnBySearch(this.search);

    //     this.isLoading = false;
    // }

    handleOnSearch(event) {
        const searchKey = event.target.value.toLowerCase();
        const previousPage = this.currentPage;
        let searchRecords = [];

        if(searchKey) {
            this.dpnList = this.initialRecords;
            if (this.dpnList) {
                for (let record of this.dpnList) {
                let valuesArray = Object.values(record);
                for (let val of valuesArray) {
                    let strVal = String(val);
                    if (strVal) {
                        if (strVal.toLowerCase().includes(searchKey)) {
                            searchRecords.push(record);
                            //console.log('Search record: ', JSON.stringify(searchRecords));
                            break;
                        }
                    }
                }
                }
                this.currentPage = 1;
                this.dpnList = searchRecords;
                this.updateDisplayedItems();

                console.log(searchRecords.length);
                if(searchRecords.length < 30 || previousPage === this.totalPages) this.isLastPage = true;
            }
        } else {
            console.log('en el else de buscar');
            this.dpnList = this.initialRecords;
            this.updateDisplayedItems();
        }

        this.actualRecords = (this.currentPage - 1) * this.pageSize + this.displayedItems.length;
        this.currentPage = previousPage;
    }

    headers = {
        Clave: "Clave",
        Descripcion: "Insumos",
        DPN: "DPN",
        CantidadValidadaAcumulada: "Cantidad Validada Acumulada",
        CantidadSugerida: "Cantidad Sugerida",
        DisponibleEnDpn: "Disponible En Dpn"
    }

    htmlTableToExcel(){
       exportCSVFile(this.headers,this.dpnList,"dpn list");
    }

    getExternalProductData(clave){
        const json = '[{"sku":"010000574100" , "availability": 500, "package_key": true}, {"sku":"010000010300" , "availability": 500, "package_key": true}, {"sku":"010000010600" , "availability": 650, "package_key": true,"quantity_pieces_package": [8]}, {"sku":"010000010400" , "availability": 200, "package_key": true,"quantity_pieces_package": [50]}]';
        const skus = JSON.parse(json);
        const filter = skus.find(element => {
            if(element.sku === clave) return element;
        })
        return filter;
    }
}