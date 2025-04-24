({
	doInit: function(cmp, event, helper) {
        var action = cmp.get("c.getRelatedInfo");
        var params = {
            recordId: cmp.get("v.recordId"),
            lookupAPI: cmp.get("v.lookupAPI"),
            relatedObjectAPI: cmp.get("v.relatedObjectAPI"),
            fieldAPIs: cmp.get("v.fieldAPIs"),
            whereCondition: cmp.get("v.whereCondition"),
            additionalRequest: cmp.get("v.additionalRequest"),
            additionalAPI: cmp.get("v.additionalAPI")
        };
        action.setParams({ params: JSON.stringify(params) });
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('state '+ state);
            if(state === "SUCCESS"){
                var objData = response.getReturnValue();
                console.log(JSON.stringify(objData, undefined, 2));
                if(objData != null && objData.values != null && objData.values.length > 0){
                    console.log("init data");
                    cmp.set("v.objectName", objData.objectName);
                    cmp.set("v.objectValues", objData.values);
                    cmp.set("v.objectLabels", objData.labels);
                    cmp.set("v.objectCount", objData.values.length);
                    cmp.set("v.hasRecords", true);
                } else {
                    console.log("no data");
                    cmp.set("v.hasRecords", false);
                }
            } else if(state === "ERROR"){
                var errors = response.getError();
                console.log('ERROR', errors);
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                        let toastParams = {
                            title: "Error",
                            message: "Error",
                            type: "error"
                        };
                        if (errors && Array.isArray(errors) && errors.length > 0) {
                            toastParams.message = errors[0].message;
                        }
                        let toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams(toastParams);
                        toastEvent.fire();
                    }
                }
            }
        });
        $A.enqueueAction(action);
   },
   
    navigateToRecord: function(cmp, event, helper) {
        var recordId = event.target.dataset.recid;
        var navEvent = $A.get("e.force:navigateToSObject");
        if(navEvent){
            navEvent.setParams({
                recordId: recordId,
                slideDevName: "detail"
            });
            navEvent.fire();   
        }
    },
})