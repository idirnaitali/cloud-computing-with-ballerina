import ballerina/http;
import ballerina/log;
import ballerinax/docker;
import ballerinax/kubernetes;
import ballerina/mime;
import ballerina/openapi;

@docker:Expose {

}

@kubernetes:Service {
    name: "Warriors"
}
@kubernetes:Deployment {
    image: "warriors",    // remember the docker image should contain only simple letters
    name: "WarriorsService",
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

listener http:Listener warriorsListener = new(9090);

@http:ServiceConfig {
    basePath: "/api/v1/warriors"
}

@openapi:ServiceInfo {
    title: "WarriorsService",
    description: "Warriors service",
    serviceVersion: "1.0.0",
    termsOfService: "The terms in ...",
    contact: {
        name: "Idir",
        email: "inaitali@bim.com",
        url: "https://inaitali/contact"
    },
    license: {
        name: "W-L",
        url: "https://inaitali/apps/warriors/license;"
    }
}

service WarriorsService on warriorsListener {

    json warriors = [
    { id: 1, name: "Yann_LG", nerfCategory: 8, grade: "*****"},
    { id: 0, name: "Idir_N", nerfCategory: 7, grade: "****"},
    { id: 1, name: "Phillipe_Y", nerfCategory: 8, grade: "**"},
    { id: 2, name: "Lukkas_C", nerfCategory: 6, grade: "****"},
    { id: 3, name: "Fouzi_B", nerfCategory: 6, grade: "****"}
    ];

    @http:ResourceConfig {
        path: "/",
        methods: ["GET"]
    }

    @openapi:ResourceInfo {
        summary: "Get request to retrieve the warriors",
        description: "This endpoint is used to get the warriors ..."
    }
    resource function getAll(http:Caller caller, http:Request req) {
        var result = caller->respond(WarriorsService.warriors);
        if (result is error) {
            log:printError("Error: failed to get wirriors");
        }
    }

}
