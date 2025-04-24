trigger ConsumerComplaintsTrigger on Consumer_Complaint__c (after insert, after update) {
    if(Trigger.isAfter && Trigger.isInsert) {
        ConsumerComplaintsHandler.evaluateRecordsInsert(Trigger.new);
    }
    if(Trigger.isAfter && Trigger.isUpdate) {
        ConsumerComplaintsHandler.evaluateRecordsUpdate(Trigger.new, Trigger.oldMap);
    }
}