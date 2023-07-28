trigger OrderLineItemTrigger on Order_Line_Item__c (before insert, after insert, after update) {
	if(CheckRecursion.runOnce()){
        switch on Trigger.operationType { 
            when BEFORE_INSERT {  
                OrderLineItemTriggerHandler.oliBeforeInsertHandler(Trigger.new);
            } 

            when AFTER_INSERT {  
                List<Order_Line_Item__c> emptyOliList = new List<Order_Line_Item__c>();
                OrderLineItemTriggerHandler.oliAfterInsertUpdateHandler(Trigger.new, emptyOliList);
            } 
            
            when AFTER_UPDATE { 
                OrderLineItemTriggerHandler.oliAfterInsertUpdateHandler(Trigger.new, Trigger.old);
            }   
        }
    }
}