//ParticleSetInspector.cs
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System;
using System.IO;

public class ParticleSetInspector_test : MaterialEditor
{
	const string keyUseUVScroll = "_USE_UVSCROLL";
	const string keyUseMask = "_USE_MASK";
	const string keyUsePMAP = "_USE_PMAP";
	const string keyUseAlphablack = "_USE_ALPFABLACK";
	const string keyUseSubtraction = "_USE_SUBTRACTION";
	const string keyUseMultiply = "_USE_MULTIPLY";
	const string keyUseAdd = "_USE_ADD";
	const string keyUseOpaque = "_USE_OPAQUE";
	const string keyUseAlpha = "_USE_ALPHA";

	/// <summary>
	/// ↓キーワード用に追加
	/// </summary>
	static readonly string pragma_multi_compile = "#pragma multi_compile";


	List<List<string>> mKeywordSets;


	static void skipSpaces(string s, ref int pos)
	{
		while (pos < s.Length && char.IsWhiteSpace(s[pos]))
		{
			pos++;
		}
	}

	public override void OnEnable()
	{
		base.OnEnable();
		Material targetMat = (Material)target;
		Shader shader = targetMat.shader;
		string path = AssetDatabase.GetAssetPath(shader.GetInstanceID());
        Debug.Log("Shader path: " + path);
		mKeywordSets = new List<List<string>>();

		using (FileStream fs = new FileStream(path, FileMode.Open))
		{
			using(StreamReader reader = new StreamReader(fs))
			{
				string line;
				while ((line = reader.ReadLine()) != null)
				{
					int pos = 0;
					skipSpaces(line, ref pos);

					if (pos >= line.Length || line[pos] != '#') continue; // empty line or not started with "#"
					if (line.IndexOf(pragma_multi_compile) != pos) continue; // not started with pragma_multi_compile

					pos += pragma_multi_compile.Length;
					skipSpaces(line, ref pos);

					List<string> keywords = new List<string>();

					while (pos < line.Length && (char.IsLetter(line, pos) || line[pos] == '_'))
					{
						int len = 1;

						while (pos + len < line.Length && (char.IsLetterOrDigit(line, pos + len) || line[pos + len] == '_'))
						{
							++len;
						}

						string keyword = line.Substring(pos, len);
						keywords.Add(keyword);

						pos += len;
						skipSpaces(line, ref pos);
					}

					if (keywords.Count > 0)
					{
						mKeywordSets.Add(keywords);
					}

				}
			}
		}


	}
	/// <summary>
	/// ↑キーワード用に追加
	/// </summary>




	public override void OnInspectorGUI()
	{
		if (!isVisible)
			return;

		//現在のマテリアルからキーワードを得る
		Material targetMat = target as Material;
		string[] oldKeyWords = targetMat.shaderKeywords;



		bool useUVScroll = false;
		bool useMask = false;

		foreach (var key in oldKeyWords)
		{
			if (key.Equals(keyUseUVScroll))
			{
				useUVScroll = true;
			}

			if (key.Equals(keyUseMask))
			{
				useMask = true;
			}
		}

		bool usePMAP = false;	
		bool useAlphablack = false;
		bool useSubtraction = false;
		bool useMultiply = false;
		bool useAdd = false;
		bool useOpaque = false;
		bool useAlpha = false;



		//GUIの変更をチェック開始
		EditorGUI.BeginChangeCheck();
		BlendMode SelectedMode = (BlendMode)EditorGUILayout.EnumPopup("ブレンドモード", (BlendMode)targetMat.GetFloat("_Mode"));

		//パラメータを描画
		DrawProperties("_MainTex");

		if (SelectedMode == BlendMode.PMAP) {
			usePMAP = true;
			DrawProperties ("_PMAP");
		} else {
			usePMAP = false;
		}

		if (SelectedMode == BlendMode.alphablack) {
			useAlphablack = true;
		} else {
			useAlphablack = false;
		}

		if (SelectedMode == BlendMode.Subtraction) {
			useSubtraction = true;
		} else {
			useSubtraction = false;
		}

		if (SelectedMode == BlendMode.Multiply) {
			useMultiply = true;
		} else {
			useMultiply = false;
		}

		if (SelectedMode == BlendMode.add) {
			useAdd = true;
		} else {
			useAdd = false;
		}

		if (SelectedMode == BlendMode.Opaque) {
			useOpaque = true;
		} else {
			useOpaque = false;
		}

		if (SelectedMode == BlendMode.alpha) {
			useAlpha = true;
		} else {
			useAlpha = false;
		}

		EditorGUILayout.BeginVertical("Box");
		DrawProperties("_ZTestMode");
		EditorGUILayout.EndVertical();

		EditorGUILayout.BeginVertical("Box");
		DrawProperties("_CullMode");
		EditorGUILayout.EndVertical();

		EditorGUILayout.BeginVertical("Box");
		useUVScroll = EditorGUILayout.Toggle("Use UVScroll", useUVScroll);
		if (useUVScroll)
		{
			DrawProperties("_UVScroll");
		}
		EditorGUILayout.EndVertical();

		EditorGUILayout.BeginVertical("Box");
		useMask = EditorGUILayout.Toggle("Use Distortion", useMask);
		if (useMask)
		{
			DrawProperties("_Mask");
		}
		EditorGUILayout.EndVertical();

		float RenderQueueMode = EditorGUILayout.FloatField("Render Queue", targetMat.GetFloat("_QueueMode"));

		//////
		/// ↓キーワード用に追加
		/// 
		EditorGUILayout.LabelField("Keywords:");
		List<string> newKeyWords = new List<string>(oldKeyWords);

		bool keywordsDirty = false;

		for (int i = 0; i < mKeywordSets.Count; ++i)
		{
			List<string> keywords = mKeywordSets[i];

			// _からはじまるものは表示しない
			if (keywords[0].StartsWith("_"))
			{
				continue;
			}

			int selection = -1;

			for (int j = 0; j < oldKeyWords.Length; ++j)
			{
				selection = keywords.IndexOf(oldKeyWords[j]);
				if (selection >= 0) break;
			}

			if (selection < 0) selection = 0;

			int newSelection = EditorGUILayout.Popup(selection, keywords.ToArray());

            string testString= "Old Keywords: ";
            foreach(string s in targetMat.shaderKeywords)
            {
                testString += s + ", ";
            }
            Debug.Log(testString);

			if (newSelection != selection)
			{
				newKeyWords.Remove(keywords[selection]); 
				if (newSelection > 0)
				{
					newKeyWords.Add(keywords[newSelection]);
				}
				keywordsDirty = true;
			}

		}

		//// ↑キーワード用に追加
		/// 




		//変更があったら反映させる
		if (EditorGUI.EndChangeCheck())
		{
			targetMat.SetFloat("_QueueMode", (float)RenderQueueMode);
			targetMat.renderQueue = (int)RenderQueueMode;
			targetMat.SetFloat("_Mode", (float)SelectedMode);
			SetupMaterialWithBlendMode(targetMat, SelectedMode);//BlendModeも保存

			//キーワードリスト作成
			//List<string> newKeyWords = new List<string>();


			if (useUVScroll)
			{
				newKeyWords.Add(keyUseUVScroll);
			}

			if (useMask)
			{
				newKeyWords.Add(keyUseMask);
			}

			if (usePMAP)
			{
				newKeyWords.Add(keyUsePMAP);
			}

			if (useAlphablack)
			{
				newKeyWords.Add(keyUseAlphablack);
			}

			if (useSubtraction)
			{
				newKeyWords.Add(keyUseSubtraction);
			}

			if (useMultiply)
			{
				newKeyWords.Add(keyUseMultiply);
			}

			if (useAdd)
			{
				newKeyWords.Add(keyUseAdd);
			}

			if (useOpaque)
			{
				newKeyWords.Add(keyUseOpaque);
			}

			if (useAlpha)
			{
				newKeyWords.Add(keyUseAlpha);
			}



			//新しいキーワードリストをマテリアルへ設定
			//これによって適切なバリアントのシェーダーが選択される

			///↓キーワード用にifで分岐　ここが間違っている可能性が大
			if (keywordsDirty) {
				targetMat.shaderKeywords = newKeyWords.ToArray ();
			} else {
				targetMat.shaderKeywords = newKeyWords.ToArray ();
			}

			EditorUtility.SetDirty(targetMat);

		}

	}

	void DrawProperties(string showParam)
	{
		Shader shader = ((Material)target).shader;
		for (int i = 0; i < ShaderUtil.GetPropertyCount(shader); i++)
		{
			string name = ShaderUtil.GetPropertyName(shader, i);
			if (name.Contains(showParam))
			{
				MaterialProperty prop = GetMaterialProperty(targets, i);
				ShaderProperty(prop, prop.displayName);
			}
		}
	}


	public enum BlendMode
	{
		Opaque,
		add,
		alphablack,
		PMAP,
		Subtraction,
		Multiply,
		alpha      

	}

	public static void SetupMaterialWithBlendMode(Material material, BlendMode blendMode)
	{
		switch (blendMode)
		{
		case BlendMode.Opaque:
			material.SetOverrideTag ("RenderType", "");
			material.SetInt ("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
			material.SetInt ("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
			break;

		case BlendMode.add:
			material.SetOverrideTag("RenderType", "Transparent");
			material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
			material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.One);
			break;

		case BlendMode.alphablack:
			material.SetOverrideTag("RenderType", "Transparent");
			material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
			material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
			break;

		case BlendMode.PMAP:
			material.SetOverrideTag("RenderType", "Transparent");
			material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
			material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
			break;

		case BlendMode.Subtraction:
			material.SetOverrideTag("RenderType", "Transparent");
			material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
			material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcColor);
			break;

		case BlendMode.Multiply:
			material.SetOverrideTag("RenderType", "Transparent");
			material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.DstColor);
			material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
			break;

		case BlendMode.alpha:
			material.SetOverrideTag("RenderType", "Transparent");
			material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
			material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
			break;

		}
	}

}