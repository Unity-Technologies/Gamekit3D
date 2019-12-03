using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Gamekit3D
{
    [ExecuteInEditMode]
    [RequireComponent(typeof(Terrain))]
    public class BlendedTerrain : MonoBehaviour
    {
        [Range(0.0f, 0.004f)]
        public float uvCorrection;
        public Texture2D heightMap;
        public Texture2D alphaMap;
        public Texture2D normalMap;
        public TerrainData td;

        [ContextMenu("Recalc")]
        void Start()
        {
            var terrain = GetComponent<Terrain>();
            td = terrain.terrainData;
            BuildHeightMap();
            BuildAlphaMap();
            Shader.SetGlobalTexture("_TerrainHeight", heightMap);
            Shader.SetGlobalTexture("_TerrainAlpha", alphaMap);
            Shader.SetGlobalTexture("_TerrainNormal", normalMap);
            for (var i = 0; i < Mathf.Min(4, td.splatPrototypes.Length); i++)
            {
                Shader.SetGlobalTexture(string.Format("_TerrainSplat{0}", i), td.splatPrototypes[i].texture);
                Shader.SetGlobalVector(string.Format("_TerrainSplat{0}Scale", i), td.splatPrototypes[i].tileSize);
            }
        }

        private void BuildHeightMap()
        {
            var height = td.heightmapResolution - 1;
            var width = td.heightmapResolution - 1;
            heightMap = new Texture2D(width, height, TextureFormat.RFloat, true);
            normalMap = new Texture2D(width, height, TextureFormat.RGBA32, true);
            var heightPixels = new Color[height * width];
            var normalPixels = new Color[height * width];
            var index = 0;
            for (var y = 0; y < height; y++)
            {
                for (var x = 0; x < width; x++)
                {
                    var h = td.GetHeight(x, y);
                    heightPixels[index] = new Color(h / td.size.y, 0, 0, 0);
                    var n = td.GetInterpolatedNormal(1f * x / width, 1f * y / height);

                    var t = new Vector3(n.x, n.y, n.z);
                    t += Vector3.one;
                    t *= 0.5f;
                    normalPixels[index] = new Color(t.x, t.y, t.z, 1);
                    index++;
                }
            }
            normalMap.SetPixels(normalPixels);
            heightMap.SetPixels(heightPixels);
            normalMap.Apply();
            heightMap.Apply();
        }



        void BuildAlphaMap()
        {
            int index;
            alphaMap = new Texture2D(td.alphamapWidth, td.alphamapHeight, TextureFormat.RGBA32, true);
            var alphaPixels = new Color[td.alphamapWidth * td.alphamapHeight];
            var alphaMaps = td.GetAlphamaps(0, 0, td.alphamapWidth, td.alphamapHeight);
            index = 0;
            for (var y = 0; y < td.alphamapHeight; y++)
            {
                for (var x = 0; x < td.alphamapWidth; x++)
                {
                    var c = Color.black;
                    for (var i = 0; i < Mathf.Min(4, td.splatPrototypes.Length); i++)
                    {
                        c[i] = alphaMaps[y, x, i];
                    }
                    alphaPixels[index] = c;
                    index++;
                }
            }

            alphaMap.SetPixels(alphaPixels);
            alphaMap.Apply();
        }

        void Update()
        {
            Shader.SetGlobalVector("_TerrainPosition", transform.position);
            Shader.SetGlobalVector("_TerrainSize", td.size);
            Shader.SetGlobalVector("_TerrainScale", td.heightmapScale);
            Shader.SetGlobalVector("_TerrainUVCorrection", Vector2.one * uvCorrection);
        }


    }

}