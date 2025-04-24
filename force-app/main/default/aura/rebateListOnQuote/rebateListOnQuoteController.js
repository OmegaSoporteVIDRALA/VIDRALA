({
    doInit : function(component, event, helper) {
        var quoteRecordId = component.get('v.recordId');
        var action = component.get("c.searchRebate");
        action.setParams({ "quoteRecordId" : quoteRecordId });
		action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
				component.set("v.rebates",response.getReturnValue());
                var rebateCount = response.getReturnValue().length;
                component.set("v.rebateCount",rebateCount);
            }
            else {
            	console.log(state);
                component.set("v.rebateCount",0);
            }
          });
          $A.enqueueAction(action);
    }
  /*  navigateToRecord : function(component, event, helper) {
        var idx = event.target.getAttribute('data-index');
        var rebate = component.get("v.rebates")[idx];
        var navEvent = $A.get("e.force:navigateToSObject");
        if(navEvent){
            navEvent.setParams({
                  recordId: rebate.Id,
                  slideDevName: "detail"
            });
            navEvent.fire(); 
        }
        else{
            window.location.href = '/one/one.app#/sObject/'+rebate.Id+'/view'
        }
    } */
        
})