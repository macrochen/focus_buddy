//
//  FocusBuddyWidgetLiveActivity.swift
//  FocusBuddyWidget
//
//  Created by jolin on 2025/3/10.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct FocusBuddyWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct FocusBuddyWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusBuddyWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension FocusBuddyWidgetAttributes {
    fileprivate static var preview: FocusBuddyWidgetAttributes {
        FocusBuddyWidgetAttributes(name: "World")
    }
}

extension FocusBuddyWidgetAttributes.ContentState {
    fileprivate static var smiley: FocusBuddyWidgetAttributes.ContentState {
        FocusBuddyWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: FocusBuddyWidgetAttributes.ContentState {
         FocusBuddyWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: FocusBuddyWidgetAttributes.preview) {
   FocusBuddyWidgetLiveActivity()
} contentStates: {
    FocusBuddyWidgetAttributes.ContentState.smiley
    FocusBuddyWidgetAttributes.ContentState.starEyes
}
