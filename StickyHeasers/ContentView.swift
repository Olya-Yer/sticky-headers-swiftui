//
//  ContentView.swift
//  StickyHeasers
//
//  Demo of two sticky modes:
//   • monthBar    — isFixed: reaches the top, stays pinned
//   • weekHeader  — regular: sticks below the fixed bar, gets pushed off
//                   by the next week (sliding cleanly UNDER the fixed bar)
//
//  z-index ordering at the call site (fixed > regular) ensures the regular
//  headers exit *behind* the fixed bar instead of covering it.
//

import SwiftUI

struct ContentView: View {
    @State private var lastItemY: CGFloat = .infinity

    private let febWeeks: [Week] = Week.sample(start: 5, count: 4)
    private let marchWeeks: [Week] = Week.sample(start: 10, count: 5)
    private let aprilWeeks: [Week] = Week.sample(start: 15, count: 5)

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                filterBar
                    .sticky(lastItemY: lastItemY, isRevers: true)
                    .zIndex(150)

                monthBar(title: "February 2026", days: 28)
                    .sticky(lastItemY: lastItemY, isFixed: true)
                    .zIndex(100)

                ForEach(febWeeks) { week in
                    VStack(spacing: 0) {
                        weekHeader(week)
                            .sticky(lastItemY: lastItemY)
                            .zIndex(50)

                        ForEach(week.events) { event in
                            EventRow(event: event)
                        }
                    }
                }

                monthBar(title: "March 2026", days: 31)
                    .sticky(lastItemY: lastItemY, isFixed: true)
                    .zIndex(100)

                ForEach(marchWeeks) { week in
                    VStack(spacing: 0) {
                        weekHeader(week)
                            .sticky(lastItemY: lastItemY)
                            .zIndex(50)

                        ForEach(week.events) { event in
                            EventRow(event: event)
                        }
                    }
                }

                monthBar(title: "April 2026", days: 30)
                    .sticky(lastItemY: lastItemY, isFixed: true)
                    .zIndex(100)

                ForEach(aprilWeeks) { week in
                    VStack(spacing: 0) {
                        weekHeader(week)
                            .sticky(lastItemY: lastItemY)
                            .zIndex(50)

                        ForEach(week.events) { event in
                            EventRow(event: event)
                        }
                    }
                }

                GeometryReader { proxy in
                    let y = proxy.frame(in: .named(UseStickyHeaders.container)).minY
                    Color.clear
                        .onAppear { lastItemY = y }
                        .onChange(of: y) { newY in lastItemY = newY }
                }
                .frame(height: 1)
            }
        }
        .useStickyHeaders()
        .background(Color.white)
        .safeAreaInset(edge: .top, spacing: 0) {
            Text("Calendar")
                .font(.system(size: 17, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white)
                .overlay(Divider(), alignment: .bottom)
        }
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            FilterChip(label: "All", selected: true)
            FilterChip(label: "Work")
            FilterChip(label: "Personal")
            FilterChip(label: "Travel")
            Spacer()
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .overlay(Divider(), alignment: .bottom)
    }

    private func monthBar(title: String, days: Int) -> some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .foregroundStyle(.tint)
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
            }
            Spacer()
            Text("\(days) days")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .overlay(Divider(), alignment: .bottom)
    }

    private func weekHeader(_ week: Week) -> some View {
        HStack {
            Text(week.label)
                .font(.system(size: 14, weight: .semibold))
            Spacer()
            Text("\(week.events.count) events")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color(red: 0.94, green: 0.94, blue: 0.96))
        .overlay(Divider(), alignment: .bottom)
    }
}

private struct FilterChip: View {
    let label: String
    var selected: Bool = false

    var body: some View {
        Text(label)
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(selected ? Color.accentColor : Color(red: 0.92, green: 0.92, blue: 0.94))
            )
            .foregroundStyle(selected ? .white : .primary)
    }
}

private struct EventRow: View {
    let event: Event

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(event.tint)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 15, weight: .medium))
                Text(event.time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .overlay(Divider(), alignment: .bottom)
    }
}

private struct Week: Identifiable {
    let id = UUID()
    let label: String
    let events: [Event]

    static func sample(start: Int, count: Int) -> [Week] {
        let titles = [
            "Standup", "Design review", "1:1 with Marco", "Coffee with Sara",
            "Code review", "Sprint planning", "Demo", "Lunch — Tomas",
            "Yoga", "Run in the park", "Bookstore", "Family dinner",
        ]
        let times = ["09:00", "11:30", "13:00", "15:45", "18:00", "20:30"]
        let tints: [Color] = [.blue, .pink, .orange, .green, .purple, .indigo, .teal]

        return (0..<count).map { i in
            let n = Int.random(in: 2...5)
            let events = (0..<n).map { _ in
                Event(
                    title: titles.randomElement()!,
                    time: times.randomElement()!,
                    tint: tints.randomElement()!
                )
            }
            return Week(label: "Week \(start + i)", events: events)
        }
    }
}

private struct Event: Identifiable {
    let id = UUID()
    let title: String
    let time: String
    let tint: Color
}

#Preview {
    ContentView()
}
