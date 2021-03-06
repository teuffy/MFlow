{-# LANGUAGE DeriveDataTypeable,  OverloadedStrings #-}
module Main where

import MFlow.Wai.Blaze.Html.All
import Data.Typeable

data Options= Sum | Prod deriving (Read,Show,Typeable)

main= runNavigation "" . transientNav $ do
    op <- ask $   wlink Sum << b "sum "
              <++ br
              <|> wlink Prod << b "product " <++ br
    p1 <- ask $ getInteger Nothing <++ "first parameter"
    p2 <- ask $ getInteger Nothing <++ "second parameter"

    ask $ case op of
           Sum  -> (fromStr $ show $ p1 + p2) 
           Prod -> (fromStr $ show $ p1 * p2)
          ++> noWidget
