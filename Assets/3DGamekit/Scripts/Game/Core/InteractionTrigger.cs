using UnityEngine;
using UnityEngine.Events;

namespace Gamekit3D
{
    [RequireComponent(typeof(SphereCollider))]
    public class InteractionTrigger : MonoBehaviour
    {
        public LayerMask layers;
        public UnityEvent OnEnter, OnExit;

        void Reset()
        {
            layers = LayerMask.NameToLayer("Everything");
            var colliderComponent = GetComponent<SphereCollider>();
            colliderComponent.radius = 5;
            colliderComponent.isTrigger = true;
        }

        void OnTriggerEnter(Collider other)
        {
            if (0 != (layers.value & 1 << other.gameObject.layer))
            {
                OnEnter.Invoke();
            }
        }

        void OnTriggerExit(Collider other)
        {
            if (0 != (layers.value & 1 << other.gameObject.layer))
            {
                OnExit.Invoke();
            }
        }

        void OnDrawGizmos()
        {
            Gizmos.DrawIcon(transform.position, "InteractionTrigger", false);
        }

        void OnDrawGizmosSelected()
        {
            //need to inspect events and draw arrows to relevant gameObjects.
        }
    } 
}
