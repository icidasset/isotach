module UI.Sources exposing (Model, Msg(..), initialModel, update, view)

import Chunky exposing (..)
import Dict.Ext as Dict
import Html.Styled as Html exposing (Html, text)
import Material.Icons.Content as Icons
import Material.Icons.Navigation as Icons
import Material.Icons.Notification as Icons
import Replying exposing (R3D3)
import Return3
import Sources exposing (..)
import Sources.Services as Services
import Tachyons.Classes as T
import UI.Kit exposing (ButtonType(..), select)
import UI.List
import UI.Navigation exposing (..)
import UI.Page as Page
import UI.Reply exposing (Reply)
import UI.Sources.Form as Form



-- 🌳


type alias Model =
    { collection : List Source
    , form : Form.Model
    }


initialModel : Model
initialModel =
    { collection = []
    , form = Form.initialModel
    }



-- 📣


type Msg
    = Bypass
      -----------------------------------------
      -- Collection
      -----------------------------------------
    | AddToCollection Source
      -----------------------------------------
      -- Children
      -----------------------------------------
    | FormMsg Form.Msg


update : Msg -> Model -> R3D3 Model Msg Reply
update msg model =
    case msg of
        Bypass ->
            model
                |> Return3.withNothing

        -----------------------------------------
        -- Collection
        -----------------------------------------
        AddToCollection source ->
            source
                |> List.singleton
                |> List.append model.collection
                |> (\c -> { model | collection = c })
                |> Return3.withNothing

        -----------------------------------------
        -- Children
        -----------------------------------------
        FormMsg sub ->
            model.form
                |> Form.update sub
                |> Return3.mapModel (\f -> { model | form = f })
                |> Return3.mapCmd FormMsg



-- 🗺


view : Sources.Page -> Model -> Html Msg
view page model =
    UI.Kit.vessel
        (case page of
            Index ->
                index model

            New ->
                List.map (Html.map FormMsg) (Form.new model.form)
        )



-- INDEX


index : Model -> List (Html Msg)
index model =
    [ -----------------------------------------
      -- Navigation
      -----------------------------------------
      UI.Navigation.local
        [ ( Icon Icons.add
          , Label "Add a new source" Shown
          , GoToPage (Page.Sources New)
          )
        , ( Icon Icons.sync
          , Label "Process sources" Shown
          , PerformMsg Bypass
          )
        ]

    -----------------------------------------
    -- Content
    -----------------------------------------
    , UI.Kit.canister
        [ UI.Kit.h1 "Sources"

        -- Intro
        --------
        , [ text "A source is a place where your music is stored."
          , lineBreak
          , text "By connecting a source, the application will scan it and keep a list of all the music in it."
          , lineBreak
          , text "It will not copy anything."
          ]
            |> Html.span []
            |> UI.Kit.intro

        -- List
        -------
        , model.collection
            |> List.map (\s -> { label = Dict.fetch "name" "" s.data, actions = [] })
            |> UI.List.view
        ]
    ]