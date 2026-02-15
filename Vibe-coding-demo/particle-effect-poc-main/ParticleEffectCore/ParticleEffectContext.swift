//
//  ParticleEffectContext.swift
//  ParticleEffectCore
//
//  Created by Konstantin Moskalenko on 28.01.2026.
//

import Metal

public final class ParticleEffectContext {
    
    public let device: MTLDevice
    public let commandQueue: MTLCommandQueue
    
    internal let renderPipelineState: MTLRenderPipelineState
    
    // MARK: - Initializers
    
    public init(device: MTLDevice? = MTLCreateSystemDefaultDevice(), colorPixelFormat: MTLPixelFormat = .bgra8Unorm) throws {
        guard let device else {
            throw ParticleEffectError.deviceUnavailable
        }
        
        guard let commandQueue = device.makeCommandQueue() else {
            throw ParticleEffectError.commandQueueCreationFailed
        }
        
        self.device = device
        self.commandQueue = commandQueue
        
        let defaultLibrary = try Self.makeDefaultLibrary(device: device, bundle: Bundle(for: Self.self))
        self.renderPipelineState = try Self.makeRenderPipelineState(library: defaultLibrary, colorPixelFormat: colorPixelFormat)
    }
    
    // MARK: - Private
    
    private static func makeDefaultLibrary(device: MTLDevice, bundle: Bundle) throws -> MTLLibrary {
        do {
            return try device.makeDefaultLibrary(bundle: bundle)
        } catch {
            throw ParticleEffectError.libraryCreationFailed(underlying: error)
        }
    }
    
    private static func makeFunction(name: String, library: MTLLibrary) throws -> MTLFunction {
        guard let function = library.makeFunction(name: name) else {
            throw ParticleEffectError.shaderFunctionNotFound(name: name)
        }
        return function
    }
    
    private static func makeRenderPipelineState(library: MTLLibrary, colorPixelFormat: MTLPixelFormat) throws -> MTLRenderPipelineState {
        let vertexFunction = try makeFunction(name: "vertexShader", library: library)
        let fragmentFunction = try makeFunction(name: "fragmentShader", library: library)
        
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        
        if let colorAttachment = renderPipelineDescriptor.colorAttachments[0] {
            colorAttachment.pixelFormat = colorPixelFormat
            colorAttachment.isBlendingEnabled = true
            colorAttachment.sourceRGBBlendFactor = .sourceAlpha
            colorAttachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
            colorAttachment.sourceAlphaBlendFactor = .one
            colorAttachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha
        }
        
        do {
            return try library.device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        } catch {
            throw ParticleEffectError.pipelineCreationFailed(underlying: error)
        }
    }
}
