import { LightningElement, track, wire, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getAccountWithParent from '@salesforce/apex/OM_CustomNewOverrideController.getAccountWithParent';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { NavigationMixin } from 'lightning/navigation';

export default class OmCustomNewOverrideOpportunity extends NavigationMixin(LightningElement) {
    @track showModal = false;
    @track parentName;
    @api targetObject;
    

    _accountId;

    // Setter que se dispara cada vez que CurrentPageReference cambia
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        const newAccountId = currentPageReference?.state?.c__accountId;
        const newTargetObject = currentPageReference?.state?.c__targetObject;

        if (newAccountId) {
            this._accountId = newAccountId;
            if (newTargetObject) {
                this.targetObject = newTargetObject;
            } else {
                console.warn('[LWC] No se pasó c__targetObject en la URL');
            }
            this.loadAccountData();
        }
    }
    
    loadAccountData() {
        getAccountWithParent({ accountId: this._accountId })
            .then(accountData => this.checkAndNavigate(accountData))
            .catch(error => console.error('[LWC] Error cargando Account:', error));
    }

    checkAndNavigate(accountData) {
        const recordType = accountData.RecordType.DeveloperName;
        const parentId = accountData.ParentId;
        const parentName = accountData.Parent?.Name;
        const parentRT = accountData.Parent?.RecordType?.DeveloperName;

        console.log('[LWC] recordType:', recordType, 'parentId:', parentId, 'parentName:', parentName, 'parentRT:', parentRT);

        if (recordType === 'Customers' && parentId && parentRT === 'OM_VID_Grupo') {
            this.parentName = parentName;
            this.showModal = true;
            console.log('[LWC] Mostrando modal');
        } else {
            console.log('[LWC] Navegando directo al formulario estándar');
            this.navigate();
        }
    }

    navigate() {
        const defaults = this.getDefaultFields();

        const pageRef = {
            type: 'standard__objectPage',
            attributes: {
                objectApiName: this.targetObject,
                actionName: 'new'
            },
            state: {
                defaultFieldValues: defaults,
                backgroundContext: `/lightning/r/Account/${this._accountId}/view`,
                navigationLocation: 'RELATED_LIST'
            }
        };

        this[NavigationMixin.Navigate](pageRef, true);
    }

    getDefaultFields() {
        let defaults = {};

        switch (this.targetObject) {
            case 'Opportunity':
                defaults.AccountId = this._accountId;
                defaults.StageName = 'Introduction';
                break;
            case 'Case':
                defaults.AccountId = this._accountId;
                defaults.Status = 'Pendiente análisis'; 
                break;
            case 'Contact':
                defaults.AccountId = this._accountId;
                defaults.Status__c = 'Active';
                break;
            case 'Discount__c':
                defaults.Account__c = this._accountId;
                break;
            case 'Competitor_Action__c':
                defaults.Account__c = this._accountId;
                break;
            case 'Customer_Contact_Report__c':
                defaults.Account__c = this._accountId;
                break;
            case 'Competitor_Price__c':
                defaults.Account__c = this._accountId;
                break;   
            default:
                break;
        }

        return encodeDefaultFieldValues(defaults);
    }

    handleCancel() {
         console.log('[LWC] Usuario canceló → cerrando modal y volviendo al Account');

        this.showModal = false;

        // Redirige de nuevo a la Account original
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this._accountId,
                objectApiName: 'Account',
                actionName: 'view'
            }
        });
    }

    handleContinue() {
        console.log('[LWC] Usuario continuó → navegando al formulario estándar');
        this.showModal = false;
        this.navigate();
    }
}