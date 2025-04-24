public with sharing class ConsumerComplaintsHandler {

    public static void evaluateRecordsInsert(List<Consumer_Complaint__c> ccs) {
        Map<String, List<Consumer_Complaint__c>> applicable = new Map<String, List<Consumer_Complaint__c>>();
        applicable.put('QD_AM', new List<Consumer_Complaint__c>());
        applicable.put('QM_Unk', new List<Consumer_Complaint__c>());
        applicable.put('QM_Elt', new List<Consumer_Complaint__c>());
        applicable.put('QM_Der', new List<Consumer_Complaint__c>());
        applicable.put('QM_Cor', new List<Consumer_Complaint__c>());

        for(Consumer_Complaint__c cc : ccs) {
            if(cc.Complaint_Type_Confirmed_Date__c != null && (cc.Manufacturing_Fault_Present__c == 'Yes' || cc.Legal__c == 'Yes' || cc.Injury__c == 'Yes')) {
                
                applicable.get('QD_AM').add(cc);

                switch on cc.Plant__c {
                    when 'Unknown' {
                        applicable.get('QM_Unk').add(cc);
                    }
                    when 'Elton' {
                        applicable.get('QM_Elt').add(cc);
                    }
                    when 'Derrylin' {
                        applicable.get('QM_Der').add(cc);
                    }
                    when 'Corsico' {
                        applicable.get('QM_Cor').add(cc);
                    }
                }
            }
        }
        if(applicable.get('QD_AM').size() > 0) {
            System.enqueueJob(new ConsumerComplaintsEmailQueue(applicable));
        }
    }

    public static void evaluateRecordsUpdate(List<Consumer_Complaint__c> ccs, Map<Id,Consumer_Complaint__c> oldCcs) {
        Map<String, List<Consumer_Complaint__c>> applicable = new Map<String, List<Consumer_Complaint__c>>();
        applicable.put('QD_AM', new List<Consumer_Complaint__c>());
        applicable.put('QM_Unk', new List<Consumer_Complaint__c>());
        applicable.put('QM_Elt', new List<Consumer_Complaint__c>());
        applicable.put('QM_Der', new List<Consumer_Complaint__c>());
        applicable.put('QM_Cor', new List<Consumer_Complaint__c>());

        for(Consumer_Complaint__c cc : ccs) {
            if(cc.Complaint_Type_Confirmed_Date__c != null 
                && oldCcs.get(cc.Id).Complaint_Type_Confirmed_Date__c != cc.Complaint_Type_Confirmed_Date__c 
                && cc.Complaint_Type_Confirmed_Date__c > System.now().addDays(-2) //remove this line for deploy
                && (cc.Manufacturing_Fault_Present__c == 'Yes' || cc.Legal__c == 'Yes' || cc.Injury__c == 'Yes')) {
                
                applicable.get('QD_AM').add(cc);

                switch on cc.Plant__c {
                    when 'Unknown' {
                        applicable.get('QM_Unk').add(cc);
                    }
                    when 'Elton' {
                        applicable.get('QM_Elt').add(cc);
                    }
                    when 'Derrylin' {
                        applicable.get('QM_Der').add(cc);
                    }
                    when 'Corsico' {
                        applicable.get('QM_Cor').add(cc);
                    }
                }
            }
        }
        if(applicable.get('QD_AM').size() > 0) {
            System.enqueueJob(new ConsumerComplaintsEmailQueue(applicable));
        }
    }
}