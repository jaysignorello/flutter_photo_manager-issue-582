import 'package:chewie/chewie.dart';
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
  AssetEntity? assetInFocus;

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

      if (assets.isNotEmpty) assetInFocus = assets.first;

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            assetInFocus == null
                ? Center(
                    child: Text('nothing to load...'),
                  )
                : FutureBuilder(
                    future: assetInFocus?.getMediaUrl(),
                    builder: (BuildContext context, AsyncSnapshot s) {
                      if (!s.hasData)
                        return Center(
                          child: CircularProgressIndicator(),
                        );

                      if (s.data == null)
                        return Center(
                          child: Text('ooops'),
                        );

                      VideoPlayerController controller =
                          VideoPlayerController.network(s.data);
                      ChewieController chewieController = ChewieController(
                        videoPlayerController: controller,
                        autoInitialize: true,
                      );

                      Size size = MediaQuery.of(context).size;
                      double ratio = assetInFocus!.size.aspectRatio;
                      double h = size.height - 100;

                      return SizedBox(
                        width: h * ratio,
                        height: h,
                        child: Chewie(controller: chewieController),
                      );
                    },
                  )
          ],
        ),
      ),
    );
  }
}
