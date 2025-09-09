/**
* @File Name : OM_CustomNewOverrideController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : September 5, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | September 5, 2025 |   | Initial Version
**/

public class OM_CustomNewOverrideController {
	@AuraEnabled(cacheable=true)
    public static Account getAccountWithParent(Id accountId) {
        return [
            SELECT Id, RecordType.DeveloperName,
                   ParentId, Parent.Name, Parent.RecordType.DeveloperName
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];
    }
}