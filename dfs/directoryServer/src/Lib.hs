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
    print e

runIt :: Action IO ()
runIt = do
    -- deleteFiles
    insertFile
    allFiles >>= printDocs "All files and their respective server location"

-- deleteFiles :: Action IO ()
-- deleteFiles = delete (select [] "file")

insertFile :: Action IO [Database.MongoDB.Value]
insertFile = insertMany "file" [
    ["filename" =: "one.txt", "server" =: "127.0.0.2"], -- have location not name for server?
    ["filename" =: "two.txt", "server" =: "127.0.0.3"] ] -- include a locking variable?

allFiles :: Action IO [Document]
allFiles = rest =<< find (select [] "file") {sort = ["filename" =: 1]}

printDocs :: String -> [Document] -> Action IO ()
printDocs title docs = liftIO $ putStrLn title >> mapM_ (print . exclude ["_id"]) docs
