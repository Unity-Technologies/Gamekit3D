using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.Audio;

namespace Gamekit3D
{
    [RequireComponent(typeof(Slider))]
    public class MixerSliderLink : MonoBehaviour
    {
        public AudioMixer mixer;
        public string mixerParameter;
        
        protected Slider m_Slider;
        
        void Awake ()
        {
            m_Slider = GetComponent<Slider>();

            float value;
            mixer.GetFloat(mixerParameter, out value);

            m_Slider.value = AudioDBHelper.DecibelsToLinear(value);

            m_Slider.onValueChanged.AddListener(SliderValueChange);
        }


        void SliderValueChange(float value)
        {
            mixer.SetFloat(mixerParameter, AudioDBHelper.LinearToDecibels(value));
        }
    }
}