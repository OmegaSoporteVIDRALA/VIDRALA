trigger OM_VID_CaseTRG on Case (before insert, after insert, before update, after update, before delete) {
    if(!OM_Utils.shouldSkipTriggerGlobal){
    	OM_VID_CaseTRGHandler.execute(trigger.new, trigger.oldMap, trigger.isBefore, trigger.isAfter, trigger.isInsert, trigger.isUpdate, trigger.isDelete);
    }
}