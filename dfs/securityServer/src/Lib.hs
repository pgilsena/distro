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
import System.Environment (getArgs)
import Database.MongoDB    (Action, Document, Document, Value, access,
                          close, connect, delete, exclude, find,
                          host, insert, insertMany, master, project, rest,
                          select, sort, (=:))
import Control.Monad.Trans (liftIO)
import Data.Text (pack, Text)

data User = User
  { username :: String
  , password :: String
  } deriving (Eq, Show)

startApp :: IO ()
startApp = do
  pipe <- connect (host "127.0.0.1")
  e <- access pipe master "users" runIt
  close pipe
  print e

runIt :: Action IO ()
runIt = do
  insertUser2
  allUsers >>= printDocs "All files and their respective server location"

{-insertUser :: Action IO [Database.MongoDB.Value]
insertUser = do
  let tmp = (User "fiddle" "sticks")
  usrIdx <- insert tmp-}
  
{-insertUser3 :: Action IO [Database.MongoDB.Value]
insertUser3 (User {username =: "fiddle", password =: "sticks"}) = do
  usrIdx <- (insert "boo"
    ["username" =: (pack "fiddle", "password" =: (pack "sticks")])
  let sUsrIdx = show usrIdx
  liftIO $ printf "Added _id : %s\n" sUsrIdx-}


insertUser2 :: Action IO [Database.MongoDB.Value]
insertUser2 = insertMany "user" [
  ["username" =: "isaac", "password" =: "pwd_isaac"],
  ["password" =: "albert", "password" =: "pwd_albert"] ]

allUsers :: Action IO [Document]
allUsers = rest =<< find (select [] "user") {sort = ["username" =: 1]}

printDocs :: String -> [Document] -> Action IO ()
printDocs title docs = liftIO $ putStrLn title >> mapM_ (print . exclude ["_id"]) docs