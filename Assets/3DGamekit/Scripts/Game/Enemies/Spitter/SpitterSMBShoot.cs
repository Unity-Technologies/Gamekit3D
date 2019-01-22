using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Gamekit3D
{
    public class SpitterSMBShoot : SceneLinkedSMB<SpitterBehaviour>
    {
        protected Vector3 m_AttackPosition;

        public override void OnSLStateEnter(Animator animator, AnimatorStateInfo stateInfo, int layerIndex)
        {
            if(m_MonoBehaviour.target == null)
                return;

            m_MonoBehaviour.controller.SetFollowNavmeshAgent(false);

            m_MonoBehaviour.RememberTargetPosition();
            Vector3 toTarget = m_MonoBehaviour.target.transform.position - m_MonoBehaviour.transform.position;
            toTarget.y = 0;

            m_MonoBehaviour.transform.forward = toTarget.normalized;
            m_MonoBehaviour.controller.SetForward(m_MonoBehaviour.transform.forward);

            if (m_MonoBehaviour.attackAudio != null)
                m_MonoBehaviour.attackAudio.PlayRandomClip();
        }

        public override void OnSLStateNoTransitionUpdate(Animator animator, AnimatorStateInfo stateInfo, int layerIndex)
        {
            m_MonoBehaviour.FindTarget();
        }
    }
}