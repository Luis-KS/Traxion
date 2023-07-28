import { LightningElement, track } from 'lwc';

export default class CsvToDatatable extends LightningElement {

    @track data;
    @track columns;

    handleFileUpload(event) {
        const files = event.detail.files;
        if (files.length > 0) {
            const file = files[0];
            
            // start reading the uploaded csv file
            this.read(file);
        }
    }
  
    async read(file) {
        try {
        const result = await this.load(file);
        
        // execute the logic for parsing the uploaded csv file
        this.parse(result);
        } catch (e) {
            console.log(e);
            this.error = e;
        }
    }

    async load(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();

            reader.onload = () => {
                resolve(reader.result);
            };
            reader.onerror = () => {
                reject(reader.error);
            };
            reader.readAsText(file);
        });
    }

    parse(csv) {

        console.log("INSIDE PARSE");

        // parse the csv file and treat each line as one item of an array
        const lines = csv.split(/\r\n|\n/);
        
        // parse the first line containing the csv column headers
        const headers = lines[0].split(',');


        headers.pop();

        console.log("Flag0");
        console.log(JSON.parse(JSON.stringify(headers)));

        // iterate through csv headers and transform them to column format supported by the datatable
        this.columns = headers.map((header) => {
            return { label: header, fieldName: header};
        });

        console.log("Continuacion")
        console.log(this.columns);
      
        const data = [];

        console.log("Flag1");
        console.log(JSON.parse(JSON.stringify(lines)));

        // iterate through csv file rows and transform them to format supported by the datatable
        lines.forEach((line, i) => {
            if (i === 0) return;
        
            const obj = {};
            let currentline = line.split(',');

            const parsedLine = currentline.map(li => li.replace(/"/g, ""));
        
            for (let j = 0; j < headers.length; j++) {
                obj[headers[j]] = parsedLine[j];
            }
        
            data.push(obj);
        });

        console.log('Printing data');
        console.log(JSON.parse(JSON.stringify(data)));
        
        // assign the converted csv data for the lightning datatable
        this.data = data;
    }
}