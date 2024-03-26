import 'package:camera/camera.dart';
import 'package:visual_impaired_assistance/camera.dart';
import 'package:visual_impaired_assistance/object_detection.dart';

late List<CameraDescription> _cameras;
late CameraController controller;
const CameraApp cameraApp = CameraApp();
final ObjectDetection detector = ObjectDetection();

Future<void> init() async {
  print("Initializing");
  _cameras = await availableCameras();
  print("Initialized");
}

List<CameraDescription> getCameras() {
  return _cameras;
}

CameraController getCameraController() {
  return controller;
}

ObjectDetection getdetector() {
  return detector;
}
