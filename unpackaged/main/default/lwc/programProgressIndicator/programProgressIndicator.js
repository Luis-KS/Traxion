import { LightningElement, api } from 'lwc';

export default class ProgramProgressIndicator extends LightningElement {
  @api selectedStep;

  connectedCallback() {
    console.log('From progress bar:'  + this.selectedStep);
  }
}