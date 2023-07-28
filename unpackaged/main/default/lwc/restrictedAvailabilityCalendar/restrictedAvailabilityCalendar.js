import { LightningElement, track, api } from 'lwc';

export default class RestrictedAvailabilityCalendar extends LightningElement {


    isCalendarVisible = false;

    handleButtonClick() {
        this.isCalendarVisible = !this.isCalendarVisible;
    }

    // renderedCallback() {
    //     if (this.calendarEl) {
    //         return;
    //     }
    //     this.calendarEl = this.template.querySelectorAll('#my-calendar');
    //     this.calendarEl.addEventListener('click', this.handleDocumentClick);
    // }

    connectedCallback() {  
        // Add event listener to window object to detect clicks outside the lightning input element 
        window.addEventListener('click', this.handleDocumentClick);
    }  

    disconnectedCallback() {
        // Remove event listener when the component is removed from the DOM 
        window.removeEventListener('click', this.handleDocumentClick);
    }  

    handleDocumentClick(event) {
        console.log("Inside handle document click");
        console.log(JSON.parse(JSON.stringify(event.target)));
    }
}