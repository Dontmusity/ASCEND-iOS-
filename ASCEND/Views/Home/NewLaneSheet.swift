import SwiftUI

struct NewLaneSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var colorHex = "E8BC75"
    @State private var icon = "star"
    @State private var notificationsEnabled = false

    private let colorOptions = ["E8BC75", "8FA173", "9E8AA8", "A8785A", "C9A15A"]
    private let iconOptions = ["star", "gamecontroller", "camera", "music.note", "airplane", "pawprint"]

    var body: some View {
        NavigationStack {
            Form {
                if !appState.canAddCustomLane {
                    Section {
                        Text("Ya tienes 3 carruseles personalizados. Elimina uno para crear otro.")
                            .foregroundColor(.ascendTextSecondary)
                    }
                } else {
                    Section("Nombre") {
                        TextField("Ej. Proyecto de robótica", text: $name)
                    }
                    Section("Color") {
                        HStack(spacing: 14) {
                            ForEach(colorOptions, id: \.self) { hex in
                                Button {
                                    colorHex = hex
                                } label: {
                                    Circle()
                                        .fill(Color(hex: hex))
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Circle().stroke(Color.ascendTextPrimary, lineWidth: colorHex == hex ? 2 : 0)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    Section("Ícono") {
                        Picker("Ícono", selection: $icon) {
                            ForEach(iconOptions, id: \.self) { name in
                                Image(systemName: name).tag(name)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    Section("Notificaciones") {
                        Toggle("Activar recordatorios de este carrusel", isOn: $notificationsEnabled)
                    }
                }
            }
            .navigationTitle("Nuevo carrusel")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                if appState.canAddCustomLane {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Crear") { save() }.disabled(name.isEmpty)
                    }
                }
            }
        }
    }

    private func save() {
        appState.addCustomLane(name: name, colorHex: colorHex, icon: icon,
                               notificationsEnabled: notificationsEnabled)
        dismiss()
    }
}
