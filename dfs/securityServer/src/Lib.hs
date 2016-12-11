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
import Data.Char
import Data.Map (Map)
import qualified Data.Map as Map
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
import Control.Monad.Trans (liftIO)
import Data.Text (pack, Text)

data User = User
  { userID :: Int
  , username :: String
  , password :: String
  } deriving (Eq, Show)
$(deriveJSON defaultOptions ''User)

data Token = Token
  { ticket :: String -- contains copy of session key, encrypted w/ server encryption key known only by SS and server
  , sessionKey :: Int -- key generated at random to encrypt + decrypt communication client <-> server
  , serverID :: Int
  , timeout :: Int
  } deriving (Eq, Show) 
-- token itself encrypted with key derived from user's password
$(deriveJSON defaultOptions ''Token)

data SessionKey = SessionKey
  { key :: Int
  } deriving (Eq, Show)

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
users = [ User 1 "Isaac Newton" "inPassword"
        , User 2 "Albert Einstein" "aePassword"
        ]

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

{-startApp :: IO ()
startApp = do
  pipe <- connect (host "127.0.0.1")
  e <- access pipe master "users" encryptSessionKey "hello" 3
  close pipe
  print e

runIt :: Action IO ()
runIt = do
  insertUser
  allUsers >>= printDocs "All files and their respective server location"


insertUser :: Action IO [Database.MongoDB.Value]
insertUser = insertMany "user" [
  ["username" =: "isaac", "password" =: "pwd_isaac"],
  ["password" =: "albert", "password" =: "pwd_albert"] ]

allUsers :: Action IO [Document]
allUsers = rest =<< find (select [] "user") {sort = ["username" =: 1]}

printDocs :: String -> [Document] -> Action IO ()
printDocs title docs = liftIO $ putStrLn title >> mapM_ (print . exclude ["_id"]) docs -}