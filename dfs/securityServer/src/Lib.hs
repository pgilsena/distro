{-# LANGUAGE DataKinds       #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE TypeOperators   #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ExtendedDefaultRules #-}

module Lib
    ( startApp
    ) where

import Data.Aeson
import Data.Aeson.TH
import Network.Wai
import Network.Wai.Handler.Warp
import Servant
import Control.Monad
import Control.Monad.Trans.Except
import Data.Char
import GHC.Generics
import System.IO
import Database.MongoDB    (Action, Document, Document, Value, access,
                            close, connect, delete, exclude, find,
                            host, insertMany, master, project, rest,
                            select, sort, (=:))
import Control.Monad.Trans (liftIO)

startApp :: IO ()
startApp = do
    pipe <- connect (host "127.0.0.1")
    e <- access pipe master "directory" runIt
    close pipe

data User = User
  { userId :: Int
  , username :: String
  } deriving (Eq, Show)

$(deriveJSON defaultOptions ''User)

data Token = Token
	{ ticket :: String
	,	sessionKey :: String
	,	serverID :: Int
	, timeout :: Int
	} deriving (Show)

$(deriveJSON defaultOptions ''Token)
-- ticket: contains copy of session key (encrypted with server encryption key)
-- sessionKey: random key (encrypts communication between client and server)
-- serverID: id of server ticket is for
-- timeout: timeout period for the ticket


--
-- authentication work
--
type Username = Text
type Password = Text

auth :: MonadIO m => Username -> Password -> Action m Bool

--
-- user functions
--
insert :: MonadIO m => Collection -> Document -> Action m Value
