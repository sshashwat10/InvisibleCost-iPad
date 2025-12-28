import Foundation
import RealityKit

/// RealityKitContent - 3D Assets for The Invisible Cost Experience
///
/// Contains the complete cinematic scene exported from Blender with:
/// - Stylized human figure with glowing core
/// - 18 notification windows swarming menacingly
/// - 80 floating data particles
/// - 5 orbiting data rings
/// - 12 light shards (reality crack effect)
/// - Central light column (revelation moment)
/// - Dramatic 5-light cinematic setup
/// - Floating text notifications
/// - Reflective ground plane
/// - HDRI environment (Neon Photostudio)

@MainActor
public struct RealityKitContent {
    public init() {}
    
    // MARK: - Asset Names
    
    public enum AssetName: String, CaseIterable, Sendable {
        // Complete cinematic scene
        case invisibleCostScene = "InvisibleCost_Cinematic"
        
        // Individual assets (legacy)
        case notificationWindow = "NotificationWindow"
        case lightShard = "LightShard"
        case dataParticle = "DataParticle"
        case lightBeam = "LightBeam"
        case centralAssembly = "CentralAssembly"
    }
    
    // MARK: - Asset Loading
    
    /// Load a named entity from the RealityKitContent bundle using URL-based loading
    public static func loadEntity(named name: String) async throws -> Entity {
        // First try URL-based loading (works with raw USD/USDZ files)
        if let url = Bundle.module.url(forResource: name, withExtension: "usdz") {
            return try await Entity(contentsOf: url)
        }
        // Fallback to named loading (works with Reality Composer Pro projects)
        return try await Entity(named: name, in: realityKitContentBundle)
    }
    
    /// Load a specific asset by enum
    public static func loadAsset(_ asset: AssetName) async throws -> Entity {
        try await loadEntity(named: asset.rawValue)
    }
    
    /// Check if an asset exists in the bundle
    public nonisolated static func assetExists(_ asset: AssetName) -> Bool {
        Bundle.module.url(forResource: asset.rawValue, withExtension: "usdz") != nil
    }
    
    // MARK: - Main Scene Loader
    
    /// Load the complete "Invisible Cost" cinematic scene
    /// This includes the human figure, notification swarm, data particles,
    /// light effects, and atmospheric elements - all from Blender
    public static func loadCinematicScene() async throws -> Entity {
        // Load directly from URL for maximum compatibility
        guard let url = Bundle.module.url(forResource: "InvisibleCost_Cinematic", withExtension: "usdz") else {
            throw NSError(domain: "RealityKitContent", code: 404, 
                          userInfo: [NSLocalizedDescriptionKey: "InvisibleCost_Cinematic.usdz not found in bundle"])
        }
        return try await Entity(contentsOf: url)
    }
    
    // MARK: - Legacy Individual Asset Loaders
    
    /// Load the notification window asset
    public static func loadNotificationWindow() async throws -> Entity {
        try await loadAsset(.notificationWindow)
    }
    
    /// Load the light shard asset
    public static func loadLightShard() async throws -> Entity {
        try await loadAsset(.lightShard)
    }
    
    /// Load the data particle asset
    public static func loadDataParticle() async throws -> Entity {
        try await loadAsset(.dataParticle)
    }
    
    /// Load the light beam asset
    public static func loadLightBeam() async throws -> Entity {
        try await loadAsset(.lightBeam)
    }
    
    /// Load the central assembly asset
    public static func loadCentralAssembly() async throws -> Entity {
        try await loadAsset(.centralAssembly)
    }
}

// MARK: - Bundle Access

/// Access the RealityKitContent bundle for asset loading
public let realityKitContentBundle = Bundle.module
