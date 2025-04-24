trigger CheckDupProductCode on Product2 (before insert,before update) {

    UniqueProductCodeIdentifier.checkDupProductCode(trigger.new, trigger.oldMap);
}