using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering.RenderGraphModule;
using System.Collections.Generic;

public class ComplexSkyboxRenderFeature : ScriptableRendererFeature
{
    // Internal classes
    
    [System.Serializable]
    public class Settings
    {
        public RenderPassEvent insertionPoint = RenderPassEvent.AfterRenderingOpaques;
    }
    
    // Settings for the render feature
    public Settings settings = new ();
    
    // Reference to the render pass
    private CustomSkyboxPass renderPass;
    
    // Create the render pass
    public override void Create()
    {
        renderPass = new CustomSkyboxPass(settings);
        renderPass.renderPassEvent = settings.insertionPoint;
    }
    
    // Enqueue the render pass each frame, as long as there is a valid SkyboxRenderer
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (ComplexSkyboxRenderer.Instance!=null)
        {
            renderer.EnqueuePass(renderPass);
        }
    }
    
    // Render pass class
    class CustomSkyboxPass : ScriptableRenderPass
    {
        // Pass data structure for render graph
        private class PassData
        {
            public List<ComplexSkyboxRenderer.RenderInfo> renderers;
            public Matrix4x4 projectionMatrix;
            public Matrix4x4 viewMatrix;
            public Matrix4x4 oldProjectionMatrix;
            public Matrix4x4 oldViewMatrix;
        }
        
        public CustomSkyboxPass(Settings settings)
        {
            string passName = "Complex skybox rendering";
            profilingSampler = new ProfilingSampler(passName);
        }
        
        public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
        {
            // Check if the renderer exists, and if it's enabled
            if (ComplexSkyboxRenderer.Instance == null || ComplexSkyboxRenderer.Instance.enabled == false ||
                ComplexSkyboxRenderer.Instance.gameObject.activeInHierarchy == false)
                return;
            
            // Get current camera this pass renders to, and ensures it's valid
            // if not done, this pass will even render in the shader graph preview
            UniversalCameraData cameraData = frameData.Get<UniversalCameraData>();
            Camera cam = cameraData.camera;

            if (ComplexSkyboxRenderer.Instance.TargetCamera != null &&
                ComplexSkyboxRenderer.Instance.TargetCamera != cam)
                return;
            
            // Get renderers to draw
            var meshesToRender = ComplexSkyboxRenderer.Instance.MeshesToRender;
            if (meshesToRender.Count == 0) 
                return;
            
            // Create custom projection matrix that outputs Z = 1
            // This only works with the assumption each rendering pass is laid out op top of each other
            // and that renderers are well sorted
            Matrix4x4 customProjection = cam.projectionMatrix;
            customProjection.SetRow(2, customProjection.GetRow(3));

            // Patch viewMatrix so we look at the given location, wherever the skybox is
            Matrix4x4 viewMatrix = cam.worldToCameraMatrix;
            var viewpointPosition = ComplexSkyboxRenderer.Instance.ViewpointOrigin;
            viewMatrix.SetColumn(3, new Vector4(
                -Vector3.Dot(viewMatrix.GetRow(0), viewpointPosition),
                -Vector3.Dot(viewMatrix.GetRow(1), viewpointPosition),
                -Vector3.Dot(viewMatrix.GetRow(2), viewpointPosition),
                1f
            ));
            
            // Actual pass adding
            using (var builder = renderGraph.AddRasterRenderPass<PassData>(passName, out var passData))
            {
                // Setup pass data
                passData.renderers = meshesToRender;
                passData.viewMatrix = viewMatrix;
                passData.projectionMatrix = customProjection;
                passData.oldViewMatrix = cam.worldToCameraMatrix;
                passData.oldProjectionMatrix = cam.projectionMatrix;
                
                // Set render target
                var resourceData = frameData.Get<UniversalResourceData>();
                builder.SetRenderAttachment(resourceData.activeColorTexture, 0);
                builder.SetRenderAttachmentDepth(resourceData.activeDepthTexture, AccessFlags.ReadWrite);
                
                // Allow pass culling
                builder.AllowPassCulling(false);
                
                // Set render function
                builder.SetRenderFunc((PassData data, RasterGraphContext context) =>
                {
                    // Set custom projection matrix
                    context.cmd.SetViewProjectionMatrices(data.viewMatrix, data.projectionMatrix);
                    
                    // Draw the renderer list
                    for (var index = 0; index < data.renderers.Count; index++)
                    {
                        var rendererInfo = data.renderers[index];
                        if (rendererInfo.renderer == null || !rendererInfo.renderer.enabled ||
                            !rendererInfo.renderer.gameObject.activeInHierarchy)
                            continue;

                        Material mat = rendererInfo.renderer.sharedMaterial;
                        if (mat == null) 
                            continue;

                        var sharedMesh = rendererInfo.mesh;
                        for (int submesh = 0; submesh < sharedMesh.subMeshCount; submesh++)
                        {
                            context.cmd.DrawRenderer(rendererInfo.renderer, mat, submesh, 0);
                        }
                    }

                    // Restore original matrices
                    context.cmd.SetViewProjectionMatrices(data.oldViewMatrix, data.oldProjectionMatrix);
                });
            }
        }
    }
}
