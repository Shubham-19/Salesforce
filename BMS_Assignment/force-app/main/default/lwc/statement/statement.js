import { LightningElement, track, wire, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import getTransactionsByDate from '@salesforce/apex/getRelatedTransactions.getTransactionsByDate'
import emailWithAttachment from '@salesforce/apex/getRelatedTransactions.emailWithAttachment'

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import JSPDF from '@salesforce/resourceUrl/jspdf';
import JSPDF_AUTO_TABLE from '@salesforce/resourceUrl/jspdfautotable';
import {loadScript} from 'lightning/platformResourceLoader';

const columnsForTransaction = [
    {
        label: 'Name',
        fieldName: 'Name',
        type: 'text',
        sortable: true
    },
    {
        label: 'Amount',
        fieldName: 'Amount__c',
        type: 'number',
        sortable: true
    },
    {
        label: 'Type',
        fieldName: 'Type__c',
        type: 'text'
    },
    {
        label: 'Status',
        fieldName: 'Status__c',
        type: 'text'
    }
];

export default class Statement extends LightningElement {
    @api recordId;
    startDate;
    endDate;

    columns;
    sortedDirection = 'desc';
    sortedBy = 'Amount__c';
    searchKey = '';
    dataReq;
    dataToBeDisplayed;

    showTable = false;
    showAlert = false;

    page = 1;
    pageSize = 5;
    totalPage = 0;
    startingRecord = 1;
    endingRecord = 0;
    totalRecordCount = 0;
    
    dataPDF;

    value = '';
    sendEmail = false;
    downloadPDF = false;

    get options() {
        return [
            { label: 'CSV', value: 'CSV' },
            { label: 'PDF', value: 'PDF' },
            { label: 'Email PDF', value: 'Email' },
        ];
    }

    @wire(getTransactionsByDate, {contactId:'$recordId', date1:'$startDate', date2:'$endDate', searchKey: '$searchKey', sortBy: '$sortedBy', sortDirection: '$sortedDirection'})
    getData({error, data}){
        if(data){
            this.dataReq = data;
            console.log('Data: ' + this.dataReq);
            this.totalRecordCount = data.length;
            console.log('totalRecordCount: ' + this.totalRecordCount);
            this.totalPage = Math.ceil(this.totalRecordCount / this.pageSize);
            
            this.dataToBeDisplayed = this.dataReq.slice(0,this.pageSize);
            console.log('Data: ' + this.dataReq);
            this.endingRecord = this.pageSize;
            this.columns = columnsForTransaction;

            console.table(this.dataReq);
        }
    }

    closeAction(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleClick(){
        if(!this.validInterval(new Date(this.startDate), new Date(this.endDate))){
            this.showTable = true;
        }
        else{
            this.showTable = false;
            this.showToast('Please select date within six months.');
        }
    }

    handleChange_1(event){
        this.showTable = false;
        this.startDate = event.target.value;
        console.log(this.startDate);
    }

    handleChange_2(event){
        this.showTable = false;
        this.endDate = event.target.value;
        console.log(this.endDate);
    }

    validInterval(date1, date2){
        // const date1 = new Date(this.startDate);
        // const date2 = new Date(this.endDate);
        const diffTime = Math.abs(date2 - date1);
        console.log('diffTime: ' + diffTime);
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        console.log(diffDays + " days");

        if(diffDays >= 180){
            console.log('Wrong Selection');
            this.showAlert = true;
        }
        else{
            this.showAlert = false;
        }

        return this.showAlert;
    }

    showToast(warningForInterval) {
        const event = new ShowToastEvent({
            title: warningForInterval,
            message: 'Toast Message',
            variant: 'warning',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    previousHandler() {
        if (this.page > 1) {
            this.page = this.page - 1; //decrease page by 1
            this.displayRecordPerPage(this.page);
        }
    }

    //clicking on next button this method will be called
    nextHandler() {
        if((this.page<this.totalPage) && this.page !== this.totalPage){
            this.page = this.page + 1; //increase page by 1
            this.displayRecordPerPage(this.page);            
        }             
    }

    displayRecordPerPage(page){

        this.startingRecord = ((page - 1) * this.pageSize) ;
        this.endingRecord = (this.pageSize * page);

        this.endingRecord = (this.endingRecord > this.totalRecordCount) 
                            ? this.totalRecordCount : this.endingRecord; 

        this.dataToBeDisplayed = this.dataReq.slice(this.startingRecord, this.endingRecord);

        this.startingRecord = this.startingRecord + 1;
    }    
    
    handleSortAccountData(event) {       
        this.sortBy = event.detail.fieldName;       
        this.sortDirection = event.detail.sortDirection;       
        this.sortAccountData(event.detail.fieldName, event.detail.sortDirection);
    }


    sortAccountData(fieldname, direction) {
        
        let parseData = JSON.parse(JSON.stringify(this.dataToBeDisplayed));
       
        let keyValue = (a) => {
            return a[fieldname];
        };


       let isReverse = direction === 'asc' ? 1: -1;


           parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; 
            y = keyValue(y) ? keyValue(y) : '';
           
            return isReverse * ((x > y) - (y > x));
        });
        
        this.dataToBeDisplayed = parseData;


    }

    handleKeyChange( event ) {
        try {
            this.searchKey = event.target.value;
            this.page = 1;
            //this.displayRecordPerPage(this.page);
            return refreshApex(this.dataReq);
        } catch (error) {
            console.log('Error: ' + error);
        }
    }

    downloadCSV(){
        let tempList = [];
        this.dataReq.forEach((row) => {
            tempList.push(Object.values(row));
        });
        console.log('tempList: ' + tempList);

        let csvContent = "data:text/csv;charset=utf-8," + tempList.map(row => row.join(',')).join('\n');
        console.log('csvContent: ' + csvContent);
        let encodedUri = encodeURI(csvContent);
        let link = document.createElement("a");
        link.setAttribute("href", encodedUri);
        link.setAttribute("download", "my_data.csv");
        document.body.appendChild(link); // Required for FF
        
        link.click(); // This will download the data file named "my_data.csv".
    }

    jsPdfInitialized = false;

    renderedCallback(){
        console.log('renderedCallback start');
        if (this.jsPdfInitialized) {
            return;
        }
        this.jsPdfInitialized = true;
        
        loadScript(this, JSPDF)
        .then(() => {
            console.log('then');
            // load the autotable js file
            loadScript(this, JSPDF_AUTO_TABLE);
        })
        .catch(error => {
            console.log('error');
            throw(error);
        });
    }

    generatePDF(){
        try {
            console.log('Button pressed to download PDF');
            const { jsPDF } = window.jspdf;
            console.log('{ jsPDF }: ' + {jsPDF});
            const doc = new jsPDF();
            console.log('Doc: ' + doc);

            let finalY = 10;
            console.log('finalY: ' + finalY);
            let dataList = [];
            this.dataReq.forEach((row) => {
                dataList.push(Object.values(row));
            });
            console.log(dataList);
            let cols = [['Name', 'Amount', 'Type', 'Status']];
            console.log('cols: ' + cols);
            doc.text('Here\'s your Data!!!', 14, finalY + 15);
            doc.autoTable({
                startY: finalY + 20,
                head: cols,
                body: dataList,
              })
            
            this.dataPDF = btoa(doc.output()); // this.data can use to create attachment in salesforce
            // var blobUrl = URL.createObjectURL(blobPDF);
            // window.open(blobUrl);
            console.log('dataPDF: ' + this.dataPDF);
            console.log('typeof: ' + typeof(this.dataPDF));

            if(this.downloadPDF){
                doc.save('my_data.pdf');
            }
            
        } catch (error) {
            console.log('Error: ' + error);
        }
        
    }

    emailPDF(){
        this.generatePDF();
        emailWithAttachment({
            contactId : this.recordId,
            blobPDF : this.dataPDF
        });
    }

    handleRadioChange(event){
        this.value = event.target.value;
        console.log('Value: ' + this.value);

        if(this.value == 'CSV' || this.value == 'PDF'){
            this.downloadPDF = true;
            this.sendEmail = false;
        }
        else{
            this.sendEmail = true;
            this.downloadPDF = false;
        }
        
        console.log('sendEmail: ' + this.sendEmail + ' ' + 'downloadPDF: ' + this.downloadPDF);
    }

    downloadOrSendEmail(){
        // this.handleRadioChange();
        if(this.value == 'CSV'){
            this.downloadCSV();
        }
        if(this.value == 'PDF'){
            this.generatePDF();
        }
        if(this.value == 'Email'){
            this.emailPDF();
        }
    }
    
}