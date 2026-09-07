using System;
using System.Collections.Generic;
using Unity.Cinemachine;
using Unity.Collections;
using Unity.Collections.LowLevel.Unsafe;
using UnityEditor;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.RenderGraphModule.Util;
using UnityEngine.Scripting.APIUpdating;

namespace UnityEngine.Rendering.Universal
{
    /// <summary>
    /// The scriptable render pass used with the render objects renderer feature.
    /// </summary>
    [MovedFrom(true, "UnityEngine.Experimental.Rendering.Universal")]
    public class WaterReflectionRenderPass : ScriptableRenderPass
    {
        /// <summary>
        /// The queue type for the objects to render.
        /// </summary>
        public enum MyRenderQueueType
        {
            /// <summary>
            /// Use this for opaque objects.
            /// </summary>
            Opaque,

            /// <summary>
            /// Use this for transparent objects.
            /// </summary>
            Transparent,
        }
        
        MyRenderQueueType renderQueueType;
        FilteringSettings m_FilteringSettings;
        WaterReflectionRenderFeature.CustomCameraSettings m_CameraSettings;


        /// <summary>
        /// The override material to use.
        /// </summary>
        public Material overrideMaterial { get; set; }

        /// <summary>
        /// The pass index to use with the override material.
        /// </summary>
        public int overrideMaterialPassIndex { get; set; }

        /// <summary>
        /// The override shader to use.
        /// </summary>
        public Shader overrideShader { get; set; }

        /// <summary>
        /// The pass index to use with the override shader.
        /// </summary>
        public int overrideShaderPassIndex { get; set; }

        List<ShaderTagId> m_ShaderTagIdList = new List<ShaderTagId>();
        private PassData m_PassData;

        /// <summary>
        /// Sets the write and comparison function for depth.
        /// </summary>
        /// <param name="writeEnabled">Sets whether it should write to depth or not.</param>
        /// <param name="function">The depth comparison function to use.</param>
        [Obsolete("Use SetDepthState instead", true)]
        public void SetDetphState(bool writeEnabled, CompareFunction function = CompareFunction.Less)
        {
            SetDepthState(writeEnabled, function);
        }

        /// <summary>
        /// Sets the write and comparison function for depth.
        /// </summary>
        /// <param name="writeEnabled">Sets whether it should write to depth or not.</param>
        /// <param name="function">The depth comparison function to use.</param>
        public void SetDepthState(bool writeEnabled, CompareFunction function = CompareFunction.Less)
        {
            m_RenderStateBlock.mask |= RenderStateMask.Depth;
            m_RenderStateBlock.depthState = new DepthState(writeEnabled, function);
        }

        /// <summary>
        /// Sets up the stencil settings for the pass.
        /// </summary>
        /// <param name="reference">The stencil reference value.</param>
        /// <param name="compareFunction">The comparison function to use.</param>
        /// <param name="passOp">The stencil operation to use when the stencil test passes.</param>
        /// <param name="failOp">The stencil operation to use when the stencil test fails.</param>
        /// <param name="zFailOp">The stencil operation to use when the stencil test fails because of depth.</param>
        public void SetStencilState(int reference, CompareFunction compareFunction, StencilOp passOp, StencilOp failOp, StencilOp zFailOp)
        {
            StencilState stencilState = StencilState.defaultValue;
            stencilState.enabled = true;
            stencilState.SetCompareFunction(compareFunction);
            stencilState.SetPassOperation(passOp);
            stencilState.SetFailOperation(failOp);
            stencilState.SetZFailOperation(zFailOp);

            m_RenderStateBlock.mask |= RenderStateMask.Stencil;
            m_RenderStateBlock.stencilReference = reference;
            m_RenderStateBlock.stencilState = stencilState;
        }
        
        // TODO:
        // ISOLATE IN A UNSAFE DLL / DOCUMENT THAT THIS SHOULD BE MAKE PUBLIC
        static ShaderTagId[] s_ShaderTagValues = new ShaderTagId[1];
        static RenderStateBlock[] s_RenderStateBlocks = new RenderStateBlock[1];
        
        internal static void CreateRendererListWithRenderStateBlock(RenderGraph renderGraph, ref CullingResults cullResults, DrawingSettings ds, FilteringSettings fs, RenderStateBlock rsb, ref RendererListHandle rl)
        {
            s_ShaderTagValues[0] = ShaderTagId.none;
            s_RenderStateBlocks[0] = rsb;
            NativeArray<ShaderTagId> tagValues = new NativeArray<ShaderTagId>(s_ShaderTagValues, Allocator.Temp);
            NativeArray<RenderStateBlock> stateBlocks = new NativeArray<RenderStateBlock>(s_RenderStateBlocks, Allocator.Temp);
            var param = new RendererListParams(cullResults, ds, fs)
            {
                tagValues = tagValues,
                stateBlocks = stateBlocks,
                isPassTagName = false
            };
            rl = renderGraph.CreateRendererList(param);
        }

        RenderStateBlock m_RenderStateBlock;
        Mesh _skyboxMesh;
        Mesh SkyboxMesh => _skyboxMesh!=null?_skyboxMesh : CreateCubeMesh();

        /// <summary>
        /// The constructor for render objects pass.
        /// </summary>
        /// <param name="profilerTag">The profiler tag used with the pass.</param>
        /// <param name="renderPassEvent">Controls when the render pass executes.</param>
        /// <param name="shaderTags">List of shader tags to render with.</param>
        /// <param name="renderQueueType">The queue type for the objects to render.</param>
        /// <param name="layerMask">The layer mask to use for creating filtering settings that control what objects get rendered.</param>
        /// <param name="cameraSettings">The settings for custom cameras values.</param>
        public WaterReflectionRenderPass(string profilerTag, RenderPassEvent renderPassEvent, string[] shaderTags, MyRenderQueueType renderQueueType, int layerMask, WaterReflectionRenderFeature.CustomCameraSettings cameraSettings)            
        {
            profilingSampler = new ProfilingSampler(profilerTag);
            Init(renderPassEvent, shaderTags, renderQueueType, layerMask, cameraSettings);
        }

        internal void Init(RenderPassEvent renderPassEvent, string[] shaderTags, MyRenderQueueType renderQueueType, int layerMask, WaterReflectionRenderFeature.CustomCameraSettings cameraSettings)
        {
            m_PassData = new PassData();

            this.renderPassEvent = renderPassEvent;
            this.renderQueueType = renderQueueType;
            this.overrideMaterial = null;
            this.overrideMaterialPassIndex = 0;
            this.overrideShader = null;
            this.overrideShaderPassIndex = 0;
            RenderQueueRange renderQueueRange = (renderQueueType == MyRenderQueueType.Transparent)
                ? RenderQueueRange.transparent
                : RenderQueueRange.opaque;
            m_FilteringSettings = new FilteringSettings(renderQueueRange, layerMask);

            if (shaderTags != null && shaderTags.Length > 0)
            {
                foreach (var tag in shaderTags)
                    m_ShaderTagIdList.Add(new ShaderTagId(tag));
            }
            else
            {
                m_ShaderTagIdList.Add(new ShaderTagId("SRPDefaultUnlit"));
                m_ShaderTagIdList.Add(new ShaderTagId("UniversalForward"));
                m_ShaderTagIdList.Add(new ShaderTagId("UniversalForwardOnly"));
            }

            m_RenderStateBlock = new RenderStateBlock(RenderStateMask.Nothing);
            m_CameraSettings = cameraSettings;
        }

        static void ComputeReflectionMatrices(Camera camera, out Matrix4x4 viewMatrix, out Matrix4x4 projectionMatrix, out Vector3 cameraPosition)
        {
            Vector3 planeNormal = WaterReflection.Instance.waterPlane.transform.up;
            Vector3 planePos = WaterReflection.Instance.waterPlane.transform.position;

            Vector3 camPos = camera.transform.position;
            float distance = Vector3.Dot(planeNormal, camPos - planePos);
            Vector3 reflectedPos = camPos - 2f * distance * planeNormal;

            Vector3 camForward = camera.transform.forward;
            Vector3 camUp = camera.transform.up;
            Vector3 camRight = camera.transform.right;

            Vector3 reflectedForward = Vector3.Reflect(camForward, planeNormal);
            Vector3 reflectedUp = Vector3.Reflect(camUp, planeNormal);
            Vector3 reflectedRight = Vector3.Cross(reflectedUp, reflectedForward);

            Matrix4x4 reflectedMatrix = new Matrix4x4(reflectedRight, reflectedUp, -reflectedForward,
                new Vector4(reflectedPos.x, reflectedPos.y, reflectedPos.z, 1.0f));

            // Cameras look along their negative Z Axis. Build the viewmatrix accordingly
            viewMatrix = reflectedMatrix.inverse;
            
            // Compute the projection matrix using the same FOV, aspect and clip planes
            projectionMatrix = Matrix4x4.Perspective(camera.fieldOfView, camera.aspect, camera.nearClipPlane,
                camera.farClipPlane);

            // Clip plane to avoid artifacts above water
            Vector4 clipPlane = CameraSpacePlane(viewMatrix, planePos, planeNormal);
            projectionMatrix = CalculateObliqueMatrix(projectionMatrix, clipPlane);
            
            cameraPosition = reflectedPos;
        }

        static Matrix4x4 CalculateObliqueMatrix(Matrix4x4 projection, Vector4 clipPlane)
        {
            Matrix4x4 inversion = Matrix4x4.Inverse(projection.inverse);

            Vector4 cps = new Vector4((clipPlane.x > 0 ? 1 : 0) - (clipPlane.x < 0 ? 1 : 0),
                (clipPlane.y > 0 ? 1 : 0) - (clipPlane.y < 0 ? 1 : 0), 1.0f, 1.0f);
            Vector4 q = inversion.MultiplyVector(cps);
            Vector4 c = clipPlane * (2.0f / Vector4.Dot(clipPlane, q));

            projection[2] = c.x - projection[3];
            projection[6] = c.y - projection[7];
            projection[10] = c.z - projection[11];
            projection[14] = c.w - projection[15];
            return projection;
        }

        static Vector4 CameraSpacePlane(Matrix4x4 viewMatrix, Vector3 pos, Vector3 normal)
        {
            Vector3 offsetPos = pos + normal * -0.05f;
            Vector3 cpos = viewMatrix.MultiplyPoint(offsetPos);
            Vector3 cnormal = viewMatrix.MultiplyVector(normal).normalized;
            return new Vector4(cnormal.x, cnormal.y, cnormal.z, -Vector3.Dot(cpos, cnormal));
        }
        
        Mesh CreateCubeMesh()
        {
            Mesh mesh = new Mesh();
            mesh.vertices = new Vector3[]
            {
                // 8 corners of the cube
                new Vector3(-1, -1, -1),
                new Vector3( 1, -1, -1),
                new Vector3( 1,  1, -1),
                new Vector3(-1,  1, -1),
                new Vector3(-1, -1,  1),
                new Vector3( 1, -1,  1),
                new Vector3( 1,  1,  1),
                new Vector3(-1,  1,  1),
            };
            mesh.SetUVs(0,mesh.vertices);
            mesh.triangles = new int[]
            {
                // Each face, two triangles (12 triangles total)
                0, 2, 1, 0, 3, 2,
                1, 2, 6, 6, 5, 1,
                4, 5, 6, 6, 7, 4,
                2, 3, 6, 6, 3, 7,
                0, 7, 3, 0, 4, 7,
                0, 1, 5, 0, 5, 4
            };
            mesh.RecalculateNormals();
            return mesh;
        }

        private static void ExecutePass(PassData passData, RasterCommandBuffer cmd, RendererList rendererList)
        {
            bool previousRTFlipped = passData.cameraData.IsRenderTargetProjectionMatrixFlipped(passData.previousColorTexture);
            
            cmd.SetViewProjectionMatrices(passData.viewMatrix, passData.projMatrix);
            //RenderingUtils.SetViewAndProjectionMatrices(cmd, viewMatrix, GL.GetGPUProjectionMatrix(projectionMatrix, true), false);
            // if (passData.cameraSettings.overrideCamera)
            // {
            //     if (passData.cameraData.xr.enabled)
            //     {
            //         Debug.LogWarning("WaterReflection pass is configured to override camera matrices. While rendering in stereo camera matrices cannot be overridden.");
            //     }
            //     else
            //     {
            //         Matrix4x4 projectionMatrix = Matrix4x4.Perspective(passData.cameraSettings.cameraFieldOfView, cameraAspect,
            //             camera.nearClipPlane, camera.farClipPlane);
            //         projectionMatrix = GL.GetGPUProjectionMatrix(projectionMatrix, true);
            //
            //         Matrix4x4 viewMatrix = passData.cameraData.GetViewMatrix();
            //         Vector4 cameraTranslation = viewMatrix.GetColumn(3);
            //         viewMatrix.SetColumn(3, cameraTranslation + passData.cameraSettings.offset);
            //
            //         RenderingUtils.SetViewAndProjectionMatrices(cmd, viewMatrix, projectionMatrix, false);
            //     }
            // }

            cmd.DrawRendererList(rendererList);
            
            // Skybox need the mesh at the origin
            var skyboxViewMatrix = passData.viewMatrix;
            skyboxViewMatrix.SetColumn(3, new Vector4(0.0f, 0.0f, 0.0f, 1.0f));
            var skyboxProjMatrix = passData.originalProjMatrix;
            skyboxProjMatrix.SetRow(2, skyboxProjMatrix.GetRow(3));
            cmd.SetViewProjectionMatrices(skyboxViewMatrix, skyboxProjMatrix);
            
            // Draw skybox
            cmd.DrawMesh(passData.skyboxMesh, Matrix4x4.identity, RenderSettings.skybox);

            // if (passData.cameraSettings.overrideCamera && passData.cameraSettings.restoreCamera && !passData.cameraData.xr.enabled)
            // {
            //     RenderingUtils.SetViewAndProjectionMatrices(cmd, passData.cameraData.GetViewMatrix(), GL.GetGPUProjectionMatrix(passData.cameraData.GetProjectionMatrix(0), previousRTFlipped), false);
            // }
            //RenderingUtils.SetViewAndProjectionMatrices(cmd, passData.cameraData.GetViewMatrix(), GL.GetGPUProjectionMatrix(passData.cameraData.GetProjectionMatrix(0), previousRTFlipped), false);
            cmd.SetViewProjectionMatrices(passData.originalViewMatrix, passData.originalProjMatrix);
        }

        private class PassData
        {
            internal WaterReflectionRenderFeature.CustomCameraSettings cameraSettings;
            internal RenderPassEvent renderPassEvent;

            internal TextureHandle previousColorTexture;
            internal TextureHandle color;
            internal TextureHandle depth;
            internal RendererListHandle rendererListHdl;

            internal UniversalCameraData cameraData;

            // Required for code sharing purpose between RG and non-RG.
            internal RendererList rendererList;
            
            internal Matrix4x4 viewMatrix;
            internal Matrix4x4 projMatrix;
            internal Matrix4x4 originalViewMatrix;
            internal Matrix4x4 originalProjMatrix;
            
            internal Vector3 cameraPosition;
            
            internal Mesh skyboxMesh;
        }
        
        private void InitRendererLists(UniversalRenderingData renderingData, UniversalLightData lightData,
            ref PassData passData, ScriptableRenderContext context, RenderGraph renderGraph, bool useRenderGraph)
        {
            SortingCriteria sortingCriteria = (renderQueueType == MyRenderQueueType.Transparent)
                ? SortingCriteria.CommonTransparent
                : passData.cameraData.defaultOpaqueSortFlags;
            DrawingSettings drawingSettings = RenderingUtils.CreateDrawingSettings(m_ShaderTagIdList, renderingData,
                passData.cameraData, lightData, sortingCriteria);
            drawingSettings.overrideMaterial = overrideMaterial;
            drawingSettings.overrideMaterialPassIndex = overrideMaterialPassIndex;
            drawingSettings.overrideShader = overrideShader;
            drawingSettings.overrideShaderPassIndex = overrideShaderPassIndex;

            passData.cameraData.camera.TryGetCullingParameters(false, out var cullingParameters);
            //context.Cull(ref cullingParameters);
            if (useRenderGraph)
            {
                CreateRendererListWithRenderStateBlock(renderGraph, ref renderingData.cullResults, drawingSettings,
                    m_FilteringSettings, m_RenderStateBlock, ref passData.rendererListHdl);
            }
        }

        /// <inheritdoc />
        public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
        {
            UniversalCameraData cameraData = frameData.Get<UniversalCameraData>();
            UniversalRenderingData renderingData = frameData.Get<UniversalRenderingData>();
            UniversalLightData lightData = frameData.Get<UniversalLightData>();
            
            // Allocate render textures
            var colorDesc = new RenderTextureDescriptor(Screen.width, Screen.height, RenderTextureFormat.Default, 0);
            var depthDesc = new RenderTextureDescriptor(Screen.width, Screen.height, RenderTextureFormat.Depth, 24);

            // Allocate temporary RT in RenderGraph
            var RTcolor = UniversalRenderer.CreateRenderGraphTexture(renderGraph, colorDesc, "WaterReflection_COLOR", false);
            var RTdepth = UniversalRenderer.CreateRenderGraphTexture(renderGraph, depthDesc, "WaterReflection_DEPTH", true);
            var Rcurrent = frameData.Get<UniversalResourceData>().activeColorTexture;
            var RcurrentDepth = frameData.Get<UniversalResourceData>().activeDepthTexture;
            
            using (var builder = renderGraph.AddRasterRenderPass<PassData>(passName, out var passData, profilingSampler))
            {
                UniversalResourceData resourceData = frameData.Get<UniversalResourceData>();

                passData.cameraSettings = m_CameraSettings;
                passData.renderPassEvent = renderPassEvent;
                passData.cameraData = cameraData;
                passData.skyboxMesh = SkyboxMesh;
                
                // Create reflection view and proj matrices
                Camera camera = passData.cameraData.camera;
                ComputeReflectionMatrices(camera, out passData.viewMatrix, out passData.projMatrix, out passData.cameraPosition);
                passData.originalViewMatrix = camera.worldToCameraMatrix;
                passData.originalProjMatrix = camera.projectionMatrix;
                
                
                // Allocate temporary RT in RenderGraph
                passData.color = RTcolor;
                passData.depth = RTdepth;
                
                // Backup the handle for the current active one, as we will need it to properly restore the projection matrix
                passData.previousColorTexture = resourceData.activeColorTexture;
                builder.UseTexture(passData.previousColorTexture, AccessFlags.Read); // TODO: Remove Write if not debugging

                // Bind Color & Depth Render targets
                builder.SetRenderAttachment(passData.color, 0, AccessFlags.Write);
                builder.SetRenderAttachmentDepth(passData.depth, AccessFlags.Write);
                
                // Bind any other resources we might need
                TextureHandle mainShadowsTexture = resourceData.mainShadowsTexture;
                TextureHandle additionalShadowsTexture = resourceData.additionalShadowsTexture;

                if (mainShadowsTexture.IsValid())
                    builder.UseTexture(mainShadowsTexture, AccessFlags.Read);

                if (additionalShadowsTexture.IsValid())
                    builder.UseTexture(additionalShadowsTexture, AccessFlags.Read);

                TextureHandle[] dBufferHandles = resourceData.dBuffer;
                for (int i = 0; i < dBufferHandles.Length; ++i)
                {
                    TextureHandle dBuffer = dBufferHandles[i];
                    if (dBuffer.IsValid())
                        builder.UseTexture(dBuffer, AccessFlags.Read);
                }

                TextureHandle ssaoTexture = resourceData.ssaoTexture;
                if (ssaoTexture.IsValid())
                    builder.UseTexture(ssaoTexture, AccessFlags.Read);

                InitRendererLists(renderingData, lightData, ref passData, default(ScriptableRenderContext), renderGraph, true);
                builder.UseRendererList(passData.rendererListHdl);

                builder.AllowPassCulling(false);
                builder.AllowGlobalStateModification(true);
                
                // if (cameraData.xr.enabled)
                //     builder.EnableFoveatedRasterization(cameraData.xr.supportsFoveatedRendering && cameraData.xrUniversal.canFoveateIntermediatePasses);
                
                builder.SetRenderFunc((PassData data, RasterGraphContext rgContext) =>
                {
                    ExecutePass(data, rgContext.cmd, data.rendererListHdl);
                });
            }

            using (var builder =
                   renderGraph.AddRasterRenderPass<PassData>(passName, out var passData, profilingSampler))
            {
                builder.UseTexture(RTcolor);
                builder.SetRenderAttachment(Rcurrent, 0, AccessFlags.Write);
                builder.SetRenderAttachmentDepth(RcurrentDepth, AccessFlags.Write);
                
                builder.AllowPassCulling(false);
                builder.AllowGlobalStateModification(true);
                
                builder.SetRenderFunc((PassData data, RasterGraphContext rgContext) =>
                {
                    rgContext.cmd.SetGlobalTexture("_ReflectionTex", RTcolor);
                    var renderer = WaterReflection.Instance.waterPlane.GetComponent<Renderer>();
                    rgContext.cmd.DrawRenderer(renderer, renderer.sharedMaterial, 0, 0);
                });
            }

            // // Debug Blit
            // using (var builder =
            //        renderGraph.AddRasterRenderPass<PassData>(passName, out var passData, profilingSampler))
            // {
            //     builder.SetRenderAttachment(Rcurrent, 0, AccessFlags.Write);
            //     builder.UseTexture(RTcolor);
            //     builder.SetRenderFunc((PassData data, RasterGraphContext rgContext) =>
            //     {
            //         float debugWidth = 512;
            //         float scaleFactor = Screen.width / debugWidth;
            //         rgContext.cmd.EnableScissorRect(new Rect(0,0,debugWidth,debugWidth));
            //         Blitter.BlitTexture(rgContext.cmd, RTcolor, new Vector4(scaleFactor,scaleFactor,0,0), 0, true);
            //         rgContext.cmd.DisableScissorRect();
            //     });
            // }
        }
    }
}
