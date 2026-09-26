// ==============================================================================
// AppleStore Prime - Reconstructed & Enhanced Source Code (Unity InjectFix C#)
// Module: ESP & In-Game UI Overlay
// Compatible with: Free Fire v0.86.x / ThreeOneOSFive Project
// ==============================================================================

using System;
using System.Collections.Generic;
using UnityEngine;
using COW.GamePlay;

namespace AppleStorePrime.Mod
{
    public class AppleStoreESP
    {
        // ======================================================================
        // CẤU HÌNH MÀU SẮC NAME TAG & LINE
        // ======================================================================
        // Màu Name tag khi nhìn thấy trực diện (Vàng Neon nổi bật)
        public static Color NameTagVisibleColor = new Color(1.0f, 1.0f, 0.0f, 1.0f);

        // Màu Name tag khi bị che khuất sau vật cản (Đỏ cảnh báo)
        public static Color NameTagHiddenColor  = new Color(1.0f, 0.3f, 0.3f, 0.85f);

        // Màu viền chữ Name tag để đọc rõ trên mọi địa hình
        public static Color NameTagOutlineColor = new Color(0.0f, 0.0f, 0.0f, 0.9f);

        // Màu tia Line (Top Tracer)
        public static Color TracerLineColor     = new Color(1.0f, 0.85f, 0.0f, 0.95f);

        // Màu hiển thị chữ Player và số line ở đỉnh màn hình
        public static Color HeaderCountColor    = new Color(1.0f, 0.9f, 0.1f, 1.0f);

        // ======================================================================
        // TRẠNG THÁI TÍNH NĂNG
        // ======================================================================
        public static bool EnableESP       = true;
        public static bool DrawPlayerName  = true;
        public static bool DrawTopTracer   = true;
        public static bool DrawDistance    = true;
        public static bool DrawHealthBar   = true;

        private static GUIStyle nameTagStyle;
        private static GUIStyle headerLabelStyle;
        private static Texture2D whiteTexture;

        public static void InitStyles()
        {
            if (headerLabelStyle == null)
            {
                headerLabelStyle = new GUIStyle(GUI.skin.label);
                headerLabelStyle.alignment = TextAnchor.UpperCenter;
                headerLabelStyle.fontSize = 15;
                headerLabelStyle.fontStyle = FontStyle.Bold;
            }

            if (nameTagStyle == null)
            {
                nameTagStyle = new GUIStyle(GUI.skin.label);
                nameTagStyle.alignment = TextAnchor.MiddleCenter;
                nameTagStyle.fontSize = 12;
                nameTagStyle.fontStyle = FontStyle.Bold;
            }

            if (whiteTexture == null)
            {
                whiteTexture = Texture2D.whiteTexture;
            }
        }

        /// <summary>
        /// Hook chính vào OnGUI của game để vẽ giao diện ESP
        /// </summary>
        public static void OnGUI_Hook()
        {
            if (!EnableESP) return;

            Camera mainCam = Camera.main;
            if (mainCam == null) return;

            InitStyles();

            Vector2 screenCenterTop = new Vector2(Screen.width * 0.5f, 0f);
            int activeLineCount = 0;

            // Lấy danh sách Player trong trận đấu
            List<Player> playerList = COW.GameFacade.CurrentMatch?.GetPlayerList();
            if (playerList == null) return;

            foreach (Player player in playerList)
            {
                if (player == null || player.IsLocalPlayer() || !player.gameObject.activeInHierarchy)
                    continue;

                // Tọa độ đầu của Player trong thế giới 3D
                Transform headTf = player.GetHeadTF();
                if (headTf == null) continue;

                Vector3 headWorldPos = headTf.position;
                Vector3 screenPos = mainCam.WorldToScreenPoint(headWorldPos);

                // Chỉ vẽ khi mục tiêu nằm trong tầm nhìn phía trước camera
                if (screenPos.z <= 0f) continue;

                // Quy đổi sang tọa độ Unity GUI (trục Y hướng xuống)
                Vector2 targetScreen = new Vector2(screenPos.x, Screen.height - screenPos.y);

                // --- 1. TÍNH NĂNG TOP TRACER (LINE) & ĐẾM SỐ LINE ĐANG HIỆN ---
                if (DrawTopTracer)
                {
                    activeLineCount++;
                    DrawLine(screenCenterTop, targetScreen, TracerLineColor, 1.5f);
                }

                // --- 2. TÍNH NĂNG NAME TAG (ĐỔI MÀU SẮC ĐỘNG) ---
                if (DrawPlayerName)
                {
                    string playerName = player.get_NickName();
                    if (!string.IsNullOrEmpty(playerName))
                    {
                        bool isVisible = player.IsVisible();
                        Color targetColor = isVisible ? NameTagVisibleColor : NameTagHiddenColor;

                        // Vẽ viền bóng đen tạo độ tương phản cao
                        GUI.color = NameTagOutlineColor;
                        Rect textRect = new Rect(targetScreen.x - 75f, targetScreen.y - 25f, 150f, 20f);
                        GUI.Label(new Rect(textRect.x + 1f, textRect.y + 1f, textRect.width, textRect.height), playerName, nameTagStyle);

                        // Vẽ chữ Name tag với màu tùy biến
                        GUI.color = targetColor;
                        GUI.Label(textRect, playerName, nameTagStyle);
                    }
                }
            }

            // --- 3. HIỂN THỊ CHỮ 'PLAYER' VÀ SỐ LƯỢNG LINE Ở ĐỈNH MÀN HÌNH ---
            if (DrawTopTracer)
            {
                string headerText = string.Format("Player: {0}", activeLineCount);
                Rect headerRect = new Rect(screenCenterTop.x - 75f, 5f, 150f, 25f);

                // Vẽ bóng chữ cho nhãn đỉnh
                GUI.color = Color.black;
                GUI.Label(new Rect(headerRect.x + 1f, headerRect.y + 1f, headerRect.width, headerRect.height), headerText, headerLabelStyle);

                // Vẽ chữ Player kèm số lượng Line (màu vàng rực)
                GUI.color = HeaderCountColor;
                GUI.Label(headerRect, headerText, headerLabelStyle);
            }
        }

        /// <summary>
        /// Hàm vẽ đường thẳng Line bằng Texture2D và Ma trận xoay GUI
        /// </summary>
        private static void DrawLine(Vector2 pointA, Vector2 pointB, Color color, float width)
        {
            Color prevColor = GUI.color;
            Matrix4x4 prevMatrix = GUI.matrix;

            GUI.color = color;
            float angle = Vector2.Angle(pointB - pointA, Vector2.right);
            if (pointA.y > pointB.y) angle = -angle;

            GUIUtility.ScaleAroundPivot(new Vector2((pointB - pointA).magnitude, width), new Vector2(pointA.x, pointA.y + 0.5f));
            GUIUtility.RotateAroundPivot(angle, pointA);
            GUI.DrawTexture(new Rect(pointA.x, pointA.y, 1f, 1f), whiteTexture);

            GUI.matrix = prevMatrix;
            GUI.color = prevColor;
        }
    }
}
