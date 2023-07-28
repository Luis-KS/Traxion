import { LightningElement, api, wire } from 'lwc';
import getFiles from '@salesforce/apex/ReplaneacionController.getFiles';
import { NavigationMixin } from 'lightning/navigation';

export default class ReplaneacionEvidenciaImagen extends LightningElement {
    @api orderId;
    @api evidencia;

    dataResult;
    url;
    Title;

    @wire(getFiles, { orderId: '$orderId' }) filesFromContentDocument({ data, error }) {
        if (data) {
            this.dataResult = data;
            this.Title = this.dataResult.ContentDocument.Title;
           // this.url = "/sfsites/c/sfc/servlet.shepherd/document/download/" + this.dataResult.ContentDocumentId;
             this.url = 'https://traxionfarma--traxsdbx.sandbox.my.site.com/traxion/s/contentdocument/'+this.dataResult.ContentDocumentId;
        } else if (error) {
            console.log(error);
        }
    }
}