@isTest
private class ProjectRESTServiceTest {

    @TestSetup
    static void makeData() {

        Opportunity opp1 = new Opportunity();
        opp1.Name = 'Opp 1';
        opp1.Amount = 1000;
        opp1.Type = 'New Project';
        opp1.CloseDate = Date.today().addDays(21);
        opp1.StageName = 'Closed Won';

        insert opp1;

        // ServiceTokens__c token = new ServiceTokens__c();
        // token.Name = 'ProjectServiceToken';
        // token.Token__c = '--token--';

        // insert token;

        Project__c newProject = new Project__c();
        newProject.Name = 'Test Project';
        newProject.ProjectRef__c = 'sdv-24tg4v00-srgs-sb';
        newProject.Start_Date__c = Date.today();
        newProject.End_Date__c = Date.today().addDays(11);
        newProject.Status__c = 'Running';
        newProject.Billable_Amount__c = 11111;
        newProject.Opportunity__c = opp1.Id;

        insert newProject;
    }

    @IsTest
    private static void testPositiveFlow() {

        Opportunity opp1 = [SELECT Id FROM Opportunity LIMIT 1];

        // Set up a test request
        RestRequest request = new RestRequest();
        // Set request properties
        request.requestUri = System.URL.getSalesforceBaseURL().toExternalForm() + '/services/apexrest/project/';
        request.httpMethod = 'POST';
        // Set other properties, such as parameters
        // ProjectRef, String ProjectName, String OpportunityId, Date StartDate, Date EndDate, Double Amount, String Amount
        // request.params.put('ProjectRef', 'sdvhw-vwev-wevwev');
        // request.params.put('ProjectName', 'Test Name 2');
        // request.params.put('OpportunityId', opp1.Id);
        // request.params.put('StartDate', Date.today().addDays(1));
        // request.params.put('EndDate', Date.today().addDays(41));
        // request.params.put('Amount', 111);
        // request.params.put('Amount', 'Running');
        // more awesome code here....
        // Finally, assign the request to RestContext if used
        RestContext.request = request;

        Test.startTest();
        ProjectRESTService.postProjectData('sdvhw-vwev-wevwev', 'Test Name 2', opp1.Id, Date.today().addDays(1), Date.today().addDays(41), 111, 'Running');
        Test.stopTest();
    }

    @IsTest
    private static void testNegativeFlow() {

        Opportunity opp1 = [SELECT Id FROM Opportunity LIMIT 1];

        // Set up a test request
        RestRequest request = new RestRequest();
        // Set request properties
        request.requestUri = System.URL.getSalesforceBaseURL().toExternalForm() + '/services/apexrest/project/';
        request.httpMethod = 'POST';
        RestContext.request = request;

        Test.startTest();
        ProjectRESTService.postProjectData('sdvhw-vwev-wevwev', 'Test Name 2', opp1.Id, Date.today().addDays(1), Date.today().addDays(41), 111, 'test');
        Test.stopTest();
    }
}