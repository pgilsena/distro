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
import Control.Monad.Trans.Except
import Data.Aeson
import Data.Aeson.TH
import Data.Char
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

startApp :: IO ()
startApp = do 
    pipe <- connect (host "127.0.0.1")
    e <- access pipe master "usersDB" getUserInfo
    sendActions
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
    liftIO $ print "Enter password: "
    pwd1 <- liftIO getLine
    liftIO $ print "Repeat password: "
    pwd2 <- liftIO getLine
    compareStr username pwd1 pwd2

compareStr :: String -> String -> String -> Action IO ()
compareStr username pwd1 pwd2
    | pwd1 == pwd2 = createUser username pwd1
    | otherwise = do
        liftIO $ print "Passwords did not match"
        getUserInfo

createUser :: String -> String -> Action IO ()
createUser username password = do
    let user = User username password
    let user2 = ["username" =: username, "password" =: password]
    liftIO $ print "Created new user"
    return ()

sendActions = do
    liftIO $ print "Enter 'upload' or 'download'"  
    command <- liftIO getLine
    checkCommand command

checkCommand :: String -> IO ()
checkCommand "upload" = uploadFile
checkCommand "download" = downloadFile
checkCommand x = do
    liftIO $ print "'upload' or 'download' not recognised"
    sendActions 

uploadFile = do
    liftIO $ print "Enter name of file: "  
    fileName <- getLine
    file <- readFile fileName 
    putStr (map toUpper file)

downloadFile = liftIO $ print "download"
errorInput = putStrLn "error"
