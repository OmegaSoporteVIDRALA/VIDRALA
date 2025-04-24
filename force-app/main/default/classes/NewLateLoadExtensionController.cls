/* -----------------------------------------------------------------------------------------------------------------------
   Name:        NewLateLoadExtensionController.cls
   Description: Extension controller class for New Late Load button
                    
   Date         Version Author              Summary of Changes 
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Nov 2017     1.0     M.Witchalls(Ciber)  Initial Release 
   Sep 2024     2.0     Globant             Added Comments and Code Refactoring
------------------------------------------------------------------------------------------------------------------------ */        
public with sharing class NewLateLoadExtensionController {
    
    private static final String ONTIME_STATUS = 'On Time';
    private static final String LATE_STATUS = 'Late';
    private static final String EARLY_STATUS = 'Early';
    private static final String ERROR_STRING = ': You must enter a value';
    private static final String RT_LATE = 'Late_Load';
    private static final String RT_EARLY = 'Early_Load';
    private static final String RT_COLLAPSED = 'Collapsed_Load';
    private static final String COLLAPSED_STATE = 'COLLAPSED';
    private static final String PALLET_FIELD = 'Pallets_damaged__c';

    private static final Map<String, String> PAGE_RT_MAP = new Map<String, String>{
        'newlateload' => RT_LATE,
        'newearlyload' => RT_EARLY,
        'newcollapsedload' => RT_COLLAPSED
    };
    
    private static final Map<String, String> PAGE_STATUS_MAP = new Map<String, String>{
        'newlateload' => LATE_STATUS,
        'newearlyload' => EARLY_STATUS,
        'newcollapsedload' => ONTIME_STATUS
    };
    
    private String rtDeveloperName; 
    private String dispatchId;
    private String baseName;

    public Dispatch__c dispatch { get; set; }
    public Late_Load__c load { get; set; }
    public String recordTypeName { get; set; }

    private transient LateLoadHandler lHandler;
    private transient DispatchProvider dProvider; 
    private transient String pageName;
    
    /**
     * Constructor for NewLateLoadExtensionController
     * 
     * @param stdController The standard controller for Dispatch__c.
     */
    public NewLateLoadExtensionController(ApexPages.StandardController stdController) {
        lHandler = new LateLoadHandler();
        dProvider = new DispatchProvider();
        this.dispatchId = ApexPages.currentPage().getParameters().get('id');
        
        if (String.isBlank(this.dispatchId)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Dispatch ID is missing or invalid.'));
            return;
        }

        String pg = EncodingUtil.urlEncode(ApexPages.CurrentPage().getURL().replaceFirst('/apex/',''),'UTF-8');
        this.pageName = pg.split('%3F')[0].toLowerCase();

        if (!PAGE_RT_MAP.containsKey(this.pageName)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Page name is invalid.'));
            return;
        }

        String recordType = PAGE_RT_MAP.get(this.pageName);
        RecordType rt = lHandler.getRecordTypeMap().get(recordType);

        if (rt == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Record Type not found.'));
            return;
        }

        this.rtDeveloperName = rt.DeveloperName;
        this.recordTypeName = rt.Name;      
        this.createLoad(rt.Id);
    }
    
    /**
     * Retrieves the fields for the ReadOnly field set.
     * 
     * @return List of Schema.FieldSetMember for ReadOnly fields.
     */
    public List<Schema.FieldSetMember> getReadOnlyFields() {
        return SObjectType.Late_Load__c.FieldSets.ReadOnly.getFields();
    }

    public List<Schema.FieldSetMember> getLateLoadFields() {
        return SObjectType.Late_Load__c.FieldSets.LateLoad.getFields();
    }
    
    public List<Schema.FieldSetMember> getEarlyLoadFields() {
        return SObjectType.Late_Load__c.FieldSets.EarlyLoad.getFields();
    }
    
    public List<Schema.FieldSetMember> getCollapsedLoadFields() {
        return SObjectType.Late_Load__c.FieldSets.CollapsedLoad.getFields();
    }
    
    public List<Schema.FieldSetMember> getCustomerInformedFields() {
        return SObjectType.Late_Load__c.FieldSets.CustomerInformed.getFields();
    }
    
    public List<Schema.FieldSetMember> getLinesDownFields() {
        return SObjectType.Late_Load__c.FieldSets.LinesDown.getFields();
    }
    
    public List<Schema.FieldSetMember> getReplacementFields() {
        return SObjectType.Late_Load__c.FieldSets.Replacement.getFields();
    }

    /**
     * Creates a new Late Load record based on the record type ID.
     * 
     * @param recordTypeId The record type ID for the new Late Load.
     */
    private void createLoad(String recordTypeId) {
        dispatch = dProvider.getDispatchById(this.dispatchId);

        if (dispatch == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Dispatch not found.'));
            return;
        }

        this.baseName = dispatch.Dispatch_ID__c + '-' + String.valueOf(dispatch.Early_Late_Collapsed_Loads__c + 1).leftPad(3).replace(' ', '0');
        String status = PAGE_STATUS_MAP.get(this.pageName);
        
        load = new Late_Load__c(
            RecordTypeId = recordTypeId,
            Status__c = status,
            Collapsed__c = (status == ONTIME_STATUS) ? true : false,  
            Name = (status == ONTIME_STATUS) ? this.baseName + ' ' + COLLAPSED_STATE : this.baseName + ' ' + status.toUpperCase(),                
            Dispatch__c = dispatch.Id,
            Customer__c = dispatch.Customer__c,
            Product__c = dispatch.Bottle__c,
            Haulier__c = dispatch.Haulier__c,
            Customer_Informed__c = false,
            Customers_lines_down__c = false,
            Was_load_replaced__c = false
        );
        
        if (status == ONTIME_STATUS) {
            load.New_Delivery_Date__c = dispatch.Planned_Delivery_Date__c;
        } 
    }

    /**
     * Saves the Late Load record and handles validation.
     * 
     * @return A PageReference to the view page of the new record, or null if validation fails.
     */
    public PageReference save() {
        if (load == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'No load to save.'));
            return null;
        }

        load.Name = load.Collapsed__c ? this.baseName + ' ' + COLLAPSED_STATE : this.baseName + ' ' + load.Status__c.toUpperCase();
        if (load.New_Delivery_Date__c == null) {
            load.New_Delivery_Date__c = dispatch.Planned_Delivery_Date__c;
        } 

        Integer errorCount = 0;

        for (Schema.FieldSetMember f : this.getCustomerInformedFields()) {
            if (load.Customer_Informed__c && load.get(f.getFieldPath()) == null) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, f.getLabel() + ERROR_STRING));
                errorCount++;
            }
        }       

        for (Schema.FieldSetMember f : this.getLinesDownFields()) {
            if (load.Customers_lines_down__c && load.get(f.getFieldPath()) == null) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, f.getLabel() + ERROR_STRING));
                errorCount++;
            }
        }   
        
        for (Schema.FieldSetMember f : this.getReplacementFields()) {
            if (load.Was_load_replaced__c && load.get(f.getFieldPath()) == null) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, f.getLabel() + ERROR_STRING));
                errorCount++;
            }
        }           
            
        if (errorCount > 0) {
            return null;
        }

        try {
            insert load;    
            PageReference loadPage = new ApexPages.StandardController(load).view();
            loadPage.setRedirect(true);
            return loadPage;
        } catch (Exception e) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, e.getMessage()));
            return null;                
        }
    }

    /**
     * Handles the change in the replacement field and validates fields accordingly.
     * 
     * @return A null PageReference.
     */
    public PageReference replacementChange() {
        if (load == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Load is not initialized.'));
            return null;
        }

        load.Customer_Informed__c = false;
        load.Customers_lines_down__c = false;

        for (Schema.FieldSetMember f : this.getCollapsedLoadFields()) {
            if (load.get(f.getFieldPath()) == null && f.getFieldPath() != PALLET_FIELD) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, f.getLabel() + ERROR_STRING));
            }
        }           
        
        return null;
    }
    
    /**
     * Handles the change in the customer informed field and validates fields accordingly.
     * 
     * @return A null PageReference.
     */
    public PageReference customerInformedChange() {
        if (load == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Load is not initialized.'));
            return null;
        }

        load.Customers_lines_down__c = false;

        if (rtDeveloperName == RT_COLLAPSED) {
            for (Schema.FieldSetMember f : this.getCollapsedLoadFields()) {
                if (load.get(f.getFieldPath()) == null && f.getFieldPath() != PALLET_FIELD) {
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, f.getLabel() + ERROR_STRING));
                    load.Customer_Informed__c = false;
                }
            }           
        } else if (rtDeveloperName == RT_LATE) {
            for (Schema.FieldSetMember f : this.getLateLoadFields()) {
                if (load.get(f.getFieldPath()) == null) {
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, f.getLabel() + ERROR_STRING));
                    load.Customer_Informed__c = false;
                }
            }
        } else {
            for (Schema.FieldSetMember f : this.getEarlyLoadFields()) {
                if (load.get(f.getFieldPath()) == null) {
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, f.getLabel() + ERROR_STRING));
                    load.Customer_Informed__c = false;
                }
            }           
        }       
        return null;
    }

    /**
     * Handles the change in the lines down field.
     * 
     * @return A null PageReference.
     */
    public PageReference linesDownChange() {
        return null;
    }
}


/*public with sharing class NewLateLoadExtensionController{
    
    private static final String ontimeStatus = 'On Time';
    private static final String lateStatus = 'Late';
    private static final String earlyStatus = 'Early';
    private static final String errorString = ': You must enter a value';
    private static final String rtLate = 'Late_Load';
    private static final String rtEarly = 'Early_Load';
    private static final String rtCollapsed = 'Collapsed_Load';
    private static final String collapsedState = 'COLLAPSED';
    private static final String palletField = 'Pallets_damaged__c';
    
    private static final Map<String,String> pageRTMap = new Map<String,String>{
        'newlateload' => rtLate,
        'newearlyload' => rtEarly,
        'newcollapsedload' => rtCollapsed
    };
    
    private static final Map<String,String> pageStatusMap = new Map<String,String>{
        'newlateload' => lateStatus,
        'newearlyload' => earlyStatus,
        'newcollapsedload' => ontimeStatus
    };
    
    private String rtDeveloperName; 
    private String dispatchId;
    private String baseName;
    
    public Dispatch__c dispatch     {get; set;}
    public Late_Load__c load        {get; set;}
    public String recordTypeName    {get; set;}
    
    private transient Map<String,ID> recordTypeMap;
    private transient LateLoadHandler lHandler;
    private transient DispatchProvider dProvider; 
    private transient String pageName;
    
    public NewLateLoadExtensionController(ApexPages.StandardController stdController) {
        lHandler = new LateLoadHandler();
        dProvider = new DispatchProvider();
        //this.dispatch = (Dispatch__c)stdController.getRecord();
        this.dispatchId = ApexPages.currentPage().getParameters().get('id');
        
        String pg = EncodingUtil.urlEncode(ApexPages.CurrentPage().getURL().replaceFirst('/apex/',''),'UTF-8');
        this.pageName = pg.split('%3F')[0].toLowerCase();
        system.debug('Page Name: '+this.pageName);
        String recordType = pageRTMap.get(this.pageName);
        RecordType rt = lHandler.getRecordTypeMap().get(recordType);
        this.rtDeveloperName = rt.DeveloperName;
        this.recordTypeName = rt.Name;      
        this.createLoad(rt.Id);
    }
    
    public List<Schema.FieldSetMember> getReadOnlyFields() {
        return SObjectType.Late_Load__c.FieldSets.ReadOnly.getFields();
    }
    public List<Schema.FieldSetMember> getLateLoadFields() {
        return SObjectType.Late_Load__c.FieldSets.LateLoad.getFields();
    }
    public List<Schema.FieldSetMember> getEarlyLoadFields() {
        return SObjectType.Late_Load__c.FieldSets.EarlyLoad.getFields();
    }
    public List<Schema.FieldSetMember> getCollapsedLoadFields() {
        return SObjectType.Late_Load__c.FieldSets.CollapsedLoad.getFields();
    }
    public List<Schema.FieldSetMember> getCustomerInformedFields() {
        return SObjectType.Late_Load__c.FieldSets.CustomerInformed.getFields();
    }
    public List<Schema.FieldSetMember> getLinesDownFields() {
        return SObjectType.Late_Load__c.FieldSets.LinesDown.getFields();
    }
    public List<Schema.FieldSetMember> getReplacementFields() {
        return SObjectType.Late_Load__c.FieldSets.Replacement.getFields();
    }

    private void createLoad(String recordTypeId) {
        dispatch = dProvider.getDispatchById(this.dispatchId);
        this.baseName = dispatch.Dispatch_ID__c + '-' + String.valueOf(dispatch.Early_Late_Collapsed_Loads__c + 1).leftPad(3).replace(' ','0');
        String status = pageStatusMap.get(this.pageName);
        
        load = new Late_Load__c(
            RecordTypeId = recordTypeId,
            Status__c = status,
            Collapsed__c = (status == onTimeStatus) ? true : false,  
            Name = (status == onTimeStatus) ? this.baseName + ' ' + collapsedState : this.baseName + ' ' + status.toUpperCase(),                
            Dispatch__c = dispatch.Id,
            Customer__c = dispatch.Customer__c,
            Product__c = dispatch.Bottle__c,
            Haulier__c = dispatch.Haulier__c,
            Customer_Informed__c = false,
            Customers_lines_down__c = false,
            Was_load_replaced__c = false
        );
        if (status == onTimeStatus) load.New_Delivery_Date__c = dispatch.Planned_Delivery_Date__c;
                 
        system.debug('Late Load Record: '+load);  
    }

    public PageReference save(){
        load.Name = load.Collapsed__c ? this.baseName + ' ' + collapsedState : this.baseName + ' ' + load.Status__c.toUpperCase();
        if (load.New_Delivery_Date__c == null) load.New_Delivery_Date__c = dispatch.Planned_Delivery_Date__c;
        system.debug('Late Load Record: '+load);
                    
        Integer errorCount = 0;
        for(Schema.FieldSetMember f: this.getCustomerInformedFields()) {
            if (load.Customer_Informed__c && load.get(f.getFieldPath()) == null) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, f.getLabel() + errorString));
                errorCount++;
            }
        }       
        for(Schema.FieldSetMember f: this.getLinesDownFields()) {
            if (load.Customers_lines_down__c && load.get(f.getFieldPath()) == null) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, f.getLabel() + errorString));
                errorCount++;
            }
        }   
        for(Schema.FieldSetMember f: this.getReplacementFields()) {
            if (load.Was_load_replaced__c && load.get(f.getFieldPath()) == null) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, f.getLabel() + errorString));
                errorCount++;
            }
        }           
        if (errorCount > 0) {
            return null;
        } else {
            try {
                insert load;    
                PageReference loadPage = new ApexPages.StandardController(load).view();
                system.debug(loadPage.getURL());
                loadPage.setRedirect(true);
                return loadPage;
            } catch(Exception e) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, e.getMessage()));
                return null;                
            }
        }
    }
    public PageReference replacementChange(){
        load.Customer_Informed__c = false;
        load.Customers_lines_down__c = false;
        for(Schema.FieldSetMember f: this.getCollapsedLoadFields()) {
            if (load.get(f.getFieldPath()) == null && f.getFieldPath() != palletField) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, f.getLabel() + errorString));
            }
        }           
        return null;
    }
    
    public PageReference customerInformedChange(){
        load.Customers_lines_down__c = false;
        system.debug('rtDeveloperName,rtCollapsed: '+rtDeveloperName+':'+rtCollapsed);
        if (rtDeveloperName == rtCollapsed) {
            for(Schema.FieldSetMember f: this.getCollapsedLoadFields()) {
                if (load.get(f.getFieldPath()) == null && f.getFieldPath() != palletField) {
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, f.getLabel() + errorString));
                    load.Customer_Informed__c = false;
                }
            }           
        } else if (rtDeveloperName == rtLate) {
            for(Schema.FieldSetMember f: this.getLateLoadFields()) {
                if (load.get(f.getFieldPath()) == null) {
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, f.getLabel() + errorString));
                    load.Customer_Informed__c = false;
                }
            }
        } else {
            for(Schema.FieldSetMember f: this.getEarlyLoadFields()) {
                if (load.get(f.getFieldPath()) == null) {
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, f.getLabel() + errorString));
                    load.Customer_Informed__c = false;
                }
            }           
        }       
        return null;
    }

    public PageReference linesDownChange(){
        return null;
    }
    
}*/