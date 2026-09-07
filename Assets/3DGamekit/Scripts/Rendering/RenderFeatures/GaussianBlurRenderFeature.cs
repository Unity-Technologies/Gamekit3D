using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.RenderGraphModule.Util;

public class GaussianBlurRenderFeature : ScriptableRendererFeature
{
    class GaussianBlurPass : ScriptableRenderPass
    {
        private Material blitMaterial;
        private readonly int blurSizeId = Shader.PropertyToID("_BlurSize");

        private void UpdateMaterial()
        {
            if (blitMaterial == null || blitMaterial.shader == null)
            {
                blitMaterial = new Material(Shader.Find("Hidden/Universal/GaussianBlur"));
            }
            blitMaterial.SetFloat(blurSizeId, 3.0f);
        }

        private class PassData
        {
        }
        
        public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
        {
            UpdateMaterial();
            
            UniversalResourceData resourceData = frameData.Get<UniversalResourceData>();
            
            var rtDesc = new RenderTextureDescriptor(Screen.width, Screen.height, RenderTextureFormat.Default, 0);
            var RT1 = UniversalRenderer.CreateRenderGraphTexture(renderGraph, rtDesc, "GaussianBlur_RT1", false);
            var RT2 = UniversalRenderer.CreateRenderGraphTexture(renderGraph, rtDesc, "GaussianBlur_RT2", false);
            //var RTOutput = resourceData.activeColorTexture; //UniversalRenderer.CreateRenderGraphTexture(renderGraph, rtDesc, "GaussianBlur_Output", false);
            var RTOutput = UniversalRenderer.CreateRenderGraphTexture(renderGraph, rtDesc, "GaussianBlur_Output", false);
            

            RenderGraphUtils.BlitMaterialParameters blitParamsHorizontalPassInitial =
                new RenderGraphUtils.BlitMaterialParameters(resourceData.activeColorTexture, RT1, blitMaterial, 0);
            RenderGraphUtils.BlitMaterialParameters blitParamsHorizontalPass =
                new RenderGraphUtils.BlitMaterialParameters(RT2, RT1, blitMaterial, 0);
            RenderGraphUtils.BlitMaterialParameters blitParamsVerticalPass =
                new RenderGraphUtils.BlitMaterialParameters(RT1, RT2, blitMaterial, 1);
            
            renderGraph.AddBlitPass(blitParamsHorizontalPassInitial, "Gaussian Blur Pass 1");
            renderGraph.AddBlitPass(blitParamsVerticalPass, "Gaussian Blur Pass 2");
            renderGraph.AddBlitPass(RT2, RTOutput, Vector2.one, Vector2.zero, passName:"Gaussian Blur Output Pass");
            
            using (var builder = renderGraph.AddRasterRenderPass<PassData>(
                       "Expose texture", out var passData))
            {
                builder.AllowGlobalStateModification(true);
                builder.UseTexture(RTOutput);
                builder.SetRenderFunc((PassData data, RasterGraphContext context) =>
                {
                    context.cmd.SetGlobalTexture("_GaussianBlurOutput", RTOutput);
                });
            }
        }
    }

    GaussianBlurPass m_ScriptablePass;

    /// <inheritdoc/>
    public override void Create()
    {
        m_ScriptablePass = new GaussianBlurPass();

        // Configures where the render pass should be injected.
        m_ScriptablePass.renderPassEvent = RenderPassEvent.AfterRenderingPostProcessing;
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_ScriptablePass);
    }
}
