# BottleKeep API仕様書

## 1. 概要

### 1.1 目的
BottleKeepアプリで使用する外部APIサービスの仕様を定義し、正確な連携実装を可能にする。API呼び出し、レスポンス処理、エラーハンドリングの詳細を記載する。

### 1.2 API使用方針
- **最小実装**: MVPでは外部API不使用、段階的に追加
- **オフライン対応**: API利用不可時もアプリ機能を維持
- **ユーザープライバシー**: 個人データは外部送信しない
- **レート制限対応**: API制限内での適切な利用

### 1.3 実装段階
```
Phase 1 (MVP): 外部API未使用
Phase 2: 商品情報API (Amazon, 楽天)
Phase 3: バーコードAPI
Phase 4: 価格比較API
```

## 2. Amazon Product Advertising API (PA-API 5.0)

### 2.1 概要
Amazon商品情報の取得とアフィリエイトリンク生成に使用。

#### 2.1.1 基本情報
- **API バージョン**: PA-API 5.0
- **認証方式**: AWS Signature Version 4
- **レート制限**: 1リクエスト/秒（アソシエイト参加後）
- **地域**: Amazon.co.jp（日本）

#### 2.1.2 必要な認証情報
```swift
struct AmazonAPICredentials {
    let accessKeyId: String      // AWS Access Key ID
    let secretAccessKey: String  // AWS Secret Access Key
    let associateTag: String     // アソシエイトタグ
    let marketplace: String = "www.amazon.co.jp"
    let region: String = "us-west-2"
}
```

### 2.2 商品検索API

#### 2.2.1 エンドポイント
```
POST https://webservices.amazon.co.jp/paapi5/searchitems
```

#### 2.2.2 リクエスト例
```swift
struct SearchItemsRequest: Codable {
    let Operation = "SearchItems"
    let Marketplace: String
    let PartnerTag: String
    let PartnerType = "Associates"
    let Keywords: String
    let ItemCount: Int = 10
    let Resources: [String] = [
        "Images.Primary.Large",
        "ItemInfo.Title",
        "ItemInfo.ByLineInfo",
        "ItemInfo.ProductInfo",
        "Offers.Listings.Price",
        "DetailPageURL"
    ]
    let SearchIndex = "Alcoholic-Beverages"
}

// 使用例
let request = SearchItemsRequest(
    Marketplace: "www.amazon.co.jp",
    PartnerTag: "your-associate-tag",
    Keywords: "山崎 ウイスキー",
    ItemCount: 5
)
```

#### 2.2.3 レスポンス例
```json
{
  "SearchResult": {
    "TotalResultCount": 100,
    "SearchURL": "https://www.amazon.co.jp/s?k=...",
    "Items": [
      {
        "ASIN": "B001234567",
        "DetailPageURL": "https://www.amazon.co.jp/dp/B001234567?tag=your-associate-tag",
        "Images": {
          "Primary": {
            "Large": {
              "URL": "https://m.media-amazon.com/images/I/...",
              "Height": 500,
              "Width": 375
            }
          }
        },
        "ItemInfo": {
          "Title": {
            "DisplayValue": "サントリー 山崎 12年 シングルモルト ウイスキー 700ml"
          },
          "ByLineInfo": {
            "Brand": {
              "DisplayValue": "サントリー"
            },
            "Manufacturer": {
              "DisplayValue": "サントリー"
            }
          }
        },
        "Offers": {
          "Listings": [
            {
              "Price": {
                "Amount": 25000,
                "Currency": "JPY",
                "DisplayAmount": "¥25,000"
              }
            }
          ]
        }
      }
    ]
  }
}
```

#### 2.2.4 Swift実装例
```swift
class AmazonProductAPI {
    private let credentials: AmazonAPICredentials
    private let baseURL = "https://webservices.amazon.co.jp/paapi5"

    init(credentials: AmazonAPICredentials) {
        self.credentials = credentials
    }

    func searchProducts(keywords: String) async throws -> AmazonSearchResult {
        let request = SearchItemsRequest(
            Marketplace: credentials.marketplace,
            PartnerTag: credentials.associateTag,
            Keywords: keywords
        )

        let url = URL(string: "\(baseURL)/searchitems")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        // AWS Signature V4 認証
        urlRequest = try addAWSSignature(request: urlRequest, body: request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw APIError.invalidResponse
        }

        return try JSONDecoder().decode(AmazonSearchResult.self, from: data)
    }

    private func addAWSSignature(request: URLRequest, body: SearchItemsRequest) throws -> URLRequest {
        // AWS Signature V4 実装
        // 詳細実装は割愛（AWS SDK使用推奨）
        return request
    }
}
```

### 2.3 レート制限対応

#### 2.3.1 レート制限管理
```swift
class RateLimiter {
    private var lastRequestTime: Date?
    private let minimumInterval: TimeInterval = 1.0 // 1秒間隔

    func waitIfNeeded() async {
        if let lastTime = lastRequestTime {
            let elapsed = Date().timeIntervalSince(lastTime)
            if elapsed < minimumInterval {
                let waitTime = minimumInterval - elapsed
                try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
            }
        }
        lastRequestTime = Date()
    }
}
```

### 2.4 エラーハンドリング

#### 2.4.1 エラータイプ
```swift
enum AmazonAPIError: Error, LocalizedError {
    case invalidCredentials
    case rateLimitExceeded
    case itemNotFound
    case networkError(Error)
    case malformedRequest
    case tooManyRequests

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Amazon API認証情報が無効です"
        case .rateLimitExceeded:
            return "APIリクエスト制限に達しました"
        case .itemNotFound:
            return "商品が見つかりませんでした"
        case .networkError(let error):
            return "ネットワークエラー: \(error.localizedDescription)"
        case .malformedRequest:
            return "リクエスト形式が不正です"
        case .tooManyRequests:
            return "リクエストが多すぎます。しばらく待ってから再試行してください"
        }
    }
}
```

## 3. 楽天商品検索API

### 3.1 概要
楽天市場の商品情報取得とアフィリエイトリンク生成。

#### 3.1.1 基本情報
- **API バージョン**: Rakuten Web Service API 2.0
- **認証方式**: Application ID
- **レート制限**: 10,000リクエスト/日
- **無料利用**: 可能

#### 3.1.2 エンドポイント
```
GET https://app.rakuten.co.jp/services/api/IchibaItem/Search/20220601
```

### 3.2 商品検索実装

#### 3.2.1 リクエストパラメータ
```swift
struct RakutenSearchParams {
    let applicationId: String
    let keyword: String
    let genreId: String = "408134" // 洋酒
    let sort: String = "standard"
    let hits: Int = 10
    let page: Int = 1
    let format: String = "json"
    let formatVersion: Int = 2
}
```

#### 3.2.2 Swift実装例
```swift
class RakutenProductAPI {
    private let applicationId: String
    private let baseURL = "https://app.rakuten.co.jp/services/api/IchibaItem/Search/20220601"

    init(applicationId: String) {
        self.applicationId = applicationId
    }

    func searchProducts(keyword: String) async throws -> RakutenSearchResult {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "applicationId", value: applicationId),
            URLQueryItem(name: "keyword", value: keyword),
            URLQueryItem(name: "genreId", value: "408134"),
            URLQueryItem(name: "hits", value: "10"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "formatVersion", value: "2")
        ]

        let (data, response) = try await URLSession.shared.data(from: components.url!)

        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw APIError.invalidResponse
        }

        return try JSONDecoder().decode(RakutenSearchResult.self, from: data)
    }
}
```

#### 3.2.3 レスポンス構造
```swift
struct RakutenSearchResult: Codable {
    let Items: [RakutenItem]
    let pageCount: Int
    let ItemCount: Int
    let hits: Int
    let last: Int
    let first: Int
    let page: Int
}

struct RakutenItem: Codable {
    let Item: RakutenItemDetail
}

struct RakutenItemDetail: Codable {
    let itemName: String
    let itemPrice: Int
    let itemUrl: String
    let affiliateUrl: String
    let imageFlag: Int
    let mediumImageUrls: [RakutenImage]
    let shopName: String
    let reviewCount: Int
    let reviewAverage: Double
}

struct RakutenImage: Codable {
    let imageUrl: String
}
```

## 4. バーコード商品情報API

### 4.1 概要
JAN/EANコードから商品情報を取得。

#### 4.1.1 利用サービス候補
- **Open Food Facts API** (無料、食品・飲料)
- **UPC Database API** (有料、高精度)
- **Barcode Lookup** (有料、包括的)

### 4.2 Open Food Facts API

#### 4.2.1 基本情報
- **料金**: 無料
- **認証**: 不要
- **制限**: Rate limiting有り（詳細不明）

#### 4.2.2 エンドポイント
```
GET https://world.openfoodfacts.org/api/v0/product/{barcode}.json
```

#### 4.2.3 実装例
```swift
class BarcodeAPI {
    private let baseURL = "https://world.openfoodfacts.org/api/v0/product"

    func getProductInfo(barcode: String) async throws -> BarcodeProduct? {
        let url = URL(string: "\(baseURL)/\(barcode).json")!

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw APIError.invalidResponse
        }

        let result = try JSONDecoder().decode(BarcodeResult.self, from: data)

        guard result.status == 1 else {
            return nil // 商品が見つからない
        }

        return result.product
    }
}

struct BarcodeResult: Codable {
    let status: Int
    let product: BarcodeProduct?
}

struct BarcodeProduct: Codable {
    let product_name: String?
    let brands: String?
    let alcohol_by_volume: String?
    let image_front_url: String?
    let categories: String?
}
```

## 5. 価格比較・最安値API

### 5.1 実装方針
複数のAPIを組み合わせて価格比較機能を実現。

#### 5.1.1 価格比較ロジック
```swift
class PriceComparisonService {
    private let amazonAPI: AmazonProductAPI
    private let rakutenAPI: RakutenProductAPI

    func comparePrices(productName: String) async -> [PriceInfo] {
        async let amazonResults = searchAmazonPrices(productName: productName)
        async let rakutenResults = searchRakutenPrices(productName: productName)

        let allResults = await [amazonResults, rakutenResults].compactMap { $0 }
        return allResults.flatMap { $0 }.sorted { $0.price < $1.price }
    }

    private func searchAmazonPrices(productName: String) async -> [PriceInfo]? {
        do {
            let result = try await amazonAPI.searchProducts(keywords: productName)
            return result.SearchResult?.Items?.compactMap { item in
                guard let price = item.Offers?.Listings?.first?.Price else { return nil }
                return PriceInfo(
                    source: "Amazon",
                    price: Decimal(price.Amount) / 100,
                    url: item.DetailPageURL,
                    productName: item.ItemInfo?.Title?.DisplayValue ?? ""
                )
            }
        } catch {
            return nil
        }
    }

    private func searchRakutenPrices(productName: String) async -> [PriceInfo]? {
        do {
            let result = try await rakutenAPI.searchProducts(keyword: productName)
            return result.Items.map { item in
                PriceInfo(
                    source: "楽天市場",
                    price: Decimal(item.Item.itemPrice),
                    url: item.Item.affiliateUrl,
                    productName: item.Item.itemName
                )
            }
        } catch {
            return nil
        }
    }
}

struct PriceInfo {
    let source: String
    let price: Decimal
    let url: String
    let productName: String
}
```

## 6. API設定管理

### 6.1 設定ファイル
```swift
// APIConfiguration.swift
struct APIConfiguration {
    static let shared = APIConfiguration()

    // Amazon API
    let amazonCredentials: AmazonAPICredentials? = {
        guard let accessKey = Bundle.main.infoDictionary?["AMAZON_ACCESS_KEY"] as? String,
              let secretKey = Bundle.main.infoDictionary?["AMAZON_SECRET_KEY"] as? String,
              let associateTag = Bundle.main.infoDictionary?["AMAZON_ASSOCIATE_TAG"] as? String else {
            return nil
        }
        return AmazonAPICredentials(
            accessKeyId: accessKey,
            secretAccessKey: secretKey,
            associateTag: associateTag
        )
    }()

    // 楽天API
    let rakutenApplicationId: String? = {
        return Bundle.main.infoDictionary?["RAKUTEN_APPLICATION_ID"] as? String
    }()

    var isAmazonAPIAvailable: Bool {
        return amazonCredentials != nil
    }

    var isRakutenAPIAvailable: Bool {
        return rakutenApplicationId != nil
    }
}
```

### 6.2 Info.plist設定
```xml
<!-- Info.plist -->
<key>AMAZON_ACCESS_KEY</key>
<string>$(AMAZON_ACCESS_KEY)</string>
<key>AMAZON_SECRET_KEY</key>
<string>$(AMAZON_SECRET_KEY)</string>
<key>AMAZON_ASSOCIATE_TAG</key>
<string>$(AMAZON_ASSOCIATE_TAG)</string>
<key>RAKUTEN_APPLICATION_ID</key>
<string>$(RAKUTEN_APPLICATION_ID)</string>
```

## 7. エラーハンドリング統合

### 7.1 共通エラー処理
```swift
enum APIError: Error, LocalizedError {
    case invalidResponse
    case networkUnavailable
    case rateLimitExceeded
    case authenticationFailed
    case serviceUnavailable
    case malformedData

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "サーバーからの応答が無効です"
        case .networkUnavailable:
            return "ネットワークに接続できません"
        case .rateLimitExceeded:
            return "API利用制限に達しました"
        case .authenticationFailed:
            return "API認証に失敗しました"
        case .serviceUnavailable:
            return "サービスが一時的に利用できません"
        case .malformedData:
            return "データ形式が正しくありません"
        }
    }
}

class APIErrorHandler {
    static func handleError(_ error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.localizedDescription
        } else if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return "インターネットに接続されていません"
            case .timedOut:
                return "タイムアウトが発生しました"
            default:
                return "ネットワークエラーが発生しました"
            }
        } else {
            return "予期しないエラーが発生しました"
        }
    }
}
```

## 8. オフライン対応

### 8.1 ネットワーク状態監視
```swift
import Network

class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    @Published var isConnected = false

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
}
```

### 8.2 API呼び出し制御
```swift
class APIManager {
    @Published var networkMonitor = NetworkMonitor()

    func callAPIWithFallback<T>(
        apiCall: @escaping () async throws -> T,
        fallback: @escaping () -> T
    ) async -> T {
        guard networkMonitor.isConnected else {
            return fallback()
        }

        do {
            return try await apiCall()
        } catch {
            print("API call failed, using fallback: \(error)")
            return fallback()
        }
    }
}
```

## 9. キャッシュ戦略

### 9.1 API結果キャッシュ
```swift
class APICache {
    private let cache = NSCache<NSString, CacheEntry>()
    private let expirationInterval: TimeInterval = 3600 // 1時間

    func get<T: Codable>(key: String, type: T.Type) -> T? {
        guard let entry = cache.object(forKey: key as NSString),
              !entry.isExpired else {
            return nil
        }
        return entry.data as? T
    }

    func set<T: Codable>(key: String, value: T) {
        let entry = CacheEntry(data: value, timestamp: Date())
        cache.setObject(entry, forKey: key as NSString)
    }

    private class CacheEntry {
        let data: Any
        let timestamp: Date

        init(data: Any, timestamp: Date) {
            self.data = data
            self.timestamp = timestamp
        }

        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > 3600
        }
    }
}
```

## 10. 使用例とベストプラクティス

### 10.1 商品検索実装例
```swift
class ProductSearchViewModel: ObservableObject {
    @Published var searchResults: [SearchResult] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let priceComparisonService = PriceComparisonService()

    func searchProduct(name: String) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        do {
            let results = await priceComparisonService.comparePrices(productName: name)
            DispatchQueue.main.async {
                self.searchResults = results.map { SearchResult(from: $0) }
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = APIErrorHandler.handleError(error)
                self.isLoading = false
            }
        }
    }
}
```

### 10.2 セキュリティベストプラクティス
- API キーは環境変数で管理
- コードにハードコードしない
- 適切なHTTPS通信の確保
- ユーザーデータの外部送信禁止

---

## 付録: API実装チェックリスト

### A.1 実装前チェック
- [ ] API キーの取得と設定
- [ ] 利用規約の確認
- [ ] レート制限の把握
- [ ] 課金体系の理解

### A.2 実装時チェック
- [ ] エラーハンドリングの実装
- [ ] オフライン対応の実装
- [ ] キャッシュ戦略の実装
- [ ] レート制限対応の実装

### A.3 テスト項目
- [ ] 正常系のレスポンス処理
- [ ] 異常系のエラーハンドリング
- [ ] ネットワーク切断時の動作
- [ ] レート制限到達時の動作

---

**文書バージョン**: 1.0
**作成日**: 2025-09-23
**最終更新**: 2025-09-23
**作成者**: Claude Code

このAPI仕様書により、外部サービスとの連携を安全かつ効率的に実装できます。