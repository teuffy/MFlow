{-# LINE 1 "INPUT" #-}
{-# OPTIONS -XDeriveDataTypeable -XQuasiQuotes -XOverloadedStrings  #-}
module Main where
{-# LINE 3 "INPUT" #-}
import MFlow.Wai.Blaze.Html.All hiding (name)
{-# LINE 4 "INPUT" #-}
import Text.Blaze.Html5 as El
{-# LINE 5 "INPUT" #-}
import Text.Blaze.Html5.Attributes as At hiding (step, name)
{-# LINE 6 "INPUT" #-}
import Data.TCache.IndexQuery
{-# LINE 7 "INPUT" #-}
import Data.Typeable
{-# LINE 10 "INPUT" #-}
import Data.Monoid
{-# LINE 11 "INPUT" #-}
import Data.String
{-# LINE 12 "INPUT" #-}
import Text.Hamlet
{-# LINE 15 "INPUT" #-}
import Control.Monad.Loc
{-# LINE 17 "INPUT" #-}
import Menu
{-# LINE 18 "INPUT" #-}
import TestREST
{-# LINE 19 "INPUT" #-}
import Actions
{-# LINE 20 "INPUT" #-}
import IncreaseInt
{-# LINE 21 "INPUT" #-}
import ShopCart
{-# LINE 22 "INPUT" #-}
import AjaxSample
{-# LINE 23 "INPUT" #-}
import IncreaseString
{-# LINE 24 "INPUT" #-}
import AutoCompList
{-# LINE 25 "INPUT" #-}
import ListEdit
{-# LINE 26 "INPUT" #-}
import AutoComplete
{-# LINE 27 "INPUT" #-}
import LoginSample
{-# LINE 28 "INPUT" #-}
import CheckBoxes
{-# LINE 29 "INPUT" #-}
import Multicounter
{-# LINE 30 "INPUT" #-}
import Combination
{-# LINE 31 "INPUT" #-}
import Options
{-# LINE 32 "INPUT" #-}
import ContentManagement
{-# LINE 33 "INPUT" #-}
import PreventGoingBack
{-# LINE 34 "INPUT" #-}
import Counter
{-# LINE 35 "INPUT" #-}
import PushDecrease
{-# LINE 36 "INPUT" #-}
import Dialog
{-# LINE 37 "INPUT" #-}
import PushSample
{-# LINE 38 "INPUT" #-}
import Grid
{-# LINE 39 "INPUT" #-}
import Radio
{-# LINE 40 "INPUT" #-}
import SumView
{-# LINE 41 "INPUT" #-}
import MCounter
{-# LINE 42 "INPUT" #-}
import Database
{-# LINE 43 "INPUT" #-}
import MFlowPersistent
{-# LINE 44 "INPUT" #-}
import RuntimeTemplates
{-# LINE 46 "INPUT" #-}
import Debug.Trace
{-# LINE 54 "INPUT" #-}
main
  = Control.Monad.Loc.withLoc "main, Main(INPUT): (54, 7)"
      (do Control.Monad.Loc.withLoc "main, Main(INPUT): (55, 4)" (index idnumber)
          Control.Monad.Loc.withLoc "main, Main(INPUT): (56, 4)" (index tfieldKey)
          Control.Monad.Loc.withLoc "main, Main(INPUT): (57, 4)" (setAdminUser adminname adminname)
          Control.Monad.Loc.withLoc "main, Main(INPUT): (58, 4)" (userRegister edadmin edadmin)
          Control.Monad.Loc.withLoc "main, Main(INPUT): (59, 4)" (userRegister "edituser" "edituser")
          Control.Monad.Loc.withLoc "main, Main(INPUT): (60, 4)" (syncWrite $ Asyncronous 120 defaultCheck 1000)
          Control.Monad.Loc.withLoc "main, Main(INPUT): (62, 4)" (setFilesPath "Demos/")
          Control.Monad.Loc.withLoc "main, Main(INPUT): (63, 4)"
            (runNavigation "" $
               Control.Monad.Loc.withLoc "main, Main(INPUT): (63, 23)"
                 (do Control.Monad.Loc.withLoc "main, Main(INPUT): (64, 8)" (setHeader $ stdheader)
                     Control.Monad.Loc.withLoc "main, Main(INPUT): (65, 8)" (setTimeouts 400 $ 60 * 60)
                     r <- Control.Monad.Loc.withLoc "main, Main(INPUT): (67, 8)" (step . ask $ tFieldEd edadmin "head" "set Header" <++ hr **> (divmenu <<< br ++> mainMenu) <** (El.div ! At.style "float:right;width:65%;overflow:auto;" <<< tFieldEd edadmin "intro" "enter intro text"))
                     Control.Monad.Loc.withLoc "main, Main(INPUT): (73, 8)"
                       (case r of
                            Wiki -> delSessionData (Filename "") >> step wiki
                            CountI -> step (clickn 0) `showSource` "IncreaseInt.hs"
                            CountS -> step (clicks "1") `showSource` "IncreaseString.hs"
                            Action -> step actions `showSource` "Actions.hs"
                            Ajax -> step ajaxsample `showSource` "AjaxSample.hs"
                            Select -> step options `showSource` "Options.hs"
                            CheckBoxes -> step checkBoxes `showSource` "CheckBoxes.hs"
                            TextEdit -> step textEdit `showSource` "ContentManagement.hs"
                            Grid -> step grid `showSource` "Grid.hs"
                            Autocomp -> step autocomplete1 `showSource` "AutoComplete.hs"
                            AutocompList -> step autocompList `showSource` "AutoCompList.hs"
                            ListEdit -> step wlistEd `showSource` "ListEdit.hs"
                            Radio -> step radio `showSource` "Radio.hs"
                            Login -> step loginSample `showSource` "LoginSample.hs"
                            PreventBack -> step preventBack `showSource` "PreventGoingBack.hs"
                            Multicounter -> step multicounter `showSource` "Multicounter.hs"
                            FViewMonad -> step sumInView `showSource` "SumView.hs"
                            Counter -> step counter `showSource` "Counter.hs"
                            Combination -> step combination `showSource` "Combination.hs"
                            WDialog -> step wdialog1 `showSource` "Dialog.hs"
                            Push -> step pushSample `showSource` "PushSample.hs"
                            PushDec -> step pushDecrease `showSource` "PushDecrease.hs"
                            Trace -> step traceSample `showSource` "TraceSample.hs"
                            RESTNav -> step testREST `showSource` "TestREST.hs"
                            Database -> step database `showSource` "Database.hs"
                            ShopCart -> shopCart `showSource` "ShopCart.hs"
                            MCounter -> mcounter `showSource` "MCounter.hs"
                            MFlowPersist -> step mFlowPersistent `showSource` "MFlowPersistent.hs"
                            RuntimeTemplates -> step runtimeTemplates `showSource` "RuntimeTemplates.hs"))))
{-# LINE 106 "INPUT" #-}
wiki
  = Control.Monad.Loc.withLoc "wiki, Main(INPUT): (106, 9)"
      (do pag <- Control.Monad.Loc.withLoc "wiki, Main(INPUT): (107, 3)" (getRestParam `onNothing` return "Index")
          Control.Monad.Loc.withLoc "wiki, Main(INPUT): (108, 3)" (askm $ (docTypeHtml $ Control.Monad.Loc.withLoc "wiki, Main(INPUT): (109, 19)" (do Control.Monad.Loc.withLoc "wiki, Main(INPUT): (110, 8)" (El.head $ Control.Monad.Loc.withLoc "wiki, Main(INPUT): (110, 18)" (do Control.Monad.Loc.withLoc "wiki, Main(INPUT): (111, 9)" (El.title $ fromString pag))))) ++> (El.div ! At.style "float:right" <<< autoRefresh wlogin) **> (h1 ! At.style "text-align:center" <<< tFieldEd "editor" (wikip ++ pag ++ "title.html") (fromString pag)) **> tFieldEd "editor" (wikip ++ pag ++ "body.html") "Enter the body" **> noWidget))
{-# LINE 117 "INPUT" #-}
wikip = "wiki/"
{-# LINE 121 "INPUT" #-}
traceSample
  = Control.Monad.Loc.withLoc "traceSample, Main(INPUT): (121, 14)"
      (do Control.Monad.Loc.withLoc "traceSample, Main(INPUT): (122, 3)" (pagem $ h2 "Error trace example" ++> p "MFlow now produces execution traces in case of error by making use of the backtracking mechanism" ++> p "It is more detailed than a call stack" ++> p "this example has a deliberate error" ++> br ++> p "You must be logged as admin to see the trace" ++> wlink () << p "pres here")
          Control.Monad.Loc.withLoc "traceSample, Main(INPUT): (130, 3)" (pagem $ p "Please login with admin/admin" ++> userWidget (Just "admin") userLogin)
          u <- Control.Monad.Loc.withLoc "traceSample, Main(INPUT): (133, 3)" (getCurrentUser)
          Control.Monad.Loc.withLoc "traceSample, Main(INPUT): (134, 3)" (pagem $ p "The trace will appear after you press the link. press one of the options available at the bottom of the page" ++> p << ("user=" ++ u) ++> br ++> wlink () "press here")
          Control.Monad.Loc.withLoc "traceSample, Main(INPUT): (137, 3)" (pagem $ error $ "this is the error"))
