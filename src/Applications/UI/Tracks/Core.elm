module UI.Tracks.Core exposing (Model, Msg(..), Scene(..))

import Html.Events.Extra.Mouse as Mouse
import InfiniteList
import Json.Encode as Json
import Playlists exposing (Playlist)
import Tracks exposing (..)
import UI.DnD as DnD
import UI.Reply exposing (Reply)



-- 🌳


type alias Model =
    { collection : Collection
    , enabledSourceIds : List String
    , favourites : List Favourite
    , favouritesOnly : Bool
    , grouping : Maybe Grouping
    , hideDuplicates : Bool
    , nowPlaying : Maybe IdentifiedTrack
    , scene : Scene
    , searchResults : Maybe (List String)
    , searchTerm : Maybe String
    , selectedPlaylist : Maybe Playlist
    , sortBy : SortBy
    , sortDirection : SortDirection

    -----------------------------------------
    -- Scenes / List
    -----------------------------------------
    , infiniteList : InfiniteList.Model
    , listDnD : DnD.Model Int
    }



-- 📣


type Msg
    = Bypass
    | Reply (List Reply)
    | ScrollToNowPlaying
    | SetEnabledSourceIds (List String)
    | SetNowPlaying (Maybe IdentifiedTrack)
    | SortBy SortBy
    | ToggleHideDuplicates
      -----------------------------------------
      -- Collection
      -----------------------------------------
    | Add Json.Value
    | RemoveByPaths Json.Value
    | RemoveBySourceId String
      -----------------------------------------
      -- Favourites
      -----------------------------------------
    | ToggleFavourite Int
    | ToggleFavouritesOnly
      -----------------------------------------
      -- Groups
      -----------------------------------------
    | DisableGrouping
    | GroupBy Grouping
      -----------------------------------------
      -- Menus
      -----------------------------------------
    | ShowTrackMenu IdentifiedTrack Mouse.Event
    | ShowViewMenu (Maybe Grouping) Mouse.Event
      -----------------------------------------
      -- Playlists
      -----------------------------------------
    | DeselectPlaylist
    | SelectPlaylist Playlist
      -----------------------------------------
      -- Scenes / List
      -----------------------------------------
    | InfiniteListMsg InfiniteList.Model
    | ListDragAndDropMsg (DnD.Msg Int)
      -----------------------------------------
      -- Search
      -----------------------------------------
    | ClearSearch
    | Search
    | SetSearchResults Json.Value
    | SetSearchTerm String



-- OTHER


type Scene
    = List
