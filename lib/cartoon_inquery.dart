import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CartoonInquiryScreen extends StatefulWidget {
  final DateTime selectedDate;

  const CartoonInquiryScreen({Key? key, required this.selectedDate}) : super(key: key);

  @override
  _CartoonInquiryScreenState createState() => _CartoonInquiryScreenState();
}

class _CartoonInquiryScreenState extends State<CartoonInquiryScreen> {
  List<Map<String, dynamic>> cartoons = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchCartoons();
  }

  Future<void> fetchCartoons() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        error = '사용자 인증에 실패했습니다.';
        isLoading = false;
      });
      return;
    }

    final formattedDate = DateFormat('yyyy-MM-dd').format(widget.selectedDate);

    try {
      final response = await http.get(
        Uri.parse('http://43.203.173.116:8080/api/cartoon/inquiry?date=$formattedDate&memberId=${user.id}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          cartoons = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      } else if (response.statusCode == 204) {
        setState(() {
          cartoons = [];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load cartoons');
      }
    } catch (e) {
      setState(() {
        error = '만화를 불러오는 데 실패했습니다: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building widget with cartoons: $cartoons');

    // 'Cartoon'으로 데이터를 분리
    final cartoonList = cartoons.where((cartoon) => cartoon['type']?.toString().toLowerCase() == "cartoon").toList();


    return Scaffold(
      appBar: AppBar(
        title: Text('${DateFormat('yyyy년 MM월 dd일').format(widget.selectedDate)}'),
        backgroundColor: Color(0xFFFDFBF0),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!))
          : cartoons.isEmpty
          ? Center(child: Text('이 날 생성된 만화가 없습니다.'))
          : ListView(
        children: [
          if (cartoonList.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '당신의 오늘 하루를 그려봤어요.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...cartoonList.map((cartoon) => buildCartoonItem(cartoon)).toList(),
          ],
        ],
      ),
    );
  }

  Widget buildCartoonItem(Map<String, dynamic> cartoon) {
    print('Building cartoon item: $cartoon');
    final cartoonPath = cartoon['cartoonPath'] as String?;

    return Card(
      margin: EdgeInsets.all(8.0),
      child: Column(
        children: [
          if (cartoonPath != null && cartoonPath.isNotEmpty)
            Image.network(
              cartoonPath,
              loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                print('Error loading image: $error');
                return Text('이미지를 불러올 수 없습니다.');
              },
            )
          else
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('이미지가 제공되지 않습니다.'),
            ),
        ],
      ),
    );
  }
}