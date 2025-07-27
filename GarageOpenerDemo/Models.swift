import Foundation
import Combine

import AbloyCuBeMobileSDK

struct GarageDoor: Identifiable, Equatable {
    let id: String
    let name: String
    let location: String
    var isOpen: Bool = false
    
    // Garaža je "online" ako smo otkrili njezinu bravu u blizini.
    var isOnline: Bool {
        discoveredDevice != nil
    }
    
    // Ovdje pohranjujemo stvarne objekte iz SDK-a
    var discoveredDevice: DiscoveredLock?
    
    // Svojstva za UI
    var isFake: Bool = false
    var isConnecting: Bool = false
    var isOperating: Bool = false
    
    // Potrebno za Equatable, uspoređujemo samo po ID-u
    static func == (lhs: GarageDoor, rhs: GarageDoor) -> Bool {
        lhs.id == rhs.id
    }
}
