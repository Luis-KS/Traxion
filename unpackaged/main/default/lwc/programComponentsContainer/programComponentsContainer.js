import { LightningElement, track } from 'lwc';

export default class ProgramComponentsContainer extends LightningElement {
  @track selectedStep;
  @track umusSelected;
  @track orderType;
  @track maxDate;
  isStep1 = true;
  isStep2 = false;
  isStep3 = false;

  connectedCallback() {
    this.selectedStep = this.handleActiveStep();
    console.log(this.selectedStep);
  }

  handleActiveStep() {
    if(localStorage.getItem('2')) {
      console.log('STEP3 LOCAL STORAGE');
      return 'Step3';
    } else if(localStorage.getItem('1')) {
      console.log('STEP2 LOCAL STORAGE');
      this.handleMenuBools(false, true, false);
      return 'Step2';
    } else {
      console.log('STEP1 LOCAL STORAGE');
      return 'Step1';
    }
  }

  handleMenuBools(step1, step2, step3){
    this.isStep1 = step1;
    this.isStep2 = step2;
    this.isStep3 = step3;
  }

  handleIndicatorPosition(event) {
    this.selectedStep = event.detail;
    console.log('STEEEEEP: ' + this.selectedStep);
    if(this.selectedStep == 'Step2') {
      this.handleMenuBools(false, true, false);
    } else if(this.selectedStep == 'Step3') {
      this.handleMenuBools(false, false, true);
    } else {
      
      this.handleMenuBools(true, false, false);
    }
  }

  handleDataMedicalUnits(event) {
    this.selectedStep = event.detail.step;
    this.umusSelected = event.detail.umus;
    this.orderType = event.detail.orderType;
    this.maxDate = event.detail.maxDate;
    console.log('Container Step: ' + this.selectedStep);
    console.log('Container Umus: ' + this.umusSelected);
    console.log('Container orderType: ' + this.orderType);
    console.log('Container Date: ' + this.maxDate);
    this.handleMenuBools(false, false, true);
  }
}