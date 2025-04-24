trigger ContentDocumentLinkTrigger on ContentDocumentLink (after insert) {

    if(Trigger.isAfter && Trigger.isInsert) {

        new ContentDocumentLinkTriggerHandler().recountFilesOnParentRecords(trigger.new);

    }

}