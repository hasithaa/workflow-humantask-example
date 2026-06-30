import ballerina/http;

// URL of the downstream shipping service. Overridable via Config.toml so tests
// can point it at a local mock.
configurable string shippingServiceUrl = "http://localhost:9000/shippingService";

final http:Client shippingServiceEP = check new (shippingServiceUrl);
