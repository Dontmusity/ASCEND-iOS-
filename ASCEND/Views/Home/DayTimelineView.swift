import SwiftUI

struct DayTimelineView: View {
    let title: String
    let icon: String
    let accentColor: Color
    let events: [CalendarEvent]
    var onAddEvent: (() -> Void)? = nil

    private let startHour = 6
    private let endHour = 23
    private let hourHeight: CGFloat = 60

    private var sortedEvents: [CalendarEvent] {
        events.sorted { $0.startHour < $1.startHour }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(accentColor)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.ascendTextPrimary)
                Spacer()
                if let onAddEvent {
                    Button(action: onAddEvent) {
                        Image(systemName: "plus").foregroundColor(.ascendGray)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel("Agregar evento a \(title)")
                }
            }
            .padding(.horizontal, 20)
            .accessibilityElement(children: .combine)

            ScrollView {
                ZStack(alignment: .topLeading) {
                    VStack(spacing: 0) {
                        ForEach(startHour...endHour, id: \.self) { hour in
                            HStack(alignment: .top) {
                                Text(String(format: "%02d:00", hour))
                                    .font(.caption2)
                                    .foregroundColor(.ascendTextSecondary)
                                    .minimumScaleFactor(0.7)
                                    .frame(width: 44, alignment: .leading)
                                Divider()
                            }
                            .frame(height: hourHeight, alignment: .top)
                        }
                    }
                    .padding(.horizontal, 20)
                    .accessibilityHidden(true)

                    ForEach(sortedEvents) { event in
                        eventCard(event)
                            .padding(.leading, 68)
                            .padding(.trailing, 20)
                            .offset(y: CGFloat(event.startHour - Double(startHour)) * hourHeight)
                    }
                }
                .overlay(alignment: .center) {
                    if events.isEmpty {
                        emptyState
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Agenda de \(title)")
        }
    }

    private func eventCard(_ event: CalendarEvent) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(event.title)
                .font(.subheadline.bold())
                .foregroundColor(.ascendTextPrimary)
                .lineLimit(2)
            if let subtitle = event.subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.ascendTextSecondary)
                    .lineLimit(2)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: max(CGFloat(event.durationHours) * hourHeight - 4, 40), alignment: .topLeading)
        .background(accentColor.opacity(0.15))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(accentColor.opacity(0.4), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(event.subtitle.map { "\(event.title), \($0)" } ?? event.title)
        .accessibilityValue("A las \(timeLabel(event.startHour))")
    }

    private func timeLabel(_ hour: Double) -> String {
        let h = Int(hour)
        let m = Int((hour - Double(h)) * 60)
        return String(format: "%02d:%02d", h, m)
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "checkmark.circle")
                .foregroundColor(.ascendGray)
            Text("Nada por aquí hoy. Buen momento para descansar.")
                .font(.footnote)
                .foregroundColor(.ascendTextSecondary)
        }
        .padding(20)
        .background(Color.ascendBackground.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
