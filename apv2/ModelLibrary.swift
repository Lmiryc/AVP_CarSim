import Foundation
import RealityKit

actor ModelLibrary {
    static let shared = ModelLibrary()

    private var gt3rsTemplate: Entity?
    private var gt3rsLoadTask: Task<Entity, Error>?

    func preloadGT3RS() async {
        _ = try? await loadGT3RSTemplate()
    }

    func makeGT3RSInstance() async throws -> Entity {
        let template = try await loadGT3RSTemplate()
        // Entities can't be attached to multiple scenes; clone a fresh instance.
        return template.clone(recursive: true)
    }

    private func loadGT3RSTemplate() async throws -> Entity {
        if let gt3rsTemplate { return gt3rsTemplate }

        if let task = gt3rsLoadTask {
            let entity = try await task.value
            gt3rsTemplate = entity
            gt3rsLoadTask = nil
            return entity
        }

        let task = Task<Entity, Error> {
            try await Entity(named: "GT3RS")
        }
        gt3rsLoadTask = task

        let entity = try await task.value
        gt3rsTemplate = entity
        gt3rsLoadTask = nil
        return entity
    }
}

