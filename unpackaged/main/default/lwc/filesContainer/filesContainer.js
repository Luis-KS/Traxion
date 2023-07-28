import { LightningElement, track, wire, api } from 'lwc';

import getAllDocumentsAndRelatedFiles from '@salesforce/apex/FilesController.getAllDocumentsAndRelatedFiles';
import getPedidoDocumentsAndRelatedFiles from '@salesforce/apex/FilesController.getPedidoDocumentsAndRelatedFiles';

import getContentDistributionForFile from '@salesforce/apex/FilesController.getContentDistributionForFile';
import deleteRelatedAttachment from '@salesforce/apex/FilesController.deleteRelatedAttachment';

export default class FilesContainer extends LightningElement {

    @api orderId = ''; 
    @track documents;

    connectedCallback() { 

        console.log("INSIDE CONNECTED CALLBACK");
        console.log(this.orderId);

        // Call Apex controller method and pass recordId parameter
        getPedidoDocumentsAndRelatedFiles({ pedidoId: this.orderId })
            .then(result => { 

                console.log("Printing results");
                console.log(JSON.parse(JSON.stringify(result)));

                result.forEach(res => {
                    const {files = []} = res; 
                    files.forEach(file => {
                        const { fileExtension = null } = file;

                        let icon = 'doctype:unknown';
                        switch (fileExtension) {
                            case 'pdf':
                                icon = `doctype:${fileExtension}`;
                                break;
                            case 'csv':
                                icon = `doctype:${fileExtension}`;
                                break; 
                            case 'jpg': case 'jpeg': case 'png':
                                icon = `doctype:image`;
                                break;  
                        }
                        file.icon = icon; 
                    }); 
                }); 
                this.documents = result;

                console.log("INSIDE DOCS");
                console.log(JSON.parse(JSON.stringify(this.documents)));



            })
            .catch(error => {
                // Handle error
                console.error(error);
            });
    } 

    handleDownloadFile(e) {
        getContentDistributionForFile({
            contentDocumentId: e.target.dataset.id
        })
        .then(response => {
            console.log(JSON.stringify(response));
            window.open(response.ContentDownloadUrl);
        })
        .catch(error => {
            console.log(JSON.stringify(error));
        })
    }

    handleDeleteFile(e) {
        console.log("INSIDE HANDLE DELETE FILE");
        console.log(e.target.dataset.id);

        deleteRelatedAttachment({
            contentDocumentId: e.target.dataset.id
        })
        .then(response => {
            console.log(response);

            if(response === 'SUCCESS'){
                getAllDocumentsAndRelatedFiles({ orderId: this.orderId })
                .then(result => { 
                    this.documents = result;
                })
                .catch(error => {
                    // Handle error
                    console.error(error);
                });
            }
        })
        .catch(error => {
            console.log(JSON.stringify(error));
        })
    }
}