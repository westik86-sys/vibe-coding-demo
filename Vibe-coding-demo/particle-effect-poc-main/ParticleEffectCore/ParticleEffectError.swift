//
//  ParticleEffectError.swift
//  ParticleEffectCore
//
//  Created by Konstantin Moskalenko on 28.01.2026.
//

public enum ParticleEffectError: Error {
    case deviceUnavailable
    case commandQueueCreationFailed
    case libraryCreationFailed(underlying: Error)
    case shaderFunctionNotFound(name: String)
    case pipelineCreationFailed(underlying: Error)
    case bufferCreationFailed
}
