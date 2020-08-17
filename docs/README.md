# Update-ArcDPS

Update ArcDPS, TacO, and Tekkit's Workshop marker pack. Start Guild Wars 2 afterwards (so you can use a shortcut to this script instead of the default shortcut)

---

## Why

[ArcDPS](https://www.deltaconnected.com/arcdps/) is a DPS meter addon provided by some cool dudes over at deltaconnected. It helps you to improve your own ability to play the game by giving you a better idea of how you're doing. It also shows you how everyone else is doing, and provides you the ability to be a total jerk to people who aren't as invested in the game as you. Don't do that. Help them understand more, and let them play the game on their own terms - if they really don't want to perform better on the meters, that's their own perogative. Let everyone have fun playing the game the way they want!

[GW2TacO](http://www.gw2taco.com/) is a Tactical Overlay for Guild Wars 2 that lets you see tons of extra content overlayed on top of the Guild Wars 2 window, when it's in Full Screen Windowed (Borderless) mode. This extra overlay can show you the paths to follow to farm a map efficiently, how to complete a jumping puzzle, where traps are in a piece of content, and more.

[Tekkit's Workshop](http://www.tekkitsworkshop.net/) is where one of the most subscribed Guild Wars 2 YouTubers keeps his advanced content packs for GW2TacO. He has some of the best routes, always updates with the newest content, and generally ensures his markers are aesthetically pleasing and easy to see and use in-game.

Some of my guild mates had a hard time downloading ArcDPS or remembering how to keep it updated. Adding GW2TacO and a separate marker pack to the mix just made it worse. There are solutions out there for keeping them updated, but none of them were really "easy." Some of the solutions work well, but don't do everything transparently. I wanted a truly turnkey solution for them that would keep it updated, stay out of their way, and let those with weird situations tinker with the code themselves. This was my answer.

### A quick note about Internet Explorer

I make heavy use of the `Invoke-WebRequest` cmdlet for PowerShell throughout this project. For `Update-TacO` in particular, I use the advanced HTML parsing provided and can't set the `-UseBasicParsing` flag. This requires that you have at least started Internet Explorer at some point and chosen Express or Custom settings on the user that is running the script. If you get an error while trying to update TacO and Tekkit's, consider firing up Internet Explorer to see if you get the prompt and if answering it resolves the issue. I could do something like [this](https://stackoverflow.com/a/58465946), but I'm pretty sure there would be pitchforks if I started editing registry keys for you.

## Installation

NOTICE: This section is under construction.

## Uninstallation

NOTICE: This section is under construction

## Special Thanks

Special thanks to those who gave me feedback, logs, access to their screens, and absolutely _invaluable_ testing time getting this all working!

- Elven Chaos
  - For an insane amount of testing, feedback, and help. Basically the QA director. I should probably pay him.
- XJay5
  - For lots of help finding and fixing new and elaborate kinds of bugs.
- Bear Empress
  - For letting me run random crap on her computer to increase my testing pool size.
