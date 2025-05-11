/**
* @description       :
* @author            : mmadridp@omegacrmconsulting.com
* @group             :
* @last modified on  : 15-03-2024
* @last modified by  : mmadridp@omegacrmconsulting.com
**/
@isTest
public with sharing class OM_VID_ConstantsTest {
    @isTest 
    public static void testConstants(){
        System.assertEquals(OM_VID_Constants.opportunityStatusQuotation, 'Quotation');
        System.assertEquals(OM_VID_Constants.opportunityRTFifty, 'Fifty_Master_Opportunity');
        System.assertEquals(OM_VID_Constants.quoteRTFifty, 'OM_VID_Quote_Fifty');
        System.assertEquals(OM_VID_Constants.quoteName, 'Quote');
        System.assertEquals(OM_VID_Constants.oppName, 'Opportunity');
        System.assertEquals(OM_VID_Constants.fiftyTemplateName, '_Email_de_Oferta');
        System.assertEquals(OM_VID_Constants.errorContentVersion, 'No existe un documento de Oferta asociado que poder enviar'); 
        
    }
}