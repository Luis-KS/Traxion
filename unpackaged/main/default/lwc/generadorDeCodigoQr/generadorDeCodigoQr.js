import { LightningElement, track, api } from 'lwc';
import qrCodeGenerator from './qrcode.js';

export default class GeneradorDeCodigoQr extends LightningElement {
    @track inputData = '';
    @api numberThatIsGoingToBeUsedToGenerateTheQR = 'klk';

    // This is to be used to automatically generate the QR when a condition to show the component is met and we have the data to generate the QR
    renderedCallback() {
        const qrCodeGenerated = new qrCodeGenerator(0, 'H');
        let strForGenearationOfQRCode  = this.numberThatIsGoingToBeUsedToGenerateTheQR;
        qrCodeGenerated.addData(strForGenearationOfQRCode);
        qrCodeGenerated.make();
        let element = this.template.querySelector(".qrcodeClass");
        element.innerHTML = qrCodeGenerated.createSvgTag({});
   }

   // For testing purposes
    handleInputChange(event) {
        this.inputData = event.target.value;
    }

    generateQRCode() {
        if (this.inputData) {
            const qrCodeGenerated = new qrCodeGenerator(0, 'H');
            qrCodeGenerated.addData(this.inputData);
            qrCodeGenerated.make();
            let element = this.template.querySelector('.qrcodeClass2');
            element.innerHTML = qrCodeGenerated.createSvgTag({});
        
        // } else {
        //     let element = this.template.querySelector('.qrcodeClass2');
        //     element.innerHTML = '';
        // }
    }}
}