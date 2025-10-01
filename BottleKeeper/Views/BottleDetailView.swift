import SwiftUI

struct BottleDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let bottle: Bottle
    @State private var showingEditForm = false
    @State private var showingRemainingVolumeSheet = false
    @State private var currentRating: Int16 = 0
    @State private var showingImagePicker = false
    @State private var showingPhotoSourceAlert = false
    @State private var selectedImage: UIImage?
    @State private var imagePickerSourceType: ImagePicker.SourceType = .photoLibrary
    @State private var photoToDelete: BottlePhoto?
    @State private var showingDeleteAlert = false
    @State private var showingDrinkingLogForm = false
    @State private var showingTastingNoteForm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 写真セクション
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("写真")
                            .font(.headline)
                        Spacer()
                        Button {
                            showingPhotoSourceAlert = true
                        } label: {
                            Label("追加", systemImage: "plus.circle.fill")
                                .font(.caption)
                        }
                    }

                    if !bottle.photosArray.isEmpty {
                        TabView {
                            ForEach(bottle.photosArray, id: \.id) { photo in
                                ZStack(alignment: .topTrailing) {
                                    if let fileName = photo.fileName,
                                       let image = PhotoManager.shared.loadPhoto(fileName: fileName) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                    } else {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                            .overlay(
                                                Image(systemName: "exclamationmark.triangle")
                                                    .font(.largeTitle)
                                                    .foregroundColor(.gray)
                                            )
                                    }

                                    Button {
                                        photoToDelete = photo
                                        showingDeleteAlert = true
                                    } label: {
                                        Image(systemName: "trash.circle.fill")
                                            .font(.title)
                                            .foregroundColor(.red)
                                            .background(Circle().fill(Color.white))
                                    }
                                    .padding(8)
                                }
                            }
                        }
                        .frame(height: horizontalSizeClass == .regular ? 450 : 300)
                        .tabViewStyle(PageTabViewStyle())
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 300)
                            .overlay(
                                VStack {
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                    Text("写真が追加されていません")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            )
                            .cornerRadius(12)
                    }
                }

                // 基本情報セクション
                VStack(alignment: .leading, spacing: 12) {
                    Text("基本情報")
                        .font(.headline)

                    DetailRowView(title: "銘柄", value: bottle.wrappedName)
                    DetailRowView(title: "蒸留所", value: bottle.wrappedDistillery)
                    DetailRowView(title: "地域", value: bottle.wrappedRegion)
                    DetailRowView(title: "タイプ", value: bottle.wrappedType)
                    DetailRowView(title: "アルコール度数", value: "\(String(format: "%.1f", bottle.abv))%")
                    DetailRowView(title: "容量", value: "\(bottle.volume)ml")

                    if bottle.vintage > 0 {
                        DetailRowView(title: "年代", value: "\(bottle.vintage)年")
                    }
                }

                // 残量情報セクション
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("残量情報")
                            .font(.headline)
                        Spacer()
                        Button("ログを記録") {
                            showingDrinkingLogForm = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                        Button("更新") {
                            showingRemainingVolumeSheet = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("残り: \(bottle.remainingVolume)ml / \(bottle.volume)ml")
                            .font(.subheadline)

                        ProgressView(value: bottle.remainingPercentage, total: 100)
                            .progressViewStyle(LinearProgressViewStyle(tint: progressColor(for: bottle.remainingPercentage)))

                        Text("\(bottle.remainingPercentage, specifier: "%.1f")%")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if bottle.isOpened {
                            if let openedDate = bottle.openedDate {
                                Text("開栓日: \(openedDate, formatter: dateFormatter)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text("未開栓")
                                .font(.caption)
                                .foregroundColor(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }

                // 購入情報セクション
                if bottle.purchaseDate != nil || bottle.purchasePrice != nil || !bottle.wrappedShop.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("購入情報")
                            .font(.headline)

                        if let purchaseDate = bottle.purchaseDate {
                            DetailRowView(title: "購入日", value: dateFormatter.string(from: purchaseDate))
                        }

                        if let purchasePrice = bottle.purchasePrice {
                            DetailRowView(title: "購入価格", value: "¥\(purchasePrice)")
                        }

                        if !bottle.wrappedShop.isEmpty && bottle.wrappedShop != "不明" {
                            DetailRowView(title: "購入店舗", value: bottle.wrappedShop)
                        }
                    }
                }

                // 評価・ノートセクション
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("評価・ノート")
                            .font(.headline)
                        Spacer()
                        Button("テイスティングノート") {
                            showingTastingNoteForm = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }

                    HStack {
                        Text("評価:")
                            .foregroundColor(.secondary)
                        ForEach(1...5, id: \.self) { star in
                            Button {
                                updateRating(Int16(star))
                            } label: {
                                Image(systemName: Int16(star) <= currentRating ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .font(.title2)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if !bottle.wrappedNotes.isEmpty {
                        Text(bottle.wrappedNotes)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }

                // 飲酒ログセクション
                if !bottle.drinkingLogsArray.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("飲酒ログ")
                            .font(.headline)

                        ForEach(bottle.drinkingLogsArray.prefix(5), id: \.id) { log in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "calendar")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(log.wrappedDate, style: .date)
                                        .font(.subheadline)
                                    Text(log.wrappedDate, style: .time)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(log.volume)ml")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }

                                if !log.wrappedNotes.isEmpty {
                                    Text(log.wrappedNotes)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(6)
                        }

                        if bottle.drinkingLogsArray.count > 5 {
                            Text("他 \(bottle.drinkingLogsArray.count - 5) 件のログ")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer(minLength: 20)
            }
            .padding()
        }
        .navigationTitle(bottle.wrappedName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("編集") {
                    showingEditForm = true
                }
            }
        }
        .sheet(isPresented: $showingEditForm) {
            BottleFormView(bottle: bottle)
        }
        .sheet(isPresented: $showingRemainingVolumeSheet) {
            RemainingVolumeUpdateView(bottle: bottle)
        }
        .sheet(isPresented: $showingDrinkingLogForm) {
            DrinkingLogFormView(bottle: bottle)
        }
        .sheet(isPresented: $showingTastingNoteForm) {
            TastingNoteFormView(bottle: bottle)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage, isPresented: $showingImagePicker, sourceType: imagePickerSourceType)
        }
        .alert("写真を追加", isPresented: $showingPhotoSourceAlert) {
            Button("カメラ") {
                imagePickerSourceType = .camera
                showingImagePicker = true
            }
            Button("フォトライブラリ") {
                imagePickerSourceType = .photoLibrary
                showingImagePicker = true
            }
            Button("キャンセル", role: .cancel) {}
        }
        .alert("写真を削除", isPresented: $showingDeleteAlert) {
            Button("削除", role: .destructive) {
                if let photo = photoToDelete {
                    deletePhoto(photo)
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("この写真を削除してもよろしいですか？")
        }
        .onChange(of: selectedImage) { _, newImage in
            if let image = newImage {
                savePhoto(image)
                selectedImage = nil
            }
        }
        .onAppear {
            currentRating = bottle.rating
        }
    }

    private func updateRating(_ newRating: Int16) {
        withAnimation {
            // 同じ星をタップした場合は0に戻す
            if currentRating == newRating {
                currentRating = 0
            } else {
                currentRating = newRating
            }

            bottle.rating = currentRating
            bottle.updatedAt = Date()

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("評価の保存に失敗: \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func progressColor(for percentage: Double) -> Color {
        switch percentage {
        case 50...100:
            return .green
        case 20..<50:
            return .orange
        default:
            return .red
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }

    private func savePhoto(_ image: UIImage) {
        let fileName = "\(UUID().uuidString).jpg"

        // 写真をファイルシステムに保存
        guard PhotoManager.shared.savePhoto(image, fileName: fileName) else {
            print("写真の保存に失敗")
            return
        }

        // Core Dataに写真レコードを作成
        let photo = BottlePhoto(context: viewContext)
        photo.id = UUID()
        photo.fileName = fileName
        photo.fileSize = PhotoManager.shared.getFileSize(fileName: fileName)
        photo.createdAt = Date()
        photo.isMain = bottle.photosArray.isEmpty // 最初の写真をメインに設定
        photo.bottle = bottle

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("写真レコードの保存に失敗: \(nsError), \(nsError.userInfo)")

            // Core Dataの保存に失敗した場合、ファイルも削除
            PhotoManager.shared.deletePhoto(fileName: fileName)
        }
    }

    private func deletePhoto(_ photo: BottlePhoto) {
        // ファイルシステムから写真を削除
        if let fileName = photo.fileName {
            PhotoManager.shared.deletePhoto(fileName: fileName)
        }

        // Core Dataから写真レコードを削除
        viewContext.delete(photo)

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("写真レコードの削除に失敗: \(nsError), \(nsError.userInfo)")
        }
    }
}

struct DetailRowView: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            Text(value)
            Spacer()
        }
    }
}

#Preview {
    NavigationView {
        BottleDetailView(bottle: {
            let context = CoreDataManager.preview.container.viewContext
            let bottle = Bottle(context: context)
            bottle.id = UUID()
            bottle.name = "山崎 12年"
            bottle.distillery = "サントリー"
            bottle.region = "日本"
            bottle.type = "シングルモルト"
            bottle.abv = 43.0
            bottle.volume = 700
            bottle.remainingVolume = 500
            bottle.rating = 5
            bottle.notes = "華やかな香りと深い味わい。バランスが素晴らしい。"
            bottle.purchaseDate = Date()
            bottle.openedDate = Date()
            return bottle
        }())
    }
    .environment(\.managedObjectContext, CoreDataManager.preview.container.viewContext)
}