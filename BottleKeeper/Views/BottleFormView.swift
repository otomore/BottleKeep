import SwiftUI

struct BottleFormView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let bottle: Bottle?

    @State private var name = ""
    @State private var distillery = ""
    @State private var region = ""
    @State private var type = ""
    @State private var abv = 40.0
    @State private var volume: Int32 = 700
    @State private var vintage: Int32 = 0
    @State private var purchaseDate = Date()
    @State private var purchasePrice = ""
    @State private var shop = ""
    @State private var rating: Int16 = 0
    @State private var notes = ""
    @State private var openedDate: Date?
    @State private var isOpened = false

    private var isEditing: Bool {
        bottle != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("銘柄名", text: $name)
                    TextField("蒸留所", text: $distillery)
                    TextField("地域", text: $region)
                    TextField("タイプ", text: $type)

                    HStack {
                        Text("アルコール度数")
                        Spacer()
                        TextField("40.0", value: $abv, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                        Text("%")
                    }

                    HStack {
                        Text("容量")
                        Spacer()
                        TextField("700", value: $volume, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                        Text("ml")
                    }

                    HStack {
                        Text("年代")
                        Spacer()
                        TextField("任意", value: $vintage, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                        Text("年")
                    }
                }

                Section("購入情報") {
                    DatePicker("購入日", selection: $purchaseDate, displayedComponents: .date)

                    HStack {
                        Text("購入価格")
                        Spacer()
                        TextField("任意", text: $purchasePrice)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 100)
                        Text("円")
                    }

                    TextField("購入店舗（任意）", text: $shop)
                }

                Section("開栓情報") {
                    Toggle("開栓済み", isOn: $isOpened)

                    if isOpened {
                        DatePicker("開栓日", selection: Binding(
                            get: { openedDate ?? Date() },
                            set: { openedDate = $0 }
                        ), displayedComponents: .date)
                    }
                }

                Section("評価・ノート") {
                    HStack {
                        Text("評価")
                        Spacer()
                        ForEach(1...5, id: \.self) { star in
                            Button {
                                let starValue = Int16(star)
                                // 既に選択されている星をタップした場合は評価を0に戻す
                                if rating == starValue {
                                    rating = 0
                                } else {
                                    rating = starValue
                                }
                                print("評価を変更: \(rating)")
                            } label: {
                                Image(systemName: Int16(star) <= rating ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .font(.title2)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    TextField("テイスティングノート（任意）", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(isEditing ? "ボトル編集" : "新規ボトル")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveBottle()
                    }
                    .disabled(name.isEmpty || distillery.isEmpty)
                }
            }
        }
        .onAppear {
            if let bottle = bottle {
                loadBottleData(bottle)
            }
        }
    }

    private func loadBottleData(_ bottle: Bottle) {
        name = bottle.wrappedName
        distillery = bottle.wrappedDistillery
        region = bottle.wrappedRegion
        type = bottle.wrappedType
        abv = bottle.abv
        volume = bottle.volume
        vintage = bottle.vintage
        purchaseDate = bottle.purchaseDate ?? Date()
        if let price = bottle.purchasePrice {
            purchasePrice = price.stringValue
        }
        shop = bottle.wrappedShop
        rating = bottle.rating
        notes = bottle.wrappedNotes
        openedDate = bottle.openedDate
        isOpened = bottle.isOpened
    }

    private func saveBottle() {
        withAnimation {
            let targetBottle: Bottle
            if let existingBottle = bottle {
                targetBottle = existingBottle
            } else {
                targetBottle = Bottle(context: viewContext)
                targetBottle.id = UUID()
                targetBottle.createdAt = Date()
                targetBottle.remainingVolume = volume // 新規の場合は満タン
            }

            targetBottle.name = name
            targetBottle.distillery = distillery
            targetBottle.region = region.isEmpty ? nil : region
            targetBottle.type = type.isEmpty ? nil : type
            targetBottle.abv = abv
            targetBottle.volume = volume
            targetBottle.vintage = vintage
            targetBottle.purchaseDate = purchaseDate

            if !purchasePrice.isEmpty, let price = Decimal(string: purchasePrice) {
                targetBottle.purchasePrice = NSDecimalNumber(decimal: price)
            }

            targetBottle.shop = shop.isEmpty ? nil : shop
            targetBottle.rating = rating
            targetBottle.notes = notes.isEmpty ? nil : notes
            targetBottle.openedDate = isOpened ? (openedDate ?? Date()) : nil
            targetBottle.updatedAt = Date()

            do {
                try viewContext.save()
                dismiss()
            } catch {
                let nsError = error as NSError
                print("⚠️ Failed to save bottle: \(nsError), \(nsError.userInfo)")
                // エラーが発生してもアプリは続行（データは保存されない）
                dismiss()
            }
        }
    }
}

#Preview {
    BottleFormView(bottle: nil)
        .environment(\.managedObjectContext, CoreDataManager.preview.container.viewContext)
}