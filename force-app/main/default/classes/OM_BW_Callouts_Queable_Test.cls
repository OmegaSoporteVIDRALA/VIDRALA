@isTest
public class OM_BW_Callouts_Queable_Test {
    class MockCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void test_Execute_Queuable() {
        Test.setMock(HttpCalloutMock.class, new MockCallout());

       
        Test.startTest();
        System.enqueueJob(new OM_BW_Callouts_Queable('1000', '2000'));
        System.enqueueJob(new OM_BW_Callouts_Queable('1000', '2000', '1', '2025'));
        Test.stopTest();

       
    }
}