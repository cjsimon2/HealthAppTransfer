import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.fill")
                .font(.largeTitle)
                .foregroundStyle(.red)

            Text("HealthAppTransfer")
                .font(.title)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
