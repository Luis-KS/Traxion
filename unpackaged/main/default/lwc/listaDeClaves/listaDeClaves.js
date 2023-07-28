import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import obtenerListaDeClaves from '@salesforce/apex/listaDeClavesControlador.obtenerListaDeClaves';
import mostrarDpnLineItem from '@salesforce/apex/listaDeClavesControlador.mostrarDpnLineItem';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const FIELDS = [
    'Account.Activar_Aviso_De_Prevision__c',
    'Account.Activar_Aviso_De_Responsable_Sanitario__c',
    'Account.Activar_Licencia_Sanitaria__c'
];

export default class ListaDeClaves extends LightningElement {

    @api
    recordId;
    error;

    account = {};
    productos;
    productosUI = [];
    productosRemovidos = [];
    showLoading = false;
    activeSectionsMessage = '';
    productoReinicio = [];

    get isMostrarListaDeClaves(){
        return this.productosUI.length > 0
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredAccount({ error, data }) {
        if (data) {
            this.account = {
                IsAvisoDePrevision:  data.fields.Activar_Aviso_De_Prevision__c.value,
                IsAvisoDeResponsable:  data.fields.Activar_Aviso_De_Responsable_Sanitario__c.value,
                IsLicenciaSanitaria:  data.fields.Activar_Licencia_Sanitaria__c.value,
            }
            this.mostrarClaves();
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.account = undefined;
        }
    }

    mostrarClaves(){
        obtenerListaDeClaves({Id: this.recordId, IsAvisoDePrevision: this.account.IsAvisoDePrevision, IsAvisoDeResponsable: this.account.IsAvisoDeResponsable, IsLicenciaSanitaria: this.account.IsLicenciaSanitaria}).then(result => {
            this.productosUI = result;
            this.productos = result;
            this.productoReinicio = [...result];
        }).catch(error =>{
            console.log('An error has occured: ', error.getMessage());
        })
    }


    handleDeleteProducto(event){
        console.log('this.productos: ', JSON.stringify(this.productos));
        const copiaProductos = [...this.productos];
        const producto = copiaProductos.find(item => item.Id == event.detail.Id);
        producto.Activo__c = false;
        
        this.productosRemovidos.push(producto);
  
        const copiaProductosUI = this.productosUI.slice();
        const nuevosProductos = copiaProductosUI.filter(item => item.Id !== event.detail.Id);

        this.productosUI = nuevosProductos;

        // Encontrar el índice del objeto con id igual al producto Id
        var indice = this.productos.findIndex(item => item.Id === producto.Id);

        // Verificar si se encontró el objeto
        if (indice !== -1) {
            // Eliminar el objeto
            this.productos.splice(indice, 1);
        }
    }
    
    handleAgregarProducto(){
   
        this.showLoading = true;

        setTimeout(() => {
            this.showLoading = false;
          }, 3000);

        // iterar por cada uno de los elementos y setear el field Activo__c a true    
        const nuevaListaProducto = this.productos.map(item => {
            return {
            ...item,
            Activo__c: true
            };
        });

        const listaActualizada = [...this.productosRemovidos, ...nuevaListaProducto];
   
        mostrarDpnLineItem({productList: listaActualizada}).then(result =>{
            this.showToast('Success', 'Insumos Agregados Exitosamente', 'success', 'pester');
            this.resetArrays();
            this.showLoading = false;
           
        }).catch(error =>{
            console.log('An error has occured: ', error.getMessage());
        })
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

    resetArrays(){
        this.productosUI = [...this.productoReinicio];
        this.productos = [...this.productoReinicio];
        this.productosRemovidos = [];

    }

    handleSectionToggle(event){
        console.log(event.detail.openSections);
    }

    handleCancelar(){
      this.resetArrays();
    }
}