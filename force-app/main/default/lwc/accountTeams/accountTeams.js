import { LightningElement, wire, api, track } from 'lwc';
import getTeamMembers from '@salesforce/apex/AccountTeamController.getTeamMembers';

export default class AccountTeams extends LightningElement {
    @api recordId;
    accountManager = '';
    areaManager = '';
    customerService = ''; 
    salesOffice = ''; 
    accountManagerIT = '';
    customerServiceIT = ''; 
    salesOfficeIT = '';
    accountManagerUK = '';
    areaManagerUK = '';
    customerServiceUK = ''; 
    salesOfficeUK = ''; 
    //Globant Case 00066108
    accountManagerFL = '';
    accountExecutiveFL = '';
    seniorSalesOfficeFL = '';
    salesAdminFL = '';
    //Globant Case 00066108
    get recordIds() {
        return this.recordId ? [this.recordId] : [];
    }

    // Getter to get the first value
    // Getter to get the value of the first key
    getAccount(data) {
        if (data) {
            const keys = Object.keys(data);
            if (keys.length > 0) {
                const firstKey = keys[0];
                return data[firstKey];
            }
        }
        return null;
    }

    @wire(getTeamMembers, { recordIds: '$recordIds' })
    wiredMembers({
        error,
        data
    }) {
        if (data) {
            let accountRecord = this.getAccount(data); 
            if (accountRecord.Account_Manager__c != "undefined" && accountRecord.Account_Manager__c != null) {
                this.accountManager = accountRecord.Account_Manager__r.Name;
            }
            if (accountRecord.Area_Manager__c != "undefined" && accountRecord.Area_Manager__c != null) {
                this.areaManager = accountRecord.Area_Manager__r.Name;
            }
            if (accountRecord.Customer_Service__c != "undefined" && accountRecord.Customer_Service__c != null) {
                this.customerService = accountRecord.Customer_Service__r.Name;
            }
            if (accountRecord.Sales_Office__c != "undefined" && accountRecord.Sales_Office__c != null) {
                this.salesOffice = accountRecord.Sales_Office__r.Name;
            }
            if (accountRecord.Account_Manager_IT__c != "undefined" && accountRecord.Account_Manager_IT__c != null) {
                this.accountManagerIT = accountRecord.Account_Manager_IT__r.Name;
            }
            if (accountRecord.Customer_Service_IT__c != "undefined" && accountRecord.Customer_Service_IT__c != null) {
                this.customerServiceIT = accountRecord.Customer_Service_IT__r.Name;
            }
            if (accountRecord.Sales_Office_IT__c != "undefined" && accountRecord.Sales_Office_IT__c != null) {
                this.salesOfficeIT = accountRecord.Sales_Office_IT__r.Name;
            }
            if (accountRecord.Account_Manager_UK__c != "undefined" && accountRecord.Account_Manager_UK__c != null) {
                this.accountManagerUK = accountRecord.Account_Manager_UK__r.Name;
            }
            if (accountRecord.Area_Manager_UK__c != "undefined" && accountRecord.Area_Manager_UK__c != null) {
                this.areaManagerUK = accountRecord.Area_Manager_UK__r.Name;
            }
            if (accountRecord.Customer_Service_UK__c != "undefined" && accountRecord.Customer_Service_UK__c != null) {
                this.customerServiceUK = accountRecord.Customer_Service_UK__r.Name;
            }
            if (accountRecord.Sales_Office_UK__c != "undefined" && accountRecord.Sales_Office_UK__c != null) {
                this.salesOfficeUK = accountRecord.Sales_Office_UK__r.Name;
            }
            //Globant Case 00066108
            if (accountRecord.Account_Manager_FL__c != "undefined" && accountRecord.Account_Manager_FL__c != null) {
                this.accountManagerFL = accountRecord.Account_Manager_FL__r.Name;
            }
            if (accountRecord.Account_Executive_FL__c != "undefined" && accountRecord.Account_Executive_FL__c != null) {
                this.accountExecutiveFL = accountRecord.Account_Executive_FL__r.Name;
            }
            if (accountRecord.Senior_Sales_Office_FL__c != null) {
                this.seniorSalesOfficeFL = accountRecord.Senior_Sales_Office_FL__c;
            }
            if (accountRecord.Sales_Admin_FL__c != null) {
                this.salesAdminFL = accountRecord.Sales_Admin_FL__c;
            }
            //Globant Case 00066108
        } else if (error) {
            this.error = error;
            console.log(this.error);
        }
    }
}