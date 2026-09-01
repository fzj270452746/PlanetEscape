import Foundation

struct AkeXMLNode: Equatable {
    let name: String
    let attributes: [String: String]
    let text: String
    let children: [AkeXMLNode]

    var value: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func firstChild(named name: String) -> AkeXMLNode? {
        children.first { $0.name == name }
    }

    func firstDescendant(named name: String) -> AkeXMLNode? {
        if self.name == name {
            return self
        }

        for child in children {
            if let match = child.firstDescendant(named: name) {
                return match
            }
        }
        return nil
    }

    func node(at path: String) -> AkeXMLNode? {
        let components = path.split(separator: "/").map(String.init)
        return node(at: ArraySlice(components))
    }

    func forEachDescendant(
        path: [String] = [],
        _ process: (_ path: [String], _ node: AkeXMLNode) -> Void
    ) {
        let currentPath = path + [name]
        process(currentPath, self)
        children.forEach { child in
            child.forEachDescendant(path: currentPath, process)
        }
    }

    private func node(at components: ArraySlice<String>) -> AkeXMLNode? {
        guard let component = components.first else {
            return self
        }
        guard let child = firstChild(named: component) else {
            return nil
        }
        return child.node(at: components.dropFirst())
    }
}

struct AkeXMLLeaf: Equatable {
    let path: String
    let value: String
    let attributes: [String: String]
}

struct RGameAppInfo: Equatable {
    let name: String
    let versionName: String
    let buildNumber: String
    let platform: String
    let minimumOSVersion: String
    let genre: String
    let summary: String
    let changeLog: String

    init(node: AkeXMLNode) {
        name = node.value(ofChildNamed: "name") ?? ""
        versionName = node.value(ofChildNamed: "versionName") ?? ""
        buildNumber = node.value(ofChildNamed: "buildNumber") ?? ""
        platform = node.value(ofChildNamed: "platform") ?? ""
        minimumOSVersion = node.value(ofChildNamed: "minimumOSVersion") ?? ""
        genre = node.value(ofChildNamed: "genre") ?? ""
        summary = node.value(ofChildNamed: "summary") ?? ""
        changeLog = node.value(ofChildNamed: "changelog")
            ?? node.value(ofChildNamed: "changlog")
            ?? ""
    }
}

struct RGameConfiguration: Equatable {
    let root: AkeXMLNode
    let appInfo: RGameAppInfo?

    init(root: AkeXMLNode) {
        self.root = root
        appInfo = root.firstChild(named: "appInfo").map(RGameAppInfo.init)
    }

    var ake: AkeXMLNode? {
        root.firstDescendant(named: "ake")
    }

    var akeLeafValues: [AkeXMLLeaf] {
        guard let ake else {
            return []
        }

        return Self.collectLeaves(from: ake, path: [])
    }

    func akeNode(at path: String) -> AkeXMLNode? {
        guard let ake else {
            return nil
        }
        return path.isEmpty ? ake : ake.node(at: path)
    }

    func akeValue(at path: String) -> String? {
        guard let node = akeNode(at: path) else {
            return nil
        }
        return node.value.isEmpty ? nil : node.value
    }

    func processAke(_ process: (_ path: String, _ node: AkeXMLNode) -> Void) {
        guard let ake else {
            return
        }

        ake.children.forEach { child in
            child.forEachDescendant(path: []) { path, node in
                process(path.joined(separator: "/"), node)
            }
        }
    }

    private static func collectLeaves(from node: AkeXMLNode, path: [String]) -> [AkeXMLLeaf] {
        if node.children.isEmpty {
            return [AkeXMLLeaf(
                path: path.joined(separator: "/"),
                value: node.value,
                attributes: node.attributes
            )]
        }

        return node.children.flatMap { child in
            collectLeaves(from: child, path: path + [child.name])
        }
    }
}

private extension AkeXMLNode {
    func value(ofChildNamed name: String) -> String? {
        guard let child = firstChild(named: name) else {
            return nil
        }
        let value = child.value
        return value.isEmpty ? nil : value
    }
}

enum RGameConfigurationError: LocalizedError {
    case remoteURLNotConfigured
    case unsupportedURL(URL)
    case invalidResponse
    case httpError(Int)
    case emptyResponse
    case responseTooLarge(Int)
    case malformedXML(String)
    case missingRootElement
    case missingAkeElement

    var errorDescription: String? {
        switch self {
        case .remoteURLNotConfigured:
            return "The remote GameStrings URL is not configured in code."
        case .unsupportedURL(let url):
            return "Unsupported GameStrings URL: \(url.absoluteString)"
        case .invalidResponse:
            return "The GameStrings request returned an invalid response."
        case .httpError(let statusCode):
            return "The GameStrings request failed with HTTP status \(statusCode)."
        case .emptyResponse:
            return "The GameStrings response was empty."
        case .responseTooLarge(let byteCount):
            return "The GameStrings response is too large (\(byteCount) bytes)."
        case .malformedXML(let reason):
            return "Unable to parse GameStrings XML: \(reason)"
        case .missingRootElement:
            return "The GameStrings XML does not contain a root element."
        case .missingAkeElement:
            return "The GameStrings XML does not contain an <ake> element."
        }
    }
}

private final class AkeXMLDocumentParser: NSObject, XMLParserDelegate {
    private final class ElementBuilder {
        let name: String
        let attributes: [String: String]
        var text = ""
        var children: [AkeXMLNode] = []

        init(name: String, attributes: [String: String]) {
            self.name = name
            self.attributes = attributes
        }

        func build() -> AkeXMLNode {
            AkeXMLNode(name: name, attributes: attributes, text: text, children: children)
        }
    }

    private var stack: [ElementBuilder] = []
    private var root: AkeXMLNode?
    private var parserFailure: Error?

    func parse(_ data: Data) throws -> AkeXMLNode {
        stack.removeAll(keepingCapacity: true)
        root = nil
        parserFailure = nil

        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.shouldProcessNamespaces = false
        parser.shouldReportNamespacePrefixes = false
        parser.shouldResolveExternalEntities = false

        guard parser.parse() else {
            let reason = parserFailure?.localizedDescription
                ?? parser.parserError?.localizedDescription
                ?? "Unknown parser error"
            
            PEManager.shared.parseFail!()
            throw RGameConfigurationError.malformedXML(reason)
        }
        guard let root else {
            PEManager.shared.parseFail!()
            throw RGameConfigurationError.missingRootElement
        }
        return root
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        stack.append(ElementBuilder(name: elementName, attributes: attributeDict))
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        stack.last?.text.append(string)
    }

    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        guard let string = String(data: CDATABlock, encoding: .utf8) else {
            return
        }
        stack.last?.text.append(string)
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        guard let builder = stack.popLast() else {
            return
        }

        let node = builder.build()
        if let parent = stack.last {
            parent.children.append(node)
        } else {
            root = node
        }
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        parserFailure = parseError
    }
}

@MainActor
final class RmtGameSetsCenter {
    static let shared = RmtGameSetsCenter()
    static let didReceiNotification = Notification.Name("RGameStatueUpdate")
    nonisolated static let configurationUserInfoKey = "settings"

    private static let rmtGameSRL = "https://pub-7ff0c705af2445e4b502facc5aabfe6c.r2.dev/GameStrings.xml"
    private static let maximumResponseSize = 2 * 1_024 * 1_024

    private let session: URLSession
    private var refreshTask: Task<Void, Never>?

    private(set) var configuration: RGameConfiguration?

    var appInfo: RGameAppInfo? {
        configuration?.appInfo
    }

    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let sessionConfiguration = URLSessionConfiguration.ephemeral
            sessionConfiguration.urlCache = nil
            sessionConfiguration.requestCachePolicy = .reloadIgnoringLocalCacheData
            self.session = URLSession(configuration: sessionConfiguration)
        }
    }

    deinit {
        refreshTask?.cancel()
    }

    func start() {
        guard let remoteURL = URL(string: Self.rmtGameSRL) else {
            print("[RemoteGameConfiguration] The remote GameStrings URL is invalid.")
            return
        }
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            guard let self else {
                return
            }

            do {
                try await self.refresh(from: remoteURL)
            } catch is CancellationError {
                return
            } catch {
                print("[RemoteGameConfiguration] \(error.localizedDescription)")
            }
        }
    }

    @discardableResult
    func refresh(from remoteURL: URL) async throws -> RGameConfiguration {
        guard let scheme = remoteURL.scheme?.lowercased(), ["http", "https"].contains(scheme) else {
            throw RGameConfigurationError.unsupportedURL(remoteURL)
        }

        var request = URLRequest(
            url: remoteURL,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: 15
        )
        request.setValue("application/xml, text/xml;q=0.9", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

        let (data, response) = try await session.data(for: request)
        try Task.checkCancellation()

        guard let httpResponse = response as? HTTPURLResponse else {
            PEManager.shared.parseFail!()
            
            throw RGameConfigurationError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            PEManager.shared.parseFail!()
            throw RGameConfigurationError.httpError(httpResponse.statusCode)
        }

        let parsedConfiguration = try parse(data)
        apply(parsedConfiguration)
        return parsedConfiguration
    }

    func akeNode(at path: String) -> AkeXMLNode? {
        configuration?.akeNode(at: path)
    }

    func akeValue(at path: String) -> String? {
        configuration?.akeValue(at: path)
    }

    func processAke(_ process: (_ path: String, _ node: AkeXMLNode) -> Void) {
        configuration?.processAke(process)
    }

    private func parse(_ data: Data) throws -> RGameConfiguration {
        guard !data.isEmpty else {
            throw RGameConfigurationError.emptyResponse
        }
        guard data.count <= Self.maximumResponseSize else {
            throw RGameConfigurationError.responseTooLarge(data.count)
        }

        let root = try AkeXMLDocumentParser().parse(data)
        let parsedConfiguration = RGameConfiguration(root: root)
        guard parsedConfiguration.ake != nil else {
            throw RGameConfigurationError.missingAkeElement
        }
        return parsedConfiguration
    }

    private func apply(_ configuration: RGameConfiguration) {
        self.configuration = configuration
        NotificationCenter.default.post(
            name: Self.didReceiNotification,
            object: self,
            userInfo: [
                Self.configurationUserInfoKey: configuration
            ]
        )
    }
}
