# Update-ArcDPS
#### Update ArcDPS and optionally Start Guild Wars 2 after (so you can use a shortcut to this script instead of the traditional launcher)
---

## Installation
#### There are two options, depending on how much you trust me.

### The easy way
1. Right click on your Start button and click "Run", or press Ctrl+R on your keyboard.
    ![Right Clicking Run](./docs_run.png)
1. Copy the following and paste it into the "Open:" text box:
```
powershell -c "[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; ; iex(New-Object Net.WebClient).DownloadString('https://github.com/solacelost/update-arcdps/raw/master/Bootstrap-ArcDPS.ps1')"
```
    ![Run Dialog](./docs_run2.png)
1. Press OK on the Run dialog. Press Enter when prompted to close the window.
1. Double-click the Update-ArcDPS Setup shortcut on your desktop to pick up below at the -CreateShortcut point.
    ![Setup Shortcut](./docs_setup_sortcut.png)

### The auditable way
1. Download the latest Release from [the releases page](https://github.com/solacelost/update-arcdps/releases).
1. Unzip it to the directory of your choice - the location doesn't matter
1. Review the script on your computer to ensure you're okay with what it does - you only need the Update-ArcDPS.ps1 script, not the Bootstrap
1. Open a PowerShell window with the -executionpolicy Bypass option set and run the script with -CreateShortcut:
    1. Suppose you unzipped Update-ArcDPS.ps1 to your Desktop on the user named James
    1. Right click on your Start button and click "Run", or press Ctrl+R on your keyboard.
    1. Type "powershell -executionpolicy bypass" into the "Open" text box and press "OK"
    1. You get a prompt that looks like this: `PS C:\Users\James>` and a blinking cursor.
    1. Run the script with the -CreateShortcut option switch set for initial setup and shortcut creation:
        `Desktop\Update-ArcDPS.ps1 -CreateShortcut`

### Both methods of installation are now at this point
1. You will see output like this during the first run:
    ![Intial Setup](./docs_initialsetup.png)
1. This means it has already found Guild Wars 2 on your computer (It starts by looking in Program Files, but will expand to looking at every drive it can find)
    - If you have multiple GW2 installations (multiboxing), it will simply pick the first one it finds. If you're multiboxing, I suspect you can dig through the script and figure out what to change if you wanted it to be a different one. It's not going to officially be supported, sorry.
1. Select the addons you would like to enable (reference the [ArcDPS README](https://www.deltaconnected.com/arcdps/) for information about these addons... I like Build Templates)
1. The script will go to the offical [ArcDPS installation sources](https://www.deltaconnected.com/arcdps/x64) and download everything, then create your shortcut and save the answers to the above queries/detections in a file. The final output will look something like this:
    ![Complete Setup](./docs_completeinstall.png)

### Update-ArcDPS is now installed and configured
You can double-click on the "Guild Wars 2 - ArcDPS" shortcut to automatically update ArcDPS to the newest version then launch Guild Wars 2 every time.

## Uninstallation
#### You need to run the script with the -Remove switch
The easiest way to do that is to manipulate the existing shortcut
1. Right click on the "Guild Wars 2 - ArcDPS" shortcut and select properties
    ![Shortcut Properties](./docs_shortcut.png)
1. At the end of the "Target:" textbox, you should see `-StartGW`. Replace that with `-Remove` and click "OK" to save the shortcut.
1. Double-click the modified shortcut. Update-ArcDPS will remove the shortcut as part of the uninstallation, too, so it's all gone!

## To do:
- [x] Make it better than it used to be
- [ ] Provide for auto-update of Update-ArcDPS (wow that's meta)
- [x] Make a real installer of some sort, or at least require less interactivity, since people seem to have a hard time with ExecutionPolicy
