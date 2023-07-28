import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class CheckPassword extends NavigationMixin(LightningElement) {
    isContainer = false;

    handleLoginLink(){
        this.isContainer = true;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes:{
                name: "Login"
            }
        });
    }
}