import cv2
import os

video_path = "scratch/tiktok_video.mp4"
out_dir = "scratch/frames"
os.makedirs(out_dir, exist_ok=True)

cap = cv2.VideoCapture(video_path)
fps = cap.get(cv2.CAP_PROP_FPS)
total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
duration = total_frames / fps if fps > 0 else 0

print(f"FPS: {fps}, Total Frames: {total_frames}, Duration: {duration:.2f}s")

# Extract frame every 2 seconds
interval = int(fps * 2) if fps > 0 else 30
frame_idx = 0
saved_count = 0

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break
    if frame_idx % interval == 0:
        sec = int(frame_idx / fps)
        out_file = os.path.join(out_dir, f"frame_{sec:03d}s.jpg")
        cv2.imwrite(out_file, frame)
        saved_count += 1
    frame_idx += 1

cap.release()
print(f"Saved {saved_count} frames to {out_dir}")
