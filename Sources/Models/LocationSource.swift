import Foundation

/// Provenance metadata indicating how physical location was derived for connection logs.
public enum LocationSource: String, Codable, CaseIterable, Identifiable {
    case gps = "GPS / CoreLocation"
    case ip = "Network IP Address"
    case timezone = "System Timezone"
    case pending = "Pending Approval"
    case disabled = "Disabled"

    public var id: String { rawValue }

    public var systemImage: String {
        switch self {
        case .gps: return "location.fill"
        case .ip: return "network"
        case .timezone: return "clock.fill"
        case .pending: return "questionmark.circle.fill"
        case .disabled: return "location.slash.fill"
        }
    }

    public var emoji: String {
        switch self {
        case .gps: return "🛰️"
        case .ip: return "🌐"
        case .timezone: return "🕒"
        case .pending: return "❓"
        case .disabled: return "🚫"
        }
    }

    public var shortLabel: String {
        switch self {
        case .gps: return "CoreLocation (Wi-Fi/GPS)"
        case .ip: return "Network IP"
        case .timezone: return "System Timezone"
        case .pending: return "Pending"
        case .disabled: return "Disabled"
        }
    }

    public var detailedDescription: String {
        switch self {
        case .gps:
            return "Resolved via macOS CoreLocation API using Wi-Fi access points and hardware positioning."
        case .ip:
            return "Resolved via local network IP address lookup when CoreLocation hardware positioning is unavailable."
        case .timezone:
            return "Resolved via macOS system time zone settings fallback (e.g., America/Los_Angeles)."
        case .pending:
            return "Awaiting Location Services authorization or first location update."
        case .disabled:
            return "Location Services disabled in macOS System Settings > Privacy & Security."
        }
    }
}
