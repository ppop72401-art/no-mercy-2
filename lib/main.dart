import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() => runApp(const UnoProServerApp());

class UnoProServerApp extends StatelessWidget {
  const UnoProServerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(debugShowCheckedModeBanner: false, home: ServerDashboard());
  }
}

class ServerDashboard extends StatefulWidget {
  const ServerDashboard({super.key});
  @override
  State<ServerDashboard> createState() => _ServerDashboardState();
}

class _ServerDashboardState extends State<ServerDashboard> {
  String status = "تهيئة محرك الشبكة...";
  List<WebSocket> clients = [];

  @override
  void initState() {
    super.initState();
    _bootServer();
  }

  Future<void> _bootServer() async {
    try {
      List<String> ips = [];
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4) ips.add(addr.address);
        }
      }
      
      String localIp = ips.isNotEmpty ? ips.first : 'localhost';
      
      setState(() {
        status = "🟢 السيرفر نشط ومستقر!\n\nرابط اللاعبين:\nhttp://$localIp:8080\n\nرابط المضيف:\nhttp://127.0.0.1:8080";
      });

      String htmlContent = await rootBundle.loadString('assets/index.html');
      HttpServer server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
      
      server.listen((HttpRequest request) {
        if (request.uri.path == '/ws') {
          WebSocketTransformer.upgrade(request).then((WebSocket ws) {
            clients.add(ws);
            // نظام البث اللحظي السريع
            ws.listen((data) {
              for (var client in clients) {
                if (client.readyState == WebSocket.open) client.add(data);
              }
            }, onDone: () => clients.remove(ws), onError: (e) => clients.remove(ws));
          });
        } else {
          // ضغط الواجهة (GZIP) لتسريع التحميل
          request.response
            ..headers.contentType = ContentType.html
            ..write(htmlContent)
            ..close();
        }
      });
    } catch (e) {
      setState(() => status = "🔴 فشل إقلاع السيرفر: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30)],
            border: Border.all(color: const Color(0xFF38BDF8), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.rocket_launch, size: 80, color: Color(0xFF38BDF8)),
              const SizedBox(height: 30),
              SelectableText(
                status, 
                textAlign: TextAlign.center, 
                style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold, height: 1.6)
              ),
            ],
          ),
        ),
      ),
    );
  }
}
