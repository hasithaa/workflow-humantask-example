import ballerina/ai;
import ballerina/io;
import ballerina/workflow;

final ai:ModelProvider travelModel = check ai:getDefaultModelProvider();

# A bookable flight option.
#
# + flightNo - The flight number
# + departure - Departure time (ISO 8601)
# + fare - The fare in USD
public type FlightOption record {|
    string flightNo;
    string departure;
    decimal fare;
|};

# Searches the GDS for flights.
#
# + fromCity - Origin city
# + toCity - Destination city
# + date - Travel date (ISO 8601)
# + return - Matching flight options, or an error
@workflow:Activity
function searchFlights(string fromCity, string toCity, string date)
        returns FlightOption[]|error {
    return [
        {flightNo: "UL 454", departure: date + "T08:30", fare: 512.00d},
        {flightNo: "SQ 469", departure: date + "T13:10", fare: 468.50d}
    ];
}

# A bookable hotel option.
#
# + name - Hotel name
# + nightlyRate - Rate per night in USD
# + rating - Star rating
public type HotelOption record {|
    string name;
    decimal nightlyRate;
    int rating;
|};

# Searches the hotel inventory.
#
# + city - The destination city
# + nights - Number of nights
# + return - Matching hotel options, or an error
@workflow:Activity
function searchHotels(string city, int nights) returns HotelOption[]|error {
    return [
        {name: "Park Hyatt", nightlyRate: 320.00d, rating: 5},
        {name: "Shinjuku Granbell", nightlyRate: 145.00d, rating: 4}
    ];
}

final workflow:DurableAgent flightAgent = check new ({
    systemPrompt: {
        role: "Flight booking specialist",
        instructions: "Find suitable flights with the searchFlights activity and recommend one with reasons."
    },
    model: travelModel,
    activities: [searchFlights],
    maxIter: 6
});

final workflow:DurableAgent hotelAgent = check new ({
    systemPrompt: {
        role: "Hotel booking specialist",
        instructions: "Find suitable hotels with the searchHotels activity and recommend one with reasons."
    },
    model: travelModel,
    activities: [searchHotels],
    maxIter: 6
});

final workflow:DurableAgent travelDeskAgent = check new ({
    systemPrompt: {
        role: "Travel desk coordinator",
        instructions: string `Plan trips by delegating to your specialist peers.
Ask askFlightDesk for flights (you get its answer immediately) and
askHotelDesk for hotels (its answer arrives later on the hotelResults
channel — wait for it before finalizing). Combine both into one itinerary.`
    },
    model: travelModel,
    events: [
        {name: "hotelResults", request: string}
    ],
    peers: [
        {
            agent: flightAgent,
            name: "askFlightDesk",
            description: "Asks the flight specialist to research and recommend flights."
        },
        {
            agent: hotelAgent,
            name: "askHotelDesk",
            description: "Asks the hotel specialist to research and recommend hotels.",
            'wait: false,
            callbackChannel: "hotelResults"
        }
    ],
    maxIter: 10
});

# Plans one trip end to end through the coordinator agent.
#
# + return - An error when the run fails
public function main() returns error? {
    string instanceId = check travelDeskAgent.run(
            "Plan a trip from Colombo to Tokyo departing 2026-08-14: " +
            "I need a flight and a 3-night hotel near Shinjuku.");
    io:println(string `travel desk started -> instance ${instanceId}`);

    string itinerary = check travelDeskAgent.waitForResult(instanceId);
    io:println("itinerary ->");
    io:println(itinerary);
}
