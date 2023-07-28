import { LightningElement, api, track } from 'lwc';
import LightningModal from 'lightning/modal';
import createOrders from '@salesforce/apex/controladorGeneracionPedidos.deserializeOrders';
import summaryModal from 'c/modalDetalleOrden';
import createContentVersion from '@salesforce/apex/controladorGeneracionPedidos.createContentVersion';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import uploadFiles from '@salesforce/apex/FilesController.uploadFiles';
import checkGeneracionDePedido from '@salesforce/apex/UserContactClass.checkGeneracionDePedido';
import sendEmailSolicitudNoOrd from '@salesforce/apex/controladorGeneracionPedidos.sendEmailSolicitudNoOrd';

export default class ProgramConfirmationModal extends NavigationMixin(LightningElement) {
  @api carrito;
  @api umusSelected;
  @api inputs;
  @api program;
  @api extraData;

  @track content = null;

  dataToEmail = [];
  orderId;
  orders;
  isDataLoading = false;
  isProgram = false;
  programName = '';
  rendered = false;

  showModal = false;

  @api show() {
    this.showModal = true;
  }

  renderedCallback() {
    console.log('MODAL');

    console.log('carrito: ');
    console.log(JSON.stringify(this.carrito));

    if(this.showModal && !this.rendered) {
      // console.log('carrito: ');
      // console.log(JSON.stringify(this.carrito));
      // console.log('umus: ');
      // console.log(this.umusSelected);
      // console.log(JSON.stringify(this.umusSelected));
      // console.log('inputs: ');
      // console.log(JSON.stringify(this.inputs));
      // console.log('programs: ');
      // console.log(JSON.stringify(this.program));
      // console.log('extraData: ');
      // console.log(JSON.stringify(this.extraData));

      if(this.carrito.lenght > 1) {
        this.content = 'varios pedidos'
      } else {
        this.content = 'un pedido'
      }

      this.rendered = true;
    }
  }

  // async openSummaryModal(carrito, programa, esPrograma) {
  //   try {
  //     const result = await summaryModal.open({
  //       size: 'small',
  //       carrito: carrito,
  //       programa: programa,
  //       esPrograma: esPrograma
  //     });
  //     console.log(result);
  //   } catch (error) {
  //     console.error('Error opening modal:', error);
  //   }
  // }

  handleSave() {
    if(this.extraData.orderType == 'Ordinario/NoOrdinario') {
      console.log('handleOrderSave0');
      this.handleOrderSave();
    } else {
      console.log('handleOrdersSave0');
      this.handleOrdersSave();
    }
  }

  // GENERACION PEDIDOS

  async handleOrderSave() {
    this.isDataLoading = true;

    const order = await createOrders({payload: JSON.stringify([this.carrito])}).then(result => {
      console.log('Order created successfully');
      return result;
    }).catch(error =>{
      console.log('An error has occured: ' + error.getMessage());
    });

    console.log('here');
    console.log(JSON.parse(JSON.stringify(order)));

    const orderIds = order.map(ord => ord.Id);

    console.log('here2');

    if(Object.keys(this.extraData.fileData).length !== 0){
      console.log('hi hi');
      console.log(order[0]);
      const recordId = order[0].Id;

      console.log('file: ' + JSON.stringify([this.extraData.fileData]));
      const fileData = this.extraData.fileData;
      uploadFiles({filesToInsert: fileData, recordId: recordId}).then(result => {
        console.log(result, 'done');
      }).catch(error => {
        console.log('An error has occured: ' + error.getMessage);
      });
    }

    if(this.carrito.TipoDePedido == 'Ordinario'){
      console.log('Inside pedido ordinario');
      const isCreated = await this.handleGeneracionDePedido(order);
      console.log(isCreated);
      //if(!isCreated) return;
    } else{
        sendEmailSolicitudNoOrd({orderIds: orderIds}).then(result => {
          console.log('Se ha generado exitosamente: ');
          console.log(JSON.parse(JSON.stringify(result)));
        }).catch(error =>{
          console.log('An error has occured: ' + error.getMessage());
        });
    }

    this.orders = order;

    const modal = this.template.querySelector("c-modal-detalle-orden");
    modal.show();

    // this.openSummaryModal(order, '', false);
    // console.log('sended');

    this.showModal = false;
  }

  async handleGeneracionDePedido(orden) {
    console.log('init handle generacion de pedido: ');
    const orderIds = orden.map(ord => ord.Id);
    try {
      const result = await checkGeneracionDePedido({ orderIdList: orderIds });
      console.log('result: ' + result);
      const parsedResult = JSON.parse(result);
      const { traxion_response = {} } = parsedResult;
      const { completed_succesfully = false } = traxion_response;
      return completed_succesfully;
    } catch (error) {
      console.log('An error has occurred: ' + error.message());
      return false;
    }
  }

  // PROGRAMAS

  async handleOrdersSave() {
    this.isDataLoading = true;

    console.log('handleOrdersSave');
    const orders = await createOrders({ payload: JSON.stringify(this.carrito)})
    .then((result) => {
      if(result) {
        console.log('Pedido: ');
        console.log(JSON.parse(JSON.stringify(result)));
        return result;
      }
    }).catch(error =>{
      console.log('An error has occured creating the orders: ' + error.getMessage());
    });

    if(orders) {
      this.orders = orders;

      const orderIds = [];
      orders.forEach((order) => {
        orderIds.push(order.Id);
      });

      console.log('OrderId');
      this.orderId = orders[0].Id;
      console.log(this.orderId);

      this.generateDataToSendEmail();

      console.log('Here');
      const isCreated = await this.handleGeneracionDePedido(orders);
      console.log('Status WMS: ' + isCreated);
      if(!isCreated) {
        console.log('Return');
      }
      console.log('Here2');

      localStorage.removeItem('0');
      localStorage.removeItem('1');
      localStorage.removeItem('2');
      console.log(localStorage.getItem('0'));
      console.log(localStorage.getItem('1'));
      console.log(localStorage.getItem('2'));

      this.isProgram = true;
      this.programName = this.program.programName;

      const modal = this.template.querySelector("c-modal-detalle-orden");
      modal.show();

      console.log('Here3');

      // this.openSummaryModal(orders, this.program.programName, true);
      // console.log('sended');

      this.showModal = false;
    }
  }

  generateDataToSendEmail() {
    let dataList = [];
    const hasMaxDate = false;
    const orderType = this.extraData.orderType;

    this.umusSelected.forEach(umu => {
      console.log('umu processed: ' + JSON.stringify(umu));

      let order = this.orders.find(order => order.UMU__c === umu.id);
      console.log('order processed: ' + JSON.stringify(order));

      let date;
      console.log('pedido date: ' + order.Pedido__r.Fecha_Limite_de_Entrega__c);
      if(orderType == 'Emergencia Sanitaria' || orderType == 'Programa') {
        console.log('date1');
        date = new Date(); // TODO: MODIFICAR ESTA FECHA CON LA QUE INGRESA EL USUARIO
      } else {
        console.log('date2');
        date = new Date(order.Pedido__r.Fecha_Limite_de_Entrega__c);
      }

      console.log('date: ' + date);
      let anio = date.getFullYear();
      let mes = ('0' + (date.getMonth() + 1)).slice(-2);
      let dia = ('0' + date.getDate()).slice(-2);
      let formattedDate = `${anio}-${mes}-${dia}`;

      //const formattedDate = date.toISOString().split('T')[0];

      let filteredInputs = this.inputs.filter(input => input.umu === umu.id);
      filteredInputs.forEach(input => {
        let dataLine = {};
        dataLine.delegacion = umu.delegation;
        dataLine.umu = umu.number;
        dataLine.clavePresupuestal = umu.budget;
        dataLine.nombreUmu = umu.name;
        dataLine.tipoPedido = this.extraData.orderType;
        dataLine.fechaSolicitud = new Date().toISOString().slice(0, 10);
        dataLine.folio = order.Pedido__r.Folio_de_Pedido__c;
        dataLine.claveInsumo = input.code;
        dataLine.descripcion = input.description;
        dataLine.cantidadAutorizada = input.value;
        dataLine.cantidadSap = input.value;
        dataLine.estatus = 'AUTORIZADO';
        dataLine.fechaLimite = formattedDate;
        dataLine.programaId = this.program.programCode;
        dataLine.programaNombre = this.program.programName;
        dataList.push(dataLine);
      });
    });
    this.dataToEmail = dataList;
    this.generateCSVContent();
  }

  columnHeaderEmail = ['DELEGACION', 'UMU', 'CLAVE PRESUPUESTAL', 'NOMBRE UMU', 'TIPO DE PEDIDO',
  'FECHA DE SOLICITUD', 'FOLIO DEL PEDIDO', 'CLAVE', 'DESCRIPCION CLAVE', 'CANTIDAD AUTORIZADA', 'CANTIDAD COLOCADA EN SAP',
  'ESTATUS', 'FECHA LIMITE DE ENTREGA', 'ID DE PROGRAMA', 'PROGRAMA'];

  generateCSVContent() {
    let csvContent = this.columnHeaderEmail.join(',') + '\n';
    this.dataToEmail.forEach(record => {
      csvContent += record.delegacion + ',' + record.umu + ',' + "'" + record.clavePresupuestal + ',' +
      record.nombreUmu + ',' + record.tipoPedido + ',' + record.fechaSolicitud + ',' + "'" + record.folio + ',' +
      "'" + record.claveInsumo + ',' + record.descripcion + ',' + record.cantidadAutorizada + ',' + record.cantidadSap + ','
      + record.estatus + ',' + record.fechaLimite + ',' + record.programaId + ',' + record.programaNombre + '\n';
    });
    this.sendCSVEmail(csvContent);
  }

  sendCSVEmail(content) {
    let csvContent = content;
    let csvData = csvContent;

    let contentVersion = {
      Title: 'Documento General.csv',
      VersionData: btoa(csvData),
      PathOnClient: 'DocumentoGeneral.csv',
    };

    const uniqueClavePresupuestal = new Set(this.dataToEmail.map(item => item.clavePresupuestal));
    const sumCantidadAutorizada = this.dataToEmail.reduce((total, item) => total + parseFloat(item.cantidadAutorizada), 0); // Sumatoria de cantidadAutorizada
    const numItems = new Set(this.dataToEmail.map(item => item.claveInsumo));
    const dataSummary = {
      numItems: numItems.size,
      numCantidadUmus: uniqueClavePresupuestal.size,
      sumCantidadAutorizada: sumCantidadAutorizada
    };

    const programName = this.program.programName;
    const summaryJson = JSON.stringify(dataSummary);

    console.log('ContentVersion');
    console.log(JSON.stringify(contentVersion));
    console.log(summaryJson);
    console.log(programName);

    createContentVersion({ title: contentVersion.Title, versionData: contentVersion.VersionData, pathOnClient: contentVersion.PathOnClient,
      contactId: this.extraData.contactId, orderId: this.orderId, programName: programName, summaryJson: summaryJson})
    .then(result => {
      console.log('Operacion exitosa creando el ContentVersion: ');
      console.log(result);
    })
    .catch(error => {
      console.log('An error has occurred while creating the ContentVersion: ');
      console.log(error);
    });
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

  handleClose() {
    this.showModal = false;
  }
}

// export default class ProgramConfirmationModal extends NavigationMixin(LightningModal) {
//   @api carrito;
//   @api umusSelected;
//   @api inputs;
//   @api program;
//   @api extraData;

//   @track content;

//   dataToEmail = [];
//   orderId;
//   orders;
//   isDataLoading = false;

//   connectedCallback() {
//     console.log('carrito: ');
//     console.log(JSON.stringify(this.carrito));
//     console.log('umus: ');
//     console.log(this.umusSelected);
//     console.log(JSON.stringify(this.umusSelected));
//     console.log('inputs: ');
//     console.log(JSON.stringify(this.inputs));
//     console.log('programs: ');
//     console.log(JSON.stringify(this.program));
//     console.log('extraData: ');
//     console.log(JSON.stringify(this.extraData));
//     if(this.carrito.lenght > 1) {
//       this.content = 'varios pedidos'
//     } else {
//       this.content = 'un pedido'
//     }
//   }

//   async openSummaryModal(carrito, programa, esPrograma) {
//     try {
//       const result = await summaryModal.open({
//         size: 'small',
//         carrito: carrito,
//         programa: programa,
//         esPrograma: esPrograma
//       });
//       console.log(result);
//     } catch (error) {
//       console.error('Error opening modal:', error);
//     }
//   }

//   handleSave() {
//     if(this.extraData.orderType == 'Ordinario/NoOrdinario') {
//       console.log('handleOrderSave0');
//       this.handleOrderSave();
//     } else {
//       console.log('handleOrdersSave0');
//       this.handleOrdersSave();
//     }
//   }

//   // GENERACION PEDIDOS

//   async handleOrderSave() {
//     this.isDataLoading = true;

//     const order = await createOrders({payload: JSON.stringify([this.carrito])}).then(result => {
//       console.log('Order created successfully');
//       return result;
//     }).catch(error =>{
//       console.log('An error has occured: ' + error.getMessage());
//     });

//     console.log('here');
//     console.log(JSON.parse(JSON.stringify(order)));

//     const orderIds = order.map(ord => ord.Id);

//     console.log('here2');

//     if(Object.keys(this.extraData.fileData).length !== 0){
//       console.log('hi hi');
//       console.log(order[0]);
//       const recordId = order[0].Id;

//       console.log('file: ' + JSON.stringify([this.extraData.fileData]));
//       const fileData = this.extraData.fileData;
//       uploadFiles({filesToInsert: fileData, recordId: recordId}).then(result => {
//         console.log(result, 'done');
//       }).catch(error => {
//         console.log('An error has occured: ' + error.getMessage);
//       });
//     }

//     if(this.carrito.TipoDePedido == 'Ordinario'){
//       console.log('Inside pedido ordinario');
//       const isCreated = await this.handleGeneracionDePedido(order);
//       console.log(isCreated);
//       //if(!isCreated) return;
//     } else{
//         sendEmailSolicitudNoOrd({orderIds: orderIds}).then(result => {
//           console.log('Se ha generado exitosamente: ');
//           console.log(JSON.parse(JSON.stringify(result)));
//         }).catch(error =>{
//           console.log('An error has occured: ' + error.getMessage());
//         });
//     }

//     this.openSummaryModal(order, '', false);
//     console.log('sended');

//     // this.showToast('Orden creada', 'La orden ha sido creada exitosamente', 'success', 'pester');

//     // this[NavigationMixin.Navigate]({
//     //   type: 'comm__namedPage',
//     //   attributes:{
//     //     name: "Mis_Pedidos__c"
//     //   }
//     // });

//     this.close('done');
//   }

//   async handleGeneracionDePedido(orden) {
//     console.log('init handle generacion de pedido: ');
//     const orderIds = orden.map(ord => ord.Id);
//     try {
//       const result = await checkGeneracionDePedido({ orderIdList: orderIds });
//       console.log('result: ' + result);
//       const parsedResult = JSON.parse(result);
//       const { traxion_response = {} } = parsedResult;
//       const { completed_succesfully = false } = traxion_response;
//       return completed_succesfully;
//     } catch (error) {
//       console.log('An error has occurred: ' + error.message());
//       return false;
//     }
//   }

//   // PROGRAMAS

//   async handleOrdersSave() {
//     this.isDataLoading = true;

//     console.log('handleOrdersSave');
//     const orders = await createOrders({ payload: JSON.stringify(this.carrito)})
//     .then((result) => {
//       if(result) {
//         console.log('Pedido: ');
//         console.log(JSON.parse(JSON.stringify(result)));
//         return result;
//       }
//     }).catch(error =>{
//       console.log('An error has occured creating the orders: ' + error.getMessage());
//     });

//     if(orders) {
//       this.orders = orders;

//       const orderIds = [];
//       orders.forEach((order) => {
//         orderIds.push(order.Id);
//       });

//       console.log('OrderId');
//       this.orderId = orders[0].Id;
//       console.log(this.orderId);

//       this.generateDataToSendEmail();

//       console.log('Here');
//       const isCreated = await this.handleGeneracionDePedido(orders);
//       console.log('Status WMS: ' + isCreated);
//       if(!isCreated) {
//         console.log('Return');
//       }
//       console.log('Here2');

//       localStorage.removeItem('0');
//       localStorage.removeItem('1');
//       localStorage.removeItem('2');
//       console.log(localStorage.getItem('0'));
//       console.log(localStorage.getItem('1'));
//       console.log(localStorage.getItem('2'));

//       //this.showToast('Guia creada', 'La guia se ha creado exitosamente', 'success', 'pester');

//       this.openSummaryModal(orders, this.program.programName, true);
//       console.log('sended');

//       // this[NavigationMixin.Navigate]({
//       //   type: 'comm__namedPage',
//       //   attributes:{
//       //     name: "Mis_Pedidos__c"
//       //   }
//       // });

//       this.close('done');
//     }

//     // await createOrders({ payload: JSON.stringify(this.carrito)})
//     // .then((result) => {
//     //   if(result) {
//     //     console.log('Pedido: ');
//     //     console.log(JSON.stringify(result));
//     //     this.orders = result;

//     //     const orderIds = [];

//     //     result.forEach((order) => {
//     //       orderIds.push(order.Id);
//     //     });

//     //     generatePDF({orderIds: orderIds}).then(result => {
//     //       console.log('Se ha generado exitosamente: ');
//     //       console.log(JSON.parse(JSON.stringify(result)));
//     //     }).catch(error =>{
//     //       console.log('An error has occured: ' + error.getMessage());
//     //     });

//     //     console.log('OrderId');
//     //     this.orderId = result[0].Id;
//     //     console.log(this.orderId);

//     //     this.generateDataToSendEmail();

//     //     this.showToast('Guia creada', 'La guia se ha creado exitosamente', 'success', 'pester');

//     //     this[NavigationMixin.Navigate]({
//     //       type: 'comm__namedPage',
//     //       attributes:{
//     //         name: "Mis_Pedidos__c"
//     //       }
//     //     });

//     //     this.close('done');
//     //   }
//     // })
//     // .catch((error) => {
//     //   this.error = error;
//     //   console.log(JSON.stringify(error));
//     // });
//   }

//   generateDataToSendEmail() {
//     let dataList = [];
//     const hasMaxDate = false;
//     const orderType = this.extraData.orderType;

//     this.umusSelected.forEach(umu => {
//       console.log('umu processed: ' + JSON.stringify(umu));

//       let order = this.orders.find(order => order.UMU__c === umu.id);
//       console.log('order processed: ' + JSON.stringify(order));

//       // let date = new Date(order.Pedido__r.Fecha_Limite_de_Entrega__c);
//       // console.log('date: ' + date);

//       // if(orderType == 'Emergencia Sanitaria' || orderType == 'Programa') {
//       //   date = new Date(order.Fecha_Limite_de_Entrega__c);
//       // } else {
//       //   date = new Date(order.Pedido__r.Fecha_Limite_de_Entrega__c);
//       // }

//       let date;
//       console.log('pedido date: ' + order.Pedido__r.Fecha_Limite_de_Entrega__c);
//       if(orderType == 'Emergencia Sanitaria' || orderType == 'Programa') {
//         console.log('date1');
//         date = new Date(); // TODO: MODIFICAR ESTA FECHA CON LA QUE INGRESA EL USUARIO
//       } else {
//         console.log('date2');
//         date = new Date(order.Pedido__r.Fecha_Limite_de_Entrega__c);
//       }

//       console.log('date: ' + date);
//       let anio = date.getFullYear();
//       let mes = ('0' + (date.getMonth() + 1)).slice(-2);
//       let dia = ('0' + date.getDate()).slice(-2);
//       let formattedDate = `${anio}-${mes}-${dia}`;

//       //const formattedDate = date.toISOString().split('T')[0];

//       let filteredInputs = this.inputs.filter(input => input.umu === umu.id);
//       filteredInputs.forEach(input => {
//         let dataLine = {};
//         dataLine.delegacion = umu.delegation;
//         dataLine.umu = umu.number;
//         dataLine.clavePresupuestal = umu.budget;
//         dataLine.nombreUmu = umu.name;
//         dataLine.tipoPedido = this.extraData.orderType;
//         dataLine.fechaSolicitud = new Date().toISOString().slice(0, 10);
//         dataLine.folio = order.Pedido__r.Folio_de_Pedido__c;
//         dataLine.claveInsumo = input.code;
//         dataLine.descripcion = input.description;
//         dataLine.cantidadAutorizada = input.value;
//         dataLine.cantidadSap = input.value;
//         dataLine.estatus = 'AUTORIZADO';
//         dataLine.fechaLimite = formattedDate;
//         dataLine.programaId = this.program.programCode;
//         dataLine.programaNombre = this.program.programName;
//         dataList.push(dataLine);
//       });
//     });
//     this.dataToEmail = dataList;
//     this.generateCSVContent();
//   }

//   columnHeaderEmail = ['DELEGACION', 'UMU', 'CLAVE PRESUPUESTAL', 'NOMBRE UMU', 'TIPO DE PEDIDO',
//   'FECHA DE SOLICITUD', 'FOLIO DEL PEDIDO', 'CLAVE', 'DESCRIPCION CLAVE', 'CANTIDAD AUTORIZADA', 'CANTIDAD COLOCADA EN SAP',
//   'ESTATUS', 'FECHA LIMITE DE ENTREGA', 'ID DE PROGRAMA', 'PROGRAMA'];

//   generateCSVContent() {
//     let csvContent = this.columnHeaderEmail.join(',') + '\n';
//     this.dataToEmail.forEach(record => {
//       csvContent += record.delegacion + ',' + record.umu + ',' + "'" + record.clavePresupuestal + ',' +
//       record.nombreUmu + ',' + record.tipoPedido + ',' + record.fechaSolicitud + ',' + "'" + record.folio + ',' +
//       "'" + record.claveInsumo + ',' + record.descripcion + ',' + record.cantidadAutorizada + ',' + record.cantidadSap + ','
//       + record.estatus + ',' + record.fechaLimite + ',' + record.programaId + ',' + record.programaNombre + '\n';
//     });
//     this.sendCSVEmail(csvContent);
//   }

//   sendCSVEmail(content) {
//     let csvContent = content;
//     let csvData = csvContent;

//     let contentVersion = {
//       Title: 'Documento General.csv',
//       VersionData: btoa(csvData),
//       PathOnClient: 'DocumentoGeneral.csv',
//     };

//     const uniqueClavePresupuestal = new Set(this.dataToEmail.map(item => item.clavePresupuestal));
//     const sumCantidadAutorizada = this.dataToEmail.reduce((total, item) => total + parseFloat(item.cantidadAutorizada), 0); // Sumatoria de cantidadAutorizada
//     const numItems = new Set(this.dataToEmail.map(item => item.claveInsumo));
//     const dataSummary = {
//       numItems: numItems.size,
//       numCantidadUmus: uniqueClavePresupuestal.size,
//       sumCantidadAutorizada: sumCantidadAutorizada
//     };

//     const programName = this.program.programName;
//     const summaryJson = JSON.stringify(dataSummary);

//     console.log('ContentVersion');
//     console.log(JSON.stringify(contentVersion));
//     console.log(summaryJson);
//     console.log(programName);

//     createContentVersion({ title: contentVersion.Title, versionData: contentVersion.VersionData, pathOnClient: contentVersion.PathOnClient,
//       contactId: this.extraData.contactId, orderId: this.orderId, programName: programName, summaryJson: summaryJson})
//     .then(result => {
//       console.log('Operacion exitosa creando el ContentVersion: ');
//       console.log(result);
//     })
//     .catch(error => {
//       console.log('An error has occurred while creating the ContentVersion: ');
//       console.log(error);
//     });
//   }

//   showToast(title, message, variant, mode) {
//     const event = new ShowToastEvent({
//       title: title,
//       message: message,
//       variant: variant,
//       mode: mode
//     });
//     this.dispatchEvent(event);
//   }

//   handleClose() {
//     this.close('done');
//   }
// }