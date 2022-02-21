port module Ports exposing
    ( GetPersonResp
    , GetRequestsResp
    , PutPersonArg
    , SendRequestArg
    , acceptRequest
    , getPeople
    , getPerson
    , getRequests
    , gotPeople
    , gotPerson
    , gotRequests
    , putPerson
    , rejectRequest
    , requestAccepted
    , requestRejected
    , requestSent
    , sendRequest
    )


port getPeople : String -> Cmd msg


port gotPeople : (List GetPersonResp -> msg) -> Sub msg


port getPerson : String -> Cmd msg


port gotPerson : (Maybe GetPersonResp -> msg) -> Sub msg


port putPerson : PutPersonArg -> Cmd msg


port getRequests : String -> Cmd msg


port acceptRequest : String -> Cmd msg


port requestAccepted : (String -> msg) -> Sub msg


port rejectRequest : String -> Cmd msg


port requestRejected : (String -> msg) -> Sub msg


port sendRequest : SendRequestArg -> Cmd msg


port requestSent : (String -> msg) -> Sub msg


port gotRequests : (List GetRequestsResp -> msg) -> Sub msg


type alias PutPersonArg =
    { cid : Maybe String
    , text : Maybe String
    }


type alias SendRequestArg =
    { to_account : String
    , message : Maybe String
    }


type alias GetPersonResp =
    { text : Maybe String
    , cid : Maybe String
    , created_timestamp : Int
    , friends : List String
    , account : String
    }


type alias GetRequestsResp =
    { message : Maybe String
    , account : String
    }
