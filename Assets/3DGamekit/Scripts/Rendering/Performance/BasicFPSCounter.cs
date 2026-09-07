using UnityEngine;

namespace ProductionValidation.Graphics
{
    /// <summary>
    /// Very basic FPS counter using unscaled delta time as an input
    /// </summary>
    public class BasicFPSCounter : MonoBehaviour
    {
        private GUIStyle m_GUIStyle;
        private const float Width = 150;
        private float m_SmoothedDeltaTime;
        private bool m_IsActive;
        
        void Awake()
        {
            m_GUIStyle = new GUIStyle { fontSize = 24, normal = { textColor = Color.white } };
        }

        void Update()
        {
            // F1 toggles the fps on & off
            if (Input.GetKeyDown(KeyCode.F1))
                m_IsActive ^= true;
            
            m_SmoothedDeltaTime += (Time.unscaledDeltaTime - m_SmoothedDeltaTime) * 0.1f;
        }

        void OnGUI()
        {
            if (!m_IsActive)
                return;
            
            // Calculate and display FPS
            float fps = 1.0f / m_SmoothedDeltaTime;
            string fpsText = $"FPS: {fps:F1}";
            GUI.Label(new Rect(Screen.width-Width, 10, Width, 50), fpsText, m_GUIStyle);
        }
    }
}