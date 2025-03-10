//
//  AppIntent.swift
//  FocusBuddyWidget
//
//  Created by jolin on 2025/3/10.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "专注计时" }
    static var description: IntentDescription { "显示当前专注任务的进度" }
    
    func perform() async throws -> some IntentResult {
        return .result()
    }
}
