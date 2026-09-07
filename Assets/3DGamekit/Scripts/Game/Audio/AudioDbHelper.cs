using UnityEngine;

namespace Gamekit3D
{
    public static class AudioDBHelper
    {
        /// <summary>
        /// This takes as an input Decibels, and convert into a linear value to be used for gameplay, UI, etc...
        /// (dB scale is not linear, perceptually speaking, which can make volume sliders, or gameplay smoothing
        /// exponentially increasing/decreasing, instead of linearly increasing/decreasing)
        /// </summary>
        /// <param name="volumeInDecibels">Volume in dB, coming from the Audio API</param>
        /// <returns>Linear volume, corrected for human perception</returns>
        public static float DecibelsToLinear(float volumeInDecibels)
        {
            // -80 dB is silence, 0 dB is full volume
            return Mathf.Pow(10f, volumeInDecibels / 20f);
        }

        /// <summary>
        /// Reverse function of DecibelsToLinear, takes a linear volume and turns it into dB, ensuring
        /// the volume is perceptually linear for the ear 
        /// </summary>
        /// <param name="linearVolume">The linear volume</param>
        /// <returns>The volue in dB, to be used in the Audio API</returns>
        public static float LinearToDecibels(float linearVolume)
        {
            // perc: 0 (silent) to 1 (full volume)
            return Mathf.Log10(Mathf.Max(linearVolume, 0.0001f)) * 20f;
        }
    }
}