module LinkedText exposing (linkedText, makeWordLink)

import Html.Styled exposing (Html, a, div, text)
import Html.Styled.Attributes exposing (href)


isLink : String -> Bool
isLink str =
    List.foldl (\val acc -> String.startsWith val str || acc) False [ "http", "www", "https" ]


makeWordLink : String -> Html msg
makeWordLink str =
    case isLink str of
        True ->
            a [ href str ] [ text str ]

        False ->
            text str


parseLine : String -> List (Html msg)
parseLine str =
    str
        |> String.words
        |> List.map makeWordLink
        |> List.intersperse (text " ")


linkedText : String -> List (Html msg)
linkedText str =
    str
        |> String.lines
        |> List.map parseLine
        |> List.map (div [])
