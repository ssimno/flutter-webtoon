import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webtoon/models/webtoon_detail_model.dart';
import 'package:webtoon/services/api_service.dart';
import 'package:webview_flutter/webview_flutter.dart';

class DetailScreen extends StatefulWidget {
  final String id, titleThumb, title;
  const DetailScreen({
    super.key,
    required this.id,
    required this.titleThumb,
    required this.title,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final likeKey = "likedToons";
  late final Future<WebtoonDetailModel> webtoonDetailModel;
  late final Future<List<WebtoonEpisodeModel>> webtoonEpisodeModel;

  bool isLiked = false;

  late SharedPreferences prefs;

  void saveLiked() {
    final likedToons = prefs.getStringList(likeKey);
    likedToons?.remove(widget.id);
    if (isLiked) likedToons?.add(widget.id);

    prefs.setStringList(likeKey, likedToons ?? []);
  }

  Future initPrefs() async {
    prefs = await SharedPreferences.getInstance();

    final likedToons = prefs.getStringList(likeKey);
    if (likedToons == null) {
      await prefs.setStringList(likeKey, []);
    } else {
      isLiked = likedToons.contains(widget.id);
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    webtoonDetailModel = ApiService.getDetailToons(widget.id);
    webtoonEpisodeModel = ApiService.getWebtoonEpisodesById(widget.id);

    initPrefs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                isLiked = !isLiked;
              });
              saveLiked();
            },
            icon: Icon(isLiked
                ? Icons.favorite_rounded
                : Icons.favorite_outline_outlined),
          )
        ],
        elevation: 3,
        backgroundColor: Colors.white,
        foregroundColor: Colors.green,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 50,
            vertical: 30,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Hero(
                    tag: widget.id,
                    child: Container(
                      width: 250,
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 12,
                              offset: const Offset(10, 10),
                              color: Colors.black.withOpacity(0.5),
                            )
                          ]),
                      child: Image.network(
                        widget.titleThumb,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 25,
              ),
              FutureBuilder(
                future: Future.wait([webtoonDetailModel, webtoonEpisodeModel]),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    var detailInfo = snapshot.data![0] as WebtoonDetailModel;
                    var episodes =
                        snapshot.data![1] as List<WebtoonEpisodeModel>;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detailInfo.about,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        Text(
                          '${detailInfo.genre} / ${detailInfo.age}',
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Column(
                          children: [
                            for (var episode in episodes)
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => WebView(
                                          initialUrl:
                                              'https://comic.naver.com/webtoon/detail?titleId=${widget.id}&no=${episode.id}',
                                          javascriptMode:
                                              JavascriptMode.unrestricted,
                                        ),
                                      ));
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Colors.green.shade400,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          episode.title,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                          ],
                        )
                      ],
                    );
                  }
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
