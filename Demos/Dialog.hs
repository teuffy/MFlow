
module Dialog (wdialog1) where

import MFlow.Wai.Blaze.Html.All

wdialog1= do
   ask  wdialogw
   ask (wlink () << "out of the page flow, press here to go to the menu")

wdialogw= pageFlow "diag" $ do
   r <- wform $ p << "please enter your name" ++> getString (Just "your name") <** submitButton "ok"
   wdialog "({modal: true})" "question"  $ 
           p << ("Do your name is \""++r++"\"?") ++> getBool True "yes" "no" <** submitButton "ok"

  `wcallback` \q -> if not q then wdialogw
                      else  wlink () << b << "thanks, press here to exit from the page Flow"


-- to run it alone:
--main= runNavigation "" $ transientNav wdialog1