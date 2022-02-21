module Network exposing
    ( Model
    , Msg(..)
    , init
    , peopleView
    , personView
    , reqView
    , requestsView
    , subscriptions
    , toSession
    , update
    , view
    )

import Brand
import Css exposing (hover)
import Html.Styled exposing (Html, a, button, div, input, text, textarea)
import Html.Styled.Attributes exposing (css, href, placeholder, value)
import Html.Styled.Events exposing (onClick, onInput)
import Loading
import Ports
import Route
import Session exposing (Session)
import Set
import Tailwind.Breakpoints as Breakpoints
import Tailwind.Utilities as T


type alias Model =
    { session : Session
    , reqsLoading : Bool
    , peopleLoading : Bool
    , personLoading : Bool
    , reqSending : Maybe String
    , reqMessage : Maybe String
    , reqMessageVisible : Maybe String
    , acceptSending : Maybe String
    , rejectSending : Maybe String
    , person : Maybe Ports.GetPersonResp
    , requests : List Ports.GetRequestsResp
    , people : List Ports.GetPersonResp
    }


toSession : Model -> Session
toSession model =
    model.session


type Msg
    = GotPerson (Maybe Ports.GetPersonResp)
    | GotPeople (List Ports.GetPersonResp)
    | GotReqs (List Ports.GetRequestsResp)
    | ReqSent String
    | AcceptSent String
    | ReqMessageUpdated String
    | ReqSending String
    | AcceptSending String
    | RejectSending String
    | ToggleReqMessage String
    | RejectSent String


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.gotPerson GotPerson
        , Ports.gotPeople GotPeople
        , Ports.gotRequests GotReqs
        , Ports.requestSent ReqSent
        , Ports.requestAccepted AcceptSent
        , Ports.requestRejected RejectSent
        ]


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , reqsLoading = True
      , peopleLoading = True
      , personLoading = True
      , reqSending = Nothing
      , reqMessage = Nothing
      , reqMessageVisible = Nothing
      , acceptSending = Nothing
      , rejectSending = Nothing
      , person = Nothing
      , requests = []
      , people = []
      }
    , Ports.getPerson (Session.toAccountName session)
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotPerson person ->
            ( { model
                | person = person
                , personLoading = False
              }
            , Ports.getPeople ""
            )

        GotPeople people ->
            let
                isPlatformPerson =
                    model.person /= Nothing

                action =
                    if isPlatformPerson then
                        Ports.getRequests (Session.toAccountName model.session)

                    else
                        Cmd.none
            in
            ( { model
                | people = people
                , peopleLoading = False
                , reqsLoading = not isPlatformPerson
              }
            , action
            )

        GotReqs reqs ->
            ( { model | requests = reqs, reqsLoading = False }, Cmd.none )

        ReqSending account ->
            ( { model | reqSending = Just account }
            , Ports.sendRequest { to_account = account, message = model.reqMessage }
            )

        ReqSent _ ->
            ( { model | reqSending = Nothing, reqMessage = Nothing, reqMessageVisible = Nothing }
            , Ports.getRequests (Session.toAccountName model.session)
            )

        AcceptSending account ->
            ( { model | acceptSending = Just account }
            , Ports.acceptRequest account
            )

        AcceptSent _ ->
            ( { model | reqSending = Nothing }
            , Ports.getRequests (Session.toAccountName model.session)
            )

        RejectSending account ->
            ( { model | acceptSending = Just account }
            , Ports.acceptRequest account
            )

        RejectSent account ->
            ( { model | rejectSending = Just account }
            , Ports.rejectRequest account
            )

        ReqMessageUpdated str ->
            ( { model | reqMessage = Just str }
            , Cmd.none
            )

        ToggleReqMessage account ->
            ( { model
                | reqMessageVisible =
                    if model.reqMessageVisible == Nothing then
                        Just account

                    else
                        Nothing
              }
            , Cmd.none
            )


content : Model -> Html Msg
content model =
    case model.personLoading of
        True ->
            div [] [ Loading.loading ]

        False ->
            div []
                [ div [ css [ T.text_3xl, T.font_bold, T.text_green, T.my_5 ] ] [ text "Network" ]
                , if model.person == Nothing then
                    div [] []

                  else
                    requestsView model
                , peopleView model
                ]


view : Model -> Html Msg
view model =
    div [ css [ T.px_5, T.mx_5 ] ] [ content model ]


requestsView : Model -> Html Msg
requestsView model =
    case ( model.reqsLoading, model.requests ) of
        ( True, _ ) ->
            div [] [ Loading.loading ]

        ( False, [] ) ->
            div [] []

        _ ->
            div
                []
                [ div [ css [ T.font_bold, T.text_green ] ] [ text "Requests" ]
                , div [] (List.map reqView model.requests)
                ]


reqView : Ports.GetRequestsResp -> Html Msg
reqView req =
    div [ Brand.greenFrame ]
        [ div [ css [ Breakpoints.sm [ T.flex, T.flex_row, T.items_start ] ] ]
            [ div [ css [ T.flex_1, T.font_bold ] ] [ text req.account ]
            , button
                [ onClick (RejectSending req.account)
                , Brand.greenButtonOutline
                , css [ T.mx_3 ]
                ]
                [ text "Reject" ]
            , button
                [ onClick (AcceptSending req.account)
                , Brand.greenButton
                ]
                [ text "Accept" ]
            ]
        , div []
            [ req.message
                |> Maybe.map (\n -> div [ css [ T.py_5 ] ] [ text n ])
                |> Maybe.withDefault (div [] [])
            ]
        ]


withoutAcc : String -> List String -> List String
withoutAcc acc =
    List.filter (\n -> n /= acc)


peopleView : Model -> Html Msg
peopleView model =
    div []
        [ div [ css [ T.font_bold, T.text_green ] ] [ text "People" ]
        , div []
            (model.people
                |> List.filter (\p -> p.account /= Session.toAccountName model.session)
                |> List.map (personView model)
            )
        ]


messageView : Model -> Bool -> Html Msg
messageView model messageIsOpen =
    case ( model.reqMessageVisible, messageIsOpen ) of
        ( Just account, True ) ->
            div
                []
                [ div []
                    [ textarea
                        [ Brand.input
                        , Brand.textarea
                        , css [ T.w_full, T.box_border, T.my_3 ]
                        , placeholder "Tell them something!"
                        , onInput ReqMessageUpdated
                        , value <| Maybe.withDefault "" model.reqMessage
                        ]
                        []
                    ]
                , div [ css [ T.text_right ] ] [ button [ onClick (ReqSending account), Brand.greenButton ] [ text "Send" ] ]
                ]

        _ ->
            div [] []


mutualFriends : Model -> Ports.GetPersonResp -> Html Msg
mutualFriends model person =
    case model.person of
        Just currentPerson ->
            let
                mutual =
                    Set.intersect (Set.fromList currentPerson.friends) (Set.fromList person.friends)
                        |> Set.toList
                        |> List.length
                        |> String.fromInt
                        |> (\n ->
                                case n of
                                    "1" ->
                                        n ++ " mutual friend"

                                    _ ->
                                        n ++ " mutual friends"
                           )
            in
            div [ css [ T.my_2 ] ] [ text mutual ]

        Nothing ->
            div [ css [ T.my_2 ] ] [ text "0 mutual friends" ]


personView : Model -> Ports.GetPersonResp -> Html Msg
personView model person =
    let
        messageIsOpen =
            model.reqMessageVisible == Just person.account
    in
    div [ Brand.greenFrame ]
        [ div [ css [ Breakpoints.sm [ T.flex, T.flex_row, T.items_start ] ] ]
            [ div
                [ css [ T.flex_1 ]
                ]
                [ a
                    [ Brand.a
                    , css [ T.font_bold, T.text_black, hover [ T.underline ] ]
                    , href (Route.toPath (Route.Person person.account))
                    ]
                    [ text person.account ]
                , mutualFriends model person
                ]
            , button [ Brand.greenButtonOutline, onClick (ToggleReqMessage person.account) ] [ text "Ping" ]
            ]
        , messageView model messageIsOpen
        ]
