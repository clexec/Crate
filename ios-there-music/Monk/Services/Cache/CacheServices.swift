import Combine
import SwiftUI

final class ImageCacheService {
    static let shared = ImageCacheService()
    private let cache = NSCache<NSURL, UIImage>()
    func image(for url: URL) -> UIImage? { cache.object(forKey: url as NSURL) }
    func set(_ image: UIImage, for url: URL) { cache.setObject(image, forKey: url as NSURL) }
    func clear() { cache.removeAllObjects() }
}

final class DataCacheService {
    private var values: [String: Data] = [:]
    func value(for key: String) -> Data? { values[key] }
    func set(_ data: Data, for key: String) { values[key] = data }
    func clear() { values.removeAll() }
}

final class CacheManager: ObservableObject {
    let imageCache = ImageCacheService.shared
    let dataCache = DataCacheService()
    @Published var estimatedSize = "Ready"
    func clear() { imageCache.clear(); dataCache.clear(); estimatedSize = "Cleared" }
}
