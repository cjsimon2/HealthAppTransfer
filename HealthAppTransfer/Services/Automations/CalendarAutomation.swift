import EventKit
import Foundation

// MARK: - Calendar Parameters

/// Sendable snapshot of AutomationConfiguration fields needed for calendar event creation.
struct CalendarParameters: Sendable {
    let name: String
    let incrementalOnly: Bool
    let lastTriggeredAt: Date?
    let enabledTypeRawValues: [String]

    init(configuration: AutomationConfiguration) {
        self.name = configuration.name
        self.incrementalOnly = configuration.incrementalOnly
        self.lastTriggeredAt = configuration.lastTriggeredAt
        self.enabledTypeRawValues = configuration.enabledTypeRawValues
    }
}

// MARK: - Calendar Automation

/// Creates calendar events for workouts using EventKit.
/// Each workout becomes an EKEvent with activity type, duration, calories, and distance in the notes.
actor CalendarAutomation {

    // MARK: - Dependencies

    private let healthKitService: HealthKitService
    private let eventStore: EKEventStore

    init(healthKitService: HealthKitService, eventStore: EKEventStore = EKEventStore()) {
        self.healthKitService = healthKitService
        self.eventStore = eventStore
    }

    // MARK: - Execute

    /// Create calendar events for workouts. Returns the number of events created.
    @discardableResult
    func execute(params: CalendarParameters) async throws -> Int {
        // Request calendar access
        let granted = try await requestCalendarAccess()
        guard granted else {
            throw CalendarAutomationError.accessDenied
        }

        // Fetch workout samples
        let samples = try await fetchWorkoutSamples(params: params)

        guard !samples.isEmpty else {
            Loggers.automation.info("Calendar automation '\(params.name)': no workouts to add")
            return 0
        }

        // Create events
        var createdCount = 0
        for sample in samples {
            try createEvent(for: sample)
            createdCount += 1
        }

        Loggers.automation.info("Calendar automation '\(params.name)': created \(createdCount) events")
        return createdCount
    }

    // MARK: - Calendar Access

    private func requestCalendarAccess() async throws -> Bool {
        if #available(iOS 17.0, macOS 14.0, *) {
            return try await eventStore.requestFullAccessToEvents()
        } else {
            return try await eventStore.requestAccess(to: .event)
        }
    }

    // MARK: - Fetch Workouts

    private func fetchWorkoutSamples(params: CalendarParameters) async throws -> [HealthSampleDTO] {
        // Only fetch workout type regardless of enabledTypeRawValues
        let startDate: Date? = params.incrementalOnly ? params.lastTriggeredAt : nil

        let samples = try await healthKitService.fetchSampleDTOs(
            for: .workout,
            from: startDate
        )

        return samples
    }

    // MARK: - Create Event

    private func createEvent(for sample: HealthSampleDTO) throws {
        let event = EKEvent(eventStore: eventStore)

        // Title: activity type name
        let activityName = workoutActivityName(for: sample.workoutActivityType)
        event.title = activityName

        // Time
        event.startDate = sample.startDate
        event.endDate = sample.endDate

        // Build notes with workout details
        var notes: [String] = []

        if let duration = sample.workoutDuration {
            let minutes = Int(duration / 60)
            let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
            notes.append("Duration: \(minutes)m \(seconds)s")
        }

        if let calories = sample.workoutTotalEnergyBurned {
            notes.append("Calories: \(Int(calories)) kcal")
        }

        if let distance = sample.workoutTotalDistance {
            let km = distance / 1000
            if km >= 1 {
                notes.append(String(format: "Distance: %.2f km", km))
            } else {
                notes.append(String(format: "Distance: %.0f m", distance))
            }
        }

        notes.append("Source: \(sample.sourceName)")

        event.notes = notes.joined(separator: "\n")

        // Use default calendar
        event.calendar = eventStore.defaultCalendarForNewEvents

        try eventStore.save(event, span: .thisEvent)
    }

    // MARK: - Activity Name

    /// Maps HKWorkoutActivityType raw value to a human-readable name.
    private func workoutActivityName(for rawValue: UInt?) -> String {
        guard let rawValue else { return "Workout" }

        // Common workout activity types
        switch rawValue {
        case 1: return "American Football"
        case 2: return "Archery"
        case 3: return "Australian Football"
        case 4: return "Badminton"
        case 5: return "Baseball"
        case 6: return "Basketball"
        case 7: return "Bowling"
        case 8: return "Boxing"
        case 9: return "Climbing"
        case 10: return "Cricket"
        case 11: return "Cross Training"
        case 12: return "Curling"
        case 13: return "Cycling"
        case 14: return "Dance"
        case 16: return "Elliptical"
        case 17: return "Equestrian Sports"
        case 18: return "Fencing"
        case 19: return "Fishing"
        case 20: return "Functional Training"
        case 21: return "Golf"
        case 22: return "Gymnastics"
        case 23: return "Handball"
        case 24: return "Hiking"
        case 25: return "Hockey"
        case 26: return "Hunting"
        case 27: return "Lacrosse"
        case 28: return "Martial Arts"
        case 29: return "Mind and Body"
        case 31: return "Paddle Sports"
        case 32: return "Play"
        case 33: return "Preparation and Recovery"
        case 34: return "Racquetball"
        case 35: return "Rowing"
        case 36: return "Rugby"
        case 37: return "Running"
        case 38: return "Sailing"
        case 39: return "Skating Sports"
        case 40: return "Snow Sports"
        case 41: return "Soccer"
        case 42: return "Softball"
        case 43: return "Squash"
        case 44: return "Stair Climbing"
        case 45: return "Surfing Sports"
        case 46: return "Swimming"
        case 47: return "Table Tennis"
        case 48: return "Tennis"
        case 49: return "Track and Field"
        case 50: return "Traditional Strength Training"
        case 51: return "Volleyball"
        case 52: return "Walking"
        case 53: return "Water Fitness"
        case 54: return "Water Polo"
        case 55: return "Water Sports"
        case 56: return "Wrestling"
        case 57: return "Yoga"
        case 58: return "Barre"
        case 59: return "Core Training"
        case 60: return "Cross Country Skiing"
        case 61: return "Downhill Skiing"
        case 62: return "Flexibility"
        case 63: return "High Intensity Interval Training"
        case 64: return "Jump Rope"
        case 65: return "Kickboxing"
        case 66: return "Pilates"
        case 67: return "Snowboarding"
        case 68: return "Stairs"
        case 69: return "Step Training"
        case 70: return "Wheelchair Walk Pace"
        case 71: return "Wheelchair Run Pace"
        case 72: return "Tai Chi"
        case 73: return "Mixed Cardio"
        case 74: return "Hand Cycling"
        case 75: return "Disc Sports"
        case 76: return "Fitness Gaming"
        case 77: return "Cardio Dance"
        case 78: return "Social Dance"
        case 79: return "Pickleball"
        case 80: return "Cooldown"
        case 81: return "Swim Bike Run"
        case 82: return "Transition"
        case 3000: return "Other"
        default: return "Workout"
        }
    }
}

// MARK: - Errors

enum CalendarAutomationError: LocalizedError {
    case accessDenied
    case noWorkoutsFound

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Calendar access was denied. Please enable in Settings > Privacy > Calendars."
        case .noWorkoutsFound:
            return "No workout data found to create events."
        }
    }
}
