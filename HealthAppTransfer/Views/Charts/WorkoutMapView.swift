import SwiftUI
import MapKit
import HealthKit
import CoreLocation

// MARK: - Workout Map View

/// Displays a workout route on a MapKit map with start/end pins and a route polyline.
/// Falls back to a placeholder when the workout has no route data.
struct WorkoutMapView: View {

    // MARK: - Properties

    let workout: HKWorkout

    // MARK: - State

    @State private var locations: [CLLocation] = []
    @State private var isLoading = true
    @State private var hasRoute = true
    @State private var mapCameraPosition: MapCameraPosition = .automatic

    // MARK: - Body

    var body: some View {
        Group {
            if isLoading {
                loadingView
            } else if !hasRoute || locations.isEmpty {
                noRouteView
            } else {
                mapContent
            }
        }
        .task { await loadRouteLocations() }
    }

    // MARK: - Map Content

    private var mapContent: some View {
        Map(position: $mapCameraPosition) {
            // Route polyline
            MapPolyline(coordinates: locations.map(\.coordinate))
                .stroke(routeGradient, lineWidth: 4)

            // Start pin
            if let start = locations.first {
                Annotation("Start", coordinate: start.coordinate) {
                    pinView(systemName: "flag.fill", color: .green)
                }
            }

            // End pin
            if let end = locations.last, locations.count > 1 {
                Annotation("End", coordinate: end.coordinate) {
                    pinView(systemName: "flag.checkered", color: .red)
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .frame(minHeight: 280)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear { fitMapToRoute() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(routeAccessibilityLabel)
    }

    // MARK: - Pin View

    private func pinView(systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(color)
            .padding(6)
            .background(.white, in: Circle())
            .shadow(radius: 2)
    }

    // MARK: - Route Gradient

    /// Gradient along the route line from green (start) to orange (end) indicating progression.
    private var routeGradient: LinearGradient {
        LinearGradient(
            colors: [.green, .yellow, .orange],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading route…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(height: 280)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - No Route View

    private var noRouteView: some View {
        VStack(spacing: 12) {
            Image(systemName: "map")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text("No Route Data")
                .font(.title3.bold())

            Text("This workout doesn't include GPS route information.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 280)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Fit Map to Route

    private func fitMapToRoute() {
        guard locations.count >= 2 else { return }

        let coordinates = locations.map(\.coordinate)
        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)

        guard let minLat = latitudes.min(),
              let maxLat = latitudes.max(),
              let minLon = longitudes.min(),
              let maxLon = longitudes.max() else { return }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.3,
            longitudeDelta: (maxLon - minLon) * 1.3
        )
        let region = MKCoordinateRegion(center: center, span: span)
        mapCameraPosition = .region(region)
    }

    // MARK: - Accessibility

    private var routeAccessibilityLabel: String {
        let distanceMeters = workout.totalDistance?.doubleValue(for: .meter()) ?? 0
        let distanceKm = distanceMeters / 1000
        let durationMinutes = Int(workout.duration / 60)
        let pointCount = locations.count

        return "Workout route map. \(String(format: "%.1f", distanceKm)) kilometers over \(durationMinutes) minutes. \(pointCount) GPS points recorded."
    }

    // MARK: - Route Loading

    private func loadRouteLocations() async {
        let store = HKHealthStore()

        // Fetch workout routes associated with this workout
        let routes: [HKWorkoutRoute]
        do {
            routes = try await fetchWorkoutRoutes(for: workout, store: store)
        } catch {
            isLoading = false
            hasRoute = false
            return
        }

        guard let route = routes.first else {
            isLoading = false
            hasRoute = false
            return
        }

        // Fetch all CLLocations from the route
        do {
            let allLocations = try await fetchLocations(from: route, store: store)
            locations = allLocations
            isLoading = false
            fitMapToRoute()
        } catch {
            isLoading = false
            hasRoute = false
        }
    }

    /// Fetch HKWorkoutRoute objects associated with a workout.
    private func fetchWorkoutRoutes(for workout: HKWorkout, store: HKHealthStore) async throws -> [HKWorkoutRoute] {
        let routeType = HKSeriesType.workoutRoute()
        let predicate = HKQuery.predicateForObjects(from: workout)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: routeType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    let routes = (samples as? [HKWorkoutRoute]) ?? []
                    continuation.resume(returning: routes)
                }
            }
            store.execute(query)
        }
    }

    /// Fetch all CLLocations from an HKWorkoutRoute using HKWorkoutRouteQuery.
    private func fetchLocations(from route: HKWorkoutRoute, store: HKHealthStore) async throws -> [CLLocation] {
        try await withCheckedThrowingContinuation { continuation in
            var allLocations: [CLLocation] = []

            let query = HKWorkoutRouteQuery(route: route) { _, newLocations, done, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                if let newLocations {
                    allLocations.append(contentsOf: newLocations)
                }

                if done {
                    continuation.resume(returning: allLocations)
                }
            }
            store.execute(query)
        }
    }
}
