import { LightningElement, track, wire, api } from 'lwc';
import getTableData from '@salesforce/apex/OM_VID_StocksTableController.getTableData';
import getProduct from '@salesforce/apex/OM_VID_StocksTableController.getProductCode';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import makeBWStocksCallout from '@salesforce/apex/OM_VID_StocksTableController.makeBWStocksCallout';

export default class OmStocksTable extends LightningElement {

    tableData = [];
    errors;
    ratiosNumber = 0;
    numStockBOT = 0;
    numStockPAL = 0;
    stockSubHeaders = [];
    totalValues = [];
    productCode;

    
    @track isSearchScreen = true;
    @track isInitialScreen = true;
    @track isLoadScreen = false;
    
    @track mesAno = '';
    @track selectedMonth = '';
    @track selectedMonthLabel = '';
    @track selectedYear = '';
    @track showTable = false;

    @track recordId;
    currentPageReference = null; 
    urlStateParameters = null;
  
    @wire(CurrentPageReference)
    getPageReferenceParameters(currentPageReference) {
       if (currentPageReference) {
          console.log(currentPageReference);
          this.recordId = currentPageReference.attributes.recordId;
          let attributes = currentPageReference.attributes;
          let states = currentPageReference.state;
          let type = currentPageReference.type;
       }
    }
    

    @wire(getProduct, { productId: '$recordId' })
    wiredProductCode({ error, data }) {
    if (data) {
        this.productCode = data.OM_Product_Code_SIP__c; 
        console.log('Código del producto obtenido:', this.productCode);  
    } else if (error) {
        console.error('Error al obtener el código del producto:', error);
    }
    }

    

    handleInvalidYear(event) {
        if (!this.selectedYear) {
            event.target.setCustomValidity('Por favor, selecciona un año.');
        } else {
            event.target.setCustomValidity('');
        }
    }

    
    handleInvalidMonth(event) {
        if (!this.selectedMonth) {
            event.target.setCustomValidity('Por favor, selecciona un mes.');
        } else {
            event.target.setCustomValidity('');
        }
    }
    

    handleNavigateToSelectionScreen() {
      
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: '', 
                objectApiName: 'Product2', 
                actionName: 'view'
            }
        });
    }

     
    generateMonthOptions() {
        const months = [
            { label: 'Enero', value: '01' },
            { label: 'Febrero', value: '02' },
            { label: 'Marzo', value: '03' },
            { label: 'Abril', value: '04' },
            { label: 'Mayo', value: '05' },
            { label: 'Junio', value: '06' },
            { label: 'Julio', value: '07' },
            { label: 'Agosto', value: '08' },
            { label: 'Septiembre', value: '09' },
            { label: 'Octubre', value: '10' },
            { label: 'Noviembre', value: '11' },
            { label: 'Diciembre', value: '12' }
        ];

        this.monthOptions = months;
    }

    
    yearOptions = Array.from({ length: 20 }, (_, i) => {
        const year = new Date().getFullYear() - i;
        return { label: `${year}`, value: `${year}` };
    });

    handleMonthChange(event) {
        
        this.selectedMonth = event.detail.value; 

        
        const selectedOption = this.monthOptions.find(option => option.value === this.selectedMonth);
        
        if (selectedOption) {
            this.selectedMonthLabel = selectedOption.label;
        } else {
            this.selectedMonthLabel = '';
        }

        
        console.log('Valor seleccionado:', this.selectedMonth);  
        console.log('Label seleccionado:', this.selectedMonthLabel);  
    }

    handleYearChange(event) {
        this.selectedYear = event.detail.value;
        console.log('Mes seleccionado:', this.selectedYear);
    }

    

    handleSearch() {
        if (!this.selectedYear || !this.selectedMonth) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Seleccione un Mes y un Año antes de buscar.',
                variant: 'error'
            }));
            return;
        }
        this.isInitialScreen = false;
        this.isLoadScreen = true;
    
        getTableData({ 
            year: this.selectedYear, 
            month: this.selectedMonth, 
            model: this.productCode 
        })
        .then((data) => {
            console.log('Resultado de la consulta:', data);
            if (data && data.tableData && data.tableData.length > 0) {
                this.tableData = data.tableData;
                this.numStockBOT = data.numStockBOT;
                this.numStockPAL = data.numStockPAL;
                this.ratiosNumber = data.ratiosNumber;
                this.stockSubHeaders = data.stockSubHeaders;
                this.totalValues = data.totalValues;
                this.isSearchScreen = false; 
                this.isLoadScreen = false;

                console.log('totalvalues', this.totalValues);

            } else {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Aviso',
                    message: 'No se encontraron datos.',
                    variant: 'warning'
                }));

                this.isInitialScreen = true;
                this.isSearchScreen = true;
                this.isLoadScreen = false;
            }
        })
        .catch((error) => {
            console.error('Error obteniendo datos:', error);
            let mensaje = 'No se pudo recuperar la información. Vuelva a intentarlo.';
            if (error.body && error.body.exceptionType === 'AuraHandledException') {
                mensaje = 'La búsqueda no arrojó resultados.';
            }
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: mensaje,
                variant: 'error'
            }));

            this.isInitialScreen = true;
            this.isSearchScreen = true;
            this.isLoadScreen = false;
        });
    }

    handleSort(event) {
        const column = event.target.dataset.column; 
        const direction = this.sortDirection === 'asc' ? 'desc' : 'asc'; 
        this.sortDirection = direction;
        this.sortedColumn = column;

        this.tableData = [...this.tableData].sort((a, b) => {
            let valueA = a[column];
            let valueB = b[column];

            
            if (!isNaN(valueA) && !isNaN(valueB)) {
                valueA = parseFloat(valueA);
                valueB = parseFloat(valueB);
            }

            if (direction === 'asc') {
                return valueA > valueB ? 1 : -1;
            } else {
                return valueA < valueB ? 1 : -1;
            }
        });
    }
    
    handleBackToSearch() {
        this.cacheBuster = new Date().getTime();
        this.isInitialScreen = true;
        this.isSearchScreen = true;
        this.selectedMonth = '';  
        this.selectedYear = '';
    }

    connectedCallback() {
        
        this.generateMonthOptions();
        console.log('Record ID:', this.recordId);
    }

    
    
}