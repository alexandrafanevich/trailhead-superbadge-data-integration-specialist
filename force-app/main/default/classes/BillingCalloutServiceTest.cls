@isTest
private class BillingCalloutServiceTest {

    final static String PROJECT_NAME_1 = 'Test Project';
    final static String PROJECT_STATUS_BILLABLE = 'Billable';

    @TestSetup
    static void makeData() {

        Opportunity opp1 = new Opportunity();
        opp1.Name = 'Opp 1';
        opp1.Amount = 1000;
        opp1.Type = 'New Project';
        opp1.CloseDate = Date.today().addDays(21);
        opp1.StageName = 'Closed Won';

        insert opp1;

        ServiceCredentials__c credentials = new ServiceCredentials__c();
        credentials.Name = 'BillingServiceCredential';
        credentials.Username__c = 'username1';
        credentials.Password__c = 'userpass1';

        insert credentials;

        Project__c newProject = new Project__c();
        newProject.Name = PROJECT_NAME_1;
        newProject.ProjectRef__c = 'sdv-24tg4v00-srgs-sb';
        newProject.Start_Date__c = Date.today();
        newProject.End_Date__c = Date.today().addDays(11);
        newProject.Status__c = '';
        newProject.Billable_Amount__c = 11111;
        newProject.Opportunity__c = opp1.Id;

        insert newProject;
    }

    @IsTest
    private static void testPositiveFlow() {

        List<Project__c> projects = [SELECT Id FROM Project__c WHERE Name = :PROJECT_NAME_1 LIMIT 1];
        Assert.isTrue(projects.size() == 1);

        Project__c project = projects.get(0);

        Test.setMock(WebServiceMock.class, new BillingCalloutServiceMock());

        Test.startTest();
        update new Project__c(
            Id = project.Id,
            Status__c = PROJECT_STATUS_BILLABLE
        );
        Test.stopTest();
    }

    @IsTest
    private static void testNegativeFlow() {

        List<Project__c> projects = [SELECT Id FROM Project__c WHERE Name = :PROJECT_NAME_1 LIMIT 1];
        Assert.isTrue(projects.size() == 1);

        Project__c project = projects.get(0);

        Test.setMock(WebServiceMock.class, new BillingCalloutServiceMockFailure());

        Test.startTest();
        update new Project__c(
            Id = project.Id,
            Status__c = 'Running'
        );
        Test.stopTest();
    }
}