import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import ForgotPassword from '@salesforce/apex/CustomForgotFormController.forgotPassowrd';

export default class ForgetPassword extends NavigationMixin(LightningElement) {

    usuario;
    errorMessage;
    isErrorMessage = false;
    isContainer = false;

    handleUsuarioInput(event){
        this.usuario = event.target.value;
    }

    handleResetPasswordBtn(){
        ForgotPassword({username: this.usuario}).then(result => {
            window.location.href = result;
            this.isErrorMessage = false;
        }).catch(error => {
            console.log("Error: " + error.body.message);
            this.isErrorMessage = true;
            this.errorMessage = 'El nombre de usuario proveido no existe.';
        })
    }

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