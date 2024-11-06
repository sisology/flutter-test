import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

class CartoonDisplayPage extends StatelessWidget {
  final List<dynamic> cartoons;

  CartoonDisplayPage({required this.cartoons});

  Widget _buildImage(String imagePath) {
    final filename = path.basename(imagePath); // 파일 이름만 추출
    final imageUrl = 'http://43.203.173.116:8080/cartoonImage/$filename';


    return Image.network(
      imageUrl,
      errorBuilder: (context, error, stackTrace) {
        print('Error loading network image: $error');
        return Text('이미지를 불러올 수 없습니다: $imageUrl');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('만화 보기'),
      ),
      body: ListView.builder(
        itemCount: cartoons.length,
        itemBuilder: (context, index) {
          final cartoon = cartoons[index];
          final imagePath = cartoon['cartoonPath'];

          return Card(
            child: Column(
              children: [
                _buildImage(imagePath),
                Text('생성 시간: ${cartoon['createdAt']}'),
              ],
            ),
          );
        },
      ),
    );
  }
}
