using UnityEngine;

[ExecuteAlways]
public class WaterReflection : MonoBehaviour
{
    public GameObject waterPlane;

    [Header("Reflection Texture")]
    public int textureSize = 512;
    public static WaterReflection Instance { get; private set; }

    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.SubsystemRegistration)]
    private static void ResetSingleton()
    {
        Instance = null;
    }

    void OnEnable()
    {
        Instance = this;
    }

    void OnDisable()
    {
        Instance = null;
        Instance = null;
    }

    
}