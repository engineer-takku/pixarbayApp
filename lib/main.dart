import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: PixabayPage(),
    );
  }
}

class PixabayPage extends StatefulWidget {
  const PixabayPage({super.key});

  @override
  State<PixabayPage> createState() => _PixabayPageState();
}

class _PixabayPageState extends State<PixabayPage> {
  List<PixabayImage> pixabayImages = [];

  //WebAPIを利用して画像を取得する
  Future<void> fetchImages(String text) async {
    final response = await Dio().get(
      'https://pixabay.com/api/',
      queryParameters: {
        'key': '38018990-5ca1e5e75d2f1d150099d2043',
        'q': text,
        'image_type': 'photo',
        'per_page': 100,
      },
    );
    final List hitts = response.data['hits'];

    pixabayImages = hitts.map(
      (e) {
        return PixabayImage.fromMap(e);
      },
    ).toList();
    setState(() {});
  }

  //画像をシェアする
  Future<void> shareImage(String url) async {
    //１、URLから画像をダウンロード
    final response = await Dio().get(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    //２、ダウンロードしたデータをファイルに保存
    final dir = await getTemporaryDirectory();
    final file =
        await File(dir.path + '/image.png').writeAsBytes(response.data);

    //３、shareパッケージを呼び出して共有
    Share.shareFiles([file.path]);
  }

  @override
  void initState() {
    super.initState();
    //最初に一度だけ呼ばれる。
    fetchImages('花');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextFormField(
          initialValue: '花',
          decoration: const InputDecoration(
            fillColor: Colors.white,
            filled: true,
          ),
          onFieldSubmitted: (text) {
            fetchImages(text);
          },
        ),
      ),
      body: GridView.builder(
        gridDelegate:
            SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
        itemCount: pixabayImages.length,
        itemBuilder: (context, index) {
          final pixabayImage = pixabayImages[index];
          return InkWell(
            onTap: () async {
              shareImage(pixabayImage.webformatURL);
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  pixabayImage.previewURL,
                  fit: BoxFit.cover,
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    color: Colors.white,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.thumb_up_alt_outlined,
                          size: 14,
                        ),
                        Text('${pixabayImage.likes}'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class PixabayImage {
  final String webformatURL;
  final String previewURL;
  final int likes;

  PixabayImage({
    required this.webformatURL,
    required this.previewURL,
    required this.likes,
  });

  factory PixabayImage.fromMap(Map<String, dynamic> map) {
    return PixabayImage(
      webformatURL: map['webformatURL'],
      previewURL: map['previewURL'],
      likes: map['likes'],
    );
  }
}
