import AppKit
import Foundation
import ApplicationServices

/// Service responsible for extracting the active URL and domain name from web browsers
/// using fast targeted Accessibility attributes, AppleScript fallbacks, and window title matching.
public final class DomainExtractor {
    public static let shared = DomainExtractor()

    private let extractorQueue = DispatchQueue(label: "com.nicklee.macDisplayMagic.domainExtractor", qos: .userInitiated)

    /// Supported browser bundle identifiers.
    public static let browserBundleIDs: Set<String> = [
        "com.google.Chrome",
        "com.apple.Safari",
        "org.mozilla.firefox",
        "company.thebrowser.Browser", // Arc
        "com.brave.Browser",
        "com.microsoft.edgemac",
        "com.opera.operasoftware.Opera"
    ]

    /// Checks if an application is a supported web browser.
    public static func isBrowser(bundleID: String) -> Bool {
        return browserBundleIDs.contains(bundleID)
    }

    /// Synchronously extracts active domain using fast targeted AX attributes or title matching (non-blocking).
    public func extractDomain(bundleID: String, pid: pid_t, windowTitle: String? = nil) -> String? {
        guard Self.isBrowser(bundleID: bundleID) else { return nil }

        // 1. Fast targeted Accessibility lookup (Direct AXDocument or AXURL attribute)
        if let axURL = extractFastAXURL(pid: pid), let domain = parseDomain(from: axURL) {
            return domain
        }

        // 2. Title-based domain matching fallback (Instant)
        if let title = windowTitle?.lowercased() {
            let knownDomains = AppSettings.shared.noZoomDomains
            for d in knownDomains {
                let cleanDomain = d.lowercased().trimmingCharacters(in: .whitespaces)
                let name = cleanDomain.replacingOccurrences(of: ".com", with: "")
                                      .replacingOccurrences(of: ".tv", with: "")
                                      .replacingOccurrences(of: ".org", with: "")
                                      .replacingOccurrences(of: ".net", with: "")
                
                var aliases = [name]
                if name.contains("disneyplus") || name.contains("disney") {
                    aliases.append("disney+")
                    aliases.append("disney")
                }
                
                for alias in aliases {
                    if !alias.isEmpty && title.contains(alias) {
                        return cleanDomain
                    }
                }
            }
        }

        return nil
    }

    /// Asynchronously extracts active domain and yields result via completion block (never hangs caller).
    public func extractDomainAsync(bundleID: String, pid: pid_t, windowTitle: String? = nil, completion: @escaping (String?) -> Void) {
        extractorQueue.async { [weak self] in
            guard let self = self else { return }
            let domain = self.extractDomain(bundleID: bundleID, pid: pid, windowTitle: windowTitle)
            DispatchQueue.main.async {
                completion(domain)
            }
        }
    }

    /// Extracts domain name from a raw URL string.
    public func parseDomain(from rawInput: String) -> String? {
        var input = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !input.contains("://") && !input.hasPrefix("http") {
            input = "https://" + input
        }

        if let url = URL(string: input), let host = url.host, !host.isEmpty {
            let lower = host.lowercased()
            return lower.hasPrefix("www.") ? String(lower.dropFirst(4)) : lower
        }
        return nil
    }

    /// Fast targeted Accessibility lookup checking focused window / document attributes (no deep tree traversal).
    private func extractFastAXURL(pid: pid_t) -> String? {
        let appElement = AXUIElementCreateApplication(pid)
        var windowRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &windowRef) == .success,
              let windowRef = windowRef else { return nil }
        
        let windowElement = windowRef as! AXUIElement

        // Check kAXDocumentAttribute on focused window
        var docRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(windowElement, kAXDocumentAttribute as CFString, &docRef) == .success,
           let docStr = docRef as? String, !docStr.isEmpty {
            return docStr
        }

        // Check kAXURLAttribute on focused window
        var urlRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(windowElement, "AXURL" as CFString, &urlRef) == .success,
           let urlStr = urlRef as? String, !urlStr.isEmpty {
            return urlStr
        }

        // Check focused UI element value (e.g. active address bar textfield)
        var focusedRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedRef) == .success,
           let focusedElement = focusedRef {
            var valRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(focusedElement as! AXUIElement, kAXValueAttribute as CFString, &valRef) == .success,
               let valStr = valRef as? String, valStr.contains(".") {
                return valStr
            }
        }

        return nil
    }
}
