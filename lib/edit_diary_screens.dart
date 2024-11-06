import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditDiaryPage extends StatefulWidget {
  final int diaryCode;
  final String initialContent;

  const EditDiaryPage({
    Key? key,
    required this.diaryCode,
    required this.initialContent,
  }) : super(key: key);

  @override
  _EditDiaryPageState createState() => _EditDiaryPageState();
}

class _EditDiaryPageState extends State<EditDiaryPage> {
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.initialContent);
  }

  Future<void> _modifyDiaryContent() async {
    final uri = Uri.parse('http://43.203.173.116:8080/api/modify/${widget.diaryCode}');

    final response = await http.put(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'diaryContent': _contentController.text,
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);

      // 수정된 일기 내용을 함께 pop하여 전달
      Navigator.of(context).pop(jsonResponse);
    } else {
      print('Failed to modify diary content. Status code: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // leading 속성을 제거하거나 null로 설정하여 뒤로가기 버튼을 없앱니다.
        leading: Container(),
        title: GestureDetector(
          onTap: () {
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
            onPressed: _modifyDiaryContent,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _contentController,
                      maxLines: null,
                      decoration: InputDecoration(
                        labelText: '일기 내용',
                        border: OutlineInputBorder(),
                      ),
                      style: TextStyle(
                        fontFamily: 'ICHimchan', // 글씨체 적용
                        fontSize: 16, // 원하는 글씨 크기 설정
                        color: Colors.black, // 글씨 색상
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('취소하기'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _modifyDiaryContent,
                    child: Text('수정하기'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
