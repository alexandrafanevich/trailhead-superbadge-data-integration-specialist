public with sharing class ProjectCalloutService {
    
    final static String DEBUG_HEADER = 'ProjectCalloutService.';

    final static String REGISTRATION_TOKEN = '9715908c-a390-4e17-aecd-3b125e520fce';

    final static String OPPORTUNITY_STAGE_SUBMITTED_PROJECT = 'Submitted Project';
    final static String OPPORTUNITY_STAGE_RESUBMIT_PROJECT = 'Resubmit Project';
    final static String OPPORTUNITY_TYPE_NEW_PROJECT = 'New Project';
    final static String RESONSE_RESULT_SUCCESS = 'Success';
    final static String RESONSE_RESULT_FAILURE = 'Failure';

    final static String SERVICE_TOKEN = ServiceTokens__c.getValues('ProjectServiceToken').Token__c;

    /**
     * @param flowInputs Flow Input list
     *
     * @return Fow Output list
     */
    @InvocableMethod(
        Label='Post Opportunity to PMS'
        Description='Post Opportunity to PMS'
    )
    public static List<FlowOutput> postOpportunityToPMS(List<FlowInput> flowInputs) {

        final String DEBUG_HERE = DEBUG_HEADER + 'postOpportunityToPMS() - ';

        FlowInput request = flowInputs.get(0);

        System.debug(DEBUG_HERE + 'Input: ' + request);

        Boolean isSuccessful = postOpportunityToPMS(request.opportunityId);

        return new List<FlowOutput>{
            new FlowOutput(isSuccessful)
        };
    }

    public static Boolean postOpportunityToPMS(String opportunityId) {

        Opportunity opportunity = getOpportunity(opportunityId);

        Boolean result = true;

        try {
            sendOpportunity(opportunity);
        } catch (Exception e) {
            System.debug(logginglevel.WARN, 'Error occur during sending: ' + e.getMessage());
            result = false;
        }
        

        return result;

    }

    private static Opportunity getOpportunity(String recordId) {

        final String DEBUG_HERE = 'getOpportunity() - ';
        
        List<Opportunity> opportunities = [
            SELECT Id, Name, Account.Name, Amount, CloseDate
            FROM Opportunity
            WHERE Id = :recordId
                AND StageName != :OPPORTUNITY_STAGE_SUBMITTED_PROJECT
                AND Type = :OPPORTUNITY_TYPE_NEW_PROJECT
            LIMIT 1
        ];

        if (opportunities.isEmpty()) {
            throw new ProjectCalloutServiceException('Opportunity has not been found');
        }

        Opportunity opportunity = opportunities.get(0);
        System.debug(logginglevel.INFO, DEBUG_HERE + 'Found record: ' + opportunity);

        return opportunity;
    }

    private static void sendOpportunity(Opportunity record) {
        System.enqueueJob(new QueueablePMSCall(record));
    }

    public class QueueablePMSCall implements Queueable, Database.AllowsCallouts {

        private String DEBUG_HERE = 'QueueablePMSCall.';

        public Opportunity record;

        public QueueablePMSCall() {}

        public QueueablePMSCall(Opportunity opportunity) {
            this.record = opportunity;
        }

        public void execute(QueueableContext context) {

            DEBUG_HERE += 'execute() - ';

            System.debug(logginglevel.INFO, DEBUG_HERE + '^^@^^ this.record ==> ' + this.record);

            String endpoint = 'callout:ProjectService';
            String method = 'POST';
            ProjectCalloutService.PmsRequest requestData = new ProjectCalloutService.PmsRequest();
            requestData.opportunityId = this.record.Id;
            requestData.opportunityName = this.record.Name;
            requestData.accountName = this.record.Account.Name;
            requestData.amount = String.valueOf(this.record.Amount);
            requestData.closeDate = String.valueOf(this.record.CloseDate);

            HttpRequest request = this.configRequest(endpoint, method, JSON.serialize(requestData));
            HttpResponse response = this.sendRequest(request);
            String responseResult = this.parseResponse(response);

            String opportunityTargetStage;
            if (responseResult == RESONSE_RESULT_SUCCESS) {
                opportunityTargetStage = OPPORTUNITY_STAGE_SUBMITTED_PROJECT;
            } else if (responseResult == RESONSE_RESULT_FAILURE) {
                opportunityTargetStage = OPPORTUNITY_STAGE_RESUBMIT_PROJECT;
            }
            
            if (String.isNotBlank(opportunityTargetStage)) {
                record.StageName = opportunityTargetStage;

                try {
                    update record;
                } catch(DMLException de) {
                    throw new ProjectCalloutService.ProjectCalloutServiceException('Error occured during DML operation: ' + de.getMessage());
                }

            }
            
        }

        private HttpRequest configRequest(String endpoint, String method, String requestData) {

            DEBUG_HERE += 'configRequest() - ';

            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod(method);
            request.setHeader('Content-Type', 'application/json');
            // request.setHeader('token', ProjectCalloutService.REGISTRATION_TOKEN);
            request.setHeader('token', ProjectCalloutService.SERVICE_TOKEN);
            request.setBody(requestData);
            request.setTimeout(120000);

            System.debug(logginglevel.INFO, DEBUG_HERE + 'Sending "' + request.getMethod() + '" request to "' + request.getEndpoint() + '" with body: ' + request.getBody());

            return request;
        }

        private HttpResponse sendRequest(HttpRequest request) {
            return new Http().send(request);
        }

        /**
        * Parses HttpResponse response
        *
        * @param response
        * @return String
        **/
        private String parseResponse(HttpResponse response) {

            final String DEBUG_HERE = 'parseResponse() - ';

            System.debug(logginglevel.INFO, DEBUG_HERE + 'Received Response: ' + response);

            String responseStatus = response.getStatus();
            Integer responseStatusCode = response.getStatusCode();
            String responseResult;

            // if 200x response is got set response data
            if (Math.floor(responseStatusCode / 100) == 2) {
                responseResult = RESONSE_RESULT_SUCCESS;
            } else if (Math.floor(responseStatusCode / 100) == 5) {
                responseResult = RESONSE_RESULT_FAILURE;
            }

            return responseResult;
        }
    }

    public class PmsRequest {
        String opportunityId;
        String opportunityName;
        String accountName;
        String closeDate;
        String amount;
    }

    /**
     * Flow Input
     */
    public class FlowInput {

        @InvocableVariable(Label='Opportunity ID' Description='Current Opportunity Id' Required=true)
        public Id opportunityId;

        // @InvocableVariable(Label='Source Entry ID' Description='ID of the Source Entry which will be canceled' Required=true)
        // public Id sourceEntryId;

        public FlowInput() {}

        public FlowInput(Id opportunityId) {
            this.opportunityId = opportunityId;
        }
    }

    /**
     * FlowOutput
     */
    public class FlowOutput {

        @InvocableVariable(Label='Sending Result' Description='Result of Sending the Opportunity to PMS')
        public Boolean isSuccessful;

        public FlowOutput(Boolean isSuccessful) {
            this.isSuccessful = isSuccessful;
        }
    }

    public class ProjectCalloutServiceException extends Exception {}
}