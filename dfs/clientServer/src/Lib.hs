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
import Network
import Network.Wai
import Network.Wai.Handler.Warp
import Servant
import Control.Monad
import Control.Monad.Trans.Except
import Data.Char
import GHC.Generics
import System.IO
import System.Environment (getArgs)
import Database.MongoDB    (Action, Document, Document, Value, access,
                            close, connect, delete, exclude, find,
                            host, insert, insertMany, master, project, rest,
                            select, sort, (=:))
--import Database.MongoDB.BSON
import Control.Monad.Trans (liftIO)

data User = User
  { username :: String
  , password  :: String
  } deriving (Eq, Show)

$(deriveJSON defaultOptions ''User)

type API = "users" :> Get '[JSON] [User]

startApp :: IO ()
startApp = do 
	getUserInfo
	sendActions

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

getUserInfo :: IO ()
getUserInfo = do  
    putStrLn "Enter username: "  
    username <- getLine  
    putStrLn "Enter password: "  
    password1 <- getLine
    putStrLn "Repeat password: "  
    password2 <- getLine  
    compareStr username password1 password2

compareStr :: String -> String -> String -> IO ()
compareStr username pwd1 pwd2
	| pwd1 == pwd2 = createUser username pwd1
    | otherwise = do
    	putStr "Passwords did not match"
    	getUserInfo

createUser :: String -> String -> IO()
createUser username password = do
	let user = User username password
	let user2 = ["username" =: username, "password" =: password]
	-- run $ insert "usersDB" 456 user2
	return ()

-- userMsg = putStr "User created"

sendActions = do
    putStrLn "Enter 'upload' or 'download'"  
    command <- getLine
    checkCommand command

checkCommand :: String -> IO ()
checkCommand "upload" = uploadFile
checkCommand "download" = downloadFile
checkCommand x = errorInput

uploadFile = do
    putStrLn "Enter name of file: "
    fileName <- getLine
    file <- readFile fileName 
    putStr (map toUpper file)
    -- fileExist :: FilePath -> IO Bool -- check if file path exists

downloadFile = putStrLn "download"
errorInput = putStrLn "error"