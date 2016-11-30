module Main where
 
import Network.Socket
 
main :: IO ()
main = do
    my_sock <- socket AF_INET Stream 0
    setSocketOption my_sock ReuseAddr 1
    bind my_sock (SockAddrInet 8080 iNADDR_ANY)
    listen my_sock 2
    run my_sock


run :: Socket -> IO ()
run sock = do
    conn <- accept sock
    do_something conn
    run sock
 
do_something :: (Socket, SockAddr) -> IO ()
do_something (sock, _) = do
    send sock "This is a message"