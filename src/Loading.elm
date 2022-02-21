module Loading exposing (loading)

import Asset
import Html.Styled exposing (Html, div, img, text)
import Html.Styled.Attributes exposing (css, src)
import Tailwind.Utilities as T


loading : Html msg
loading =
    div [ css [ T.text_center, T.p_10 ] ]
        [ text "loading..." ]
