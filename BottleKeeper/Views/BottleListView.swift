import SwiftUI
import CoreData

struct BottleListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var motionManager = MotionManager()

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Bottle.updatedAt, ascending: false)],
        animation: .default)
    private var bottles: FetchedResults<Bottle>

    @State private var showingAddBottle = false
    @State private var searchText = ""

    var filteredBottles: [Bottle] {
        if searchText.isEmpty {
            return Array(bottles)
        } else {
            return bottles.filter { bottle in
                bottle.wrappedName.localizedCaseInsensitiveContains(searchText) ||
                bottle.wrappedDistillery.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if bottles.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "wineglass")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("ボトルが登録されていません")
                            .font(.headline)
                            .foregroundColor(.gray)

                        Text("右上の+ボタンから新しいボトルを登録しましょう")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button {
                            showingAddBottle = true
                        } label: {
                            Label("ボトルを追加", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                } else {
                    List {
                        ForEach(filteredBottles, id: \.id) { bottle in
                            NavigationLink(destination: BottleDetailView(bottle: bottle)) {
                                BottleRowView(bottle: bottle, motionManager: motionManager)
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    consumeOneShot(bottle)
                                } label: {
                                    Label("1ショット", systemImage: "drop.fill")
                                }
                                .tint(.blue)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteBottle(bottle)
                                } label: {
                                    Label("削除", systemImage: "trash")
                                }
                            }
                        }
                        .onDelete(perform: deleteBottles)
                    }
                    .searchable(text: $searchText, prompt: "銘柄名や蒸留所で検索")
                }
            }
            .navigationTitle("コレクション")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddBottle = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }

                if !bottles.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton()
                    }
                }
            }
            .sheet(isPresented: $showingAddBottle) {
                BottleFormView(bottle: nil)
            }
        }
    }

    private func consumeOneShot(_ bottle: Bottle) {
        withAnimation {
            // 1ショット = 30ml
            let shotVolume: Int32 = 30

            // 未開栓の場合は開栓日を設定
            if bottle.openedDate == nil {
                bottle.openedDate = Date()
            }

            // 残量を減らす（0以下にはしない）
            bottle.remainingVolume = max(0, bottle.remainingVolume - shotVolume)
            bottle.updatedAt = Date()

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("⚠️ Failed to toggle bottle status: \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteBottle(_ bottle: Bottle) {
        withAnimation {
            viewContext.delete(bottle)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("⚠️ Failed to delete bottle: \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteBottles(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredBottles[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("⚠️ Failed to delete bottles: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct BottleRowView: View {
    let bottle: Bottle
    @ObservedObject var motionManager: MotionManager

    var body: some View {
        HStack(spacing: 12) {
            // ボトル形状のビュー
            BottleShapeView(
                remainingPercentage: bottle.remainingPercentage / 100.0,
                motionManager: motionManager
            )
            .frame(width: 50, height: 80)

            VStack(alignment: .leading, spacing: 4) {
                Text(bottle.wrappedName)
                    .font(.headline)

                Text(bottle.wrappedDistillery)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack {
                    // 開栓ステータス
                    if bottle.isOpened {
                        Label("\(bottle.remainingPercentage, specifier: "%.0f")%", systemImage: "drop.fill")
                            .font(.caption)
                            .foregroundColor(remainingColor(for: bottle.remainingPercentage))
                    } else {
                        Label("未開栓", systemImage: "seal.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }

                    // レーティング
                    if bottle.rating > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                            Text("\(bottle.rating)")
                                .font(.caption)
                        }
                        .foregroundColor(.yellow)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func remainingColor(for percentage: Double) -> Color {
        AppColors.remainingColor(for: percentage)
    }
}

// ボトル形状のカスタムビュー
struct BottleShapeView: View {
    let remainingPercentage: Double // 0.0 ~ 1.0
    @ObservedObject var motionManager: MotionManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var wavePhase: Double = 0

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation) { timeline in
                ZStack(alignment: .bottom) {
                    // ボトルの輪郭
                    BottleOutlineShape()
                        .stroke(AppColors.bottleOutline(for: colorScheme), lineWidth: 2)

                    // ボトルの背景
                    BottleOutlineShape()
                        .fill(AppColors.bottleBackground(for: colorScheme))

                    // 液体の部分
                    LiquidWaveShape(
                        liquidHeight: remainingPercentage,
                        tiltOffset: motionManager.roll * 45,
                        wavePhase: wavePhase,
                        waveAmplitude: min(motionManager.accelerationMagnitude * 8, 3.0)
                    )
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: AppColors.whiskyLiquid(for: colorScheme)),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(BottleOutlineShape()) // ボトルの形に切り抜く
                }
                .onChange(of: timeline.date) { _ in
                    wavePhase += 0.05
                }
            }
        }
    }
}

// ボトルの輪郭を描画するShape
struct BottleOutlineShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height

        // ボトルの首部分（上部20%）
        let neckWidth = width * 0.4
        let neckHeight = height * 0.2

        // ボトルの胴体部分（中央60%）
        let bodyWidth = width * 0.8
        let bodyHeight = height * 0.6

        // ボトルの底部分（下部20%）
        let bottomWidth = width * 0.7
        let bottomHeight = height * 0.2

        // 描画開始（左上）
        path.move(to: CGPoint(x: (width - neckWidth) / 2, y: 0))

        // 首の右側
        path.addLine(to: CGPoint(x: (width + neckWidth) / 2, y: 0))
        path.addLine(to: CGPoint(x: (width + neckWidth) / 2, y: neckHeight))

        // 肩の部分（曲線）
        path.addQuadCurve(
            to: CGPoint(x: (width + bodyWidth) / 2, y: neckHeight + 10),
            control: CGPoint(x: (width + bodyWidth) / 2, y: neckHeight)
        )

        // 胴体の右側
        path.addLine(to: CGPoint(x: (width + bodyWidth) / 2, y: neckHeight + bodyHeight))

        // 底への移行（曲線）
        path.addQuadCurve(
            to: CGPoint(x: (width + bottomWidth) / 2, y: neckHeight + bodyHeight + 10),
            control: CGPoint(x: (width + bodyWidth) / 2, y: neckHeight + bodyHeight + 5)
        )

        // 底の右側
        path.addLine(to: CGPoint(x: (width + bottomWidth) / 2, y: height))

        // 底辺
        path.addLine(to: CGPoint(x: (width - bottomWidth) / 2, y: height))

        // 底の左側
        path.addLine(to: CGPoint(x: (width - bottomWidth) / 2, y: neckHeight + bodyHeight + 10))

        // 胴体への移行（曲線）
        path.addQuadCurve(
            to: CGPoint(x: (width - bodyWidth) / 2, y: neckHeight + bodyHeight),
            control: CGPoint(x: (width - bodyWidth) / 2, y: neckHeight + bodyHeight + 5)
        )

        // 胴体の左側
        path.addLine(to: CGPoint(x: (width - bodyWidth) / 2, y: neckHeight + 10))

        // 肩の部分（曲線）
        path.addQuadCurve(
            to: CGPoint(x: (width - neckWidth) / 2, y: neckHeight),
            control: CGPoint(x: (width - bodyWidth) / 2, y: neckHeight)
        )

        // 首の左側
        path.addLine(to: CGPoint(x: (width - neckWidth) / 2, y: 0))

        path.closeSubpath()
        return path
    }
}

// 波動を持つ液体を描画するShape
struct LiquidWaveShape: Shape {
    var liquidHeight: Double // 0.0 ~ 1.0
    var tiltOffset: Double // 傾きによるオフセット
    var wavePhase: Double // 波の位相
    var waveAmplitude: Double // 波の振幅

    var animatableData: AnimatableDataQuad {
        get {
            AnimatableDataQuad(
                first: liquidHeight,
                second: tiltOffset,
                third: wavePhase,
                fourth: waveAmplitude
            )
        }
        set {
            liquidHeight = newValue.first
            tiltOffset = newValue.second
            wavePhase = newValue.third
            waveAmplitude = newValue.fourth
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height
        let liquidLevel = height * (1 - liquidHeight)

        // 波のパラメータ
        let waveFrequency = 2.0 * .pi / width // 波の周波数
        let segments = 50 // 波の精度

        // 液体の表面（波形を描画）
        for i in 0...segments {
            let x = width * Double(i) / Double(segments)

            // 傾きによる基本オフセット
            let tiltY = liquidLevel + tiltOffset * (1.0 - 2.0 * x / width)

            // 波動を追加
            let waveY = sin(x * waveFrequency + wavePhase) * waveAmplitude

            let y = tiltY + waveY

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        // 底辺までパスを閉じる
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()

        return path
    }
}

// AnimatableDataを4つのDoubleに拡張
struct AnimatableDataQuad: VectorArithmetic {
    var first: Double
    var second: Double
    var third: Double
    var fourth: Double

    static var zero = AnimatableDataQuad(first: 0, second: 0, third: 0, fourth: 0)

    static func + (lhs: AnimatableDataQuad, rhs: AnimatableDataQuad) -> AnimatableDataQuad {
        AnimatableDataQuad(
            first: lhs.first + rhs.first,
            second: lhs.second + rhs.second,
            third: lhs.third + rhs.third,
            fourth: lhs.fourth + rhs.fourth
        )
    }

    static func - (lhs: AnimatableDataQuad, rhs: AnimatableDataQuad) -> AnimatableDataQuad {
        AnimatableDataQuad(
            first: lhs.first - rhs.first,
            second: lhs.second - rhs.second,
            third: lhs.third - rhs.third,
            fourth: lhs.fourth - rhs.fourth
        )
    }

    mutating func scale(by rhs: Double) {
        first *= rhs
        second *= rhs
        third *= rhs
        fourth *= rhs
    }

    var magnitudeSquared: Double {
        first * first + second * second + third * third + fourth * fourth
    }
}

// 液体を描画するShape（旧バージョン - 参考用に残す）
struct LiquidShape: Shape {
    var liquidHeight: Double // 0.0 ~ 1.0
    var tiltOffset: Double // 傾きによるオフセット

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(liquidHeight, tiltOffset) }
        set {
            liquidHeight = newValue.first
            tiltOffset = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height
        let liquidLevel = height * (1 - liquidHeight)

        // 傾きによる左右のオフセット（方向を反転し、増幅率を上げる）
        let leftOffset = tiltOffset
        let rightOffset = -tiltOffset

        // 液体の表面（傾きを考慮）
        path.move(to: CGPoint(x: 0, y: liquidLevel + leftOffset))
        path.addLine(to: CGPoint(x: width, y: liquidLevel + rightOffset))
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()

        return path
    }
}

#Preview {
    BottleListView()
        .environment(\.managedObjectContext, CoreDataManager.preview.container.viewContext)
}