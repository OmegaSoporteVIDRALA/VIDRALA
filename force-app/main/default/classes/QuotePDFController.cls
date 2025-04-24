/* -----------------------------------------------------------------------------------------------------------------------
   Name:        QuotePDFController.cls
   Description: Apex controller class for handling PDF operations related to Quote records. 
                Provides functionality to generate and attach PDF documents to Quote records.
   
   Date         Version Author    Summary of Changes
   -----------  ------- --------- ------------------------------------------------------------------------------
   Sep 2024     1.0     Globant   Initial Release
----------------------------------------------------------------------------------------------------------------------- */

public class QuotePDFController {
    /**
     * Generates a PDF from a Visualforce page and attaches it to a Quote record.
     *
     * @param recordId 
     * @param pageURL 
     * @param pageName 
     * @return String - A status message indicating the result of the operation.
     */
    @AuraEnabled
    public static String attachPDF(String recordId, String pageURL, String pageName) {
        if (String.isBlank(recordId) || String.isBlank(pageURL) || String.isBlank(pageName)) {
            return null;
        }
             
        PageReference pageRef = new PageReference(pageURL);
        Blob renderedPDF;

        try {
            if (Test.isRunningTest()) { 
                renderedPDF = Blob.valueOf('Unit.Test');
            } else {
                renderedPDF = pageRef.getContentAsPDF();
            }

            QuoteDocument doc = new QuoteDocument(QuoteId = recordId, Document = renderedPDF);
            insert doc;
            return 'success';
        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
    }
}



// TODO remove once it has been tested/validated/QA-ed
/*public class QuotePDFController {
    
    @AuraEnabled
    public static String attachPDF(String recordId, String pageURL, String pageName)
    {
        PageReference pageRef = new PageReference(pageURL);
        Blob renderedPDF;
        if(Test.isRunningTest()) { 
            renderedPDF = blob.valueOf('Unit.Test');
        } else {
            renderedPDF = new PageReference(pageURL).getContentAsPDF();        	
        }
        
        QuoteDocument doc = new QuoteDocument(QuoteId = recordId, Document = renderedPDF);
        insert doc;
        return 'success';
    }
}*/