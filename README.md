![macos-version](https://img.shields.io/badge/macOS-11+-blue)

# SwiftXcodeSelect
GUI for the xcode-select command line tool to run in Jamf Self Service


SwiftXcodeSelect is an [open source](https://github.com/gilburns/SwiftXcodeSelect/blob/main/LICENSE) utility for macOS 11+ that creates a graphical interface for xcode-select command line tool. It will popup a dialog via a Jamf Self Service task, allowing non-admin users to specify the default Xcode tools on the system.

![SwiftXcodeSelect](https://github.com/gilburns/SwiftXcodeSelect/blob/main/Images/Xcode%20select%20GUI%20window.png?raw=true)

Inspiration for this tool comes from this [blog](https://smithjw.me/2022/05/20/Installing-Xcode-xip/) post about installing multiple Xcode versions via Jamf Self Service from [James Smith](https://smithjw.me). The [gist](https://gist.github.com/smithjw/b61a180b099624cebf61a8460fc594ed) can be found here.

The latest version can be found on the [Releases](https://github.com/gilburns/SwiftXcodeSelect/releases) page

Detailed documentation and information can be found in the [Wiki](https://github.com/gilburns/SwiftXcodeSelect/wiki)

SwiftXcodeSelect does require and utilize **swiftDialog** for all the notification dialogs. Please visit this page for more details: [Releases](https://github.com/bartreardon/Dialog/releases)

# Giving Feedback
If there are bugs or ideas, please create an [issue](https://github.com/gilburns/SwiftXcodeSelect/issues/new/choose) so your idea can be included.
