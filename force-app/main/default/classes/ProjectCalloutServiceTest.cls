@IsTest
private class ProjectCalloutServiceTest {
    
    @TestSetup
    static void makeData() {
        Opportunity opp1 = new Opportunity();
        opp1.Name = 'Opp 1';
        opp1.Amount = 1000;
        opp1.Type = 'New Project';
        opp1.CloseDate = Date.today();
        opp1.StageName = 'Closed Won';

        insert opp1;

        ServiceTokens__c token = new ServiceTokens__c();
        token.Name = 'ProjectServiceToken';
        token.Token__c = '--token--';

        insert token;
    }

    @IsTest
    private static void testPositiveFlow() {

        Opportunity opp1 = [SELECT Id FROM Opportunity LIMIT 1];

        ProjectCalloutService.FlowInput input = new ProjectCalloutService.FlowInput(opp1.Id);

        Test.setMock(HttpCalloutMock.class, new ProjectCalloutServiceMock());

        Test.startTest();
        List<ProjectCalloutService.FlowOutput> result = ProjectCalloutService.postOpportunityToPMS(new List<ProjectCalloutService.FlowInput>{input});
        Test.stopTest();
    }

    @IsTest
    private static void testNegativeFlow() {

        Opportunity opp1 = [SELECT Id FROM Opportunity LIMIT 1];

        ProjectCalloutService.FlowInput input = new ProjectCalloutService.FlowInput(opp1.Id);

        Test.setMock(HttpCalloutMock.class, new ProjectCalloutServiceMockFailure());

        Test.startTest();
        List<ProjectCalloutService.FlowOutput> result = ProjectCalloutService.postOpportunityToPMS(new List<ProjectCalloutService.FlowInput>{input});
        Test.stopTest();
    }
}