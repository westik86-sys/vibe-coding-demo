//
//  ParticleEffectRenderer.swift
//  ParticleEffectCore
//
//  Created by Konstantin Moskalenko on 26.01.2026.
//

import Metal

public struct ParticleData {
    public var position: SIMD2<Float> = .zero
    public var size: Float = 0
    public var color: SIMD4<Float> = .zero
}

private enum BufferIndex: Int {
    case particles = 0
    case viewportSize = 1
}

public final class ParticleEffectRenderer {
    
    public let context: ParticleEffectContext
    
    private let particleBufferCapacity: Int = 1024
    private let particleBuffer: MTLBuffer
    private var particleCount: Int = 0
    private var viewportSize: SIMD2<Float> = .zero
    
    // MARK: - Initializers
    
    public init(context: ParticleEffectContext) throws {
        let bufferSize = MemoryLayout<ParticleData>.stride * particleBufferCapacity
        guard let buffer =  context.device.makeBuffer(length: bufferSize, options: .storageModeShared) else {
            throw ParticleEffectError.bufferCreationFailed
        }
        
        self.context = context
        self.particleBuffer = buffer
    }
    
    // MARK: - API
    
    public func updateParticles(_ body: (UnsafeMutablePointer<ParticleData>) -> Int) {
        let rawPointer = particleBuffer.contents()
        let count = rawPointer.withMemoryRebound(to: ParticleData.self, capacity: particleBufferCapacity, body)
        
        assert(count <= particleBufferCapacity)
        particleCount = min(count, particleBufferCapacity)
    }
    
    public func updateViewportSize(with size: CGSize) {
        viewportSize = [Float(size.width), Float(size.height)]
    }
    
    public func encodeRenderPass(using renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setRenderPipelineState(context.renderPipelineState)
        renderEncoder.setVertexBuffer(particleBuffer,
                                      offset: 0,
                                      index: BufferIndex.particles.rawValue)
        renderEncoder.setVertexBytes(&viewportSize,
                                     length: MemoryLayout<SIMD2<Float>>.stride,
                                     index: BufferIndex.viewportSize.rawValue)
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: particleCount)
    }
}
