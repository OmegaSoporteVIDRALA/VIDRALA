import { LightningElement, api, wire, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import createQuoteFromOpportunity from '@salesforce/apex/OM_VID_GenerateOffersController.createQuote';

const FIELDS = ['Opportunity.StageName', 'Opportunity.HasOpportunityLineItem'];

export default class OMGenerateOffers extends LightningElement {
    @api recordId;
      
    stageName;
    numPLI;
    @track isScreenOpen = true;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    opportunityRecord({ data, error }) {
        console.log('Id deOportunidad:', this.recordId);
        if (data) {
            this.stageName = data.fields.StageName.value;
            this.numPLI = data.fields.HasOpportunityLineItem.value;

            
        } else if (error) {
            this.showToast('Error', 'Error al recuperar la oportunidad.', 'error');
        }
    }

    handleConfirm() {
        this.validateOpportunity();
    }

    validateOpportunity() {
    if (this.stageName !== 'Quotation') {
        this.showToast('Error', 'La oportunidad debe estar en estado "Quotation" para generar la Quote.', 'error');
        this.closeScreen();
    } else if (!this.numPLI) {
        this.showToast('Error', 'Debe añadir al menos un producto a la Oportunidad.', 'error');
        this.closeScreen();
    } else {
        this.handleCreateQuote();
    }
    }

    handleCreateQuote() {
    createQuoteFromOpportunity({ opportunityId: this.recordId })
        .then(() => {
            this.showToast('Éxito', 'La Oferta se ha creado correctamente.', 'success');
            this.closeScreen(); 
        })
        .catch(error => {
            this.showToast('Error', 'Error al crear la Oferta: ' + error.body.message, 'error');
            this.closeScreen();
        });
    }

    closeScreen() {
        this.isScreenOpen = false;
        this.dispatchEvent(new CloseActionScreenEvent());
    
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}