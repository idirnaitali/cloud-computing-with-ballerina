import ballerina/io;
import ballerina/http;
import ballerina/log;
import ballerinax/kubernetes;
import ballerinax/docker;
import ballerina/mime;
import ballerina/openapi;

@docker:Expose {

}

@kubernetes:Service {
    name: "apigateway"
}
@kubernetes:Deployment {
    image: "apigateway",    // remember the docker image should contain only simple letters
    name: "api-gateway",
    replicas: 3,
    //namespace: "kube-public",
    buildImage: true,
    labels: {
        team: "WIRED",
        scope: "SERVICE"
    },
    dockerHost: "tcp://192.168.99.104:2376",    // IP can be obtained via `minikube ip` command
    dockerCertPath: "~/.minikube/certs",    // Docker cert path should be configure here
    singleYAML: true
}

listener http:Listener apigwListener = new(9091);

@http:ServiceConfig {
    basePath: "/api/v1/apigw"
}

@openapi:ServiceInfo {
    title: "ApiGateway",
    description: "The API Gateway service",
    serviceVersion: "1.0.0",
    termsOfService: "The terms in ...",
    contact: {
        name: "Idir",
        email: "inaitali@bim.com",
        url: "https://inaitali/contact"
    },
    license: {
        name: "APIGW-L",
        url: "https://inaitali/apps/apigw/license;"
    }
}

service ApiGateway on apigwListener {

    int calsCounter = 0;
    http:Client warriorsClient = new("http://localhost:9090/api/v1/warriors");
    json apikeys = ["Z2FtZTpnYW1lMQ=="];

    @http:ResourceConfig {
        path: "/ping",
        methods: ["GET"]
    }

    @openapi:ResourceInfo {
        summary: "Get request to ping the API Gateway",
        description: "This endpoint is used to pingle the apig ... "
    }
    resource function ping(http:Caller caller, http:Request req) {
        json respondBody = {
            status: "UP",
            message: "Dont worry 'phil Y', the Api Gateway is up!"
        };
        log:printInfo(respondBody.toString());
        var result = caller->respond(respondBody);
    }

    @http:ResourceConfig {
        path: "/warriors",
        methods: ["GET"]
    }

    @openapi:ResourceInfo {
        summary: "Get request to retrieve the warriors through the apigw",
        description: "This endpoint is used to get the warriors ..."
    }
    resource function callWirriorsApi(http:Caller caller, http:Request req) {

        ApiGateway.calsCounter = ApiGateway.calsCounter + 1;
        log:printInfo("Call N° " + ApiGateway.calsCounter + ": call warriors backend API to get warriors");

        http:Response httpResponse = new;

        if (!req.hasHeader("apikey") || "Z2FtZTpnYW1lMQ==" != req.getHeader("apikey")) {
            httpResponse.statusCode = 401;
            httpResponse.setPayload({errorType: "FUNCTIONAL",errorCode: "err.func.unauthorized",errorMessage: "Access unauthorized"});
        } else {

            var wc = ApiGateway.warriorsClient;
            var response = wc->get("/");

            if (response is http:Response) {
                var payload = response.getJsonPayload();
                if (payload is json) {
                    httpResponse.statusCode = 200;
                    httpResponse.setPayload({
                        page: 0,
                        pageSize: payload.length(),
                        data: untaint payload
                    });
                } else {
                    httpResponse.statusCode = 500;
                    httpResponse.setPayload({errorType: "TECHNICAL",errorCode: "err.tech.unxpected",errorMessage: "Error when trying to read recieved payload"});
                }
            } else {
                io:println("Error when calling the backend: ", response.reason());
                httpResponse.statusCode = 500;
                httpResponse.setPayload({errorType: "TECHNICAL",errorCode: "err.tech.get-wirriors",errorMessage: "Error when calling warriors backend"});
            }
        }
        var result = caller->respond(httpResponse);
    }

}
