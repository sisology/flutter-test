import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wisely_diary/edit_diary_screens.dart';
import 'cartoon_inquery.dart';
import 'package:wisely_diary/letter/letter_inquiry_page.dart';
import 'package:wisely_diary/music/music_inquiry_page.dart';

class DiaryNoImgPage extends StatefulWidget {
  final DateTime selectedDate;

  const DiaryNoImgPage({
    Key? key,
    required this.selectedDate,
  }) : super(key: key);

  @override
  _DiaryNoImgPageState createState() => _DiaryNoImgPageState();
}

class _DiaryNoImgPageState extends State<DiaryNoImgPage> {
  String? diaryContent;
  List<String> imageUrls = [];
  bool isLoading = true;
  int? diaryCode;
  String? memberId;
  OverlayEntry? _overlayEntry;
  bool _isOverlayVisible = false;

  // 추가: 각 기능의 활성화 상태를 저장할 변수
  bool isMusicActive = false;
  bool isCartoonActive = false;
  bool isLetterActive = false;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _getUserId();
  }

  Future<void> _getUserId() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      setState(() {
        memberId = user.id;
      });
      await _loadDiaryData();
      await _checkGiftStatus();
    } else {
      print('User is not authenticated');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadDiaryData() async {
    await _loadImages();
    await _loadDiaryContent();
  }

  Future<void> _loadImages() async {
    if (memberId == null) {
      print('Member ID is null');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://43.203.173.116:8080/api/diary/selectdetail'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'memberId': memberId,
          'date': DateFormat('yyyy-MM-dd').format(widget.selectedDate),
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        setState(() {
          diaryCode = jsonResponse['diaryCode'];
        });
      } else {
        print('Failed to load diary code. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading diary code: $e');
      return;
    }

    if (diaryCode == null) {
      print('Diary code is null');
      return;
    }

    final url = Uri.parse('http://43.203.173.116:8080/api/images/diary/$diaryCode');
    try {
      final response = await http.get(url, headers: {
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        setState(() {
          imageUrls = jsonResponse
              .map((image) => image['imagePath'] as String)
              .toList();
        });
      } else {
        print('Failed to load images. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading images: $e');
    }
  }

  Future<void> _loadDiaryContent() async {
    if (memberId == null) {
      print('Member ID is null');
      setState(() {
        isLoading = false;
      });
      return;
    }

    final url = Uri.parse('http://43.203.173.116:8080/api/diary/selectdetail');
    try {
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'memberId': memberId,
          'date': DateFormat('yyyy-MM-dd').format(widget.selectedDate),
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            diaryContent = jsonResponse['diaryContents'];
            isLoading = false;
          });
        }
      } else {
        print('Failed to load diary content. Status code: ${response.statusCode}');
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading diary content: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _checkGiftStatus() async {
    if (diaryCode == null) {
      print('Diary code is null');
      return;
    }
    print("일기코드 $diaryCode");

    try {
      // 편지 상태 확인
      final letterResponse = await supabase
          .from('letter')
          .select()
          .eq('diary_code', diaryCode.toString())
          .limit(1)
          .maybeSingle();
      print("편지 응답 $letterResponse");
      setState(() {
        isLetterActive = letterResponse != null;
      });

      // 만화 상태 확인
      final cartoonResponse = await supabase
          .from('cartoon')
          .select()
          .eq('diary_code', diaryCode.toString())
          .eq('type','Cartoon')
          .limit(1)
          .maybeSingle();
      setState(() {
        isCartoonActive = cartoonResponse != null;
      });
      print("만화 응답 $cartoonResponse");

      // 음악 상태 확인
      final musicResponse = await supabase
          .from('music')
          .select()
          .eq('diary_code', diaryCode.toString())
          .limit(1)
          .maybeSingle();
      setState(() {
        isMusicActive = musicResponse != null;
      });
      print("음악 응답 $musicResponse");

    } catch (e) {
      print('Error checking gift status: $e');
    }
  }
  void _editDiary() async {
    _removeOverlayIfVisible();
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditDiaryPage(
          diaryCode: diaryCode!,
          initialContent: diaryContent!,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        isLoading = true;
      });

      await _loadDiaryContent();

      setState(() {
        isLoading = false;
      });
    }
  }

  void _showImagePopup(int initialIndex) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: double.infinity,
            height: 400,
            child: PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: imageUrls.length,
              itemBuilder: (context, index) {
                return Image.network(
                  imageUrls[index],
                  fit: BoxFit.contain,
                );
              },
            ),
          ),
        );
      },
    );
  }

  // 선물 상자 토글
  void _toggleGiftMenu() {
    setState(() {
      if (!_isOverlayVisible) {
        _overlayEntry = _createOverlayEntry();
        Overlay.of(context).insert(_overlayEntry!);
        _isOverlayVisible = true;
      } else {
        _removeOverlayIfVisible();
      }
    });
  }

  void _removeOverlayIfVisible() {
    if (_isOverlayVisible) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _isOverlayVisible = false;
    }
  }

  @override
  void dispose() {
    _removeOverlayIfVisible();
    super.dispose();
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Positioned(
        bottom: 100,
        right: 25,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 75,
            padding: EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildGiftButton(
                  imagePath: isMusicActive ? 'assets/music_icon.png' : 'assets/deactive_music_logo.png',
                  label: '맞춤노래',
                  isActive: isMusicActive,
                  onTap: () {
                    if (isMusicActive) {
                      _removeOverlayIfVisible(); // 페이지 이동 전 오버레이 제거
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MusicInquiryPage(
                            date: DateFormat('yyyy-MM-dd').format(widget.selectedDate),
                          ),
                        ),
                      );
                    }
                  },
                ),
                SizedBox(height: 16),
                _buildGiftButton(
                  imagePath: isCartoonActive ? 'assets/cuttoon_icon.png' : 'assets/deactive_cartoon_logo.png',
                  label: '하루만화',
                  isActive: isCartoonActive,
                  onTap: () {
                    if (isCartoonActive) {
                      _removeOverlayIfVisible();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CartoonInquiryScreen(selectedDate: widget.selectedDate),
                        ),
                      );
                    }
                  },
                ),
                SizedBox(height: 16),
                _buildGiftButton(
                  imagePath: isLetterActive ? 'assets/letter_icon.png' : 'assets/deactive_letter_logo.png',
                  label: '오늘의 편지',
                  isActive: isLetterActive,
                  onTap: () {
                    if (isLetterActive) {
                      _removeOverlayIfVisible(); // 페이지 이동 전 오버레이 제거
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LetterInquiryPage(
                            date: DateFormat('yyyy-MM-dd').format(widget.selectedDate),
                            diaryCode:diaryCode
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGiftButton({
    required String imagePath,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isActive ? onTap : null,
      child: Opacity(
        opacity: isActive ? 1.0 : 0.5,
        child: Column(
          children: [
            Image.asset(imagePath),
            SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xfffdfbf0),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            _removeOverlayIfVisible();
            Navigator.pop(context);
          },
        ),
        title: GestureDetector(
          onTap: () {
            _removeOverlayIfVisible();
            Navigator.pushReplacementNamed(context, '/home');
          },
          child: Image.asset(
            'assets/wisely-diary-logo.png',
            height: 30,
            fit: BoxFit.contain,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Image.asset(
              'assets/Edit.png',
              height: 30,
              width: 30,
            ),
            onPressed: _editDiary,
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (imageUrls.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _showImagePopup(0);
                    },
                    child: Container(
                      height: 200,
                      child: Stack(
                        children: [
                          Image.network(
                            imageUrls.first,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          if (imageUrls.length > 1)
                            Positioned(
                              right: 10,
                              bottom: 10,
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '+${imageUrls.length - 1}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: 16.0),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: isLoading
                        ? Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                      child: Text(
                        diaryContent ?? '일기 내용을 불러올 수 없습니다.',
                        style: TextStyle(fontSize: 16, color: Colors.black,fontFamily: 'ICHimchan',),
                      ),
                    ),

                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 30,
            right: 25,
            child: GestureDetector(
              onTap: _toggleGiftMenu,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Color(0xFF8D83FF),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                    child: Image.asset(
                      'assets/gift_icon.png',
                      width: 30,
                      height: 30,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
