------------------------------------------------------------------------
---IMPORTS
------------------------------------------------------------------------
    -- Base
import XMonad
import XMonad.Config.Desktop
import Data.Monoid
import Data.Maybe (isJust)
import System.IO (hPutStrLn, hSetEncoding, stdout, utf8)
import System.Exit (exitSuccess)
import qualified XMonad.StackSet as W

    -- Utilities
import XMonad.Util.Loggers
import XMonad.Util.EZConfig (additionalKeysP, additionalMouseBindings)
import XMonad.Util.NamedScratchpad
import XMonad.Util.Run (safeSpawn, unsafeSpawn, runInTerm, spawnPipe)
import XMonad.Util.SpawnOnce

    -- Hooks
import XMonad.Hooks.DynamicLog (dynamicLogWithPP, defaultPP, wrap, pad, xmobarPP, xmobarColor, shorten, PP(..))
import XMonad.Hooks.ManageDocks (avoidStruts, docksStartupHook, manageDocks, ToggleStruts(..))
import XMonad.Hooks.ManageHelpers (isFullscreen, isDialog,  doFullFloat, doCenterFloat)
import XMonad.Hooks.Place (placeHook, withGaps, smart)
import XMonad.Hooks.SetWMName
import XMonad.Hooks.EwmhDesktops   -- required for xcomposite in obs to work
import XMonad.Hooks.Script         -- required for executing script at .xmonad/hooks

    -- Actions
--import XMonad.Hooks.Minimize (minimizeWindow)
import XMonad.Actions.Promote
import XMonad.Actions.RotSlaves (rotSlavesDown, rotAllDown)
import XMonad.Actions.CopyWindow (kill1, copyToAll, killAllOtherCopies, runOrCopy)
import XMonad.Actions.WindowGo (runOrRaise, raiseMaybe)
import XMonad.Actions.WithAll (sinkAll, killAll)
import XMonad.Actions.CycleWS (moveTo, shiftTo, WSType(..), shiftNextScreen, shiftPrevScreen)
import XMonad.Actions.GridSelect (GSConfig(..), goToSelected, bringSelected, colorRangeFromClassName, buildDefaultGSConfig)
import XMonad.Actions.DynamicWorkspaces (addWorkspacePrompt, removeEmptyWorkspace)
import XMonad.Actions.MouseResize
import qualified XMonad.Actions.ConstrainedResize as Sqr

    -- Layouts modifiers
import XMonad.Layout.PerWorkspace (onWorkspace)
import XMonad.Layout.Renamed (renamed, Rename(CutWordsLeft, Replace))
import XMonad.Layout.WorkspaceDir
import XMonad.Layout.Spacing (spacing)
import XMonad.Layout.NoBorders
import XMonad.Layout.LimitWindows (limitWindows, increaseLimit, decreaseLimit)
import XMonad.Layout.WindowArranger (windowArrange, WindowArrangerMsg(..))
import XMonad.Layout.Reflect (reflectVert, reflectHoriz, REFLECTX(..), REFLECTY(..))
import XMonad.Layout.MultiToggle (mkToggle, single, EOT(EOT), Toggle(..), (??))
import XMonad.Layout.MultiToggle.Instances (StdTransformers(NBFULL, MIRROR, NOBORDERS))
import qualified XMonad.Layout.ToggleLayouts as T (toggleLayouts, ToggleLayout(Toggle))

    -- Layouts
import XMonad.Layout.GridVariants (Grid(Grid))
import XMonad.Layout.SimplestFloat
import XMonad.Layout.OneBig
import XMonad.Layout.ThreeColumns
import XMonad.Layout.ResizableTile
import XMonad.Layout.ZoomRow (zoomRow, zoomIn, zoomOut, zoomReset, ZoomMessage(ZoomFullToggle))
import XMonad.Layout.IM (withIM, Property(Role))

    -- Prompts
import XMonad.Prompt (defaultXPConfig, XPConfig(..), XPPosition(Top), Direction1D(..))

------------------------------------------------------------------------
---CONFIG
------------------------------------------------------------------------
myModMask       = mod4Mask  -- Sets modkey to super/windows key
myTerminal      = "xfce4-terminal"      -- Sets default terminal
myTextEditor    = "vim"     -- Sets default text editor
myBorderWidth   = 2         -- Sets border width for windows
windowCount     = gets $ Just . show . length . W.integrate' . W.stack . W.workspace . W.current . windowset

main = do
    xmproc0 <- spawnPipe "xmobar -x 0 /home/daniel/.config/xmobar/xmobarrc1" -- xmobar mon 1
    xmproc1 <- spawnPipe "xmobar -x 0 /home/daniel/.config/xmobar/xmobarrc0" -- xmobar mon 1
    xmproc2 <- spawnPipe "xmobar -x 1 /home/daniel/.config/xmobar/xmobarrc1" -- xmobar mon 2
    xmproc3 <- spawnPipe "xmobar -x 1 /home/daniel/.config/xmobar/xmobarrc0" -- xmobar mon 2

    --hSetEncoding xmproc0 utf8
    --hSetEncoding xmproc1 utf8
    --hSetEncoding xmproc2 utf8
    --hSetEncoding xmproc3 utf8

    xmonad $ ewmh desktopConfig
        { manageHook =  myManageHook <+> ( isFullscreen --> doFullFloat ) <+> manageHook desktopConfig <+> manageDocks
        , logHook = dynamicLogWithPP xmobarPP
                        { ppOutput = \x -> hPutStrLn xmproc0 x  >> hPutStrLn xmproc1 x >> hPutStrLn xmproc2 x >> hPutStrLn xmproc3 x
                        , ppCurrent = xmobarColor "#c3e88d" "" . wrap "[" "]" -- Current workspace in xmobar
                        , ppVisible = xmobarColor "#c3e88d" ""                -- Visible but not current workspace
                        , ppHidden = xmobarColor "#82AAFF" "" . wrap "*" ""   -- Hidden workspaces in xmobar
                        , ppHiddenNoWindows = xmobarColor "#F07178" ""        -- Hidden workspaces (no windows)
                        , ppTitle = xmobarColor "#d0d0d0" "" . shorten 120     -- Title of active window in xmobar
                        , ppSep =  "<fc=#9AEDFE> : </fc>"                     -- Separators in xmobar
                        , ppUrgent = xmobarColor "#C45500" "" . wrap "!" "!"  -- Urgent workspace
                        , ppExtras  = [windowCount]                           -- # of windows current workspace
                        --, ppOrder  = \(ws:l:t:ex) -> [ws,l]++ex++[t]
                        , ppOrder  = \(ws:l:t:ex) -> [ws,l]++ex++[]
                        } <+> dynamicLogWithPP xmobarPP -- config for the second xmobar
                        { ppOutput = hPutStrLn xmproc1
                        , ppTitle = xmobarColor "#F07178" "" . shorten 120     -- Title of active window in xmobar
                        , ppOrder  = \(ws:l:t:ex) -> []++ex++[t]
                        } <+> dynamicLogWithPP xmobarPP -- config for the second xmobar on the second monitor
                        { ppOutput = hPutStrLn xmproc3
                        , ppTitle = xmobarColor "#F07178" "" . shorten 120     -- Title of active window in xmobar
                        , ppOrder  = \(ws:l:t:ex) -> []++ex++[t]
                        }

        , modMask            = myModMask
        --, handleEventHook    = fullscreenEventHook
        , terminal           = myTerminal
        , startupHook        = myStartupHook
        , layoutHook         = myLayoutHook
        , workspaces         = myWorkspaces
        , borderWidth        = myBorderWidth
        , normalBorderColor  = "#292d3e"
        , focusedBorderColor = "#bbc5ff"
        } `additionalKeysP`         myKeys

------------------------------------------------------------------------
---AUTOSTART
------------------------------------------------------------------------
myStartupHook = do
        execScriptHook "startup"
        spawnOnce "xset m 0 0";
        spawnOnce "xrandr --output DVI-D-0 --primary --auto --right-of HDMI-1";
        spawnOnce "xsetroot -cursor_name left_ptr";
        spawnOnce "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
        spawnOnce "/usr/bin/trayer --edge top --align right --SetDockType true --SetPartialStrut true --expand true --width 15 --transparent true --alpha 0 --tint 0x292d3e --height 19 &";
        spawnOnce "volumeicon &"
        spawnOnce "nm-applet"
        spawnOnce "dropbox start"
        spawnOnce "nitrogen --restore"
        spawnOnce "compton &"
        spawnOnce "redshift-gtk -t 3800:3800";

------------------------------------------------------------------------
---KEYBINDINGS
------------------------------------------------------------------------
myKeys =
    -- Xmonad
        [ ("M-C-r", spawn "xmonad --recompile")      -- Recompiles xmonad
        , ("M-S-r", spawn "xmonad --restart")        -- Restarts xmonad
        , ("M-S-z", io exitSuccess)                  -- Quits xmonad
        , ("M-q", spawn "")                          -- Disabling default keybind

    -- Windows
        , ("M-S-q", kill1)                           -- Kill the currently focused client
        , ("M-S-a", killAll)                         -- Kill all the windows on current workspace

    -- Floating windows
        , ("M-<Delete>", withFocused $ windows . W.sink)  -- Push floating window back to tile.
        , ("M-S-<Delete>", sinkAll)                  -- Push ALL floating windows back to tile.

    -- Windows navigation
        --, ("M-m", windows W.focusMaster)             -- Move focus to the master window
        , ("M-j", windows W.focusDown)               -- Move focus to the next window
        , ("M-k", windows W.focusUp)                 -- Move focus to the prev window
        , ("M-S-m", windows W.swapMaster)            -- Swap the focused window and the master window
        , ("M-S-j", windows W.swapDown)              -- Swap the focused window with the next window
        , ("M-S-k", windows W.swapUp)                -- Swap the focused window with the prev window
        , ("M-<Backspace>", promote)                 -- Moves focused window to master, all others maintain order
        , ("M1-S-<Tab>", rotSlavesDown)              -- Rotate all windows except master and keep focus in place
        , ("M1-C-<Tab>", rotAllDown)                 -- Rotate all the windows in the current stack
        , ("M-S-s", windows copyToAll)
        , ("M-C-s", killAllOtherCopies)

        , ("M-C-M1-<Up>", sendMessage Arrange)
        , ("M-C-M1-<Down>", sendMessage DeArrange)
        , ("M-<Up>", sendMessage (MoveUp 10))             --  Move focused window to up
        , ("M-<Down>", sendMessage (MoveDown 10))         --  Move focused window to down
        , ("M-<Right>", sendMessage (MoveRight 10))       --  Move focused window to right
        , ("M-<Left>", sendMessage (MoveLeft 10))         --  Move focused window to left
        , ("M-S-<Up>", sendMessage (IncreaseUp 10))       --  Increase size of focused window up
        , ("M-S-<Down>", sendMessage (IncreaseDown 10))   --  Increase size of focused window down
        , ("M-S-<Right>", sendMessage (IncreaseRight 10)) --  Increase size of focused window right
        , ("M-S-<Left>", sendMessage (IncreaseLeft 10))   --  Increase size of focused window left
        , ("M-C-<Up>", sendMessage (DecreaseUp 10))       --  Decrease size of focused window up
        , ("M-C-<Down>", sendMessage (DecreaseDown 10))   --  Decrease size of focused window down
        , ("M-C-<Right>", sendMessage (DecreaseRight 10)) --  Decrease size of focused window right
        , ("M-C-<Left>", sendMessage (DecreaseLeft 10))   --  Decrease size of focused window left

    -- Layouts
        , ("M-<Space>", sendMessage NextLayout)                              -- Switch to next layout
        --, ("M-S-<Space>", sendMessage ToggleStruts)                          -- Toggles struts
        , ("M-S-b", sendMessage $ Toggle NOBORDERS)                          -- Toggles noborder
        , ("M-S-=", sendMessage (Toggle NBFULL) >> sendMessage ToggleStruts) -- Toggles noborder/full
        , ("M-S-f", sendMessage (T.Toggle "float"))
        --, ("M-S-x", sendMessage $ Toggle REFLECTX)
        , ("M-S-y", sendMessage $ Toggle REFLECTY)
        , ("M-S-m", sendMessage $ Toggle MIRROR)
        , ("M-<KP_Multiply>", sendMessage (IncMasterN 1))   -- Increase number of clients in the master pane
        , ("M-<KP_Divide>", sendMessage (IncMasterN (-1)))  -- Decrease number of clients in the master pane
        , ("M-S-<KP_Multiply>", increaseLimit)              -- Increase number of windows that can be shown
        , ("M-S-<KP_Divide>", decreaseLimit)                -- Decrease number of windows that can be shown

        , ("M-C-h", sendMessage Shrink)
        , ("M-C-l", sendMessage Expand)
        , ("M-C-j", sendMessage MirrorShrink)
        , ("M-C-k", sendMessage MirrorExpand)
        , ("M-S-;", sendMessage zoomReset)
        , ("M-;", sendMessage ZoomFullToggle)

    -- Workspaces
        , ("M-<KP_Add>", moveTo Next nonNSP)                                -- Go to next workspace
        , ("M-<KP_Subtract>", moveTo Prev nonNSP)                           -- Go to previous workspace
        , ("M-S-<KP_Add>", shiftTo Next nonNSP >> moveTo Next nonNSP)       -- Shifts focused window to next workspace
        , ("M-S-<KP_Subtract>", shiftTo Prev nonNSP >> moveTo Prev nonNSP)  -- Shifts focused window to previous workspace

    -- Main Run Apps
        , ("M-<Return>", spawn myTerminal)
        , ("M-S-x", spawn "i3lock --color 475263")
        , ("M-d", spawn "rofi -show run")
        , ("M-w", spawn "chromium")
        , ("M-n", spawn "pcmanfm")
        , ("M-m", spawn "xfce4-terminal -e vifm")
        , ("M-<KP_Insert>", spawn "dmenu_run -fn 'UbuntuMono Nerd Font:size=10' -nb '#292d3e' -nf '#bbc5ff' -sb '#82AAFF' -sf '#292d3e' -p 'dmenu:'")


    -- Multimedia Keys
        --, ("<XF86AudioPlay>", spawn "cmus toggle")
        --, ("<XF86AudioPrev>", spawn "cmus prev")
        --, ("<XF86AudioNext>", spawn "cmus next")
        ---- , ("<XF86AudioMute>",   spawn "amixer set Master toggle")  -- Bug prevents it from toggling correctly in 12.04.
        --, ("<XF86AudioLowerVolume>", spawn "amixer set Master 5%- unmute")
        --, ("<XF86AudioRaiseVolume>", spawn "amixer set Master 5%+ unmute")
        --, ("<XF86HomePage>", spawn "firefox")
        --, ("<XF86Search>", safeSpawn "firefox" ["https://www.google.com/"])
        --, ("<XF86Mail>", runOrRaise "geary" (resource =? "thunderbird"))
        --, ("<XF86Calculator>", runOrRaise "gcalctool" (resource =? "gcalctool"))
        --, ("<XF86Eject>", spawn "toggleeject")
        , ("<Print>", spawn "xfce4-screenshooter")
        , ("C-S-<Escape>", spawn "termite -e htop")
        ] where nonNSP          = WSIs (return (\ws -> W.tag ws /= "nsp"))
                nonEmptyNonNSP  = WSIs (return (\ws -> isJust (W.stack ws) && W.tag ws /= "nsp"))

------------------------------------------------------------------------
---WORKSPACES
------------------------------------------------------------------------

xmobarEscape = concatMap doubleLts
  where
        doubleLts '<' = "<<"
        doubleLts x   = [x]

myWorkspaces :: [String]
myWorkspaces = clickable . (map xmobarEscape)
               $ [" 1 ", " 2 ", " 3 ", " 4 ", " 5 ", " 6 ", " 7 ", " 8 ", " 9 "]
  where
        clickable l = [ "<action=xdotool key super+" ++ show (n) ++ ">" ++ ws ++ "</action>" |
                      (i,ws) <- zip [1..9] l,
                      let n = i ]
myManageHook :: Query (Data.Monoid.Endo WindowSet)
myManageHook = composeAll
     [     
        className =? "Firefox"     --> doShift "<action=xdotool key super+2>2</action>"
      , title =? "Vivaldi"         --> doShift "<action=xdotool key super+2>www</action>"
      , title =? "irssi"           --> doShift "<action=xdotool key super+6>chat</action>"
      , title =? "cmus"            --> doFloat
      , className =? "vlc"         --> doShift "<action=xdotool key super+7>media</action>"
      , className =? "Virtualbox"  --> doFloat
      , className =? "Gimp"        --> doFloat
      , className =? "Gimp"        --> doShift "<action=xdotool key super+8>gfx</action>"
      , (className =? "Firefox" <&&> resource =? "Dialog") --> doFloat  -- Float Firefox Dialog
     ]

------------------------------------------------------------------------
---LAYOUTS
------------------------------------------------------------------------

myLayoutHook = smartBorders . avoidStruts $ mouseResize $ windowArrange $ T.toggleLayouts floats $
               mkToggle (NBFULL ?? NOBORDERS ?? EOT) $ myDefaultLayout
             where
                 myDefaultLayout = noBorders monocle ||| tall ||| grid ||| space ||| floats ||| threeCol ||| threeRow ||| oneBig


tall       = renamed [Replace "tall"]     $ limitWindows 12 $ spacing 6 $ ResizableTall 1 (3/100) (1/2) []
grid       = renamed [Replace "grid"]     $ limitWindows 12 $ spacing 6 $ mkToggle (single MIRROR) $ Grid (16/10)
threeCol   = renamed [Replace "threeCol"] $ limitWindows 3  $ ThreeCol 1 (3/100) (1/2)
threeRow   = renamed [Replace "threeRow"] $ limitWindows 3  $ Mirror $ mkToggle (single MIRROR) zoomRow
oneBig     = renamed [Replace "oneBig"]   $ limitWindows 6  $ Mirror $ mkToggle (single MIRROR) $ mkToggle (single REFLECTX) $ mkToggle (single REFLECTY) $ OneBig (5/9) (8/12)
monocle    = renamed [Replace "monocle"]  $ limitWindows 20 $ Full
space      = renamed [Replace "space"]    $ limitWindows 4  $ spacing 12 $ Mirror $ mkToggle (single MIRROR) $ mkToggle (single REFLECTX) $ mkToggle (single REFLECTY) $ OneBig (2/3) (2/3)
floats     = renamed [Replace "floats"]   $ limitWindows 20 $ simplestFloat
