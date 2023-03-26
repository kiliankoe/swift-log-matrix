# LoggingMatrix 

This is a logging backend for [SwiftLog](https://github.com/apple/swift-log) that sends messages to a [Matrix](https://matrix.org) channel of your choice.

Inspired by [LoggingTelegram](https://github.com/stevapple/swift-log-telegram).

## Installation

Add the package as a dependency to your manifest file:

```swift
.package(url: "https://github.com/kiliankoe/swift-log-matrix.git", from: <#current#>)
```

Don't forget to list it as a dependency of your target as well:

```swift
.product(name: "LoggingMatrix", package: "swift-log-matrix"),
```

## Usage

```swift
import Logging
import LoggingMatrix

LoggingSystem.bootstrap { label in
    MultiplexLogHandler([
        // Default stdout logger
        StreamLogHandler.standardOutput(label: label),
        
        MatrixLogHandler(
            label: label,
            homeserver: URL(string: "<#Homeserver URL#>")!,
            roomID: "<#Room ID#>",
            accessToken: "<#Access Token#>"
        ),
    ])
}
```

You need three things to configure the Matrix logger to be able to send messages, your homeserver URL (for example https://matrix.org), a room ID (of the format `!xxxxxxxxxxxxxxx:homeserver.tld`) and an access token.

The room ID can be found in the room settings of most clients, the access token in the account settings (in Element it's under Settings > Help & About > Advanced).

The log level defaults to only send `critical` logs to Matrix, feel free to set that to whatever works best for your use-case, but it's recommended to not send too many logs to your homeserver, especially if you're not running it yourself.

Now you can just log messages as usual!

```swift
logger.debug("Some debug message")
logger.error("Oh no, an error occurred!", metadata: ["important context": "some value here"])
```

![screenshot](https://user-images.githubusercontent.com/2625584/227747613-b1a08d79-71d8-4338-b020-f2f6de87ec4d.png)

⚠️ Please be aware that messages are *not* sent using Matrix' end-to-end encryption, they are being sent unencrypted.
