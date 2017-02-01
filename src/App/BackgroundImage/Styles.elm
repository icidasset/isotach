module BackgroundImage.Styles exposing (..)

import Css exposing (..)


type Classes
    = BackgroundImage


styles : List Snippet
styles =
    [ class BackgroundImage
        [ backgroundPosition center
        , backgroundRepeat noRepeat
        , backgroundSize (pct 110)
        , height (vh 100)
        , left zero
        , position fixed
        , top zero
        , width (vw 100)
        , zIndex (int -10)
        ]
    ]
