import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final AssetEntity assetInFocus;

  late final VideoPlayerController _controller;

  /// Whether the controller has initialized.
  bool hasLoaded = false;

  /// Whether there's any error when initialize the video controller.
  bool hasErrorWhenInitializing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    PermissionState state = await PhotoManager.requestPermissionExtend();

    if (PermissionState.authorized == state) {
      List<AssetPathEntity> assetPaths = await PhotoManager.getAssetPathList(
        type: RequestType.video,
      );

      AssetPathEntity recent =
          assetPaths.firstWhere((e) => (e.name == 'Recents'));

      List<AssetEntity> assets = await recent.getAssetListPaged(0, 100);

      if (assets.isNotEmpty) {
        assetInFocus = assets.first;
        initializeVideoPlayerController();
      }
    }
  }

  // Get media url from the asset, then initialize the controller.
  Future<void> initializeVideoPlayerController() async {
    final String? url = await assetInFocus.getMediaUrl();
    if (url == null) {
      hasErrorWhenInitializing = true;
      if (mounted) {
        setState(() {});
      }
      return;
    }

    _controller = VideoPlayerController.network(
      Uri.parse(url).toString(),
    );

    await _controller.initialize().then((_) {
      // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
      hasLoaded = true;
    }).onError((error, stackTrace) {
      hasErrorWhenInitializing = true;
    }).whenComplete(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!hasLoaded) return Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _controller.value.isPlaying
                ? _controller.pause()
                : _controller.play();
          });
        },
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
      body: Center(
        child: FutureBuilder(
          future: assetInFocus.getMediaUrl(),
          builder: (BuildContext context, AsyncSnapshot s) {
            if (!s.hasData)
              return Center(
                child: CircularProgressIndicator(),
              );

            if (s.data == null)
              return Center(
                child: Text('ooops'),
              );

            return Center(
              child: _controller.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : Container(),
            );
          },
        ),
      ),
    );
  }
}
