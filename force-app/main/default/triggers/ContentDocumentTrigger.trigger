trigger ContentDocumentTrigger on ContentDocument (before delete) {

    if ( Trigger.isBefore && Trigger.isDelete ) {

        // original
        new ContentDocumentTriggerHandler().recountFilesOnParentRecords(trigger.old);

    }
    
}