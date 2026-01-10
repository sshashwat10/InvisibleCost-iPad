import Foundation
import Observation
import Network

/// Bridge for communicating with Unreal Engine render server
/// Protocol: JSON-RPC over TCP/WebSocket
///
/// This enables the hybrid architecture where:
/// - Unreal handles complex rendering (humans, particles, effects)
/// - visionOS hosts the experience and manages interaction
///
/// Future implementation: Connect to Unreal's pixel streaming or
/// receive render texture updates for display in RealityKit

@Observable
class UnrealBridge {
    
    // MARK: - Connection State
    
    enum ConnectionState {
        case disconnected
        case connecting
        case connected
        case error(String)
    }
    
    var connectionState: ConnectionState = .disconnected
    var isConnected: Bool {
        if case .connected = connectionState { return true }
        return false
    }
    
    // MARK: - Scene State
    
    enum SceneState: String, Codable {
        case idle = "idle"
        case overwhelm = "overwhelm"
        case patternBreak = "pattern_break"
        case humanFragment = "human_fragment"
        case dataChoreography = "data_choreography"
        case restoration = "restoration"
        case exit = "exit"
    }
    
    var currentSceneState: SceneState = .idle
    
    // MARK: - Connection
    
    private var connection: NWConnection?
    private let host: NWEndpoint.Host = "localhost"
    private let port: NWEndpoint.Port = 9998  // Unreal MCP default port
    
    func connect() {
        connectionState = .connecting
        
        connection = NWConnection(host: host, port: port, using: .tcp)
        
        connection?.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    self?.connectionState = .connected
                    self?.startReceiving()
                case .failed(let error):
                    self?.connectionState = .error(error.localizedDescription)
                case .cancelled:
                    self?.connectionState = .disconnected
                default:
                    break
                }
            }
        }
        
        connection?.start(queue: .global())
    }
    
    func disconnect() {
        connection?.cancel()
        connectionState = .disconnected
    }
    
    // MARK: - Scene Commands
    
    /// Transition Unreal to a specific scene state
    func transitionTo(state: SceneState, duration: TimeInterval = 1.0) {
        let command = SceneCommand(
            type: "transition",
            state: state.rawValue,
            duration: duration
        )
        sendCommand(command)
        currentSceneState = state
    }
    
    /// Map narrative phase to Unreal scene state
    func syncWithPhase(_ phase: NarrativePhase) {
        let sceneState: SceneState
        
        switch phase {
        case .waiting:
            sceneState = .idle
        case .microColdOpen, .narratorFrame:
            sceneState = .idle
        case .spatialOverwhelm, .realityCrack, .humanFragment:
            sceneState = .overwhelm
        case .patternBreak:
            sceneState = .patternBreak
        case .agenticOrchestration:
            sceneState = .dataChoreography
        case .humanReturn:
            sceneState = .restoration
        case .personalization, .stillnessCTA, .complete:
            sceneState = .exit
        }
        
        transitionTo(state: sceneState)
    }
    
    /// Update Unreal with current phase progress (0.0 - 1.0)
    func updateProgress(_ progress: Double, phase: NarrativePhase) {
        let command = ProgressCommand(
            type: "progress",
            phase: phase.rawValue,
            progress: progress
        )
        sendCommand(command)
    }
    
    // MARK: - Low-Level Communication
    
    private func sendCommand<T: Encodable>(_ command: T) {
        guard case .connected = connectionState else {
            print("UnrealBridge: Not connected, skipping command")
            return
        }
        
        do {
            let data = try JSONEncoder().encode(command)
            connection?.send(content: data, completion: .contentProcessed { error in
                if let error = error {
                    print("UnrealBridge: Send error - \(error)")
                }
            })
        } catch {
            print("UnrealBridge: Encoding error - \(error)")
        }
    }
    
    private func startReceiving() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            if let data = data {
                self?.handleReceivedData(data)
            }
            
            if let error = error {
                print("UnrealBridge: Receive error - \(error)")
                return
            }
            
            if !isComplete {
                self?.startReceiving()
            }
        }
    }
    
    private func handleReceivedData(_ data: Data) {
        // Handle responses from Unreal (scene ready, transition complete, etc.)
        if let response = try? JSONDecoder().decode(UnrealResponse.self, from: data) {
            DispatchQueue.main.async { [weak self] in
                self?.processResponse(response)
            }
        }
    }
    
    private func processResponse(_ response: UnrealResponse) {
        switch response.type {
        case "scene_ready":
            print("UnrealBridge: Scene '\(response.state ?? "unknown")' ready")
        case "transition_complete":
            print("UnrealBridge: Transition to '\(response.state ?? "unknown")' complete")
        case "error":
            print("UnrealBridge: Error - \(response.message ?? "unknown")")
        default:
            break
        }
    }
}

// MARK: - Command Types

private struct SceneCommand: Encodable {
    let type: String
    let state: String
    let duration: TimeInterval
}

private struct ProgressCommand: Encodable {
    let type: String
    let phase: Int
    let progress: Double
}

private struct UnrealResponse: Decodable {
    let type: String
    let state: String?
    let message: String?
}







