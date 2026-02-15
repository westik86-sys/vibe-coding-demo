//
//  ParticleEffectView.swift
//  ParticleEffectCore
//
//  Created by Konstantin Moskalenko on 28.01.2026.
//

import MetalKit

public final class ParticleEffectMetalView: MTKView, MTKViewDelegate {
    
    private let renderer: ParticleEffectRenderer?
    
    // MARK: - Initializers
    
    public init(context: ParticleEffectContext) {
        do {
            renderer = try ParticleEffectRenderer(context: context)
        } catch {
            assertionFailure("Renderer creation failed: \(error)")
            renderer = nil
        }
        
        super.init(frame: .zero, device: context.device)
        
        isOpaque = false
        clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        enableSetNeedsDisplay = true
        isPaused = true
        delegate = self
    }
    
    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - API
    
    public func updateParticles(_ body: (UnsafeMutablePointer<ParticleData>) -> Int) {
        guard let renderer else { return }
        
        renderer.updateParticles(body)
        setNeedsDisplay()
    }
    
    // MARK: - MTKViewDelegate
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        guard let renderer else { return }
        
        renderer.updateViewportSize(with: size)
    }
    
    public func draw(in view: MTKView) {
        guard let renderer,
              let commandBuffer = renderer.context.commandQueue.makeCommandBuffer(),
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        else { return }
        
        renderer.encodeRenderPass(using: commandEncoder)
        commandEncoder.endEncoding()
        
        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
        }
        
        commandBuffer.commit()
    }
}
