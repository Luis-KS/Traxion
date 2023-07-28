import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

// import COMMUNITY_FIELD from '@salesforce/schema/Contact.Account.Customer_Community__c';
import USER_FIELD from '@salesforce/schema/Contact.Owner.Name';
// import PERMISSION_SET_FIELD from '@salesforce/schema/Contact.Owner.PermissionSetAssignments';

export default class ContactUserInformation extends LightningElement {
    @api recordId;
    
    @wire(getRecord, { recordId: '$recordId', fields: [COMMUNITY_FIELD, USER_FIELD, PERMISSION_SET_FIELD] })
    contact;

    // get customerCommunity() {
    //     return getFieldValue(this.contact.data, COMMUNITY_FIELD);
    // }

    get user() {
        return getFieldValue(this.contact.data, USER_FIELD);
    }

    // get permissionSets() {
    //     return getFieldValue(this.contact.data, PERMISSION_SET_FIELD)?.result?.records;
    // }
}