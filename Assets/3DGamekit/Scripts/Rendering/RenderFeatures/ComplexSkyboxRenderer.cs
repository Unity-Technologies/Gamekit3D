using System.Collections.Generic;
using UnityEngine;

public class ComplexSkyboxRenderer : MonoBehaviour
{
    // Internal types
    public class RenderInfo
    {
        public Renderer renderer;
        public Mesh mesh;
    }

    // Private fields
    private List<RenderInfo> cachedRenderers = new ();
    
    // Public API
    public List<RenderInfo> MeshesToRender => cachedRenderers;
    public Camera TargetCamera => targetCamera;
    public Vector3 ViewpointOrigin => viewpointOrigin.transform.position;

    // Serialized fields
    [SerializeField]private Transform[] layerRoots;
    [SerializeField]private Transform viewpointOrigin;
    [SerializeField]private Camera targetCamera;

    // Singleton
    public static ComplexSkyboxRenderer Instance = null;
    
    // Support for domain reload
    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.SubsystemRegistration)]
    private static void ResetSingleton()
    {
        Instance = null;
    }

    // Initialize singleton & collect renderers
    public void Awake()
    {
        Debug.Assert(Instance == null, "There should only be one instance of ComplexSkyboxRenderer");
        Instance = this;
        CollectRenderers();
    }

    // Build the cache of all renderers needed for the skybox layers
    private void CollectRenderers()
    {
        cachedRenderers.Clear();
        
        foreach (var layerRoot in layerRoots)
        {
            // Collect all renderers in the hierarchy
            MeshRenderer[] allRenderers = layerRoot.GetComponentsInChildren<MeshRenderer>(false);

            foreach (var currentRenderer in allRenderers)
            {
                if (!currentRenderer.enabled)
                    continue;

                var meshFilter = currentRenderer.GetComponent<MeshFilter>();
                if (meshFilter == null || meshFilter.sharedMesh == null)
                    continue;

                cachedRenderers.Add(new RenderInfo { renderer = currentRenderer, mesh = meshFilter.sharedMesh });
            }
        }
    }
}