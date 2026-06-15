════════════════════════════════════════════════════════════════
  [PLACEHOLDER] نماذج الذكاء الاصطناعي المطلوبة
════════════════════════════════════════════════════════════════

ضع الملفات التالية في هذا المجلد قبل البناء:

1. whisper_tiny.tflite  (~75 MB)
   المصدر: https://huggingface.co/openai/whisper-tiny
   الأداة: python -c "import whisper; whisper.load_model('tiny')"
   ثم تحويله: pip install onnx tf2onnx && (اتبع التعليمات)
   أو جاهز: https://github.com/usefulsensors/tiny_whisper

2. selfie_segmentation.tflite  (~1 MB)
   المصدر الرسمي من MediaPipe:
   https://storage.googleapis.com/mediapipe-models/image_segmenter/selfie_segmenter/float16/1/selfie_segmenter.tflite

3. selfie_segmentation_landscape.tflite (اختياري للمقاطع الأفقية)
   https://storage.googleapis.com/mediapipe-models/image_segmenter/selfie_segmenter_landscape/float16/1/selfie_segmenter_landscape.tflite

════════════════════════════════════════════════════════════════
  بعد وضع الملفات شغّل:  flutter pub get && flutter run
════════════════════════════════════════════════════════════════
