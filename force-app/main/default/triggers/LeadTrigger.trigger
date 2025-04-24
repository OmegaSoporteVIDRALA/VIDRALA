/**
* @author Jamie Kennedy <jamie.kennedy@cloudshiftgroup.com>
* @date 2021-10-01
* @group CloudShiftGroup
*
* Date              Author              Change Description
* -----------------------------------------------------------------------------------
* 2021-11-01        Jamie Kennedy      	Created Class
**/
trigger LeadTrigger on Lead (after insert) {
	if (trigger.isAfter) {
        LeadHandler handler = new LeadHandler();
        handler.processWebProducts(Trigger.new);
    }
}