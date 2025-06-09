@isTest
public class OM_BW_Callouts_Scheduler_Test {

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
    static void testSchedulerExecution() {
        Test.setMock(HttpCalloutMock.class, new MockCallout());

        OM_BW_Callouts_Scheduler scheduler = new OM_BW_Callouts_Scheduler('1000', '2000');

        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();
    }
}