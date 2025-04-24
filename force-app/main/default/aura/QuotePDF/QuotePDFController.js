({
    openPDF : function(component, event, helper) {
       let select = component.get("v.template");
       let targetPage = "/apex/" + select + "?Id=" + component.get("v.recordId");
       let urlEvent = $A.get("e.force:navigateToURL");
       urlEvent.setParams({
       "url":targetPage
       });
       urlEvent.fire(); 
    },

    savePDF : function(component, event, helper) {
        let action = component.get("c.attachPDF");
        let select = component.get("v.template");
        let page = select + '.pdf';
        console.log('select='+select);
        let targetPage = "/apex/" + select + "?Id=" + component.get("v.recordId");
        action.setParams({ recordId : component.get("v.recordId"),  pageURL: targetPage, pageName: page});
        
        // Call back method
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                $A.get("e.force:closeQuickAction").fire();
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                                 $A.get("e.force:closeQuickAction").fire();
                    }
                } else {
                    console.log("Unknown error");
                    $A.get("e.force:closeQuickAction").fire();
                }
            }
        });
        $A.enqueueAction(action);
     }
})