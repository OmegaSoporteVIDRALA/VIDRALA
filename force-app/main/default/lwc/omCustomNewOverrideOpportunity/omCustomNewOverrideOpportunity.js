import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import getAccountWithParent from '@salesforce/apex/OM_CustomNewOverrideController.getAccountWithParent';
import getUserProfile from '@salesforce/apex/OM_CustomNewOverrideController.getUserProfile';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';

export default class OmCustomNewOverrideOpportunity extends NavigationMixin(LightningElement) {
    @track showConfirmationModal = false;
    @track showRecordTypeSelector = false;
    @track parentName;
    @api targetObject;

    accountId;
    profileId;

    connectedCallback() {
        getUserProfile()
            .then(profileId => {
                this.profileId = profileId;
                console.log('[LWC] Profile ID cargado:', profileId);
            })
            .catch(error => {
                console.error('[LWC] Error cargando Profile ID:', error);
            });
    }

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        const newAccountId = currentPageReference?.state?.c__accountId;
        const newTargetObject = currentPageReference?.state?.c__targetObject;

        if (newAccountId) {
            this.accountId = newAccountId;
            this.targetObject = newTargetObject ?? this.targetObject;
            this.loadAccountData();
        } else {
            console.warn('[LWC] No se recibió c__accountId en la URL');
        }
    }

    loadAccountData() {
        if (!this.accountId) {
            console.warn('[LWC] accountId no definido — no se cargará Account');
            return;
        }
        getAccountWithParent({ accountId: this.accountId })
            .then(accountData => this.checkAndNavigate(accountData))
            .catch(error => console.error('[LWC] Error cargando Account:', error));
    }

    checkAndNavigate(accountData) {
    const recordType = accountData?.RecordType?.DeveloperName;
    const parentId = accountData?.ParentId;
    const parentName = accountData?.Parent?.Name;
    const parentRT = accountData?.Parent?.RecordType?.DeveloperName;

    console.log('[DEBUG] RecordType:', recordType);
    console.log('[DEBUG] ParentId:', parentId);
    console.log('[DEBUG] ParentRT:', parentRT);
    console.log('[DEBUG] Target Object:', this.targetObject);

    // ✅ Si el account pertenece a un grupo, mostrar siempre el modal de confirmación
    if (recordType === 'Customers' && parentId && parentRT === 'OM_VID_Grupo') {
        this.parentName = parentName;
        this.showConfirmationModal = true;
    } else {
        // Si no cumple las condiciones del grupo, navega directamente
        this.navigate();
    }
}

    navigate(selectedRecordTypeId = null) {
    // 🚀 Caso especial: Supplier_Share__c con selector de Record Type
    if (this.targetObject === 'Supplier_Share__c') {
        if (!selectedRecordTypeId) {
            console.error('[LWC] Intento de navegar a Supplier Share sin un Record Type ID.');
            return;
        }

        // 🧩 Incluir Account__c como valor por defecto
        const defaults = encodeDefaultFieldValues({
            Account__c: this.accountId
        });

        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Supplier_Share__c',
                actionName: 'new'
            },
            state: {
                recordTypeId: selectedRecordTypeId,
                defaultFieldValues: defaults,
                backgroundContext: `/lightning/r/Account/${this.accountId}/view`,
                navigationLocation: 'RELATED_LIST'
            }
        });
        return;
    }

    // 🔹 Resto de objetos → flujo normal
    const defaults = this.getDefaultFields();
    const pageRef = {
        type: 'standard__objectPage',
        attributes: {
            objectApiName: this.targetObject,
            actionName: 'new'
        },
        state: {
            defaultFieldValues: defaults,
            backgroundContext: `/lightning/r/Account/${this.accountId}/view`,
            navigationLocation: 'RELATED_LIST'
        }
    };
    this[NavigationMixin.Navigate](pageRef);
}


    getDefaultFields() {
        let defaults = {};
        switch (this.targetObject) {
            case 'Opportunity':
                defaults.AccountId = this.accountId;
                defaults.StageName = 'Introduction';
                break;
            case 'Case':
                defaults.AccountId = this.accountId;
                defaults.Status = 'Pendiente análisis';
                break;
            case 'Contact':
                defaults.AccountId = this.accountId;
                defaults.Status__c = 'Active';
                break;
            case 'Discount__c':
            case 'Competitor_Action__c':
            case 'Customer_Contact_Report__c':
                defaults.Account__c = this.accountId;
                break;
        }
        return encodeDefaultFieldValues(defaults);
    }

    handleCancel() {
        console.log('[LWC] Usuario canceló → volviendo a la Account');
        this.showConfirmationModal = false;
        this.showRecordTypeSelector = false;

        if (!this.accountId) return;

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.accountId,
                objectApiName: 'Account',
                actionName: 'view'
            }
        }, true); // 👈 fuerza un reload completo
    }

    handleConfirmationContinue() {
    console.log('[LWC] Usuario continuó → cerrando modal de confirmación');
    this.showConfirmationModal = false;

    // ✅ Si es Supplier_Share__c, mostrar selector de RecordType después del modal
    if (this.targetObject === 'Supplier_Share__c') {
        this.showRecordTypeSelector = true;
    } else {
        this.navigate();
    }
}

    handleRecordTypeSelected(event) {
        const { recordTypeId } = event.detail;
        this.showRecordTypeSelector = false;
        this.navigate(recordTypeId);
    }
}