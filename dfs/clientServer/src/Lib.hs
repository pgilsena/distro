{-# LANGUAGE DataKinds       #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeOperators   #-}
module Lib
    ( startApp
    ) where

import Data.Aeson
import Data.Aeson.TH
import Data.Char
import Network.Wai
import Network.Wai.Handler.Warp
import Servant
import System.IO
import System.Environment

data User = User
  { username :: String
  , password  :: String
  } deriving (Eq, Show)

$(deriveJSON defaultOptions ''User)

type API = "users" :> Get '[JSON] [User]

startApp :: IO ()
startApp = do 
	getUserInfo

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
    | otherwise = getUserInfo

createUser :: String -> String -> IO()
createUser username password = do
	let user = User username password
	printUser user

printUser :: User -> IO ()
printUser user = do
	putStr "I think it's working"
	getUserInfo