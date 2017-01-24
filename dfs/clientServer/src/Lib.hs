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
--import Database.MongoDB.BSON
import qualified Data.Text    as T
import qualified Data.Text.IO as T

data User = User
    { username :: String
    , password  :: String
    } deriving (Eq, Show)
$(deriveJSON defaultOptions ''User)
type API = "users" :> Get '[JSON] [User]

data File = File
    { fileName :: String
    --, date :: 
    , fileContents :: String
} deriving (Eq, Show)
$(deriveJSON defaultOptions ''File)
--type API = "files" :> Get '[JSON] [File]

startApp :: IO ()
startApp = do 
    pipe <- connect (host "127.0.0.1")
    access pipe master "dbase" getUserInfo
    close pipe

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
    insertUsers user
    liftIO $ print "Created new user"
    getCommand

insertUsers :: User -> Action IO ()
insertUsers user = do
  let doc = userToDoc user
  contactIds <- (insert "contacts" doc)
  return ()

userToDoc :: User -> Document
userToDoc (User {username = uN, password = pW}) =
  ["username" =: (T.pack uN), "password" =: (T.pack pW)]

getCommand = do
    liftIO $ print "'upload' or 'download'"
    command <- liftIO getLine
    compareCommands command

compareCommands :: String -> Action IO ()
compareCommands command
    | command == "upload" = uploadFile
    | otherwise = do
        liftIO $ print "Chose to download"
        download

uploadFile :: Action IO ()
uploadFile = do
    liftIO $ print "Enter name of file: "  
    fileName <- liftIO getLine
    checkFilenameExists fileName
    fileContents <- liftIO (readFile fileName)
    let file = File fileName fileContents
    insertFile file
    liftIO $ print "Creating new file"
    return ()

insertFile :: File -> Action IO ()
insertFile file = do
  let doc = fileToDoc file
  fileIds <- (insert "files" doc)
  return ()

fileToDoc :: File -> Document
fileToDoc (File {fileName = fN, fileContents = fC}) =
  ["fileName" =: (T.pack fN), "fileContents" =: (T.pack fC)]

download = do
    liftIO $ print "Enter name of file to download: "  
    fileName <- liftIO getLine
    findFile fileName >>= printDocs "Found this: "

findFile :: String -> Action IO [Document]
findFile fileName = rest =<< find (select ["fileName" =: fileName] "files")

printDocs :: String -> [Document] -> Action IO ()
printDocs title docs = liftIO $ putStrLn title >> mapM_ (print . exclude ["_id"]) docs

checkFilenameExists :: String -> Action IO ()--[Document]
checkFilenameExists name = do
    tmp <- rest =<< find (select ["fileName" =: name] "files")
    --rest =<< find (select ["fileName" =: name] "files")
    exists tmp

exists :: [Document] -> Action IO ()
exists str
    | str == [] = return ()
    | otherwise = fileAlreadyExists

fileAlreadyExists = do
    liftIO $ print "Already exists a file with that name in the database"
    uploadFile  