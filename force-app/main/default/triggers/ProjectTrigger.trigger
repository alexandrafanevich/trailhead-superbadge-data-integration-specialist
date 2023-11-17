trigger ProjectTrigger on Project__c (after update) {

    final static String PROJECT_STATUS_BILLABLE = 'Billable';

    for (Project__c record : Trigger.new) {
        if (record.Status__c == PROJECT_STATUS_BILLABLE) {
            BillingCalloutService.callBillingService(record.ProjectRef__c, record.Billable_Amount__c);
        }
    }
}