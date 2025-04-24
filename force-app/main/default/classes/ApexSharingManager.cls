/* -----------------------------------------------------------------------------------------------------------------------
   Name:        ApexSharingManager.cls
   Description: Manage Apex sharing of objects with users
                    
   Date         Version Author              Summary of Changes 
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Nov 2017     1.0     M.Witchalls(Ciber)  Initial Release 
   Sep 2024     2.0     Globant             Code Refactoring
------------------------------------------------------------------------------------------------------------------------ */     
public class ApexSharingManager {

    private static final String defaultSharingReason = 'Manual';
    private static final String defaultAccessLevel = 'Edit';
    
    private Schema.SObjectType shareSObjectType;
    private Boolean hasShares = false;
    private String parentIdFieldName = 'ParentId';
    private String accessLevelFieldName = 'AccessLevel';
    
    private String objectName;
    private String shareName;
    private String sharingReason;
    private String accessLevel;
    
    /**
     * Constructor that initializes the ApexSharingManager with an object name.
     *
     * @param objectName The API name of the object to manage sharing for. Must not be null or empty.
     */
    public ApexSharingManager(String objectName) {
        this(objectName, defaultSharingReason, defaultAccessLevel);
    }
    
    /**
     * Constructor that initializes the ApexSharingManager with an object name and sharing reason.
     *
     * @param objectName The API name of the object to manage sharing for. Must not be null or empty.
     * @param sharingReason The reason for sharing. Must not be null or empty.
     */
    public ApexSharingManager(String objectName, String sharingReason) {
        this(objectName, sharingReason, defaultAccessLevel);
    }
    
    /**
     * Constructor that initializes the ApexSharingManager with object name, sharing reason, and access level.
     *
     * @param objectName The API name of the object to manage sharing for. Must not be null or empty.
     * @param sharingReason The reason for sharing. Must not be null or empty.
     * @param accessLevel The access level for sharing. Must not be null or empty.
     */
    public ApexSharingManager(String objectName, String sharingReason, String accessLevel) {
        if (String.isBlank(objectName)) {
            throw new IllegalArgumentException('Object name must not be null or empty.');
        }
        if (String.isBlank(sharingReason)) {
            throw new IllegalArgumentException('Sharing reason must not be null or empty.');
        }
        if (String.isBlank(accessLevel)) {
            throw new IllegalArgumentException('Access level must not be null or empty.');
        }

        this.objectName = objectName;
        this.shareName = (objectName.endsWith('__c')) ? objectName.replace('__c','__Share') : objectName + 'Share';
        this.sharingReason = sharingReason;
        this.accessLevel = accessLevel;
        
        this.shareSObjectType = Schema.getGlobalDescribe().get(shareName);
        this.hasShares = (shareSObjectType != null);
        
        if (!this.hasShares) {
            return;
        }

        if (shareName == Schema.SObjectType.ContactShare.Name) {
            parentIdFieldName = Schema.SObjectType.ContactShare.Fields.ContactId.Name;
            accessLevelFieldName = Schema.SObjectType.ContactShare.Fields.ContactAccessLevel.Name;
        } else if (shareName == Schema.SObjectType.OpportunityShare.Name) {
            parentIdFieldName = Schema.SObjectType.OpportunityShare.Fields.OpportunityId.Name;
            accessLevelFieldName = Schema.SObjectType.OpportunityShare.Fields.OpportunityAccessLevel.Name;
        } else if (shareName == Schema.SObjectType.CaseShare.Name) {
            parentIdFieldName = Schema.SObjectType.CaseShare.Fields.CaseId.Name;
            accessLevelFieldName = Schema.SObjectType.CaseShare.Fields.CaseAccessLevel.Name;
        }
    }

    /**
     * Updates sharing for accounts based on new account ownership.
     *
     * @param accountRelationship The relationship field from the object to the account. Must not be null or empty.
     * @param accountList List of Account records. Must not be null or empty.
     * @param oldMap Map of old Account records for comparison. Must not be null.
     */
    public void newAccountOwner(String accountRelationship, List<Account> accountList, Map<ID,Account> oldMap) {
        if (String.isBlank(accountRelationship)) {
            throw new IllegalArgumentException('Account relationship must not be null or empty.');
        }
        if (accountList == null || accountList.isEmpty()) {
            throw new IllegalArgumentException('Account list must not be null or empty.');
        }
        if (oldMap == null) {
            throw new IllegalArgumentException('Old account map must not be null.');
        }

        if (!this.hasShares) {
            return;
        }

        Set<ID> accountIdSet = new Set<ID>();
        Map<ID,ID> objectIdUserIdMap = new Map<ID,ID>();

        for (Account a: accountList) {
            Account oldA = oldMap.get(a.Id);
            if (a.OwnerId != oldA.ownerId || a.Recalculate_Apex_Sharing__c) {
                accountIdSet.add(a.Id);
            }
        }

        if (accountIdSet.isEmpty()) {
            return;  
        }

        String queryString = 
             'SELECT Id, OwnerId, '+ accountRelationship+'.OwnerId'+
             ' FROM '+ this.objectName +
             ' WHERE '+ accountRelationship+'.Id IN :accountIdSet';
        
        List <sObject> objectMapList = Database.query(queryString);
        List <sObject> objectToShareList = new List<sObject>();

        for (sObject o: objectMapList) {
            Account a = (Account) o.getSObject(accountRelationship);
            String ownerId = String.valueOf(o.get('OwnerId'));
            if (a.OwnerId != ownerId) {
                objectToShareList.add(o);
                objectIdUserIdMap.put(o.Id, a.OwnerId);
            }
        }

        if (!objectToShareList.isEmpty()) {
            deleteSharing(objectToShareList);
            createSharing(objectIdUserIdMap);
        }
    }

    /**
     * Shares records with account owners based on account relationship.
     *
     * @param accountRelationship The relationship field from the object to the account. Must not be null or empty.
     * @param objectList List of SObject records to share. Must not be null or empty.
     */
    public void shareWithAccountOwner(String accountRelationship, List<sObject> objectList) {
        if (String.isBlank(accountRelationship)) {
            throw new IllegalArgumentException('Account relationship must not be null or empty.');
        }
        if (objectList == null || objectList.isEmpty()) {
            throw new IllegalArgumentException('Object list must not be null or empty.');
        }

        if (!this.hasShares) {
            return;
        }

        Set<ID> objectIdSet = new Set<ID>();
        Map<ID,ID> objectIdUserIdMap = new Map<ID,ID>();

        for (sObject o: objectList) objectIdSet.add(o.Id);

        String queryString = 
             'SELECT Id, '+ accountRelationship+'.OwnerId'+
             ' FROM '+ this.objectName +
             ' WHERE Id IN :objectIdSet';

        List<sObject> objectMapList = Database.query(queryString);
        for (sObject o: objectMapList) {
            Account a = (Account) o.getSObject(accountRelationship);
            objectIdUserIdMap.put(o.Id, a.OwnerId);
        }
        createSharing(objectIdUserIdMap);
    }

    /**
     * Creates sharing records for a map of object IDs and user IDs.
     *
     * @param objectIdUserIdMap Map of object IDs and corresponding user IDs to share with. Must not be null or empty.
     */
    public void createSharing(Map<ID,ID> objectIdUserIdMap) {
        if (objectIdUserIdMap == null || objectIdUserIdMap.isEmpty()) {
            throw new IllegalArgumentException('Object ID and User ID map must not be null or empty.');
        }

        if (!this.hasShares) {
            return;
        }

        List<sObject> objectShareList = new List<sObject>();
        for (ID objectId: objectIdUserIdMap.keySet()) {
            ID userId = objectIdUserIdMap.get(objectId);
            objectShareList.add(newObjectShare(objectId, userId));
        }
        if (!objectShareList.isEmpty()) {
            insert objectShareList;
        }
    }

    /**
     * Creates a new sharing SObject record for the given object and user.
     *
     * @param objectId The ID of the object to share. Must not be null.
     * @param userId The ID of the user to share the object with. Must not be null.
     * @return The SObject share record.
     */
    public sObject newObjectShare(ID objectId, ID userId) {
        if (objectId == null) {
            throw new IllegalArgumentException('Object ID must not be null.');
        }
        if (userId == null) {
            throw new IllegalArgumentException('User ID must not be null.');
        }

        SObject newShare = shareSObjectType.newSObject(); 
        newShare.put(parentIdFieldName, objectId);
        newShare.put('UserOrGroupId', userId);
        newShare.put('RowCause', this.sharingReason);
        newShare.put(accessLevelFieldName, this.accessLevel);
        return newShare;
    }

    /**
     * Deletes sharing records for a list of objects.
     *
     * @param objectList The list of SObject records whose sharing to delete. Must not be null or empty.
     */
    public void deleteSharing(List<sObject> objectList) {
        if (objectList == null || objectList.isEmpty()) {
            throw new IllegalArgumentException('Object list must not be null or empty.');
        }

        if (!this.hasShares) {
            return;
        }

        Set<ID> objectIdSet = new Set<ID>();
        for (sObject o: objectList) objectIdSet.add(o.Id);

        String deleteSOQL = 
            'SELECT Id FROM '+shareName+' WHERE RowCause = \''+sharingReason+'\''+
            ' AND '+parentIdFieldName+' IN :objectIdSet';

        List<sObject> objectShareList = Database.query(deleteSOQL);
        if (!objectShareList.isEmpty()) {
            delete objectShareList;
        }
    }
}



/*public class ApexSharingManager {
    private static final String defaultSharingReason = 'Manual';
    private static final String defaultAccessLevel = 'Edit';
    
    private Schema.SObjectType shareSObjectType;
    private Boolean hasShares = false;
    private String parentIdFieldName = 'ParentId';
    private String accessLevelFieldName = 'AccessLevel';
    
    private String objectName;
    private String shareName;
    private String sharingReason;
    private String accessLevel;
    
    public ApexSharingManager(String objectName) {
        this(objectName, defaultSharingReason, defaultAccessLevel);
    }
    
    public ApexSharingManager(String objectName, String sharingReason) {
        this(objectName, sharingReason, defaultAccessLevel);
    }
    
    public ApexSharingManager(String objectName, String sharingReason, String accessLevel) {
        this.objectName = objectName;
        this.shareName = (objectName.endsWith('__c')) ? objectName.replace('__c','__Share') : objectName +'Share';
        this.sharingReason = sharingReason;
        this.accessLevel = accessLevel;
        
        this.shareSObjectType = Schema.getGlobalDescribe().get(shareName);
        this.hasShares = (shareSObjectType != null);
        if (shareName == Schema.SObjectType.ContactShare.Name) {
            parentIdFieldName = Schema.SObjectType.ContactShare.Fields.ContactId.Name;
            accessLevelFieldName = Schema.SObjectType.ContactShare.Fields.ContactAccessLevel.Name;
        } else if (shareName == Schema.SObjectType.OpportunityShare.Name) {
            parentIdFieldName = Schema.SObjectType.OpportunityShare.Fields.OpportunityId.Name;
            accessLevelFieldName = Schema.SObjectType.OpportunityShare.Fields.OpportunityAccessLevel.Name;
        } else if (shareName == Schema.SObjectType.CaseShare.Name) {
            parentIdFieldName = Schema.SObjectType.CaseShare.Fields.CaseId.Name;
            accessLevelFieldName = Schema.SObjectType.CaseShare.Fields.CaseAccessLevel.Name;
        }
        system.debug('Object Share Name: '+ shareName);
        system.debug('Object has shares? '+ hasShares);
    }
    
    public void newAccountOwner(String accountRelationship, List<Account> accountList, Map<ID,Account> oldMap) {
        Set<ID> accountIdSet = new Set<ID>();
        Set<ID> objectIdSet = new Set<ID>();
        Map<ID,ID> objectIdUserIdMap = new Map<ID,ID>();
        
        if (this.hasShares) {
            for (Account a: accountList) {
                Account oldA = oldMap.get(a.Id);
                if (a.OwnerId != oldA.ownerId || a.Recalculate_Apex_Sharing__c) {
                    accountIdSet.add(a.Id);
                }
            }       
            String queryString = 
                 'SELECT Id, OwnerId, '+ accountRelationship+'.OwnerId'+
                 ' FROM '+ this.objectName +
                 ' WHERE '+ accountRelationship+'.Id IN :accountIdSet';
            system.debug('queryString: '+queryString);
            
            List <sObject> objectMapList = Database.query(queryString);
            List <sObject> objectToShareList = new List<sObject>();
            if (objectMapList.size() > 0) {
                for (sObject o: objectMapList) {
                    Account a = (Account) o.getSObject(accountRelationship);
                    String ownerId = String.valueOf(o.get('OwnerId'));
                    system.debug('Account Owner: '+a.OwnerId);
                    if (a.OwnerId != ownerId) {
                        objectToShareList.add(o);
                        objectIdUserIdMap.put(o.Id, a.OwnerId);
                    }
                }
                
                if (objectToShareList.size() > 0) {
                    deleteSharing(objectToShareList);
                    createSharing(objectIdUserIdMap);
                }
            }
        }
    }
    
    public void shareWithAccountOwner(String accountRelationship, List<sObject> objectList) {
        Set<ID> objectIdSet = new Set<ID>();
        Map<ID,ID> objectIdUserIdMap = new Map<ID,ID>();
        
        if (this.hasShares) {
            for (sObject o: objectList) objectIdSet.add(o.Id);
            String queryString = 
                 'SELECT Id, '+ accountRelationship+'.OwnerId'+
                 ' FROM '+ this.objectName +
                 ' WHERE Id IN :objectIdSet';
            system.debug('queryString: '+queryString);
                 
            List<sObject> objectMapList = Database.query(queryString);
            for (sObject o: objectMapList) {
                Account a = (Account) o.getSObject(accountRelationship);
                system.debug('Account Owner: '+a.OwnerId);
                objectIdUserIdMap.put(o.Id, a.OwnerId);
            }
            createSharing(objectIdUserIdMap);
        }
    }
    
    public void createSharing(Map<ID,ID> objectIdUserIdMap) {
        if (this.hasShares) {
            List<sObject> objectShareList = new List<sObject>();
            for (ID objectId: objectIdUserIdMap.keySet()) {
                ID userId = objectIdUserIdMap.get(objectId);
                objectShareList.add(newObjectShare(objectId, userId));
            }
            if (objectShareList.size() > 0) insert objectShareList;
        }
    }
    
    public sObject newObjectShare(ID objectId, ID userId) {
        SObject newShare = shareSObjectType.newSObject(); 
        newShare.put(parentIdFieldName, objectId);
        newShare.put('UserOrGroupId', userId);
        newShare.put('RowCause', this.sharingReason);
        newShare.put(accessLevelFieldName, this.accessLevel);
        return newShare;
    }
    
    
    public void deleteSharing(List<sObject> objectList) {
        if (this.hasShares) {
            Set<ID> objectIdSet = new Set<ID>();
            for (sObject o: objectList) objectIdSet.add(o.Id);
            
            String deleteSOQL = 
                'SELECT Id FROM '+shareName+' WHERE RowCause = \''+sharingReason+'\''+
                ' AND '+parentIdFieldName+' IN :objectIdSet';
            system.debug('Deletion SOQL: '+deleteSOQL);
            
            List<sObject> objectShareList = Database.query(deleteSOQL);
            if (objectShareList.size() > 0) delete objectShareList;
        }
    }
    
}*/