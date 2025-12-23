import { LightningElement, api, wire} from 'lwc';
import {CurrentPageReference} from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import validateErrors from '@salesforce/apex/OM_VID_EnviarEmailOfertaController.validateErrors';

export default class OmVidEnviarEmailOferta extends LightningElement {
    recordId;
    _hasRun = false;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        console.log('OM _hasRun? ' + this._hasRun);
        if (!currentPageReference || this._hasRun){
            console.log('OM _hasRun');
            return;
        }

        const state = currentPageReference.state || {};
        this.recordId = state.recordId || state.c__recordId;

        if (this.recordId) {
            this._hasRun = true;
            this.runValidation();
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Fallo',
                    message: 'No se encontró el Id de registro en la URL.',
                    variant: 'error',
                    mode: 'sticky'
                })
            );
            this.dispatchEvent(new CloseActionScreenEvent());
        }
    }

    async runValidation() {
        try {
            const res = await validateErrors({ quoteId: this.recordId });

            if (res === 'Ok') {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Correcto',
                        message: 'Se ha enviado el email correctamente.',
                        variant: 'success',
                        mode: 'dismissable'
                    })
                );
            } else {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Fallo',
                        message: res || 'Se produjo un error de validación.',
                        variant: 'error',
                        mode: 'sticky'
                    })
                );
            }
        } catch (error) {
            const msg =
                (error?.body && (error.body.message || error.body.exceptionType)) ||
                error?.message ||
                'Se produjo un error inesperado. Contacte con su administrador.';
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Fallo',
                    message: msg,
                    variant: 'error',
                    mode: 'sticky'
                })
            );
        } finally {
            this.dispatchEvent(new CloseActionScreenEvent());
        }
    }
}