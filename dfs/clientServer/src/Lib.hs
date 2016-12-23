{-# LANGUAGE DataKinds       #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE TypeOperators   #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ExtendedDefaultRules #-}

module Lib
    ( startApp
    ) where


import Control.Applicative
import Control.Monad
import Control.Monad.IO.Class
import Control.Monad.Trans (liftIO)
--import Control.Monad.Trans.Either
import Control.Monad.Trans.Except
import Data.Aeson
import Data.Aeson.TH
import Data.Char
--import Data.CompactString ()  -- only needed when using ghci
import Data.Monoid
import Data.Proxy
import Data.Text (Text)
import Data.Map (Map)
import qualified Data.Map as Map
import GHC.Generics
import Network
import Network.Wai
import Network.Wai.Handler.Warp
import Servant
import Servant.API
--import Servant.Client
import System.IO
import System.Environment (getArgs)
import Text.Printf
import Database.MongoDB    (Action, Document, Value, access,
                            close, connect, delete, exclude, find,
                            host, insert, insertMany, master, project, rest,
                            select, sort, (=:))

import qualified Data.Text    as T
import qualified Data.Text.IO as T

data User = User
    { username :: String
    , password  :: String
    } deriving (Eq, Show)

$(deriveJSON defaultOptions ''User)

type API = "users" :> Get '[JSON] [User]

{-startApp :: IO ()
startApp = do 
    getUserInfo
    sendActions-}

--type Handler a = EitherT ServantErr IO a

startApp :: IO ()
startApp = do 
    pipe <- connect (host "127.0.0.1")
    e <- access pipe master "usersDB" getUserInfo
    close pipe
    print e

app :: Application
app = serve api server

api :: Proxy API
api = Proxy

server :: Server API
server = return users

users :: [User]
users = [ User "Isaac" "Newton"
        , User "Albert" "Einstein"
        ]

getUserInfo :: Action IO ()
getUserInfo = do
    liftIO $ print "Enter username: "
    username <- liftIO getLine
    compareStr username

compareStr :: String -> Action IO ()
compareStr username = do
    liftIO $ print "Username is: "
    liftIO $ print username
    getUserInfo
