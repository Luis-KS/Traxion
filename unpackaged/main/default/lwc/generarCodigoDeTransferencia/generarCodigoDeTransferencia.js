import { LightningElement, track } from 'lwc';

export default class GenerarCodigoDeTransferencia extends LightningElement {
    @track inputValue = 'a0J3K00000CELZpUAP';
    @track encodedValue = '';

    handleInputChange(event) {
        this.inputValue = event.target.value;
    }

    handleEncode() {
        // Remove the first 3 characters of the input value
        const trimmedValue = this.inputValue.substring(3);

        // Convert the trimmed value to an array of numbers
        const numberArray = Array.from(trimmedValue, char => char.charCodeAt(0));

        // Encode the number array using base64
        const base64Encoded = btoa(String.fromCharCode(...numberArray));

        // Format the encoded value with dashes
        const formattedValue = this.formatEncodedValue(base64Encoded);

        // Update the encodedValue property with the formatted value
        this.encodedValue = formattedValue;
    }

    formatEncodedValue(encodedValue) {
        // Split the encoded value into groups of 4 characters
        const groups = encodedValue.match(/.{1,4}/g);

        // Join the groups with dashes and return the formatted value
        return groups.join('-');
    }
}