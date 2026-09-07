using System;
using Unity.Cinemachine;
using UnityEngine;

namespace Gamekit3D
{
    public class CameraSettings : MonoBehaviour
    {
        public enum InputChoice
        {
            KeyboardAndMouse, Controller,
        }

        [Serializable]
        public struct InvertSettings
        {
            public bool invertX;
            public bool invertY;
        }

        public Transform follow;
        public Transform lookAt;
        public CinemachineVirtualCameraBase keyboardAndMouseCamera;
        public CinemachineVirtualCameraBase controllerCamera;
        public InputChoice inputChoice;
        public InvertSettings keyboardAndMouseInvertSettings;
        public InvertSettings controllerInvertSettings;
        public bool allowRuntimeCameraSettingsChanges;
        
        private CinemachineOrbitalFollow m_KeyboardOrbitalFollow;
        private CinemachineOrbitalFollow m_ControllerOrbitalFollow;

        public CinemachineVirtualCameraBase Current => inputChoice == InputChoice.KeyboardAndMouse ? keyboardAndMouseCamera : controllerCamera;

        public CinemachineOrbitalFollow CurrentOrbitalFollow => inputChoice == InputChoice.KeyboardAndMouse ? m_KeyboardOrbitalFollow : m_ControllerOrbitalFollow;

        void Reset()
        {
            Transform keyboardAndMouseCameraTransform = transform.Find("KeyboardAndMouseFreeLookRig");
            if (keyboardAndMouseCameraTransform != null)
                keyboardAndMouseCamera = keyboardAndMouseCameraTransform.GetComponent<CinemachineVirtualCameraBase>();

            Transform controllerCameraTransform = transform.Find("ControllerFreeLookRig");
            if (controllerCameraTransform != null)
                controllerCamera = controllerCameraTransform.GetComponent<CinemachineVirtualCameraBase>();

            PlayerController playerController = FindFirstObjectByType<PlayerController>();
            if (playerController != null && playerController.name == "Ellen")
            {
                follow = playerController.transform;

                lookAt = follow.Find("HeadTarget");

                if (playerController.cameraSettings == null)
                    playerController.cameraSettings = this;
            }
        }

        void Awake()
        {
            m_KeyboardOrbitalFollow = keyboardAndMouseCamera.GetComponent<CinemachineOrbitalFollow>();
            m_ControllerOrbitalFollow = controllerCamera.GetComponent<CinemachineOrbitalFollow>();
            
            UpdateCameraSettings();
        }

        void Update()
        {
            if (allowRuntimeCameraSettingsChanges)
            {
                UpdateCameraSettings();
            }
        }

        /// <summary>
        /// This is used to patch the legacy input gain inside the axis controllers of
        /// the CinemachineInputAxisController component.
        /// This can be updated when the whole system gets updated to using the new Input System
        /// </summary>
        void UpdateAxisConfig(CinemachineInputAxisController axisController, bool invertX, bool invertY)
        {
            foreach (var controller in axisController.Controllers)
            {
                if (controller.Input.LegacyInput == "CameraX")
                    controller.Input.LegacyGain = Mathf.Abs(controller.Input.LegacyGain) * (invertX?-1:1);
                if (controller.Input.LegacyInput == "CameraY")
                    controller.Input.LegacyGain = Mathf.Abs(controller.Input.LegacyGain) * (invertY?-1:1);
            }
        }

        void UpdateCameraSettings()
        {
            keyboardAndMouseCamera.Follow = follow;
            keyboardAndMouseCamera.LookAt = lookAt;
            var kbmInputAxisController = keyboardAndMouseCamera.GetComponent<CinemachineInputAxisController>();
            if (kbmInputAxisController != null)
            {
                UpdateAxisConfig(kbmInputAxisController, keyboardAndMouseInvertSettings.invertX, keyboardAndMouseInvertSettings.invertY);
            }

            var ctrlInputAxisController = controllerCamera.GetComponent<CinemachineInputAxisController>();
            if (ctrlInputAxisController != null)
            {
                UpdateAxisConfig(ctrlInputAxisController, controllerInvertSettings.invertX, controllerInvertSettings.invertY);
            }
            
            controllerCamera.Follow = follow;
            controllerCamera.LookAt = lookAt;

            keyboardAndMouseCamera.Priority = inputChoice == InputChoice.KeyboardAndMouse ? 1 : 0;
            controllerCamera.Priority = inputChoice == InputChoice.Controller ? 1 : 0;
        }
    } 
}
