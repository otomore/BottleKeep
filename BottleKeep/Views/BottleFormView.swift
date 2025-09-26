import SwiftUI

struct BottleFormView: View {
    let bottle: Bottle?

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var diContainer: DIContainer

    // フォーム入力値
    @State private var name: String = ""
    @State private var distillery: String = ""
    @State private var region: String = ""
    @State private var type: String = ""
    @State private var abv: Double = 0
    @State private var volume: Int32 = 700
    @State private var vintage: Int32 = 0

    @State private var purchaseDate: Date = Date()
    @State private var purchasePrice: String = ""
    @State private var shop: String = ""

    @State private var openedDate: Date = Date()
    @State private var hasOpenedDate: Bool = false
    @State private var rating: Int16 = 0
    @State private var notes: String = ""

    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    var isEditing: Bool {
        return bottle != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                // 基本情報セクション
                basicInfoSection

                // 購入情報セクション
                purchaseInfoSection

                // テイスティング情報セクション
                tastingInfoSection
            }
            .navigationTitle(isEditing ? "ボトル編集" : "ボトル追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "更新" : "保存") {
                        Task {
                            await saveBottle()
                        }
                    }
                    .disabled(isLoading || !isValidForm)
                }
            }
            .onAppear {
                loadBottleData()
            }
        }
        .alert("エラー", isPresented: Binding<Bool>(
            get: { errorMessage != nil },
            set: { _ in errorMessage = nil }
        )) {
            Button("OK") {}
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Form Sections

    private var basicInfoSection: some View {
        Section("基本情報") {
            TextField("ボトル名", text: $name)
            TextField("蒸留所", text: $distillery)
            TextField("地域", text: $region)
            TextField("タイプ", text: $type)

            HStack {
                Text("アルコール度数")
                Spacer()
                TextField("43.0", value: $abv, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                Text("%")
            }

            HStack {
                Text("容量")
                Spacer()
                TextField("700", value: $volume, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                Text("ml")
            }

            HStack {
                Text("ヴィンテージ")
                Spacer()
                TextField("年", value: $vintage, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    private var purchaseInfoSection: some View {
        Section("購入情報") {
            DatePicker("購入日", selection: $purchaseDate, displayedComponents: .date)

            TextField("購入価格（円）", text: $purchasePrice)
                .keyboardType(.numberPad)

            TextField("購入店舗", text: $shop)
        }
    }

    private var tastingInfoSection: some View {
        Section("テイスティング情報") {
            Toggle("開栓済み", isOn: $hasOpenedDate)

            if hasOpenedDate {
                DatePicker("開栓日", selection: $openedDate, displayedComponents: .date)
            }

            // 評価
            VStack(alignment: .leading, spacing: 8) {
                Text("評価")
                HStack {
                    ForEach(1...5, id: \.self) { star in
                        Button(action: {
                            rating = Int16(star)
                        }) {
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.title2)
                        }
                    }
                    Spacer()
                    if rating > 0 {
                        Button("クリア") {
                            rating = 0
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
            }

            TextField("テイスティングノート", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    // MARK: - Computed Properties

    private var isValidForm: Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !distillery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Methods

    private func loadBottleData() {
        guard let bottle = bottle else { return }

        name = bottle.name
        distillery = bottle.distillery
        region = bottle.region ?? ""
        type = bottle.type ?? ""
        abv = bottle.abv
        volume = bottle.volume
        vintage = bottle.vintage

        if let purchaseDateValue = bottle.purchaseDate {
            purchaseDate = purchaseDateValue
        }

        if let priceValue = bottle.purchasePrice {
            purchasePrice = String(priceValue.intValue)
        }

        shop = bottle.shop ?? ""

        if let openedDateValue = bottle.openedDate {
            openedDate = openedDateValue
            hasOpenedDate = true
        }

        rating = bottle.rating
        notes = bottle.notes ?? ""
    }

    private func saveBottle() async {
        isLoading = true
        errorMessage = nil

        do {
            let repository = diContainer.getBottleRepository()

            if let existingBottle = bottle {
                // 既存ボトルの更新
                existingBottle.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                existingBottle.distillery = distillery.trimmingCharacters(in: .whitespacesAndNewlines)
                existingBottle.region = region.isEmpty ? nil : region
                existingBottle.type = type.isEmpty ? nil : type
                existingBottle.abv = abv
                existingBottle.volume = volume
                existingBottle.vintage = vintage

                existingBottle.purchaseDate = purchaseDate
                existingBottle.purchasePrice = purchasePrice.isEmpty ? nil : NSDecimalNumber(string: purchasePrice)
                existingBottle.shop = shop.isEmpty ? nil : shop

                existingBottle.openedDate = hasOpenedDate ? openedDate : nil
                existingBottle.rating = rating
                existingBottle.notes = notes.isEmpty ? nil : notes

                try await repository.saveBottle(existingBottle)
            } else {
                // 新規ボトルの作成
                let newBottle = try await repository.createBottle(
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    distillery: distillery.trimmingCharacters(in: .whitespacesAndNewlines)
                )

                newBottle.region = region.isEmpty ? nil : region
                newBottle.type = type.isEmpty ? nil : type
                newBottle.abv = abv
                newBottle.volume = volume
                newBottle.vintage = vintage

                newBottle.purchaseDate = purchaseDate
                newBottle.purchasePrice = purchasePrice.isEmpty ? nil : NSDecimalNumber(string: purchasePrice)
                newBottle.shop = shop.isEmpty ? nil : shop

                newBottle.openedDate = hasOpenedDate ? openedDate : nil
                newBottle.rating = rating
                newBottle.notes = notes.isEmpty ? nil : notes

                try await repository.saveBottle(newBottle)
            }

            isLoading = false
            dismiss()

        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}

// MARK: - Preview

#Preview {
    BottleFormView(bottle: nil)
        .environmentObject(DIContainer())
}