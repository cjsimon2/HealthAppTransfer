import SwiftUI

// MARK: - Watch Metric Row View

/// A single row displaying a health metric on watchOS.
struct WatchMetricRowView: View {

    // MARK: - Properties

    let snapshot: WidgetMetricSnapshot

    // MARK: - Body

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: snapshot.iconName)
                .font(.body)
                .foregroundStyle(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(snapshot.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let value = snapshot.currentValue {
                    Text("\(Int(value).formatted()) \(snapshot.unit)")
                        .font(.headline)
                } else {
                    Text("—")
                        .font(.headline)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(snapshot.displayName): \(formattedValue)")
    }

    // MARK: - Helpers

    private var formattedValue: String {
        if let value = snapshot.currentValue {
            return "\(Int(value).formatted()) \(snapshot.unit)"
        }
        return "no data"
    }
}
