import { LightningElement, wire, api } from 'lwc';
import getDiscounts from '@salesforce/apex/CustomRelatedListController.getDiscounts';
import getAgreements from '@salesforce/apex/CustomRelatedListController.getAgreements';
import {getRecord} from 'lightning/uiRecordApi';
import { NavigationMixin } from "lightning/navigation";

const columns = [
    { label: 'Name', fieldName: 'Name' },
    { label: 'Status', fieldName: 'Status__c'},
    { label: 'Currency', fieldName: 'CurrencyIsoCode'},
    { label: 'Unit type', fieldName: 'Unit_Type__c'},
    { label: 'Product', fieldName: 'ProductName__c'},
    { label: 'Quantity', fieldName: 'Quantity__c'},
    { label: 'Percentage', fieldName: 'Percentage__c'},
    { label: 'Type', fieldName: 'TYPE__c' },
    { label: 'EUR', fieldName: 'EUR__c' },
];

const agreementColumns = [
    { label: 'Name', fieldName: 'Name' },
    { label: 'Agreement', fieldName: 'Agreement__c'},
    { label: 'Agreement Code', fieldName: 'Agreement_Code__c'},
    { label: 'Credit Price', fieldName: 'Credit_Price__c' },
    { label: 'Debit Price', fieldName: 'Debit_Price__c'},
    { label: 'Material', fieldName: 'Material__c'},
];

export default class QuoteRelatedList extends NavigationMixin(LightningElement) {
    @api recordId;
    data = [];
    dataAgreement = [];
    columns = columns;
    agreementColumns = agreementColumns;
    isDataEmpty = false;
    isDataAgreementEmpty = false;

    @wire(getDiscounts, { recordId: '$recordId' })
    wiredDiscounts({
        error,
        data
    }) {
        if (data) {
            console.log('data='+JSON.stringify(data));
            this.data = data;
            if (typeof this.data != "undefined" 
                        && this.data != null 
                        && this.data.length != null 
                        && this.data.length > 0)
                this.isDataEmpty = true;
            else
                this.isDataEmpty = false;
        } else if (error) {
            this.error = error;
            console.log(this.error);
        }
    }

    @wire(getAgreements, { recordId: '$recordId' })
    wiredAgreements({
        error,
        data
    }) {
        if (data) {
            this.dataAgreement = data;
            if (typeof this.dataAgreement != "undefined" 
                        && this.dataAgreement != null 
                        && this.dataAgreement.length != null 
                        && this.dataAgreement.length > 0)
                this.isDataAgreementEmpty = true;
            else
                this.isDataAgreementEmpty = false;
        } else if (error) {
            this.error = error;
            console.log(this.error);
        }
    }
    handleGotoDiscounts() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordRelationshipPage',
            attributes: {
                recordId: this.data[0].Account__c,
                objectApiName: 'Account',
                relationshipApiName: 'Discounts__r',
                actionName: 'view'
            },
        });
    }
    handleGotoAgreements() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordRelationshipPage',
            attributes: {
                recordId: this.dataAgreement[0].Account__c,
                objectApiName: 'Account',
                relationshipApiName: 'Packaging_Agreements__r',
                actionName: 'view'
            },
        });
    }
}