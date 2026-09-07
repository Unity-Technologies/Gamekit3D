using UnityEngine;

namespace Gamekit3D
{
    [RequireComponent(typeof(Collider))]
    public class DeathVolume : MonoBehaviour
    {
        public AudioSource audioSource;

        void OnTriggerEnter(Collider other)
        {
            var pc = other.GetComponent<PlayerController>();
            if (pc != null)
            {
                pc.Die(new Damageable.DamageMessage());
            }
            if (audioSource != null)
            {
                audioSource.transform.position = other.transform.position;
                if (!audioSource.isPlaying)
                    audioSource.Play();
            }
        }

        void Reset()
        {
            if (LayerMask.LayerToName(gameObject.layer) == "Default")
                gameObject.layer = LayerMask.NameToLayer("Environment");
            var c = GetComponent<Collider>();
            if (c != null)
                c.isTrigger = true;
        }
    }
}
