# Content Based Routing

The Content-Based Router (CBR) reads the content of a message and routes it to a specific recipient based on its content. This approach is useful when an implementation of a specific logical function is distributed across multiple physical systems.

> This guide walks you through the process of implementing a content based routing using Ballerina language.


This is a simple ballerina code for content based routing.

The following are the sections available in this guide.

- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Implementation](#implementation)
- [Testing](#testing)
- [Deployment](#deployment)
- [Observability](#observability)

## What you’ll build

To understanding how you can build a content based routing using Ballerina, let's consider a real-world use case of a Company recruitmet agency that provides recruiments details of companies. When Company recruitmet agency sends a request that includes the company name (EX : ABC Company), that particular request  will be routed to  to its respective endpoint. The Company recruitmet agency service requires communicating with other necessary back-ends. The following diagram illustrates this use case clearly.

![alt text](/images/BBG-Content_Based_Routing.png)


## Prerequisites
 
- [Ballerina Distribution](https://ballerina.io/learn/getting-started/)
- A Text Editor or an IDE 

### Optional Requirements
- Ballerina IDE plugins ([IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina), [VSCode](https://marketplace.visualstudio.com/items?itemName=WSO2.Ballerina), [Atom](https://atom.io/packages/language-ballerina))
- [Docker](https://docs.docker.com/engine/installation/)
- [Kubernetes](https://kubernetes.io/docs/setup/)


## Implementation

> If you want to skip the basics, you can download the git repo and directly move to the "Testing" section by skipping "Implementation" section.   

### Create the project structure

Ballerina is a complete programming language that supports custom project structures. Use the following package structure for this guide.

```
Company_Recruitment
 └── guide
      └── Company Recruitments Agency
           ├── company_recruitment_agency_service.bal
       └── tests
            └── company_recruitment_agency_service.bal
```
- Create the above directories in your local machine and also create empty `.bal` files.

- Then open the terminal and navigate to `Company_Recruitment/guide` and run Ballerina project initializing toolkit.

```bash
   $ ballerina init
```

### Developing the service
Let's look at the implementation of the Company recruitmet agency service , which acts as The Content-Based Router.

Let's consider that a request comes to the Company recruitmet agency service with a specific content. when Company recruitmet agency service receives the request message, reads it, and routes the request to one of the recipients according to the message's content.

##### companyRecruitments.bal
```ballerina
import ballerina/http;
import ballerina/log;
import ballerina/mime;
import ballerina/io;

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
service<http:Service> comapnyRecruitmentsAgency  bind { port: 9090 } {


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
                    locationEP->post("/v2/5b195c31300000f328da16e8");


                } else if(nameString == "ABC Company") {
                    //Here, `post` represents the POST action of the HTTP client connector routes the payload to the relevant service when the server accepts the enclosed entity.
                    //HTTP client connector routes the payload to "/v2/5b195c31300000f328da16e8" Endpoint
                    clientResponse =
                    locationEP->post("/v2/5b195c6e3000006f26da16e9");

                }else {
                    //request routes to this EP when Company name is a not a valid one
                    clientResponse =
                    locationEP->post("/v2/5b1cffbc3200006c00c36d31");

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
```
- According to the code implementation company_recruitment_agency_service checks the request content and routes it to relevent service.

- In above implementation, company_recruitment_agency_service reads the request's json content("Name") using nameString and sends the request to relevent company. Resource that handles the HTTP POST requests that are directed to a specific company using ```/checkVacancies/company```

- After receiving the request from content based router(company_recruitment_agency_service),the relevent company endpoint send the client response back to the caller.


## Testing 

### Invoking the service

You can run the company_recruitment_agency_service  that you developed above, in your local environment. Open your terminal and navigate to `guide/Company Recruitments Agency`, and execute the following command.
```
$ ballerina run company_recruitment_agency_service.bal
```
You can test the functionality of the company_recruitment_agency_service by sending HTTP POST request. For example, we have used the curl commands to test each routing operation of company_recruitment_agency_service as follows.

**Route the request when "Name"="John and Brothers (pvt) Ltd"** 

```bash
 $ curl -v http://localhost:9090/checkVacancies/company -d '{"Name" :"John and Brothers (pvt) Ltd"}' -H "Content- Type:application/json"
  
 Output : 
  
*   Trying 127.0.0.1...
* Connected to localhost (127.0.0.1) port 9090 (#0)
> POST /checkVacancies/company HTTP/1.1
> Host: localhost:9090
> User-Agent: curl/7.47.0
> Accept: */*
> Content-Type:application/json
> Content-Length: 40
> 

* upload completely sent off: 40 out of 40 bytes
< HTTP/1.1 200 OK
< Date: Mon, 11 Jun 2018 13:30:00 GMT
< Content-Type: application/json
< Via: 1.1 vegur
< server: Cowboy
< content-length: 356

{
     Name: "John and Brothers (pvt) Ltd",
     Total_number_of_Vacancies: 12,
     Available_job_roles : "Senior Software Engineer = 3 ,Marketing Executives =5 Management Trainees=4",
     CV_Closing_Date: "17/06/2018" ,
     ContactNo: 01123456 ,
     Email_Address: "careersjohn@jbrothers.com"
    
    
* Connection #0 to host localhost left intact
}
```

**Route the request when "Name"="ABC Company"**

```bash
$ curl -v http://localhost:9090/checkVacancies/company -d '{"Name" : "ABC Company"}' -H "Content-Type:application/json"

Output : 

*   Trying 127.0.0.1...
* Connected to localhost (127.0.0.1) port 9090 (#0)
> POST /checkVacancies/company HTTP/1.1
> Host: localhost:9090
> User-Agent: curl/7.47.0
> Accept: */*
> Content-Type:application/json
> Content-Length: 22

* upload completely sent off: 40 out of 40 bytes
< HTTP/1.1 200 OK
< Date: Mon, 11 Jun 2018 13:30:00 GMT
< Content-Type: application/json
< Via: 1.1 vegur
< server: Cowboy
< content-length: 308

{
     Name:"ABC Company",
     Total_number_of_Vacancies: 10,
     Available_job_roles : "Senior Finance Manager = 2 ,Marketing Executives =6 HR Manager=2",
     CV_Closing_Date: "20/07/2018" ,
     ContactNo: 0112774 ,
     Email_Address: "careers@abc.com"
        
 }

```

**Route the request when "Name"="Smart Automobile"**

```bash
$ curl -v http://localhost:9090/checkVacancies/company -d '{"Name" : "Smart Automobile"}' -H "Content-Type:application/json"

Output :

*   Trying 127.0.0.1...
* Connected to localhost (127.0.0.1) port 9090 (#0)
> POST /checkVacancies/company HTTP/1.1
> Host: localhost:9090
> User-Agent: curl/7.47.0
> Accept: */*
> Content-Type:application/json
> Content-Length: 29

* upload completely sent off: 29 out of 29 bytes
< HTTP/1.1 200 OK
< Date: Mon, 11 Jun 2018 12:27:45 GMT
< Content-Type: application/json
< Via: 1.1 vegur
< server: Cowboy
< content-length: 315

{
    Name:"Smart Automobile",
    Total_number_of_Vacancies: 11,
    Available_job_roles : "Senior Finance Manager = 2 ,Marketing Executives =6 HR Manager=3",
    CV_Closing_Date: "20/07/2018" ,
    ContactNo: 0112774 ,
    Email_Address: "careers@smart.com"

 }
```
### Writing unit tests 

In Ballerina, the unit test cases should be in the same package inside a folder named as 'tests'.  When writing the test functions the below convention should be followed.
- Test functions should be annotated with `@test:Config`. See the below example.
```ballerina
   @test:Config
   Company_Recruitments_Agency) {
```
  
This guide contains unit test cases for each resource available in the 'company_recruitment_agency_service implemented above. 

To run the unit tests, open your terminal and navigate to `/content-based-routing/guide`, and run the following command.
```bash
   $ ballerina test
```

## Deployment

Once you are done with the development, you can deploy the service using any of the methods that we listed below. 

### Deploying locally

- As the first step, you can build a Ballerina executable archive (.balx) of the service that we developed above. Navigate to `/content-based-routing/guide` and run the following command. 
```bash
   $ ballerina build company_recruitment_agency_service
```

- Once the company_recruitment_agency_service.balx is created inside the target folder, you can run that with the following command. 
```bash
   $ ballerina run target/company_recruitment_agency_service.balx
```

- The successful execution of the service will show us the following output. 
```
   ballerina: initiating service(s) in 'target/company_recruitment_agency_service.balx'
   ballerina: started HTTP/WS endpoint 0.0.0.0:9090
```

### Deploying on Docker

You can run the service that we developed above as a docker container. As Ballerina platform includes [Ballerina_Docker_Extension](https://github.com/ballerinax/docker), which offers native support for running ballerina programs on containers, you just need to put the corresponding docker annotations on your service code. 

- In our company_recruitment_agency_service, we need to import  `ballerinax/docker` and use the annotation `@docker:Config` as shown below to enable docker image generation during the build time. 

```ballerina

@docker:Config {
    registry:"ballerina.guides.io",
    name:"company_recruitment_agency_service",
    tag:"v1.0"
}

@docker:Expose {}


// Client endpoint to communicate with company recruitment service
//"http://www.mocky.io" is used to create mock services

endpoint http:Listener comEP {
    port: 9090
};

endpoint http:Client locationEP {
    url: "http://www.mocky.io"
};

//Service is invoked using `basePath` value "/checkVacancies"
@http:ServiceConfig {
    basePath: "/checkVacancies"
}

service<http:Service> comapnyRecruitmentsAgency  bind comEP {

```

