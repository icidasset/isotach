module Slave.Types exposing (..)

-- Children

import Sources.Processing.Types


-- Messages


type Msg
    = Extraterrestrial AlienMsg AlienResult
      --
      -- Children
    | SourceProcessingMsg Sources.Processing.Types.Msg



-- Talking to the outside world


type AlienMsg
    = ProcessSources


type alias AlienResult =
    Result String Json.Encode.Value
