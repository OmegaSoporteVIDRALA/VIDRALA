import { LightningElement, api, wire } from 'lwc';
import getAvailableRecordTypes from '@salesforce/apex/OM_CustomRTSelectorController.getRecordTypes';
import getObjectLabel from '@salesforce/apex/OM_CustomRTSelectorController.getObjectLabel';
import OM_SELECT_RT from '@salesforce/label/c.omSelectRT'; 

export default class OmCustomRtSelector extends LightningElement {
    @api targetObject; 
    @api profileId; 
    recordTypeOptions = [];
    selectedRecordTypeId;
    objectLabel = 'Record';

    label = {
        RT_MESSAGE: OM_SELECT_RT
    };

    get isContinueDisabled() {
        return !this.selectedRecordTypeId;
    }

    @wire(getObjectLabel, { objectApiName: '$targetObject' })
    wiredObjectLabel({ error, data }) {
        if (data) {
            this.objectLabel = data; 
        } else if (error) {
            console.error('[LWC Selector] Error cargando Object Label:', error);
        }
    }
    
    @wire(getAvailableRecordTypes, { objectApiName: '$targetObject', profileId: '$profileId' })
    wiredRecordTypes({ error, data }) {
        if (data && data.length > 0) {
            this.recordTypeOptions = data.map((rt, index) => ({
                ...rt,
                checked: index === 0
            }));
            this.selectedRecordTypeId = this.recordTypeOptions[0].value;
        } else if (error) {
            this.recordTypeOptions = [];
            console.error('[LWC Selector] Error cargando Record Types:', error);
        }
    }

    handleRecordTypeChange(event) {
        this.selectedRecordTypeId = event.target.value;
    }

    handleContinue() {
        if (this.selectedRecordTypeId) {
            this.dispatchEvent(new CustomEvent('recordtypeselected', {
                detail: { recordTypeId: this.selectedRecordTypeId },
                bubbles: true,
                composed: true 
            }));
        }
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel', {
            bubbles: true,
            composed: true 
        }));
    }
}