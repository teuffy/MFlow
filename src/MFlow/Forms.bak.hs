{-# OPTIONS  -XDeriveDataTypeable
             -XUndecidableInstances
             -XExistentialQuantification
             -XMultiParamTypeClasses
             -XTypeSynonymInstances
             -XFlexibleInstances
             -XScopedTypeVariables
             -XFunctionalDependencies
             -XFlexibleContexts
             -XRecordWildCards
             -XIncoherentInstances
             -XTypeFamilies
             -XTypeOperators
             -XOverloadedStrings

#-}

{- | This module implement  stateful processes (flows) that are optionally persistent.
This means that they automatically store and recover his execution state. They are executed by the MFlow app server.
defined in the "MFlow" module.

These processses interact with the user trough user interfaces made of widgets (see below) that return back statically typed responses to
the calling process. Because flows are stateful, not request-response, the code is more understandable, because
all the flow of request and responses is coded by the programmer in a single function. Allthoug
single request-response flows and callbacks are possible.

This module is abstract with respect to the formatting (here referred with the type variable @view@) . For an
instantiation for "Text.XHtml"  import "MFlow.Forms.XHtml", "MFlow.Hack.XHtml.All"  or "MFlow.Wai.XHtml.All" .
To use Haskell Server Pages import "MFlow.Forms.HSP". However the functionalities are documented here.

`ask` is the only method for user interaction. It run in the @MFlow view m@ monad, with @m@ the monad chosen by the user, usually IO.
It send user interfaces (in the @View view m@ monad) and return statically
typed responses. The user interface definitions are  based on a extension of
formLets (<http://www.haskell.org/haskellwiki/Formlets>) with the addition of caching, links, formatting, attributes,
 extra combinators, callbaks and modifiers.
The interaction with the user is  stateful. In the same computation there may be  many
request-response interactions, in the same way than in the case of a console applications. 

* APPLICATION SERVER

Therefore, session and state management is simple and transparent: it is in the haskell
structures in the scope of the computation. `transient` (normal) procedures have no persistent session state
and `stateless` procedures accept a single request and return a single response.

`MFlow.Forms.step` is a lifting monad transformer that permit persistent server procedures that
remember the execution state even after system shutdowns by using the package workflow (<http://hackage.haskell.org/package/Workflow>) internally.
This state management is transparent. There is no programer interface for session management.

The programmer set the process timeout and the session timeout with `setTimeouts`.
If the procedure has been stopped due to the process timeout or due to a system shutdowm,
the procedure restart in the last state when a request for this procedure arrives
(if the procedure uses the `step` monad transformer)

* WIDGETS

The correctness of the web responses is assured by the use of formLets.
But unlike formLets in its current form, it permits the definition of widgets.
/A widget is a combination of formLets and links within its own formatting template/, all in
the same definition in the same source file, in plain declarative Haskell style.

The formatting is abstract. It has to implement the 'FormInput' class.
There are instances for Text.XHtml ("MFlow.Forms.XHtml"), Haskell Server Pages ("MFlow.Forms.HSP")
and ByteString. So widgets
can use any formatting that is instance of `FormInput`.
It is possible to use more than one format in the same widget.

Links defined with `wlink` are treated the same way than forms. They are type safe and return values
 to the same flow of execution.
It is posssible to combine links and forms in the same widget by using applicative combinators  but also
additional applicative combinators like  \<+> !*> , |*|. Widgets are also monoids, so they can
be combined as such.

* NEW IN THIS RELEASE

[@WAI interface@] Now MFlow works with Snap and other WAI developments. Include "MFlow.Wai" or "MFlow.Wai.Blaze.Html.All" to use it.

[@blaze-html support@] see <http://hackage.haskell.org/package/blaze-html> import "MFlow.Forms.Blaze.Html" or "MFlow.Wai.Blaze.Html.All" to use Blaze-Html

[@AJAX@] Now an ajax procedures (defined with 'ajax' can perform many interactions with the browser widgets, instead
of a single request-response (see 'ajaxSend').

[@Active widgets@] "MFlow.Forms.Widgets" contains active widgets that interact with the
server via Ajax and dynamically control other widgets: 'wEditList', 'autocomplete' 'autocompleteEdit' and others.

[@Requirements@] a widget can specify javaScript files, JavasScript online scipts, CSS files, online CSS and server processes
 and any other instance of the 'Requrement' class. See 'requires' and 'WebRequirements'


[@content-management@] for templating and online edition of the content template. See 'tFieldEd' 'tFieldGen' and 'tField'

[@multilanguage@] see 'mField' and 'mFieldEd'

[@URLs to internal states@] if the web navigation is trough GET forms or links,
 an URL can express a direct path to the n-th step of a flow, So this URL can be shared with other users.
Just like in the case of an ordinary stateless application.

* NEW IN PREVIOUS RELEASE:

[@Back Button@] This is probably the first implementation in any language where the navigation
can be expressed procedurally and still it works well with the back button, thanks
to monad magic. (See <http://haskell-web.blogspot.com.es/2012/03//failback-monad.html>)


[@Cached widgets@] with `cachedWidget` it is possible to cache the rendering of a widget as a ByteString (maintaining type safety)
, the caching can be permanent or for a certain time. this is very useful for complex widgets that present information. Specially if
the widget content comes from a database and it is shared by all users.


[@Callbacks@] `waction` add a callback to a widget. It is executed when its input is validated.
The callback may initate a flow of interactions with the user or simply executes an internal computation.
Callbacks are necessary for the creation of abstract container
widgets that may not know the behaviour of its content. with callbacks, the widget manages its content as  black boxes.


[@Modifiers@] `wmodify` change the visualization and result returned by the widget. For example it may hide a
login form and substitute it by the username if already logged.

Example:

@ ask $ wform userloginform \``validate`\` valdateProc \``waction`\` loginProc \``wmodify`\` hideIfLogged@


[@attributes for formLet elements@]  to add atributes to widgets. See the  '<!' opèrator


[@ByteString normalization and hetereogeneous formatting@] For caching the rendering of widgets at the
 ByteString level, and to permit many formatring styles
in the same page, there are operators that combine different formats which are converted to ByteStrings.
For example the header and footer may be coded in XML, while the formlets may be formatted using Text.XHtml.

[@File Server@] With file caching. See "MFlow.FileServer"


-}

module MFlow.Forms(

-- * Basic definitions 
-- FormLet(..), 
FlowM, View(..), FormElm(..), FormInput(..)

-- * Users 
,userRegister, userValidate, isLogged, setAdminUser, getAdminName
,getCurrentUser,getUserSimple, getUser, userFormLine, userLogin,logout, userWidget,getLang, login,
userName,
-- * User interaction 
ask, askt, clearEnv, wstateless, transfer,
-- * formLets 
-- | They usually produce the HTML form elements (depending on the FormInput instance used)
-- It is possible to modify their attributes with the `<!` operator.
-- They are combined with applicative ombinators and some additional ones
-- formatting can be added with the formatting combinators.
-- modifiers change their presentation and behaviour
getString,getInt,getInteger, getTextBox 
,getMultilineText,getBool,getSelect, setOption,setSelectedOption, getPassword,
getRadio, setRadio, setRadioActive, getCheckBoxes, genCheckBoxes, setCheckBox,
submitButton,resetButton, whidden, wlink, returning, wform, firstOf, manyOf, wraw, wrender, notValid
-- * FormLet modifiers
,validate, noWidget, waction, wcallback, wmodify,

-- * Caching widgets
cachedWidget, wcached, wfreeze,

-- * Widget combinators
(<+>),(|*>),(|+|), (**>),(<**),(<|>),(<*),(<$>),(<*>),(>:>)

-- * Normalized (convert to ByteString) widget combinators
-- | These dot operators are indentical to the non dot operators, with the addition of the conversion of the arguments to lazy byteStrings
--
-- The purpose is to combine heterogeneous formats into byteString-formatted widgets that
-- can be cached with `cachedWidget`
,(.<+>.), (.|*>.), (.|+|.), (.**>.),(.<**.), (.<|>.),

-- * Formatting combinators
(<<<),(++>),(<++),(<!),

-- * Normalized (convert to ByteString) formatting combinators
-- | Some combinators that convert the formatting of their arguments to lazy byteString
(.<<.),(.<++.),(.++>.)

-- * ByteString tags
,btag,bhtml,bbody

-- * Normalization
, flatten, normalize

-- * Running the flow monad
,runFlow,runFlowOnce,runFlowIn,runFlowConf,MFlow.Forms.Internals.step, goingBack,breturn, preventGoingBack

-- * Setting parameters
,setHeader
,setSessionData
,getSessionData
,getHeader
,setTimeouts

-- * Cookies
,setCookie
-- * Ajax
,ajax
,ajaxSend
,ajaxSend_
-- * Requirements
,Requirements(..)
,WebRequirement(..)
,requires
-- * Utility
,genNewId
,changeMonad
,FailBack
,fromFailBack
,toFailBack
-- * The monster of the deep
,MFlowState
)
where

import Data.RefSerialize hiding ((<|>))
import Data.TCache
import Data.TCache.Memoization
import MFlow
import MFlow.Forms.Internals
import MFlow.Cookies
import Data.ByteString.Lazy.Char8 as B(ByteString,cons,pack,unpack,append,empty,fromChunks) 
import Data.List
--import qualified Data.CaseInsensitive as CI
import Data.Typeable
import Data.Monoid
import Control.Monad.State.Strict 
import Data.Maybe
import Control.Applicative
import Control.Exception
import Control.Concurrent
import Control.Workflow as WF 
import Control.Monad.Identity
import Unsafe.Coerce
import Data.List(intersperse)
import Data.IORef
import qualified Data.Map as M
import System.IO.Unsafe
import Data.Char(isNumber,toLower)
import Network.HTTP.Types.Header

--import Debug.Trace
--(!>)= flip trace



-- | Validates a form or widget result against a validating procedure
--
-- @getOdd= getInt Nothing `validate` (\x -> return $ if mod x 2==0 then  Nothing else Just "only odd numbers, please")@
validate
  :: (FormInput view, Monad m) =>
     View view m a
     -> (a -> WState view m (Maybe view))
     -> View view m a
validate  formt val= View $ do
   FormElm form mx <- (runView  formt)  
   case mx of
    Just x -> do
      me <- val x
      modify (\s -> s{inSync= True})
      case me of
         Just str ->
           return $ FormElm ( form ++ [inred  str]) Nothing 
         Nothing  -> return $ FormElm [] mx 
    _ -> return $ FormElm form mx

-- | Actions are callbacks that are executed when a widget is validated.
-- A action may be a complete flow in the flowM monad. It takes complete control of the navigation
-- while it is executed. At the end it return the result to the caller and display the original
-- calling page.
-- It is useful when the widget is inside widget containers that may treat it as a black box.
--
-- It returns a result  that can be significative or, else, be ignored with '<**' and '**>'.
-- An action may or may not initiate his own dialog with the user via `ask`
waction
  :: (FormInput view, Monad m)
     => View view m a
     -> (a -> FlowM view m b)
     -> View view m b
waction f ac = do
  x <- f
  s <- get
  let env =  mfEnv s
  let seq = mfSequence s
  put s{mfSequence=mfSequence s+ 100,mfEnv=[],newAsk=True{-,mfLinkSelected= False-}}
  r <- flowToView $ ac x
  modify $ \s-> s{mfSequence= seq, mfEnv= env}
  return r
  where
  flowToView x=
          View $ do
              r <- runBackT $ runFlowM  x
              case r of
                NoBack x ->
                     return (FormElm [] $ Just x)
                BackPoint x->
                     return (FormElm [] $ Just x)
                GoBack-> do
                     modify $ \s ->s{notSyncInAction= True}
                     return (FormElm [] Nothing)

wmodify :: (Monad m, FormInput v)
        => View v m a
        -> ([v] -> Maybe a -> WState v m ([v], Maybe b))
        -> View v m b
wmodify formt act = View $ do
   FormElm f mx <- runView  formt 
   (f',mx') <-  act f mx
   return $ FormElm f' mx'


--
--instance (FormInput view, FormLet a m view , FormLet b m view )
--          => FormLet (a,b) m view  where
--  digest  mxy  = do
--      let (x,y)= case mxy of Nothing -> (Nothing, Nothing); Just (x,y)-> (Just x, Just y)
--      (,) <$> digest x   <*> digest  y
--
--instance (FormInput view, FormLet a m view , FormLet b m view,FormLet c m view )
--          => FormLet (a,b,c) m view  where
--  digest  mxy  = do
--      let (x,y,z)= case mxy of Nothing -> (Nothing, Nothing, Nothing); Just (x,y,z)-> (Just x, Just y,Just z)
--      (,,) <$> digest x  <*> digest  y  <*> digest  z

-- | Display a text box and return a String
getString  :: (FormInput view,Monad m) =>
     Maybe String -> View view m String
getString = getTextBox

-- | Display a text box and return an Integer (if the value entered is not an Integer, fails the validation)
getInteger :: (FormInput view,  MonadIO m) =>
     Maybe Integer -> View view m  Integer
getInteger =  getTextBox

-- | Display a text box and return a Int (if the value entered is not an Int, fails the validation)
getInt :: (FormInput view, MonadIO m) =>
     Maybe Int -> View view m Int
getInt =  getTextBox

-- | Display a password box 
getPassword :: (FormInput view,
     Monad m) =>
     View view m String
getPassword = getParam Nothing "password" Nothing

data Radio= Radio String
-- | Implement a radio button that perform a submit when pressed.
-- the parameter is the name of the radio group
setRadioActive :: (FormInput view,  MonadIO m) =>
             String -> String -> View view m  Radio
setRadioActive  v n = View $ do
  st <- get
  put st{needForm= True}
  let env =  mfEnv st
  mn <- getParam1 n env
  return $ FormElm [finput n "radio" v
          ( isValidated mn  && v== fromValidated mn) (Just  "this.form.submit()")]
          (fmap Radio $ valToMaybe mn)

valToMaybe (Validated x)= Just x
valToMaybe _= Nothing

isValidated (Validated x)= True
isValidated _= False

fromValidated (Validated x)= x
fromValidated NoParam= error $ "fromValidated : NoParam"
fromValidated (NotValidated s err)= error $ "fromValidated: NotValidated "++ s

-- | Implement a radio button
-- the parameter is the name of the radio group
setRadio :: (FormInput view,  MonadIO m) => 
            String -> String -> View view m  Radio
setRadio v n= View $ do
  st <- get
  put st{needForm= True}
  let env =  mfEnv st
  mn <- getParam1 n env
  return $ FormElm [finput n "radio" v
          ( isValidated mn  && v== fromValidated mn) Nothing]
          (fmap Radio $ valToMaybe mn)

-- | encloses a set of Radio boxes. Return the option selected
getRadio
  :: (Monad m, Functor m, FormInput view) =>
     [String -> View view m Radio] -> View view m String
getRadio rs=  do
        id <- genNewId
        Radio r <- firstOf $ map (\r -> r id)  rs
        return r

data CheckBoxes = CheckBoxes [String]

instance Monoid CheckBoxes where
  mappend (CheckBoxes xs) (CheckBoxes ys)= CheckBoxes $ xs ++ ys
  mempty= CheckBoxes []

--instance (Monad m, Functor m) => Monoid (View v m CheckBoxes) where
--  mappend x y=  mappend <$> x <*> y
--  mempty= return (CheckBoxes [])


-- | Display a text box and return the value entered if it is readable( Otherwise, fail the validation)
setCheckBox :: (FormInput view,  MonadIO m) =>
                Bool -> String -> View view m  CheckBoxes
setCheckBox checked v= View $ do
  n <- genNewId
  st <- get
  put st{needForm= True}
  let env = mfEnv st
      strs= map snd $ filter ((==) n . fst) env
      mn= if null strs then Nothing else Just $ head strs
      val = inSync st
  let ret= case val of                    -- !> show val of
        True  -> Just $ CheckBoxes  strs  -- !> show strs
        False -> Nothing
  return $ FormElm
      ( [ finput n "checkbox" v
        ( checked || (isJust mn  && v== fromJust mn)) Nothing])
      ret

-- | Read the checkboxes dinamically created by JavaScript within the view parameter
-- see for example `selectAutocomplete` in "MFlow.Forms.Widgets"
genCheckBoxes :: (Monad m, FormInput view) => view ->  View view m  CheckBoxes
genCheckBoxes v= View $ do
  n <- genNewId
  st <- get
  put st{needForm= True}
  let env = mfEnv st
      strs= map snd $ filter ((==) n . fst) env
      mn= if null strs then Nothing else Just $ head strs

  val <- gets inSync
  let ret= case val of
        True ->  Just $ CheckBoxes  strs
        False -> Nothing
  return $ FormElm [ftag "span" v `attrs`[("id",n)]] ret

whidden :: (Monad m, FormInput v,Read a, Show a, Typeable a) => a -> View v m a
whidden x= View $ do
  n <- genNewId
  env <- gets mfEnv
  let showx= case cast x of
              Just x' -> x'
              Nothing -> show x
  r <- getParam1 n env
  return $ FormElm [finput n "hidden" showx False Nothing] $ valToMaybe r

getCheckBoxes ::(FormInput view, Monad m)=> View view m  CheckBoxes -> View view m [String]
getCheckBoxes boxes =  View $ do
    n <- genNewId
    st <- get
    let env =  mfEnv st
    let form= [finput n "hidden" "" False Nothing]
    mr  <- getParam1 n env

    let env = mfEnv st
    modify $ \st -> st{needForm= True}
    FormElm form2 mr2 <- runView boxes
    return $ FormElm (form ++ form2) $
        case (mr `asTypeOf` Validated ("" :: String),mr2) of
          (NoParam,_) ->  Nothing
          (Validated _,Nothing) -> Just []
          (Validated _, Just (CheckBoxes rs))  ->  Just rs




     
getTextBox
  :: (FormInput view,
      Monad  m,
      Typeable a,
      Show a,
      Read a) =>
     Maybe a ->  View view m a
getTextBox ms  = getParam Nothing "text" ms


getParam
  :: (FormInput view,
      Monad m,
      Typeable a,
      Show a,
      Read a) =>
     Maybe String -> String -> Maybe a -> View view m  a
getParam look type1 mvalue = View $ do
    tolook <- case look of
       Nothing  -> genNewId  
       Just n -> return n
    let nvalue x= case x of
           Nothing  -> ""
           Just v   ->
               case cast v of
                 Just v' -> v'
                 Nothing -> show v
    st <- get
    let env = mfEnv st
    put st{needForm= True}
    r <- getParam1 tolook env
    case r of
       Validated x        -> return $ FormElm [finput tolook type1 (nvalue $ Just x) False Nothing] $ Just x
       NotValidated s err -> return $ FormElm ([finput tolook type1 s False Nothing]++[err]) $ Nothing
       NoParam            -> return $ FormElm [finput tolook type1 (nvalue mvalue) False Nothing] $ Nothing
       
-- | Generate a new string. Useful for creating tag identifiers and other attributes
genNewId :: MonadState (MFlowState view) m =>  m String
genNewId=  do
  st <- get
  case mfCached st of
    False -> do
      let n= mfSequence st
          prefseq= let seq= mfCallBackSeq st
                   in if seq==0 then "" else show seq
      put $ st{mfSequence= n+1}

      return $ 'p':prefseq ++(show n)
    True  -> do
      let n = mfSeqCache st
      put $ st{mfSeqCache=n+1}
      return $  'c' : (show n)


getCurrentName :: MonadState (MFlowState view) m =>  m String
getCurrentName= do
     st <- get
     let parm = mfSequence st
     return $ "p"++show parm


-- | Display a multiline text box and return its content
getMultilineText :: (FormInput view,
      Monad m) =>
      String ->  View view m String
getMultilineText nvalue = View $ do
    tolook <- genNewId
    env <- gets mfEnv
    r <- getParam1 tolook env
    case r of
       Validated x        -> return $ FormElm [ftextarea tolook  (show x) ] $ Just x
       NotValidated s err -> return $ FormElm [ftextarea tolook  s ] $ Nothing
       NoParam            -> return $ FormElm [ftextarea tolook  nvalue ] $ Nothing

      
--instance  (MonadIO m, Functor m, FormInput view) => FormLet Bool m view where
--   digest mv =  getBool b "True" "False"
--       where
--       b= case mv of
--           Nothing -> Nothing
--           Just bool -> Just $ case bool of
--                          True ->  "True"
--                          False -> "False"

-- | Display a dropdown box with the two values (second (true) and third parameter(false))
-- . With the value of the first parameter selected.                  
getBool :: (FormInput view,
      Monad m) =>
      Bool -> String -> String -> View view m Bool
getBool mv truestr falsestr= View $ do
    tolook <- genNewId
    st <- get
    let env = mfEnv st
    put st{needForm= True}
    r <- getParam1 tolook env
    let flag=  isValidated r && fromstr (fromValidated r)
    let form= [fselect tolook (foption1 truestr flag `mappend` foption1 falsestr (not flag))]
    return $ FormElm form . fmap fromstr $ valToMaybe r
--    case mx of
--       Nothing ->  return $ FormElm f Nothing
--       Just x  ->  return . FormElm f $ fromstr x
    where
    fromstr x= if x== truestr then True else False

-- | Display a dropdown box with the options in the first parameter is optionally selected
-- . It returns the selected option. 
getSelect :: (FormInput view,
      Monad m,Typeable a, Read a) =>
      View view m (MFOption a) ->  View view m  a
getSelect opts = View $ do
    tolook <- genNewId
    st <- get
    let env = mfEnv st
    put st{needForm= True}
    FormElm form mr <- (runView opts)
    r <- getParam1 tolook env
    return $ FormElm [fselect tolook $ mconcat form] $ valToMaybe r 

data MFOption a= MFOption

instance (Monad m, Functor m) => Monoid (View view m (MFOption a)) where
  mappend =  (<|>)
  mempty = Control.Applicative.empty

-- | Set the option for getSelect. Options are concatenated with `<|>`
setOption n v = setOption1 n v False

-- | Set the selected option for getSelect. Options are concatenated with `<|>`
setSelectedOption n v= setOption1 n v True
 
setOption1 :: (FormInput view,
      Monad m, Typeable a, Show a) =>
      a -> view -> Bool ->  View view m  (MFOption a) 
setOption1 nam  val check= View $ do
    st <- get
    let env = mfEnv st
    put st{needForm= True}
    let n= if typeOf nam== typeOf(undefined :: String) then unsafeCoerce nam else show nam
    return . FormElm [foption n val check]  $ Just MFOption


-- | Enclose Widgets within some formating.
-- @view@ is intended to be instantiated to a particular format
--
-- NOTE: It has a infix priority : @infixr 5@ less than the one of @++>@ and @<++@ of the operators, so use parentheses when appropriate,
-- unless the we want to enclose all the widgets in the right side.
-- Most of the type errors in the DSL are due to the low priority of this operator.
--
-- This is a widget, which is a table with some links. it returns an Int
--
-- > import MFlow.Forms.Blaze.Html
-- >
-- > tableLinks :: View Html Int
-- > table ! At.style "border:1;width:20%;margin-left:auto;margin-right:auto"
-- >            <<< caption << text "choose an item"
-- >            ++> thead << tr << ( th << b << text  "item" <> th << b << text "times chosen")
-- >            ++> (tbody
-- >                 <<< tr ! rowspan "2" << td << linkHome
-- >                 ++> (tr <<< td <<< wlink  IPhone (b << text "iphone") <++  td << ( b << text (fromString $ show ( cart V.! 0)))
-- >                 <|>  tr <<< td <<< wlink  IPod (b << text "ipad")     <++  td << ( b << text (fromString $ show ( cart V.! 1)))
-- >                 <|>  tr <<< td <<< wlink  IPad (b << text "ipod")     <++  td << ( b << text (fromString $ show ( cart V.! 2))))
-- >                 )
(<<<) :: (Monad m,  Monoid view)
          => (view ->view)
         -> View view m a
         -> View view m a
(<<<) v form= View $ do
  FormElm f mx <- runView form 
  return $ FormElm [v $ mconcat f] mx


infixr 5 <<<






-- | Append formatting code to a widget
--
-- @ getString "hi" <++ H1 << "hi there"@
--
-- It has a infix prority: @infixr 6@ higuer that '<<<' and most other operators
(<++) :: (Monad m)
      => View v m a
      -> v
      -> View v m a 
(<++) form v= View $ do
  FormElm f mx <-  runView  form  
  return $ FormElm ( f ++ [ v]) mx 
 
infixr 6 <++ , .<++. , ++> , .++>.
-- | Prepend formatting code to a widget
--
-- @bold << "enter name" ++> getString Nothing @
--
-- It has a infix prority: @infixr 6@ higuer that '<<<' and most other operators
(++>) :: (Monad m,  Monoid view)
       => view -> View view m a -> View view m a
html ++> digest =  (html `mappend`) <<< digest




-- | Add attributes to the topmost tag of a widget
--
-- it has a fixity @infix 8@
infix 8 <!
widget <! attribs= View $ do
      FormElm fs  mx <- runView widget
      return $ FormElm  (head fs `attrs` attribs:tail fs) mx
--      case fs of
--        [hfs] -> return $ FormElm  [hfs `attrs` attribs] mx
--        _ -> error $ "operator <! : malformed widget: "++ concatMap (unpack. toByteString) fs


-- | Is an example of login\/register validation form needed by 'userWidget'. In this case
-- the form field appears in a single line. it shows, in sequence, entries for the username,
-- password, a button for loging, a entry to repeat password necesary for registering
-- and a button for registering.
-- The user can build its own user login\/validation forms by modifying this example
--
-- @ userFormLine=
--     (User \<\$\> getString (Just \"enter user\") \<\*\> getPassword \<\+\> submitButton \"login\")
--     \<\+\> fromStr \"  password again\" \+\> getPassword \<\* submitButton \"register\"
-- @
userFormLine :: (FormInput view, Functor m, Monad m)
            => View view m (Maybe (UserStr,PasswdStr), Maybe PasswdStr)
userFormLine=
       ((,)  <$> getString (Just "enter user")                  <! [("size","5")]
             <*> getPassword                                    <! [("size","5")]
         <** submitButton "login")
         <+> (fromStr "  password again" ++> getPassword      <! [("size","5")]
         <*  submitButton "register")

-- | Example of user\/password form (no validation) to be used with 'userWidget'
userLogin :: (FormInput view, Functor m, Monad m)
          => View view m (Maybe (UserStr,PasswdStr), Maybe String)
userLogin=
        ((,)  <$> fromStr "Enter User: " ++> getString Nothing     <! [("size","4")]
              <*> fromStr "  Enter Pass: " ++> getPassword         <! [("size","4")]
              <** submitButton "login")
              <+> (noWidget
              <*  noWidget)



-- | Empty widget that return Nothing. May be used as \"empty boxes\" inside larger widgets
noWidget ::  (FormInput view,
     Monad m) =>
     View view m a
noWidget= View . return $ FormElm  [] Nothing

-- | Render a Show-able  value and return it
wrender
  :: (Monad m, Functor m, Show a, FormInput view) =>
     a -> View view m a
wrender x = (fromStr $ show x) ++> return x

-- | Render raw view formatting. It is useful for displaying information
wraw :: Monad m => view -> View view m ()
wraw x= View . return . FormElm [x] $ Just ()

-- To display some rendering and return  non valid
notValid :: Monad m => view -> View view m a
notValid x= View . return $ FormElm [x] Nothing

-- | Wether the user is logged or is anonymous
isLogged :: MonadState (MFlowState v) m => m Bool
isLogged= do
   rus <-  return . tuser =<< gets mfToken
   return . not $ rus ==  anonymous

-- | It creates a widget for user login\/registering. If a user name is specified
-- in the first parameter, it is forced to login\/password as this specific user.
-- If this user was already logged, the widget return the user without asking.
-- If the user press the register button, the new user-password is registered and the
-- user logged.
userWidget :: ( MonadIO m, Functor m
          , FormInput view) 
         => Maybe String
         -> View view m (Maybe (UserStr,PasswdStr), Maybe String)
         -> View view m String
userWidget muser formuser= do
   user <- getCurrentUser
   if muser== Just user || isNothing muser && user/= anonymous
         then return user
         else formuser `validate` val muser `waction` login1 
   where
   val _ (Nothing,_) = return . Just $ fromStr "Plese fill in the user/passwd to login, or user/passwd/passwd to register"

   val mu (Just us, Nothing)=
        if isNothing mu || isJust mu && fromJust mu == fst us
           then userValidate us
           else return . Just $ fromStr "This user has no permissions for this task"

   val mu (Just us, Just p)=
      if isNothing mu || isJust mu && fromJust mu == fst us
        then  if  length p > 0 && snd us== p
                  then return Nothing
                  else return . Just $ fromStr "The passwords do not match"
        else return . Just $ fromStr "wrong user for the operation"

--   val _ _ = return . Just $ fromStr "Please fill in the fields for login or register"

   login1
      :: (MonadIO m, MonadState (MFlowState view) m) =>
         (Maybe (String, String), Maybe String) -> m String
   login1 (Just (uname,_), Nothing)= login uname >> return uname

   login1 (Just us@(u,p), Just _)=  do  -- register button pressed
             userRegister u p
             login u
             return u

-- | change the user
--
-- It is supposed that the user has been validated


login uname= do
 st <- get
 let t = mfToken st
     u = tuser t
 if u == uname then return () else do
     let t'= t{tuser= uname}
     moveState (twfname t) t t'
     put st{mfToken= t'}
     liftIO $ deleteTokenInList t
     liftIO $ addTokenToList t'
     setCookie cookieuser   uname "/"  (Just $ 365*24*60*60) 
     return ()



-- | logout. The user is resetted to the `anonymous` user
logout :: (MonadIO m, MonadState (MFlowState view) m) => m ()
logout= do
     st <- get
     let t = mfToken st
         t'= t{tuser= anonymous}
     if tuser t == anonymous then return () else do
         moveState (twfname t) t t'
         put st{mfToken= t'}
         liftIO $ deleteTokenInList t
         liftIO $ addTokenToList t'

         setCookie cookieuser   anonymous "/" (Just $ -1000)

-- | If not logged, perform login. otherwise return the user
--
-- @getUserSimple= getUser Nothing userFormLine@
getUserSimple :: ( FormInput view, Typeable view)
              => FlowM view IO String
getUserSimple= getUser Nothing userFormLine

-- | Very basic user authentication. The user is stored in a cookie.
-- it looks for the cookie. If no cookie, it ask to the user for a `userRegister`ed
-- user-password combination.
-- The user-password combination is only asked if the user has not logged already
-- otherwise, the stored username is returned.
--
-- @getUser mu form= ask $ userWidget mu form@
getUser :: ( FormInput view, Typeable view)
          => Maybe String
          -> View view IO (Maybe (UserStr,PasswdStr), Maybe String)
          -> FlowM view IO String
getUser mu form= ask $ userWidget mu form


-- | Join two widgets in the same page
-- the resulting widget, when `ask`ed with it, return a 2 tuple of their validation results
-- if both return Noting, the widget return @Nothing@ (invalid).
--
-- it has a low infix priority: @infixr 2@
-- 
--  > r <- ask  widget1 <+>  widget2
--  > case r of (Just x, Nothing) -> ..
(<+>) , mix ::  Monad m
      => View view m a
      -> View view m b
      -> View view m (Maybe a, Maybe b)
mix digest1 digest2= View $ do
  FormElm f1 mx' <- runView  digest1
  FormElm f2 my' <- runView  digest2
  return $ FormElm (f1++f2) 
         $ case (mx',my') of
              (Nothing, Nothing) -> Nothing
              other              -> Just other

infixr 2 <+>, .<+>.

(<+>)  = mix



-- | The first elem result (even if it is not validated) is discarded, and the secod is returned
-- . This contrast with the applicative operator '*>' which fails the whole validation if
-- the validation of the first elem fails.
--
-- The first element is displayed however, as happens in the case of '*>' .
--
-- Here @w\'s@ are widgets and @r\'s@ are returned values
--
--   @(w1 <* w2)@  will return @Just r1@ only if w1 and w2 are validated
--
--   @(w1 <** w2)@ will return @Just r1@ even if w2 is not validated
--
--  it has a low infix priority: @infixr 1@

(**>) :: (Functor m, Monad m)
      => View view m a -> View view m b -> View view m b
(**>) form1 form2 = valid form1 *> form2

infixr 1  **> , .**>. ,  <** , .<**.

-- | The second elem result (even if it is not validated) is discarded, and the first is returned
-- . This contrast with the applicative operator '*>' which fails the whole validation if
-- the validation of the second elem fails.
-- The second element is displayed however, as in the case of '<*'.
-- see the `<**` examples
--
--  it has a low infix priority: @infixr 1@
(<**)
  :: (Functor m, Monad m) =>
     View view m a -> View view m b -> View view m a
(<**) form1 form2 =  form1 <* valid form2


valid form= View $ do
   FormElm form mx <- runView form
   return $ FormElm form $ Just undefined

-- | for compatibility with the same procedure in 'MFLow.Forms.Test.askt'.
-- This is the non testing version
--
-- > askt v w= ask w
--
-- hide one or the other
askt :: FormInput v => (Int -> a) -> View v IO a -> FlowM v IO a
askt v w =  ask w


-- | It is the way to interact with the user.
-- It takes a widget and return the input result. If the widget is not validated (return @Nothing@)
-- , the page is presented again
--
-- If the environment or the URL has the parameters being looked at, maybe as a result of a previous interaction,
-- it will not ask to the user and return the result.
-- To force asking in any case, add an `clearEnv` statement before.
-- It also handles ajax requests
--
-- 'ask' also synchronizes the execution of the flow with the user page navigation by

-- * Backtracking (invoking previous 'ask' staement in the flow) when detecting mismatches between get and post parameters and what is expected by the widgets
-- until a total or partial match is found.
--
-- * Advancing in the flow by mathing a single requests with one or more sucessive ask statements
--
-- Backtracking and advancing can occur in a single request, so the flow in any state can reach any
-- other state in the flow if the request satisfy the parameters required.
ask
  :: (FormInput view) =>
      View view IO a -> FlowM view IO a
ask w =  do
  st1 <- get

  -- AJAX
  let env= mfEnv st1
      mv1= lookup "ajax" env
      majax1= mfAjax st1

  case (majax1,mv1,M.lookup (fromJust mv1)(fromJust majax1), lookup "val" env)  of
   (Just ajaxl,Just v1,Just f, Just v2) -> do
     FlowM . lift $ (unsafeCoerce f) v2
     FlowM $ lift receiveWithTimeouts
     ask w
  -- END AJAX

   _ ->   do
     let st= st1{needForm= False, inSync= False, mfRequirements= []} 
     put st
     FormElm forms mx <- FlowM . lift $ runView  w                !> ("mfPath="++ show (mfPath st1))
              
     st' <- get
     if notSyncInAction st' then put st'{notSyncInAction=False}>> ask w  else
      case mx !> ("lengthreqs="++ (show $ length $mfRequirements st'))of
       Just x -> do
--         let depth= mfLinkDepth st'
         put st'{newAsk= True ,mfEnv=[]
--                ,mfLinks = M.empty
                ,mfCallBackSeq= 0}
--                ,mfLinkDepth=
--                         if mfLinkSelected  st'
--                            then
--                            depth +1
--                            else
--                            depth
--                ,mfLinkSelected= False}
         breturn x

       Nothing ->
         if  not (inSync st')  && not (newAsk st')     -- !> ("insinc="++show (inSync st'))
                                                       -- !> ("newask="++show (newAsk st'))
          then  fail ""
          else do
             reqs <-  FlowM $ lift installAllRequirements
             let header= mfHeader st'
                 t= mfToken st'
             cont <- case (needForm st') of
                      True ->  do
                               frm <- formPrefix (twfname t ) st' forms False
                               return . header $  reqs <> frm
                      _    ->  return . header $  reqs <> mconcat  forms

             let HttpData ctype c s= toHttpData cont 
             liftIO . sendFlush t $ HttpData (ctype++mfHttpHeaders st') (mfCookies st' ++ c) s


             put st{mfCookies=[]
--                   ,mfLinks= mfLinks st'
--                   ,mfLinkDepth= incLinkDepth st'
                   ,mfHttpHeaders=[]
                   ,newAsk= False
                   ,mfToken= t
                   ,mfAjax= mfAjax st'
                   ,mfSeqCache= mfSeqCache st' }                --    !> ("after "++show ( mfSequence st'))

             FlowM $ lift  receiveWithTimeouts
             ask w
    where
    head1 []=0
    head1 xs= head xs
    tail1 []=[]
    tail1 xs= tail xs

-- | A synonym of ask.
--
-- Maybe more appropiate for pages with long interactions with the user
-- while the result has little importance.
page
  :: (FormInput view) =>
      View view IO a -> FlowM view IO a
page= ask


-- | True if the flow is going back (as a result of the back button pressed in the web browser).
--  Usually this check is nos necessary unless conditional code make it necessary
--
-- @menu= do
--       mop <- getGoStraighTo
--       case mop of
--        Just goop -> goop
--        Nothing -> do
--               r \<- `ask` option1 \<|> option2
--               case r of
--                op1 -> setGoStraighTo (Just goop1) >> goop1
--                op2 -> setGoStraighTo (Just goop2) >> goop2@
--
-- This pseudocode below would execute the ask of the menu once. But the user will never have
-- the possibility to see the menu again. To let him choose other option, the code
-- has to be change to
--
-- @menu= do
--       mop <- getGoStraighTo
--       back <- `goingBack`
--       case (mop,back) of
--        (Just goop,False) -> goop
--        _ -> do
--               r \<- `ask` option1 \<|> option2
--               case r of
--                op1 -> setGoStraighTo (Just goop1) >> goop1
--                op2 -> setGoStraighTo (Just goop2) >> goop2@
--
-- However this is very specialized. Normally the back button detection is not necessary.
-- In a persistent flow (with step) even this default entry option would be completely automatic,
-- since the process would restar at the last page visited. No setting is necessary.
goingBack :: (MonadIO m,MonadState (MFlowState view) m) => m Bool
goingBack = do
    st <- get
    liftIO $ do
      print $"Insync=" ++ show (inSync st)
      print $ "newAsk st=" ++ show (newAsk st)
    return $ not (inSync st) && not (newAsk st)

-- | Will prevent the backtrack beyond the point where 'preventGoingBack' is located.
-- If the  user press the back button beyond that point, the flow parameter is executed, usually
-- it is an ask statement with a message. If the flow is not going back, it does nothing. It is a cut in backtracking
--
-- It is useful when an undoable transaction has been commited. For example, after a payment.
--
-- This example show a message when the user go back and press again to pay
--
-- >   ask $ wlink () << b << "press here to pay 100000 $ "
-- >   payIt
-- >   preventGoingBack . ask $   b << "You  paid 10000 $ one time"
-- >                          ++> wlink () << b << " Please press here to complete the proccess"
-- >   ask $ wlink () << b << "OK, press here to go to the menu or press the back button to verify that you can not pay again"
-- >   where
-- >   payIt= liftIO $ print "paying"

preventGoingBack
  :: (Functor m, MonadIO m, FormInput v) => FlowM v m () -> FlowM v m ()
preventGoingBack msg= do
   back <- goingBack
   liftIO $ putStr "BACK= ">> print back
   if not back  then breturn() else do
         breturn()  -- will not go back bellond this
         clearEnv
         modify $ \s -> s{newAsk= True}
         msg




receiveWithTimeouts :: MonadIO m => WState view m ()
receiveWithTimeouts= do
     st <- get
     let t= mfToken st
         t1= mfkillTime st
         t2= mfSessionTime st
     msg <-  liftIO ( receiveReqTimeout t1 t2  t)
     let req= getParams msg
         env= updateParams pathChanged (mfEnv st) req -- !> show req
         path=  pwfPath msg
         pathChanged= path /= mfPath st
     put st{ mfPath=path
           , mfEnv= env}

     where
     updateParams :: Bool -> Params -> Params -> Params
     updateParams True _ req= req
     updateParams False env req=

        let params= takeWhile isparam env
            fs= fst $ head req
            parms= (case findIndex (\p -> fst p == fs)  params of
                      Nothing -> params
                      Just  i -> take i params)
                    ++  req
        in parms -- !> show parms `seq` parms



isparam ('p': r,_)= and $ map isNumber r
isparam ('c': r,_)= and $ map isNumber r
isparam _= False

-- | Creates a stateless flow (see `stateless`) whose behaviour is defined as a widget. It is a
-- higuer level form of the latter 
wstateless
  :: (Typeable view,  FormInput view) =>
     View view IO a -> Flow
wstateless w = transient $ runFlow loop
  where
  loop= do
      ask w
      env <- get
      put $ env{ mfSequence= 0} 
      loop


---- This version writes a log with all the values returned by ask
--wstatelessLog
--  :: (Typeable view, ToHttpData view, FormInput view,Serialize a,Typeable a) =>
--     View view IO a -> (Token -> Workflow IO ())
--wstatelessLog w = runFlow loop
--  where
--  loop= do
--      MFlow.Forms.step $ do
--         r <- ask w
--         env <- get
--         put $ env{ mfSequence= 0,prevSeq=[]}
--         return r
--      loop

-- | transfer control to another flow.
transfer :: MonadIO m => String -> FlowM v m ()
transfer flowname =do
         t <- gets mfToken
         let t'= t{twfname= flowname}
         liftIO  $ do
             (r,_) <- msgScheduler t'
             sendFlush t r


-- | Wrap a widget of form element within a form-action element.
---- Usually this is not necessary since this wrapping is done automatically by the @Wiew@ monad.
wform ::  (Monad m, FormInput view)
          => View view m b -> View view m b 

wform x = View $ do
     FormElm form mr <- (runView $   x )
     st <- get
     verb <- getWFName
     form1 <- formPrefix verb st form True
     put st{needForm=False}
     return $ FormElm [form1] mr


formPrefix verb st form anchored= do
     let path  = currentPath (mfPath st) verb
     (anchor,anchorf)
           <- case anchored of
               True -> do
                        anchor <- genNewId
                        return ('#':anchor, (ftag "a") mempty  `attrs` [("name",anchor)])
               False -> return (mempty,mempty)
     return $ formAction (path ++ anchor ) $  mconcat ( anchorf:form)  -- !> anchor

resetButton :: (FormInput view, Monad m) => String -> View view m () 
resetButton label= View $ return $ FormElm [finput  "reset" "reset" label False Nothing]   $ Just ()

submitButton :: (FormInput view, Monad m) => String -> View view m String
submitButton label= getParam Nothing "submit" $ Just label

newtype AjaxSessionId= AjaxSessionId String deriving Typeable

-- | Install the server code and return the client code for an AJAX interaction.
--
-- This example increases the value of a text box each time the box is clicked
--
-- >  ask $ do
-- >        let elemval= "document.getElementById('text1').value"
-- >        ajaxc <- ajax $ \n -> return $ elemval <> "='" <> B.pack(show(read  n +1)) <> "'"
-- >        b <<  text "click the box"
-- >          ++> getInt (Just 0) <! [("id","text1"),("onclick", ajaxc elemval)]
ajax :: (MonadIO m)
     => (String ->  View v m ByteString)  -- ^ user defined procedure, executed in the server.Receives the value of the javascript expression and must return another javascript expression that will be executed in the web browser
     ->  View v m (String -> String)      -- ^ returns a function that accept a javascript expression and return a javascript event handler expression that invoques the ajax server procedure
ajax  f =  do
     requires[JScript ajaxScript]
     t <- gets mfToken
     id <- genNewId
     installServerControl id $ \x-> do
          setSessionData $ AjaxSessionId id
          r <- f x
          liftIO $ sendFlush t  (HttpData [("Content-Type", "text/plain")][] r )
          return ()

installServerControl :: MonadIO m => String -> (String -> View v m ()) -> View v m (String -> String)
installServerControl id f= do
      t <- gets mfToken
      st <- get
      let ajxl = fromMaybe M.empty $ mfAjax st
      let ajxl'= M.insert id (unsafeCoerce f ) ajxl
      put st{mfAjax=Just ajxl'}
      return $ \param ->  "doServer("++"'" ++  twfname t ++"','"++id++"',"++ param++")"

-- | Send the javascript expression, generated by the procedure parameter as a ByteString, execute it in the browser and the result is returned back
--
-- The @ajaxSend@ invocation must be inside a ajax procedure or else a /No ajax session set/ error will be produced
ajaxSend
  :: (Read a,MonadIO m) => View v m ByteString -> View v m a
ajaxSend cmd=  View $ do
   AjaxSessionId id <- getSessionData `onNothing` error "no AjaxSessionId set"
   env <- getEnv
   t <- getToken
   case (lookup "ajax" $ env, lookup "val" env) of
       (Nothing,_) -> return $ FormElm [] Nothing
       (Just id, Just _) -> do
           FormElm __ (Just  str) <- runView  cmd
           liftIO $ sendFlush t  $ HttpData [("Content-Type", "text/plain")][] $ str <>  readEvalLoop t id "''"
           receiveWithTimeouts
           env <- getEnv
           case (lookup "ajax" $ env,lookup "val" env) of
               (Nothing,_) -> return $ FormElm [] Nothing
               (Just id, Just v2) -> do
                    return $ FormElm []  . Just  $ read v2
   where
   readEvalLoop t id v = "doServer('"<> pack (twfname t)<>"','"<> pack id<>"',"<>v<>");" :: ByteString

-- | Like @ajaxSend@ but the result is ignored
ajaxSend_
  :: MonadIO m => View v m ByteString -> View v m ()
ajaxSend_ = ajaxSend


    
-- | Creates a link wiget. A link can be composed with other widget elements,
wlink :: (Typeable a, Show a, MonadIO m,  FormInput view) 
         => a -> view -> View  view m a
wlink x v= View $ do
      verb <- getWFName
      st   <- get
      
      let links= mfLinks st
          name' = map toLower $ if typeOf x== typeOf(undefined :: String)
                                   then unsafeCoerce x
                                   else show x
          env = mfEnv st
          lpath' = mfPath st
          lpath =  if null lpath' then [] else tail $ lpath'
      suffix <- case M.lookup name' links of
            Nothing -> do
                 put st{mfLinks= M.insert name' 1 links}
                 return ""
            Just n  -> do
                 put st{mfLinks= M.insert name' (n+1) links}
                 return $ show n
      let csuffix= let n= mfCallBackSeq st in if n == 0 then "" else show n
      let name= name' ++  csuffix ++ suffix
      let path= currentPath lpath' verb  ++ name 
          toSend = flink path v

      r <- if (not (null lpath)
--             && depth < length lpath
             && elem name lpath) -- lpath !! depth  == name)
--             !> show lpath
--             !> show name
             then do
                  modify $ \s -> s{inSync= True{-,mfLinkSelected=True-} } -- , mfLinkDepth= depth +1 }
                  return $ Just x
             else return Nothing
--           !> ("inc=" ++ show links)
      return $ FormElm [toSend] r


currentPath lpath' verb =
      let lpath  =  if null lpath' then [] else tail $ lpath'
      in if null lpath' then verb
                           else concat ['/':p | p <- lpath']++"/"
-- | When some user interface int return some response to the server, but it is not produced by
-- a form or a link, but for example by an script, @returning@ notify the type checker.
--
-- At runtime the parameter is read from the environment and validated.
--
-- . The parameter is the visualization code, that accept a serialization function that generate
-- the server invocation string, used by the visualization to return the value by means
-- of a link or a @window.location@ statement in javasCript
returning ::(Typeable a, Read a, Show a,Monad m, FormInput view) 
         => ((a->String) ->view) -> View view m a
returning expr=View $ do
      verb <- getWFName
      name <- genNewId
      env  <- gets mfEnv
      let string x=
            let showx= case cast x of
                   Just x' -> x'
                   _       -> show x
            in (verb ++ "?" ++  name ++ "=" ++ showx)
          toSend= expr string
      r <- getParam1 name env
      return $ FormElm [toSend] $ valToMaybe r
      




--instance (Widget a b m view, Monoid view) => Widget [a] b m view where
--  widget xs = View $ do
--      forms <- mapM(\x -> (runView  $  widget x )) xs
--      let vs  = concatMap (\(FormElm v _) -> v) forms
--          res = filter isJust $ map (\(FormElm _ r) -> r) forms
--          res1= if null res then Nothing else head res
--      return $ FormElm [mconcat vs] res1

-- | Concat a list of widgets of the same type, return a the first validated result
firstOf :: (Monoid view, Monad m, Functor m)=> [View view m a]  -> View view m a
firstOf xs= View $ do 
      forms <- mapM runView  xs
      let vs  = concatMap (\(FormElm v _) ->  [mconcat v]) forms
          res = filter isJust $ map (\(FormElm _ r) -> r) forms
          res1= if null res then Nothing else head res
      return $ FormElm  vs res1

-- | from a list of widgets, it return the validated ones.
manyOf :: (FormInput view, MonadIO m, Functor m)=> [View view m a]  -> View view m [a]
manyOf xs= whidden () *> (View $ do 
      forms <- mapM runView  xs
      let vs  = concatMap (\(FormElm v _) ->  [mconcat v]) forms
          
          res1= catMaybes $ map (\(FormElm _ r) -> r) forms
      return $ FormElm  vs $ Just res1)


(>:>) ::(Monad m)=> View v m a -> View v m [a]  -> View v m [a]
(>:>) w ws= View $ do
    FormElm fs mxs <- runView $  ws
    FormElm f1 mx  <- runView w
    return $ FormElm (f1++ fs)
         $ case( mx,mxs) of
             (Just x, Just xs) -> Just $ x:xs
             (Nothing, mxs) -> mxs
             (Just x, _) -> Just [x]

-- | Intersperse a widget in a list of widgets. the results is a 2-tuple of both types.
--
-- it has a infix priority @infixr 5@
(|*>) :: (MonadIO m, Functor m,Monoid view)
            => View view m r
            -> [View view m r']
            -> View view m (Maybe r,Maybe r')
(|*>) x xs= View $ do
  FormElm fxs rxs <-  runView $ firstOf  xs
  FormElm fx rx   <- runView $  x

  return $ FormElm (fx ++ intersperse (mconcat fx) fxs ++ fx)
         $ case (rx,rxs) of
            (Nothing, Nothing) -> Nothing
            other -> Just other



infixr 5 |*>, .|*>.

-- | Put a widget before and after other. Useful for navigation links in a page that appears at toAdd
-- and at the bottom of a page.

-- It has a low infix priority: @infixr 1@
(|+|) :: (Functor m, Monoid view, MonadIO m)
      => View view m r
      -> View view m r'
      -> View view m (Maybe r, Maybe r')
(|+|) w w'=  w |*> [w']

infixr 1 |+|, .|+|.


-- | Flatten a binary tree of tuples of Maybe results produced by the \<+> operator
-- into a single tuple with the same elements in the same order.
-- This is useful for easing matching. For example:
--
-- @ res \<- ask $ wlink1 \<+> wlink2 wform \<+> wlink3 \<+> wlink4@
--
-- @res@  has type:
--
-- @Maybe (Maybe (Maybe (Maybe (Maybe a,Maybe b),Maybe c),Maybe d),Maybe e)@
--
-- but @flatten res@ has type:
--
-- @ (Maybe a, Maybe b, Maybe c, Maybe d, Maybe e)@

flatten :: Flatten (Maybe tree) list => tree -> list
flatten res= doflat $ Just res

class Flatten tree list  where
 doflat :: tree -> list


type Tuple2 a b= Maybe (Maybe a, Maybe b)
type Tuple3 a b c= Maybe ( (Tuple2 a b), Maybe c)
type Tuple4 a b c d= Maybe ( (Tuple3 a b c), Maybe d)
type Tuple5 a b c d e= Maybe ( (Tuple4 a b c d), Maybe e)
type Tuple6 a b c d e f= Maybe ( (Tuple5 a b c d e), Maybe f)

instance Flatten (Tuple2 a b) (Maybe a, Maybe b) where
  doflat (Just(ma,mb))= (ma,mb)
  doflat Nothing= (Nothing,Nothing)

instance Flatten (Tuple3 a b c) (Maybe a, Maybe b,Maybe c) where
  doflat (Just(mx,mc))= let(ma,mb)= doflat mx in (ma,mb,mc)
  doflat Nothing= (Nothing,Nothing,Nothing)

instance Flatten (Tuple4 a b c d) (Maybe a, Maybe b,Maybe c,Maybe d) where
  doflat (Just(mx,mc))= let(ma,mb,md)= doflat mx in (ma,mb,md,mc)
  doflat Nothing= (Nothing,Nothing,Nothing,Nothing)

instance Flatten (Tuple5 a b c d e) (Maybe a, Maybe b,Maybe c,Maybe d,Maybe e) where
  doflat (Just(mx,mc))= let(ma,mb,md,me)= doflat mx in (ma,mb,md,me,mc)
  doflat Nothing= (Nothing,Nothing,Nothing,Nothing,Nothing)

instance Flatten (Tuple6 a b c d e f) (Maybe a, Maybe b,Maybe c,Maybe d,Maybe e,Maybe f) where
  doflat (Just(mx,mc))= let(ma,mb,md,me,mf)= doflat mx in (ma,mb,md,me,mf,mc)
  doflat Nothing= (Nothing,Nothing,Nothing,Nothing,Nothing,Nothing)

infixr 7 .<<.
-- | > (.<<.) w x = w $ toByteString x
(.<<.) :: (FormInput view) => (ByteString -> ByteString) -> view -> ByteString
(.<<.) w x = w ( toByteString x)

-- | > (.<+>.) x y = normalize x <+> normalize y
(.<+>.)
  :: (Monad m, FormInput v, FormInput v1) =>
     View v m a -> View v1 m b -> View ByteString m (Maybe a, Maybe b)
(.<+>.) x y = normalize x <+> normalize y

-- | > (.|*>.) x y = normalize x |*> map normalize y
(.|*>.)
  :: (Functor m, MonadIO m, FormInput v, FormInput v1) =>
     View v m r
     -> [View v1 m r'] -> View ByteString m (Maybe r, Maybe r')
(.|*>.) x y = normalize x |*> map normalize y

-- | > (.|+|.) x y = normalize x |+| normalize y
(.|+|.)
  :: (Functor m, MonadIO m, FormInput v, FormInput v1) =>
     View v m r -> View v1 m r' -> View ByteString m (Maybe r, Maybe r')
(.|+|.) x y = normalize x |+| normalize y

-- | > (.**>.) x y = normalize x **> normalize y
(.**>.)
  :: (Monad m, Functor m, FormInput v, FormInput v1) =>
     View v m a -> View v1 m b -> View ByteString m b
(.**>.) x y = normalize x **> normalize y

-- | > (.<**.) x y = normalize x <** normalize y
(.<**.)
  :: (Monad m, Functor m, FormInput v, FormInput v1) =>
     View v m a -> View v1 m b -> View ByteString m a
(.<**.) x y = normalize x <** normalize y

-- | > (.<|>.) x y= normalize x <|> normalize y
(.<|>.)
  :: (Monad m, Functor m, FormInput v, FormInput v1) =>
     View v m a -> View v1 m a -> View ByteString m a
(.<|>.) x y= normalize x <|> normalize y

-- | > (.<++.) x v= normalize x <++ toByteString v
(.<++.) :: (Monad m, FormInput v, FormInput v') => View v m a -> v' -> View ByteString m a
(.<++.) x v= normalize x <++ toByteString v

-- | > (.++>.) v x= toByteString v ++> normalize x
(.++>.) :: (Monad m, FormInput v, FormInput v') => v -> View v' m a -> View ByteString m a
(.++>.) v x= toByteString v ++> normalize x


instance FormInput  ByteString  where
    toByteString= id
    toHttpData = HttpData [contentHtml ] []
    ftag x= btag x []
    inred = btag "b" [("style", "color:red")]
    finput n t v f c= btag "input"  ([("type", t) ,("name", n),("value",  v)] ++ if f then [("checked","true")]  else []
                              ++ case c of Just s ->[( "onclick", s)]; _ -> [] ) ""
    ftextarea name text= btag "textarea"  [("name", name)]   $ pack text

    fselect name   options=  btag "select" [("name", name)]   options

    foption value content msel= btag "option" ([("value",  value)] ++ selected msel)   content
            where
            selected msel = if  msel then [("selected","true")] else []

    attrs = addAttrs


    formAction action form = btag "form" [("action", action),("method", "post")]  form
    fromStr = pack
    fromStrNoEncode= pack

    flink  v str = btag "a" [("href",  v)]  str



