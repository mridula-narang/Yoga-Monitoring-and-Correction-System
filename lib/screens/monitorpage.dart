import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:core';
import 'package:collection/collection.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:yoga_monitor/screens/homepage.dart';
import 'package:flutter_tts/flutter_tts.dart';

class MonitorPage extends StatefulWidget {
  const MonitorPage({super.key});
  @override
  State<MonitorPage> createState() => _MonitorPageState();
}

class _MonitorPageState extends State<MonitorPage> {

  //Defining Variables
  late CameraController _controller;
  late List<CameraDescription> _cameras;
  late PoseDetector _poseDetector;
  late Size imagesize;
  late WebSocketChannel _channel;
  late DateTime starttime;
  late ChewieController _chewieController;
  late VideoPlayerController _videoPlayerController;
  FlutterTts flutterTts = FlutterTts();

  String asana="Vrikshasana";
  int no_steps=3;
  int current_steps=0;
  String step="";
  String step_instruction="";
  String displayphase='';
  String m_type='';
  String imageref='';
  List imagerefs=["assets/vs1i.jpg","assets/vs1f.jpg","assets/vs2f.jpg","assets/vs3f.jpg"];
  List videorefs=["assets/1.mp4","assets/2.mp4","assets/3.mp4"];
  List instructions=["stand straight,\nobserve mentor","rise your right leg,\nfollow mentor","join your hands","Rise your hands"];

  String recived_data="";
  int status=0;
  String comment="Server not Connected";
  List worngangles = [[]];
  int r_step=1;

  List<int> keyjoints=[11,12,13,14,15,16,23,24,25,26,27,28];
  Map kejointdat={};
  Map kejointdatseq={};
  bool _isAllset=false;

  @override
  void initState() {
    super.initState();
    initializeCamera_posedectector();
    // stepsequencedisplayer();
  }

  void stepsequencedisplayer() async{

    while(current_steps<no_steps) {
      setState(() {
        displayphase="text";
        step="Step${current_steps+1}";
        step_instruction=instructions[current_steps];
      });
      await delay(5);

      setState(() {
        displayphase="refimage";
        imageref=imagerefs[current_steps];
      });
      await delay(5);

      setState(() {
        displayphase="monitor";
      });
      m_type="pos";
      await _controller.initialize();
      await startposeprocessing();
      await delay(3);
      _isAllset=false;
      status=0;
      await delay(2);

      setState(() {
        displayphase="refvideo";
      });
      await playVideo(videorefs[current_steps]);
      await delay(2);

      setState(() {
        displayphase="monitor";
      });
      m_type="act";
      comment="observing";
      await _controller.initialize();
      await startposeprocessing();
      await delay(5);
      _isAllset=false;
      status=0;

      current_steps++;
    }
    setState(() {
      displayphase="text";
      step="Step${current_steps+1}";
      step_instruction=instructions[current_steps];
    });
    await delay(5);

    setState(() {
      displayphase="refimage";
      imageref=imagerefs[current_steps];
    });
    await delay(5);


    setState(() {
      displayphase="monitor";
    });
    m_type="pos";
    await _controller.initialize();
    await startposeprocessing();
    await delay(3);
    _isAllset=false;
    status=0;
    await delay(2);

    setState(() {
      displayphase="complete";
    });
  }

  Future<void> delay(int seconds) async {
    await Future.delayed(Duration(seconds: seconds));
  }

  Future<void> playVideo(String path) async {
    Completer<void> completer = Completer<void>();
    _videoPlayerController = VideoPlayerController.asset(
      path, // Replace with the path to your asset video
    );
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      aspectRatio:  3/5, // Adjust the aspect ratio as needed
      showControls: false,
      autoPlay: true,
      looping: false, // Set looping to false to stop after playing once

      // Other customization options can be added here
    );

    _videoPlayerController.addListener(() {
      if (_videoPlayerController.value.position ==
          _videoPlayerController.value.duration) {
        // Video has completed playing
        completer.complete();
      }
    });
    return completer.future;
  }

  //initializing resources
  Future<void> initializeCamera_posedectector() async {

    //initialize websockect and listener
    _channel = WebSocketChannel.connect(Uri.parse('ws://'
        '192.168.250.49:8000/ws/mesg/'));
    _channel.stream.listen((message) {
      print(message);
      r_step = jsonDecode(message)['message']["r_step"];
      if ((current_steps+1)==r_step) {
        if(m_type=="pos") {
          comment = jsonDecode(message)['message']["Comment"];
          worngangles=jsonDecode(message)['message']["Part"];
        }
        status = jsonDecode(message)['message']["Status"];

      }
      if(m_type=="act"){

        if(status==0){
          comment="Re Do!";
          starttime=DateTime.now();
          setState(() {
          });
          flutterTts.speak(comment);


          Future.delayed(Duration(seconds: 2), () {
            _controller.resumePreview();
            starttime=DateTime.now();
            comment="observing";
          });

        }
        else{
          _controller.resumePreview();
          starttime=DateTime.now();
          comment="observing";
        }
        // _controller.resumePreview();

      }
    });

    //initializing posedetector
    _poseDetector = PoseDetector(options: PoseDetectorOptions());

    //initializing camera controller
    _cameras = await availableCameras();
    _controller = CameraController(_cameras[1], ResolutionPreset.medium, imageFormatGroup: ImageFormatGroup.nv21);
    // await _controller.initialize();

    //calling posedetection function
    // startposeprocessing();

    //text to speech
    await flutterTts.setLanguage("en-IN"); // Change to your desired language
    await flutterTts.setSpeechRate(0.5); // Change speech rate (0.0 - 1.0)
    await flutterTts.setPitch(1.1); // Change speech pitch (0.0 - 2.0)

    stepsequencedisplayer();
  }

  Future<void> startposeprocessing() async{

    Completer<void> completer = Completer<void>();

    //local varialbles
    List<Pose> poses;
    InputImage inputImage;
    int counter=0;
    int lock=0; // to controll the ImageStream for memory conservation

    //Image Streaming from camera controller
    _controller.resumePreview();

    _controller.startImageStream((CameraImage image)async{
      step="Step${current_steps+1}";
      if(lock==0) {
        lock=1;
        //preparing input image for posedetection
        inputImage = InputImage.fromBytes(
          bytes: image.planes[0].bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: InputImageRotationValue.fromRawValue(270) ??
                InputImageRotation.rotation270deg,
            format: InputImageFormatValue.fromRawValue(image.format.raw) ??
                InputImageFormat.nv21,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );

        //detecting pose
        poses = await _poseDetector.processImage(inputImage);
        if(poses.isEmpty){
          lock=0;
          return;
        }

        int keyindex = 0;
        kejointdat = {};

        poses[0].landmarks.forEach((key, landmark) {
          kejointdat[keyindex] = [landmark.x, landmark.y];
          keyindex++;
        });

        imagesize = Size(image.width.toDouble(), image.height.toDouble());

        if (counter==0){
          starttime=DateTime.now();
          _isAllset = true;
          counter=1;
        };

        print("${status},${current_steps+1},${r_step}");
        if (status==1 && r_step==(current_steps+1)){
          print("hai1");
          setState(() {});
          await flutterTts.speak("Step Done!");
          poses.clear();
          // status=0;
          _controller.stopImageStream();
          _controller.pausePreview();
          completer.complete();
          return;
        }

        setState(() {});

        if(m_type=="act"){
          print("hai2");
          keyindex=0;
          poses[0].landmarks.forEach((key, landmark) {
            if (kejointdatseq[keyindex] == null) {
              kejointdatseq[keyindex] = [[landmark.x, landmark.y]];
            }
            else {
              kejointdatseq[keyindex].add([landmark.x, landmark.y]);
            }
            keyindex++;
          });

          // poses[0].landmarks.forEach((key, landmark) {
          //   kejointdatseq[keyindex] = [[landmark.x, landmark.y]];
          //   keyindex++;
          // });

          print((DateTime.now().difference(starttime).inSeconds)+1%11);

          // var datatosend= {"step":current_steps+1,"monitor":"action","keyjointdat":Map.from(kejointdatseq).toString(),};
          // _channel.sink.add(jsonEncode(datatosend));
          // kejointdatseq={};

          if((DateTime.now().difference(starttime).inSeconds+1)%11==0){
            var datatosend= {"step":current_steps+1,"monitor":"action","keyjointdat":Map.from(kejointdatseq).toString()};
            print(datatosend);
            starttime=DateTime.now();
            comment="validating";
            _channel.sink.add(jsonEncode(datatosend));
            kejointdatseq={};
            _controller.pausePreview();
          }
          if((DateTime.now().difference(starttime).inSeconds+1)%3==0){
            if (comment.isNotEmpty) {
              await flutterTts.speak(comment);
            }
          }
        }
        else{
          var kejointdatpos={};

          keyindex=0;
          poses[0].landmarks.forEach((key, landmark) {
            kejointdatpos[keyindex] = [[landmark.x, landmark.y]];
            keyindex++;
          });

          if((DateTime.now().difference(starttime).inSeconds+1)%3==0){
            if (comment.isNotEmpty) {
              await flutterTts.speak(comment);
            }
          }

          var datatosend= {"step":current_steps+1,"monitor":"posture","keyjointdat":Map.from(kejointdatpos).toString()};
          print(datatosend);
          _channel.sink.add(jsonEncode(datatosend));
        }

        poses.clear();
        lock=0;

      }
    });
    print("object1111");
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(asana.toString()),
      ),
      body: Center(
          child:displayphase==""?
          CircularProgressIndicator()

              : displayphase=="text"?
          Text("Asana:${asana}\nStep:${step}\nInstruction:${step_instruction}",
            textScaleFactor: 2,
            textAlign: TextAlign.center,
          )

              : displayphase=="refimage"?
          Stack(
              children:<Widget>[
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(3.14159), // Horizontal flip
                  child: Image.asset(imageref,
                    width: 300.0, // Set the desired width
                    height: 600.0,
                    fit:BoxFit.fitWidth,),
                ),
                Text("Monitoring will start in 5s",
                  textScaleFactor: 2,
                  textAlign: TextAlign.center,),
              ]
          )

              : displayphase=="refvideo"?
          Stack(
              children:<Widget>[
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(3.14159), // Horizontal flip
                  child: Chewie(
                    controller: _chewieController,
                  ),
                ),
                Text("Mentor video",
                  textScaleFactor: 2,
                  textAlign: TextAlign.center,),
              ]
          )
              : displayphase=="monitor"?
          !_isAllset ?
          CircularProgressIndicator()

              : ClipRect(
              child:Stack(
                  children: <Widget>[
                    CameraPreview(_controller),
                    Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(3.14159), // Horizontal flip
                      child: CustomPaint(
                        size: Size(392.7,523.6),
                        painter: PosePainter(
                          keyjointdata: kejointdat,
                          imageSize: imagesize,
                          worngangles: worngangles,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 5,
                      top: 2,
                      child: Text('Step: $step',
                        textScaleFactor: 2,
                        style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold,backgroundColor: Colors.white),
                      ),
                    ),
                    Positioned(
                      left: 270,
                      top: 5,
                      child: Text("Time: ${DateTime.now().difference(starttime).inSeconds.toString()}",
                        textScaleFactor: 1.5,
                        style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold,backgroundColor: Colors.white),),
                    ),
                    Positioned(
                        left: 5,
                        top: 40,
                        child: Text("Comment:",
                          textScaleFactor: 1.7,
                          style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold,backgroundColor: Colors.white),)
                    ),
                    Positioned(
                        left: 5,
                        top: 70,
                        child: Text(status==1?"Step Done":comment,
                          textScaleFactor: 2,
                          style: status==1?TextStyle(color: Colors.green,backgroundColor: Colors.white,fontWeight:FontWeight.bold):TextStyle(color: Colors.black,fontWeight: FontWeight.bold,backgroundColor: Colors.white),)
                    )

                  ]
              )
          )
              : displayphase=="complete"?
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Asana Completed:)",
                        textScaleFactor: 2,),
                      ElevatedButton(
                          onPressed:(){
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HomePage(),
                              ),
                            );
                          },

                          child: Text("Go to Homepage"))
                    ],
                  )
              : CircularProgressIndicator()

      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}


//custompainter for drawing keyjoint co-ordinates
class PosePainter extends CustomPainter {
  final Paint circlePaint;
  final Paint linePaint;
  final Map keyjointdata;
  final Size imageSize;
  List worngangles;
  final textPainter = TextPainter(textDirection: TextDirection.ltr);

  TextSpan createTextSpan(String text) {
    return TextSpan(
      text: text,
      style: const TextStyle(
        color: Color.fromRGBO(0, 128, 255, 1),
        fontSize: 10,

      ),
    );
  }


  final connections = [[0, 1], [0, 4], [1, 2], [2, 3], [3, 7], [4, 5], [5, 6], [6, 8], [9, 10],
    [11, 12], [11, 13], [11, 23], [12, 14], [12, 24], [13, 15], [14, 16], [15, 17], [15, 19],
    [15, 21], [16, 18], [16, 20], [16, 22], [17, 19], [18, 20], [23, 24], [23, 25], [24, 26],
    [25, 27], [26, 28], [27, 29], [27, 31], [28, 30], [28, 32], [29, 31], [30, 32]
  ];

  // final landmarkLabels=["nose","left eye (inner)","left eye","left eye (outer)","right eye (inner)","right eye",
  //   "right eye (outer)","left ear","right ear","mouth (left)","mouth (right)","left shoulder",
  //   "right shoulder","left elbow","right elbow","left wrist","right wrist","left pinky",
  //   "right pinky","left index","right index","left thumb","right thumb","left hip",
  //   "right hip","left knee","right knee","left ankle","right ankle","left heel","right heel",
  //   "left foot index","right foot index"];

  PosePainter({required this.keyjointdata, required this.imageSize,required this.worngangles})

      : circlePaint = Paint()
    ..color = const Color.fromRGBO(255, 255, 0, 1),
        linePaint = Paint()
          ..color = const Color.fromRGBO(0, 255, 0, 1)
          ..strokeWidth = 3.5;

  Paint linepaintred = Paint()
    ..color = Colors.red // Set the color to blue
    ..strokeWidth = 3.5;

  // PoseLandmark indexpart(int index){
  //   final landmarksByType = {};
  //   int count=0;
  //   pose.landmarks.forEach((_, part) {
  //     landmarksByType[count] = part;
  //     count++;
  //   });
  //   return landmarksByType[index];
  // }


  @override
  void paint(Canvas canvas, Size size) {

    if(keyjointdata == null || imageSize == null) {
      return;
    }

    // print(size);

    final double hRatio =
    imageSize.width == 0 ? 1 : size.width/ imageSize.width;
    final double vRatio =
    imageSize.height == 0 ? 1 : size.height / imageSize.height;

    // print("${size.width},${imageSize.width},${size.width/ imageSize.width}");
    // print("${size.height},${imageSize.height},${size.height/ imageSize.height}");

    offsetForPart(List part) =>
        Offset((part[0] * (hRatio+0.2)), (part[1] * (vRatio-0.3)));

    keyjointdata.forEach((index, part) {
      // Draw a circular indicator for the landmark.
      canvas.drawCircle(offsetForPart(part), 7, circlePaint);

      // Draw text index for the landmark.
      textPainter.text = createTextSpan(index.toString());
      textPainter.layout();
      textPainter.paint(canvas, offsetForPart(part));
    });

    // Draw connections between the landmarks.
    for (final connection in connections) {
      final point1 = offsetForPart(keyjointdata[connection[0]]);
      final point2 = offsetForPart(keyjointdata[connection[1]]);
      if(worngangles.any((worngangle) => ListEquality().equals(worngangle, connection))) {
        canvas.drawLine(point1, point2, linepaintred);
      }
      else{
        canvas.drawLine(point1, point2, linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

