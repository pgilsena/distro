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

data User = User {
username :: String,
password :: String
} deriving (Show)

startApp :: IO ()
startApp = do
  pipe <- connect (host "127.0.0.1")
  e <- access pipe master "users" runIt
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
printDocs title docs = liftIO $ putStrLn title >> mapM_ (print . exclude ["_id"]) docs