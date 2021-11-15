import { LightningElement, track, wire, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import getTransactions from '@salesforce/apex/getRelatedTransactions.getTransactions'

export default class MiniStatement extends LightningElement {

    dataReq;

    @track columnsForTransaction = [
        {
            label: 'Name',
            fieldName: 'TxURL',
            type: 'url',
            typeAttributes: {
                label: {
                    fieldName: 'Name'
                },
                target: '_blank'
            }
        },
        {
            label: 'Amount',
            fieldName: 'Amount__c',
            type: 'number'
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

    @api recordId;
    value;

    @wire(getTransactions, {contactId:'$recordId', value:'$value'})
    getData(result){
        if(result.data != undefined){
            console.log('ID passed to the Apex class is: ' + this.recordId);
            console.log('Data: ' + result.data);

            let tempTxList = [];
            result.data.forEach((record) => {
                let tempTxRec = Object.assign({}, record);
                tempTxRec.TxURL = '/lightning/r/Account/' + tempTxRec.Id + '/view';
                tempTxList.push(tempTxRec);
            });

            this.dataReq = tempTxList;
            console.table(this.dataReq);
        }
    }
    
    get options(){
        return [
            {label: '5', value: '5'},
            {label: '10', value: '10'},
            {label: '15', value: '15'},
            {label: '20', value: '20'},
            {label: '25', value: '25'}    
        ]
    }

    closeAction(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleClick(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleChange(event){
        this.value = event.target.value;
    }

}