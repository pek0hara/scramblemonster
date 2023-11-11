import 'package:flutter/material.dart';
import 'resultHelper.dart';
import 'totalScoreHelper.dart';
import 'actionPointsHelper.dart';
import 'monster.dart';
import 'search.dart';
import 'combine.dart';

void main() => runApp(MyApp());

// 画面の状態を表すenum
enum ScreenState { home, game, result }

List<Monster> ownMonsters = [];
List<Monster?> combineMonsters = [null, null];
List<Monster> searchedMonsters = [];

Text infoMessage = Text('');
int maxMagicPower = 0;
int actionPoints = 0;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'スクランブルモンスター',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: WillPopScope(
        onWillPop: () async {
          // ここでfalseを返すことで、戻る動作をキャンセルします。
          return false;
        },
        child: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // 現在の画面の状態を保持するフィールド
  ScreenState _screenState = ScreenState.game;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData().then((loadedMonsters) {
      setState(() {
        if (loadedMonsters.isNotEmpty) {
          ownMonsters = loadedMonsters;
        } else {
          _resetGame();
        }
        // ロード終わったよ
        isLoading = false;
      });
    });
  }

  Future<void> _resetGame() async {
    var score = await TotalScoreHelper.getScore();

    if (score != 0) {
      int maxMagicPower = ownMonsters
          .map((monster) => monster.lv)
          .reduce((a, b) => a > b ? a : b);
      Map<String, dynamic> result = {
        'party': ownMonsters.map((monster) => monster.toJson()).toList(),
        'score': score,
        'maxMagicPower': maxMagicPower,
      };
      ResultHelper.saveResult(result);
      ResultHelper.saveHighScore(result);
    }

    await TotalScoreHelper.setScore(0);
    await ActionPointsHelper.setActionPoints(1000);
    ownMonsters = [Monster(no: 0, magic: 10, will: 10, intel: 10, lv: 5)];
    combineMonsters = [null, null];
    searchedMonsters = [];
    infoMessage = Text('');

    await saveData(ownMonsters);

    setState(() {});
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('リセット確認'),
          content: Text('ゲームをリセットして次のゲームを行いますか？'),
          actions: <Widget>[
            TextButton(
              child: Text('キャンセル'),
              onPressed: () {
                Navigator.of(context).pop(); // ダイアログを閉じる
              },
            ),
            TextButton(
              child: Text('リセット'),
              onPressed: () async {
                await _resetGame(); // 行動力をリセットする関数
                Navigator.of(context).pop(); // ダイアログを閉じる
                // 必要に応じてUIを更新
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  void _showGameDescription(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('ゲームの説明'),
          content: Text('・モンスターの発見と合体を繰り返して強いモンスターを作るゲームです。\n'
              '・気力が高いモンスターを持っていると、たくさんモンスターを発見できます。\n'
              '・魅力が高いモンスターを持っていると、魅力が高いモンスターを発見できます。\n'
              '・知力が高いモンスターを持っていると、魔力が高いモンスターを発見できます。\n'
              '・魔力はモンスターの総合的な強さです。'),
          actions: [
            TextButton(
              child: Text('閉じる'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()), // ローディングインジケータを表示
      );
    }

    // ゲーム画面
    return Scaffold(
      appBar: AppBar(
        title: Text('スクランブルモンスター'),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu), // ハンバーガーメニューのアイコン
              onPressed: () {
                Scaffold.of(context).openDrawer(); // ドロワーを開く
              },
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () {
              _showGameDescription(context);
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Text('メニュー'),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            ListTile(
              title: Text('リザルト画面'),
              onTap: () {
                setState(() {
                  _screenState = ScreenState.result;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('ゲームに戻る'),
              onTap: () {
                setState(() {
                  _screenState = ScreenState.game;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('ゲームをリセット'),
              onTap: () {
                Navigator.pop(context);
                _showResetConfirmation();
              },
            ),
          ],
        ),
      ),
      body: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        if (_screenState == ScreenState.game) ...[
          // ゲーム画面
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // スコアを表示するFutureBuilder
              FutureBuilder<int>(
                future: TotalScoreHelper.getScore(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text('スコア: ${snapshot.data}');
                  } else {
                    return Text('スコア: 0');
                  }
                },
              ),
              // 行動力を表示するFutureBuilder
              FutureBuilder<int>(
                future: ActionPointsHelper.getActionPoints(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text('行動力: ${snapshot.data}');
                  } else {
                    return Text('行動力: 0');
                  }
                },
              ),
            ],
          ),
          // 合体のUI
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              buildCombineMonsterSlot(0), // 選択されたモンスターのスロット1
              Icon(Icons.add), // `+` アイコンを表示
              buildCombineMonsterSlot(1), // 選択されたモンスターのスロット2
              // 合体後のモンスターを表示
              if (combineMonsters[0] != null && combineMonsters[1] != null) ...[
                Icon(Icons.arrow_forward), // `→` アイコンを表示
                buildNewCombinedMonsterWidget(combineMonsters[0]!, combineMonsters[1]!), // 合体後のモンスターを表示
              ],
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: combineMonsters[0] != null || combineMonsters[1] != null
                    ? () {
                  // キャンセルボタンが押された時の処理
                  setState(() {
                    combineMonsters = [null, null];
                  });
                }
                    : null, // combineMonstersが両方nullの場合はボタンを非アクティブにする
                child: Text('キャンセル'),
              ),
              FutureBuilder<int>(
                future: ActionPointsHelper.getActionPoints(),
                builder: (context, snapshot) {
                  Text combineButtonText = Text('合体 (-10)'); // デフォルトのテキスト

                  if (snapshot.hasData) {
                    if (0 < snapshot.data! && snapshot.data! < 10) {
                      combineButtonText = Text('合体 (-${snapshot.data})');
                    }
                  }

                  return ElevatedButton(
                    onPressed: (snapshot.hasData && snapshot.data! > 0 &&
                        (combineMonsters[0] != null && combineMonsters[1] != null))
                        ? () async {
                      // 合体ボタンが押された時の処理
                      bool result = await combine();
                      if (!result) {
                        infoMessage = Text('行動力がなくなりました', style: TextStyle(color: Colors.red));
                      }
                      setState(() {});
                    }
                        : null, // ボタンを非アクティブ状態にする
                    child: combineButtonText,
                  );
                },
              ),
            ],
          ),
          // 所持モンスター
          buildLine(ownMonsters),

          // 画面メッセージ
          infoMessage,

          // 捜索のUI
          buildLine(searchedMonsters),

          FutureBuilder<int>(
            future: ActionPointsHelper.getActionPoints(),
            builder: (context, snapshot) {
              Text searchButtonText = Text('捜索 (-1)');
              bool isSearchButtonActive = true;
              List<Widget> buttons = [];

              if (snapshot.hasData) {
                if (snapshot.data! < 1) {
                  isSearchButtonActive = false;
                  buttons.add(
                    ElevatedButton(
                      onPressed: _resetGame,
                      child: Text('リトライ', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                  );
                }
              }

              buttons.insert(
                0,
                ElevatedButton(
                  onPressed: isSearchButtonActive
                      ? () async {
                    int cost = 1;
                      bool result = await search(cost);
                      if (!result) {
                        infoMessage = Text('行動力がなくなりました',
                            style: TextStyle(color: Colors.red));
                      }
                      setState(() {});
                  }
                      : null, // ボタンを非アクティブ状態にする
                  child: searchButtonText,
                ),
              );

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: buttons,
              );
            },
          )

        ] else if (_screenState == ScreenState.result) ...[
          // リザルト画面
          Text('上位の結果'),
          Expanded(
            child: FutureBuilder<List>(
              future: ResultHelper.getHighScores(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      List<Monster> partyMonsters =
                          (snapshot.data![index]['party'] as List)
                              .map((json) => Monster.fromJson(json))
                              .toList();
                      return ListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: partyMonsters
                              .map((monster) => MonsterWidget(monster: monster))
                              .toList(),
                        ),
                        subtitle: Text(
                            '最高Lv. ${snapshot.data![index]['maxMagicPower']} '
                            'スコア: ${snapshot.data![index]['score']} '),
                      );
                    },
                  );
                } else {
                  return CircularProgressIndicator();
                }
              },
            ),
          ),
          Text('直近の結果'),
          Expanded(
            child: FutureBuilder<List>(
              future: ResultHelper.getResults(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      List<Monster> partyMonsters =
                          (snapshot.data![index]['party'] as List)
                              .map((json) => Monster.fromJson(json))
                              .toList();
                      return ListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: partyMonsters
                              .map((monster) => MonsterWidget(monster: monster))
                              .toList(),
                        ),
                        subtitle: Text(
                            '最高Lv. ${snapshot.data![index]['maxMagicPower']} '
                            'スコア: ${snapshot.data![index]['score']} '),
                      );
                    },
                  );
                } else {
                  return CircularProgressIndicator();
                }
              },
            ),
          )
        ]
      ]),
      // bottomNavigationBar: bottomNavBar,
    );
  }

  Widget buildCombineMonsterSlot(int index) {
    return DragTarget<Monster>(
      onAccept: (selectedMonster) {
        setState(() {
          if (!combineMonsters.contains(selectedMonster)) {
            combineMonsters[index] = selectedMonster;
          }
        });
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: 105,
          height: 142,
          child: combineMonsters[index] == null
              ? Placeholder() // モンスターが選択されていない場合、プレースホルダーを表示
              : MonsterWidget(monster: combineMonsters[index]!),
        );
      },
    );
  }

// 成長率に基づいて色とフォントウェイトを決定する関数
  Map<String, dynamic> determineStyle(int growthRate) {
    Color color;
    FontWeight fontWeight;

    if (growthRate == 80) {
      color = Colors.redAccent;
      fontWeight = FontWeight.bold; // 成長率が80の場合は太字
    } else if (growthRate == 70) {
      color = Colors.orangeAccent;
      fontWeight = FontWeight.normal;
    } else {
      color = Colors.black;
      fontWeight = FontWeight.normal;
    }

    return {
      'color': color,
      'fontWeight': fontWeight,
    };
  }

  Widget buildNewCombinedMonsterWidget(Monster monster1, Monster monster2) {
    // 各属性の成長率を計算する
    int growM = calculateGrowth(monster1.magic, monster2.magic);
    int growW = calculateGrowth(monster1.will, monster2.will);
    int growI = calculateGrowth(monster1.intel, monster2.intel);

    // 合体後のモンスターを生成
    Monster combinedMonster = newCombinedMonster(monster1, monster2);

    // 各属性のスタイルを決定する
    Map<String, dynamic> magicStyle = determineStyle(growM);
    Map<String, dynamic> willStyle = determineStyle(growW);
    Map<String, dynamic> intelStyle = determineStyle(growI);

    // MonsterWidgetを生成する
    return Container(
      width: 115,
      height: 142,
      child: MonsterWidget(
        monster: combinedMonster,
        magicColor: magicStyle['color'],
        willColor: willStyle['color'],
        intelColor: intelStyle['color'],
        backColor: Colors.black, // 背景色は黒に固定
        borderColor: Colors.black, // 枠線色は黒に固定
        fontWeight: FontWeight.normal, // デフォルトのフォントウェイト
        magicFontWeight: magicStyle['fontWeight'],
        willFontWeight: willStyle['fontWeight'],
        intelFontWeight: intelStyle['fontWeight'],
      ),
    );
  }


  Widget buildLine(List<Monster> lineMonsters) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: lineMonsters.map((monster) => buildOwnMonsterBox(monster)).toList(),
    );
  }

  Future<void> _swapMonster(
      Monster draggedMonster, Monster targetMonster) async {
    int draggedIndexMonsters = ownMonsters.indexOf(draggedMonster);
    int targetIndexMonsters = ownMonsters.indexOf(targetMonster);
    int draggedIndexSearched = searchedMonsters.indexOf(draggedMonster);
    int targetIndexSearched = searchedMonsters.indexOf(targetMonster);

    setState(() {
      if (draggedIndexMonsters != -1 && targetIndexMonsters != -1) {
        final temp = ownMonsters[draggedIndexMonsters];
        ownMonsters[draggedIndexMonsters] = ownMonsters[targetIndexMonsters];
        ownMonsters[targetIndexMonsters] = temp;
      } else if (draggedIndexSearched != -1 && targetIndexSearched != -1) {
        final temp = searchedMonsters[draggedIndexSearched];
        searchedMonsters[draggedIndexSearched] =
            searchedMonsters[targetIndexSearched];
        searchedMonsters[targetIndexSearched] = temp;
      } else if (draggedIndexMonsters != -1 && targetIndexSearched != -1) {
        ownMonsters[draggedIndexMonsters] = searchedMonsters[targetIndexSearched];
        searchedMonsters[targetIndexSearched] = draggedMonster;
      } else if (draggedIndexSearched != -1 && targetIndexMonsters != -1) {
        searchedMonsters[draggedIndexSearched] = ownMonsters[targetIndexMonsters];
        ownMonsters[targetIndexMonsters] = draggedMonster;
      }

      if (draggedMonster == targetMonster) {
        if (searchedMonsters.contains(draggedMonster) &&
            ownMonsters.length < 5){
          searchedMonsters.remove(draggedMonster);
          ownMonsters.add(draggedMonster);

          infoMessage = Text('モンスターを仲間に加えた！');
          return;
        }

        if (combineMonsters[1] == draggedMonster) {
          combineMonsters[0] = draggedMonster;
          combineMonsters[1] = null;
        } else if (!combineMonsters.contains(draggedMonster)) {
          if (combineMonsters[0] == null) {
            combineMonsters[0] = draggedMonster;
          } else {
            combineMonsters[1] = draggedMonster;
          }
        }
      }
    });
    await saveData(ownMonsters);
  }
}

Widget buildOwnMonsterBox(Monster monster) {
  // モンスターが存在する場合、通常のアイコンを表示
  return Draggable<Monster>(
    data: monster,
    child: OwnMonsterBox(monster: monster),
    feedback: Material(
      type: MaterialType.transparency,
      child: OwnMonsterBox(monster: monster),
    ),
    childWhenDragging: OwnMonsterBox(monster: monster),
    onDragCompleted: () {},
  );
}

class OwnMonsterBox extends StatelessWidget {
  final Monster monster;
  final bool isDragging;

  OwnMonsterBox({required this.monster, this.isDragging = false});

  @override
  Widget build(BuildContext context) {
    return DragTarget<Monster>(
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: 60,
          height: 142,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MonsterWidget(monster: monster),
            ],
          ),
        );
      },
      onWillAccept: (data) => true,
      onAccept: (data) {
        final _MyHomePageState state =
            context.findAncestorStateOfType<_MyHomePageState>()!;
        state._swapMonster(data, monster);
      },
    );
  }
}

class MonsterWidget extends StatelessWidget {
  final Monster monster;
  final Color magicColor;
  final Color willColor;
  final Color intelColor;
  final Color backColor;
  final Color borderColor;
  final FontWeight fontWeight;
  final FontWeight magicFontWeight;
  final FontWeight willFontWeight;
  final FontWeight intelFontWeight;

  MonsterWidget({
    required this.monster,
    this.magicColor = Colors.black,
    this.willColor = Colors.black,
    this.intelColor = Colors.black,
    this.backColor = Colors.black,
    this.borderColor = Colors.black,
    this.fontWeight = FontWeight.normal,
    this.magicFontWeight = FontWeight.normal,
    this.willFontWeight = FontWeight.normal,
    this.intelFontWeight = FontWeight.normal,
  });

  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            // 背景用の黒いContainer
            Container(
              width: 60,
              height: 60,
              color: Colors.black, // 背景を黒に設定
            ),
            // アイコン用のImage.asset
            Positioned.fill(
              child: Image.asset('assets/images/${monster.no}.png', fit: BoxFit.cover),
            ),
            // 縁取り用のContainer
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: this.borderColor, width: 3.0), // 縁取りの色を設定
                ),
              ),
            ),
          ],
        ),
        Text(
          'Lv.${monster.lv}',
          style: TextStyle(
            color: Colors.black,
            fontWeight: this.fontWeight,
          ),
        ),
        Text(
          '魔力:${monster.magic}',
          style: TextStyle(
            color: this.magicColor,
            fontWeight: this.magicFontWeight,
          ),
        ),
        Text(
          '精神:${monster.will}',
          style: TextStyle(
            color: this.willColor,
            fontWeight: this.willFontWeight,
          ),
        ),
        Text(
          '知力:${monster.intel}',
          style: TextStyle(
            color: this.intelColor,
            fontWeight: this.intelFontWeight,
          ),
        ),
      ],
    );
  }
}
