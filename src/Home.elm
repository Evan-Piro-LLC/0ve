port module Home exposing
    ( Model
    , Msg(..)
    , getThreads
    , gotThreads
    , init
    , subscriptions
    , toSession
    , update
    , view
    )

import Asset
import Brand
import Browser.Navigation as Browser
import Css exposing (hover)
import Html.Styled exposing (Html, a, button, div, h1, h3, img, input, span, text)
import Html.Styled.Attributes exposing (css, href, placeholder, src, value)
import Html.Styled.Events exposing (onClick, onInput)
import Loading
import Route
import Session exposing (Session)
import Tailwind.Utilities as T
import Url


port getThreads : () -> Cmd msg


port gotThreads : (List ThreadMetadata -> msg) -> Sub msg


port addThread : String -> Cmd msg


port gotThreadCreated : (String -> msg) -> Sub msg


type alias ThreadMetadata =
    { name : String
    , size : Int
    }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch [ gotThreads GotThreads, gotThreadCreated ThreadCreated ]


type Frame
    = AddingThread
    | SendingThread
    | SeeingThreads
    | LoadingThreads
    | SeeingError


type alias Model =
    { threads : List ThreadMetadata
    , loading : Bool
    , threadName : String
    , session : Session
    , frame : Frame
    }


toSession : Model -> Session
toSession model =
    model.session


init : Session -> ( Model, Cmd Msg )
init session =
    ( { threads = []
      , loading = True
      , threadName = ""
      , session = session
      , frame = LoadingThreads
      }
    , getThreads ()
    )


type Msg
    = GotThreads (List ThreadMetadata)
    | GotError
    | ThreadNameUpdated String
    | CreateThread
    | OpenAddThread
    | CloseAddThread
    | ThreadCreated String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OpenAddThread ->
            ( { model | frame = AddingThread }, Cmd.none )

        CloseAddThread ->
            ( { model | frame = SeeingThreads }, Cmd.none )

        GotThreads threads ->
            ( { model
                | loading = False
                , threads = threads
                , threadName = ""
                , frame = SeeingThreads
              }
            , Cmd.none
            )

        GotError ->
            ( { model | loading = False, threads = [], frame = SeeingError }, Cmd.none )

        ThreadNameUpdated name ->
            ( { model | threadName = name }, Cmd.none )

        ThreadCreated name ->
            -- @Todo change receive thread ID for route and not hardcoded.
            let
                url =
                    Route.toPath (Route.Thread name)
            in
            ( model, Browser.pushUrl (Session.toKey model.session) url )

        CreateThread ->
            ( { model | loading = True, frame = SendingThread }, addThread model.threadName )


threadTeaser : ThreadMetadata -> Html Msg
threadTeaser { name, size } =
    a
        [ href (Route.toPath <| Route.Thread name)
        , Brand.greenFrame
        , Brand.row
        , css
            [ T.block
            , T.no_underline
            , hover []
            ]
        ]
        [ div [ css [ T.text_xl, T.font_bold, T.flex_1 ] ] [ text name ]
        , div [ css [ T.flex_1, T.text_right ] ] [ commentsCount size ]
        ]


commentsCount : Int -> Html Msg
commentsCount num =
    div [ Brand.row, css [ T.text_green, T.justify_end ] ]
        [ img [ Asset.toAttr Asset.post ] []
        , div [ css [ T.mx_1 ] ]
            [ num
                |> String.fromInt
                |> (\n -> "(" ++ n ++ ")")
                |> text
            ]
        ]


threadsFeed : Model -> Html Msg
threadsFeed model =
    let
        threads =
            List.map
                threadTeaser
                model.threads

        threadsOrMessage =
            if List.isEmpty model.threads then
                [ div [ css [ T.mt_10 ] ] [ text "Nothing yet." ] ]

            else
                threads
    in
    div [ css [ T.px_5, T.text_green, T.my_3 ] ]
        [ div [ Brand.row, css [ T.justify_center ] ]
            [ div [ css [ T.text_2xl, T.pt_2, T.font_bold, T.flex_1 ] ]
                [ text "Channels"
                ]
            , img [ css [ T.text_right, T.ml_auto, hover [ T.cursor_pointer ] ], Asset.toAttr Asset.add, onClick OpenAddThread ] []
            ]
        , div
            []
            threadsOrMessage
        ]


addThreadView : Model -> Html Msg
addThreadView model =
    div
        [ Brand.greenFrame, css [ T.px_5, T.mx_5 ] ]
        [ div [ Brand.row, css [ T.justify_center ] ]
            [ div [ css [ T.text_xl, T.pt_1, T.font_bold, T.flex_1 ] ]
                [ text "Create Channel"
                ]
            , img [ css [ T.text_right, T.ml_auto, hover [ T.cursor_pointer ] ], Asset.toAttr Asset.close, onClick CloseAddThread ] []
            ]
        , div []
            [ input
                [ Brand.input
                , Brand.textarea
                , value model.threadName
                , placeholder "Got something to post about?"
                , onInput ThreadNameUpdated
                , css [ T.my_4 ]
                ]
                []
            , div [] [ button [ Brand.greenButton, onClick CreateThread ] [ text "Launch" ] ]
            ]
        ]


view : Model -> Html Msg
view model =
    case model.frame of
        LoadingThreads ->
            Loading.loading

        SeeingError ->
            div [] [ text "Got Error" ]

        SeeingThreads ->
            threadsFeed model

        AddingThread ->
            addThreadView model

        SendingThread ->
            div [] [ Loading.loading ]
