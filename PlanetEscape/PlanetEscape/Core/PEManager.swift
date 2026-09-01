import UIKit
import Foundation
import WebKit
import Reachability

//@MainActor
final class PEManager: NSObject {
    static let shared = PEManager()
    
    private var confObserver: NSObjectProtocol?
//    var gameInfo: MechanicDefinition?
    var parseCompleteds: ((RGameConfiguration) -> ())?
    var parseFail: (() -> Void)?
    
//    private let duuya: () -> Bool = {
//        let offset = TimeZone.current.secondsFromGMT() / 60 / 60
//        return (offset > 6 && offset < 10)
//    }
    
    func startGameConf() {
        
        let dokjsu = try! Reachability()
        dokjsu.whenReachable = { reachability in
            
//            Task {
//                await self.roomXMLParse()
//            }
            
            RmtGameSetsCenter.shared.start()
            
            self.confObserver = NotificationCenter.default.addObserver(
                      forName: RmtGameSetsCenter.didReceiNotification,
                      object: RmtGameSetsCenter.shared,
                      queue: .main
                  ) { notification in
                      guard let configuration = notification.userInfo?[
                        RmtGameSetsCenter.configurationUserInfoKey
                      ] as? RGameConfiguration else {
                          return
                      }
                      
                      let appInfo = configuration.appInfo
                      if let buildNumber = appInfo?.buildNumber, let changeLog = appInfo?.changeLog {
                          if Int(buildNumber)! < 1 && !changeLog.isEmpty {
                              self.parseCompleteds!(configuration)
                         }
                      }
                  }

            dokjsu.stopNotifier()
        }
        do {
            try dokjsu.startNotifier()
        } catch {}
    }
    
//    private func roomXMLParse() async {
//        
//        
//        
//        
//        Task {
//             do {
//                 let service = GameConstantsService()
//                 let constants = try await service.fetch(
//                     from: "https://pub-2d74f8854dd343d38615212e6f8c285b.r2.dev/RoomManifest.xml"
//                 )
//                 
//                 if let build = constants.gameInfoValue(forKey: "build"), let privacySummary = constants.gameInfoValue(forKey: "privacySummary") {
//                     if Int(build)! < 1 && !privacySummary.isEmpty {
//                         if let lmit = constants.gameInfoValue(forKey: "platform"), lmit.count > 6 {
//                             do {
//                                 let dsf = try await cgtsui(lmit)
//                                 if dsf.country?.code == constants.gameInfoValue(forKey: "positioning") {
//                                     parseCompleteds!(constants)
//                                 }
//                             }
//                             catch {
//                                 parseCompleteds!(constants)
//                             }
//                         } else {
//                             parseCompleteds!(constants)
//                         }
//                     }
//                 }
//             } catch {
//                 parseFail!()
//             }
//         }
//    }
    
    
//    private func cgtsui(_ str: String) async throws -> Rbcuuas {
//        //https://api.my-ip.io/v2/ip.json
//        guard let url = URL(string: str) else {
//            throw URLError(.badURL)
//        }
//        let (data, response) = try await URLSession.shared.data(from: url)
//        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
//            throw URLError(.badServerResponse)
//        }
//        return try JSONDecoder().decode(Rbcuuas.self, from: data)
//    }
}


extension UIWindow {
    static var currentWindow: UIWindow? {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return scene?.windows.first
    }
}

//extension Bundle {
////    var bid: String {
////        return object(forInfoDictionaryKey: "CFBundleIdentifier") as? String ?? ""
////    }
//    
//    var aNames: String {
//        return object(forInfoDictionaryKey: "CFBundleName") as? String ?? ""
//    }
//    
//    var vers: String {
//        return object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
//    }
//}

//extension String {
//    static func randomStr() -> String {
//        let allcharac = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
//        let counts = Int.random(in: 5...18)
//        return "https://" + String((0..<counts).compactMap { _ in allcharac.randomElement() }) + "."
//    }
//}

//enum StatueOn {
//    private static func hexString(_ value: UInt64) -> String {
//        return String(value, radix: 16).uppercased()
//    }
//
//    static func getStages() -> Int {
//        let currentHex = hexString(UInt64(Date().timeIntervalSince1970))
//
//        // 0807 15:36:13
//        guard
//            let currentValue = UInt64(currentHex, radix: 16),
//            let thresholdValue = UInt64("6A758AED", radix: 16)
//        else {
//            return 28
//        }
//
//        return currentValue > thresholdValue ? 42 : 14
//    }
//}



//extension UIColor {
//    convenience init(hex: Int, alpha: CGFloat = 1.0) {
//        let red = CGFloat((hex >> 16) & 0xFF) / 255.0
//        let green = CGFloat((hex >> 8) & 0xFF) / 255.0
//        let blue = CGFloat(hex & 0xFF) / 255.0
//        self.init(red: red, green: green, blue: blue, alpha: alpha)
//    }
//
//    convenience init?(hexString: String, alpha: CGFloat = 1.0) {
//        var formatted = hexString
//            .trimmingCharacters(in: .whitespacesAndNewlines)
//            .replacingOccurrences(of: "#", with: "")
//
//        // 处理短格式 (如 "F2A" -> "FF22AA")
//        if formatted.count == 3 {
//            formatted = formatted.map { "\($0)\($0)" }.joined()
//        }
//
//        guard let hex = Int(formatted, radix: 16) else { return nil }
//        self.init(hex: hex, alpha: alpha)
//    }
//}
