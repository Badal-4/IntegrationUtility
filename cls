public with sharing class IntegrationUtility{
    
    public static integrationWrapper iwData{get;set;}
    public static integrationWrapper doCallout(integrationWrapper iw){
        
        List<Integration_Setting__mdt> integrationSettings = [select id,endpoint__c,JWT_custom_label__c,Request_Body__c,Request_Type__c,Use_JWT__c from Integration_Setting__mdt where DeveloperName=:iw.metadataName ];
        if(integrationSettings != null && integrationSettings.size() > 0) {
            iwData = iw;
            if(integrationSettings[0].Request_Type__c == 'POST'){
                iw = doPostcallout(iw, integrationSettings[0]);
            } 
            if(integrationSettings[0].Request_Type__c == 'GET'){
                iw = doGetcallout(iw, integrationSettings[0]);
            } 
        }
        
        return iw;
    }
    
    public static integrationWrapper doPostcallout(integrationWrapper iw, Integration_Setting__mdt integrationSettings){
        if(iw.endpointFormatter != null && iw.endpointFormatter.size() > 0){
            integrationSettings.endpoint__c = string.format(integrationSettings.endpoint__c,iw.endpointFormatter);
        }
        string reqBody = '';
        system.debug(iw.requestBody);
        if(!string.isblank(iw.requestBody)){
            reqBody = iw.requestBody;
        }
        else{
            reqBody = integrationSettings.Request_Body__c;
            if(iw.requestbodyFormatter != null && iw.requestbodyFormatter.size() > 0){
                reqBody = string.format(reqBody,iw.requestbodyFormatter);
            }
        }
        
        system.debug('reqBody --> '+reqBody );
        
        // add payload
        datetime dt = datetime.now().addminutes(30);
        iw.jwtPayload = '{"role":"rest_user","exp":'+dt.getTime()+'}';
        
        httpRequest req = new httpRequest();
        req.setMethod(integrationSettings.Request_Type__c);
        req.setEndpoint(integrationSettings.endpoint__c);
        req.setTimeout(30000);
        if(String.isNotBlank(reqBody)){
           req.setBody(reqBody); 
        }               
        req.setHeader('Content-Type', 'application/json');
        if(integrationSettings.Use_JWT__c){
            string JWTKey = generateJWTToken();
            req.setHeader('Authorization', 'Bearer '+ JWTKey);
        }
        
        system.debug('request check --> '+req);
        
        Http h = new Http();
        HttpResponse res = h.send(req);
        iw.responseBody = res.getBody();
        iw.statusCode = res.getStatusCode();
        system.debug(res);
        system.debug(res.getBody());
        //system.debug(iw);
        return iw;
    }
    
    public static integrationWrapper doGetcallout(integrationWrapper iw, Integration_Setting__mdt integrationSettings){
        if(iw.queryParameter != null && iw.queryParameter != ''){
            integrationSettings.endpoint__c =  integrationSettings.endpoint__c + '?'+ iw.queryParameter;
        }
        system.debug('End Point::'+ integrationSettings.endpoint__c);
        httpRequest req = new httpRequest();
        req.setMethod(integrationSettings.Request_Type__c);
        req.setEndpoint(integrationSettings.endpoint__c);
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(30000);
        //add payload
        datetime dt = datetime.now().addminutes(30);
        iw.jwtPayload = '{"role":"rest_user","exp":'+dt.getTime()+'}';
        
        if(integrationSettings.Use_JWT__c){
            string JWTKey = generateJWTToken();
            req.setHeader('Authorization', 'Bearer '+ JWTKey);
        }
        
        system.debug('request check --> '+req);
        
        Http h = new Http();
        HttpResponse res = h.send(req);
        system.debug(res);
        iw.responseBody = res.getBody();
        iw.statusCode = res.getStatusCode();
        return iw;
    }
    
    public static string generateJWTToken(){
        datetime dt = datetime.now().addminutes(30);
        system.debug(dt);
        system.debug(dt.getTime());
        String header = '{"alg": "HS256","typ":"jwt"}';
        String payload = '{"role":"salesforce_user","exp":'+dt.getTime()+'}';
        if(!String.isblank(iwData.jwtPayload)){
            payload  = iwData.jwtPayload;
        }
        string jwt = base64URLencode(blob.valueof(header)) + '.' +base64URLencode(blob.valueof(payload));
        
        Blob key = blob.valueof(system.label.JWT_Key);
        blob signature = Crypto.generateMac('hmacSHA256',Blob.valueof(jwt),key);
        string JWTString = jwt+'.'+base64URLencode(signature);
        
        system.debug('final data --> '+jwt+'.'+base64URLencode(signature));
        return JWTString ;
    }
    
    public static String base64URLencode(Blob input){ 
        String output = encodingUtil.base64Encode(input);
        output = output.replace('+', '-');
        output = output.replace('/', '_');
        while ( output.endsWith('=')){
            output = output.subString(0,output.length()-1);
        }
        //output = output.replaceAll('=','');
        return output;
    }
    
    public class integrationWrapper{
        public string metadataName{get;set;}
        public list<string> requestbodyFormatter{get;set;}
        public list<string> endpointFormatter{get;set;}
        public string responseBody {get;set;}
        public integer statusCode{get;set;}
        public string requestBody{get;set;}
        public string queryParameter{get;set;}
        public string jwtPayload{get;set;}
    }
}
