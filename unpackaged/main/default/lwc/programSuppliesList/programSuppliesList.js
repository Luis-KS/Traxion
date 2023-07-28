import { LightningElement, track, wire, api } from 'lwc';
// import modalDetail from 'c/programSupplieDetailModal';
import modalConfirmation from 'c/programConfirmationModal';
import { getRecord, getFieldValue } from "lightning/uiRecordApi"
import getSuppliesBySearch from '@salesforce/apex/SuppliesController.getSuppliesBySearch';
import getProgramsByContact from '@salesforce/apex/ProgramController.getProgramsByContact';
import getProgramById from '@salesforce/apex/ProgramController.getProgramById';
import getUmusById from '@salesforce/apex/UmuController.getUmusById';
import getAvailabilitySkus from '@salesforce/apex/UserContactClass.getDisponibilidadSkus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CONTACT_ID from "@salesforce/schema/User.ContactId";
import USER_ID from "@salesforce/user/Id";
import { NavigationMixin } from 'lightning/navigation';

export default class ProgramSuppliesList extends NavigationMixin(LightningElement) {
  @api selectedStep;
  @api umusSelected;
  @api orderType;
  @api maxDate;

  searchTerm = '';
  rendered = false;
  renderedStep3 = false;
  isStep3 = false;
  addSuppliesBtn;
  quantityInputs;
  emptyInput = true;
  isInputValidate = true;
  isProgramPicklistEmpty = true;

  @track data;
  @track listRecords;
  @track quantity = 0;
  @track dataOfUmusSelected;
  @track addSuppliesText = "Insumos seleccionados (" + this.quantity + ")";

  @track options = [];
  @track isProgramsDataLoaded = false;
  @track programId;
  @track isDataLoaded = false;
  @track isDataSkuLoaded = false;
  @track isUmusSelectedDataLoaded = false;
  @track carrito;

  resume = {};
  piecesAdded = false;
  disabled = true;
  programInfo = {};

  @track error = null;
  @track initialRecords = [];
  @track totalRecords = 0;
  isFirstTime = true;
  dataToDownload = [];
  currentPage = 1;
  actualRecords = 0;
  totalPages = 0;
  displayedItems = [];
  isFirstPage = true;
  isLastPage = false;
  pageSize = 10;

  columnHeader = ['PROGRAMA', 'DELEGACION', 'CLAVE PRESUPUESTAL', 'NOMBRE UMU',
  'CLAVE DE INSUMO', 'DESCRIPCION CLAVE', 'DISPONIBLE EN CENADI', 'CANTIDAD A ENVIAR'];

  @track importData;
  @track columns;

  @wire(getRecord, { recordId: USER_ID, fields: [CONTACT_ID] })
  user;

  get contactId() {
    return getFieldValue(this.user.data, CONTACT_ID);
  }

  // Datatable to CSV

  generateDataToDownload() {
    let dataList = [];
    this.dataOfUmusSelected.forEach((umu => {
      let input = this.template.querySelectorAll('lightning-input[data-umu="' + umu.id + '"]');
      input.forEach((input => {
        let dataLine = {};
        dataLine.Programa = this.orderType;
        dataLine.Delegacion = umu.delegation;
        dataLine.Clave_Presupuestal = umu.budget.toString();
        dataLine.Nombre_UMU = umu.name.replace(/,/g, '');
        dataLine.Clave_De_Insumo = input.dataset.code;
        dataLine.Producto = input.dataset.description.replace(/,/g, '');
        dataLine.Existencia_Umu = input.dataset.capacity;
        if(input.value) {
          dataLine.Cantidad_A_Enviar = input.value;
        } else {
          dataLine.Cantidad_A_Enviar = 0;
        }
        dataList.push(dataLine);
      }));
    }));
    this.dataToDownload = dataList;
    this.downloadCSVFile();
  }

  downloadCSVFile(){
    let doc;
    this.columnHeader.forEach(element => {
      if(doc) {
        doc += element + ',';
      } else {
        doc = element + ',';
      }
    });
    this.dataToDownload.forEach(record => {
      doc += '\n';
      doc += record.Programa + ',';
      doc += record.Delegacion + ',';
      doc += "'" + record.Clave_Presupuestal.toString() + ',';
      doc += '"' + record.Nombre_UMU + '",';
      doc += "'" + record.Clave_De_Insumo.toString() + ',';
      doc += '"' + record.Producto + '",';
      doc += record.Existencia_Umu + ',';
      doc += record.Cantidad_A_Enviar + ',';
    });
    let downloadElement = document.createElement('a');
    downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURIComponent(doc);
    downloadElement.target = '_self';
    downloadElement.download = 'Documento Base.csv';
    document.body.appendChild(downloadElement);
    downloadElement.click();
  }

  // CSV to Datatable

  handleFileUpload(event) {
    const files = event.detail.files;
    if (files.length > 0) {
      const file = files[0];
      this.read(file); // start reading the uploaded csv file
    }
  }

  async read(file) {
    try {
      const result = await this.load(file);
      this.parse(result); // execute the logic for parsing the uploaded csv file
    } catch (e) {
      console.log(e);
      this.error = e;
    }
  }

  async load(file) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => {
        resolve(reader.result);
      };
      reader.onerror = () => {
        reject(reader.error);
      };
      reader.readAsText(file);
    });
  }

  parse(csv) {
    const self = this;

    const lines = csv.split(/\r\n|\n/); // parse the csv file and treat each line as one item of an array
    const headers = lines[0].split(','); // parse the first line containing the csv column headers

    if (headers[headers.length-1].trim() === '"') headers.pop();

    // iterate through csv headers and transform them to column format supported by the datatable
    this.columns = headers.map((header) => {
      return { label: header, fieldName: header};
    });

    const importData = [];

    // iterate through csv file rows and transform them to format supported by the datatable

    lines.forEach((line, i) => {
      if (i === 0) return;
      const obj = {};
      let currentline = line.split(',');
      const parsedLine = currentline.map(li => li.replace(/"/g, ""));
      for (let j = 0; j < headers.length; j++) {
        const formattedKey = headers[j].toLowerCase().replace(/\s+/g, '');
        obj[formattedKey] = parsedLine[j];
      }
      importData.push(obj);
    });

    // assign the converted csv data for the lightning datatable
    this.importData = importData;
    const selectedUmus = this.dataOfUmusSelected;

    const filteredData = importData.filter(rec => {
      const { clavepresupuestal, programa } = rec;
      if (programa === "") {
        return false;
      }
      if (clavepresupuestal) {
        for (const umu of selectedUmus) {
          if (umu.budget && clavepresupuestal.substring(1).trim() === umu.budget) {
            return true;
          }
        }
        return false;
      }
      return true;
    });

    // console.log('lines');
    // console.log(JSON.parse(JSON.stringify(lines)));
    // console.log('filtered data');
    // console.log(JSON.parse(JSON.stringify(filteredData)));
    // console.log('importData data');
    // console.log(JSON.parse(JSON.stringify(importData)));
    // console.log('selectedUmus');
    // console.log(JSON.parse(JSON.stringify(selectedUmus)));

    filteredData.forEach(function(data){
      const {clavepresupuestal = null} = data;
      if(clavepresupuestal){
        const quantityInput = self.template.querySelector('lightning-input[data-code="' + data.clavedeinsumo.substring(1).trim() + '"][data-clavepresupuestal="' + data.clavepresupuestal.substring(1).trim()  + '"]');
        quantityInput.value = data.cantidadaenviar;
      }
    });

    this.quantityInputs.forEach((input) => {
      this.handleChangeQuantity({ target: input });
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

  // Get Information

  getUmuInfoById() {
    getUmusById({ umuIds: this.umusSelected })
    .then((result) => {
      if(result) {
        let supplieList = [];
        result.forEach((row) => {
          let dataLine = {};
          dataLine.id = row.Id;
          dataLine.name = row.Name;
          dataLine.delegation = row.Delegaci_n__c;
          dataLine.budget = row.Clave_Presupuestal__c;
          dataLine.number = row.UMU__c;
          supplieList.push(dataLine);
        })
        this.dataOfUmusSelected = supplieList;
        this.isUmusSelectedDataLoaded = true;
      }
    })
    .catch((error) => {
      this.error = error;
      console.log(JSON.stringify(error));
    })
  }

  getPrograms() {
    getProgramsByContact()
    .then((result) => {
      if(result) {
        this.options = result.map((row) => ({ value: row.Id, label: row.Name }));
        this.isProgramsDataLoaded = true;
      }
    })
    .catch((error) => {
      this.error = error;
      console.log(JSON.stringify(error));
    })
  }

  getProgramById() {
    getProgramById({ programId: this.programId })
    .then((result) => {
      if(result) {
        this.programInfo = { programCode: result.Programa_ID__c, programName: result.Name };
      }
    })
    .catch((error) => {
      this.error = error;
      console.log(JSON.stringify(error));
    })
  }

  handleShowDescription(event){
    const code = event.target.dataset.code;
    const buttonName = event.target.dataset.name;
    const product = this.data.find(data => data.productCodeId === code);

    buttonName === "Show" ? product.showDescription = true : product.showDescription = false;
    this.data = [...this.data];
  }

  @track persistentData = null;
  @track persistentDataStep3 = null;
  @track parsedData = null;
  @track parsedDataStep3 = null;

  connectedCallback() {
    this.getPrograms();

    if(localStorage.getItem('0') != null) {
      this.isProgramPicklistEmpty = false;
      this.persistentData = localStorage.getItem('0');
      this.parsedData = JSON.parse(this.persistentData);
    }

    if(localStorage.getItem('2') != null) {
      this.persistentDataStep3 = localStorage.getItem('2');
      this.parsedDataStep3 = JSON.parse(this.persistentDataStep3);
    }

    if(this.selectedStep == "Step3") {
      const data = JSON.parse(localStorage.getItem('1'));
      this.isStep3 = true;
      this.programId = this.parsedData.programId;
      this.umusSelected = data.umuSelectedValues;
      this.orderType = data.orderType;
      this.maxDate = data.maxDeliveryDate ? data.maxDeliveryDate : null;
      this.getUmuInfoById();
      this.getProgramById();
    }

    this.getSupplies3();
  }

  renderedCallback() {
    if(this.rendered == false) {
      this.addSuppliesBtn = this.template.querySelector('lightning-button[data-name="addSuppliesBtn"]');
      if(localStorage.getItem('0') != null && !this.isStep3) this.calcQuantity();
      if(this.parsedDataStep3?.emptyInput == false  || this.parsedDataStep3?.emptyInput == true) {
        this.emptyInput = this.parsedDataStep3.emptyInput;
        // console.log('rendered:' + this.emptyInput);
      }
      console.log(JSON.stringify(this.parsedDataStep3));
      this.rendered = true;
    }
    if(this.isStep3) {
      this.quantityInputs = this.template.querySelectorAll('lightning-input[data-name="quantityInput"]');

      if(this.quantityInputs.length > 0 && this.parsedDataStep3?.inputsValues && !this.renderedStep3) {
        this.quantityInputs.forEach(input => {
          this.parsedDataStep3?.inputsValues.forEach(value => {
            if(input.dataset.umu == value.umu && input.dataset.code == value.clave) {
              input.value = value.value;
            }
          })
        })
        this.renderedStep3 = true;
      }
    }
  }

  handleSaveProgress() {
    if(this.programId != undefined && !this.isStep3) {
      const codes = [];
      this.data.forEach(row => {
        codes.push(row.productCodeId);
      })
      const dataToLoad = {
        programId: this.programId,
        supplieList: this.data,
        listRecords: this.listRecords
      };
      this.calcQuantity();
      localStorage.setItem('0', JSON.stringify(dataToLoad));

      this.persistentData = localStorage.getItem('0');
      console.log(this.persistentData);
      console.log(localStorage.getItem('1'));
    }

    if(this.programId != undefined && this.isStep3) {
      const inputs = [];
      this.quantityInputs.forEach(input => {
        if(input.validity.valid) {
          let dataLine = {};
          dataLine.clave = input.dataset.code;
          dataLine.umu = input.dataset.umu;
          dataLine.value = input.value;
          inputs.push(dataLine);
        }
      })

      const dataToLoad = {
        inputsValues: inputs,
        emptyInput: this.emptyInput
      }
      localStorage.setItem('2', JSON.stringify(dataToLoad));

      this.persistentDataStep3 = localStorage.getItem('2');
      console.log(this.persistentDataStep3);
    }
  }

  handleResetProgress() {
    localStorage.removeItem('0');
    localStorage.removeItem('1');
    localStorage.removeItem('2');

    location.reload();
  }

  isProgramChanged = false;

  async getSupplies3() {
    try {
      let supplieList = [];
      let productsCode = [];

      console.log('here');
      // console.log(JSON.stringify( this.parsedData));
      // console.log(JSON.stringify( this.programId));
      if(!this.persistentData || this.isStep3 || this.isProgramChanged) {
        console.log('here2');
        const result = await getSuppliesBySearch({ search: this.searchTerm, programId: this.programId });

        if(result) {
          if(this.isStep3) {
            console.log('here2.1');
            this.listRecords = this.parsedData.listRecords;
            //console.log('Lista: '); console.log(JSON.parse(JSON.stringify(this.listRecords)));
            this.listRecords.forEach(row => {
              console.log(JSON.stringify(row));
              let dataLine = {};
              dataLine.id = row.id;
              dataLine.productCodeId = row.productCodeId;
              dataLine.description = row.description;
              dataLine.availability = row.availability;
              dataLine.showDescription = false;
              dataLine.quantityPiecesPackage = row.quantityPiecesPackage;
              supplieList.push(dataLine);
              console.log(JSON.stringify(dataLine));
            })
          } else {
            console.log('here2.2');
            result.forEach(async (row) => {
              let dataLine = {};
              dataLine.id = row.Id;
              dataLine.productCodeId = row.Product_Code_ID__c;
              dataLine.name = row.Name;
              dataLine.packageCapacity = row.Package_Capacity__c;
              dataLine.description = row.Description__c;
              dataLine.quantityPiecesPackage = '';
              dataLine.availability = 0;
              dataLine.showButton = true;
              dataLine.showDescription = false;
              dataLine.disabled = false;
              productsCode.push(row.Product_Code_ID__c);
              supplieList.push(dataLine);
            });
          }
        } else {
          this.isDataLoaded = false;
        }
      } else {
        console.log('here3');
        this.programId = this.parsedData.programId;
        supplieList = this.parsedData.supplieList;
        productsCode = this.parsedData.productsCode;
        this.listRecords = this.parsedData.listRecords;
        this.isDataSkuLoaded = true;
        console.log('----LocalStorage----');
        console.log(supplieList);
        console.log(this.listRecords);
      }

      this.initialRecords = supplieList;
      this.data = supplieList;
      console.log('----DATA----');
      console.log(JSON.stringify(this.data));

      if(this.programId != undefined && !this.isStep3) {
        this.isDataLoaded = true;
        if(!this.persistentData || this.isProgramChanged) this.getAvailabilitySkus(productsCode);
      }

      this.totalPages = Math.ceil(this.data.length / this.pageSize);
      this.totalRecords = this.data.length;
      this.updateDisplayedItems(productsCode);
      console.log('me5');
      if(this.persistentData && !this.isStep3 && !this.isProgramChanged) this.handleDisableAddBtns();
    } catch (error) {
      this.error = error;
    }
  }

  async getAvailabilitySkus(productsCode){
    console.log('dentro funcion 1');
    console.log(JSON.stringify(productsCode));
    await getAvailabilitySkus({ jsonData: JSON.stringify(productsCode) }).then(result => {
      console.log('dentro funcion 2');
      const data = JSON.parse(result);
      const dataCopy = this.data.slice();

      data.forEach(record => {
        dataCopy.forEach(element =>{
          if(element.productCodeId == record.sku) {
            element.availability = record.availability;
            element.quantityPiecesPackage = record.packages_details.length > 0 ? record.packages_details
            .map(piece => piece.quantity_pieces_package)
            .filter(quantity => quantity !== 1)
            .join(", ") : 0;
          }
        })
      });
      this.data = dataCopy;
      console.log('data: ' + JSON.stringify(this.data));
      this.isDataSkuLoaded = true;
    }).catch(error =>{
      console.log('An error has occured: ' + error.message());
    })
    this.handleDisableAddBtns();
  }

  handleDisableAddBtns() {
    console.log('aqui1');
    this.data.forEach(row => {
      if(row.availability == 0) {
        console.log(row.availability);
        row.disabled = true;
      }
    });
  }

  handleCheckbox(event) {
    const checked = event.target.checked;

    this.data.forEach(row => {
      if(row.disabled == false) {
        row.showButton = checked ? false : true;
        const isProductInList = this.listRecords.some(value => value.productCodeId === row.productCodeId);

        if (checked && !isProductInList) {
          this.listRecords.push(row);
        } else if (!checked && isProductInList) {
          this.listRecords = this.listRecords.filter(value => value.productCodeId !== row.productCodeId);
        }
      }
    });

    this.calcQuantity();
    console.log('checkbox' + JSON.stringify(this.listRecords));
  }

  updateDisplayedItems() {
    const startIndex = (this.currentPage - 1) * this.pageSize;
    const endIndex = this.currentPage * this.pageSize;
    this.displayedItems = this.data.slice(startIndex, endIndex);
    this.isFirstPage = this.currentPage === 1;
    this.isLastPage = this.currentPage === this.totalPages;

    if(this.isFirstTime && this.programId) {
      this.actualRecords += this.displayedItems.length;
      this.isFirstTime = false;
    }
  }

  // Handle functionalities

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

  handleChangeQuantity(event) {
    const productCode = event.target.dataset.code;
    const umuId = event.target.dataset.umu;
    const quantityInput = this.template.querySelector('lightning-input[data-code="' + productCode + '"][data-umu="' + umuId + '"]');

    var sku = this.data.find(key => key.productCodeId == productCode);
    console.log('SKU: ' + JSON.stringify(sku));

    this.validateInput(quantityInput, sku);
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

  validateInput(element, sku){
    let errorMessage = '';
    let isMultiplo = false;

    if(sku.quantityPiecesPackage) isMultiplo = this.validateMultiplo(sku.quantityPiecesPackage, element.value);

    // if(element.value <= 0){
    //   errorMessage = 'La cantidad mínima a ingresar es 1';
    // } else 
    if(element.value > sku.availability) {
      errorMessage = `La cantidad ingresada sobrepasa la disponibilidad en CENADI`;
    } else if(!isMultiplo && sku.quantityPiecesPackage != undefined && sku.quantityPiecesPackage){
      errorMessage = `Ingrese múltiplos de ${sku.quantityPiecesPackage}`;
    } else if(!Number.isInteger(Number(element.value))) {
      errorMessage = 'Ingrese números enteros, no decimales';
    }

    for(let input of this.quantityInputs) {
      if(input.value == '') {
        this.emptyInput = true;
        break;
      } else {
        errorMessage === '' ? this.emptyInput = false : this.emptyInput = true;
      }
    }

    console.log('this.emptyInput: ' + this.emptyInput);
    element.setCustomValidity(errorMessage);
    this.isInputValidate = (errorMessage === '');
    element.reportValidity();
  }

  handleChange(event) {
    this.programId = event.detail.value;
    this.isProgramChanged = true;
    this.isDataSkuLoaded = false;
    this.isDataLoaded = false;
    this.isProgramPicklistEmpty = false;
    this.actualRecords = 0;
    this.isFirstTime = true;
    this.listRecords = [];
    this.calcQuantity();
    this.getSupplies3();
  }

  handleClickAddBtn(event) {
    let search = this.template.querySelector('lightning-input[data-name="search"]');
    search.value = '';
    this.handleKeyChange({target: search});
    this.handleSaveProgress();
    this.selectedStep = 'Step2';
    this.handleStep();
  }

  handleBack() {
    console.log('back');
    this.handleSaveProgress();
    this.selectedStep = 'Step2';
    this.handleStep();
  }

  handleStep() {
    const indicatorEvent = new CustomEvent('getindicatorposition', {
      detail: this.selectedStep
    });
    this.dispatchEvent(indicatorEvent);
  }

  handleKeyChange(event) {
    const searchKey = event.target.value.toLowerCase();
    const previousPage = this.currentPage;
    let searchRecords = [];

    if(searchKey) {
      this.data = this.initialRecords;
      if (this.data) {
        for (let record of this.data) {
          let valuesArray = Object.values(record);
          for (let val of valuesArray) {
            let strVal = String(val);
            if (strVal) {
              if (strVal.toLowerCase().includes(searchKey)) {
                searchRecords.push(record);
                break;
              }
            }
          }
        }
        this.currentPage = 1;
        this.data = searchRecords;
        this.updateDisplayedItems();

        console.log(searchRecords.length);
        if(searchRecords.length < 10 || previousPage === this.totalPages) this.isLastPage = true;
      }
    } else {
      this.data = this.initialRecords;
      this.updateDisplayedItems();
    }

    this.actualRecords = (this.currentPage - 1) * this.pageSize + this.displayedItems.length;
    this.currentPage = previousPage;
  }

  handleClick(event) {
    const productCode = event.target.dataset.code;
    const productName = event.target.dataset.name;
    const product = this.data.find(data => data.productCodeId === productCode);

    if(productName === "Add") {
      product.showButton = false;
      this.listRecords = this.listRecords ? [...this.listRecords, product] : [product];
    } else if(productName === "Remove") {
      product.showButton = true;
      this.listRecords = this.listRecords.filter(value => value.productCodeId !== product.productCodeId);
    }

    this.calcQuantity();
    this.data = [...this.data];
    console.log(JSON.stringify(this.listRecords));
  }

  calcQuantity() {
    if(this.listRecords.length) {
      this.quantity = this.listRecords.length;
      if(this.addSuppliesBtn.disabled == true) this.addSuppliesBtn.disabled = false;
    } else {
      this.quantity = 0;
      if(this.addSuppliesBtn.disabled == false) this.addSuppliesBtn.disabled = true;
    }
    this.addSuppliesText = "Insumos seleccionados (" + this.quantity + ")";
  }

  // -------------- GENERATE CAR ----------------

  generateCar() {
    this.carrito = [];
    let limitDate;
    this.umusSelected.forEach((row => {
      let dataLine = {};
      dataLine.Idcontacto = this.contactId;
      dataLine.IdUmu = row;
      dataLine.TipoDePedido = this.orderType;
      dataLine.esPrograma = true;
      if(this.maxDate) {
        limitDate = new Date(this.maxDate);
        limitDate.setDate(limitDate.getDate() + 1);
        dataLine.fechaMaxima = limitDate.toISOString().substring(0, 10);;
      }

      let input = this.template.querySelectorAll('lightning-input[data-umu="' + row + '"]');

      let products = [];
      input.forEach((input => {
        if(input.value > 0) {
          let dataProduct = {};
          dataProduct.insumoId = input.dataset.id;
          dataProduct.CantidadSolicitada = input.value;
          products.push(dataProduct);
        }
      }))
      dataLine.ordenesDetails = products;

      this.carrito ? this.carrito = [...this.carrito, dataLine] : this.carrito = [dataLine];
    }))

    console.log(JSON.stringify(this.carrito));

    let pieces = 0;
    this.quantityInputs.forEach(input => {
      pieces += parseInt(input.value.trim(), 10);
    })

    this.resume = {
      totalUmus: this.umusSelected.length,
      totalProducts: this.quantityInputs.length,
      totalPieces: pieces
    };

    this.piecesAdded = true;
    this.disabled = false;

    console.log('resume: ' + JSON.stringify(this.resume));
  }

  inputValues;
  extraData;

  handleCreateOrder() {
    try {
      this.inputValues = Array.from(this.quantityInputs).map((input) => ({
        code: input.dataset.code,
        umu: input.dataset.umu,
        description: input.dataset.description,
        value: input.value
      }));

      this.extraData = {
        orderType: this.orderType,
        contactId: this.contactId,
      };

      const modal = this.template.querySelector("c-program-confirmation-modal");
      modal.show();

      //this.openConfirmationModal(this.carrito, this.dataOfUmusSelected, inputValues, this.programInfo, extraData);
    } catch (error) {
      console.error('Error charging data:', error);
    }
  }

  // Modals

  // async openConfirmationModal(carrito, umusSelected, inputs, program, extraData) {
  //   try {
  //     const result = await modalConfirmation.open({
  //       size: 'small',
  //       carrito: carrito,
  //       umusSelected: umusSelected,
  //       inputs: inputs,
  //       program: program,
  //       extraData: extraData
  //     });
  //     console.log(result);
  //   } catch (error) {
  //     console.error('Error opening modal:', error);
  //   }
  // }
}