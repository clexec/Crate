import Foundation

/// Нативные источники музыки в Crate.
enum MusicSource: String, Codable, Hashable {
    case yandex
    case youtube

    var title: String {
        switch self {
        case .yandex: return "Яндекс Музыка"
        case .youtube: return "YouTube"
        }
    }
}

struct Track: Identifiable, Codable, Hashable {
    /// Стабильный числовой идентификатор (детерминированно из source + sourceID).
    let id: Int
    /// Оригинальный идентификатор в исходном сервисе (YM track id или YouTube videoId).
    let sourceID: String
    /// Источник, из которого получен трек.
    let source: MusicSource
    let title: String
    let artistName: String
    let albumTitle: String
    let artworkURL: URL?
    /// Прямая ссылка на полный трек. Может быть nil, пока не разрешена по запросу (лениво).
    var streamURL: URL?
    let durationMillis: Int
    let genre: String
    let releaseDate: Date?

    var durationText: String {
        TimeFormatHelper.format(milliseconds: durationMillis)
    }
}

extension Track {
    /// Детерминированный хеш (FNV-1a), чтобы id не менялся между запусками (важно для лайков/персистентности).
    static func stableID(source: MusicSource, sourceID: String) -> Int {
        let key = source.rawValue + ":" + sourceID
        var hash: UInt64 = 1469598103934665603
        for byte in key.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1099511628211
        }
        return Int(hash & 0x7FFF_FFFF_FFFF_FFFF)
    }
}
