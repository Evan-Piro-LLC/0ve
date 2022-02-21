module Route exposing (Route(..), parser, toPath, toRoute)

import Url exposing (Url)
import Url.Builder exposing (absolute)
import Url.Parser exposing ((</>), Parser, int, map, oneOf, parse, s, string, top)


type Route
    = Home
    | Thread String
    | Person String
    | Network
    | NotFound


parser : Parser (Route -> a) a
parser =
    oneOf
        [ map Thread <| s "channel" </> string
        , map Network (s "network")
        , map Person string
        , map Home top
        ]


toPath : Route -> String
toPath route =
    case route of
        Thread name ->
            absolute [ "channel", name ] []

        Network ->
            absolute [ "network" ] []

        Home ->
            absolute [] []

        Person account ->
            absolute [ account ] []

        _ ->
            absolute [] []


toRoute : Url -> Route
toRoute url =
    Maybe.withDefault NotFound (parse parser url)
