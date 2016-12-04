{-# LANGUAGE DataKinds       #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeOperators   #-}
module Lib
    ( startApp
    ) where

import Data.Aeson
import Data.Aeson.TH
import Network.Wai
import Network.Wai.Handler.Warp
import Servant
import System.IO

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

type API = "users" :> Get '[JSON] [User]

startApp :: IO ()
startApp = run 8080 app

app :: Application
app = serve api server

api :: Proxy API
api = Proxy

server :: Server API
server = return users

users :: [User]
users = [ User 1 "Isaac" "Newton"
        , User 2 "Albert" "Einstein"
        ]
