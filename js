({
	doInit : function(component, event, helper) {
		var action = component.get("c.fetchFactset");
        action.setParams({
            contactId : component.get("v.recordId")
        });
        action.setCallback(this, function(resp){
            
            if(resp.getState() === "SUCCESS"){
                if(resp.getReturnValue().isSuccess){
                    var respObject = JSON.parse((resp.getReturnValue().response));
                    console.log('data check --> '+JSON.stringify(respObject));
                    if(!respObject.isBasic){
                        var respData = [];
                        var responsiList = [];
                        var recommenList = [];
                        console.log('JSON response --> '+JSON.stringify(respObject.parserData));
                        var tempRespData = respObject.parserData;
                        for(var i=0;i<tempRespData.length;i++){
                          //  if(respData[i].name=='Shares Held' || respData[i].name=='AuR'){
                          //  respData[i].value = respData[i].value.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
                          //  }
                            
                             if(tempRespData[i].type == 'investor_info'){
                             if(tempRespData[i].name == 'AuR' || tempRespData[i].name == 'Shares Held'){
                                 tempRespData[i].value = tempRespData[i].value.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
                                 respData.push(tempRespData[i]);
                             }
                             
                             if(tempRespData[i].name == '% of Shares Outstanding'){
                                 respData.push(tempRespData[i]);
                             }
                             }
                             else if(tempRespData[i].type == "responsible_funds")
                             {
                                
                                    tempRespData[i].value = tempRespData[i].value.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
                                    responsiList.push(tempRespData[i]);
                                    component.set("v.responsibleFundList",responsiList);
                                }                               
                             
                             else if(tempRespData[i].type == "recommended_funds")
                             {
                                tempRespData[i].value = tempRespData[i].value.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
                                recommenList.push(tempRespData[i]);
                                component.set("v.recommendedFundList",recommenList);
                                
                             }
                        }                      
                        component.set("v.factsetData", respData);
                        var payload = {
                            recordId : component.get("v.recordId"),
                            message : JSON.stringify(tempRespData)
                        };
                        component.find('contactMessageChannel').publish(payload);
                       
                    }
                    else{
                        component.set("v.isbasic", true);
                    }
                    if(respObject  && respObject.conData){
                        component.set("v.contactData", respObject.conData);
                    }
                    
                }
            }else{
                helper.showToast("Error", resp.getError(), "error" ) ;
            }
        });
        
       $A.enqueueAction(action);
	},
    handleNavigate : function(component,event,helper)
    {
        var fundId = event.target.name;  
        var recordId = component.get("v.recordId");      
        window.parent.postMessage('navigateFund'+';'+fundId+';'+'fromContactDetail'+';'+recordId);
    }
})
