import SwiftUI

struct CreatePlaylistView: View {
    @EnvironmentObject private var library: LibraryManager
    @State private var playlistName = ""
    @State private var created = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Создать")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Название плейлиста")
                        .font(.subheadline)
                        .foregroundStyle(ColorPalette.textSecondary)

                    TextField("Мой плейлист", text: $playlistName)
                        .padding(13)
                        .background(ColorPalette.elevated, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                }

                Button {
                    created = true
                } label: {
                    Text("Создать плейлист")
                }
                .thereButtonStyle()
                .opacity(playlistName.isEmpty ? 0.5 : 1.0)
                .disabled(playlistName.isEmpty)

                Spacer()
            }
            .padding()
            .padding(.bottom, 120)
        }
        .background(Color.black.ignoresSafeArea())
        .alert("Готово", isPresented: $created) {
            Button("OK") { playlistName = "" }
        } message: {
            Text("Плейлист создан")
        }
    }
}
