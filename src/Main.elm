module Main exposing (Model, Msg(..), init, main, update)

import Account exposing (Account)
import Asset
import Brand
import Browser exposing (UrlRequest(..))
import Browser.Navigation as Browser
import Home
import Html.Styled as Html exposing (Html, a, div, footer, header, img, main_, text, toUnstyled)
import Html.Styled.Attributes as Attr exposing (css, href)
import Network
import Person
import Route
import Session exposing (Session)
import Tailwind.Utilities as T
import Thread exposing (ThreadName(..))
import Tuple exposing (first, second)
import Url exposing (Url)



---- MODEL ----


type Model
    = ThreadPage Thread.Model
    | HomePage Home.Model
    | PersonPage Person.Model
    | NetworkPage Network.Model
    | NotFound Session


toSession : Model -> Session
toSession model =
    case model of
        ThreadPage subModel ->
            Thread.toSession subModel

        HomePage subModel ->
            Home.toSession subModel

        NetworkPage subModel ->
            Network.toSession subModel

        PersonPage subModel ->
            Person.toSession subModel

        NotFound session ->
            session



---- UPDATE ----


type Msg
    = GotThreadMsg Thread.Msg
    | GotHomeMsg Home.Msg
    | GotPersonMsg Person.Msg
    | GotNetworkMsg Network.Msg
    | UrlChanged Url
    | UrlRequested UrlRequest
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        session =
            toSession model
    in
    case ( msg, model ) of
        ( UrlChanged url, _ ) ->
            init
                (Session.toAccountName session)
                url
                (Session.toKey session)

        ( UrlRequested urlRequest, _ ) ->
            case urlRequest of
                Internal url ->
                    ( model, Browser.pushUrl (Session.toKey session) (Url.toString url) )

                External url ->
                    ( model, Browser.load url )

        ( GotThreadMsg subMsg, ThreadPage oldModel ) ->
            let
                ( subModel, subCmd ) =
                    Thread.update subMsg oldModel
            in
            ( ThreadPage subModel, Cmd.map GotThreadMsg subCmd )

        ( GotHomeMsg subMsg, HomePage oldModel ) ->
            let
                ( subModel, subCmd ) =
                    Home.update subMsg oldModel
            in
            ( HomePage subModel, Cmd.map GotHomeMsg subCmd )

        ( GotPersonMsg subMsg, PersonPage oldModel ) ->
            let
                ( subModel, subCmd ) =
                    Person.update subMsg oldModel
            in
            ( PersonPage subModel, Cmd.map GotPersonMsg subCmd )

        ( GotNetworkMsg subMsg, NetworkPage oldModel ) ->
            let
                ( subModel, subCmd ) =
                    Network.update subMsg oldModel
            in
            ( NetworkPage subModel, Cmd.map GotNetworkMsg subCmd )

        _ ->
            ( model, Cmd.none )


content : Model -> Html Msg
content model =
    case model of
        HomePage subModel ->
            Html.map GotHomeMsg (Home.view subModel)

        ThreadPage subModel ->
            Html.map GotThreadMsg (Thread.view subModel)

        PersonPage subModel ->
            Html.map GotPersonMsg (Person.view subModel)

        NetworkPage subModel ->
            Html.map GotNetworkMsg (Network.view subModel)

        _ ->
            div [] [ text "Not Found" ]


view : Model -> Html Msg
view model =
    div
        [ css [ T.flex, T.flex_col, T.h_screen, T.overscroll_none ] ]
        [ header [ css [] ] [ navBar model ]
        , main_ [ css [ T.flex_1, T.overflow_y_auto ] ] [ div [ css [ T.max_w_3xl, T.m_auto ] ] [ content model ] ]
        , footer [] []
        ]


navBar : Model -> Html Msg
navBar model =
    header
        [ Brand.row
        , css
            [ T.bg_green
            , T.justify_center
            , T.p_3
            ]
        ]
        [ div
            [ css
                [ T.flex_1
                , T.block
                ]
            ]
            [ a [ href <| Route.toPath Route.Home ]
                [ img
                    [ Asset.toAttr Asset.logoRoundedWhite
                    , css [ T.align_middle ]
                    ]
                    []
                ]
            ]
        , div
            [ css
                [ T.mx_4 ]
            ]
            [ a
                [ css [ T.text_white ]
                , href <| Route.toPath Route.Network
                ]
                [ img [ Asset.toAttr Asset.hand ] [] ]
            ]
        , div
            [ css
                [ T.text_right
                ]
            ]
            [ a
                [ css [ T.text_white ]
                , model
                    |> toSession
                    |> Session.toAccountName
                    |> Route.Person
                    |> Route.toPath
                    |> href
                ]
                [ img [ Asset.toAttr Asset.house ] [] ]
            ]
        ]


init : String -> Url -> Browser.Key -> ( Model, Cmd Msg )
init accountName url key =
    let
        session =
            Session.new key (Account.new accountName)
    in
    case Route.toRoute url of
        Route.Home ->
            let
                ( model, cmd ) =
                    Home.init session
            in
            ( HomePage model, Cmd.map GotHomeMsg cmd )

        Route.Thread name ->
            let
                ( model, cmd ) =
                    Thread.init session (ThreadName <| Maybe.withDefault name <| Url.percentDecode name)
            in
            ( ThreadPage model, Cmd.map GotThreadMsg cmd )

        Route.Person name ->
            let
                ( model, cmd ) =
                    Person.init session name
            in
            ( PersonPage model, Cmd.map GotPersonMsg cmd )

        Route.Network ->
            let
                ( model, cmd ) =
                    Network.init session
            in
            ( NetworkPage model, Cmd.map GotNetworkMsg cmd )

        _ ->
            ( NotFound session, Cmd.none )


subscription : Model -> Sub Msg
subscription model =
    case model of
        ThreadPage subModel ->
            Sub.map GotThreadMsg <| Thread.subscription subModel

        HomePage subModel ->
            Sub.map GotHomeMsg <| Home.subscriptions subModel

        PersonPage subModel ->
            Sub.map GotPersonMsg <| Person.subscriptions subModel

        NetworkPage subModel ->
            Sub.map GotNetworkMsg <| Network.subscriptions subModel

        _ ->
            Sub.none


main : Program String Model Msg
main =
    Browser.application
        { view = view >> toUnstyled >> (\n -> { title = "0ve", body = [ n ] })
        , init = init
        , update = update
        , subscriptions = subscription
        , onUrlChange = UrlChanged
        , onUrlRequest = UrlRequested
        }
