import ballerina/http;
import ballerina/log;
import ballerina/mime;
import ballerina/io;

//Deploying on kubernetes

//import ballerina/http;
//import ballerinax/kubernetes;

//@kubernetes:Ingress {
//    hostname:"ballerina.guides.io",
//    name:"ballerina-guides-company_recruitment_agency_service",
//    path:"/"
//}
//
//@kubernetes:Service {
//    serviceType:"NodePort",
//    name:"ballerina-guides-company_recruitment_agency_service"
//}
//
//@kubernetes:Deployment {
//    image:"ballerina.guides.io/company_recruitment_agency_service:v1.0",
//    name:"ballerina-guides-company_recruitment_agency_service"
//}



//Deploying on docker

//import ballerina/http;
//import ballerinax/docker;

//@docker:Config {
//    registry:"ballerina.guides.io",
//    name:"company_recruitment_agency_service",
//    tag:"v1.0"
//}
//
//@docker:Expose {}
//



endpoint http:Listener comEP {
    port: 9090
};

// Client endpoint to communicate with company recruitment service
//"http://www.mocky.io" is used to create mock services
endpoint http:Client locationEP {
    url: "http://www.mocky.io"
};

//Service is invoked using `basePath` value "/checkVacancies"
@http:ServiceConfig {
    basePath: "/checkVacancies"
}

//comapnyRecruitmentsAgency service to route each request to relevent endpoints and get their responses.
service<http:Service> comapnyRecruitmentsAgency  bind comEP {


    //`http:resourceConfig{}` annotation with POST method declares the HTTP method.
    //Resource that handles the HTTP POST requests that are directed to a specific company using /checkVacancies/company.
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/company"
    }

    comapnyRecruitmentsAgency(endpoint CompanyEP, http:Request req) {
        //Get the JSON payload from the request message.
        var jsonMsg = req.getJsonPayload();

        // "match jsonMsg" allows  selective code execution based on the type of the expression that is being tested.
        match jsonMsg {
            // Try parsing the JSON payload from the request
            json msg => {
                //Get the string value relevant to the key `name`.
                string nameString;

                nameString = check <string>msg["Name"];

                //the http response can be either error|empty|clientResponse
                (http:Response|error|()) clientResponse;

                if (nameString == "John and Brothers (pvt) Ltd") {
                    //Here, `post` represents the POST action of the HTTP client connector routes the payload to the relevant service when the server accepts the enclosed entity.
                    //HTTP client connector routes the payload to "/v2/5b195c31300000f328da16e8" Endpoint
                    clientResponse =
                    locationEP->post("/v2/5b1e6956310000fa163ff82e");


                } else if(nameString == "ABC Company") {
                    //Here, `post` represents the POST action of the HTTP client connector routes the payload to the relevant service when the server accepts the enclosed entity.
                    //HTTP client connector routes the payload to "/v2/5b195c31300000f328da16e8" Endpoint
                    clientResponse =
                    locationEP->post("/v2/5b1e69bd310000f4113ff832");

                }else {
                    //request routes to this EP when Company name is a not a valid one
                    clientResponse =
                    locationEP->post("/v2/5b1e6a1d310000f4113ff836");

                }
                //Use the native function 'respond' to send the client response back to the caller.
                match clientResponse {
                    // If the request was successful, an HTTP response is returned.
                    //`respond()` sends back the inbound clientResponse to the caller if no any error is found.
                    http:Response respone => {
                        CompanyEP->respond(respone) but { error e =>
                        log:printError("Error sending response", err = e) };
                    }
                    error conError => {
                        error err = {};
                        http:Response res = new;
                        res.statusCode = 500;
                        res.setPayload(err.message);
                        CompanyEP->respond(res) but { error e =>
                        log:printError("Error sending response", err = e) };
                    }
                    () => {}
                }

            }
            error err => {
                // If there was an error, the 500 error response is constructed and sent back to the client.
                http:Response res = new;
                res.statusCode = 500;
                res.setPayload(err.message);
                CompanyEP->respond(res) but { error e =>
                log:printError("Error sending response", err = e) };
            }
        }
    }
}
