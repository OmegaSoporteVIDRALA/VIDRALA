import { LightningElement, track, wire, api } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getTableData from '@salesforce/apex/OM_VID_VentasAbonosTableController.getTableData';
import getAccount from '@salesforce/apex/OM_VID_VentasAbonosTableController.getAccountCode';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOrderReasonValues from '@salesforce/apex/OM_VID_VentasAbonosTableController.getOrderReasonValues';
import getMaterials from '@salesforce/apex/OM_VID_VentasAbonosTableController.getMaterials';
import NAME_FIELD from '@salesforce/schema/Product2.Name';
import CODE_FIELD from '@salesforce/schema/Product2.OM_Product_Code_SIP__c';

export default class OmSacVentasAbonos extends LightningElement {
    
    tableData = [];
    errors;
    ratiosNumber = 0;
    customerCode;
    materialOptions = [];
    isDisabled = true; 
    placeholderMaterial = 'Todos';
    productOptions = [];
    isDisabledProduct = true; 
    placeholderProduct = 'Todos';
    @track isSearchScreen = true;
    @track isInitialScreen = true;
    @track isLoadScreen = false;
    @track selectedMonth = '';
    @track selectedMonthLabel = '';
    @track selectedMonthTo = '';
    @track selectedMonthToLabel = '';
    @track selectedYear = '';
    @track selectedYearTo = '';
    @track selectedOrderLabel = '';
    @track selectedMaterial = '';
    @track selectedProduct = '';
    @track showTable = false;
    @track recordId;
    @track orderOptions = [];
    @track selectedProductId = '';
    @track selectedProductName = '';
    @track selectedProductCode = 'vacio';
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
    
    @wire(getAccount, { accountId: '$recordId' })
    wiredProductCode({ error, data }) {
        if (data) {
            this.customerCode = data.SAP_Account_Number__c;
            console.log('Código del cliente obtenido:', this.customerCode);
        } else if (error) {
            console.error('Error al obtener el código de la cuenta:', error);
        }
    }

    // Obtener datos del producto seleccionado
    @wire(getRecord, { recordId: '$selectedProductId', fields: [NAME_FIELD, CODE_FIELD] })
    wiredProduct({ data, error }) {
        if (data) {
            this.selectedProductName = data.fields.Name.value;
            this.selectedProductCode = data.fields.OM_Product_Code_SIP__c.value;
            console.log('Nombre:', this.selectedProductName);
            console.log('Código SIP:', this.selectedProductCode);
        } else if (error) {
            console.error('Error al recuperar datos del producto:', error);
        }
    }

    // Cuando se selecciona producto desde el lookup
    handleSelected(event) {
        const selectedRecord = event.detail[0]; // objeto completo
        if (selectedRecord && selectedRecord.Id) {
            this.selectedProductId = selectedRecord.Id;
            console.log('Producto seleccionado ID:', this.selectedProductId);
            this.loadMaterials();
        } else {
            this.selectedProductId = '';
            this.selectedProductCode = 'vacio';
            this.selectedProductName = '';
            this.materialOptions = [];
            this.selectedMaterial = 'vacio';
            this.isDisabled = true;
            console.log('Producto deseleccionado, valores reseteados');
        }
    }

    

    handleInvalidProduct(event) {
        if (!this.selectedProduct) {
            event.target.setCustomValidity('Por favor, selecciona un Product.');
        } else {
            event.target.setCustomValidity('');
        }
    }

    loadMaterials() {
    getMaterials({ productId: this.selectedProductId })
        .then(data => {
            if (data && data.length > 0) {
                this.materialOptions = [
                    { label: 'Todos', value: 'vacio' },
                    ...data.map(material => ({
                        label: material,
                        value: material
                    }))
                ];
                this.selectedMaterial = 'vacio';
                this.isDisabled = false;
                console.log('Materiales cargados');
            } else {
                this.materialOptions = [];
                this.selectedMaterial = 'vacio';
                this.isDisabled = true;
                console.log('Sin materiales para este producto');
            }
        })
        .catch(error => {
            console.error('Error al cargar materiales:', error);
            this.materialOptions = [];
            this.selectedMaterial = 'vacio';
            this.isDisabled = true;
        });
}

    handleMaterialChange(event) {
        this.selectedMaterial = event.target.value; 
        console.log('Material seleccionado:', this.selectedMaterial); 
    }

    handleInvalidMaterial(event) {
        if (!this.selectedMaterial) {
            event.target.setCustomValidity('Por favor, selecciona un Material.');
        } else {
            event.target.setCustomValidity('');
        }
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

    generateMonthToOptions() {
        const monthsTo = [
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

        this.monthToOptions = monthsTo;
    }

    yearOptions = Array.from({ length: 20 }, (_, i) => {
        const year = new Date().getFullYear() - i;
        return { label: `${year}`, value: `${year}` };
    });

    yearToOptions = Array.from({ length: 20 }, (_, i) => {
        const year = new Date().getFullYear() - i;
        return { label: `${year}`, value: `${year}` };
    });

    connectedCallback() {
        this.loadPicklistValues();
    }

    loadPicklistValues() {
        getOrderReasonValues({ objectApiName: 'Account', fieldApiName: 'OM_VID_Order_Reason__c' })
        .then(result => {
            
            this.orderOptions = result;
        })
            .catch(error => {
                console.error('Error obteniendo valores de la picklist:', error);
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: 'No se pudieron cargar los motivos de pedido.',
                    variant: 'error'
                }));
            });
    }

    handleInvalidYear(event) {
        if (!this.selectedYear) {
            event.target.setCustomValidity('Por favor, selecciona un año de inicio.');
        } else {
            event.target.setCustomValidity('');
        }
    }

    handleInvalidYearTo(event) {
        if (!this.selectedYearTo) {
            event.target.setCustomValidity('Por favor, selecciona un año de fin.');
        } else {
            event.target.setCustomValidity('');
        }
    }

    
    handleInvalidMonth(event) {
        if (!this.selectedMonth) {
            event.target.setCustomValidity('Por favor, selecciona un mes de inicio.');
        } else {
            event.target.setCustomValidity('');
        }
    }

    handleInvalidMonthTo(event) {
        if (!this.selectedMonthTo) {
            event.target.setCustomValidity('Por favor, selecciona un mes de fin.');
        } else {
            event.target.setCustomValidity('');
        }
    }

    handleInvalidOrder(event) {
        if (!this.selectedOrder) {
            event.target.setCustomValidity('Por favor, selecciona un Motivo de pedido.');
        } else {
            event.target.setCustomValidity('');
        }
    }
    

    
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

    handleMonthToChange(event) {
        
        this.selectedMonthTo = event.detail.value; 

        
        const selectedOption = this.monthToOptions.find(option => option.value === this.selectedMonthTo);
        
        if (selectedOption) {
            this.selectedMonthToLabel = selectedOption.label;
        } else {
            this.selectedMonthToLabel = '';
        }

        
        console.log('Valor seleccionado:', this.selectedMonthTo);  
        console.log('Label seleccionado:', this.selectedMonthToLabel);  
    }

    

    handleOrderChange(event) {
        
        this.selectedOrder = event.detail.value; 

        
        const selectedOption = this.orderOptions.find(option => option.value === this.selectedOrder);
        
        if (selectedOption) {
            this.selectedOrderLabel = selectedOption.label;
        } else {
            this.selectedOrderLabel = null;
        }

        
        console.log('Valor seleccionado:', this.selectedOrder);  
        console.log('Label seleccionado:', this.selectedOrderLabel);  
    }


    handleYearChange(event) {
        this.selectedYear = event.detail.value;
        console.log('Mes seleccionado:', this.selectedYear);
    }

    handleYearToChange(event) {
        this.selectedYearTo = event.detail.value;
        console.log('Año fin seleccionado:', this.selectedYearTo);
    }

    handleNavigateToSelectionScreen() {
      
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: '', 
                objectApiName: 'Account', 
                actionName: 'view'
            }
        });
    }

    
    handleSearch() {
        if (!this.selectedYear || !this.selectedYearTo || !this.selectedMonth || !this.selectedMonthTo || !this.selectedOrder) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Introduzca los campos Obligarios para continuar.',
                variant: 'error'
            }));
            return;
        }

        if ((this.selectedOrder.includes('vacio') || this.selectedOrder.includes('#')) && (this.selectedMonth !== this.selectedMonthTo || this.selectedYear !== this.selectedYearTo)) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Si se selecciona la opción Todos o Sin asignar , la búsqueda solo puede realizarse en un mismo mes',
                variant: 'error'
            }));
            return;
        }


        if (this.selectedYear > this.selectedYearTo)  {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'El año de Inicio no puede ser mayor al año de Fin',
                variant: 'error'
            }));
            return;
        }

        if (this.selectedYear === this.selectedYearTo && this.selectedMonth > this.selectedMonthTo){
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'El mes de Inicio no puede ser mayor al mes de Fin',
                variant: 'error'
            }));
            return;
        }

        const params = {
            yearFrom: this.selectedYear, 
            yearTo: this.selectedYearTo, 
            monthFrom: this.selectedMonth,
            monthTo: this.selectedMonthTo, 
            customerCode: this.customerCode,
                
        };

    if (!this.selectedOrder.includes('vacio') ) {
        params.orderReason = this.selectedOrder; 
    }

    if (this.selectedProductCode !== 'vacio') {
            params.model = this.selectedProductCode;
    }   

    if (this.selectedMaterial !== 'vacio') {
            params.material = this.selectedMaterial;
    }
    
    this.isInitialScreen = false;
    this.isLoadScreen = true;

    
    getTableData(params)
        .then((data) => {
            console.log('Resultado de la consulta:', data);
            console.log('params', params);
            
            if (data && data.tableData && data.tableData.length > 0) {
                this.tableData = data.tableData; 
                this.ratiosNumber = data.ratiosNumber;
                this.isSearchScreen = false; 
                this.isLoadScreen = false; 
                console.log('** esto es ratiosNumber: '+data.ratiosNumber);
                
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
        this.selectedMonthTo = '';    
        this.selectedOrder = '';  
        this.selectedYear = '';
        this.selectedYearTo = '';
        this.selectedProductCode = 'vacio';
        this.selectedProductId = '';
        this.selectedProductName = '';
        this.selectedMaterial = 'vacio';

    }

    connectedCallback() {
        
        this.generateMonthOptions();
        this.generateMonthToOptions();
        this.loadPicklistValues();
        console.log('Record ID:', this.recordId);
    }
}