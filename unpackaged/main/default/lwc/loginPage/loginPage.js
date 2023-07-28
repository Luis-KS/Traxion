import { LightningElement } from 'lwc';
import Login from '@salesforce/apex/CustomLoginFormController.login';
import { NavigationMixin } from 'lightning/navigation';

export default class LoginPage extends NavigationMixin(LightningElement) {

    usuario;
    password;
    resultado;
    currentUrl;
    errorMessage;
    isErrorMessage = false;
    domainUrl;
    isContainer = false;

    handleUsuarioInput(event){
        this.usuario = event.target.value;
    }

    handleContrasenaInput(event){
        this.password = event.target.value;
    }

    handleSignInBtnClick(){
        Login({username: this.usuario , password: this.password}).then(result => {
            window.location.href = result;
            this.isErrorMessage = false;
        }).catch(error => {
            console.log("Error: " + error.body.message);
            this.isErrorMessage = true;
            this.errorMessage = 'Tu intento de logueo ha sido fallido. Asegura que tu usuario y contraseña estén correctos.';
        })
    }

    handleForgetPasswordLinkClick(){
        this.isContainer = true;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes:{
                name: "Forgot_Password"
            }
        });
    }
}