import 'package:flutter/material.dart';

class ShowData extends StatelessWidget {
  const ShowData({super.key, required this.data, required this.saveFile});
  final String data;
  final void Function(String content) saveFile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            saveFile(data);
          },
          child: Text('Сохранить зашифрованный текст'),
        ),
        const Text(
          'Encrypted Text',
          textAlign: TextAlign.left,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey,
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SelectableText(
              '${data}',
              style: TextStyle(fontSize: 16),
              onTap: () {
                // Обработчик события при нажатии на текст
              },
              showCursor: true,
              cursorColor: Colors.blue,
              cursorWidth: 2,
              cursorRadius: Radius.circular(2),
            ),
          ),
        ),
      ],
    );
  }
}
