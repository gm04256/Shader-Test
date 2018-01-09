using UnityEngine;
using System.Collections;

public class MeshGenerator : MonoBehaviour
{
    public Texture texture;

    void Start()
    {
        gameObject.AddComponent<MeshFilter>();
        MeshRenderer meshRenderer = gameObject.AddComponent<MeshRenderer>();
        Mesh mesh = GetComponent<MeshFilter>().mesh;

        mesh.Clear();

        // make changes to the Mesh by creating arrays which contain the new values
        mesh.vertices = new Vector3[] { new Vector3(0, 0, 0), new Vector3(1, 0, 0), new Vector3(1, 1, 0), new Vector3(0, 1, 0) };
        mesh.uv = new Vector2[] { new Vector2(0, 0), new Vector2(1, 0), new Vector2(1, 1), new Vector2(0, 1) };
        mesh.triangles = new int[] { 0, 2, 1, 0, 3, 2};

        // set material to mesh renderer
        Material material = new Material(Shader.Find("Transparent/Diffuse"));
        material.mainTexture = texture;

        meshRenderer.material = material;
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
