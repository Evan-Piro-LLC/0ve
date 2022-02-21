module Drawing exposing (Model, MouseMoveData, Msg(..), Particle, Path, Vector, addVector, aging, clearScreen, drawParticle, drawParticles, drawPath, height, init, isParticleLive, main, mouseMoveDecoder, mult, newParticle, subscriptions, subt, update, updateParticle, updatePath, updatePaths, view, width)

{-
   Transliteration of p5js example:
       https://p5js.org/examples/hello-p5-drawing.html

   using:
       joakin/elm-canvas

    Note that compared to the original p5js example the lists of paths and
    particles are in the reverse order to simplify the adding of new paths
    and particles.
-}

import Browser
import Browser.Events exposing (onAnimationFrameDelta, onMouseDown, onMouseMove, onMouseUp)
import Canvas exposing (..)
import Color
import Html exposing (Html)
import Json.Decode as D exposing (Decoder, field, int)
import Random


width : number
width =
    720


height : number
height =
    400


{-| This is how much life a particle loses every tick. Life begins at 1.0
equating to the maximum alpha value for rgba.
-}
aging : Float
aging =
    1 / 255


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Particle =
    { position : Point
    , velocity : Vector
    , drag : Float
    , lifespan : Float
    }


type alias Path =
    List Particle


type alias Model =
    { millis : Float
    , next : Float
    , latestMousePosition : Point
    , previousMousePosition : Point
    , painting : Bool
    , paths : List Path
    }


init : () -> ( Model, Cmd Msg )
init () =
    ( Model 0 0 ( 0, 0 ) ( 0, 0 ) False [], Cmd.none )


newParticle : Point -> Vector -> Particle
newParticle p v =
    Particle p v 0.98 1.0


updateParticle : Particle -> Particle
updateParticle particle =
    { particle
        | position = addVector particle.position particle.velocity
        , velocity = mult particle.drag particle.velocity
        , lifespan = particle.lifespan - aging
    }


isParticleLive : Particle -> Bool
isParticleLive particle =
    particle.lifespan > 0


updatePath : Path -> Path
updatePath particles =
    List.filter isParticleLive <| List.map updateParticle particles


updatePaths : List Path -> List Path
updatePaths paths =
    let
        newPaths =
            List.map updatePath paths
    in
    case newPaths of
        head :: tail ->
            head :: List.filter (not << List.isEmpty) tail

        [] ->
            newPaths


addVector : Point -> Vector -> Point
addVector p v =
    ( (+) (Tuple.first p) (Tuple.first v)
    , (+) (Tuple.second p) (Tuple.second v)
    )



-- UPDATE


mouseMoveDecoder : Decoder MouseMoveData
mouseMoveDecoder =
    D.map2 MouseMoveData
        (field "offsetX" int)
        (field "offsetY" int)


type alias MouseMoveData =
    { offsetX : Int
    , offsetY : Int
    }


type Msg
    = Tick Float
    | UserPressedMouseButton MouseMoveData
    | UserMovedMouse MouseMoveData
    | UserReleasedMouseButton
    | NewParticle Float


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick delta ->
            ( { model
                | millis = model.millis + delta
                , paths = updatePaths model.paths
              }
            , Cmd.none
            )

        NewParticle n ->
            let
                next =
                    model.millis + n

                current =
                    model.latestMousePosition

                force =
                    mult 0.05 <| subt current model.previousMousePosition

                particle =
                    newParticle current force

                -- prepend particle to the first (i.e. latest) path
                paths : List Path
                paths =
                    case model.paths of
                        latestPath :: otherPaths ->
                            case latestPath of
                                head :: tail ->
                                    (particle :: latestPath) :: otherPaths

                                [] ->
                                    [ particle ] :: otherPaths

                        [] ->
                            [ [ particle ] ]
            in
            ( { model | paths = paths, next = next }, Cmd.none )

        UserMovedMouse data ->
            let
                mousePosition =
                    ( toFloat data.offsetX, toFloat data.offsetY )

                ( millis, cmd ) =
                    if model.millis > model.next then
                        ( 0, Random.generate NewParticle <| Random.float 0 100 )

                    else
                        ( model.millis, Cmd.none )

                newModel =
                    { model
                        | previousMousePosition = model.latestMousePosition
                        , latestMousePosition = mousePosition
                        , millis = millis
                    }
            in
            ( newModel, cmd )

        UserPressedMouseButton data ->
            let
                mousePosition =
                    ( toFloat data.offsetX, toFloat data.offsetY )

                -- prepend empty Particle list if not present
                paths =
                    case model.paths of
                        head :: tail ->
                            if List.isEmpty head then
                                model.paths

                            else
                                [] :: model.paths

                        [] ->
                            [ [] ]
            in
            ( { model
                | painting = True
                , previousMousePosition = mousePosition
                , latestMousePosition = mousePosition
                , paths = paths
              }
            , Cmd.none
            )

        UserReleasedMouseButton ->
            ( { model | painting = False }, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    Canvas.toHtml
        ( width, height )
        []
        (clearScreen
            :: (List.reverse model.paths
                    |> List.map drawPath
                    |> List.concat
               )
        )


{-| reverse the list so that particles are drawn in the correct order
-}
drawPath : Path -> List Renderable
drawPath particles =
    List.reverse particles
        |> drawParticles Nothing


{-| recursively draw particles using this particle's position
as parameter for the next call
-}
drawParticles : Maybe Point -> Path -> List Renderable
drawParticles p particles =
    case particles of
        head :: tail ->
            let
                renderable =
                    drawParticle head p
            in
            renderable :: drawParticles (Just head.position) tail

        [] ->
            []


{-| draw a circle and a line to the previous point "p" - or just a circle
if the point "p" is Nothing
-}
drawParticle : Particle -> Maybe Point -> Renderable
drawParticle particle p =
    shapes
        []
        (case p of
            Just point ->
                [ circle particle.position 4
                , path point
                    [ lineTo particle.position
                    ]
                ]

            Nothing ->
                [ circle particle.position 4 ]
        )


clearScreen : Renderable
clearScreen =
    shapes [] []



-- SUBSCRIPTIONS
{- Only animate when required -}


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        animation =
            case model.painting of
                True ->
                    [ onAnimationFrameDelta Tick ]

                False ->
                    case model.paths of
                        -- head is a Path (list of Particle)
                        -- tail is list of Path
                        head :: tail ->
                            if (not <| List.isEmpty head) || (not <| List.isEmpty tail) then
                                [ onAnimationFrameDelta Tick ]

                            else
                                []

                        [] ->
                            []

        mouse =
            case model.painting of
                False ->
                    [ onMouseDown (D.map UserPressedMouseButton mouseMoveDecoder)
                    ]

                True ->
                    [ onMouseUp (D.succeed UserReleasedMouseButton)
                    , onMouseMove (D.map UserMovedMouse mouseMoveDecoder)
                    ]
    in
    Sub.batch <| animation ++ mouse



-- OTHER


type alias Vector =
    Point


subt : Point -> Point -> Vector
subt pos1 pos2 =
    ( (-) (Tuple.first pos1) (Tuple.first pos2)
    , (-) (Tuple.second pos1) (Tuple.second pos2)
    )


mult : Float -> Vector -> Vector
mult n v =
    ( (*) n <| Tuple.first v
    , (*) n <| Tuple.second v
    )



--
--import Array exposing (Array)
--import Browser.Events exposing (onAnimationFrameDelta)
--import Canvas exposing (..)
--import Canvas.Settings exposing (..)
--import Canvas.Settings.Advanced exposing (..)
--import Canvas.Settings.Line exposing (..)
--import Color exposing (Color)
--import ColorButtons exposing (getShadowColor)
--import Html exposing (Attribute, Html, button, div, p)
--import Html.Attributes exposing (style)
--import Html.Events exposing (onClick)
--import Html.Events.Extra.Mouse as Mouse
--import Html.Events.Extra.Touch as Touch
--import Json.Decode as Decode exposing (Decoder)
--
--
--subscriptions : Model -> Sub Msg
--subscriptions model =
--    onAnimationFrameDelta AnimationFrame
--
--
--h : number
--h =
--    400
--
--
--w : number
--w =
--    400
--
--
--padding : number
--padding =
--    20
--
--
--type alias DrawingPointer =
--    { previousMidpoint : Point, lastPoint : Point }
--
--
--type alias Model =
--    { frames : Int
--    , pending : Array Renderable
--    , toDraw : List Renderable
--    , drawingPointer : Maybe DrawingPointer
--    , color : Color
--    , size : Int
--    }
--
--
--type Msg
--    = AnimationFrame Float
--    | StartAt ( Float, Float )
--    | MoveAt ( Float, Float )
--    | EndAt ( Float, Float )
--    | SelectColor Color
--    | SelectSize Int
--
--
--init : () -> ( Model, Cmd Msg )
--init floatSeed =
--    ( { frames = 0
--      , pending = Array.empty
--      , toDraw = []
--      , drawingPointer = Nothing
--      , color = Color.lightBlue
--      , size = 10
--      }
--    , Cmd.none
--    )
--
--
--update : Msg -> Model -> ( Model, Cmd Msg )
--update msg ({ frames, drawingPointer, pending, toDraw } as model) =
--    ( case msg of
--        AnimationFrame delta ->
--            model
--                |> incFrames
--                |> flushPendingToDraw
--
--        StartAt point ->
--            initialPoint point model
--
--        MoveAt point ->
--            case drawingPointer of
--                Just pointer ->
--                    drawPoint point pointer model
--
--                Nothing ->
--                    model
--
--        EndAt point ->
--            case drawingPointer of
--                Just pointer ->
--                    finalPoint point pointer model
--
--                Nothing ->
--                    model
--
--        SelectColor color ->
--            selectColor color model
--
--        SelectSize size ->
--            selectSize size model
--    , Cmd.none
--    )
--
--
--incFrames : Model -> Model
--incFrames ({ frames } as model) =
--    { model | frames = frames + 1 }
--
--
--flushPendingToDraw : Model -> Model
--flushPendingToDraw ({ pending } as model) =
--    { model
--        | pending = Array.empty
--        , toDraw = Array.toList pending
--    }
--
--
--selectColor color model =
--    { model | color = color }
--
--
--selectSize size model =
--    { model | size = size }
--
--
--initialPoint : Point -> Model -> Model
--initialPoint (( x, y ) as point) model =
--    { model
--        | drawingPointer = Just { previousMidpoint = ( x, y ), lastPoint = ( x, y ) }
--    }
--
--
--drawPoint : Point -> DrawingPointer -> Model -> Model
--drawPoint newPoint { previousMidpoint, lastPoint } ({ pending } as model) =
--    let
--        newMidPoint =
--            controlPoint lastPoint newPoint
--    in
--    { model
--        | drawingPointer = Just { previousMidpoint = newMidPoint, lastPoint = newPoint }
--        , pending =
--            Array.push
--                (drawLine model
--                    [ path previousMidpoint [ quadraticCurveTo lastPoint newMidPoint ] ]
--                )
--                pending
--    }
--
--
--finalPoint point { previousMidpoint, lastPoint } ({ pending } as model) =
--    { model
--        | drawingPointer = Nothing
--        , pending =
--            Array.push
--                (drawLine model
--                    [ path previousMidpoint [ quadraticCurveTo lastPoint point ] ]
--                )
--                pending
--    }
--
--
--controlPoint : Point -> Point -> Point
--controlPoint ( x1, y1 ) ( x2, y2 ) =
--    ( x1 + (x2 - x1) / 2, y1 + (y2 - y1) / 2 )
--
--
--drawLine : Model -> List Shape -> Renderable
--drawLine { color, size } line =
--    line
--        |> shapes
--            [ lineCap RoundCap
--            , lineJoin RoundJoin
--            , lineWidth (toFloat size)
--            , shadow { blur = 10, offset = ( 0, 0 ), color = getShadowColor color }
--            , stroke color
--            ]
--
--
--view : Model -> Html Msg
--view { color, size, toDraw } =
--    div []
--        [ Canvas.toHtml ( w, h )
--            [ style "touch-action" "none"
--            , Mouse.onDown (.offsetPos >> StartAt)
--            , Mouse.onMove (.offsetPos >> MoveAt)
--            , Mouse.onUp (.offsetPos >> EndAt)
--
--            -- These 2 get annoying sometimes when painting
--            -- , Mouse.onLeave (.offsetPos >> EndAt)
--            -- , Mouse.onContextMenu (.offsetPos >> EndAt)
--            , onTouch "touchstart" (touchCoordinates >> StartAt)
--            , onTouch "touchmove" (touchCoordinates >> MoveAt)
--            , onTouch "touchend" (touchCoordinates >> EndAt)
--            ]
--            toDraw
--        , ColorButtons.view SelectColor SelectSize w color size
--        ]
--
--
--touchCoordinates : { event : Touch.Event, targetOffset : ( Float, Float ) } -> ( Float, Float )
--touchCoordinates { event, targetOffset } =
--    List.head event.changedTouches
--        |> Maybe.map
--            (\touch ->
--                let
--                    ( x, y ) =
--                        touch.pagePos
--
--                    ( x2, y2 ) =
--                        targetOffset
--                in
--                ( x - x2, y - y2 )
--            )
--        |> Maybe.withDefault ( 0, 0 )
--
--
--onTouch : String -> ({ event : Touch.Event, targetOffset : ( Float, Float ) } -> Msg) -> Attribute Msg
--onTouch event tag =
--    eventDecoder
--        |> Decode.map
--            (\ev ->
--                { message = tag ev
--                , preventDefault = True
--                , stopPropagation = True
--                }
--            )
--        |> Html.Events.custom event
--
--
--eventDecoder : Decoder { event : Touch.Event, targetOffset : ( Float, Float ) }
--eventDecoder =
--    Decode.map2
--        (\event offset ->
--            { event = event
--            , targetOffset = offset
--            }
--        )
--        Touch.eventDecoder
--        offsetDecoder
--
--
--offsetDecoder : Decoder ( Float, Float )
--offsetDecoder =
--    Decode.field "target"
--        (Decode.map2 (\top left -> ( left, top ))
--            (Decode.field "offsetTop" Decode.float)
--            (Decode.field "offsetLeft" Decode.float)
--        )
