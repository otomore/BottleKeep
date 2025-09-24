import Foundation
import AVFoundation
import UIKit
import SwiftUI

/// バーコード読み取りとボトル情報検索を管理するサービス
class BarcodeScannerManager: NSObject, ObservableObject {

    static let shared = BarcodeScannerManager()

    @Published var isScanning = false
    @Published var scannedCode: String?
    @Published var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    @Published var bottleInfo: ScannedBottleInfo?
    @Published var isLoadingBottleInfo = false
    @Published var errorMessage: String?

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    private override init() {
        super.init()
        checkCameraPermission()
    }

    // MARK: - Camera Permission

    /// カメラ許可をチェック
    func checkCameraPermission() {
        cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }

    /// カメラ許可をリクエスト
    func requestCameraPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    // MARK: - Barcode Scanning

    /// バーコードスキャンを開始
    func startScanning() {
        guard cameraPermissionStatus == .authorized else { return }

        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else { return }

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            errorMessage = "カメラの初期化に失敗しました"
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            errorMessage = "カメラ入力を追加できませんでした"
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [
                .ean8, .ean13, .pdf417, .code128, .code39, .code93,
                .upce, .qr, .aztec, .dataMatrix, .interleaved2of5
            ]
        } else {
            errorMessage = "メタデータ出力を追加できませんでした"
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
            DispatchQueue.main.async {
                self.isScanning = true
            }
        }
    }

    /// バーコードスキャンを停止
    func stopScanning() {
        captureSession?.stopRunning()
        captureSession = nil
        previewLayer = nil
        isScanning = false
    }

    /// プレビューレイヤーを取得
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        guard let captureSession = captureSession else { return nil }

        if previewLayer == nil {
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.videoGravity = .resizeAspectFill
        }
        return previewLayer
    }

    // MARK: - Bottle Information Lookup

    /// バーコードからボトル情報を検索
    func lookupBottleInfo(barcode: String) async {
        isLoadingBottleInfo = true
        errorMessage = nil

        do {
            // 複数のデータソースから情報を検索
            if let info = try await searchUPCDatabase(barcode: barcode) {
                await MainActor.run {
                    self.bottleInfo = info
                    self.isLoadingBottleInfo = false
                }
                return
            }

            if let info = try await searchOpenFoodFacts(barcode: barcode) {
                await MainActor.run {
                    self.bottleInfo = info
                    self.isLoadingBottleInfo = false
                }
                return
            }

            if let info = try await searchLocalDatabase(barcode: barcode) {
                await MainActor.run {
                    self.bottleInfo = info
                    self.isLoadingBottleInfo = false
                }
                return
            }

            // 情報が見つからない場合
            await MainActor.run {
                self.bottleInfo = nil
                self.errorMessage = "このバーコードに対応するボトル情報が見つかりませんでした"
                self.isLoadingBottleInfo = false
            }

        } catch {
            await MainActor.run {
                self.errorMessage = "ボトル情報の検索中にエラーが発生しました: \(error.localizedDescription)"
                self.isLoadingBottleInfo = false
            }
        }
    }

    // MARK: - Data Source Methods

    /// UPCデータベースから検索
    private func searchUPCDatabase(barcode: String) async throws -> ScannedBottleInfo? {
        // UPC Database API (例)
        guard let url = URL(string: "https://api.upcitemdb.com/prod/trial/lookup?upc=\(barcode)") else {
            return nil
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(UPCResponse.self, from: data)

        guard let item = response.items.first else { return nil }

        return ScannedBottleInfo(
            name: item.title,
            brand: item.brand,
            category: item.category,
            description: item.description,
            barcode: barcode,
            confidence: 0.8,
            source: "UPC Database"
        )
    }

    /// OpenFoodFactsから検索
    private func searchOpenFoodFacts(barcode: String) async throws -> ScannedBottleInfo? {
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v0/product/\(barcode).json") else {
            return nil
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: data)

        guard response.status == 1, let product = response.product else { return nil }

        // アルコール飲料かどうかをチェック
        let isAlcoholic = product.categories?.contains("alcoholic-beverages") == true ||
                         product.categories?.contains("spirits") == true ||
                         product.categories?.contains("whisky") == true

        if !isAlcoholic { return nil }

        return ScannedBottleInfo(
            name: product.productName ?? "Unknown",
            brand: product.brands?.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces),
            category: "Whiskey",
            description: product.ingredients_text,
            barcode: barcode,
            confidence: 0.9,
            source: "OpenFoodFacts"
        )
    }

    /// ローカルデータベースから検索
    private func searchLocalDatabase(barcode: String) async throws -> ScannedBottleInfo? {
        // ローカルに保存されたボトル情報データベースから検索
        // 実際の実装では Core Data や SQLite から検索
        return getKnownWhiskeyInfo(barcode: barcode)
    }

    /// 既知のウイスキー情報を取得（ハードコード例）
    private func getKnownWhiskeyInfo(barcode: String) -> ScannedBottleInfo? {
        let knownWhiskies: [String: ScannedBottleInfo] = [
            "4904230037576": ScannedBottleInfo(
                name: "山崎 12年",
                brand: "サントリー",
                category: "シングルモルト",
                description: "日本のシングルモルトウイスキーの代表格",
                barcode: barcode,
                confidence: 1.0,
                source: "ローカルDB"
            ),
            "4904230037583": ScannedBottleInfo(
                name: "白州 12年",
                brand: "サントリー",
                category: "シングルモルト",
                description: "爽やかな味わいの日本産シングルモルト",
                barcode: barcode,
                confidence: 1.0,
                source: "ローカルDB"
            ),
            "80432400043": ScannedBottleInfo(
                name: "マッカラン 12年",
                brand: "マッカラン",
                category: "シングルモルト",
                description: "スコットランド産のシェリー樽熟成シングルモルト",
                barcode: barcode,
                confidence: 1.0,
                source: "ローカルDB"
            )
        ]

        return knownWhiskies[barcode]
    }

    // MARK: - Utility Methods

    /// スキャン結果をクリア
    func clearScanResults() {
        scannedCode = nil
        bottleInfo = nil
        errorMessage = nil
    }

    /// ボトル情報からBottleモデルを作成
    func createBottleFromScannedInfo(_ info: ScannedBottleInfo, additionalData: BottleAdditionalData = BottleAdditionalData()) async throws -> Bottle {
        let repository: BottleRepositoryProtocol = BottleRepository()

        let bottle = try await repository.createBottle(
            name: info.name,
            distillery: info.brand ?? "Unknown"
        )

        // スキャンされた情報を適用
        bottle.type = info.category
        bottle.notes = info.description

        // 追加データを適用
        if let abv = additionalData.abv {
            bottle.abv = abv
        }
        if let volume = additionalData.volume {
            bottle.volume = volume
            bottle.remainingVolume = volume
        }
        if let purchasePrice = additionalData.purchasePrice {
            bottle.purchasePrice = NSDecimalNumber(decimal: purchasePrice)
        }
        if let purchaseDate = additionalData.purchaseDate {
            bottle.purchaseDate = purchaseDate
        }
        if let shop = additionalData.shop {
            bottle.shop = shop
        }

        try await repository.saveBottle(bottle)
        return bottle
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension BarcodeScannerManager: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first else { return }
        guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
        guard let stringValue = readableObject.stringValue else { return }

        // バーコードが読み取れた時の処理
        scannedCode = stringValue
        stopScanning()

        // ボトル情報を自動検索
        Task {
            await lookupBottleInfo(barcode: stringValue)
        }
    }
}

// MARK: - Supporting Types

struct ScannedBottleInfo {
    let name: String
    let brand: String?
    let category: String?
    let description: String?
    let barcode: String
    let confidence: Double
    let source: String
}

struct BottleAdditionalData {
    var abv: Double?
    var volume: Int32?
    var purchasePrice: Decimal?
    var purchaseDate: Date?
    var shop: String?
}

// MARK: - API Response Types

struct UPCResponse: Codable {
    let code: String
    let total: Int
    let items: [UPCItem]
}

struct UPCItem: Codable {
    let title: String
    let brand: String?
    let category: String?
    let description: String?
}

struct OpenFoodFactsResponse: Codable {
    let status: Int
    let product: OpenFoodFactsProduct?
}

struct OpenFoodFactsProduct: Codable {
    let productName: String?
    let brands: String?
    let categories: String?
    let ingredients_text: String?

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case brands
        case categories
        case ingredients_text
    }
}

// MARK: - SwiftUI Integration

struct BarcodeScannerView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onBarcodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> BarcodeScannerViewController {
        let controller = BarcodeScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: BarcodeScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, BarcodeScannerDelegate {
        let parent: BarcodeScannerView

        init(_ parent: BarcodeScannerView) {
            self.parent = parent
        }

        func barcodeScanned(_ code: String) {
            parent.onBarcodeScanned(code)
            parent.isPresented = false
        }

        func scanningDidCancel() {
            parent.isPresented = false
        }
    }
}

protocol BarcodeScannerDelegate: AnyObject {
    func barcodeScanned(_ code: String)
    func scanningDidCancel()
}

class BarcodeScannerViewController: UIViewController {
    weak var delegate: BarcodeScannerDelegate?
    private let scannerManager = BarcodeScannerManager.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupScanner()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scannerManager.startScanning()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        scannerManager.stopScanning()
    }

    private func setupUI() {
        view.backgroundColor = .black

        // キャンセルボタン
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("キャンセル", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(cancelButton)

        NSLayoutConstraint.activate([
            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16)
        ])

        // スキャンエリアの枠
        let scanFrame = UIView()
        scanFrame.layer.borderColor = UIColor.white.cgColor
        scanFrame.layer.borderWidth = 2
        scanFrame.layer.cornerRadius = 10
        scanFrame.backgroundColor = .clear
        scanFrame.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scanFrame)

        NSLayoutConstraint.activate([
            scanFrame.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scanFrame.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            scanFrame.widthAnchor.constraint(equalToConstant: 250),
            scanFrame.heightAnchor.constraint(equalToConstant: 150)
        ])

        // 説明ラベル
        let instructionLabel = UILabel()
        instructionLabel.text = "バーコードをスキャンしてください"
        instructionLabel.textColor = .white
        instructionLabel.textAlignment = .center
        instructionLabel.font = .systemFont(ofSize: 16, weight: .medium)
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(instructionLabel)

        NSLayoutConstraint.activate([
            instructionLabel.topAnchor.constraint(equalTo: scanFrame.bottomAnchor, constant: 32),
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func setupScanner() {
        if let previewLayer = scannerManager.getPreviewLayer() {
            previewLayer.frame = view.layer.bounds
            view.layer.insertSublayer(previewLayer, at: 0)
        }

        // スキャン結果の監視
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("BarcodeScanned"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let code = notification.userInfo?["code"] as? String {
                self?.delegate?.barcodeScanned(code)
            }
        }
    }

    @objc private func cancelTapped() {
        delegate?.scanningDidCancel()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}