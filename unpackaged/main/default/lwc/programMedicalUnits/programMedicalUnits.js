import { LightningElement, track, wire } from 'lwc';
import getUmuPicklist from '@salesforce/apex/UmuController.getUmuMultiSelectOptions';
import getAllUmus from '@salesforce/apex/UmuController.getAllUmus';
import getUmuDelegationByType from '@salesforce/apex/UmuController.getUmuDelegationByType';
import getUmuByType from '@salesforce/apex/UmuController.getUmuByType';
import getUmuByDelegation from '@salesforce/apex/UmuController.getUmuByDelegation';
import getUmuByTypeAndDelegation from '@salesforce/apex/UmuController.getUmuByTypeAndDelegation';

export default class ProgramMedicalUnits extends LightningElement {
  @track optionsUmuType = [];
  @track optionsDelegation = [];
  @track optionsUmu = [];
  @track allOptionsUmu = [];
  @track allOptionsDelegation = [];

  @track isUmuTypeDataLoaded = false;
  @track isDelegationDataLoaded = false;
  @track isUmuDataLoaded = false;
  @track isDataLoading = true;
  @track maxDeliveryDate;
  @track today = new Date();
  @track minDate = this.getMinimumDate();
  
  umuTypeSelectedValues = [];
  delegationSelectedValues = [];
  umuSelectedValues = [];

  umuTypes = [];
  delegations = [];
  rendered = false;
  orderType = '';
  selectedStep;
  calendar;

  get optionsOrderType() {
    return [
      { label: "Soporte de Vida", value: "Soporte de Vida" },
      { label: "Urgencia Médica", value: "Urgencia Médica" },
      { label: "Emergencia Sanitaria", value: "Emergencia Sanitaria" },
      { label: "Programa", value: "Programa" },
    ];
  }

  handleClickSelect(event) {
    try {
      if(this.orderType == "Soporte de Vida" || this.orderType == "Urgencia Médica") this.maxDeliveryDate = '';
      this.selectedStep = 'Step3';

      this.handleSaveProgress();

      const indicatorEvent = new CustomEvent('getdatafrommedicalunits', {
        detail: {
          step: this.selectedStep,
          umus: this.umuSelectedValues,
          orderType: this.orderType,
          maxDate: this.maxDeliveryDate
        }
      });

      this.dispatchEvent(indicatorEvent);
    } catch (e) {
      console.log('Error en handleClickSelect', e);
    }
  }

  @track persistentData = null;
  @track parsedData = null;

  connectedCallback() {
    if(localStorage.getItem('1') != null) {
      this.persistentData = localStorage.getItem('1');
      this.parsedData = JSON.parse(this.persistentData);

      if(this.parsedData.orderType) {
        this.orderType = this.parsedData.orderType;
      }

      if(this.parsedData.maxDeliveryDate) {
        this.maxDeliveryDate = this.parsedData.maxDeliveryDate;
        this.isValidDate = true;
      }
    }

    this.getUmuType();
    this.getDelegation();
    this.getUmus();
    console.log('minDate: ' + this.minDate);
  }

  selectedItems = [];
  isFirstTimeDelegation = true;
  isFirstTimeUmu  = true;

  rerenderedUmuType = true;
  rerenderedDelegation = true;
  rerenderedUmu = true;

  renderedCallback() {
    if(this.rendered == false) {
      this.addUmusBtn = this.template.querySelector('lightning-button[data-name="addUmusBtn"]');
      this.calendar = this.template.querySelector('lightning-input[data-name="calendar"]')
      this.rendered = true;

      console.log('parsed data');
      console.log(this.parsedData?.orderType);

      if(this.parsedData) {
        if(this.parsedData.orderType) {
          this.handleCalendarDisabled(this.orderType);
        }

        if(this.parsedData.umuTypeSelectedValues) {
          const selectedValues = this.parsedData.umuTypeSelectedValues;
          this.defaultSelectedUmuItems = this.optionsUmuType.filter(
            item => selectedValues.includes(item.key)
          );
          // this.hasPreselectedValUmuType = true;
          // this.hasPreselectedValDelegation = true;
          // console.log('SELECTED: ' + JSON.stringify(this.defaultSelectedUmuItems));
          this.isDelegationDataLoaded = true;
          this.getDelegation();
          console.log('<-----> UMU:  ' + this.rerenderedUmuType)
          this.isUmuTypeDataLoaded = true;
        } else {
          this.isUmuTypeDataLoaded = true;
        }

        if(this.parsedData.delegationSelectedValues) {
          const selectedValues = this.parsedData.delegationSelectedValues;
          this.defaultSelectedDelegations = this.optionsDelegation.filter(
            item => selectedValues.includes(item.key)
          );
          console.log('<-----> DELEGATION:  ' + this.rerenderedDelegation)
          // console.log('SELECTED: ' + JSON.stringify(this.defaultSelectedDelegations));
          this.isDelegationDataLoaded = true;
        } else {
          this.isDelegationDataLoaded = true;
        }

        if(this.parsedData.umuSelectedValues) {
          const selectedValues = this.parsedData.umuSelectedValues;
          this.defaultSelectedUmus = this.optionsUmu.filter(
            item => selectedValues.includes(item.key)
          );
          console.log('<-----> UMUS:  ' + this.rerenderedUmu);
          // console.log('SELECTED: ' + JSON.stringify(this.defaultSelectedUmus));
          this.isUmuDataLoaded = true;
        } else {
          this.isUmuDataLoaded = true;
        }
      }

      setTimeout(() => {
        this.setBoolsToFalse();
      }, 1000);
    }
  }

  setBoolsToFalse()  {
    this.rerenderedUmuType = false;
    this.rerenderedDelegation = false;
    this.rerenderedUmu = false;
  }

  handleBack() {
    this.handleStep('Step1')
  }

  handleStep(step) {
    const indicatorEvent = new CustomEvent('getindicatorpositionumu', {
      detail: step
    });
    this.dispatchEvent(indicatorEvent);
  }

  handleSaveProgress() {
    if(this.isUmuTypeDataLoaded && this.isDelegationDataLoaded && this.isUmuDataLoaded) {
      const dataUmuToLoad = {
        selectedStep: 'Step2',
        optionsUmuType: this.optionsUmuType,
        optionsDelegation: this.optionsDelegation,
        optionsUmu: this.optionsUmu,
      };

      if(this.orderType) dataUmuToLoad.orderType = this.orderType;
      if(this.maxDeliveryDate) dataUmuToLoad.maxDeliveryDate = this.maxDeliveryDate;
      if(this.umuTypeSelectedValues.length > 0) dataUmuToLoad.umuTypeSelectedValues = this.umuTypeSelectedValues;
      if(this.delegationSelectedValues.length > 0) dataUmuToLoad.delegationSelectedValues = this.delegationSelectedValues;
      if(this.umuSelectedValues.length > 0) dataUmuToLoad.umuSelectedValues = this.umuSelectedValues;
      localStorage.setItem('1', JSON.stringify(dataUmuToLoad));
    }

    this.persistentData = localStorage.getItem('1');
    console.log(localStorage.getItem('0'));
    console.log(this.persistentData);

    const test = JSON.parse(this.persistentData);
    console.log('---Order: ' + test.orderType);
    console.log('---Date: ' + test.maxDeliveryDate);
    console.log('---UmuTypeSelected: ' + test.umuTypeSelectedValues);
    console.log('---delegationSelected: ' + test.delegationSelectedValues);
    console.log('---umusSelected: ' + test.umuSelectedValues);
  }

  handleResetProgress() {
    localStorage.removeItem('0');
    localStorage.removeItem('1');
    localStorage.removeItem('2');
    console.log(localStorage.getItem('0'));
    console.log(localStorage.getItem('1'));
    console.log(localStorage.getItem('2'));

    location.reload();
  }

  getUmuType() {
    console.log('lenght: ' + this.optionsUmuType.length);
    if(this.persistentData && this.parsedData.optionsUmuType.length > 0) {
      console.log('here');
      this.optionsUmuType = this.parsedData.optionsUmuType;
      //this.isUmuTypeDataLoaded = true;
    } else {
      console.log('here2');
      getUmuPicklist({ objectName: "Account", fieldName: "Tipo_UMU__c" })
      .then((result) => {
        if(result) {
          let optionList = [];
          result.forEach((row) => {
            let dataLine = {};
            dataLine.key = row.value;
            dataLine.value = row.label;
            optionList.push(dataLine);
          })
          this.optionsUmuType = optionList;
          this.isUmuTypeDataLoaded = true;
          // this.hasPreselectedValUmuType = true;
        }
      })
      .catch((error) => {
        this.error = error;
        console.log(JSON.stringify(error));
      })
    }
  }

  getUmus() {
    if(this.delegations.length == 0 && this.umuTypes.length == 0) {

      if(this.persistentData && this.parsedData.optionsUmu.length > 0 && this.isFirstTimeUmu) {
        console.log('here5');
        this.optionsUmu = this.parsedData.optionsUmu;
        this.allOptionsUmu = this.parsedData.optionsUmu;
        this.isFirstTimeUmu = false;
        //this.isUmuDataLoaded = true;
        this.isDataLoading = false;
      } else {
        console.log('here6');
        getAllUmus()
        .then((result) => {
          console.log('inside getAllUmus');
          if(result) {
            let optionList = [];
            result.forEach((row) => {
              let dataLine = {};
              dataLine.key = row.Id;
              dataLine.value = row.Name;
              optionList.push(dataLine);
            })
            this.allOptionsUmu = optionList;
            this.optionsUmu = optionList;
            this.isUmuDataLoaded = true;
            this.isDataLoading = false;
          }
        })
        .catch((error) => {
          this.error = error;
          console.log(JSON.stringify(error));
        })
      }
    } else if(this.delegations.length == 0) {
      getUmuByType({ umuTypes: this.umuTypes })
      .then((result) => {
        console.log('inside getUmuByType');
        console.log(result);
        if(result) {
          let optionList = [];
          result.forEach((row) => {
            let dataLine = {};
            dataLine.key = row.Id;
            dataLine.value = row.Name;
            optionList.push(dataLine);
          })
          this.optionsUmu = optionList;
        }
      })
      .catch((error) => {
        this.error = error;
        console.log(JSON.stringify(error));
      })
    } else if(this.umuTypes.length == 0) {
      getUmuByDelegation({ umuDelegations: this.delegations })
      .then((result) => {
        console.log('inside getUmuByDelegation');
        console.log(result);
        if(result) {
          let optionList = [];
          result.forEach((row) => {
            let dataLine = {};
            dataLine.key = row.Id;
            dataLine.value = row.Name;
            optionList.push(dataLine);
          })
          this.optionsUmu = optionList;
        }
      })
      .catch((error) => {
        this.error = error;
        console.log(JSON.stringify(error));
      })
    } else {
      getUmuByTypeAndDelegation({ umuTypes: this.umuTypes, umuDelegations: this.delegations })
      .then((result) => {
        console.log('inside getUmuByTypeAndDelegation');
        console.log(result);
        if(result) {
          let optionList = [];
          result.forEach((row) => {
            let dataLine = {};
            dataLine.key = row.Id;
            dataLine.value = row.Name;
            optionList.push(dataLine);
          })
          this.optionsUmu = optionList;
        }
      })
      .catch((error) => {
        this.error = error;
        console.log(JSON.stringify(error));
      })
    }
  }

  getDelegation() {
    if(!this.isDelegationDataLoaded) {
      if(this.persistentData && this.parsedData.optionsDelegation.length > 0 && this.isFirstTimeDelegation) {
        console.log('here3');
        this.optionsDelegation = this.parsedData.optionsDelegation;
        this.allOptionsDelegation = this.parsedData.optionsDelegation;
        this.isFirstTimeDelegation  = false;
        //this.isDelegationDataLoaded = true;
      } else {
        console.log('this.isDelegationDataLoaded: ' + this.isDelegationDataLoaded);
        console.log('here4');
        getUmuPicklist({ objectName: "Account", fieldName: "Delegaci_n__c" })
        .then((result) => {
          if(result) {
            let optionList = [];
            result.forEach((row) => {
              let dataLine = {};
              dataLine.key = row.value;
              dataLine.value = row.label;
              optionList.push(dataLine);
            })

            this.allOptionsDelegation = optionList;
            this.optionsDelegation = optionList;
            this.isDelegationDataLoaded = true;
            // this.hasPreselectedValDelegation = true;
          }
        })
        .catch((error) => {
          this.error = error;
          console.log(JSON.stringify(error));
        })
      }
    } else {
      console.log('here7');
      console.log(this.isDelegationDataLoaded);
      // console.log(this.hasPreselectedValDelegation);

      getUmuDelegationByType({ umuTypes: this.umuTypes})
      .then((result) => {
        if(result) {
          let optionList = [];
          result.forEach((row) => {
            let dataLine = {};
            dataLine.key = row.Delegaci_n__c;
            dataLine.value = row.Delegaci_n__c;

            if(optionList.findIndex(object => object.key === dataLine.key) == -1 && dataLine.key != null) {
              optionList.push(dataLine);
            }
          })
          this.optionsDelegation = optionList;
          //this.isDelegationDataLoaded = true;
        }
      })
      .catch((error) => {
        this.error = error;
        console.log(JSON.stringify(error));
      })
    }
  }

  handleOnItemSelectedUmuType(event) {
    if(event.detail) {
      this.umuTypeSelectedValues = [];
      let self = this;

      event.detail.forEach(function (eachItem) {
        self.umuTypeSelectedValues = [...self.umuTypeSelectedValues, eachItem.value];
      });

      if(this.umuTypeSelectedValues.length > 0) {
        this.umuTypes = this.umuTypeSelectedValues;
      } else {
        this.umuTypes = [];
        this.delegations = [];
        this.delegationSelectedValues = [];
        this.isDelegationDataLoaded = false;
      }

      this.getDelegation();
      this.getUmus();
    }
  }

  handleOnItemSelectedDelegation(event) {
    if(event.detail) {
      this.delegationSelectedValues = [];
      let self = this;

      event.detail.forEach(function (eachItem) {
        self.delegationSelectedValues = [...self.delegationSelectedValues, eachItem.value];
      });

      if(this.delegationSelectedValues.length > 0) {
        this.delegations = this.delegationSelectedValues;
      }
      else {
        this.delegations = [];
      }

      this.getUmus();
      console.log(JSON.stringify(this.umuTypeSelectedValues));
      console.log(JSON.stringify(this.delegationSelectedValues));

      this.handleBtnDisabled();
    }
  }

  handleOnItemSelectedUmu(event) {
    if(event.detail) {
      this.umuSelectedValues = [];
      let self = this;

      event.detail.forEach(function (eachItem) {
        self.umuSelectedValues = [...self.umuSelectedValues, eachItem.key];
      });

      console.log(JSON.stringify(this.umuTypeSelectedValues));
      console.log(JSON.stringify(this.delegationSelectedValues));
      console.log(JSON.stringify(this.umuSelectedValues));

      this.handleBtnDisabled();
    }
  }

  handleChange(event) {
    this.orderType = event.detail.value;
    console.log(this.orderType);
    this.handleCalendarDisabled(this.orderType);
  }

  handleCalendarDisabled(orderType) {
    //orderType == "Programa" || orderType == "Emergencia Sanitaria" ? this.calendar.disabled = false : this.calendar.disabled = true;
    this.calendar.disabled = orderType == "Programa" || orderType == "Emergencia Sanitaria" ? false : true;
    this.handleBtnDisabled();
  }

  isBusinessDay(date) {
    const dayOfWeek = new Date(date).getDay();
    return dayOfWeek !== 5 && dayOfWeek !== 6;
  }

  getMinimumDate() {
    const minimumDate = new Date(this.today.getTime() + 2 * 24 * 60 * 60 * 1000);
    console.log('MinimumDay0: ' + minimumDate.getDay());
    if (minimumDate.getDay() === 6) { // Sabado
      minimumDate.setDate(minimumDate.getDate() + 2); // Agregar 2 días
    } else if (minimumDate.getDay() === 0) { // Domingo
      minimumDate.setDate(minimumDate.getDate() + 1); // Agregar 1 día
    }
    console.log('MinimumDay: ' + minimumDate.getDay());
    return minimumDate.toISOString().split('T')[0];
  }

  isValidDate;

  handleCalendar(event) {
    const selectedDate = event.target.value;

    if (selectedDate < this.minDate) {
      const message = `La fecha mínima de entrega es ${this.minDate}`;
      event.target.setCustomValidity(message);
      this.isValidDate = false;
    } else if (!this.isBusinessDay(selectedDate)) {
      event.target.setCustomValidity('La fecha de entrega debe especificarse de lunes a viernes');
      this.isValidDate = false;
    } else {
      event.target.setCustomValidity('');
      this.isValidDate = true;
      this.maxDeliveryDate = selectedDate;
    }

    console.log('Date: ' + this.maxDeliveryDate);
    this.handleBtnDisabled();
  }

  handleBtnDisabled() {
    if(this.orderType == "Programa" || this.orderType == "Emergencia Sanitaria") {
      if(this.umuSelectedValues.length > 0 && this.orderType != ''
      && this.maxDeliveryDate != null && this.maxDeliveryDate != '' && this.isValidDate) {
        if(this.addUmusBtn.disabled == true) this.addUmusBtn.disabled = false;
      } else {
        if(this.addUmusBtn.disabled == false) this.addUmusBtn.disabled = true;
      }

      console.log('orderType: ' + this.orderType);
      console.log('maxDeliveryDate: ' + this.maxDeliveryDate);
      console.log('umuSelectedValues: ' + this.umuSelectedValues.length);
    } else {
      if(this.umuSelectedValues.length > 0 && this.orderType != '') {
        if(this.addUmusBtn.disabled == true) this.addUmusBtn.disabled = false;
      } else {
        if(this.addUmusBtn.disabled == false) this.addUmusBtn.disabled = true;
      }
    }
  }

  // const child = this.template.querySelector('c-pick-list-multiselect[data-name="delegation"]');
  // console.log(child);
  // child.onRefreshClick();
}