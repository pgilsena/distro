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
import System.Directory
import System.IO
import System.Environment (getArgs)
import Text.Printf
import Database.MongoDB    (Action, Document, Label, Value, access,
                            close, connect, delete, exclude, find, findOne,
                            host, insert, insertMany, master, project,replace,                            rest, select, sort, typed, valueAt, (=:))
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
    , fileLock :: Bool
} deriving (Eq, Show)
$(deriveJSON defaultOptions ''File)
--type API = "files" :> Get '[JSON] [File]

startApp :: IO ()
startApp = do 
    pipe <- connect (host "127.0.0.1")
    access pipe master "dbase" firstPrompt
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

firstPrompt = do
    liftIO $ print "'signup' or 'login'"
    command <- liftIO getLine
    signInOrLogIn command

signInOrLogIn command
    | command == "signup" = getUserInfo
    | command == "login" = getLoginDetails
    | otherwise = do
        liftIO $ print "Didn't recognise command, try again"
        firstPrompt

getLoginDetails = do
    liftIO $ print "Enter username: "
    username <- liftIO getLine
    liftIO $ print "Enter password: "
    pwd <- liftIO getLine
    tmp username pwd

tmp :: String -> String -> Action IO ()
tmp username pwd = checkDB4usr username pwd

checkDB4usr :: String -> String -> Action IO ()
checkDB4usr name pwd = do 
    result <- rest =<< find (select ["username" =: name, "password" =: pwd] "contacts")
    checkUserDetails result

checkUserDetails :: [Document] -> Action IO ()
checkUserDetails docs
    | docs == [] = getLoginDetails
    | otherwise = getCommand

getUserInfo = do
    liftIO $ print "Enter username: "
    username <- liftIO getLine
    liftIO $ print "Enter password: "
    pwd1 <- liftIO getLine
    liftIO $ print "Repeat password: "
    pwd2 <- liftIO getLine
    comparePasswords username pwd1 pwd2

comparePasswords :: String -> String -> String -> Action IO ()
comparePasswords username pwd1 pwd2
    | pwd1 == pwd2 = createUser username pwd1
    | otherwise = do
        liftIO $ print "Passwords did not match"
        getUserInfo

createUser :: String -> String -> Action IO ()
createUser username password = do
    let user = User username password
    let doc = userToDoc user
    contactIds <- (insert "contacts" doc)
    liftIO $ print "Created new user"
    getCommand

userToDoc :: User -> Document
userToDoc (User {username = uN, password = pW}) =
  ["username" =: (T.pack uN), "password" =: (T.pack pW)]

getCommand = do
    liftIO $ print "'upload', 'download' or 'delete' file"
    command <- liftIO getLine
    compareCommands command

compareCommands :: String -> Action IO ()
compareCommands command
    | command == "upload" = uploadFile
    | command == "download" = download
    | command == "delete" = deleteFile
    | otherwise = do
        liftIO $ print "Didn't recognise command, try again"
        getCommand

uploadFile :: Action IO ()
uploadFile = do
    liftIO $ print "Enter name of file: "  
    fileName <- liftIO getLine
    checkFilenameExists fileName
    fileContents <- liftIO (readFile fileName)
    let fileLock = False
    let file = File fileName fileContents fileLock
    let doc = fileToDoc file
    fileIds <- (insert "files" doc)
    liftIO $ print "Uploading file"
    getCommand

fileToDoc :: File -> Document
fileToDoc (File {fileName = fN, fileContents = fC, fileLock = fL}) =
  ["fileName" =: (T.pack fN), "fileContents" =: (T.pack fC), "fileLock" =: fL]

download = do
    liftIO $ print "Enter name of file to download: "  
    fileName <- liftIO getLine
    file <- findFileToDownload fileName
    downloadExists file
    liftIO $ print "Found file"  
    let fileLock = lockExists file
    checkLock fileLock
    let contents = contentExists file
    downloadFile fileName contents
    requestLockCommand
    changeLock fileName contents fileLock
    getCommand

requestLockCommand = do
    liftIO $ print "Would you lock the file so others can't edit it?"
    lockResponse <- liftIO getLine
    lockOrNot lockResponse

lockOrNot :: String -> Action IO ()
lockOrNot response 
    | response == "yes" = return ()
    | response == "no" = getCommand
    | otherwise =  do
        liftIO $ print "Didn't recognise command, try again"
        requestLockCommand

downloadFile :: String -> String -> Action IO ()
downloadFile fileName fileContents = do
    filePath <- liftIO $ System.Directory.getUserDocumentsDirectory
    let fPath = filePath ++ fileName
    liftIO (writeFile fileName fileContents)
    return ()

contentExists :: Maybe Document -> String
contentExists file = case file of
    Just file -> getFileContent "fileContents" file
    Nothing -> "File is empty"

getFileContent :: Label -> Document -> String
getFileContent label = do
    typed . (valueAt label)

getLock :: Label -> Document -> Bool
getLock label = do
    typed . (valueAt label)  

findFileToDownload :: String -> Action IO (Maybe Document)
findFileToDownload fileName = findOne (select ["fileName" =: fileName] "files")

lockExists :: Maybe Document -> Bool
lockExists file = case file of
    Just file -> getLock "fileLock" file
    Nothing -> False

checkLock :: Bool -> Action IO ()
checkLock lock
    | lock == True = do
        liftIO $ print "There is a lock on the file, you can download it, but can't upload changes" 
        return ()
    | lock == False = do
        liftIO $ print "There is no lock on the file"  
        return ()

changeLock :: String -> String -> Bool -> Action IO ()
changeLock fileName fileContent fileLock
    | fileLock == True = return ()
    | fileLock == False = do
        fileToChange <- findFileToDownload fileName
        let fileWithChange = File fileName fileContent True
        let doc = fileToDoc fileWithChange
        replace (select ["fileName" =: fileName] "files") doc
        --replace fileToChange doc
        liftIO $ print "Lock applied to file"  
        getCommand

downloadExists :: Maybe Document -> Action IO ()
downloadExists file = case file of
    Just file -> return ()
    Nothing -> do
        liftIO $ print "No file matches that name in database"
        download  

exists :: [Document] -> Action IO ()
exists str
    | str == [] = return ()
    | otherwise = fileAlreadyExists

fileAlreadyExists = do
    liftIO $ print "Already exists a file with that name in the database"
    uploadFile

printDocs :: String -> [Document] -> Action IO ()
printDocs title docs = do
    liftIO $ putStrLn title >> mapM_ (print . exclude ["_id"]) docs
    return()

checkFilenameExists :: String -> Action IO ()
checkFilenameExists name = do
    tmp <- rest =<< find (select ["fileName" =: name] "files")
    exists tmp

encryptSessionKey :: String -> Int -> [String]
encryptSessionKey strToEncrypt shiftBy = do
  let strToNum = map ord strToEncrypt
  let plusKey = map (+shiftBy) strToNum 
  let numToChar = map chr plusKey
  return numToChar

decryptSessionKey :: String -> Int -> [String]
decryptSessionKey strToDecrypt shiftBy = do
    let strToNum = map ord strToDecrypt
    let minusKey = map (+(-shiftBy)) strToNum 
    let numToChar = map chr minusKey
    return numToChar

deleteFile = do
    liftIO $ print "Enter name of file: "  
    fileName <- liftIO getLine 
    tmp <- rest =<< find (select ["fileName" =: fileName] "files")
    deleteExists tmp
    deleteEntry fileName
    getCommand

deleteExists :: [Document] -> Action IO ()
deleteExists str
    | str /= [] = return ()
    | otherwise = do 
        liftIO $ print "File not in database"  
        deleteFile

deleteEntry file = delete (select ["fileName" =: (T.pack file)] "files")