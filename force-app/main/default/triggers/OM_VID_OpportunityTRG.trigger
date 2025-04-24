trigger OM_VID_OpportunityTRG on Opportunity (before insert, after insert, before update, after update, before delete) {
    OM_VID_OpportunityTRGHandler.execute(trigger.new, trigger.oldMap, trigger.isBefore, trigger.isAfter, trigger.isInsert, trigger.isUpdate, trigger.isDelete);
}