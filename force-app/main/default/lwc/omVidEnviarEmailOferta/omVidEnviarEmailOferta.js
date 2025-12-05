import { LightningElement, api, wire} from 'lwc';
import {CurrentPageReference} from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import validateErrors from '@salesforce/apex/OM_VID_EnviarEmailOfertaController.validateErrors';

export default class OmVidEnviarEmailOferta extends LightningElement {
    @api recordId;

    // eslint-disable-next-line no-undef
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            // eslint-disable-next-line @lwc/lwc/no-api-reassignments
            this.recordId = currentPageReference.state.recordId;
        }
    }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    connectedCallback() {
        validateErrors({quoteId : this.recordId
        }).then(res => {
            if(res === 'Ok'){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Correcto',
                        message: 'Se ha enviado el email correctamente.',
                        variant: 'success',
                        mode: 'sticky'
                    })
                )
            }else{
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Fallo',
                        message: res,
                        variant: 'error',
                        mode: 'sticky'
                    })
                )
            }
        })
        .catch((error) => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Fallo',
                    message: 'Se produjo un error inesperado. Contacte con su administrador.',
                    variant: 'error',
                    mode: 'sticky'
                })
            );
        })
        .finally(() => {
            this.closeQuickAction();
        });
    }
}