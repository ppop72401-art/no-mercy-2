import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(const HotspotServerApp());
}

class HotspotServerApp extends StatelessWidget {
  const HotspotServerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ServerScreen(),
    );
  }
}

class ServerScreen extends StatefulWidget {
  const ServerScreen({super.key});

  @override
  State<ServerScreen> createState() => _ServerScreenState();
}

class _ServerScreenState extends State<ServerScreen> {
  String status = "جاري التشغيل...";
  List<WebSocket> clients = [];

  @override
  void initState() {
    super.initState();
    _startServer();
  }

  Future<void> _startServer() async {
    List<String> ips = [];
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4) ips.add(addr.address);
      }
    }
    
    setState(() {
      status = "السيرفر يعمل!\nاطلب من أصدقائك فتح المتصفح وإدخال:\nhttp://${ips.isNotEmpty ? ips.first : 'localhost'}:8080";
    });

    String htmlContent = await rootBundle.loadString('assets/index.html');
    HttpServer server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
    
    server.listen((HttpRequest request) {
      if (request.uri.path == '/ws') {
        WebSocketTransformer.upgrade(request).then((WebSocket ws) {
          clients.add(ws);
          ws.listen((data) {
            // إعادة بث أي حركة لجميع الهواتف المتصلة فوراً
            for (var client in clients) {
              if (client.readyState == WebSocket.open) {
                client.add(data);
              }
            }
          }, onDone: () => clients.remove(ws));
        });
      } else {
        request.response
          ..headers.contentType = ContentType.html
          ..write(htmlContent)
          ..close();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111B21),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_tethering, size: 80, color: Color(0xFF58CC02)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2C34),
                  borderRadius: BorderRadius.circular(20),
                  border: const Border(bottom: BorderSide(color: Color(0xFF131A1F), width: 6)),
                ),
                child: SelectableText(
                  status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, color: Color(0xFF1CB0F6), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
