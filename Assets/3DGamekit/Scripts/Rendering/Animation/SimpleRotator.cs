using System;
using UnityEngine;

public class SimpleRotator : MonoBehaviour
{
    [SerializeField] private float speed = 90;
    
    private Quaternion _initialRotation = Quaternion.identity;
    private float _currentAngle = 0;

    private void Awake()
    {
        _initialRotation = transform.rotation;
    }

    public void Update()
    {
        _currentAngle = Mathf.Repeat(_currentAngle + speed*Time.deltaTime, 360);
        this.transform.rotation =  Quaternion.AngleAxis(_currentAngle, Vector3.up) * _initialRotation;;
    }
}
