using System.Collections;
using UnityEngine;

namespace Gamekit3D
{
    [RequireComponent(typeof(AudioSource))]
    public class AmbientAudio : MonoBehaviour
    {
        public float minPitch = 0.99f;
        public float maxPitch = 1.01f;
        public float minVolume = 0.5f;
        public float maxVolume = 0.9f;
        public bool randomDelays = true;

        public AudioListener audioListener;

        AudioSource audioSource;

        WaitForSeconds[] delays;
        int delayIndex = 0;

        WaitForSeconds Delay => delays[delayIndex++ % delays.Length];

        IEnumerator Start()
        {
            audioSource = GetComponent<AudioSource>();
            if (audioSource.clip == null) yield break;
            if (audioListener == null) audioListener = GameObject.FindFirstObjectByType<AudioListener>();
            audioSource.loop = false;
            delays = new WaitForSeconds[7];
            for (var i = 0; i < delays.Length; i++)
                delays[i] = new WaitForSeconds(audioSource.clip.length * Random.Range(1, 3));
            var loopDelay = new WaitForSeconds(audioSource.clip.length);
            while (true)
            {
                if (randomDelays)
                    yield return Delay;
                else
                    yield return loopDelay;
                if (audioListener != null && (audioListener.transform.position - transform.position).magnitude >
                    audioSource.maxDistance)
                    continue;
                audioSource.pitch = Random.Range(minPitch, maxPitch);
                audioSource.volume = Random.Range(minVolume, maxVolume);
                audioSource.Play();
            }
        }
    }
}