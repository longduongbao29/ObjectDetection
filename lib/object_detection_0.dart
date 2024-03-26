import 'dart:io';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:visual_impaired_assistance/init.dart' as init;
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:isolate';
import 'package:tflite_v2/tflite_v2.dart';

const int targetWidth = 240;
const int targetHeight = 320;
const int delayFrame = 20;
const input_shape = [1,720,480,3];

class ObjectDetection {
  String modelpath = "assets/yolov2_tiny.tflite";
  String labelpath = "assets/yolov2_tiny.txt";
  late dynamic model;
  late dynamic isolateInterpreter;
  var labels = [];
  int delay = 0;
  late List input;
  var ouput;
  Future<dynamic> _read() async {
    var text = [];
    try {
      final Directory directory = await getApplicationDocumentsDirectory();
      final File file = File('${directory.path}/assets/ssd_mobilenet.txt');
      text = await file.readAsLines();
    } catch (e) {
      print("Couldn't read file $e");
    }
    return text;
  }

  _write(String text) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    String path = '${directory.path}/my_file.txt';
    final File file = File(path);
    await file.writeAsString(text);
     print("file saved successfully at $path");
  }

  Future<void> loadModel() async {
    model = await tfl.Interpreter.fromAsset(modelpath);
    var inputDetails = model.getInputTensor(0);
    var outputDetails = model.getOutputTensor(0);

    // Print input details
    print("Input details:");
    print(inputDetails);

    // Print output details
    print("\nOutput details:");
    print(outputDetails);
    isolateInterpreter =
        await tfl.IsolateInterpreter.create(address: model.address);
    labels = await _read();
    print(labels.length);
  }

  Future<void> startDetection() async {
    var cameraController = init.getCameraController();

    cameraController.startImageStream((CameraImage image) {
      if (delay == delayFrame) {
        detect(image);
        delay = 0;
      } else {
        delay++;
      }
    });
  }

  Future<void> detect(CameraImage image) async {
    ReceivePort receivePort = ReceivePort();
    Isolate isolate = await Isolate.spawn(convertYUV420toRGB, {
      'image': image,
      'sendPort': receivePort.sendPort,
    });
    receivePort.listen((message) {
      input = message.map((dynamic item) => int.parse(item.toString())).toList();
      input = input.reshape(input_shape);
      print((input.shape));
      // Đóng Isolate sau khi nhận kết quả.
      isolate.kill();
      receivePort.close();
    });

    print("Width ${image.width} Height ${image.height}");




    // var output = List.filled(1 * 100, 0).reshape([1, 100]);
    // var output = [0];
    // await isolateInterpreter.run(image, output);
    // var pred = output[0];
    // int maxValue = pred.reduce(
    //     (currentMax, element) => currentMax > element ? currentMax : element);

    // // Tìm chỉ số của giá trị lớn nhất
    // int maxIndex = pred.indexOf(maxValue);

    // print(output);
  }


  static void convertYUV420toRGB(Map<String, dynamic> message)  {
      SendPort sendPort = message['sendPort'];
      var image = message['image'];
      final int width = image.width;
      final int height = image.height;
      final int uvRowStride = image.planes[1].bytesPerRow;
      final int? uvPixelStride = image.planes[1].bytesPerPixel;
      // imgLib -> Image package from https://pub.dartlang.org/packages/image
      List<int> rgbData = [];
      // Fill image buffer with plane[0] from YUV420_888
      for (int x = 0; x < width; x++) {
        for (int y = 0; y < height; y++) {
          final int uvIndex = uvPixelStride! * (x / 2).floor() + uvRowStride * (y / 2).floor();
          final int index = y * width + x;

          final yp = image.planes[0].bytes[index];
          final up = image.planes[1].bytes[uvIndex];
          final vp = image.planes[2].bytes[uvIndex];
          // Calculate pixel color
          int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
          int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91).round().clamp(0, 255);
          int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
          // color: 0x FF  FF  FF  FF
          //           A   B   G   R
          rgbData.add(r);
          rgbData.add(g);
          rgbData.add(b);
        }
      }

      sendPort.send(rgbData);

  }
}
