# UnplugWarning
UnplugWarning is a macOS app that notifies you when your device is unplugged.

## Usage
There is no visual feedback when UnplugWarning is launched. You can check to be sure it is active by running `pidof UnplugWarning` or by searching for it in the Activity Monitor.

## Obnoxious Notifications
You cannot disable notifications from UnplugWarning. If you do not grant it notification access, it will resort to using the "obnoxious" notifications. These horrible looking notifications forcibly overlay every other app on the system and cannot be focused, thereby preventing quitting using key combinations. The only way to avoid getting these obnoxious notifications is granting UnplugWarning "Banners" or "Alerts" notification access in System Preferences.

## Killing UnplugWarning
You can kill UnplugWarning by executing `killall UnplugWarning` or by killing it in Activity Monitor.

## License
[MIT](LICENSE)
