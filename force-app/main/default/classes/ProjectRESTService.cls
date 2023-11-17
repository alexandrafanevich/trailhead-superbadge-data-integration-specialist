@RestResource(urlMapping='/project')
global class ProjectRESTService {

    final static String DEBUG_HEADER = 'ProjectRESTService.';

    final static String OPPORTUNITY_DELIVERY_INSTALLATION_STATUS = 'In progress';
    final static String RESULT_SUCCESS = 'OK';
    
    @HttpPost
    // global static String postProjectData(PmsProject project) {
    global static String postProjectData(String ProjectRef, String ProjectName, String OpportunityId, Date StartDate, Date EndDate, Double Amount, String Status) {

        final String DEBUG_HERE = DEBUG_HEADER + 'postProjectData() - ';

        System.debug(logginglevel.INFO, DEBUG_HERE + 'Incomming data: Project: ' + ProjectName + ' ' + ProjectRef + ', oppId: ' + OpportunityId);

        Project__c newProject = new Project__c();
        newProject.Name = ProjectName;
        newProject.ProjectRef__c = ProjectRef;
        newProject.Start_Date__c = StartDate;
        newProject.End_Date__c = EndDate;
        newProject.Status__c = Status;
        newProject.Billable_Amount__c = Amount;
        newProject.Opportunity__c = OpportunityId;

        String result = RESULT_SUCCESS;
        Savepoint savepoint = Database.setSavepoint();

        System.debug(logginglevel.INFO, DEBUG_HERE + 'Project data to be upserted: ' + newProject);

        try {
            upsert newProject ProjectRef__c;
            update new Opportunity(
                Id = OpportunityId,
                DeliveryInstallationStatus__c = OPPORTUNITY_DELIVERY_INSTALLATION_STATUS
            );
        } catch (DMLException de) {
            result = de.getMessage();
            Database.rollback(savepoint);
        }

        return result;

        // sendResponse(result);
    }

    // private static void sendResponse() {

    //     RestResponse res = RestContext.response;
    //     res.responseBody
    // }

}