module UI.Tracks.Covers exposing (..)

import Base64
import Conditional exposing (ifThenElse)
import List.Extra as List
import Maybe.Extra as Maybe
import Tracks exposing (..)



-- 🔱


generate :
    SortBy
    -> Maybe Cover
    -> Tracks.Collection
    -> { collection : CoverCollection, selectedCover : Maybe Cover }
generate sortBy previouslySelectedCover tracks =
    let
        groupFn =
            coverGroup sortBy

        makeCoverFn =
            makeCover sortBy
    in
    tracks.arranged
        |> List.indexedFoldr
            (\idx identifiedTrack { covers, gathering } ->
                let
                    group =
                        groupFn identifiedTrack

                    ( identifiers, track ) =
                        identifiedTrack

                    { artist, album } =
                        track.tags
                in
                if group /= gathering.previousGroup then
                    -- New group, make cover for previous group
                    let
                        { collection, selectedCover } =
                            makeCoverFn gathering covers previouslySelectedCover
                    in
                    { gathering =
                        { acc = [ identifiedTrack ]
                        , accIds = [ track.id ]
                        , previousGroup = group
                        , previousTrack = track
                        , selectedCover = selectedCover

                        --
                        , currentAlbumSequence = Just ( identifiedTrack, 1 )
                        , largestAlbumSequence = Nothing

                        --
                        , currentAlbumFavsSequence = Just ( identifiedTrack, ifThenElse identifiers.isFavourite 1 0 )
                        , largestAlbumFavsSequence = Nothing

                        --
                        , currentArtistSequence = Just ( identifiedTrack, 1 )
                        , largestArtistSequence = Nothing
                        }
                    , covers =
                        collection
                    }

                else
                    -- Same group
                    { gathering =
                        { acc = identifiedTrack :: gathering.acc
                        , accIds = track.id :: gathering.accIds
                        , previousGroup = group
                        , previousTrack = track
                        , selectedCover = gathering.selectedCover

                        -- Album sequence
                        -----------------
                        , currentAlbumSequence =
                            if album /= gathering.previousTrack.tags.album then
                                Just ( identifiedTrack, 1 )

                            else
                                increaseSequence gathering.currentAlbumSequence

                        --
                        , largestAlbumSequence =
                            if album /= gathering.previousTrack.tags.album then
                                resolveLargestSequence
                                    gathering.currentAlbumSequence
                                    gathering.largestAlbumSequence

                            else
                                gathering.largestAlbumSequence

                        -- Album favourites sequence
                        ----------------------------
                        , currentAlbumFavsSequence =
                            if album /= gathering.previousTrack.tags.album then
                                Just ( identifiedTrack, ifThenElse identifiers.isFavourite 1 0 )

                            else if identifiers.isFavourite then
                                increaseSequence gathering.currentAlbumFavsSequence

                            else
                                gathering.currentAlbumFavsSequence

                        --
                        , largestAlbumFavsSequence =
                            if album /= gathering.previousTrack.tags.album then
                                resolveLargestSequence
                                    gathering.currentAlbumFavsSequence
                                    gathering.largestAlbumFavsSequence

                            else
                                gathering.largestAlbumFavsSequence

                        -- Artist sequence
                        ------------------
                        , currentArtistSequence =
                            if artist /= gathering.previousTrack.tags.artist then
                                Just ( identifiedTrack, 1 )

                            else
                                increaseSequence gathering.currentArtistSequence

                        --
                        , largestArtistSequence =
                            if artist /= gathering.previousTrack.tags.artist then
                                resolveLargestSequence
                                    gathering.currentArtistSequence
                                    gathering.largestArtistSequence

                            else
                                gathering.largestArtistSequence
                        }
                    , covers =
                        covers
                    }
            )
            { covers =
                []
            , gathering =
                { acc = []
                , accIds = []
                , previousGroup = ""
                , previousTrack = emptyTrack
                , selectedCover = Nothing

                --
                , currentAlbumSequence = Nothing
                , largestAlbumSequence = Nothing
                , currentAlbumFavsSequence = Nothing
                , largestAlbumFavsSequence = Nothing
                , currentArtistSequence = Nothing
                , largestArtistSequence = Nothing
                }
            }
        |> (\{ covers, gathering } ->
                makeCoverFn gathering covers previouslySelectedCover
           )
        |> (\{ collection, selectedCover } ->
                { collection = { arranged = collection, harvested = [] }
                , selectedCover = selectedCover
                }
           )


harvest : SortBy -> Tracks.Collection -> CoverCollection -> List Cover
harvest sortBy tracks covers =
    let
        groupFn =
            coverGroup sortBy

        ( _, groups ) =
            List.foldr
                (\identifiedTrack ( previousGroup, acc ) ->
                    let
                        group =
                            groupFn identifiedTrack
                    in
                    ( group
                    , if group /= previousGroup then
                        group :: acc

                      else
                        acc
                    )
                )
                ( "", [] )
                tracks.harvested
    in
    List.filter
        (\cover -> List.member cover.group groups)
        covers.arranged



-- ⚗️


coverGroup : SortBy -> IdentifiedTrack -> String
coverGroup sort ( identifiers, { tags } as track ) =
    (case sort of
        Artist ->
            tags.artist

        Album ->
            -- There is the possibility of albums with the same name,
            -- such as "Greatests Hits".
            -- To make sure we treat those as different albums,
            -- we prefix the album by its parent directory.
            identifiers.parentDirectory ++ tags.album

        PlaylistIndex ->
            ""

        Title ->
            tags.title
    )
        |> String.trim
        |> String.toLower


coverKey : Bool -> Track -> String
coverKey isVariousArtists { tags } =
    if isVariousArtists then
        tags.album

    else
        tags.artist ++ " --- " ++ tags.album


makeCover sortBy_ gathering collection previouslySelectedCover =
    let
        closedGathering =
            { gathering
                | largestAlbumSequence =
                    resolveLargestSequence
                        gathering.currentAlbumSequence
                        gathering.largestAlbumSequence

                --
                , largestAlbumFavsSequence =
                    resolveLargestSequence
                        gathering.currentAlbumFavsSequence
                        gathering.largestAlbumFavsSequence

                --
                , largestArtistSequence =
                    resolveLargestSequence
                        gathering.currentArtistSequence
                        gathering.largestArtistSequence
            }
    in
    case closedGathering.acc of
        [] ->
            { collection = collection
            , selectedCover = closedGathering.selectedCover
            }

        fallback :: _ ->
            let
                cover =
                    makeCoverWithFallback sortBy_ closedGathering fallback
            in
            { collection =
                cover :: collection
            , selectedCover =
                case ( previouslySelectedCover, closedGathering.selectedCover ) of
                    ( Nothing, _ ) ->
                        Nothing

                    ( Just _, Just _ ) ->
                        closedGathering.selectedCover

                    ( Just sc, Nothing ) ->
                        case sortBy_ of
                            Artist ->
                                if cover.group == sc.group then
                                    Just cover

                                else
                                    Nothing

                            _ ->
                                if cover.key == sc.key then
                                    Just cover

                                else
                                    Nothing
            }


makeCoverWithFallback sortBy_ gathering fallback =
    let
        amountOfTracks =
            List.length gathering.accIds

        group =
            gathering.previousGroup

        identifiedTrack =
            gathering.largestAlbumFavsSequence
                |> Maybe.orElse gathering.largestAlbumSequence
                |> Maybe.map Tuple.first
                |> Maybe.withDefault fallback

        ( identifiers, track ) =
            identifiedTrack

        ( largestAlbumSequence, largestArtistSequence ) =
            ( Maybe.unwrap 0 Tuple.second gathering.largestAlbumSequence
            , Maybe.unwrap 0 Tuple.second gathering.largestArtistSequence
            )

        ( sameAlbum, sameArtist ) =
            ( largestAlbumSequence == amountOfTracks
            , largestArtistSequence == amountOfTracks
            )

        isVariousArtists =
            False
                || (amountOfTracks > 4 && largestArtistSequence < 3)
                || (String.toLower track.tags.artist == "va")
    in
    { key = Base64.encode (coverKey isVariousArtists track)
    , identifiedTrackCover = identifiedTrack

    --
    , focus =
        case sortBy_ of
            Artist ->
                "artist"

            _ ->
                "album"

    --
    , group = group
    , sameAlbum = sameAlbum
    , sameArtist = sameArtist

    --
    , trackIds = gathering.accIds
    , tracks = gathering.acc
    , variousArtists = isVariousArtists
    }



-- ⚗️  ░░  SEQUENCES


increaseSequence =
    Maybe.map (Tuple.mapSecond ((+) 1))


resolveLargestSequence curr state =
    case ( curr, state ) of
        ( Just ( _, c ), Just ( _, s ) ) ->
            ifThenElse (c > s) curr state

        ( Just _, Nothing ) ->
            curr

        ( Nothing, Just _ ) ->
            state

        ( Nothing, Nothing ) ->
            Nothing