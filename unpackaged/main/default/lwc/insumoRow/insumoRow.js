import { LightningElement, wire } from 'lwc';
import getDataFromContact from '@salesforce/apex/DPNController.getDataFromContact';


const columns=[
    {
        label: 'View',
        type: 'button-icon',
        initialWidth: 75,
        typeAttributes: {
            iconName: 'action:preview',
            title: 'Preview',
            variant: 'border-filled',
            alternativeText: 'View'
        }
      },
      {
        label: 'First Name',
        fieldName: 'FirstName',
        hideDefaultActions: true,
    },
    {
        label: 'Last Name',
        fieldName: 'LastName',
        hideDefaultActions: true,
    },
    {
        label: 'Amount',
        fieldName: 'Amount',
        editable: true,
        hideDefaultActions: true
    },
    {
        label: 'Phone',
        fieldName: 'Phone',
        hideDefaultActions: true
    }
];
export default class InsumoRow extends LightningElement {

    errors;
    columns = columns;
    @wire(getDataFromContact) wireContact;

    handleRowAction(event){
        const dataRow = event.detail.row;
        let Id = dataRow.Id;
        window.console.log('dataRow@@ ' + Id);
        this.contactRow=dataRow;
        window.console.log('contactRow## ' + JSON.stringify(dataRow));
        this.modalContainer=true;

        // get draft values
        const draft = this.template.querySelector('lightning-datatable').draftValues;
        console.log('Data: ' + JSON.stringify(draft));

        this.errors = {
            rows: {
                b: {
                    title: 'We found 1 errors.',
                    messages: [
                        'Verify the email address and try again.'
                    ],
                    fieldNames: ['Amount'],
                }
            },
            table: {
                title: 'Your entry cannot be saved. Fix the errors and try again.',
                messages: [
                    'DPN Excedida'
                ],
                cellAttributes: {
                    class: {
                        fieldName: 'error-color'
                    },
                    alignment: `left`
                }
            }
        };
    }
}