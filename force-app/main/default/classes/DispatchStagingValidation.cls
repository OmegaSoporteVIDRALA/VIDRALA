/* -----------------------------------------------------------------------------------------------------------------------
   Name:        DispatchStagingValidation.cls
   Description: Class to convert invalid time format to valid time format
				and to concats two fields and map to a Salesforce_Unique_id__c, maps Customer_Code__c to Encirc_Account__c Dispatch_Staging__c fields

   Date         Version Author              Summary of Changes
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Aug 2025		1.0		Globant				Initial Release
------------------------------------------------------------------------------------------------------------------------ */

public class DispatchStagingValidation {

    public static void cleanTimeFields(List<Dispatch_Staging__c> stagingRecords) {
        for (Dispatch_Staging__c dl : stagingRecords) {
            dl.Dispatch_Time__c = normalizeTime(dl.Dispatch_Time__c);
            dl.Planned_Delivery_Time__c = normalizeTime(dl.Planned_Delivery_Time__c);
            dl.Planned_Check_In_Time__c = normalizeTime(dl.Planned_Check_In_Time__c);
            dl.Planned_Loading_Start_Time__c = normalizeTime(dl.Planned_Loading_Start_Time__c);
            dl.Planned_Loading_End_Time__c = normalizeTime(dl.Planned_Loading_End_Time__c);
            dl.Planned_Transport_Start_Time__c = normalizeTime(dl.Planned_Transport_Start_Time__c);
            dl.Planned_Transport_End_Time__c = normalizeTime(dl.Planned_Transport_End_Time__c);
            dl.Planned_Time_for_Processing__c = normalizeTime(dl.Planned_Time_for_Processing__c);
            dl.Time_of_Transportation_Processing__c = normalizeTime(dl.Time_of_Transportation_Processing__c);
            dl.Actual_Loading_Start_Time__c = normalizeTime(dl.Actual_Loading_Start_Time__c);
            dl.Actual_Loading_End_Time__c = normalizeTime(dl.Actual_Loading_End_Time__c);
            dl.Actual_Shipment_End_Time__c = normalizeTime(dl.Actual_Shipment_End_Time__c);
            dl.Actual_Transport_Start_Time__c = normalizeTime(dl.Actual_Transport_Start_Time__c);
            dl.Current_Time_of_Check_In__c = normalizeTime(dl.Current_Time_of_Check_In__c);
            dl.Entry_Time__c = normalizeTime(dl.Entry_Time__c);
        }
    }

    private static String normalizeTime(String rawTime) {
        if (String.isBlank(rawTime)) return null;
        try {
            List<String> parts = rawTime.trim().split(':');
            if (parts.size() < 2) return null;

            String hour   = parts[0].leftPad(2, '0');
            String minute = parts[1].leftPad(2, '0');
            String second = parts.size() > 2 ? parts[2].leftPad(2, '0') : '00';

            Integer.valueOf(hour);
            Integer.valueOf(minute);
            Integer.valueOf(second);

            return hour + ':' + minute + ':' + second;
        } catch (Exception e) {
    		System.debug('Bad time format: ' + rawTime);
            return null;
        }
    }
    
 public static void populateDerivedFields(List<Dispatch_Staging__c> newRecords) {
        for (Dispatch_Staging__c rec : newRecords) {
            String materialDoc = String.isNotBlank(rec.Number_of_Material_Document__c) ? rec.Number_of_Material_Document__c.trim() : '';
            String sapCode = String.isNotBlank(rec.SAP_Material_Code__c) ? rec.SAP_Material_Code__c.trim() : '';

            if (String.isNotBlank(materialDoc) && String.isNotBlank(sapCode)) {
                rec.Salesforce_Unique_Id__c = materialDoc + '-' + sapCode;
            }

            if (String.isNotBlank(rec.Customer_Code__c)) {
                rec.Encirc_Account_Number__c = rec.Customer_Code__c;
            }

            System.debug('Generated Salesforce Unique ID: ' + rec.Salesforce_Unique_Id__c);
        }
    }
}