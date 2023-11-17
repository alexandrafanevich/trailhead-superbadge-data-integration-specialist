public class BillingCalloutService {

    final static String PROJECT_STATUS_BILLED = 'Billed';
    final static ServiceCredentials__c credentials = ServiceCredentials__c.getValues('BillingServiceCredential');

    @Future(callout=true)
    public static void callBillingService(String projectRef, Decimal billingAmount) {

        BillingServiceProxy.project project = new BillingServiceProxy.project();
        project.username = credentials.Username__c;
        project.password = credentials.Password__c;
        project.billAmount = billingAmount;
        project.projectid = projectRef;

        BillingServiceProxy.InvoicesPortSoap11 invoicesPortSoap11 = new BillingServiceProxy.InvoicesPortSoap11();
        String response = invoicesPortSoap11.billProject(project);

        if (!response.equalsIgnoreCase('OK')) {
            return;
        }
        
        Project__c newProject = new Project__c(
            ProjectRef__c = projectRef,
            Status__c = PROJECT_STATUS_BILLED
        );
        
        upsert newProject ProjectRef__c;

    }

}