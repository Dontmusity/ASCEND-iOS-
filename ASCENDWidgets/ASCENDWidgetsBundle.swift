import WidgetKit
import SwiftUI

@main
struct ASCENDWidgetsBundle: WidgetBundle {
    var body: some Widget {
        NowWidget()
        MonthWidget()
        HabitsWidget()
        FocusShortcutWidget()
        FocusLiveActivityWidget()
    }
}
