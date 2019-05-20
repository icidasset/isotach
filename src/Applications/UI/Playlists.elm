module UI.Playlists exposing (Model, Msg(..), initialModel, update, view)

import Chunky exposing (..)
import Color
import Color.Ext as Color
import Css
import Html.Styled exposing (Html, text)
import Html.Styled.Attributes exposing (css, style)
import Material.Icons exposing (Coloring(..))
import Material.Icons.Content as Icons
import Material.Icons.File as Icons
import Material.Icons.Navigation as Icons
import Playlists exposing (..)
import Return3 exposing (..)
import Tachyons.Classes as T
import UI.Kit
import UI.List
import UI.Navigation exposing (..)
import UI.Page
import UI.Playlists.Page exposing (Page(..))
import UI.Reply exposing (Reply(..))



-- 🌳


type alias Model =
    { collection : List Playlist }


initialModel : Model
initialModel =
    { collection = [] }



-- 📣


type Msg
    = Activate Playlist
    | Bypass
    | Deactivate


update : Msg -> Model -> Return Model Msg Reply
update msg model =
    case msg of
        Activate playlist ->
            returnRepliesWithModel
                model
                [ ActivatePlaylist playlist
                , GoToPage UI.Page.Index
                ]

        Bypass ->
            return model

        Deactivate ->
            returnReplyWithModel
                model
                DeactivatePlaylist



-- 🗺


view : Page -> Maybe Playlist -> Model -> Html Msg
view page selectedPlaylist model =
    UI.Kit.receptacle
        (case page of
            Index ->
                index selectedPlaylist model
        )



-- INDEX


index : Maybe Playlist -> Model -> List (Html Msg)
index selectedPlaylist model =
    let
        selectedPlaylistName =
            Maybe.map .name selectedPlaylist
    in
    [ -----------------------------------------
      -- Navigation
      -----------------------------------------
      UI.Navigation.local
        [ ( Icon Icons.arrow_back
          , Label "Back to list" Hidden
          , NavigateToPage UI.Page.Index
          )
        , ( Icon Icons.add
          , Label "Create a new playlist" Shown
            -- TODO
          , PerformMsg Bypass
          )
        ]

    -----------------------------------------
    -- Content
    -----------------------------------------
    , UI.Kit.canister
        [ UI.Kit.h1 "Playlists"

        -- Intro
        --------
        , intro

        -- Directory Playlists
        ----------------------
        , category "Autogenerated Directory Playlists"
        , model.collection
            |> List.filter .autoGenerated
            |> List.map
                (\p ->
                    if selectedPlaylistName == Just p.name then
                        { label =
                            brick
                                [ style "color" (Color.toCssString UI.Kit.colorKit.accent) ]
                                []
                                [ text p.name ]
                        , actions =
                            [ { color = Color UI.Kit.colorKit.accent
                              , icon = Icons.check
                              , msg = Nothing
                              , title = "Selected playlist"
                              }
                            ]
                        , msg = Just Deactivate
                        }

                    else
                        { label = text p.name
                        , actions = []
                        , msg = Just (Activate p)
                        }
                )
            |> UI.List.view UI.List.Normal
        ]
    ]


intro : Html Msg
intro =
    [ text "Playlists are not tied to the sources of its tracks."
    , lineBreak
    , text "Same goes for favourites."
    ]
        |> raw
        |> UI.Kit.intro


category : String -> Html Msg
category cat =
    brick
        [ css categoryStyles ]
        [ T.f7, T.mb3, T.mt4, T.truncate, T.ttu ]
        [ UI.Kit.inlineIcon Icons.folder
        , inline [ T.fw7, T.ml2 ] [ text cat ]
        ]


categoryStyles : List Css.Style
categoryStyles =
    [ Css.color (Color.toElmCssColor UI.Kit.colorKit.base06)
    , Css.fontFamilies UI.Kit.headerFontFamilies
    , Css.fontSize (Css.px 11)
    ]