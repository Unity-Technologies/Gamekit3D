using UnityEngine;

namespace Gamekit3D.GameCommands
{
    public class SimpleTranslator : SimpleTransformer
    {
        public Rigidbody rigidbodyComponent;
        public Vector3 start = -Vector3.forward;
        public Vector3 end = Vector3.forward;

        public override void PerformTransform(float position)
        {
            var curvePosition = accelCurve.Evaluate(position);
            var pos = transform.TransformPoint(Vector3.Lerp(start, end, curvePosition));
            Vector3 deltaPosition = pos - rigidbodyComponent.position;
            if (Application.isEditor && !Application.isPlaying)
                rigidbodyComponent.transform.position = pos;
            rigidbodyComponent.MovePosition(pos);

            if (m_Platform != null)
                m_Platform.MoveCharacterController(deltaPosition);
        }
    }
}
